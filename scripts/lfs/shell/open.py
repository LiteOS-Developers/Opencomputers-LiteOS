import os
import os.path as path

from .partition import LFSCmd
from .. import Open, LFSDriver
from ..open import Partition


def trunc(value, size):
    if len(value) > size: return value[0:size]
    elif len(value) == size: return value
    while len(value) < size: value += " "
    return value



class OpenCmd:
    def __init__(self, filename, *args):
        self.filename = path.abspath(filename)
        self.vfs = Open(self.filename)
        self.vfs.read()

    def execute(self):

        while True:
            value = input(f'{path.basename(self.filename)}> ').strip()
            cmd = value.split(" ")[0]
            args = value.split(" ")[1:]
            match cmd:
                case 'list':
                    print('Name  | First-Sector | Sectors')
                    print('======|==============|========')
                    for partition in self.vfs.partitions():
                        if isinstance(partition, Partition):
                            print(f'{partition.name.decode()} | {trunc(str(partition.firstSector), 12)} | {str(partition.size)}')
                case 'open':
                    if len(args) < 1:
                        print('Expected Argument: Partition name')
                        continue
                    driver = self.vfs.driver(args[0])
                    if driver is None:
                        print('Invalid Partition: PartitionDoesNotExists')
                        continue
                    if isinstance(driver, LFSDriver):
                        LFSCmd(driver, self.filename).execute(args[0])
                    else: assert False

                case 'exit': return
