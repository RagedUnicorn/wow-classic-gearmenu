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

-- luacheck: globals GetItemInfo GM_AddToCombatQueue GM_RemoveFromCombatQueue

--[[
  Macro bridge for using certain functions from gearmenu directly in a macro
]]--
local mod = rggm
local me = {}
mod.macro = me

me.tag = "Macro"

--[[
  Global macrobridge for switching an item into a specific slot

  @param {number} itemId
  @param {number} slotId
]]--
function GM_AddToCombatQueue(itemId, slotId)
  assert(type(itemId) == "number", string.format(
    "bad argument #1 to `GM_AddToCombatQueue` (expected number got %s)", type(itemId)))

  assert(type(slotId) == "number", string.format(
    "bad argument #2 to `GM_AddToCombatQueue` (expected number got %s)", type(slotId)))

  local equipSlot = me.CheckItemIdValidity(itemId)

  if equipSlot == nil then return end

  if me.CheckSlotValidity(equipSlot, slotId) then
    mod.combatQueue.AddToQueue(itemId, slotId)
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
  assert(type(slotId) == "number", string.format(
    "bad argument #1 to `GM_RemoveFromCombatQueue` (expected number got %s)", type(slotId)))

  mod.combatQueue.RemoveFromQueue(slotId)
end

--[[
  Checks if any metadata can be found for a certain itemId. If no metadata can be retrieved
  we assume that it is an invalid itemId

  @param {number} itemId

  @return {string | nil}
]]--
function me.CheckItemIdValidity(itemId)
  local _, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemId)

  if equipSlot == nil then
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
