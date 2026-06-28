--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

--[[
  Generic byte-string <-> printable-string codec with an integrity check.

  Encode wraps the input with a 4-byte Adler-32 checksum and base64-encodes the
  result. The output uses the standard base64 alphabet (A-Z a-z 0-9 + /), none
  of which is the WoW chat escape character "|", so the string is safe to paste
  into an edit box or chat. Decode reverses it and verifies the checksum so a
  truncated or garbled paste is rejected rather than silently mis-decoded.

  Implemented with plain arithmetic (no bit library) so it runs unchanged on
  the WoW client, on LuaJIT and on stock PUC Lua 5.1 (headless busted).
]]--

local mod = rggm
local me = {}
mod.encoder = me

me.tag = "Encoder"

local BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local PAD_BYTE = 61 -- string.byte("=")
local ADLER_MOD = 65521

--[[
  Reverse lookup: base64 character byte -> 6-bit value.
]]--
local base64Lookup = {}

for index = 1, #BASE64_CHARS do
  base64Lookup[string.byte(BASE64_CHARS, index)] = index - 1
end

--[[
  Compute the Adler-32 checksum of a byte string.

  @param {string} input
  @return {number} 32-bit checksum
]]--
local function Adler32(input)
  local a = 1
  local b = 0

  for index = 1, #input do
    a = (a + string.byte(input, index)) % ADLER_MOD
    b = (b + a) % ADLER_MOD
  end

  return b * 65536 + a
end

--[[
  Encode a 32-bit number as 4 little-endian bytes.

  @param {number} value
  @return {string}
]]--
local function NumberToBytes(value)
  local byte0 = value % 256
  value = math.floor(value / 256)

  local byte1 = value % 256
  value = math.floor(value / 256)

  local byte2 = value % 256
  value = math.floor(value / 256)

  local byte3 = value % 256

  return string.char(byte0, byte1, byte2, byte3)
end

--[[
  Decode 4 little-endian bytes back into a 32-bit number.

  @param {string} input
    a string whose first 4 bytes hold the value
  @return {number}
]]--
local function BytesToNumber(input)
  local byte0, byte1, byte2, byte3 = string.byte(input, 1, 4)

  return byte0 + byte1 * 256 + byte2 * 65536 + byte3 * 16777216
end

--[[
  Base64-encode a byte string.

  @param {string} input
  @return {string}
]]--
local function Base64Encode(input)
  local out = {}
  local length = #input
  local index = 1

  while index <= length do
    local byte0 = string.byte(input, index)
    local byte1 = string.byte(input, index + 1)
    local byte2 = string.byte(input, index + 2)

    local chunk = byte0 * 65536 + (byte1 or 0) * 256 + (byte2 or 0)

    local sextet0 = math.floor(chunk / 262144) % 64
    local sextet1 = math.floor(chunk / 4096) % 64
    local sextet2 = math.floor(chunk / 64) % 64
    local sextet3 = chunk % 64

    out[#out + 1] = string.sub(BASE64_CHARS, sextet0 + 1, sextet0 + 1)
    out[#out + 1] = string.sub(BASE64_CHARS, sextet1 + 1, sextet1 + 1)
    out[#out + 1] = byte1 and string.sub(BASE64_CHARS, sextet2 + 1, sextet2 + 1) or "="
    out[#out + 1] = byte2 and string.sub(BASE64_CHARS, sextet3 + 1, sextet3 + 1) or "="

    index = index + 3
  end

  return table.concat(out)
end

--[[
  Base64-decode a string. Returns nil on any malformed input (bad length,
  invalid character, or misplaced padding).

  @param {string} input
  @return {string | nil}
]]--
local function Base64Decode(input)
  if #input % 4 ~= 0 then return nil end

  local out = {}
  local length = #input
  local index = 1

  while index <= length do
    local char0 = string.byte(input, index)
    local char1 = string.byte(input, index + 1)
    local char2 = string.byte(input, index + 2)
    local char3 = string.byte(input, index + 3)

    local isPad2 = char2 == PAD_BYTE
    local isPad3 = char3 == PAD_BYTE

    -- padding may only appear in the final quartet, and "=" before "X" is invalid
    if (isPad2 or isPad3) and index < length - 3 then return nil end
    if isPad2 and not isPad3 then return nil end

    local value0 = base64Lookup[char0]
    local value1 = base64Lookup[char1]
    local value2 = isPad2 and 0 or base64Lookup[char2]
    local value3 = isPad3 and 0 or base64Lookup[char3]

    if value0 == nil or value1 == nil or value2 == nil or value3 == nil then
      return nil
    end

    local chunk = value0 * 262144 + value1 * 4096 + value2 * 64 + value3

    out[#out + 1] = string.char(math.floor(chunk / 65536) % 256)
    if not isPad2 then out[#out + 1] = string.char(math.floor(chunk / 256) % 256) end
    if not isPad3 then out[#out + 1] = string.char(chunk % 256) end

    index = index + 4
  end

  return table.concat(out)
end

--[[
  Encode a byte string into a checksum-framed, base64, paste-safe string.

  @param {string} input
  @return {string}
]]--
function me.Encode(input)
  local checksum = Adler32(input)

  return Base64Encode(NumberToBytes(checksum) .. input)
end

--[[
  Decode a string produced by me.Encode. Never raises - returns nil plus a
  short error code for any malformed or corrupt input.

  @param {string} encoded

  @return {string | nil}, {string | nil}
    the original byte string, or nil plus one of:
    "input"     - not a non-empty string
    "base64"    - not valid base64
    "truncated" - too short to contain the checksum header
    "checksum"  - checksum mismatch (corrupt / truncated paste)
]]--
function me.Decode(encoded)
  if type(encoded) ~= "string" or encoded == "" then
    return nil, "input"
  end

  local framed = Base64Decode(encoded)

  if not framed then
    return nil, "base64"
  end

  if #framed < 4 then
    return nil, "truncated"
  end

  local checksum = BytesToNumber(string.sub(framed, 1, 4))
  local payload = string.sub(framed, 5)

  if Adler32(payload) ~= checksum then
    return nil, "checksum"
  end

  return payload
end
