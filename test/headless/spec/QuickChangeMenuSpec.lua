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
  Spec for the rule editing of the QuickChange settings page in gui/QuickChangeMenu.lua: picking
  the 'from' and 'to' item and a configured rule through the row click handler (me.SetupRowEvents),
  adding and removing a rule with their validation, the rule row matching and the inventory type
  dropdown. code/QuickChange.lua is replaced by a recorder (QuickChangeSpec covers the real rules).

  The selections live in file-local state, so the page is re-dofile'd per test and the selections
  are made the way the player makes them - by clicking a row. The three list refreshes are replaced
  on the module by recorders; the list layout itself is not asserted.
]]--

local wowStubs = require("WowStubs")

local FROM_ITEM = { itemId = 19950, enchantId = 2564, runeAbilityId = 6720 }
local TO_ITEM = { itemId = 19949 }
local DELAY = 3

describe("QuickChangeMenu", function()
  local menu
  local calls
  local userErrors
  local previous
  local restore

  --[[
    A fake list row that keeps the OnClick script SetupRowEvents installs

    @param {table} fields
      the row fields the list update would have set (side, itemId, ...)

    @return {table}
  ]]--
  local function FakeRow(fields)
    local row = fields

    function row:SetScript(scriptType, handler)
      self[scriptType] = handler
    end

    menu.SetupRowEvents(row)

    return row
  end

  local function selectFrom(item)
    local row = FakeRow({
      side = RGGM_CONSTANTS.QUICK_CHANGE_SIDE_FROM,
      itemId = item.itemId,
      enchantId = item.enchantId,
      runeAbilityId = item.runeAbilityId
    })

    row:OnClick()
  end

  local function selectTo(item)
    local row = FakeRow({ side = RGGM_CONSTANTS.QUICK_CHANGE_SIDE_TO, itemId = item.itemId })

    row:OnClick()
  end

  local function selectRule()
    local row = FakeRow({
      fromItemId = FROM_ITEM.itemId,
      fromItemEnchantId = FROM_ITEM.enchantId,
      fromRuneAbilityId = FROM_ITEM.runeAbilityId,
      toItemId = TO_ITEM.itemId
    })

    row:OnClick()
  end

  --[[
    The add rule button the page clicks, whose parent is the delay slider

    @param {number | nil} delay

    @return {table}
      the button, its slider at .slider
  ]]--
  local function FakeAddRuleButton(delay)
    local slider = {
      Slider = {
        value = delay,
        GetValue = function(self) return self.value end,
        SetValue = function(self, value) self.value = value end
      }
    }

    return { slider = slider, GetParent = function() return slider end }
  end

  before_each(function()
    calls = { added = {}, removed = {}, updated = {} }
    userErrors = {}

    previous = {
      quickChangeMenu = rggm.quickChangeMenu,
      quickChange = rggm.quickChange,
      gearManager = rggm.gearManager,
      logger = rggm.logger,
      L = rggm.L
    }

    rggm.L = setmetatable({}, { __index = function(_, key) return key end })
    rggm.logger = {
      LogDebug = function() end,
      LogWarn = function() calls.warned = true end,
      PrintUserError = function(message) userErrors[#userErrors + 1] = message end
    }
    rggm.quickChange = {
      -- the menu hands over its live selection and clears it right after - keep a copy
      AddQuickChangeRule = function(rule, delay)
        calls.added[#calls.added + 1] = { rule = rggm.common.Clone(rule), delay = delay }
      end,
      RemoveQuickChangeRule = function(rule)
        calls.removed[#calls.removed + 1] = rggm.common.Clone(rule)
      end
    }

    restore = wowStubs.install({ STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF" })

    dofile("gui/QuickChangeMenu.lua")
    menu = rggm.quickChangeMenu

    for _, listUpdate in ipairs({ "FromListOnUpdate", "ToListOnUpdate", "RulesListOnUpdate" }) do
      menu[listUpdate] = function(_, slotId)
        calls.updated[#calls.updated + 1] = { listUpdate, slotId }
      end
    end
  end)

  after_each(function()
    restore()

    for name, module in pairs(previous) do
      rggm[name] = module
    end
  end)

  describe("add rule", function()
    it("refuses a rule without a 'from' item", function()
      selectTo(TO_ITEM)

      menu.AddRuleOnClick(FakeAddRuleButton(DELAY))

      assert.are.same({ "quick_change_unable_to_add_rule_from" }, userErrors)
      assert.are.same({}, calls.added)
    end)

    it("refuses a rule without a 'to' item", function()
      selectFrom(FROM_ITEM)

      menu.AddRuleOnClick(FakeAddRuleButton(DELAY))

      assert.are.same({ "quick_change_unable_to_add_rule_to" }, userErrors)
      assert.are.same({}, calls.added)
    end)

    it("adds nothing when the delay slider has no value", function()
      selectFrom(FROM_ITEM)
      selectTo(TO_ITEM)

      menu.AddRuleOnClick(FakeAddRuleButton(nil))

      assert.is_true(calls.warned)
      assert.are.same({}, calls.added)
    end)

    it("adds the selected items with their enchant and rune and the chosen delay", function()
      selectFrom(FROM_ITEM)
      selectTo(TO_ITEM)

      menu.AddRuleOnClick(FakeAddRuleButton(DELAY))

      assert.are.same({ rule = { from = FROM_ITEM, to = TO_ITEM }, delay = DELAY }, calls.added[1])
    end)

    it("clears the selection, resets the delay and refreshes the three lists after adding", function()
      local button = FakeAddRuleButton(DELAY)

      selectFrom(FROM_ITEM)
      selectTo(TO_ITEM)
      calls.updated = {}

      menu.AddRuleOnClick(button)

      assert.are.equal(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MIN, button.slider.Slider.value)
      assert.are.same(
        { { "FromListOnUpdate" }, { "ToListOnUpdate" }, { "RulesListOnUpdate" } },
        calls.updated
      )

      -- the selection is gone, so a second click asks for a 'from' item again
      menu.AddRuleOnClick(button)

      assert.are.same({ "quick_change_unable_to_add_rule_from" }, userErrors)
      assert.are.equal(1, #calls.added)
    end)
  end)

  describe("remove rule", function()
    it("refuses when no rule is selected", function()
      menu.RemoveRuleOnClick()

      assert.are.same({ "quick_change_unable_to_remove_rule" }, userErrors)
      assert.are.same({}, calls.removed)
    end)

    it("removes the clicked rule and clears the selection", function()
      selectRule()

      menu.RemoveRuleOnClick()

      assert.are.same({ from = FROM_ITEM, to = TO_ITEM }, calls.removed[1])

      menu.RemoveRuleOnClick()

      assert.are.same({ "quick_change_unable_to_remove_rule" }, userErrors)
    end)
  end)

  describe("rule row matching", function()
    local row = {
      fromItemId = FROM_ITEM.itemId,
      fromItemEnchantId = FROM_ITEM.enchantId,
      fromRuneAbilityId = FROM_ITEM.runeAbilityId,
      toItemId = TO_ITEM.itemId
    }

    it("matches the row of the same items, enchants and runes", function()
      assert.is_true(menu.IsRuleMatching({ from = FROM_ITEM, to = TO_ITEM }, row))
    end)

    it("does not match the same items with another rune", function()
      local otherRune = { itemId = FROM_ITEM.itemId, enchantId = FROM_ITEM.enchantId, runeAbilityId = 1 }

      assert.is_false(menu.IsRuleMatching({ from = otherRune, to = TO_ITEM }, row))
    end)

    it("does not match while only one side is selected", function()
      assert.is_false(menu.IsRuleMatching({ from = FROM_ITEM }, row))
      assert.is_false(menu.IsRuleMatching({ to = TO_ITEM }, row))
    end)
  end)

  describe("inventory type dropdown", function()
    it("offers one entry per inventory type and prefers the simplified slot name", function()
      local entries = {}

      rggm.gearManager = {
        GetGearSlots = function()
          return {
            { name = "slot_name_head", inventoryTypeId = 1, slotId = 1 },
            {
              name = "slot_name_upper_trinket", simplifiedName = "slot_name_trinket", inventoryTypeId = 12, slotId = 13
            },
            {
              name = "slot_name_lower_trinket", simplifiedName = "slot_name_trinket", inventoryTypeId = 12, slotId = 14
            }
          }
        end
      }

      menu.InitializeInventoryTypeDropdownMenu(nil, {
        CreateRadio = function(_, text, isSelected, onSelect, value)
          entries[#entries + 1] = { text = text, isSelected = isSelected, onSelect = onSelect, value = value }
        end
      })

      assert.are.equal(2, #entries)
      assert.are.same({ "slot_name_head", 1 }, { entries[1].text, entries[1].value })
      assert.are.same({ "slot_name_trinket", 13 }, { entries[2].text, entries[2].value })
      assert.are.equal(menu.IsInventoryTypeSelected, entries[1].isSelected)
      assert.are.equal(menu.OnInventoryTypeSelect, entries[1].onSelect)
    end)

    it("clears the item selection and reloads both item lists for the selected type", function()
      selectFrom(FROM_ITEM)
      selectTo(TO_ITEM)
      calls.updated = {}

      menu.OnInventoryTypeSelect(13)

      assert.are.same({ { "FromListOnUpdate", 13 }, { "ToListOnUpdate", 13 } }, calls.updated)
      assert.is_true(menu.IsInventoryTypeSelected(13))
      assert.is_false(menu.IsInventoryTypeSelected(RGGM_CONSTANTS.CATEGORY_DROPDOWN_DEFAULT_VALUE))

      menu.AddRuleOnClick(FakeAddRuleButton(DELAY))

      assert.are.same({ "quick_change_unable_to_add_rule_from" }, userErrors)
    end)
  end)
end)
