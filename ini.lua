#!/usr/bin/luajit
--[[
    ini.lua - read/write access to INI files in Lua
    Copyright (C) 2013 Jens Oliver John <asterisk@2ion.de>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Project home: <https://github.com/2ion/ini.lua>
--]]

local Path = require("pl.path")
local ffi = require("ffi")

ffi.cdef([[
enum base64_encodestep
{
	step_A, step_B, step_C
};

struct base64_encodestate 
{
	enum base64_encodestep step;
	char result;
	int stepcount;
};

void base64_init_encodestate(struct base64_encodestate* state_in);
char base64_encode_value(char value_in);
int base64_encode_block(const char* plaintext_in, int length_in,
    char* code_out, struct base64_encodestate* state_in);
int base64_encode_blockend(char* code_out, struct base64_encodestate* state_in);

enum base64_decodestep { step_a, step_b, step_c, step_d };
struct base64_decodestate { enum base64_decodestep step; char plainchar; };

void base64_init_decodestate(struct base64_decodestate* state_in);
int base64_decode_value(char value_in);
int base64_decode_block(const char* code_in, const int length_in,
    char* plaintext_out, struct base64_decodestate* state_in);
]])

local b64 = ffi.load("libb64.so.0d")

local function base64_encode(str)
    local str = type(str) == "string" and str or tostring(str)
    local len = #str + 1 -- we also encode empty strings
    local inbuf = ffi.new("char[?]", len, str)
    local inlen = ffi.new("int", len)
    local buf = ffi.new("char[?]", 2*len)
    local state = ffi.new("struct base64_encodestate[1]")
    local cnt = 0

    b64.base64_init_encodestate(state)
    cnt = b64.base64_encode_block(inbuf, inlen, buf, state)

    return ffi.string(buf), cnt
end

local function base64_decode(b64str)
    local len = #b64str + 1
    local inbuf = ffi.new("char[?]", len, b64str)
    local inlen = ffi.new("int", len)
    local buf = ffi.new("char[?]", len)
    local state = ffi.new("struct base64_decodestate[1]")

    b64.base64_init_decodestate(state)
    local cnt = b64.base64_decode_block(inbuf, inlen, buf, state)

    return ffi.string(buf), cnt
end

local function debug_enum(t, section)
    for k,v in pairs(t) do
        if type(v) == "table" then
            debug_enum(v, tostring(k))
        else
            print(section or "", k, "", "",v)
        end
    end
end

local function read(file)
    if not Path.isfile(file) then return nil end
   
    local file = io.open(file, "r")
    local data = {}
    local rejected = {}
    local parent = data
    local i = 0
    local m, n

    local function parse(line)
        local m, n

        -- kv-pair
        m,n = line:match("^([%w%p]-)=(.*)$")
        if m then
            parent[m] = n
            return true
        end

        -- section opening
        m = line:match("^%[([%w%p]+)%][%s]*")
        if m then
            data[m] = {}
            parent = data[m]
            return true
        end

        if line:match("^$") then
            return true
        end

        -- comment
        if line:match("^#") then
            return true
        end

        return false
    end

    for line in file:lines() do
        i = i + 1
        if not parse(line) then
            table.insert(rejected, i)
        end
    end
    file:close()
    return data, rejected
end

local function read64(file)
    if not Path.isfile(file) then return nil end
   
    local file = io.open(file, "r")
    local data = {}
    local rejected = {}
    local parent = data
    local i = 0
    local m, n

    local function parse(line)
        local m, n

        -- kv-pair
        m,n = line:match("^([%w%p]-)=(.*)$")
        if m then
            if n:match("^base64:") then
                local n = n:match("^base64:(.*)")
                local v = base64_decode(n)
                local mt = getmetatable(v)
                mt.__ini_is_binary = true
                parent[m] = v
            else
                parent[m] = n
            end
            return true
        end

        -- section opening
        m = line:match("^%[([%w%p]+)%][%s]*")
        if m then
            data[m] = {}
            parent = data[m]
            return true
        end

        if line:match("^$") then
            return true
        end

        -- comment
        if line:match("^#") then
            return true
        end

        return false
    end

    for line in file:lines() do
        i = i + 1
        if not parse(line) then
            table.insert(rejected, i)
        end
    end
    file:close()
    return data, rejected
end



local function read_nested(file)
    if not Path.isfile(file) then return nil end

    local file = io.open(file, "r")
    local d = {}
    local h = {}
    local r = {}
    local p = d
    local i = 0

    local function parse(line)
        local m, n

        -- section opening
        m = line:match("^[%s]*%[([^/.]+)%]$")
        if m then
            table.insert(h, { p, m=m })
            p[m] = {}
            p = p[m]
            return true
        end

        -- section closing
        m = line:match("^[%s]*%[/([^/.]+)%]$")
        if m then
            local hl = #h
            if hl == 0 or h[hl].m ~= m then
                return nil
            end
            p = table.remove(h).p
            if not p then p = d end
            return true
        end

        -- kv-pair
        m,n = line:match("^[%s]*([%w%p]-)=(.*)$")
        if m then
            p[m] = n
            return true
        end

        -- ignore empty lines
        if line:match("^$") then
            return true
        end

        -- ignore comments
        if line:match("^#") then
            return true
        end

        -- reject everything else
        return nil
    end

    for line in file:lines() do
        i = i + 1
        if not parse(line) then
            table.insert(r, i)
        end
    end

    file:close()
    return d, r
end

local function write(file, data)
    if type(data) ~= "table" then return nil end
    local file = io.open(file, "w")
    for s,t in pairs(data) do
        file:write(string.format("[%s]\n", s))
        for k,v in pairs(t) do
            file:write(string.format("%s=%s\n", tostring(k), tostring(v)))
        end
    end
    file:close()
    return true
end

local function write64(file, data)
    if type(data) ~= "table" then return nil end
    local file = io.open(file, "w")
    for s,t in pairs(data) do
        file:write(string.format("[%s]\n", s))
        for k,v in pairs(t) do
            local mt = getmetatable(v)
            if mt and mt.__ini_is_binary then
                file:write(string.format("%s=base64:%s\n", tostring(k), base64_encode(v)))
            else
                file:write(string.format("%s=%s\n", tostring(k), tostring(v)))
            end
        end
    end
    file:close()
    return true
end

local function write_nested(file, data)
    if type(data) ~= "table" then return nil end
    local file = io.open(file, "w")
    local function w(t)
        for i,j in pairs(t) do
            if type(j) == "table" then
                file:write(string.format("[%s]\n", i))
                w(j)
                file:write(string.format("[/%s]\n", i))
            else
                file:write(string.format("%s=%s\n", tostring(i), tostring(j)))
            end
        end
    end
    w(data)
    file:close()
    return true
end

return { read = read, read64 = read64, read_nested = read_nested, write = write, write64 = write64, write_nested = write_nested, debug = { enum = debug_enum } }
