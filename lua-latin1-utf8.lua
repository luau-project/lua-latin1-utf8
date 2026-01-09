-- The MIT License (MIT)
--
-- Copyright (c) 2026 luau-project
--                    [https://github.com/luau-project/lua-latin1-utf8](https://github.com/luau-project/lua-latin1-utf8)
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local VERSION = "0.0.1"

local NULL_CHAR = "\0"

local UTF8_TABLE = {
	"\1",
	"\2",
	"\3",
	"\4",
	"\5",
	"\6",
	"\7",
	"\8",
	"\9",
	"\10",
	"\11",
	"\12",
	"\13",
	"\14",
	"\15",
	"\16",
	"\17",
	"\18",
	"\19",
	"\20",
	"\21",
	"\22",
	"\23",
	"\24",
	"\25",
	"\26",
	"\27",
	"\28",
	"\29",
	"\30",
	"\31",
	"\32",
	"\33",
	"\34",
	"\35",
	"\36",
	"\37",
	"\38",
	"\39",
	"\40",
	"\41",
	"\42",
	"\43",
	"\44",
	"\45",
	"\46",
	"\47",
	"\48",
	"\49",
	"\50",
	"\51",
	"\52",
	"\53",
	"\54",
	"\55",
	"\56",
	"\57",
	"\58",
	"\59",
	"\60",
	"\61",
	"\62",
	"\63",
	"\64",
	"\65",
	"\66",
	"\67",
	"\68",
	"\69",
	"\70",
	"\71",
	"\72",
	"\73",
	"\74",
	"\75",
	"\76",
	"\77",
	"\78",
	"\79",
	"\80",
	"\81",
	"\82",
	"\83",
	"\84",
	"\85",
	"\86",
	"\87",
	"\88",
	"\89",
	"\90",
	"\91",
	"\92",
	"\93",
	"\94",
	"\95",
	"\96",
	"\97",
	"\98",
	"\99",
	"\100",
	"\101",
	"\102",
	"\103",
	"\104",
	"\105",
	"\106",
	"\107",
	"\108",
	"\109",
	"\110",
	"\111",
	"\112",
	"\113",
	"\114",
	"\115",
	"\116",
	"\117",
	"\118",
	"\119",
	"\120",
	"\121",
	"\122",
	"\123",
	"\124",
	"\125",
	"\126",
	"\127",
	"\194\128",
	"\194\129",
	"\194\130",
	"\194\131",
	"\194\132",
	"\194\133",
	"\194\134",
	"\194\135",
	"\194\136",
	"\194\137",
	"\194\138",
	"\194\139",
	"\194\140",
	"\194\141",
	"\194\142",
	"\194\143",
	"\194\144",
	"\194\145",
	"\194\146",
	"\194\147",
	"\194\148",
	"\194\149",
	"\194\150",
	"\194\151",
	"\194\152",
	"\194\153",
	"\194\154",
	"\194\155",
	"\194\156",
	"\194\157",
	"\194\158",
	"\194\159",
	"\194\160",
	"\194\161",
	"\194\162",
	"\194\163",
	"\194\164",
	"\194\165",
	"\194\166",
	"\194\167",
	"\194\168",
	"\194\169",
	"\194\170",
	"\194\171",
	"\194\172",
	"\194\173",
	"\194\174",
	"\194\175",
	"\194\176",
	"\194\177",
	"\194\178",
	"\194\179",
	"\194\180",
	"\194\181",
	"\194\182",
	"\194\183",
	"\194\184",
	"\194\185",
	"\194\186",
	"\194\187",
	"\194\188",
	"\194\189",
	"\194\190",
	"\194\191",
	"\195\128",
	"\195\129",
	"\195\130",
	"\195\131",
	"\195\132",
	"\195\133",
	"\195\134",
	"\195\135",
	"\195\136",
	"\195\137",
	"\195\138",
	"\195\139",
	"\195\140",
	"\195\141",
	"\195\142",
	"\195\143",
	"\195\144",
	"\195\145",
	"\195\146",
	"\195\147",
	"\195\148",
	"\195\149",
	"\195\150",
	"\195\151",
	"\195\152",
	"\195\153",
	"\195\154",
	"\195\155",
	"\195\156",
	"\195\157",
	"\195\158",
	"\195\159",
	"\195\160",
	"\195\161",
	"\195\162",
	"\195\163",
	"\195\164",
	"\195\165",
	"\195\166",
	"\195\167",
	"\195\168",
	"\195\169",
	"\195\170",
	"\195\171",
	"\195\172",
	"\195\173",
	"\195\174",
	"\195\175",
	"\195\176",
	"\195\177",
	"\195\178",
	"\195\179",
	"\195\180",
	"\195\181",
	"\195\182",
	"\195\183",
	"\195\184",
	"\195\185",
	"\195\186",
	"\195\187",
	"\195\188",
	"\195\189",
	"\195\190",
	"\195\191"
}

--- Converts a ISO-8859-1
-- character (\0 - \255)
-- to the corresponding UTF-8
-- sequence.
-- @param c the character to convert.
-- @return the resulting UTF-8 sequence.
local function charConverter(c)
    local result = NULL_CHAR
    local b = c:byte(1, 1)
    if (b ~= 0) then
        result = UTF8_TABLE[b]
    end
    return result
end

--- Converts a string from
-- ISO-8859-1 to UTF-8.
-- @string s the string to convert.
-- @return the resulting UTF-8 string.
local function convert(s)
    local ts = type(s)
    if (ts ~= "string") then
        error(("bad #1 argument (string expected, but got `%s')."):format(ts), 2)
    end
    return (s:gsub(".", charConverter))
end

return setmetatable({}, {
    __index = function(self, key)
        local result = nil
        if (key == "version") then
            result = VERSION
        else
            result = rawget(self, key)
        end
        return result
    end,
    __newindex = function(self, key, value)
        error("This module is readonly", 2)
    end,
    __metatable = false,
    __call = function(self, s)
        return convert(s)
    end
})
