import io
import struct
from dataclasses import dataclass
from typing import Any
from .LFSDriver import LFSDriver

drivers = {
    1: LFSDriver,
}

def trunc(value, size):
    if len(value) > size: return value[0:size]
    elif len(value) == size: return value
    while len(value) < size: value += " "
    return value

@dataclass
class Partition:
    attribute:int
    firstSector:int
    number:int
    name:bytes
    type:int
    size:int

    @classmethod
    def empty(cls):
        return cls(0, 0, 0, b"", 0, 0)

def decode(v):
    return int.from_bytes(v, "little", signed=False)

class Open:
    def __init__(self, file):
        self.data:dict[str, Any] = {}
        self.filename = file

    def read(self):
        file = open(self.filename, "rb")
        self.data["sectorSize"] = struct.unpack("<H", file.read(2))[0]
        file.read(2)
        self.data["sectorCount"] = struct.unpack("<I", file.read(4))[0]
        assert struct.unpack("<5s", file.read(5))[0] == b"LPT0 ", "Invalid Format!"
        file.read(425)
        self.data["partitions"] = []
        for _ in range(4):
            attr = decode(file.read(1))
            if attr != 0:
                part = Partition.empty()
                part.attribute = attr
                part.firstSector = decode(file.read(4))
                part.number = decode(file.read(1))
                part.name = file.read(5)
                part.type = decode(file.read(1))
                part.size = decode(file.read(4))
                self.data["partitions"].append(part)
            else:
                self.data["partitions"].append("<FREE>")
                file.read(15)

        # print(file.tell())
        file.read(2)
        self.data["serialNumber"] = hex(decode(file.read(4)))
        file.read(2)
        assert decode(file.read(2)) == 0x55aa, "Invalid Boot Signature"
        # print(self.data)
        file.close()

    def save(self, p:Partition, buffer:io.BytesIO):
        file = open(self.filename, "rb+")
        file.seek(p.firstSector * self.data["sectorSize"])
        buffer.seek(0)
        for i in range(len(buffer.getvalue()) // self.data["sectorSize"]):
            file.write(buffer.read(512))
        file.close()

    def driver(self, name):
        if not self.data.get("partitions"): raise Exception("Virtual drive not opened")
        for partition in self.data["partitions"]:
            if not isinstance(partition, Partition): continue
            if partition.name == trunc(name, 5).encode("utf-8"):
                driver = drivers.get(partition.type)
                if not driver: raise Exception("Invalid Filesystem Driver: Driver does not exists for %d" % partition.type)
                inst = driver.__new__(driver)

                file = open(self.filename, "rb")
                file.seek(partition.firstSector * self.data["sectorSize"])
                buffer = io.BytesIO()
                for _ in range(partition.size):
                    buffer.write(file.read(512))

                file.close()
                inst.__init__(buffer, {
                    "partStart": partition.firstSector,
                    "sectorSize": self.data["sectorSize"],
                    "partSize": partition.size,
                    "saveFunc": lambda buf : self.save(partition, buf)
                })
                return inst


    def createPartitionEntry(self, name, size, type_, attrs):
        if not self.data.get("partitions"): raise Exception("Virtual drive not opened")
        for part in self.data["partitions"]:
            if not isinstance(part, Partition): continue
            if part.name == trunc(name, 5).encode("utf-8"): raise Exception("Partition already exists")

        free, num = self._findFreePartitionEntry()
        start, e = self._findFreeSector(size)
        if not start: raise Exception("Error from _findFreeSector: '%s'" % e)
        data = struct.pack("<BIB5sBI", attrs & 0x17 | 0x20, start, num + 1, trunc(name, 5).encode("utf-8"), type_ % 256, size)
        file = open(self.filename, "rb+")
        file.seek(free)
        file.write(data)
        file.close()


    def _findFreePartitionEntry(self):
        if not self.data.get("partitions"): raise Exception("Please open before creating new Partition Entry")
        for idx, v in enumerate(self.data["partitions"]):
            if v == "<FREE>":
                if idx < 4:
                    return 438 + idx * 16, idx
                else: raise NotImplementedError
        raise NotImplementedError

    def _findFreeSector(self, size):
        free:list[dict[str, int]] = self.listFreeSpace()
        if len(free) == 1 and free[0]["count"] == 0: return None, "No space left"
        for idx, v in enumerate(free):
            if v["count"] >= size: return v["begin"], None
        return None, "No space left"

    def listFreeSpace(self):
        if not isinstance(self.data.get("partitions", None), list) : raise Exception("Virtual drive not opened")
        sectors = []
        partitions = self.data.get("partitions")
        last = None
        for idx, p in enumerate(partitions):
            if isinstance(p, Partition) and len(partitions) > idx+1:
                if isinstance(partitions[idx + 1], Partition):
                    overalloc = partitions[idx+1].firstSector - (p.firstSector + p.size)
                    if overalloc < 0:
                        raise Exception("Overallocation between %s and %s by %.0f sectors "
                                        %( p.firstSector, partitions[idx + 1].firstSector, overalloc))
                    if overalloc >= 2:
                        sectors.append({"begin": p.firstSector + p.size + 1, "count": overalloc})
            if isinstance(p, Partition):
                last = p
        # print(sectors)
        # print(last)
        if not last:
            return [{
                    "begin": 3,
                    "count": self.data["sectorCount"] - 3
                }]

        if self.data["sectorCount"] - (last.firstSector + last.size) - 4 > 0:
            sectors.append({
                "begin": last.firstSector + last.size + 1,
                "count": self.data["sectorCount"] - (last.firstSector + last.size) - 4
            })

        return sectors

    def partitions(self) -> list[Partition]:
        if not isinstance(self.data.get("partitions", None), list) : raise Exception("Virtual drive not opened")
        return self.data["partitions"]


