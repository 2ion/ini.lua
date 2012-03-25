#!/usr/bin/lua
--[[
    R/W access to .INI style configuration files
    Written by Jens Oliver John <jens.o.john.at.gmail.com>
    Licensed under the GNU General Public License v3.
    This program is just a quick hack and nothing solid.

    Demo:
    require("ini")
    T = ini:new()
    T:write("TEST.INI", { general = { A = "42" }, bofh = { conf = 0 }})
    S = T:read("TEST.INI")
    -- print table
    function pt(t)
        for k,v in pairs(t) do
            if type(v)=="table" then
                print("["..k.."]")
                pt(v)
            else
                print(k,v)
            end
        end
    end
    pt(S)
--]]

ini = {}

function ini:new()
    local i = {}
    setmetatable(i, self)
    self.__index = self
    return i
end

function ini:parse()
    if not self.handle then return nil end
    self.data = {}
    local parent = self.data
    local match, smatch
    local lineno = 0
    for line in self.handle:lines() do
        lineno = lineno + 1
        match = string.match(line, "^%[(.+)%]$")
        if match then
            self.data[match] = {}
            parent = self.data[match]
        else
            match, smatch = string.match(line, "^([%w]+)[%s]*=[%s]*([%w]*)$")
            if not match then
                self:error("Line " .. lineno .. ": invalid syntax: <" .. line .. ">.")
            else
                parent[match] = smatch
            end
        end
    end
end

function ini:read(path)
    self:open(path, "r")
    self:parse()
    self:close()
    return self.data
end

function ini:write(path, data)
    local path = path or self.path
    local data = data or self.data
    if self.handle then
        self.handle_tmp = self.handle
    end
    self:open(path, "w")
    local function write_table(t)
        for k,v in pairs(t) do
            if type(v) == "table" then
                self.handle:write("["..tostring(k).."]\n")
                write_table(t[k])
            else
                self.handle:write(tostring(k).."="..tostring(v).."\n")
            end
        end
    end
    write_table(data)
    self.handle:close()
    self.handle = self.handle_tmp or nil
end

function ini:error(log)
    self.log = self.log or {}
    table.insert(self.log, { self.path, log })
end

function ini:close()
    if self.handle then
        self.handle:close()
        self.handle = nil
    end
end

function ini:open(path, mode)
    self.handle = io.open(path, mode or "r")
    self.path = path
    return self.handle or nil
end
