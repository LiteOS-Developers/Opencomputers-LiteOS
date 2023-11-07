def perm(p, d=False):
    o = 0
    o |= 256 if p[0] != "-" else 0
    o |= 128 if p[1] != "-" else 0
    o |= 64 if p[2]  != "-" else 0

    o |= 32 if p[3]  != "-" else 0
    o |= 16 if p[4]  != "-" else 0
    o |= 8 if p[5]   != "-" else 0

    o |= 4 if p[6]   != "-" else 0
    o |= 2 if p[7]   != "-" else 0
    o |= 1 if p[8]   != "-" else 0
    
    if d:
        o |= 0x4000
    else:
        o |= 0x8000

    return o

def pint(o):
    r = ""
    r += "r" if o & 256 else "-"
    r += "w" if o & 128 else "-"
    r += "x" if o & 64  else "-"

    r += "r" if o & 32  else "-"
    r += "w" if o & 16  else "-"
    r += "x" if o & 8   else "-"

    r += "r" if o & 4   else "-"
    r += "w" if o & 2   else "-"
    r += "x" if o & 1   else "-"

    r = ("d" if o & 0x4000 else "f") + r

    return r
