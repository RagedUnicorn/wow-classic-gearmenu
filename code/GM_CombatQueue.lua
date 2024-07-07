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

-- luacheck: globals GetItemInfo C_LossOfControl InCombatLockdown

local mod = rggm
local me = {}
mod.combatQueue = me

me.tag = "CombatQueue"

local combatQueueStore = {}
--[[
  Tracks whether an equipment change is blocked or not based on loss of control effects.
  Does not include other possible states such as in combat that can prevent an equipment change
]]--
local isEquipChangeBlocked = false

--[[
  Getter for combatQueueStore

  @return {table}
]]--
function me.GetCombatQueueStore()
  return combatQueueStore
end

--[[
  Add item to combatQueue. There can only be one item per slot

  @param {number} itemId
    itemId to consider when equipping the item
  @param {number} enchantId
    Optional enchantId to consider when equipping the item
  @param {number} runeAbilityId
    Optional runeAbilityId

  @param {number} slotId
    The slotId to add the item to
]]--
function me.AddToQueue(itemId, enchantId, runeAbilityId, slotId)
  if not itemId or not slotId then return end

  assert(type(itemId) == "number", string.format(
    "bad argument #1 to `AddToQueue` (expected number got %s)", type(itemId)))

  if enchantId ~= nil then
    assert(type(enchantId) == "number", string.format(
      "bad argument #2 to `AddToQueue` (expected number got %s)", type(enchantId)))
  end

  assert(type(slotId) == "number", string.format(
    "bad argument #3 to `AddToQueue` (expected number got %s)", type(slotId)))

  combatQueueStore[slotId] = { itemId, enchantId, runeAbilityId }

  mod.logger.LogDebug(me.tag, "Added item with itemId " .. itemId .. " and enchantId " .. (enchantId or "nil") ..
    " in slotId " .. slotId .. " to combatQueueStore")

  mod.gearBar.UpdateCombatQueue(itemId, slotId)
  mod.ticker.StartTickerCombatQueue()
end

--[[
  Remove item from combatQueue

  @param {number} slotId
]]--
function me.RemoveFromQueue(slotId)
  if not slotId then return end

  assert(type(slotId) == "number", string.format(
    "bad argument #1 to `RemoveFromQueue` (expected number got %s)", type(slotId)))

  local itemId
  -- get item from queue that is about to be removed
  if combatQueueStore[slotId] ~= nil then
    itemId = combatQueueStore[slotId][1]
  else
    -- if no item is registered in queue for that specific slotId
    mod.logger.LogDebug(me.tag, "No item in queue for slotId - " .. slotId)
    return
  end

  combatQueueStore[slotId] = nil
  mod.logger.LogDebug(me.tag, "Removed item with id " .. itemId .. " in slotId "
    .. slotId .. " from combatQueueStore")
  mod.gearBar.UpdateCombatQueue(nil, slotId)
end

--[[
  Process through combat queue and equip item if there is one waiting in the queue
]]--
function me.ProcessQueue()
  if me.IsCombatQueueEmpty() then
    -- stop combat queue ticker when combat queue is empty
    mod.ticker.StopTickerCombatQueue()
    return
  end

  -- cannot change gear while player is in combat or is casting
  if InCombatLockdown() or mod.common.IsPlayerCasting() or mod.common.IsPlayerReallyDead() then return end

  -- update queue for all slot positions
  for _, gearSlot in pairs(mod.gearManager.GetGearSlots()) do
    if combatQueueStore[gearSlot.slotId] ~= nil then
      local item = {}
      item.itemId = combatQueueStore[gearSlot.slotId][1]
      item.enchantId = combatQueueStore[gearSlot.slotId][2] or nil
      item.runeAbilityId = combatQueueStore[gearSlot.slotId][3] or nil
      item.slotId = gearSlot.slotId
      mod.itemManager.EquipItemByItemAndEnchantId(item)
    end
  end
end

--[[
  @return {boolean}
    true - If the combatQueue is completely empty
    false - If the combatQueue is not empty
]]--
function me.IsCombatQueueEmpty()
  if next(combatQueueStore) == nil then
    return true
  end

  return false
end

--[[
  Checks whether the player has a loss of control effect on him that prevents him from changing equipment.

  Possible values for locType:

  | SCHOOL_INTERRUPT | IRRELEVANT |
  | DISARM           | IRRELEVANT |
  | PACIFYSILENCE    | IRRELEVANT |
  | SILENCE          | IRRELEVANT |
  | PACIFY           | IRRELEVANT |
  | ROOT             | IRRELEVANT |
  | STUN_MECHANIC    | RELEVANT   |
  | STUN             | RELEVANT   |
  | FEAR_MECHANIC    | RELEVANT   |
  | FEAR             | RELEVANT   |
  | CHARM            | RELEVANT   |
  | CONFUSE          | RELEVANT   |
  | POSSESS          | RELEVANT   |
]]--
function me.UpdateEquipChangeBlockStatus()
  local relevantLocTypes = {
    ["SCHOOL_INTERRUPT"] = false,
    ["DISARM"] = false,
    ["PACIFYSILENCE"] = false,
    ["SILENCE"] = false,
    ["PACIFY"] = false,
    ["ROOT"] = false,
    ["STUN_MECHANIC"] = true,
    ["STUN"] = true,
    ["FEAR_MECHANIC"] = true,
    ["FEAR"] = true,
    ["CHARM"] = true,
    ["CONFUSE"] = true,
    ["POSSESS"] = true
  }
  local eventIndex = C_LossOfControl.GetActiveLossOfControlDataCount()

  while eventIndex > 0 do
    local event = C_LossOfControl.GetActiveLossOfControlData(eventIndex)

    mod.logger.LogDebug(me.tag, "UpdateEquipChangeBlockStatus detected locType: " .. event.locType)

    if relevantLocTypes[event.locType] then
      isEquipChangeBlocked = true

      return
    end

    eventIndex = eventIndex - 1
  end

  isEquipChangeBlocked = false
  mod.ticker.StartTickerCombatQueue()
end

--[[
  @return {boolean}
    true - If equipment change is blocked
    false - If equipment change is not blocked
]]--
function me.IsEquipChangeBlocked()
  return isEquipChangeBlocked
end
