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

-- luacheck: globals GetItemInfo GetItemSpell GetInventoryItemID C_Timer IsEquippedItem

local mod = rggm
local me = {}
mod.quickChange = me

me.tag = "QuickChange"

--[[
  Save new quick change rule

  @param (table) quickChangeRule
    A rule with an item to switch from to another one
  @param {number} delay
    time to wait before changing an item
]]--
function me.AddQuickChangeRule(quickChangeRule, delay)
  --[[
    If items are of the same itemId and also don't have a different enchantId
    then the rule is invalid
  ]]--
  if quickChangeRule.from.itemId == quickChangeRule.to.itemId
      and quickChangeRule.from.enchantId == quickChangeRule.to.enchantId then
    mod.logger.PrintUserError(rggm.L["quick_change_invalid_rule"])
    return
  end

  -- prevent adding duplicate rules
  for _, rule in ipairs(mod.configuration.GetQuickChangeRules()) do
    if rule.changeFromItemId == quickChangeRule.from.itemId
        and rule.changeFromItemEnchantId == quickChangeRule.from.enchantId then
      mod.logger.PrintUserError(rggm.L["quick_change_unable_to_add_rule_duplicate"])
      return
    end
  end

  local changeFromItemId = quickChangeRule.from.itemId
  local changeToItemId = quickChangeRule.to.itemId
  local changeFromName, _, itemFromQuality, _, _, _, _, _, equipFromSlot, itemFromTexture =
    GetItemInfo(changeFromItemId)
  local changeToName, _, itemToQuality, _, _, _, _, _, _, itemToTexture = GetItemInfo(changeToItemId)

  local _, spellId = GetItemSpell(changeFromItemId)
  local rule = {
    ["changeFromName"] = changeFromName,
    ["changeFromItemId"] = changeFromItemId,
    ["changeFromItemEnchantId"] = quickChangeRule.from.enchantId,
    ["changeFromRuneAbilityId"] = quickChangeRule.from.runeAbilityId,
    ["changeFromRuneName"] = quickChangeRule.from.runeName,
    ["changeFromItemIcon"] = itemFromTexture,
    ["changeFromItemQuality"] = itemFromQuality,
    ["changeToName"] = changeToName,
    ["changeToItemId"] = changeToItemId,
    ["changeToItemEnchantId"] = quickChangeRule.to.enchantId,
    ["changeToRuneAbilityId"] = quickChangeRule.to.runeAbilityId,
    ["changeToRuneName"] = quickChangeRule.to.runeName,
    ["changeToItemIcon"] = itemToTexture,
    ["changeToItemQuality"] = itemToQuality,
    ["equipSlot"] = equipFromSlot,
    ["spellId"] = spellId,
    ["delay"] = delay
  }

  mod.configuration.AddQuickChangeRule(rule)
  mod.logger.LogDebug(me.tag, "Added new quickChange from: " .. rule.changeFromItemId ..
    " to: " .. rule.changeToItemId)
end

--[[
  Search for the selectedRule in the quickChangeRules and remove it if found

  @param {table} selectedRule
]]--
function me.RemoveQuickChangeRule(selectedRule)
  for index, quickChangeRule in ipairs(mod.configuration.GetQuickChangeRules()) do
    if me.IsRuleMatching(
      selectedRule.from.itemId,
      selectedRule.from.enchantId,
      selectedRule.to.itemId,
      selectedRule.to.enchantId,
      quickChangeRule.changeFromItemId,
      quickChangeRule.changeFromItemEnchantId,
      quickChangeRule.changeToItemId,
      quickChangeRule.changeToItemEnchantId
    ) then
      mod.configuration.RemoveQuickChangeRule(index)
      mod.logger.LogDebug(me.tag, "Removed quickChange from: " .. quickChangeRule.changeFromItemId ..
        " to: " .. quickChangeRule.changeToItemId)
    end
  end
end

