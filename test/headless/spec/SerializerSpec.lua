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
  Tests for the generic table (de)serializer (code/Serializer.lua).
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it
-- luacheck: ignore 143

describe("Serializer", function()
  local serializer = rggm.serializer

  it("round-trips a representative GearMenu config", function()
    local original = {
      enableTooltips = true,
      filterItemQuality = 2,
      uiTheme = 2,
      gearBars = {
        {
          id = 1,
          displayName = "Default GearBar",
          isLocked = false,
          slots = { { slotId = 13 }, { slotId = 14 } },
          position = { "CENTER", 0, 0 }
        }
      },
      frames = {
        GM_TrinketMenuFrame = {
          point = "CENTER",
          relativePoint = "CENTER",
          relativeTo = false,
          posX = 12.5,
          posY = -30.25
        }
      }
    }

    assert.are.same(original, serializer.Deserialize(serializer.Serialize(original)))
  end)

  it("round-trips booleans, numbers, empty strings and deep nesting", function()
    local original = {
      yes = true,
      no = false,
      zero = 0,
      negative = -17.25,
      empty = "",
      nested = { a = { b = { c = { d = 1 } } } }
    }

    assert.are.same(original, serializer.Deserialize(serializer.Serialize(original)))
  end)

  it("is immune to type tags and delimiters embedded in string values", function()
    -- a naive delimiter parser would choke on these; length-prefixing must not
    local original = {
      tricky = "t3:looks like a table z T F n2:99",
      colons = "a:b:c:d",
      newline = "line1\nline2\ttabbed"
    }

    assert.are.same(original, serializer.Deserialize(serializer.Serialize(original)))
  end)

  it("returns nil plus an error for truncated input", function()
    local encoded = serializer.Serialize({ key = "value", other = 1 })
    local result, err = serializer.Deserialize(string.sub(encoded, 1, #encoded - 4))

    assert.is_nil(result)
    assert.is_string(err)
  end)

  it("returns nil for empty and non-string input without raising", function()
    assert.is_nil(serializer.Deserialize(""))
    assert.is_nil(serializer.Deserialize(nil))
    assert.is_nil(serializer.Deserialize(42))
  end)

  it("rejects trailing garbage after a valid value", function()
    local encoded = serializer.Serialize({ a = 1 })

    assert.is_nil(serializer.Deserialize(encoded .. "garbage"))
  end)

  it("rejects a malformed length prefix", function()
    assert.is_nil(serializer.Deserialize("s999:short"))
  end)
end)
