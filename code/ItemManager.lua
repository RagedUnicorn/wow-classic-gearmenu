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

-- luacheck: globals C_Item INVSLOT_MAINHAND INVSLOT_OFFHAND PutItemInBackpack GetInventoryItemID
-- luacheck: globals UnitAffectingCombat CursorHasItem SpellIsTargeting ClearCursor C_Timer
-- luacheck: globals IsInventoryItemLocked PutItemInBag PickupInventoryItem C_Container GetInventoryItemLink

--[[
  Itemmanager manages all items. All itemslots muss register to work properly
]]--
local mod = rggm
local me = {}
mod.itemManager = me

me.tag = "ItemManager"

--[[
  Typed reasons for why an item swap was aborted. SwitchItems and UnequipItemToBag return the
  matching reason so callers (and tests) can distinguish the failure paths
]]--
me.failureReason = {
  itemNotFound = "ITEM_NOT_FOUND",
  itemLocked = "ITEM_LOCKED",
  cursorBusy = "CURSOR_BUSY",
  spellTargeting = "SPELL_TARGETING",
  noBagSpace = "NO_BAG_SPACE"
}

-- maps each typed failure reason to its localized user message
local swapFailureMessages = {
  [me.failureReason.itemNotFound] = "swap_failure_item_not_found",
  [me.failureReason.itemLocked] = "swap_failure_item_locked",
  [me.failureReason.cursorBusy] = "swap_failure_cursor_busy",
  [me.failureReason.spellTargeting] = "swap_failure_spell_targeting",
  [me.failureReason.noBagSpace] = "swap_failure_no_bag_space"
}

local bagUpdatePending = false

-- forward declarations
local NotifySwapFailure
local RequiresOffhandDisplacement
local ScanBagsForItem

--[[
  Surface an aborted swap to the user with a localized chat message. The combatQueue guard
  makes sure a queued swap reports each reason only once instead of once per ProcessQueue tick

  @param {string} reason
    One of me.failureReason
  @param {number} slotId
  @param {number} itemId
]]--
NotifySwapFailure = function(reason, slotId, itemId)
  if not mod.combatQueue.ShouldNotifySwapFailure(slotId, reason) then return end

  local itemName = itemId and C_Item.GetItemInfo(itemId) or nil

  mod.logger.PrintUserChatError(string.format(rggm.L[swapFailureMessages[reason]], itemName or itemId))
end

--[[
  Coalesce BAG_UPDATE bursts into a single rescan. BAG_UPDATE fires once per bag and bursts
  while looting/vendoring; without debouncing each event runs a full synchronous inventory scan
  (me.GetItemsForInventoryType over bags 0-4). The pending guard ensures only one refresh runs
  per burst.
]]--
function me.RequestBagUpdate()
  if bagUpdatePending then return end

  bagUpdatePending = true

  C_Timer.After(RGGM_CONSTANTS.BAG_UPDATE_DEBOUNCE_DELAY, function()
    bagUpdatePending = false

    -- refresh the change menu items after an item was equipped
    if _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CHANGE_FRAME]:IsVisible() then
      mod.gearBarChangeMenu.UpdateChangeMenu()
    end

    if mod.configuration.IsTrinketMenuEnabled() then
      mod.trinketMenu.UpdateTrinketMenu()
    end
  end)
end

