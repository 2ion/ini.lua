# ini.lua

This script implements a parser mapping .ini style configuration files to Lua
tables and vice versa.

# INI format

I briefly describe the format ini.lua supports as of now.

## Flat INI files

* Flat INI files don't have nested sections
* Section names may consist of any character as in the [.]
  Lua regex symbol
* Key names must not contain the = character and spaces [%s], values may contain any
  character in [.]
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

```lua

local ini = require("ini")

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

# Dependencies

* Lua >= 5.1 (probably)
* lua-penlight's pl.path module

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

