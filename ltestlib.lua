--========================================================================================
-- LICENSE (public domain)                                                              --
--========================================================================================
--                                                                                      --
-- This is free and unencumbered software released into the public domain.              --
--                                                                                      --
-- Anyone is free to copy, modify, publish, use, compile, sell, or                      --
-- distribute this software, either in source code form or as a compiled                --
-- binary, for any purpose, commercial or non-commercial, and by any                    --
-- means.                                                                               --
--                                                                                      --
-- In jurisdictions that recognize copyright laws, the author or authors                --
-- of this software dedicate any and all copyright interest in the                      --
-- software to the public domain. We make this dedication for the benefit               --
-- of the public at large and to the detriment of our heirs and                         --
-- successors. We intend this dedication to be an overt act of                          --
-- relinquishment in perpetuity of all present and future rights to this                --
-- software under copyright law.                                                        --
--                                                                                      --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,                      --
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                   --
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.               --
-- IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR                    --
-- OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,                --
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR                --
-- OTHER DEALINGS IN THE SOFTWARE.                                                      --
--                                                                                      --
-- For more information, please refer to <https://unlicense.org/>                       --
--                                                                                      --
--========================================================================================
-- LICENSE (MIT) on countries that refuse public domain                                 --
--========================================================================================
--                                                                                      --
-- The MIT License (MIT)                                                                --
--                                                                                      --
-- Copyright (c) 2026 ltestlib contributors https://github.com/luau-project/ltestlib    --
--                                                                                      --
-- Permission is hereby granted, free of charge, to any person obtaining a copy         --
-- of this software and associated documentation files (the "Software"), to deal        --
-- in the Software without restriction, including without limitation the rights         --
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell            --
-- copies of the Software, and to permit persons to whom the Software is                --
-- furnished to do so, subject to the following conditions:                             --
--                                                                                      --
-- The above copyright notice and this permission notice shall be included in all       --
-- copies or substantial portions of the Software.                                      --
--                                                                                      --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR           --
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,             --
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE          --
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER               --
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,        --
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE        --
-- SOFTWARE.                                                                            --
--                                                                                      --
--========================================================================================
-- NOTES                                                                                --
--========================================================================================
--                                                                                      --
-- This file (library) was initially created by luau-project                            --
-- [https://github.com/luau-project/ltestlib](https://github.com/luau-project/ltestlib) --
--                                                                                      --
-- The intent of this file is to provide a minimal                                      --
-- and rudimentary test library for Lua projects without any dependencies.              --
-- Moreover, the main goal of this library is to be used                                --
-- in a drag-and-drop style. This means that you can drop it                            --
-- on your own project, then start to use it immediately.                               --
--                                                                                      --
-- * No need to give credits;                                                           --
-- * No warranties of any kind;                                                         --
-- * Use at your own risk.                                                              --
--                                                                                      --
--========================================================================================

local version = "0.0.1"

local results = {
    order = {},
    t = {},
    executed = false
}

local function get_test(tn)
    return results.t[tn]
end

local function set_test_empty(tn, f)
    results.t[tn] = {
        execution_failed = 0,
        assertions_failed = 0,
        assertions_passed = 0,
        f = f,
        msg = {},
        logs = {}
    }
end

local function assertion_passed(tn)
    local t = get_test(tn)
    t.assertions_passed = t.assertions_passed + 1
end

local function assertion_failed(tn, msg)
    local t = get_test(tn)
    t.assertions_failed = t.assertions_failed + 1
    table.insert(t.msg, msg)
end

local function new_test(tn, f)
    if (get_test(tn) ~= nil) then
        error("Test already exists.", 2)
    end
    set_test_empty(tn, f)
    table.insert(results.order, tn)
end

local function assert_equal(tn, expected, value, msg)
    if (expected == value) then
        assertion_passed(tn)
    else
        assertion_failed(tn, msg or ("EQUAL assertion failed: Expected (%s) is not equal to what we Got (%s)"):format(tostring(expected), tostring(value)))
    end
end

local function assert_not_equal(tn, expected, value, msg)
    if (expected == value) then
        assertion_failed(tn, msg or ("NOT EQUAL assertion failed: Expected (%s) is equal to what we Got (%s)"):format(tostring(expected), tostring(value)))
    else
        assertion_passed(tn)
    end
end

local function assert_throws(tn, f, msg)
    assert(type(f) == "function", "`f' must be a (callback) function")
    local ok, err = pcall(f)
    if (ok) then
        assertion_failed(tn, msg or "THROWS assertion failed: Expected to throw.")
    else
        assertion_passed(tn)
    end
end

local function assert_true(tn, value, msg)
    assert_equal(tn, true, value, msg)
end

local function assert_false(tn, value, msg)
    assert_equal(tn, false, value, msg)
end

local function log(tn, ...)
    local t = get_test(tn)
    local varargs = { ... }
    local n = #varargs
    if (n > 0) then
        local msglist = {}
        for i, msg in ipairs(varargs) do
            table.insert(msglist, tostring(msg))
        end
        table.insert(t.logs, table.concat(msglist, "\t"))
    else
        table.insert(t.logs, "")
    end
end

local function logfmt(tn, msg, ...)
    local t = get_test(tn)
    table.insert(t.logs, tostring(msg):format(...))
end

local function execute()
    assert(not (results.executed), "You cannot execute twice. Please, call the `reset' method first to start a clean session.")
    print()
    print("======================== Start of Execution ========================")
    print()
    results.executed = true
    local total_execution_failed = 0
    local total_tests_passed = 0
    local total_tests_failed = 0
    local total_assertions_passed = 0
    local total_assertions_failed = 0
    local log10 = math.log10
    if (log10 == nil) then
        local l10 = math.log(10)
        log10 = function(x)
            return ((math.log(x)) / l10)
        end
    end

    for i, tn in ipairs(results.order) do
        local t = get_test(tn)
        local ok, err = pcall(t.f)
        if (not ok) then
            total_execution_failed = total_execution_failed + 1
            total_tests_failed = total_tests_failed + 1
            t.execution_failed = t.execution_failed + 1
            if (err ~= nil) then
                table.insert(t.msg, tostring(err))
            end
        end
        if (t.assertions_failed > 0) then
            total_tests_failed = total_tests_failed + 1
            if (t.execution_failed > 0) then
                total_tests_failed = total_tests_failed - 1
            end
            total_assertions_failed = total_assertions_failed + t.assertions_failed
            print(("[%d][Failed]: %s"):format(i, tn))

            for j, m in ipairs(t.msg) do
                print(("\t[%d] %s"):format(j, m))
            end
        else
            if (t.assertions_passed > 0) then
                total_tests_passed = total_tests_passed + 1
                total_assertions_passed = total_assertions_passed + t.assertions_passed
            end
            print(("[%d][%s]: %s"):format(i, ((t.execution_failed > 0) and "Failed") or "Passed", tn))
        end

        local nlogs = #(t.logs)
        if (nlogs > 0) then
            local nlogsdigits = math.ceil((log10(nlogs)) + 0.1)
            local jfmt = "0" .. tostring(nlogsdigits)
            local jlogfmt = ("\t[%%%sd][Log] %%s"):format(jfmt)

            for j, m in ipairs(t.logs) do
                print(jlogfmt:format(j, m))
            end
        end
    end
    print()
    print("========================= End of Execution =========================")
    print()
end

local function summary()
    print()
    print("========================= Start of Summary =========================")
    print()
    local total_execution_failed = 0
    local total_tests_passed = 0
    local total_tests_failed = 0
    local total_assertions_passed = 0
    local total_assertions_failed = 0
    for i, tn in ipairs(results.order) do
        local t = get_test(tn)
        if (t.execution_failed > 0) then
            total_execution_failed = total_execution_failed + 1
            total_tests_failed = total_tests_failed + 1
        end
        if (t.assertions_failed > 0) then
            total_tests_failed = total_tests_failed + 1
            if (t.execution_failed > 0) then
                total_tests_failed = total_tests_failed - 1
            end
            total_assertions_failed = total_assertions_failed + t.assertions_failed
        else
            if (t.assertions_passed > 0) then
                total_tests_passed = total_tests_passed + 1
                total_assertions_passed = total_assertions_passed + t.assertions_passed
            end
        end
    end
    local total_tests_executed = total_tests_failed + total_tests_passed
    if (total_tests_executed == 0) then
        total_tests_executed = 1
    end
    local total_tests_failed_ratio = total_tests_failed / total_tests_executed
    local total_tests_passed_ratio = total_tests_passed / total_tests_executed
    local total_assertions_executed = total_assertions_failed + total_assertions_passed
    if (total_assertions_executed == 0) then
        total_assertions_executed = 1
    end
    local total_assertions_failed_ratio = total_assertions_failed / total_assertions_executed
    local total_assertions_passed_ratio = total_assertions_passed / total_assertions_executed
    print(("Tests Executed: %d"):format(total_tests_failed + total_tests_passed))
    print(("\tTests Passed: %d (%.1f%%)"):format(total_tests_passed, total_tests_passed_ratio * 100))
    print(("\tTests Failed: %d (%.1f%%)"):format(total_tests_failed, total_tests_failed_ratio * 100))
    print()
    print(("Assertions Executed: %d"):format(total_assertions_failed + total_assertions_passed))
    print(("\tAssertions Passed: %d (%.1f%%)"):format(total_assertions_passed, total_assertions_passed_ratio * 100))
    print(("\tAssertions Failed: %d (%.1f%%)"):format(total_assertions_failed, total_assertions_failed_ratio * 100))
    print()
    print("========================== End of Summary ==========================")
    print()

    return {
        total_execution_failed = total_execution_failed,
        total_tests_passed = total_tests_passed,
        total_tests_failed = total_tests_failed,
        total_tests_passed_ratio = total_tests_passed_ratio,
        total_tests_failed_ratio = total_tests_failed_ratio,
        total_assertions_passed = total_assertions_passed,
        total_assertions_failed = total_assertions_failed,
        total_assertions_passed_ratio = total_assertions_passed_ratio,
        total_assertions_failed_ratio = total_assertions_failed_ratio
    }
end

local function finish()
    for i, tn in ipairs(results.order) do
        local t = get_test(tn)
        if ((t.execution_failed > 0) or (t.assertions_failed > 0)) then
            os.exit(1)
            return
        end
    end
end

local function reset()
    local order = results.order
    local n = #order
    for i = n, 1, -1 do
        table.remove(order, i)
    end
    results.executed = false
    results.t = {}
end

local methods = {
    new_test = new_test,
    assert_equal = assert_equal,
    assert_not_equal = assert_not_equal,
    assert_throws = assert_throws,
    assert_true = assert_true,
    assert_false = assert_false,
    log = log,
    logfmt = logfmt,
    execute = execute,
    summary = summary,
    reset = reset,
    finish = finish,
    version = version
}

return setmetatable({}, {
    __index = methods,
    __newindex = function(s, k, v) error("Read-only testlib", 2) end,
    __metatable = false
})
