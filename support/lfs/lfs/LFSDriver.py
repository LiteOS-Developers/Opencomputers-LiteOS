import math
import random
import struct
import time
from abc import ABC
from dataclasses import dataclass
from io import BytesIO
from typing import Any

from .BaseDriver import BaseDriver

@dataclass
class LFSData:
    sectorCount:int
    signature:int
    firstRDSector:int
    label:str

    @classmethod
    def empty(cls):
        return cls(0, 0, 0, "")

class Permission:
    U_READ =    256
    U_WRITE =   128
    U_EXEC =    64
    U_ = 258 | 128 | 64

    G_READ =    32
    G_WRITE =   16
    G_EXEC =    8
    G_ = 32 | 16 | 8

    O_READ =    4
    O_WRITE =   2
    O_EXEC =    1
    O_ = 4 | 2 | 1

    def __init__(self, uid, gid, perms = U_ | G_READ):
        self.uid = uid
        self.gid = gid
        self.perms = perms

@dataclass
class DirectoryEntry:
    attrs:int
    lastAccess:int
    size:int
    firstSector:int
    filename:str
    ext:str
    perms:int
    uid:int
    gid:int
    entryPos:int

    def pack(self):
        return struct.pack("<BIII10s3sHHH", self.attrs, self.lastAccess, self.size, self.firstSector, trunc(self.filename, 10).encode("utf-8"),
                           trunc(self.ext, 3).encode("utf-8"), self.perms, self.uid, self.gid)

    @classmethod
    def empty(cls):
        return cls(0, 0, 0, 0, "", "", 0, 0, 0, 0)

    @classmethod
    def fromTuple(cls, v):
        if len(v) != 9: raise Exception()
        return cls(v[0], v[1], v[2], v[3], v[4].decode("utf-8"), v[5].decode("utf-8"), v[6], v[7], v[8], 0)


def decode(v):
    return int.from_bytes(v, "little", signed=False)

def trunc(value, size):
    if len(value) > size: return value[0:size]
    elif len(value) == size: return value
    while len(value) < size: value += " "
    return value

