--[[
  MIT License

  Copyright (c) 2024 Michael Wiesendanger

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

-- luacheck: globals C_Timer INVSLOT_TRINKET1

local mod = rggm
local me = {}

mod.debug = me

me.tag = "Debug"

_G["__GM__DEBUG__ADD_QUICK_CHANGE_RULE"] = function()
  local changeFromItemId = 55881 -- Impetuous Query
  local changeToItemId = 128959 -- Seal of House Wrynn
  local delay = 10

  me.AddQuickChangeRule(changeFromItemId, changeToItemId, delay)
end


_G["__GM__DEBUG__EXECUTE_QUICK_CHANGE_RULE"] = function()
  local quickChangeRules = mod.configuration.GetQuickChangeRules()

  for _, quickChangeRule in ipairs(quickChangeRules) do
    mod.logger.LogDebug(me.tag, "Switching from: " .. quickChangeRule.changeFromItemId)
    mod.logger.LogDebug(me.tag, "Switching to: " .. quickChangeRule.changeToItemId)
    mod.logger.LogDebug(me.tag, "EquipSlot: " .. quickChangeRule.equipSlot)

    C_Timer.After(quickChangeRule.delay or 0, function()
      local item = {}
      item.itemId = quickChangeRule.changeToItemId
      item.enchantId = quickChangeRule.changeToItemEnchantId
      item.slotId = INVSLOT_TRINKET1

      mod.itemManager.EquipItem(item)
    end)
  end
end
