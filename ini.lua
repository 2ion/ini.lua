#!/usr/bin/lua
--[[
    R/W access to .INI style configuration files
    Written by Jens Oliver John <jens.o.john.at.gmail.com>
    Licensed under the GNU General Public License v3.
--]]

local Path = require("pl.path")

local function debug_print(t, section)
    for k,v in pairs(t) do
        if type(v) == "table" then
            p(v, k)
        else
            print(section or "", k,v)
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
        m,n = line:match("^([%w]-)=(.*)$")
        if m then
            parent[m] = n
            return true
        end

        -- section opening
        m = line:match("^%[(.+)%]$")
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

        m = line:match("^[%s]*%[([^/.]+)%]$")
        if m then
            table.insert(h, { p, m=m })
            p[m] = {}
            p = p[m]
            return true
        end

        m = line:match("^[%s]*%[/([^/.]+)%]$")
        if m then
            if #h == 0 or h[#h].m ~= m then
                return nil
            end
            p = table.remove(h).p
            if not p then p = d end
            return true
        end

        if line:match("[%s]*%[/%]") then
            if #h == 0 then
                return nil
            end
            p = table.remove(h).p
            return true
        end

        m,n = line:match("^[%s]*([%w]-)=(.*)$")
        if m then
            p[m] = n
            return true
        end

        if line:match("^$") then
            return true
        end

        if line:match("^#") then
            return true
        end

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

write_nested("outnested.ini", { A={ a="hello World!", sub={ b="hello universe!"} }, B={ somekey=42 } })
local c,d = read_nested("outnested.ini")
write_nested("outnested2.ini", c)


return { read = read, read_nested = read_nested }
