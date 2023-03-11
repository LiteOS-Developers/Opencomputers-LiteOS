keyCode = {}
keyCode["32"] = " "
keyCode["33"] = "!"
keyCode["34"] = "\""
keyCode["35"] = "#"
keyCode["36"] = "$"
keyCode["37"] = "%"
keyCode["38"] = "&"
keyCode["39"] = "'"
keyCode["40"] = "("
keyCode["41"] = ")"
keyCode["42"] = "*"
keyCode["43"] = "+"
keyCode["44"] = ","
keyCode["45"] = "-"
keyCode["46"] = "."
keyCode["47"] = "/"

keyCode["48"] = "0"
keyCode["49"] = "1"
keyCode["50"] = "2"
keyCode["51"] = "3"
keyCode["52"] = "4"
keyCode["53"] = "5"
keyCode["54"] = "6"
keyCode["55"] = "7"
keyCode["56"] = "8"
keyCode["57"] = "9"
keyCode["58"] = ":"
keyCode["59"] = ";"
keyCode["61"] = "="
keyCode["63"] = "?"

keyCode["65"] = "A"
keyCode["66"] = "B"
keyCode["67"] = "C"
keyCode["68"] = "D"
keyCode["69"] = "E"
keyCode["70"] = "F"
keyCode["71"] = "G"
keyCode["72"] = "H"
keyCode["73"] = "I"
keyCode["74"] = "J"
keyCode["75"] = "K"
keyCode["76"] = "L"
keyCode["77"] = "M"
keyCode["78"] = "N"
keyCode["79"] = "O"
keyCode["80"] = "P"
keyCode["81"] = "Q"
keyCode["82"] = "R"
keyCode["83"] = "S"
keyCode["84"] = "T"
keyCode["85"] = "U"
keyCode["86"] = "V"
keyCode["87"] = "W"
keyCode["88"] = "X"
keyCode["89"] = "Y"
keyCode["90"] = "Z"

keyCode["92"] = "\\"
keyCode["94"] = "^"
keyCode["95"] = "_"

keyCode["97"] = "a"
keyCode["98"] = "b"
keyCode["99"] = "c"
keyCode["100"] = "d"
keyCode["101"] = "e"
keyCode["102"] = "f"
keyCode["103"] = "g"
keyCode["104"] = "h"
keyCode["105"] = "i"
keyCode["106"] = "j"
keyCode["107"] = "k"
keyCode["108"] = "l"
keyCode["109"] = "m"
keyCode["110"] = "n"
keyCode["111"] = "o"
keyCode["112"] = "p"
keyCode["113"] = "q"
keyCode["114"] = "r"
keyCode["115"] = "s"
keyCode["116"] = "t"
keyCode["117"] = "u"
keyCode["118"] = "v"
keyCode["119"] = "w"
keyCode["120"] = "x"
keyCode["121"] = "y"
keyCode["122"] = "z"
keyCode["123"] = "{"

keyCode["125"] = "}"
keyCode["126"] = "~"
keyCode["167"] = "§"

keyCode["196"] = "Ä"
keyCode["214"] = "Ö"
keyCode["220"] = "Ü"
keyCode["223"] = "ß"
keyCode["228"] = "ä"

keyCode["226"] = "ö"
keyCode["252"] = "ü"

local superKeys = {
    ["0.29"] = "STRG",
    ["0.157"] = "RSTRG",
    ["0.42"] = "SHIFT",
    ["0.54"] = "RSHIFT",
    ["0.56"] = "ALT",   
    ["0.58"] = "CAPSLOCK",
    ["0.219"] = "SUPER",
    ["8.14"] = "BACKSPACE",
    ["9.15"] = "TAB",
    ["13.28"] = "ENTER"
}
assert(keyCode ~= nil, "keyCode variable not found!")   


return keyCode, superKeys
