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

-- luacheck: globals C_Item GM_AddToCombatQueue GM_RemoveFromCombatQueue
-- luacheck: globals GM_RegisterSwapListener GM_UnregisterSwapListener

--[[
  Macro bridge for using certain functions from gearmenu directly in a macro
]]--
local mod = rggm
local me = {}
mod.macro = me

me.tag = "Macro"

--[[
  Third-party callbacks registered through GM_RegisterSwapListener. Notified by
  me.FireSwapEvent whenever a swap is queued, unqueued or completed
]]--
local swapListeners = {}

--[[
  Global macrobridge for switching an item into a specific slot

  @param {number} itemId
  @param {number} enchantId
    Optional enchantId to consider when equipping the item
  @param {number} runeAbilityId
    Optional runeAbilityId to consider
  @param {number} slotId
]]--
function GM_AddToCombatQueue(itemId, enchantId, runeAbilityId, slotId)
  if type(itemId) ~= "number" then
    mod.logger.PrintUserChatError(
      string.format(rggm.L["macro_invalid_argument"], 1, "GM_AddToCombatQueue", type(itemId)))
    return
  end

  if enchantId ~= nil and type(enchantId) ~= "number" then
    mod.logger.PrintUserChatError(
      string.format(rggm.L["macro_invalid_argument"], 2, "GM_AddToCombatQueue", type(enchantId)))
    return
  end

  if runeAbilityId ~= nil and type(runeAbilityId) ~= "number" then
    mod.logger.PrintUserChatError(
      string.format(rggm.L["macro_invalid_argument"], 3, "GM_AddToCombatQueue", type(runeAbilityId)))
    return
  end

  if type(slotId) ~= "number" then
    mod.logger.PrintUserChatError(
      string.format(rggm.L["macro_invalid_argument"], 4, "GM_AddToCombatQueue", type(slotId)))
    return
  end

  local equipSlot = me.CheckItemIdValidity(itemId)

  if equipSlot == nil then return end

  if me.CheckSlotValidity(equipSlot, slotId) then
    mod.combatQueue.AddToQueue(itemId, enchantId, runeAbilityId, slotId)
  else
    mod.logger.PrintUserChatError(string.format(rggm.L["unable_to_find_equipslot"], itemId))
    return
  end
end

--[[
  Global macrobridge for clearing a certain slot

  @param {number} slotId
]]
function GM_RemoveFromCombatQueue(slotId)
  if type(slotId) ~= "number" then
    mod.logger.PrintUserChatError(
      string.format(rggm.L["macro_invalid_argument"], 1, "GM_RemoveFromCombatQueue", type(slotId)))
    return
  end

  mod.combatQueue.RemoveFromQueue(slotId)
end

--[[
  Public registration for third-party addons that want to be notified about swap-lifecycle
  events. The callback is invoked as callback(eventName, slotId, itemId) where eventName is one
  of RGGM_CONSTANTS.SWAP_EVENT_QUEUED, SWAP_EVENT_UNQUEUED or SWAP_EVENT_COMPLETED. Registering
  the same callback twice is a no-op

  @param {function} callback
]]--
function GM_RegisterSwapListener(callback)
  if type(callback) ~= "function" then
    mod.logger.PrintUserChatError(
      string.format(rggm.L["macro_invalid_listener"], "GM_RegisterSwapListener", type(callback)))
    return
  end

  for i = 1, #swapListeners do
    if swapListeners[i] == callback then return end -- already registered
  end

  table.insert(swapListeners, callback)
  mod.logger.LogDebug(me.tag, "Registered new swap listener")
end

--[[
  Public deregistration counterpart to GM_RegisterSwapListener. Unknown callbacks are ignored

  @param {function} callback
]]--
function GM_UnregisterSwapListener(callback)
  for i = 1, #swapListeners do
    if swapListeners[i] == callback then
      table.remove(swapListeners, i)
      mod.logger.LogDebug(me.tag, "Unregistered swap listener")

      return
    end
  end
end

--[[
  Notify all registered swap listeners about a swap-lifecycle event. Each listener is isolated
  with pcall so a broken third-party callback can never break the swap path itself; errors are
  routed to the logger

  @param {string} eventName
    One of RGGM_CONSTANTS.SWAP_EVENT_QUEUED, SWAP_EVENT_UNQUEUED or SWAP_EVENT_COMPLETED
  @param {number} slotId
  @param {number} itemId
]]--
function me.FireSwapEvent(eventName, slotId, itemId)
  for i = 1, #swapListeners do
    local status, err = pcall(swapListeners[i], eventName, slotId, itemId)

    if not status then
      mod.logger.LogError(me.tag, "Swap listener failed for event '" .. eventName .. "': " .. tostring(err))
    end
  end
end

--[[
  Checks if any metadata can be found for a certain itemId. If no metadata can be retrieved
  we assume that it is an invalid itemId

  @param {number} itemId

  @return {string | nil}
]]--
function me.CheckItemIdValidity(itemId)
  local _, _, _, equipSlot = C_Item.GetItemInfoInstant(itemId)

  if equipSlot == nil or equipSlot == "" then
    mod.logger.PrintUserChatError(string.format(rggm.L["unable_to_find_item"], itemId))
    return nil
  end

  return equipSlot
end

--[[
  Searches for a valid slot in gearManager

  @param {string} equipSlot
  @param {number} slotId

  @return {boolean}
    True  - If a valid slot could be found
    False - If a valid slot could not be found
]]--
function me.CheckSlotValidity(equipSlot, slotId)
  local gearSlots = mod.gearManager.GetGearSlotsForType(equipSlot)

  for i = 1, #gearSlots do
    mod.logger.LogDebug(me.tag,
      string.format("Comparing valid slot %s against passed slot %s", gearSlots[i].slotId, slotId)
    )
    if gearSlots[i].slotId == slotId then
      return true -- abort when valid slot was found
    end
  end

  return false
end
