#!/usr/bin/lua
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

return { read = read, read_nested = read_nested, write = write, write_nested = write_nested, debug = { enum = debug_enum } }
