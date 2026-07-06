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
  Spec for the pure matcher helpers in code/ItemManager.lua: IsEnchantIdMatching, IsRuneAbilityIdMatching
  and IsDuplicateItem. These helpers take plain Lua tables/numbers and touch neither mod.* collaborators
  nor WoW globals, so the spec only re-dofiles the module (per the isolation convention documented in
  test/headless/Bootstrap.lua) and asserts return values -- no stubs and no WowStubs are required.

  The bag-scanning bulk of ItemManager is dominated by C_Container.* and is intentionally out of scope.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

describe("ItemManager matchers", function()
  local itemManager

  before_each(function()
    -- fresh module table (clears any file-local state) -- see test/headless/Bootstrap.lua
    dofile("code/ItemManager.lua")
    itemManager = rggm.itemManager
  end)

  describe("IsEnchantIdMatching", function()
    it("matches regardless of the item enchant when the passed enchantId is 0", function()
      assert.is_true(itemManager.IsEnchantIdMatching({ enchantId = 1234 }, 0))
      assert.is_true(itemManager.IsEnchantIdMatching({ enchantId = nil }, 0))
    end)

    it("matches when the item enchantId equals the passed enchantId", function()
      assert.is_true(itemManager.IsEnchantIdMatching({ enchantId = 60 }, 60))
    end)

    it("does not match when the item enchantId differs from the passed enchantId", function()
      assert.is_false(itemManager.IsEnchantIdMatching({ enchantId = 60 }, 70))
    end)

    it("does not match when the item has no enchant but a non-zero enchantId is requested", function()
      assert.is_false(itemManager.IsEnchantIdMatching({ enchantId = nil }, 70))
    end)
  end)

  describe("IsRuneAbilityIdMatching", function()
    it("matches regardless of the rune when the passed runeAbilityId is 0", function()
      assert.is_true(itemManager.IsRuneAbilityIdMatching({ skillLineAbilityID = 99 }, 0))
      assert.is_true(itemManager.IsRuneAbilityIdMatching(nil, 0))
    end)

    it("matches when both the rune and the runeAbilityId are nil", function()
      assert.is_true(itemManager.IsRuneAbilityIdMatching(nil, nil))
    end)

    it("matches when the rune skillLineAbilityID equals the passed runeAbilityId", function()
      assert.is_true(itemManager.IsRuneAbilityIdMatching({ skillLineAbilityID = 7 }, 7))
    end)

    it("does not match when the rune skillLineAbilityID differs from the passed runeAbilityId", function()
      assert.is_false(itemManager.IsRuneAbilityIdMatching({ skillLineAbilityID = 7 }, 8))
    end)

    it("does not match when there is no rune but a non-zero runeAbilityId is requested", function()
      assert.is_false(itemManager.IsRuneAbilityIdMatching(nil, 7))
    end)
  end)

  describe("IsDuplicateItem", function()
    it("is false for an empty item list", function()
      assert.is_false(itemManager.IsDuplicateItem({}, 12345, nil, nil))
    end)

    it("treats a same-id item with no enchant and no rune as a duplicate", function()
      local items = { { id = 12345, enchantId = nil, runeAbilityId = nil } }

      assert.is_true(itemManager.IsDuplicateItem(items, 12345, nil, nil))
    end)

    it("treats a same-id item with the same enchant as a duplicate", function()
      local items = { { id = 12345, enchantId = 60, runeAbilityId = nil } }

      assert.is_true(itemManager.IsDuplicateItem(items, 12345, 60, nil))
    end)

    it("does not treat a same-id item with a different enchant as a duplicate", function()
      local items = { { id = 12345, enchantId = 60, runeAbilityId = nil } }

      assert.is_false(itemManager.IsDuplicateItem(items, 12345, 70, nil))
    end)

    it("does not treat a different-id item as a duplicate", function()
      local items = { { id = 12345, enchantId = nil, runeAbilityId = nil } }

      assert.is_false(itemManager.IsDuplicateItem(items, 99999, nil, nil))
    end)

    it("does not treat two different-id items sharing the same rune as duplicates", function()
      -- regression: the condition once parsed as (id == itemId and enchant) or (rune present),
      -- so a matching rune alone made distinct items collide and the second was silently dropped
      local items = { { id = 12345, enchantId = nil, runeAbilityId = 7 } }

      assert.is_false(itemManager.IsDuplicateItem(items, 99999, nil, 7))
    end)

    it("treats a same-id item with the same rune as a duplicate", function()
      local items = { { id = 12345, enchantId = nil, runeAbilityId = 7 } }

      assert.is_true(itemManager.IsDuplicateItem(items, 12345, nil, 7))
    end)

    it("does not treat a same-id item with a different rune as a duplicate", function()
      local items = { { id = 12345, enchantId = nil, runeAbilityId = 7 } }

      assert.is_false(itemManager.IsDuplicateItem(items, 12345, nil, 8))
    end)

    it("does not treat a same-id, same-rune item as a duplicate when only one has an enchant", function()
      local items = { { id = 12345, enchantId = 60, runeAbilityId = 7 } }

      assert.is_false(itemManager.IsDuplicateItem(items, 12345, nil, 7))
    end)

    it("does not treat a same-id, same-rune item with a different enchant as a duplicate", function()
      local items = { { id = 12345, enchantId = 60, runeAbilityId = 7 } }

      assert.is_false(itemManager.IsDuplicateItem(items, 12345, 70, 7))
    end)

    it("treats a same-id item with matching enchant and rune as a duplicate", function()
      local items = { { id = 12345, enchantId = 60, runeAbilityId = 7 } }

      assert.is_true(itemManager.IsDuplicateItem(items, 12345, 60, 7))
    end)
  end)
end)
