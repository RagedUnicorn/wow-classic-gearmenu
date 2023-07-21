--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT COOLDOWN_TYPE_NORMAL CooldownFrame_Clear CooldownFrame_Set
-- luacheck: globals GetInventoryItemID C_Container

local mod = rggm
local me = {}
mod.cooldown = me

me.tag = "Cooldown"

--[[
  Create a cooldown overlay and attach it to the passed slot

  @param {table} slot
  @param {string} frameName
  @param {number} slotSize
  @param {number} uiTheme

  @param {table}
    The created cooldownOverlay
]]--
function me.CreateCooldownOverlay(slot, frameName, slotSize, uiTheme)
  local cooldownOverlay = CreateFrame(
    "Cooldown",
    frameName,
    slot,
    "CooldownFrameTemplate"
  )

  if uiTheme == RGGM_CONSTANTS.UI_THEME_CLASSIC then
    cooldownOverlay:ClearAllPoints()
    cooldownOverlay:SetPoint("CENTER", slot, 0, 0)
    cooldownOverlay:SetSize(slotSize - 2, slotSize - 2)
  else
    cooldownOverlay:SetAllPoints(slot)
  end

  -- set fontsize based on slotsize
  cooldownOverlay:GetRegions()
                 :SetFont(
    STANDARD_TEXT_FONT,
    slotSize * RGGM_CONSTANTS.GEAR_BAR_COOLDOWN_TEXT_MODIFIER
  )
  cooldownOverlay:SetHideCountdownNumbers(false)
  cooldownOverlay.currentCooldownType = COOLDOWN_TYPE_NORMAL

  return cooldownOverlay
end

--[[
  Update the cooldown of a single gearSlot

  @param {table} gearBar
  @param {table} uiSlot
  @param {table} gearSlotMetaData
]]--
function me.UpdateGearSlotCooldown(gearBar, uiSlot, gearSlotMetaData)
  local itemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlotMetaData.slotId)

  if itemId ~= nil then
    if mod.gearBarManager.IsShowCooldownsEnabled(gearBar.id) then
      local startTime, duration = C_Container.GetItemCooldown(itemId)
      CooldownFrame_Set(uiSlot.cooldownOverlay, startTime, duration, true)

      return
    else
      CooldownFrame_Clear(uiSlot.cooldownOverlay)
    end
  else
    CooldownFrame_Clear(uiSlot.cooldownOverlay)
  end
end

--[[
  @param {table} uiGearSlot
  @param {number} slotSize
]]--
function me.UpdateGearSlotCooldownOverlaySize(uiGearSlot, slotSize)
  uiGearSlot.cooldownOverlay:SetSize(slotSize, slotSize)
  uiGearSlot.cooldownOverlay:GetRegions()
            :SetFont(
    STANDARD_TEXT_FONT,
    slotSize * RGGM_CONSTANTS.GEAR_BAR_COOLDOWN_TEXT_MODIFIER
  )
end
