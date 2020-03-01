--[[
  MIT License

  Copyright (c) 2020 Michael Wiesendanger

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

-- luacheck: globals GetContainerNumSlots GetContainerItemID GetItemInfo INVSLOT_MAINHAND INVSLOT_OFFHAND
-- luacheck: globals UnitAffectingCombat CursorHasItem SpellIsTargeting GetContainerItemInfo
-- luacheck: globals IsInventoryItemLocked PickupContainerItem PickupInventoryItem GetContainerItemLink
-- luacheck: globals GetInventoryItemLink GetInventoryItemID GetItemSpell

--[[
  Itemmanager manages all items. All itemslots muss register to work properly
]]--
local mod = rggm
local me = {}
mod.itemManager = me

me.tag = "ItemManager"

--[[
  Retrieve all items from inventory bags matching any type of
    INVTYPE_AMMO
    INVTYPE_HEAD
    INVTYPE_NECK
    INVTYPE_SHOULDER
    INVTYPE_BODY
    INVTYPE_CHEST
    INVTYPE_ROBE
    INVTYPE_WAIST
    INVTYPE_LEGS
    INVTYPE_FEET
    INVTYPE_WRIST
    INVTYPE_HAND
    INVTYPE_FINGER
    INVTYPE_TRINKET
    INVTYPE_CLOAK
    INVTYPE_WEAPON
    INVTYPE_SHIELD
    INVTYPE_2HWEAPON
    INVTYPE_WEAPONMAINHAND
    INVTYPE_WEAPONOFFHAND

  @param {table} inventoryType

  @return {table}
]]--
function me.GetItemsForInventoryType(inventoryType)
  local idx = 1
  local items = {}

  if inventoryType == nil then
    mod.logger.LogError(me.tag, "InventoryType(s) missing")
    return items
  end

  for i = 0, 4 do
    for j = 1, GetContainerNumSlots(i) do
      local itemId = GetContainerItemID(i, j)

      if itemId then
        local itemName, _, itemRarity, _, _, _, _, _, equipSlot, itemIcon = GetItemInfo(itemId)
        for it = 1, table.getn(inventoryType) do
          if equipSlot == inventoryType[it] then
            if itemRarity >= mod.configuration.GetFilterItemQuality() then
              if not items[idx] then
                items[idx] = {}
              end

              items[idx].bag = i
              items[idx].slot = j
              items[idx].name = itemName
              items[idx].icon = itemIcon
              items[idx].id = itemId
              items[idx].equipSlot = equipSlot
              items[idx].quality = itemRarity

              idx = idx + 1
            else
              mod.logger.LogDebug(me.tag, "Ignoring item because its quality is lower than setting "
                .. mod.configuration.GetFilterItemQuality())
            end
          end
        end
      end
    end
  end

  return items
end

--[[
  Equip an item into a specific slot identified by it's itemId
    INVSLOT_HEAD
    INVSLOT_NECK
    INVSLOT_SHOULDER
    INVSLOT_CHEST
    INVSLOT_WAIST
    INVSLOT_LEGS
    INVSLOT_FEET
    INVSLOT_WRIST
    INVSLOT_HAND
    INVSLOT_FINGER1
    INVSLOT_FINGER2
    INVSLOT_TRINKET1
    INVSLOT_TRINKET2
    INVSLOT_BACK
    INVSLOT_MAINHAND
    INVSLOT_OFFHAND
    INVSLOT_RANGED

  @param {number} itemId
  @param {number} slotId
]]--
function me.EquipItemById(itemId, slotId)
  if not itemId or not slotId then return end

  mod.logger.LogDebug(me.tag, "EquipItem: " .. itemId .. " in slot: " .. slotId)
  --[[
    Blizzard blocks even weapons from being switched by addons during combat. Because of this
    all items are added to the combatqueue if the player is in combat.
  ]]--
  if UnitAffectingCombat(RGGM_CONSTANTS.UNIT_ID_PLAYER) or mod.common.IsPlayerReallyDead()
      or mod.combatQueue.IsEquipChangeBlocked() or mod.common.IsPlayerCasting() then
    mod.combatQueue.AddToQueue(itemId, slotId)
  else
    me.SwitchItems(itemId, slotId)
  end
end

--[[
  Switch to items from itemSlot and a bag position
    INVSLOT_HEAD
    INVSLOT_NECK
    INVSLOT_SHOULDER
    INVSLOT_CHEST
    INVSLOT_WAIST
    INVSLOT_LEGS
    INVSLOT_FEET
    INVSLOT_WRIST
    INVSLOT_HAND
    INVSLOT_FINGER1
    INVSLOT_FINGER2
    INVSLOT_TRINKET1
    INVSLOT_TRINKET2
    INVSLOT_BACK
    INVSLOT_MAINHAND
    INVSLOT_OFFHAND
    INVSLOT_RANGED

  @param {number} itemId
  @param {number} slotId
]]--
function me.SwitchItems(itemId, slotId)
  if not CursorHasItem() and not SpellIsTargeting() then
    local bagNumber, bagPos = me.FindItemInBag(itemId)

    if bagNumber and bagPos then
      local _, _, isLocked = GetContainerItemInfo(bagNumber, bagPos)

      if not isLocked and not IsInventoryItemLocked(bagPos) and not IsInventoryItemLocked(slotId) then
        -- neither container item nor inventory item locked, perform swap
        PickupContainerItem(bagNumber, bagPos)
        PickupInventoryItem(slotId)

        -- make sure to clear combatQueue
        mod.combatQueue.RemoveFromQueue(slotId)

        return -- abort
      end
    end

    --[[
      Special case for when an item can't be found in the bag. This can happen when the
      user drag and drops an item that he has equiped onto another slot. This essentialy
      needs to cause a switch of those items. This is only possible for INVTYPE_TRINKET and
      INVTYPE_FINGER
    ]]--
    local foundSlotId = me.FindEquipedItem(itemId)

    if foundSlotId then
      -- the found slot with the queue slot
      PickupInventoryItem(foundSlotId)
      PickupInventoryItem(slotId)

      mod.combatQueue.RemoveFromQueue(slotId)

      return -- abort
    end

    mod.logger.LogDebug(me.tag, "Was unable to switch because the item to switch to could not be found")
    mod.combatQueue.RemoveFromQueue(slotId)
  end
end

--[[
  Search for an item in all inventoryslots

  @param {number} itemId

  @return {number | nil}
    number - the slotId where the item was found
    nil - if the item could not be found
]]--
function me.FindEquipedItem(itemId)
  local gearSlots = mod.gearManager.GetGearSlots()

  for i = 1, table.getn(gearSlots) do
    local equipedItemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlots[i].slotId)

    if equipedItemId == itemId then
      -- return the slot where the item was found
      return gearSlots[i].slotId -- found in the following slot
    end
  end

  return nil
end

--[[
  Search for an item in all bags

  @param {number} itemId

  @return {number}, {number}
]]--
function me.FindItemInBag(itemId)
  for i = 0, 4 do
    for j = 1, GetContainerNumSlots(i) do
      local _, _, id = string.find(GetContainerItemLink(i, j) or "", "item:(%d+):")

      if tonumber(id) == itemId then
        return i, j
      end
    end
  end
end

--[[
  Find items in both bags and worn items that have an onUse effect. Duplicate items are filtered

  @param {table} inventoryType
  @param {boolean} mustHaveOnUse
    true - If the items have to have an onUse effect to be considered
    false - If the items do not have to have an onUse effect to be considered
]]--
function me.FindQuickChangeItems(inventoryType, mustHaveOnUse)
  local items = {}

  if inventoryType == nil then
    mod.logger.LogError(me.tag, "InventoryType(s) missing")
    return items
  end

  for i = 0, 4 do
    for j = 1, GetContainerNumSlots(i) do
      local itemId = GetContainerItemID(i, j)

      if itemId and not me.IsDuplicateItem(items, itemId) then
        local item = me.AddItemsMatchingInventoryType(inventoryType, itemId, mustHaveOnUse)

        if item ~= nil then
          table.insert(items, item)
        end
      end
    end
  end

  local gearSlots = mod.gearManager.GetGearSlots()

  for i = 1, table.getn(gearSlots) do
    local itemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlots[i].slotId)

    if itemId and not me.IsDuplicateItem(items, itemId) then
      local item = me.AddItemsMatchingInventoryType(inventoryType, itemId, mustHaveOnUse)

      if item ~= nil then
        table.insert(items, item)
      end
    end
  end

  return items
