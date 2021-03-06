# ini.lua

This README references: version 2.1

This script implements a parser mapping .ini style configuration files to Lua
tables and vice versa.

The current release v2.1 is a DEVELOPMENT release. See the Changelog for
changes relative to the 2.0 release.

Stable releses are all releases with an even minor version number
(currently: 2.0).

# Installation

Make sure all dependencies are installed (-> DEPENDENCIES.

```shell
# clone the repository
git clone https://github.com/2ion/ini.lua.git lua-ini && cd lua-ini

# should exit without errors
make test doc
```

If the tests ran successfully, you can take the module `ini.lua` from
the repository and put it wherever you want -> "installed".

## Dependencies

* LuaJIT
* lua-penlight's pl.path module
* libb64 (http://libb64.sourceforge.net/)

# INI format

I briefly describe the format ini.lua supports as of now.

## Flat INI files

* Flat INI files don't have nested sections
* Section names may consist of any character as in the [.]
  Lua regex symbol
* Key names must not contain the = character and spaces [%s], values may contain any
  character in [.].
* EXCEPTION: if the read64/write64() API is used, Lua strings holding
  arbitrary binary values may be passed.
* Key names must not be preceeded by any [%s].
* Lines beginning with # and empty lines will be ignored

Example file:

```ini
[SectionA]
key1=value1 with some spaces and punctuation =)(!/_%@

[Section2]
key2=value2
```

## Nested INI files

The flat format applies, with the following extensions:

* Sections may be nested
* Section names must not contain the / character
* The last section in a file is not required to be closed
* Sections are closed with a [/$section] element
* Sections must be closed in the same order they were opened
* Section openings and closings as well as key names may be preceeded by
  [%s]*

Example file:

```ini
[Section10]
k=v
a=2
    [Section11]
    k=a
    a=3
    [/Section11]
lastword=World
[/Section10]

[nichts]
jp=nanimo
[/nichts]
```

# API

* Every key and value to be written must be convertable to a string
  using tostring()
* No extensive error checking yet
* No autodetection of nested/unnested file format yet

```lua
local ini = require("ini")

ini.read(infile)
ini.write(outfile, data)

ini.read_nested(infile)
ini.write_nested(outfile, data)
```

```lua

--- Flat INI files

-- The table format as passed to write(), and returned by read()
local data = { SectionA = { key1 = "value1" }, Section2 = { key2 = "value2" } }

-- write(outfile, datatable)
-- returns NIL if outfile couldn't be opened, otherwise true

ini.write("flat.ini", data)

-- read(infile)
-- returns:
--  in case of success: <data table>, <list of rejected/ungrammatical lines' line numbers>
--  in case of failure, #<data table> == 0 or
--                      NIL if infile couldn't be opened.
local data, rejected = read(outfile)

--- Nested INI files
-- The API works the same, but the table format can hold nested tables
data = { SecA = { SecAB = { a=1 } } }

-- writing:
ini.write_nested(outfile, data)
data, rejected = ini.read_nested(outfile)
```

# read64/write64

This API works analog to the unnested read/write API, except for the
following changes:

* All values with a metatable holding a key __ini_is_binary which
  evaluates as true will be stored in a base64 encoded form.
* If a non-base64 value begins with the sequence "base64:", it will be
  parsed as base64. This is a limitation and will be fixed in the
  upcoming 2.2 release.
* read64() will produce data tables with all the necessary metatables in
  place.

Example:

```lua
local ini = require("ini")
local data = {
    DATA = {
        bin = 0xaf6723dc
    },
    STRINGS = {
        str = "Hello World!"
    }
}

-- setting a metatable for non-table data types requires the debug
-- library!
debug.setmetatable(data.DATA.bin, { __ini_is_binary = true })

ini.write64("test.ini", data)

-- is equivalent to the data referenced by $data
local d = ini.read64("test.ini")
```

# ```read_typed/write_typed```

This is the logical extension of the read64/write64 API, to which it
adds the ability to preserve in addition to the base64 binary data type
all native Lua data types minus table and user data, meaning your
strings, numbers, boolean, or binary data can be stored and read without
losing any type information.

Example:

```lua
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
        y = 22.1,
        ishere = true
    }
}

ini.write_typed("test-typed.0.ini", data)
local b = ini.read_typed("test-typed.0.ini")
ini.write_typed("test-typed.1.ini", b)

-- test-typed.{0,1}.ini contain exactly the same data.
-- the data returned from ini.read_typed(...) is equivalent to the
-- data stored in the input `data` table.
```

# Documentation

This README.

Additionally, there is  a (at this point basic) HTML documentation
generated using LuaDoc in the doc directory. It may be re-generated by
issueing the `make doc` command.  This requires LuaDoc to be installed. 

# License

```
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
```

