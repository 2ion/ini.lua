#!/usr/bin/luajit
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

local ffi = require("ffi")

ffi.cdef([[
enum base64_encodestep
{
	step_A, step_B, step_C
};

struct base64_encodestate 
{
	enum base64_encodestep step;
	char result;
	int stepcount;
};

void base64_init_encodestate(struct base64_encodestate* state_in);
char base64_encode_value(char value_in);
int base64_encode_block(const char* plaintext_in, int length_in,
    char* code_out, struct base64_encodestate* state_in);
int base64_encode_blockend(char* code_out, struct base64_encodestate* state_in);

enum base64_decodestep { step_a, step_b, step_c, step_d };
struct base64_decodestate { enum base64_decodestep step; char plainchar; };

void base64_init_decodestate(struct base64_decodestate* state_in);
int base64_decode_value(char value_in);
int base64_decode_block(const char* code_in, const int length_in,
    char* plaintext_out, struct base64_decodestate* state_in);
]])

local b64 = ffi.load("libb64.so.0d")

local function base64_encode(str)
    local len = #str + 1 -- we also encode empty strings
    local inbuf = ffi.new("char[?]", len, str)
    local inlen = ffi.new("int", len)
    local buf = ffi.new("char[?]", 2*len)
    local state = ffi.new("struct base64_encodestate[1]")
    local cnt = 0

    b64.base64_init_encodestate(state)
    cnt = b64.base64_encode_block(inbuf, inlen, buf, state)

    return ffi.string(buf), cnt
end

local function base64_decode(b64str)
    local len = #b64str + 1
    local inbuf = ffi.new("char[?]", len, b64str)
    local inlen = ffi.new("int", len)
    local buf = ffi.new("char[?]", len)
    local state = ffi.new("struct base64_decodestate[1]")

    b64.base64_init_decodestate(state)
    local cnt = b64.base64_decode_block(inbuf, inlen, buf, state)

    return ffi.string(buf), cnt
end
