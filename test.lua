do
    local arg_iter = 1
    local current
    local run_luacov = false
    repeat
        current = arg[arg_iter]
        if (
            (type(current) == "string") and
            (
                (current == "--coverage") or
                (current == "-c")
            )
        ) then
            run_luacov = true
        end
        arg_iter = arg_iter + 1
    until current == nil

    if (run_luacov) then
        local ok, luacov_runner = pcall(require, "luacov.runner")
        if (ok) then
            luacov_runner.init()
        else
            error("Failed to load luacov.runner. Please, install `luacov' to run code coverage on tests.", 2)
        end
    end
end

local ltestlib = require("ltestlib")
local latin1_utf8

-- configs for the runner environment
local dirSeparator = package.config:sub(1, 1)
local IS_WINDOWS = dirSeparator == "\\"
local pathDelimiter = IS_WINDOWS and ";" or ":"
local executableExtension = IS_WINDOWS and ".exe" or ""

-- the raw path (unquoted)
-- to the `iconv' program,
-- supposed to be
-- in the system PATH
-- environment variable
local iconv = nil

-- joins a path
local pathJoin
pathJoin = function(params)
    local results = {}
    local tParams = type(params)
    if (tParams ~= "table") then
        error(("bad #1 argument (table expected, but got %s)"):format(tParams))
    end
    local nParams = #params
    local sepLen = #dirSeparator
    for i, p in ipairs(params) do
        local tp = type(p)
        if (tp == "string") then
            if (p:sub(-sepLen) == dirSeparator or i == nParams) then
                table.insert(results, p)
            else
                table.insert(results, p .. dirSeparator)
            end
        elseif (tp == "table") then
            table.insert(results, pathJoin(p))
        end
    end
    return table.concat(results)
end

-- gets a temporary file name
local function tmpFile()
    local tmpDir = os.getenv("TMP") or os.getenv("TMPDIR") or "."
    local filename = ("lua-latin1-utf8-%s"):format(os.getenv("RANDOM") or tostring(math.random(1, 1e6)))
    return pathJoin({tmpDir, filename})
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
    local convertTmpname = tmpFile()
    local quotedConvertTmpname = DQUOTE(convertTmpname)
    local iconvTmpname = tmpFile()
    local quotedIconvTmpname = DQUOTE(iconvTmpname)
    local quotedIconv = DQUOTE(iconvProgram)
    local convertInput = io.open(convertTmpname, "wb")
    convertInput:write(inputString)
    convertInput:close()
    local CMD
    local batchTmpname
    if (IS_WINDOWS) then
        local iconvBaseName = "iconv.exe";
        local iconvDirname = iconvProgram:sub(1, -(#iconvBaseName + 1))
        local quotedIconvDirname = DQUOTE(iconvDirname)
        local batchContent = ("cd %s\r\n%s -f ISO-8859-1 -t UTF-8 %s>%s"):format(
            quotedIconvDirname, iconvBaseName, quotedConvertTmpname, quotedIconvTmpname
        )
        batchTmpname = tmpFile() .. ".bat"
        local quotedBatchTmpname = DQUOTE(batchTmpname)
        local batchFile = io.open(batchTmpname, "wb")
        batchFile:write(batchContent)
        batchFile:close()
        local systemDrive = os.getenv("SystemDrive") or "C:"
        CMD = ("%s /C %s"):format(
            pathJoin({systemDrive, "Windows", "System32", "cmd.exe"}),
            quotedBatchTmpname
        )
    else
        CMD = ("%s -f ISO-8859-1 -t UTF-8 %s>%s"):format(
            quotedIconv, quotedConvertTmpname, quotedIconvTmpname
        )
    end
    local process = io.popen(CMD)
    process:read("*a")
    process:close()
    local iconvOutputFile = io.open(iconvTmpname, "rb")
    local iconvOutput = iconvOutputFile:read("*a")
    iconvOutputFile:close()
    local convertOutput = convertFunction(inputString)
    os.remove(convertTmpname)
    os.remove(iconvTmpname)
    if (IS_WINDOWS) then
        os.remove(batchTmpname)
    end
    return { expected = iconvOutput, got = convertOutput }
end

local testnames = {}

testnames.setup = "lua-latin1-utf8 should have `iconv' program available to run tests"
ltestlib.new_test(testnames.setup, function()
    local PATH = os.getenv("PATH") or ""
    for p in PATH:gmatch("[^" .. pathDelimiter .. "]+") do
        local _iconv = pathJoin({p, "iconv" .. executableExtension})
        local f = io.open(_iconv, "rb")
        if (f ~= nil) then
            iconv = _iconv
            f:close()
            break
        end
    end

    if ((iconv == nil) and IS_WINDOWS) then
        -- tries to find iconv from
        -- a `Git for Windows` installation
        local regRoots = { "HKLM", "HKCU" }
        local systemDrive = os.getenv("SystemDrive") or "C:"

        for i, root in ipairs(regRoots) do
            local CMD = ("%s /C reg query %s\\SOFTWARE\\GitForWindows /v InstallPath 2>NUL"):format(
                DQUOTE(pathJoin({systemDrive, "Windows", "System32", "cmd.exe"})),
                root
            )

            local process = io.popen(CMD)
            local output = process:read("*a")
            process:close()

            for line in output:gmatch("[^\r\n]+") do
                local installPath = line:match("%s*InstallPath%s+REG_SZ%s+(.*)")
                if (installPath ~= nil) then
                    local _iconv = pathJoin({installPath, "usr", "bin", "iconv.exe"})

                    local f = io.open(_iconv, "rb")
                    if (f ~= nil) then
                        iconv = _iconv
                        f:close()
                        break
                    end
                end
            end
        end
    end

    if ((iconv == nil) and IS_WINDOWS) then
        -- tries to find iconv from
        -- standard MSYS2 or Cygwin locations
        local possibleLocations = {
            {os.getenv("SystemDrive") or "C:", "msys64", "usr", "bin", "iconv.exe"},
            {os.getenv("SystemDrive") or "C:", "cygwin64", "bin", "iconv.exe"},
            {os.getenv("SystemDrive") or "C:", "msys", "usr", "bin", "iconv.exe"},
            {os.getenv("SystemDrive") or "C:", "cygwin", "bin", "iconv.exe"}
        }
        for i, location in ipairs(possibleLocations) do
            local _iconv = pathJoin(location)
            local f = io.open(_iconv, "rb")
            if (f ~= nil) then
                iconv = _iconv
                f:close()
                break
            end
        end
    end

    ltestlib.assert_true(testnames.setup, iconv ~= nil)
end)

