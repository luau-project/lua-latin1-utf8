package = "lua-latin1-utf8"
local raw_version = "dev"
version = raw_version .. "-1"
source = {
    url = "git+https://github.com/luau-project/lua-latin1-utf8.git"
}
description = {
    summary = "Convert strings from Latin 1 to UTF-8 in pure Lua",
    detailed = [[Convert strings from ISO-8859-1 (Latin 1) to UTF-8 in pure Lua.

Visit the repository for detailed info.]],
    homepage = "https://github.com/luau-project/lua-latin1-utf8",
    license = "MIT"
}
build = {
    type = "builtin",
    modules = {
        ["lua-latin1-utf8"] = "lua-latin1-utf8.lua"
    }
}
