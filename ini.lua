#!/usr/bin/lua
--[[
    R/W access to .INI style configuration files
    Written by Jens Oliver John <jens.o.john.at.gmail.com>
    Licensed under the GNU General Public License v3.
    This program is just a quick hack and nothing solid.
--]]

-- Test for Lua 5.2
if setfenv then
    error("ini.lua requires Lua >= 5.2 because of goto statements.")
end

-- Returns a new ini object
-- $1: The object may be initialized with a file path $1.
ini = {}
function ini:new(path)
    local i = {}
    setmetatable(i, self)
    self.__index = self
    if path then self.path = path end
    return i
end

-- Parses the file self.path points to as an INI file.
-- Returns nil on failure and true on success.
-- The file will be processed line by line. Line-specific parsing errors will be
-- logged to the table at self.log in { ini-filepath, error-description }
-- format.
-- Data will be committed to self.data. INI syntax maps as follows:
--
-- [sectionname]
-- key=value
-- #somecomment
--
-- becomes tostring(sectionname) = { tostring(key) = tostring(value) }
-- effectively. Lines starting with # will be ignored.
-- Each subsequent section overrides the previous section.
-- Sections cannot be nested.
function ini:parse()
    if not self.handle then return nil end
    self.data = {}
    local parent = self.data
    local match, smatch
    local lineno = 0
    for line in self.handle:lines() do
        lineno = lineno + 1
        match = string.match(line, "^#.*$")
        if match then goto continue end
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
        ::continue::
    end
    return true
end

function ini:parseNested()
    -- mapping regex -> handler
    local tree = {}
    tree["^[%s]*#.*$"] =
        function (matches, parent, lineno) 
            return 
        end

    tree["^[%s]*%[(.+)%]$"] = 
        function(matches, parent, lineno)
            if not parent[#parent][matches[1]] then
                parent[#parent][matches[1]] = {}
            end
            table.insert(parent, parent[#parent][matches[1]])
        end

    tree["^[%s]*%[/%]$"] = 
        function(matches, parent, lineno)
            table.remove(parent)
        end
    tree["^[%s]*%[/.*%]$"] = tree["^[%s]*%[/%]$"] 

    tree["^[%s]*([%w]+)[%s]*=[%s]*([%w]*)$"] = 
        function(matches, parent, lineno)
            parent[#parent][matches[1]] = matches[2]
        end

    self.data = {}
    local parent = { self.data }
    local matches
    local lineno = 0
    local line_processed = false
    for line in self.handle:lines() do
        lineno = lineno + 1
        for regex,handler in pairs(tree) do
            matches = { string.match(line, regex) }
            if matches[1] then 
                handler(matches, parent, lineno)
                line_processed = true
                goto continue
            end
        end
        ::continue::
        if not line_processed then
            self:error("Line " .. lineno .. ": error: Could not parse, because no pattern matched.")
        else
            line_processed = false
        end
    end
end

-- Parse the ini file at path or self.path and return the resulting table and
-- error log.
function ini:read(path, isNested)
    self.path = path or self.path
    self:open(self.path, "r")
    if isNested then
        self:parse()
    else
        self:parseNested()
    end
    self:close()
    return self.data, self.log
end

-- Write the data in a Lua table data or self.data to an INI file at path or
-- self.path.
-- Eventually opened INI file handles at self.handle will not be affected.
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

-- Commit an error message log to self.log
function ini:error(log)
    self.log = self.log or {}
    table.insert(self.log, { self.path, log })
end

-- Close eventually open file handles.
function ini:close()
    if self.handle then
        self.handle:close()
        self.handle = nil
    end
end

-- Open a file at path in access mode mode.
-- Mode defaults to "r".
-- Will set self.path and self.handle if successful.
-- Returns self.handle or nil.
function ini:open(path, mode)
    self.handle = io.open(path, mode or "r")
    self.path = path
    return self.handle or nil
end