class LFSDriver(BaseDriver, ABC):
    DRIVER_NUM = 1

    def __init__(self, buffer, info):
        super().__init__()
        self.buffer:BytesIO = buffer
        self.info:dict[str, Any] = info
        self.data:LFSData|None = None

    def create(self):
        self.buffer.seek(0)
        self.buffer.write(struct.pack("<I16sII16s", self.info["partSize"], b"\0",
                                      random.randint(0x1000_0000, 0xFFFF_FFF0),
                                      self.info["partStart"] + 1,
                                      trunc("", 16).encode("utf-8")))
        timestamp = int(time.time())
        self.buffer.seek(512)
        self.buffer.write(struct.pack("<IIB", 0xFFFF_FFFF, timestamp, 0))

    def save(self):
        self.info["saveFunc"](self.buffer)

    # def createDirEntry(self, dir:DirectoryEntry):

    def isFile(self, path):
        fname, ext = self._getFNandExt(path)
        entry = self._findEntryDeep(fname, ext)
        if not entry: return False
        return entry.attrs & (1 << 4) == 0

    def isDir(self, path):
        fname, ext = self._getFNandExt(path)
        entry = self._findEntryDeep(fname, ext)
        if not entry: return False
        return entry.attrs & (1 << 4) != 0

    def getEntry(self, path) -> DirectoryEntry|None:
        fname, ext = self._getFNandExt(path)
        entry = self._findEntryDeep(fname, ext)
        return entry

    def read(self):
        if self.info["sectorSize"] != 512: raise ValueError("SectorSize")
        self.buffer.seek(0)
        data = LFSData.empty()
        data.sectorCount = decode(self.buffer.read(4))
        if data.sectorCount == 0: raise Exception("Filesystem not created!")
        self.buffer.read(16)
        data.signature = decode(self.buffer.read(4))
        data.firstRDSector = decode(self.buffer.read(4)) - self.info["partStart"]
        data.label = self.buffer.read(16).decode("utf-8").strip()
        self.buffer.read(468)
        assert self.buffer.tell() == 512
        self.data = data

    def _getFNandExt(self, filename, isDir = False):
        extpos = filename.rfind(".")
        if extpos < 0 and not isDir: raise ValueError("Filename needs ExtDot")
        filen = filename[:extpos] if not isDir else filename
        ext = filename[extpos + 1:] if not isDir else ""
        return filen, ext

    ###########################

    def mkdir(self, filename, perms: Permission, attrs = 0):
        parts = filename.split("/")
        parent = parts[:-1]
        name = parts[-1]
        filen, ext = self._getFNandExt(name, True)
        self.createEntry("/".join(parent), filen, ext, {
            "uid": perms.uid,
            "gid": perms.gid,
            "perms": perms.perms,
            "attributes": 1 << 4 | attrs
        })
    def createFile(self, filename, perms:Permission, attrs = 0):
        parts = filename.split("/")
        parent = parts[:-1]
        name = parts[-1]
        filen, ext = self._getFNandExt(name)
        parent = "/".join(parent)
        parent = "/" if len(parent) == 0 else parent
        self.createEntry(parent, filen, ext, {
            "uid": perms.uid,
            "gid": perms.gid,
            "perms": perms.perms,
            "attrs": attrs
        })

    def rename(self, filename, newfilename):
        oldfilen, oldext = self._getFNandExt(filename)
        newfilen, newext = self._getFNandExt(newfilename)
        entry = self._findEntryDeep(oldfilen, oldext)
        self.buffer.seek(entry.entryPos+23)
        self.buffer.write(newfilen[:10].encode("utf-8"))
        self.buffer.write(newext[:3].encode("utf-8"))
        if len(oldfilen) > 10:
            raise NotImplementedError("!")

        elif len(newfilen) > 10: raise ValueError("New Filename cannot be longer than 10 Characters since the old was shorter then 10!")

    def readFile(self, filename, count):
        filen, ext = self._getFNandExt(filename)
        entry = self._findEntryDeep(filen, ext)
        if not entry: raise FileNotFoundError(filename)
        sectors = self._getSectors(entry.firstSector)
        to_read = count
        content = b""
        for idx, s in enumerate(sectors):
            self.buffer.seek(s * self.info["sectorSize"])
            _, _, lfnCount = struct.unpack("<IIB", self.buffer.read(9))
            if idx != 1 and lfnCount != 0: raise Exception() # TODO
            elif idx == 0 and lfnCount != 0: self.buffer.read(lfnCount)
            count_in_block = 512 - 9 - lfnCount
            if to_read <= count_in_block:
                content += self.buffer.read(to_read)
                return content
            content += self.buffer.read(count_in_block)
            to_read -= count_in_block
            assert to_read >= 0
        assert False, "Reach?"

    def remove(self, filename):
        filen, ext = self._getFNandExt(filename)
        entry = self._findEntryDeep(filen, ext)
        self.buffer.seek(entry.entryPos)
        self.buffer.write(b"\x00")
        self.buffer.seek(entry.entryPos+5)
        self.buffer.seek(3, 1)
        self.buffer.write(struct.pack("<B", entry.attrs))
        self.buffer.seek(entry.entryPos+5)
        x = self.buffer.read(4)
        self.save()
        pass

    def list(self, filename):
        if '.' in filename: raise Exception("!")
        filen, ext = self._getFNandExt(filename + ".")
        entry = self._findEntryDeep(filen, ext)
        if entry.attrs & (1 << 4) == 0: raise Exception(filename + " is not a Directory")
        entries = self._getEntries(entry.firstSector)
        filenames = []
        for entry in entries:
            fn = entry.filename.strip()
            self.buffer.seek(entry.firstSector * 512 + 8)
            remaining = decode(self.buffer.read(1))
            if remaining != 0:
                fn += self.buffer.read(remaining).decode("utf-8")
            else: fn += "." +  entry.ext
            filenames.append(fn)
        return filenames


    def writeFile(self, filename:str, content:bytes):
        filen, ext = self._getFNandExt(filename)
        entry = self._findEntryDeep(filen, ext)
        if not entry: raise FileNotFoundError(filename)
        sectors = self._getSectors(entry.firstSector)
        sectors_needed = 0
        self.buffer.seek(entry.entryPos + 5, 0)
        self.buffer.write(int.to_bytes(len(content), 4, "little", signed=False))
        for idx, s in enumerate(sectors):
            self.buffer.seek(s * self.info["sectorSize"])
            _, _, lfnCount = struct.unpack("<IIB", self.buffer.read(9))
            if idx != 0 and lfnCount != 0: raise Exception() # TODO
            elif idx == 0 and lfnCount != 0: self.buffer.read(lfnCount)
            count_to_write = 512 - 9 - lfnCount
            if count_to_write >= len(content):
                self.buffer.write(b"\0" * count_to_write)
                self.buffer.seek(-count_to_write, 1)
                self.buffer.write(content.encode("utf-8"))
                sectors_needed += 1
                break
            to_write = content[:count_to_write]
            self.buffer.write(to_write.encode("utf-8"))
            content = content[count_to_write:]
            sectors_needed += 1
        else:
            if len(content) != 0:
                while True:
                    free = self._findFreeSector()
                    assert free
                    self.buffer.seek(sectors[-1] * self.info["sectorSize"])
                    self.buffer.write(struct.pack("<I", free))
                    self.buffer.seek(free * self.info["sectorSize"])
                    self.buffer.write(struct.pack("<IIB", 0xFFFF_FFFF, round(time.time()), 0))
                    sectors.append(free)
                    sectors_needed += 1
                    count_to_write = math.ceil(self.buffer.tell() / 512) * 512 - self.buffer.tell()
                    if count_to_write >= len(content):
                        self.buffer.write(content.encode("utf-8"))
                        break
                    to_write = content[:count_to_write]
                    self.buffer.write(to_write.encode("utf-8"))
                    content = content[count_to_write:]
            # Else everthing written
        if sectors_needed < len(sectors):
            remove_count = len(sectors) - sectors_needed
            idx = len(sectors) - 1
            print("FREEING SECTORS")
            while remove_count > 0:
                self.buffer.seek(sectors[idx] * self.info["sectorSize"], 0)
                # print(sectors[idx], self.buffer.tell())
                self.buffer.write(b"\0\0\0\0")
                self.buffer.write(b"\0\0\0\0")
                remove_count -= 1
                idx -= 1
                if remove_count == 0:
                    self.buffer.seek(sectors[idx] * self.info["sectorSize"], 0)
                    self.buffer.write(b"\xff\xff\xff\xff")


    def spaceUsed(self):
        used = 1
        self.buffer.seek(512)
        for _ in range(self.info["partSize"]):
            if decode(self.buffer.read(4)) != 0: used += 1

        return used


    def _getSectors(self, start):
        self.buffer.seek(start * self.info["sectorSize"])
        sectors = [start]
        while True:
            next = decode(self.buffer.read(4))
            if next == 0xFFFF_FFFF: break
            sectors.append(next)
            self.buffer.seek(next * self.info["sectorSize"], 0)
        return sectors

    def _findFreeSector(self):
        for idx in range(self.data.firstRDSector + 1, self.data.sectorCount + 1):
            off = idx * self.info["sectorSize"]
            self.buffer.seek(off, 0)
            val = self.buffer.read(4)
            if decode(val) == 0: return idx
        raise Exception("")

    def _findFreeEntry(self, entry:DirectoryEntry):
        if entry is not None:
            sectors = self._getSectors(entry.firstSector)
        else:
            sectors = self._getSectors(self.data.firstRDSector)
        entries = []
        for idx, s in enumerate(sectors):
            self.buffer.seek(s * self.info["sectorSize"])
            start = self.buffer.tell()
            data = struct.unpack("<IIB", self.buffer.read(9))
            if data[2] != 0 and idx > 0: raise Exception("Invalid LFNCount byte.")
            if idx == 1 and data[2] > 0: self.buffer.read(data[2])
            while (self.buffer.tell() - start) + 32 < 512:
                attr = decode(self.buffer.read(1))
                if attr == 0:
                    return self.buffer.tell() - 1
                else:
                    self.buffer.seek(31, 1)
        _next = self._findFreeSector()
        self.buffer.seek(sectors[-1] * 512)
        v = decode(self.buffer.read(4))
        if v != 0xFFFFFFFF: raise ValueError("!")
        self.buffer.seek(sectors[-1] * 512)
        self.buffer.write(struct.pack("<I", _next))
        self.buffer.seek(_next * 512)
        self.buffer.write(struct.pack("<IIB", 0xFFFF_FFFF, round(time.time()), 0))
        if entry is not None:
            sectors = self._getSectors(entry.firstSector)
        else:
            sectors = self._getSectors(self.data.firstRDSector)
        return self._findFreeEntry(entry)


    def createEntry(self, parent:str, name:str, ext:str, opts:dict = None):
        x = self._findEntryDeep((parent if not parent.endswith("/") else parent[:-1]) + name, ext)
        if x:
            raise FileExistsError(parent + name + "." + ext)
        opts = opts or {}
        entry = DirectoryEntry.empty()
        entry.attrs = (opts.get("attributes", 0) & 31) | 1 << 5
        created = int(opts.get("created", time.time()))
        entry.lastAccess = int(opts.get("lastAccess", time.time()))
        entry.fileSize = int(opts.get("fileSize", 0))
        entry.firstSector = self._findFreeSector()
        entry.ext = ext
        entry.filename = name
        entry.perms = int(opts.get("perms", (1 << 9) - 1))
        entry.uid = int(opts.get("uid", 0))
        entry.gid = int(opts.get("gid", 0))
        data = entry.pack()
        parentEntry = self._findEntryDeep(parent, "")
        free = self._findFreeEntry(parentEntry)
        self.buffer.seek(free, 0)
        self.buffer.write(data)
        self.buffer.seek(entry.firstSector * self.info["sectorSize"])
        self.buffer.write(struct.pack("<II", 0xFFFF_FFFF, created))
        if len(name) > 10:
            remaining = len(name[10:]) + len(ext) + 1
            self.buffer.write(struct.pack(f"<B{remaining}s", remaining, (name[10:] + "." + ext).encode("utf-8")))
        else:
            self.buffer.write(b"\x00")

    def _getFilename(self, entry:DirectoryEntry):
        self.buffer.seek(entry.firstSector * self.info["sectorSize"], 0)
        _, _, lfnCount = struct.unpack("<IIB", self.buffer.read(9))
        if lfnCount == 0: return entry.filename.strip() + "." + entry.ext.strip()
        else:
            data = self.buffer.read(lfnCount).decode("utf-8")
            return entry.filename.strip() + data

    def _findEntryDeep(self, filename:str, ext:str):
        if not self.data: raise Exception("Filesystem not opened")
        parts = filename.split("/")
        entries = self._getEntries(self.data.firstRDSector)
        entry = None
        if filename == "/": return DirectoryEntry(
            (1 << 6) - 1,
            int(time.time()),
            0, self.data.firstRDSector,
            "/", "", (1 << 9) - 1, 0, 0, -1
        )
        for idx, part in enumerate(parts):
            for entry in entries.copy():
                if trunc(part, 10) == entry.filename and ((idx + 1) != len(parts) or trunc(ext, 3) == entry.ext):
                    if idx + 1 != len(parts):
                        entries = self._getEntries(entry.firstSector)
                    elif self._getFilename(entry) == parts[-1] + "." + ext: # we reached last part of filename
                        return entry
                    break
        # if trunc(part, 10) == entry.filename and trunc(ext, 3) == entry.ext:
        #     return entry

        return None


    def _getEntries(self, start):
        sectors = self._getSectors(start)
        entries = []
        for idx, s in enumerate(sectors):
            self.buffer.seek(s * self.info["sectorSize"])
            start = self.buffer.tell()
            data = struct.unpack("<IIB", self.buffer.read(9))
            if data[2] != 0 and idx > 0: raise Exception("Invalid LFNCount byte.")
            if idx == 1 and data[2] > 0: self.buffer.read(data[2])
            while (self.buffer.tell() - start) + 32 < 512:
                attr = decode(self.buffer.read(1))
                if attr != 0:
                    self.buffer.seek(-1, 1)
                    entry = DirectoryEntry.fromTuple(
                        struct.unpack("<BIII10s3sHHH", self.buffer.read(32))
                    )
                    entry.entryPos = self.buffer.tell() - 32
                    entries.append(entry)
                else: self.buffer.seek(31, 1)

        return entries

    def setLabel(self, new):
        if not self.data: raise Exception("Filesystem not opened")
        self.buffer.seek(28)
        self.buffer.write(trunc(new, 16).encode("utf-8"))
        self.data.label = trunc(new, 16).strip()
        return trunc(new, 16)

    def getLabel(self):
        if not self.data: raise Exception("Filesystem not opened")
        return self.data.label.strip()
