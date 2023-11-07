from lfs.shell.open import OpenCmd

import sys

while True:
    try:
        value = input("> ").strip()
        cmd = value.split(" ")[0]
        args = value.split(" ")[1:]
        match cmd:
            case 'open':
                OpenCmd(*args).execute()
            case 'exit': break
    except FileNotFoundError:
        print("File Not Found!")
    except KeyboardInterrupt:
        sys.exit(0)

