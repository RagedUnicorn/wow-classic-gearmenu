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
  Tests for the pure table helpers of code/Common.lua (loaded by test/headless/Bootstrap.lua):
  Clone and DeepEquals, the comparison behind the active profile adoption in code/Profile.lua.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it
-- luacheck: ignore 143

describe("Common", function()
  local common = rggm.common

  describe("Clone", function()
    it("deep-copies nested tables so the copy shares nothing with the original", function()
      local original = { a = 1, nested = { list = { 1, 2 }, flag = false } }
      local copy = common.Clone(original)

      assert.are.same(original, copy)
      assert.are_not.equal(original, copy)
      assert.are_not.equal(original.nested, copy.nested)

      copy.nested.list[1] = 99
      assert.are.equal(1, original.nested.list[1])
    end)

    it("returns a non-table value as is", function()
      assert.are.equal(5, common.Clone(5))
      assert.are.equal("x", common.Clone("x"))
      assert.is_nil(common.Clone(nil))
    end)
  end)

  describe("DeepEquals", function()
    it("compares scalars with a plain equality", function()
      assert.is_true(common.DeepEquals(1, 1))
      assert.is_true(common.DeepEquals("a", "a"))
      assert.is_true(common.DeepEquals(nil, nil))
      assert.is_false(common.DeepEquals(1, 2))
      assert.is_false(common.DeepEquals(1, "1"))
      assert.is_false(common.DeepEquals(false, nil))
    end)

    it("compares tables recursively by content, not by reference", function()
      local a = { enableTooltips = true, gearBars = { { id = 1, slots = { 13, 14 } } }, frames = {} }
      local b = common.Clone(a)

      assert.are_not.equal(a, b)
      assert.is_true(common.DeepEquals(a, b))
      assert.is_true(common.DeepEquals({}, {}))
    end)

    it("reports a difference in either direction of the key sets", function()
      -- a key only the first table has
      assert.is_false(common.DeepEquals({ a = 1, b = 2 }, { a = 1 }))
      -- a key only the second table has
      assert.is_false(common.DeepEquals({ a = 1 }, { a = 1, b = 2 }))
      -- a false value is a present key, not a missing one
      assert.is_false(common.DeepEquals({ a = false }, {}))
      assert.is_false(common.DeepEquals({}, { a = false }))
    end)

    it("reports a difference buried in a nested table", function()
      local a = { gearBars = { { id = 1, slots = { 13, 14 } } } }
      local b = { gearBars = { { id = 1, slots = { 13, 1 } } } }

      assert.is_false(common.DeepEquals(a, b))
      assert.is_false(common.DeepEquals({ nested = {} }, { nested = 1 }))
    end)
  end)
end)
