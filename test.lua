if (describe == nil) then
    require("busted.runner")()
end

describe("lua-latin1-utf8", function()

    -- configs for the runner environment
    local IS_WINDOWS = package.config:sub(1, 1) == "\\"
    local pathDelimiter = IS_WINDOWS and ";" or ":"
    local dirSeparator = IS_WINDOWS and "\\" or "/"
    local executableExtension = IS_WINDOWS and ".exe" or ""

    -- the raw path (unquoted)
    -- to the `iconv' program,
    -- supposed to be
    -- in the system PATH
    -- environment variable
    local iconv = nil

    -- joins a path
    local function pathJoin(...)
        local params = {...}
        local results = {}
        for i = 1, #params do
            local p = params[i]
            if (type(p) == "string") then
                if (p:sub(-#dirSeparator) == dirSeparator) then
                    table.insert(results, p)
                else
                    table.insert(results, p .. ((i < #params) and dirSeparator or ""))
                end
            end
        end
        return table.concat(results)
    end

    -- surrounds a path
    -- with double quotes
    -- for shell execution
    local function DQUOTE(path)
        return ("\"%s\""):format(path)
    end

    -- helper function to obtain
    -- convertion results of `inputString'
    -- running the oracle (`iconvProgram')
    local function getConversionResults(inputString, iconvProgram, convertFunction)
        local convertTmpname = os.tmpname()
        local quotedConvertTmpname = DQUOTE(convertTmpname)
        local iconvTmpname = os.tmpname()
        local quotedIconvTmpname = DQUOTE(iconvTmpname)
        local quotedIconv = DQUOTE(iconvProgram)
        local CMD = ("%s -f ISO-8859-1 -t UTF-8 %s>%s"):format(
            quotedIconv, quotedConvertTmpname, quotedIconvTmpname
        )
        local convertInput = io.open(convertTmpname, "wb")
        convertInput:write(inputString)
        convertInput:close()
        local process = io.popen(CMD)
        process:read("*a")
        process:close()
        local iconvOutputFile = io.open(iconvTmpname, "rb")
        local iconvOutput = iconvOutputFile:read("*a")
        iconvOutputFile:close()
        local convertOutput = convertFunction(inputString)
        os.remove(convertTmpname)
        os.remove(iconvTmpname)
        return { expected = iconvOutput, got = convertOutput }
    end

    setup(function()
        local PATH = os.getenv("PATH") or ""
        for p in PATH:gmatch("[^" .. pathDelimiter .. "]+") do
            local _iconv = pathJoin(p, "iconv" .. executableExtension)
            local f = io.open(_iconv, "rb")
            if (f ~= nil) then
                iconv = _iconv
                f:close()
                return
            end
        end

        if (IS_WINDOWS) then
            -- tries to find iconv from
            -- a `Git for Windows` installation
            local regRoots = { "HKLM", "HKCU" }
            local windir = os.getenv("WINDIR") or ""

            for i, root in ipairs(regRoots) do
                local CMD = ("%s /C reg query %s\\SOFTWARE\\GitForWindows /v InstallPath 2>NUL"):format(
                    DQUOTE(pathJoin(windir, "System32", "cmd.exe")),
                    root
                )

                local process = io.popen(CMD)
                local output = process:read("*a")
                process:close()

                for line in output:gmatch("[^\r\n]+") do
                    local installPath = line:match("%s*InstallPath%s+REG_SZ%s+(.*)")
                    if (installPath ~= nil) then
                        local _iconv = pathJoin(installPath, "usr", "bin", "iconv.exe")

                        local f = io.open(_iconv, "rb")
                        if (f ~= nil) then
                            iconv = _iconv
                            f:close()
                            return
                        end
                    end
                end
            end
        end

        if (IS_WINDOWS) then
            -- tries to find iconv from
            -- a standard MSYS2 installation
            local _iconv = pathJoin("C:", "msys64", "usr", "bin", "iconv.exe")
            local f = io.open(_iconv, "rb")
            if (f ~= nil) then
                iconv = _iconv
                f:close()
                return
            end
        end
    end)

    it("should have `iconv' program available to run tests", function()
        assert.True(iconv ~= nil)
    end)

    it("should return a `table' on require", function()
        assert.are.equal("table", type(require("lua-latin1-utf8")))
    end)

    it("should have a `string' version as field", function()
        assert.are.equal("string", type(require("lua-latin1-utf8").version))
    end)

    describe("should throw error", function()
        it("trying to set the `version' field of the library", function()
            assert.has_error(
                function()
                    require("lua-latin1-utf8").version = 1
                end
            )
        end)

        it("trying to set the `__metatable' field of the library", function()
            assert.has_error(
                function()
                    require("lua-latin1-utf8").__metatable = {}
                end
            )
        end)

        it("trying to set the `__index' field of the library", function()
            assert.has_error(
                function()
                    require("lua-latin1-utf8").__index = 1
                end
            )
        end)

        it("trying to set the `__newindex' field of the library", function()
            assert.has_error(
                function()
                    require("lua-latin1-utf8").__newindex = function(self, key, value) rawset(self, key, value) end
                end
            )
        end)

        it("trying to set the `__call' field of the library", function()
            assert.has_error(
                function()
                    require("lua-latin1-utf8").__call = function(self, s) return s end
                end
            )
        end)

        it("trying to set non-existent field of the library", function()
            assert.has_error(
                function()
                    require("lua-latin1-utf8").some = 1
                end
            )
        end)
    end)

    describe("`convert' function", function()
        local convert = nil

        setup(function()
            convert = require("lua-latin1-utf8")
        end)

        it("should throw error on non-string input", function()
            local inputs = {-3.2, 1, function() end, coroutine.wrap(function() end), {}, false, true}
            for i, input in ipairs(inputs) do
                assert.has_error(function() convert(input) end)
            end
        end)

        it("should map 7-bit characters in the range 0 - 0x7F to themselves", function()
            for byte = 0, 0x7F do
                local sevenBit = string.char(byte)
                local latin1SevenBit = convert(sevenBit)
                assert.are.equal(
                    convert(sevenBit),
                    convert(latin1SevenBit)
                )
            end
        end)

        it("should be case-sensitive", function()
            for byte = 0xC0, 0xD6 do
                local upperCase = string.char(byte)
                local lowerCase = string.char(byte + 0x20)
                assert.are_not.equal(
                    convert(upperCase),
                    convert(lowerCase)
                )
            end
            for byte = 0xD8, 0xDE do
                local upperCase = string.char(byte)
                local lowerCase = string.char(byte + 0x20)
                assert.are_not.equal(
                    convert(upperCase),
                    convert(lowerCase)
                )
            end
        end)

        describe("should match iconv output", function()
            it("for each single-byte character (0 - 0xFF)", function()
                for byte = 0, 0xFF do
                    local inputString = string.char(byte)
                    local results = getConversionResults(inputString, iconv, convert)
                    assert.are.equal(results.expected, results.got)
                end
            end)

            it("for the statement in the usage section of the README", function()

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

                local results = getConversionResults(statementLatin1, iconv, convert)
                assert.are.equal(results.expected, results.got)
            end)
        end)
    end)

end)
