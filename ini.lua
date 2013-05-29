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

        -- comment
        if line:match("^#") then
            return true
        end

        return false
    end

    for line in file:lines() do
        i = i + 1
        if not parse(line) then
            rejected[i] = line
        end
    end
    file:close()
    return data, rejected
end

local function read_nested(file)
    if not Path.isfile(file) then return nil end

     -- map regex -> handler
    local map = {}

    -- comments
    map["^#"] = function () return end

    -- section opening
    map["^[%s]*%[([^/.]+)%]$"] = 
        function(matches, parent)
            if not parent[#parent][matches[1]] then
                parent[#parent][matches[1]] = {}
            end
            table.insert(parent, parent[#parent][matches[1]])
        end

    -- section closing. 
    map["^[%s]*%[/%]$"] = 
        function(matches, parent)
            table.remove(parent)
        end
    map["^[%s]*%[/.*%]$"] = map["^[%s]*%[/%]$"] 

    -- kv-pair
    map["^[%s]*([%w]+)=(.*)$"] = 
        function(matches, parent)
            parent[#parent][matches[1]] = matches[2]
        end

    local file = io.open(file, "r")
    local data = {}
    local parent = { data }
    local rejected = {}
    local matches
    local i = 0
    local line_processed = false

    for line in file:lines() do
        i = i + 1
        line_processed = false

        for regex,handler in pairs(map) do
            matches = { string.match(line, regex) }
            if matches[1] then 
                handler(matches, parent)
                line_processed = true
                break
            end
        end

        if not line_processed then
            rejected[i] = line
        end
    end
    
    file:close()
    return data, rejected
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

print(write("./output.ini", { CategoryA={ somekey="somevalue" }, CategoryB={ anotherkey="canothervalue", number=42 } }))
local a,b = read("output.ini")
print(write("outputcopy.ini", a))

print(write_nested("outnested.ini", { A={ a="hello World!", sub={ b="hello universe!"} }, B={ somekey=42 } }))
local c,d = read("outnested.ini")
print(write_nested("outnested2.ini", c))


return { read = read, read_nested = read_nested }
