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

-- luacheck: globals C_Engraving

local mod = rggm
local me = {}

mod.engrave = me

me.tag = "Engrave"

--[[
  Get the rune for a specific inventory slot

  @param {number} bagNumber
  @param {number} bagPos

  @return {table | nil}
]]--
function me.GetRuneForInventorySlot(bagNumber, bagPos)
  if not me.IsEngravingActive() then return end

  --[[
    Note there are some buggy items in SOD that are not correctly identified as engrave able such as
    Merithra's Inheritence - 220649
   ]]--
  if not C_Engraving.IsInventorySlotEngravable(bagNumber, bagPos) then
    mod.logger.LogDebug(me.tag, "Item in position " .. bagNumber .. " " .. bagPos .. " is not engrave able")
    return nil
  end

  return C_Engraving.GetRuneForInventorySlot(bagNumber, bagPos)
end

--[[
  Get the rune for a specific equipment slot

  @param {number} slotId

  @return {table | nil}
]]--
function me.GetRuneForEquipmentSlot(slotId)
  if not me.IsEngravingActive() then return end
  if not me.IsEquipmentSlotEngravable(slotId) then return end

  return C_Engraving.GetRuneForEquipmentSlot(slotId)
end

--[[
  Check if engraving is active

  @param {number) bagNumber
  @param {number} bagPos

  @return {table | nil}
]]--
function me.GetRuneForInventorySlot(bagNumber, bagPos)
  if not me.IsEngravingActive() then return end
  if not me.IsInventorySlotEngravable(bagNumber, bagPos) then return end

  return C_Engraving.GetRuneForInventorySlot(bagNumber, bagPos)
end

--[[
  Check if engraving is active

  @return {boolean}
]]--
function me.IsEngravingActive()
  if not mod.season.IsSodActive() then
    mod.logger.LogDebug(me.tag, "Season of Mastery is not active - runes are deactivated")
    return false
  end

  mod.logger.LogDebug(me.tag, "Season of Mastery is active - runes are activated")

  return true
end

--[[
  Check if an inventory slot is engrave able

  @param {number} bagNumber
  @param {number} bagPos

  @return {boolean}
]]--
function me.IsEquipmentSlotEngravable(slotId)
  local isEngravable

  if not me.IsEngravingActive() then return end

  isEngravable = C_Engraving.IsEquipmentSlotEngravable(slotId)

  if not isEngravable then
    mod.logger.LogDebug(me.tag, "Item in slot " .. slotId .. " is not engrave able")
  end

  return isEngravable
end

--[[

  Check if an inventory slot is engravable

  @param {number} bagNumber
  @param {number} bagPos

  @return {boolean}
]]--
function me.IsInventorySlotEngravable(bagNumber, bagPos)
  local isEngravable

  if not me.IsEngravingActive() then return end

  isEngravable = C_Engraving.IsInventorySlotEngravable(bagNumber, bagPos)

  if not isEngravable then
    mod.logger.LogDebug(me.tag, "Item in position " .. bagNumber .. " " .. bagPos .. " is not engrave able")
  end

  return isEngravable
end

--[[
  Refresh the list of runes
]]--
function me.RefreshRunes()
  if not me.IsEngravingActive() then return end

  C_Engraving.RefreshRunesList()
end
