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

-- luacheck: globals C_Engraving CreateFrame

local mod = rggm
local me = {}

mod.engraveFrame = me

me.tag = "EngraveFrame"

--[[
  Note that rune slots are a feature of Season of Discovery and are not available in the classic version

  Rune slot are created even if the player has them disabled in the configuration they are just not displayed.
  All slots receive a rune slot even though not all slots can actually have a rune engraved. A gearmenu slot can
  change its type at any point though and thus it is required for all slots to be able to handle runes.

  @param {table} gearSlot
  @param {number} gearSlotSize

  @return {table}
    The created runeSlot
]]--
function me.CreateRuneSlot(gearSlot, gearSlotSize)
  if not mod.engrave.IsEngravingActive() then return end

  local runeSlot = CreateFrame("Frame", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_RUNE_SLOT, gearSlot)
  local runeSlotSize = gearSlotSize * RGGM_CONSTANTS.GEAR_BAR_RUNE_SLOT_SIZE_MODIFIER

  runeSlot:SetSize(
    runeSlotSize,
    runeSlotSize
  )
  runeSlot:SetPoint("BOTTOMRIGHT", gearSlot)
  -- putting the runeslot above the cooldown overlay
  runeSlot:SetFrameLevel(runeSlot:GetParent():GetFrameLevel() + 2)

  local iconHolderTexture = runeSlot:CreateTexture(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_ICON_TEXTURE_NAME,
    "BACKGROUND",
    nil
  )
  iconHolderTexture:SetPoint("TOPLEFT", runeSlot, "TOPLEFT")
  iconHolderTexture:SetPoint("BOTTOMRIGHT", runeSlot, "BOTTOMRIGHT")
  iconHolderTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

  runeSlot.icon = iconHolderTexture

  return runeSlot
end

--[[
  Note that rune slots are a feature of Season of Discovery and are not available in the classic version
  Update all runeSlot textures of the passed gearBar

  @param {table} gearBar
]]--
function me.UpdateGearBarRuneSlotTextures(gearBar)
  if not mod.season.IsSodActive() then return end

  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)

  for index, gearSlotMetaData in pairs(gearBar.slots) do
    me.UpdateRuneSlotTexture(uiGearBar.gearSlotReferences[index], gearSlotMetaData)
  end
end

--[[
  Update the visual representation of the rune slot on

  @param {table} gearSlot
  @param {table} gearSlotMetaData
]]--
function me.UpdateRuneSlotTexture(gearSlot, gearSlotMetaData)
  if not mod.engrave.IsEquipmentSlotEngravable(gearSlotMetaData.slotId) then return end

  if not mod.configuration.IsRuneSlotsEnabled() then
    gearSlot.runeSlot.icon:SetTexture(nil)
    return
  end

  mod.logger.LogDebug(me.tag, "Updating rune slot for slotId - " .. gearSlotMetaData.slotId)
  local rune = mod.engrave.GetRuneForEquipmentSlot(gearSlotMetaData.slotId)

  if rune ~= nil then
    gearSlot.runeSlot.icon:SetTexture(rune.iconTexture)
  else
    gearSlot.runeSlot.icon:SetTexture(nil)
  end
end