--[[
  Retrieve all items from inventory bags matching any type of
    INVTYPE_HEAD
    INVTYPE_NECK
    INVTYPE_SHOULDER
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
    INVTYPE_HOLDABLE
    INVTYPE_RANGED
    INVTYPE_THROWN
    INVTYPE_RANGEDRIGHT
    INVTYPE_RELIC
    INVTYPE_AMMO

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

  for _, entry in ipairs(mod.itemLocationCache.GetBagEntries()) do
    -- runes are not cached (engraving fires no bag event) - read live per occupied slot
    local rune = mod.engrave.GetRuneForInventorySlot(entry.bagNumber, entry.bagPos)
    local itemName, _, itemRarity, _, _, _, _, _, equipSlot, itemIcon = C_Item.GetItemInfo(entry.itemId)

    for it = 1, #inventoryType do
      if equipSlot == inventoryType[it] then
        if itemRarity >= mod.configuration.GetFilterItemQuality() then
          if not items[idx] then
            items[idx] = {}
          end

          items[idx].bag = entry.bagNumber
          items[idx].slot = entry.bagPos
          items[idx].name = itemName
          items[idx].icon = itemIcon
          items[idx].id = entry.itemId
          items[idx].equipSlot = equipSlot
          items[idx].quality = itemRarity
          items[idx].enchantId = entry.enchantId
          items[idx].rune = rune or nil

          idx = idx + 1
        else
          mod.logger.LogDebug(me.tag, "Ignoring item because its quality is lower than setting "
            .. mod.configuration.GetFilterItemQuality())
        end
      end
    end
  end

  return items
end

--[[
  Switch items from one to another considering both itemId and enchantId and a target slot

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

  @param {table} item
]]--
function me.EquipItemByItemAndEnchantId(item)
  if not item then return end

  mod.logger.LogDebug(me.tag, "EquipItem: " .. item.itemId .. " in slot: " .. item.slotId)
  --[[
    Blizzard blocks weapons from being switched by addons during combat. Because of this
    all items are added to the combatqueue if the player is in combat.
  ]]--
  if UnitAffectingCombat(RGGM_CONSTANTS.UNIT_ID_PLAYER) or mod.common.IsPlayerReallyDead()
    or mod.combatQueue.IsEquipChangeBlocked() or mod.common.IsPlayerCasting() then
    mod.combatQueue.AddToQueue(
      tonumber(item.itemId), tonumber(item.enchantId), tonumber(item.runeAbilityId), tonumber(item.slotId)
    )
  else
    me.SwitchItems(
      tonumber(item.itemId), tonumber(item.enchantId), tonumber(item.runeAbilityId), tonumber(item.slotId)
    )
  end
end

--[[
  Whether equipping the item will displace the currently worn offhand into the bags. This is
  the case when a two-handed weapon is equipped into the mainhand slot while an offhand is worn

  @param {number} itemId
  @param {number} slotId

  @return {boolean}
    true - if equipping the item displaces the worn offhand into the bags
    false - if no offhand displacement will happen
]]--
RequiresOffhandDisplacement = function(itemId, slotId)
  if slotId ~= INVSLOT_MAINHAND then return false end

  if GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, INVSLOT_OFFHAND) == nil then
    return false
  end

  local equipSlot = select(4, C_Item.GetItemInfoInstant(itemId))

  return equipSlot == "INVTYPE_2HWEAPON"
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
  @param {number} enchantId
    Optional enchantId
  @param {number} runeAbilityId
    Optional runeAbilityId
  @param {number} slotId

  @return {string | nil}
    string - one of me.failureReason if the swap was aborted
    nil - if the swap was executed
]]--
function me.SwitchItems(itemId, enchantId, runeAbilityId, slotId)
  if CursorHasItem() then
    NotifySwapFailure(me.failureReason.cursorBusy, slotId, itemId)

    return me.failureReason.cursorBusy -- keep a queued swap for a retry once the cursor is free
  end

  if SpellIsTargeting() then
    NotifySwapFailure(me.failureReason.spellTargeting, slotId, itemId)

    return me.failureReason.spellTargeting -- keep a queued swap for a retry once targeting ended
  end

  --[[
    Equipping a two-handed weapon while an offhand is worn displaces the offhand into the bags.
    Verify a free bag slot exists before initiating the cursor-based swap - with full bags the
    client would otherwise cancel the swap after the item was already picked up
  ]]--
  if RequiresOffhandDisplacement(itemId, slotId) and not me.FindSpace() then
    NotifySwapFailure(me.failureReason.noBagSpace, slotId, itemId)
    mod.combatQueue.RemoveFromQueue(slotId)

    return me.failureReason.noBagSpace
  end

  local failureReason = me.failureReason.itemNotFound
  local bagNumber, bagPos, usedFallback = me.FindItemInBag(itemId, enchantId, runeAbilityId)

  if bagNumber and bagPos then
    local itemInfo = C_Container.GetContainerItemInfo(bagNumber, bagPos)
    local isLocked = itemInfo and itemInfo.isLocked

    if not isLocked and not IsInventoryItemLocked(slotId) then
      -- neither container item nor inventory item locked, perform swap
      C_Container.PickupContainerItem(bagNumber, bagPos)
      PickupInventoryItem(slotId)

      -- make sure to clear combatQueue
      mod.combatQueue.RemoveFromQueue(slotId)

      if usedFallback then
        local itemName = C_Item.GetItemInfo(itemId)

        mod.logger.PrintUserChatWarn(
          string.format(rggm.L["swap_fallback_to_base_item"], itemName or itemId))
      end

      return -- abort
    end

    failureReason = me.failureReason.itemLocked
  end

  --[[
    Special case for when an item can't be found in the bag. This can happen when the
    user drag and drops an item that he has equipped onto another slot. This essentially
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

  mod.logger.LogDebug(me.tag, "Was unable to switch because of failure reason: " .. failureReason)
  NotifySwapFailure(failureReason, slotId, itemId)
  mod.combatQueue.RemoveFromQueue(slotId)

  return failureReason
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

  for i = 1, #gearSlots do
    local equipedItemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlots[i].slotId)

    if equipedItemId == itemId then
      -- return the slot where the item was found
      return gearSlots[i].slotId -- found in the following slot
    end
  end

  return nil
end

--[[
  Find a bag location holding an item matching the passed itemId, enchantId and runeAbilityId.
  Candidate locations come from the item location cache; each candidate is re-verified against
  the live container link so a stale cache entry can never equip the wrong item. If the live
  contents diverged from the cache the scan retries once against a rebuilt cache

  @param {number} itemId
  @param {number} enchantId
    Optional enchantId to match
  @param {number} runeAbilityId
    Optional runeAbilityId to match
  @param {boolean} isRetry
    Internal; true when re-scanning after a stale cache was detected and invalidated

  @return {number | nil}, {number | nil}
    number - the bagNumber where the item was found
    number - the bagPos where the item was found
    nil - if the item could not be found
]]--
ScanBagsForItem = function(itemId, enchantId, runeAbilityId, isRetry)
  local locations = mod.itemLocationCache.GetItemLocations(itemId)
  local staleEntryDetected = false

  for i = 1, #locations do
    local entry = locations[i]
    local itemLink = C_Container.GetContainerItemLink(entry.bagNumber, entry.bagPos)
    local itemInfo = mod.common.GetItemInfo(itemLink)
    -- runes are not cached (engraving fires no bag event) - read live per candidate
    local rune = mod.engrave.GetRuneForInventorySlot(entry.bagNumber, entry.bagPos)

    if itemInfo.itemId == itemId then
      if me.IsEnchantIdMatching(itemInfo, enchantId) and me.IsRuneAbilityIdMatching(rune, runeAbilityId) then
        mod.logger.LogDebug(me.tag, "Found item in bag: " .. entry.bagNumber .. " at position: " .. entry.bagPos)

        return entry.bagNumber, entry.bagPos
      end
    else
      staleEntryDetected = true
    end
  end

  if staleEntryDetected and not isRetry then
    mod.logger.LogDebug(me.tag, "Item location cache diverged from live bag contents - rescanning")
    mod.itemLocationCache.Invalidate()

    return ScanBagsForItem(itemId, enchantId, runeAbilityId, true)
  end

  return nil, nil
end

--[[
  Search for an item in all bags

  If we have an enchantId set we have to consider it as well. This prevents GearMenu from equipping an item that
  has a matching itemId but a different enchantId (or no enchant at all)

  If no exact copy can be found and fallbackToBaseItem is enabled a second pass matching the
  itemId only is made (enchantId and runeAbilityId 0 act as wildcards for the matchers)

  @param {number} itemId
  @param {number} enchantId
    Optional enchantId to match
  @param {number} runeAbilityId
    Optional runeAbilityId to match

  @return {number | nil}, {number | nil}, {boolean}
    number - the bagNumber where the item was found
    number - the bagPos where the item was found
    nil - if the item could not be found
    boolean - whether the hit was found by the itemId-only fallback pass
]]--
function me.FindItemInBag(itemId, enchantId, runeAbilityId)
  mod.logger.LogDebug(me.tag, "Searching for item: " .. itemId .. " with enchant: "
      .. (enchantId or "nil") ..  " in bags")

  local bagNumber, bagPos = ScanBagsForItem(itemId, enchantId, runeAbilityId)

  if bagNumber ~= nil then
    return bagNumber, bagPos, false
  end

  -- skip the fallback pass when the strict pass was already an itemId-only wildcard scan
  if mod.configuration.IsFallbackToBaseItemEnabled() and not (enchantId == 0 and runeAbilityId == 0) then
    bagNumber, bagPos = ScanBagsForItem(itemId, 0, 0)

    if bagNumber ~= nil then
      mod.logger.LogDebug(me.tag, "Found substitute copy of item: " .. itemId .. " through fallback pass")

      return bagNumber, bagPos, true
    end
  end

  mod.logger.LogError(me.tag, "Item not found in bags")

  return nil, nil, false
end

--[[
  Search for an item in all bags and return the bagNumber and bagPos

  @param {table} itemInfo

  @return {number | nil}, {number | nil}
    number - the bagNumber where the item was found
    number - the bagPos where the item was found
    nil - if the item could not be found
]]--
function me.FindItemInBagForCursor(itemInfo)
  for i = 0, 4 do
    for j = 1, C_Container.GetContainerNumSlots(i) do
      local itemLink = C_Container.GetContainerItemLink(i, j)
      local item = mod.common.GetItemInfo(itemLink)

      if item.itemId == itemInfo.itemId and item.enchantId == itemInfo.enchantId then
        return i, j
      end
    end
  end

  return nil, nil
end

--[[
  Check if the enchantId of an item matches the passed enchantId

  @param {table} itemInfo
  @param {number} enchantId

  @return {boolean}
    true - If the enchantId of the item matches the passed enchantId
    false - If the enchantId of the item does not match the passed enchantId
]]--
function me.IsEnchantIdMatching(itemInfo, enchantId)
  --[[
    If enchantId is set to 0 we consider it to match as well. This can be the case if we don't care
    about the enchant itself and pass 0 for the enchant id
  ]]--
  if enchantId == 0 then
    return true
  end

  if itemInfo.enchantId == enchantId then
    return true
  end

  return false
end

--[[
  Check if the runeAbilityId of a rune matches the passed runeAbilityId

  @param {table} rune
  @param {number} runeAbilityId

  @return {boolean}
    true - If the runeAbilityId of the rune matches the passed runeAbilityId
    false - If the runeAbilityId of the rune does not match the passed runeAbilityId
]]--
function me.IsRuneAbilityIdMatching(rune, runeAbilityId)
  --[[
    If the rune and the runeAbilityId is nil we consider it a match. This can happen when the
    item doesn't have a rune at all or if SOD is not active and we ignore runes completely

    If runeAbilityId is set to 0 we consider it to match as well. This can be the case if we don't care
    about the rune itself and pass nil for the rune ability id
  ]]--
  if runeAbilityId == 0 or (rune == nil and runeAbilityId == nil) then
    return true
  end

  --[[
    If the rune is not nil we expect the runeAbilityId to match the passed skillLineAbilityID
  ]]--
  if rune and rune.skillLineAbilityID == runeAbilityId then
    return true
  end

  return false
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

  for bag = 0, 4 do
    local numSlots = C_Container.GetContainerNumSlots(bag)

    for slot = 1, numSlots do
      local itemLink = C_Container.GetContainerItemLink(bag, slot)
      local itemInfo = mod.common.GetItemInfo(itemLink)
      local rune = mod.engrave.GetRuneForInventorySlot(bag, slot)
      local runeAbilityId = rune and rune.skillLineAbilityID or nil
      local runeName = rune and rune.name or nil

      if itemInfo.itemId and not me.IsDuplicateItem(items, itemInfo.itemId, itemInfo.enchantId, runeAbilityId) then
        local item = me.AddItemsMatchingInventoryType(
          inventoryType,
          itemInfo.itemId,
          itemInfo.enchantId,
          runeAbilityId,
          runeName,
          mustHaveOnUse
        )

        if item then
          table.insert(items, item)
        end
      end
    end
  end

  local gearSlots = mod.gearManager.GetGearSlots()

  for _, gearSlot in ipairs(gearSlots) do
    local itemLink = GetInventoryItemLink(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlot.slotId)
    local itemInfo = mod.common.GetItemInfo(itemLink)
    local rune = mod.engrave.GetRuneForEquipmentSlot(gearSlot.slotId)
    local runeAbilityId = rune and rune.skillLineAbilityID or nil
    local runeName = rune and rune.name or nil

    if itemInfo.itemId and not me.IsDuplicateItem(items, itemInfo.itemId, itemInfo.enchantId, runeAbilityId) then
      local item = me.AddItemsMatchingInventoryType(
        inventoryType,
        itemInfo.itemId,
        itemInfo.enchantId,
        runeAbilityId,
        runeName,
        mustHaveOnUse
      )

      if item then
        table.insert(items, item)
      end
    end
  end

  return items
end

--[[
  @param {table} items
  @param {number} itemId
  @param {number} enchantId
    Optional enchantId to match
  @param {number} runeAbilityId
    Optional runeAbilityId to match

  @return {boolean}
    true  - If the list already contains an item with the passed itemId and enchantId
    false - If the list does not contain an item with the passed itemId and enchantId
]]--
function me.IsDuplicateItem(items, itemId, enchantId, runeAbilityId)
  for i = 1, #items do
    if items[i].id == itemId
      and items[i].enchantId == enchantId
      and items[i].runeAbilityId == runeAbilityId then
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
  @param {number} enchantId
    Optional enchantId
  @param {number} runeAbilityId
    Optional runeAbilityId
  @param {string} runeName
    Optional runeName
  @param {boolean} mustHaveOnUse
    true - If the items have to have an onUse effect to be considered
    false - If the items do not have an onUse effect to be considered

  @return {table, nil}
    table - If an item could be found
    nil - If no item could be found
]]--
function me.AddItemsMatchingInventoryType(inventoryType, itemId, enchantId, runeAbilityId, runeName, mustHaveOnUse)
  local item
  local itemName, _, _, _, _, _, _, _, equipSlot, itemIcon = C_Item.GetItemInfo(itemId)

  for it = 1, #inventoryType do
    if equipSlot == inventoryType[it] then
      local spellName, spellId = C_Item.GetItemSpell(itemId)

      if spellName ~= nil and spellId ~= nil or not mustHaveOnUse then
        item = {}
        item.name = itemName
        item.id = itemId
        item.enchantId = enchantId or nil
        item.runeAbilityId = runeAbilityId or nil
        item.runeName = runeName or nil
        item.texture = itemIcon
      else
        mod.logger.LogDebug(me.tag, "Skipped item: " .. itemName .. " because it has no onUse effect")
        return nil
      end
    end
  end

  return item