end

--[[
  @param {table} items
  @param {number} itemId

  @return {boolean}
    true  - If the list already contains an item with the passed itemId
    false - If the list does not contain an item with the passed itemId
]]--
function me.IsDuplicateItem(items, itemId)
  for i = 1, table.getn(items) do
    if items[i].id == itemId then
      mod.logger.LogDebug(me.tag, "Filtered duplicate item - " .. items[i].name .. " - from item list")
      return true
    end
  end

  return false
end

--[[
  Check an item against certain rules
    INVTYPE_AMMO
    INVTYPE_HEAD
    INVTYPE_NECK
    INVTYPE_SHOULDER
    INVTYPE_BODY
    INVTYPE_CHEST
    INVTYPE_ROBE
    INVTYPE_WAIST
    INVTYPE_LEGS
    INVTYPE_FEET
    INVTYPE_WRIST
    INVTYPE_HAND
    INVTYPE_FINGER
    INVTYPE_TRINKET
    INVTYPE_CLOAK
    INVTYPE_WEAPON
    INVTYPE_SHIELD
    INVTYPE_2HWEAPON
    INVTYPE_WEAPONMAINHAND
    INVTYPE_WEAPONOFFHAND


  @param {table} inventoryType
  @param {number} itemId
  @param {boolean} mustHaveOnUse
    true - If the items have to have an onUse effect to be considered
    false - If the items do not have to have an onUse effect to be considered

  @return {table, nil}
    table - If an item could be found
    nil - If no item could be found
]]--
function me.AddItemsMatchingInventoryType(inventoryType, itemId, mustHaveOnUse)
  local item = nil
  local itemName, _, _, _, _, _, _, _, equipSlot, itemIcon = GetItemInfo(itemId)

  for it = 1, table.getn(inventoryType) do
    if equipSlot == inventoryType[it] then
      local spellName, spellId = GetItemSpell(itemId)

      if spellName ~= nil and spellId ~= nil or not mustHaveOnUse then
        item = {}
        item.name = itemName
        item.id = itemId
        item.texture = itemIcon
      else
        mod.logger.LogDebug(me.tag, "Skipped item: " .. itemName .. " because it has no onUse effect")
        return nil
      end
    end
  end

  return item
end
