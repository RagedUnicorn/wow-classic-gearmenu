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
  Generic Lua value (de)serializer.

  The format is a compact, length-prefixed, type-tagged encoding so the parser
  never has to escape or guess delimiters:

    nil     -> "z"
    boolean -> "T" | "F"
    number  -> "n" <len> ":" <text>        text via string.format("%.14g", v)
    string  -> "s" <len> ":" <raw bytes>   length-prefixed: any content is safe
    table   -> "t" <pairCount> ":" <key><value> repeated pairCount times

  Deserialize is a hand-written data-only parser. It deliberately does NOT use
  loadstring/load - a serialized string may come from untrusted input (an
  imported profile string) and must never be able to execute code.
]]--

local mod = rggm
local me = {}
mod.serializer = me

me.tag = "Serializer"

--[[
  Guards the recursive parser/encoder against pathologically nested input.
  GearMenu profiles nest at most a few levels; 64 is far above any real payload
  while still preventing a crafted string from exhausting the Lua stack.
]]--
local MAX_DEPTH = 64

-- forward declarations
local EncodeValue
local ReadValue

--[[
  Serialize an arbitrary Lua value (nil/boolean/number/string/table) to a
  compact string.

  @param {any} value
  @return {string}
]]--
function me.Serialize(value)
  local out = {}
  EncodeValue(value, out, 0)
  return table.concat(out)
end

--[[
  Append the encoding of a single value to the output buffer.

  @param {any} value
  @param {table} out
    output buffer collected via table.concat
  @param {number} depth
]]--
EncodeValue = function(value, out, depth)
  if depth > MAX_DEPTH then
    error("serializer: maximum nesting depth exceeded")
  end

  local valueType = type(value)

  if value == nil then
    out[#out + 1] = "z"
  elseif valueType == "boolean" then
    out[#out + 1] = value and "T" or "F"
  elseif valueType == "number" then
    local text = string.format("%.14g", value)
    out[#out + 1] = "n" .. #text .. ":" .. text
  elseif valueType == "string" then
    out[#out + 1] = "s" .. #value .. ":" .. value
  elseif valueType == "table" then
    local count = 0
    for _ in pairs(value) do
      count = count + 1
    end

    out[#out + 1] = "t" .. count .. ":"

    for tableKey, tableValue in pairs(value) do
      EncodeValue(tableKey, out, depth + 1)
      EncodeValue(tableValue, out, depth + 1)
    end
  else
    error("serializer: cannot serialize value of type " .. valueType)
  end
end

--[[
  Read a length-prefixed payload (<digits> ":" <len bytes>) used by the number
  and string tags.

  @param {string} input
  @param {number} pos
    1-based position of the first length digit

  @return {string | nil}, {number | nil}
    the payload bytes and the position just after them, or nil on malformed input
]]--
local function ReadLengthPrefixed(input, pos)
  local colon = string.find(input, ":", pos, true)

  if not colon then return nil end

  local lengthText = string.sub(input, pos, colon - 1)

  if not string.match(lengthText, "^%d+$") then return nil end

  local length = tonumber(lengthText)
  local valueStart = colon + 1
  local valueEnd = valueStart + length - 1

  if valueEnd > #input then return nil end

  return string.sub(input, valueStart, valueEnd), valueEnd + 1
end

--[[
  Read the pair-count header of a table tag (<digits> ":").

  @param {string} input
  @param {number} pos

  @return {number | nil}, {number | nil}
    the count and the position just after the colon, or nil on malformed input
]]--
local function ReadCount(input, pos)
  local colon = string.find(input, ":", pos, true)

  if not colon then return nil end

  local countText = string.sub(input, pos, colon - 1)

  if not string.match(countText, "^%d+$") then return nil end

  return tonumber(countText), colon + 1
end

--[[
  Read a single value starting at pos.

  @param {string} input
  @param {number} pos
  @param {number} depth

  @return {number | nil}, {any}, {string | nil}
    On success returns the position just after the value plus the value itself
    (the position is the success discriminator - it is never nil on success,
    even when the parsed value legitimately is nil). On failure returns nil
    plus an error message.
]]--
ReadValue = function(input, pos, depth)
  if depth > MAX_DEPTH then
    return nil, nil, "maximum nesting depth exceeded"
  end

  if pos > #input then
    return nil, nil, "unexpected end of input"
  end

  local tag = string.sub(input, pos, pos)
  pos = pos + 1

  if tag == "z" then
    return pos, nil
  elseif tag == "T" then
    return pos, true
  elseif tag == "F" then
    return pos, false
  elseif tag == "n" then
    local text, nextPos = ReadLengthPrefixed(input, pos)

    if not text then return nil, nil, "malformed number" end

    local number = tonumber(text)

    if not number then return nil, nil, "invalid number value" end

    return nextPos, number
  elseif tag == "s" then
    local text, nextPos = ReadLengthPrefixed(input, pos)

    if not text then return nil, nil, "malformed string" end

    return nextPos, text
  elseif tag == "t" then
    local count, nextPos = ReadCount(input, pos)

    if not count then return nil, nil, "malformed table header" end

    local result = {}

    for _ = 1, count do
      local keyPos, key, keyErr = ReadValue(input, nextPos, depth + 1)

      if not keyPos then return nil, nil, keyErr end
      if key == nil then return nil, nil, "nil table key" end

      local valuePos, value, valueErr = ReadValue(input, keyPos, depth + 1)

      if not valuePos then return nil, nil, valueErr end

      result[key] = value
      nextPos = valuePos
    end

    return nextPos, result
  end

  return nil, nil, "unknown type tag"
end

--[[
  Deserialize a string produced by me.Serialize back into a Lua value. Never
  raises - returns nil plus an error message for any malformed input.

  @param {string} encoded

  @return {any | nil}, {string | nil}
    the decoded value, or nil plus an error message
]]--
function me.Deserialize(encoded)
  if type(encoded) ~= "string" then
    return nil, "input is not a string"
  end

  if encoded == "" then
    return nil, "empty input"
  end

  local nextPos, value, err = ReadValue(encoded, 1, 0)

  if not nextPos then
    return nil, err or "deserialization failed"
  end

  if nextPos ~= #encoded + 1 then
    return nil, "trailing data after value"
  end

  return value
end
