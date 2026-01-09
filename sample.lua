local latin1_utf8 = require("lua-latin1-utf8")

-- print the library version
print(latin1_utf8.version)

-- statement bytes encoded in latin1 (ISO-8859-1)
local statementBytesLatin1 = {
    0x4c, 0x75, 0x61, 0x20, 0xe9, 0x20, 0x75, 0x6d,
    0x61, 0x20, 0xd3, 0x54, 0x49, 0x4d, 0x41, 0x20,
    0x6c, 0x69, 0x6e, 0x67, 0x75, 0x61, 0x67, 0x65,
    0x6d, 0x20, 0x64, 0x65, 0x20, 0x70, 0x72, 0x6f,
    0x67, 0x72, 0x61, 0x6d, 0x61, 0xe7, 0xe3, 0x6f
}

-- holds the characters
local statementCharsLatin1 = {}
for i, byte in ipairs(statementBytesLatin1) do
    table.insert(statementCharsLatin1, string.char(byte))
end

-- the statement string ISO-8859-1 (latin 1) encoded
local statementLatin1 = table.concat(statementCharsLatin1)

-- the statement string UTF-8 encoded
local statementUtf8 = latin1_utf8(statementLatin1)

-- prints the UTF-8 encoded statement
-- "Lua é uma ÓTIMA linguagem de programação"
print(statementUtf8)
