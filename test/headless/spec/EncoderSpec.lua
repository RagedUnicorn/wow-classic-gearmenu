--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

--[[
  Tests for the generic byte-string codec (code/Encoder.lua).
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it
-- luacheck: ignore 143

describe("Encoder", function()
  local encoder = rggm.encoder

  it("round-trips strings of every length class", function()
    local samples = { "", "a", "ab", "abc", "abcd", "hello world", string.rep("x", 100) }

    for _, sample in ipairs(samples) do
      assert.are.equal(sample, (encoder.Decode(encoder.Encode(sample))))
    end
  end)

  it("round-trips every byte value 0-255", function()
    local bytes = {}

    for value = 0, 255 do
      bytes[#bytes + 1] = string.char(value)
    end

    local blob = table.concat(bytes)

    assert.are.equal(blob, (encoder.Decode(encoder.Encode(blob))))
  end)

  it("produces only paste-safe characters", function()
    local encoded = encoder.Encode("some payload bytes \1\2\3 with controls")

    assert.is_nil(string.find(encoded, "[^%w+/=]"))      -- only the base64 alphabet
    assert.is_nil(string.find(encoded, "|", 1, true))    -- never the WoW escape char
    assert.is_nil(string.find(encoded, "%s"))            -- no whitespace or newlines
  end)

  it("detects a corrupted character via the checksum", function()
    local encoded = encoder.Encode("important configuration data")
    local firstChar = string.sub(encoded, 1, 1)
    local replacement = firstChar == "A" and "B" or "A"
    local corrupted = replacement .. string.sub(encoded, 2)

    local result, err = encoder.Decode(corrupted)

    assert.is_nil(result)
    assert.are.equal("checksum", err)
  end)

  it("rejects malformed base64", function()
    assert.is_nil(encoder.Decode("not valid base64 !!!"))
    assert.is_nil(encoder.Decode("ABC"))  -- length not a multiple of 4
  end)

  it("rejects empty and non-string input without raising", function()
    assert.is_nil(encoder.Decode(""))
    assert.is_nil(encoder.Decode(nil))
  end)
end)