testnames.table_on_require = "lua-latin1-utf8 should return a `table' on require"
ltestlib.new_test(testnames.table_on_require, function()
    latin1_utf8 = require("lua-latin1-utf8")
    ltestlib.assert_equal(testnames.table_on_require, "table", type(latin1_utf8))
end)

testnames.version_field = "lua-latin1-utf8 should have a `string' version as field"
ltestlib.new_test(testnames.version_field, function()
    ltestlib.assert_equal(testnames.version_field, "string", type(latin1_utf8.version))
end)

testnames.nil_for_fields_not_present = "lua-latin1-utf8 should return nil for fields not present in the library"
ltestlib.new_test(testnames.nil_for_fields_not_present, function()
    ltestlib.assert_equal(testnames.nil_for_fields_not_present, "nil", type(latin1_utf8.some))
end)

testnames.throw_error_setting_version = "lua-latin1-utf8 should throw error trying to set the `version' field of the library"
ltestlib.new_test(testnames.throw_error_setting_version, function()
    ltestlib.assert_throws(testnames.throw_error_setting_version, function()
        latin1_utf8.version = 1
    end)
end)

testnames.throw_error_setting_metatable = "lua-latin1-utf8 should throw error trying to set the `__metatable' field of the library"
ltestlib.new_test(testnames.throw_error_setting_metatable, function()
    ltestlib.assert_throws(testnames.throw_error_setting_metatable, function()
        latin1_utf8.__metatable = 1
    end)
end)