--[[
Check if a rule is matching another rule

  @param {number} ruleFromItemId
  @param {number} ruleFromEnchantId
  @param {number} ruleToItemId
  @param {number} ruleToEnchantId
  @param {number} otherRuleFromItemId
  @param {number} otherRuleFromEnchantId
  @param {number} otherRuleToItemId
  @param {number} otherRuleToEnchantId

  @return {boolean}
    true if the rules are matching
    false if the rules are not matching
]]--
function me.IsRuleMatching(ruleFromItemId, ruleFromEnchantId, ruleToItemId, ruleToEnchantId, otherRuleFromItemId,
                           otherRuleFromEnchantId, otherRuleToItemId, otherRuleToEnchantId)

  if ruleFromItemId == otherRuleFromItemId
    and ruleFromEnchantId == otherRuleFromEnchantId
    and ruleToItemId == otherRuleToItemId
    and ruleToEnchantId == otherRuleToEnchantId then
    return true
  end

  return false
end

--[[
  On UNIT_SPELLCAST_SUCCEEDED

  Upon detecting a used spell compare it against the quickChangeRules wether the spell
  was one that matches with a rule. If not immediately abort. If it matches gather
  the possible slotId that this rule fits to. For most slots there is only one place
  where they fit. For trinkets however it can be INVSLOT_TRINKET1 and INVSLOT_TRINKET2 (same
  for rings).

  Once the possible slots are found check in which one was the item that triggered the quickChange.
  QuickChange will make sure to switch the item that triggered the rule with the new one. If there is
  a delay configured QuickChange will wait until the delay passed and then atempt to switch the item.
  At this point the same rules as a normal item switch apply. E.g. if the player is in combat QuickSwitch
  will add the item to the combatQueue.

  Note: Spells are filtered by unit = "player". We're only interested in spells casted by
  the player himself
]]--
function me.OnUnitSpellCastSucceeded(...)
  local unitId, _, spellId = ...
  -- only interested in spell events that where caused by the player itself
  if unitId ~= RGGM_CONSTANTS.UNIT_ID_PLAYER then return end

  for _, quickChangeRule in ipairs(mod.configuration.GetQuickChangeRules()) do
    if spellId == quickChangeRule.spellId then
      --
      --[[
        Found a rule for used spell. Search for all eligible slots that match the inventoryType
        from the quickChangeRule. Then execute all those rules.
      ]]--
      local slotIds = me.CollectEligibleSlotIds(quickChangeRule)
      me.ExecuteQuickChangeRule(quickChangeRule, slotIds)
    end
  end
end

--[[
  Search for slots that are eligible for a certain quickChangeRule. There can be multiple
  eligible slots for certain slots such as trinket slots because there are more than one such slots.

  @param {table} quickChangeRule

  @return {table}
    The collected eligible slotIds
]]--
function me.CollectEligibleSlotIds(quickChangeRule)
  local slotIds = {}

  for _, gearSlot in ipairs(mod.gearManager.GetGearSlots()) do
    for _, inventoryType in ipairs(gearSlot.type) do
      if inventoryType == quickChangeRule.equipSlot then
        gearSlot.itemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlot.slotId)
        table.insert(slotIds, gearSlot)
      end
    end
  end

  return slotIds
end

--[[
  Executes a quickChangeRule once the correct slot was found

  @param {table} quickChangeRule
  @param {table} slotIds
]]--
function me.ExecuteQuickChangeRule(quickChangeRule, slotIds)
  for _, slotMetadata in ipairs(slotIds) do
    -- Only perform quickchange if item ID's match and item is not currently equipped.
    -- Solving situations such as users using two of the same trinket or weapon will need a more complicated approach.
    if slotMetadata.itemId == quickChangeRule.changeFromItemId
      and not IsEquippedItem(quickChangeRule.changeToItemId) then
      C_Timer.After(quickChangeRule.delay or 0, function()
        local item = {}
        item.itemId = quickChangeRule.changeToItemId
        item.enchantId = quickChangeRule.changeToItemEnchantId
        item.slotId = slotMetadata.slotId

        mod.itemManager.EquipItemByItemAndEnchantId(item)
      end)

      return -- rule executed - back out
    end
  end
end
