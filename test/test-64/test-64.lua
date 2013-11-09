local sep = package.config:sub(1,1)
package.path = string.format("..%s..%s?.lua;", sep, sep) .. package.path
--

local ini = require("ini")

local data = {
    main={
        bitmask = 0xdc95afbc,
    }
}

local mt = debug.getmetatable(data.main.bitmask) or {}
mt.__ini_is_binary = true
debug.setmetatable(data.main.bitmask, mt)

ini.write64("test-64.0.ini", data)
local b = ini.read64("test-64.0.ini")
ini.write64("test-64.1.ini", b)