end

--[[
  Find the first free bag slot across the backpack and all equipped bags. Bag families
  (quiver, soul bag, ...) are not considered - the first empty slot wins, matching the
  order in which unequipped items were placed before this precheck existed

  @return {number | nil}, {number | nil}
    number - the bagNumber of the first free bag slot
    number - the bagPos of the first free bag slot
    nil - if all bag slots are occupied
]]--
function me.FindSpace()
  for i = 0, 4 do
    for j = 1, C_Container.GetContainerNumSlots(i) do
      if C_Container.GetContainerItemID(i, j) == nil then
        return i, j
      end
    end
  end

  return nil, nil
end

--[[
  Unequips the item from the referenced slot into the first free bag slot. The free slot is
  searched before the item is picked up - with full bags the action is aborted and the user
  is notified without the cursor ever holding the item

  @param {table} slot

  @return {string | nil}
    string - me.failureReason.noBagSpace if no bag space could be found for the item
    nil - if the item was unequipped (or the slot was empty to begin with)
]]--
function me.UnequipItemToBag(slot)
  local itemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, slot.slotId)

  if itemId == nil then return end -- slot is empty, nothing to unequip

  local bagNumber, bagPos = me.FindSpace()

  if bagNumber == nil then
    NotifySwapFailure(me.failureReason.noBagSpace, slot.slotId, itemId)

    return me.failureReason.noBagSpace
  end

  PickupInventoryItem(slot.slotId)

  if bagNumber == 0 then
    PutItemInBackpack()
  else
    -- PutItemInBag(mod.gearManager.GetMappedBag(bagNumber)) seems to be broken with latest patch
    C_Container.PickupContainerItem(bagNumber, bagPos)
  end

  -- if the item is still on the cursor the placement was refused (e.g. a special bag slot)
  if CursorHasItem() then
    ClearCursor()
    NotifySwapFailure(me.failureReason.noBagSpace, slot.slotId, itemId)

    return me.failureReason.noBagSpace
  end
end

--[[
  @param {number} slotId

  @param {boolean}
    true - if an item is equipped in the specific slot
    false - if no item is equipped in the specific slot
]]--
function me.HasItemEquipedInSlot(slotId)
  local equipedItemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, slotId)

  if equipedItemId then
    return true
  end

  return false
end
