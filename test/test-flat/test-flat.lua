local sep = package.config:sub(1,1)
package.path = string.format("..%s..%s?.lua;", sep, sep) .. package.path
--
local ini = require("ini")

local data = {
    Time = {
        hour = 6,
        minute = 50,
        second = 13,
        milliseconds = 493,
        day = "Mo",
        month = "Nov"
    },
    Location = {
        x = 14.4,
        y = 22.1
    }
}

ini.write("test-flat.0.ini", data)
local b = ini.read("test-flat.0.ini")
ini.write("test-flat.1.ini", b)