testnames.throw_error_setting_index = "lua-latin1-utf8 should throw error trying to set the `__index' field of the library"
ltestlib.new_test(testnames.throw_error_setting_index, function()
    ltestlib.assert_throws(testnames.throw_error_setting_index, function()
        latin1_utf8.__index = 1
    end)
end)

testnames.throw_error_setting_newindex = "lua-latin1-utf8 should throw error trying to set the `__newindex' field of the library"
ltestlib.new_test(testnames.throw_error_setting_newindex, function()
    ltestlib.assert_throws(testnames.throw_error_setting_newindex, function()
        latin1_utf8.__newindex = 1
    end)
end)

testnames.throw_error_setting_nonexistent = "lua-latin1-utf8 should throw error trying to set non-existent field of the library"
ltestlib.new_test(testnames.throw_error_setting_nonexistent, function()
    ltestlib.assert_throws(testnames.throw_error_setting_nonexistent, function()
        latin1_utf8.some = 1
    end)
end)

testnames.throw_error_on_non_string_input = "lua-latin1-utf8 should throw error on non-string input"
ltestlib.new_test(testnames.throw_error_on_non_string_input, function()
    local convert = latin1_utf8
    local inputs = {-3.2, 1, function() end, coroutine.wrap(function() end), {}, false, true}
    for i, input in ipairs(inputs) do
        ltestlib.assert_throws(testnames.throw_error_on_non_string_input, function()
            convert(input)
        end)
    end
end)

testnames.map_sevenbit_chars = "lua-latin1-utf8 should map 7-bit characters in the range 0 - 0x7F to themselves"
ltestlib.new_test(testnames.map_sevenbit_chars, function()
    local convert = latin1_utf8
    for byte = 0, 0x7F do
        local sevenBit = string.char(byte)
        local latin1SevenBit = convert(sevenBit)
        ltestlib.assert_equal(
            testnames.map_sevenbit_chars,
            convert(sevenBit),
            convert(latin1SevenBit)
        )
    end
end)

testnames.case_sensitive = "lua-latin1-utf8 should be case-sensitive"
ltestlib.new_test(testnames.case_sensitive, function()
    local convert = latin1_utf8
    for byte = 0xC0, 0xD6 do
        local upperCase = string.char(byte)
        local lowerCase = string.char(byte + 0x20)
        ltestlib.assert_not_equal(
            testnames.case_sensitive,
            convert(upperCase),
            convert(lowerCase)
        )
    end
    for byte = 0xD8, 0xDE do
        local upperCase = string.char(byte)
        local lowerCase = string.char(byte + 0x20)
        ltestlib.assert_not_equal(
            testnames.case_sensitive,
            convert(upperCase),
            convert(lowerCase)
        )
    end
end)

testnames.match_iconv_output = "lua-latin1-utf8 should match iconv output for each single-byte character (0 - 0xFF)"
ltestlib.new_test(testnames.match_iconv_output, function()
    local convert = latin1_utf8
    for byte = 0, 0xFF do
        local inputString = string.char(byte)
        local results = getConversionResults(inputString, iconv, convert)
        ltestlib.assert_equal(
            testnames.match_iconv_output,
            results.expected,
            results.got
        )
    end
end)

testnames.match_iconv_output_for_usage_on_readme = "lua-latin1-utf8 should match iconv output for the statement in the usage section of the README"
ltestlib.new_test(testnames.match_iconv_output_for_usage_on_readme, function()
    local convert = latin1_utf8

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
    ltestlib.assert_equal(
        testnames.match_iconv_output_for_usage_on_readme,
        results.expected,
        results.got
    )
end)

-- execute the tests
ltestlib.execute()

-- collect statistics
-- and print the summary of execution
ltestlib.summary()

-- finish all the tests
-- returning the execution code
ltestlib.finish()