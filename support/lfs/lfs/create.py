import io
import struct
import random

class Create:
    def __init__(self, sectors):
        self.sectors = sectors
        self.data = io.BytesIO()

    def create(self):
        # LPT
        data = struct.pack("<HHI5s425s64sHIHH", 512, 0, self.sectors, b"LPT0 ", b"\0", b"\0", 0,
                           random.randint(0x1000_0000, 0xFFFF_FFF0), # Serial Number
                           0, 0x55AA)
        self.data.write(data)
        for _ in range(self.sectors - 1):
            self.data.write(struct.pack("<512s", b"\0"))

        assert len(self.data.getvalue()) == self.sectors * 512, len(self.data.getvalue()) / 512
        # print(len(self.data.getvalue()))

    def save(self, filename):
        if len(self.data.getvalue()) == 0: raise Exception("Please create vfs file before saving")
        file = open(filename, "wb")
        file.seek(0)
        file.write(self.data.getvalue())

        