# lua-latin1-utf8

[![Coverage Status](https://codecov.io/gh/luau-project/lua-latin1-utf8/branch/main/graph/badge.svg)](https://app.codecov.io/gh/luau-project/lua-latin1-utf8/tree/main)

## Overview

Convert strings from ISO-8859-1 (Latin 1) to UTF-8 in pure Lua.

## Installation

* If you have [LuaRocks](https://luarocks.org) properly installed and configured on your system, run the command:

    ```sh
    luarocks install lua-latin1-utf8
    ```

* Otherwise, just drop the file [lua-latin1-utf8.lua](./lua-latin1-utf8.lua) on any directory covered by `LUA_PATH` environment variable.

## Usage

### Quick

```lua
local latin1_utf8 = require("lua-latin1-utf8")

-- print the library version
print(latin1_utf8.version)

local latin1Str = " " -- some latin1-encoded string

local utf8Str = latin1_utf8(latin1Str)

-- now, `utf8Str' holds the encoded form of `latin1Str'
```

### In-depth

Consider the following statement: `Lua is an AWESOME programming language`. Such statement translated to `pt-BR` is more or less like `Lua é uma ÓTIMA linguagem de programação`.

Under the ISO-8859-1 character set, the `pt-BR` statement can be encoded to the following sequence of bytes (hex form):

```
4c 75 61 20 e9 20 75 6d
61 20 d3 54 49 4d 41 20
6c 69 6e 67 75 61 67 65
6d 20 64 65 20 70 72 6f
67 72 61 6d 61 e7 e3 6f
```

Below, we show an example of how to perform this conversion:

```lua
local latin1_utf8 = require("lua-latin1-utf8")

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
```

## Tests

### Environment setup to run tests

In order to run tests, you need to install:

* busted (testing library)
* iconv (a program to convert text in different encodings)

You can install [busted](https://github.com/lunarmodules/busted) through LuaRocks:

```sh
luarocks install busted
```

If you are on Windows, the test script tries to detect a possible `git` installation, and then use `iconv` provided by `git`. In case the test script failed to locate `iconv` installed on your computer, you can download the `iconv` program from different sources:

* [Git for Windows](https://git-scm.com/)
* [Cygwin](https://cygwin.org/)
* [MSYS2](https://www.msys2.org/)

On Unix-like distributions (Linux, macOS, BSD), most likely `iconv` is already installed on your system.

> [!IMPORTANT]
> 
> The test suite requires the directory of the `iconv` program to be on your `PATH` environment variable.
> 
> ```sh
> iconv --help
> ```

### Run tests

In the project directory, run: `lua test.lua`

### Code Coverage

Since `lua-latin1-utf8` is a tiny Lua library, one primary goal is the achievement of high code coverage.

Additionally to the previous test dependencies, you have to install the following libraries to run code coverage on tests:

* luacov (code coverage library)

You can install [luacov](https://github.com/lunarmodules/luacov) through LuaRocks:

```sh
luarocks install luacov
```

After luacov installation:

1. Run code coverage on tests: `lua -lluacov test.lua`;
2. Browse the file `luacov.report.out` to analyze the results.
