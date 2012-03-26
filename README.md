# ini.lua
This script implements a parser mapping .ini style configuration files to Lua
tables and vice versa.

# Usage
<code>
\#!/usr/bin/env lua

require("ini")
T = ini:new()

-- Write to TEST.INI
T:write("TEST.INI", { general = { A = "42" }, bofh = { conf = 0 }})

-- Read back whatever went into TEST.INI
S = T:read("TEST.INI")

-- Print what we've got
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
</code>

# License
Copyright (c) 2012 Jens Oliver John

Licensed under the GNU General Public License v3.
