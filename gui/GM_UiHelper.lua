--[[
  MIT License

  Copyright (c) 2021 Michael Wiesendanger

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

-- luacheck: globals CreateFrame GetTime STANDARD_TEXT_FONT COOLDOWN_TYPE_NORMAL

local mod = rggm
local me = {}

mod.uiHelper = me

me.tag = "UiHelper"

--[[
  Slot prepare texture

  @param {table} slot
  @param {number} slotSize
    Optional slotSize
]]--
function me.UpdateSlotTextureAttributes(slot, slotSize)
  if slot:GetNormalTexture() == nil then
    -- set a dummy texture - otherwise GetNormalTexture will return nil
    slot:SetNormalTexture("//dummy")
  end

  local actualSlotSize = slotSize or RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE
  local texture = slot:GetNormalTexture()
  texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  texture:SetPoint(
    "TOPLEFT",
    slot,
    "TOPLEFT",
    actualSlotSize * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER,
    actualSlotSize * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER * -1
  )
  texture:SetPoint(
    "BOTTOMRIGHT",
    slot,
    "BOTTOMRIGHT",
    actualSlotSize * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER * -1,
    actualSlotSize * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER
  )
end

--[[
  Create a cooldown overlay and attach it to the passed slot

  @param {table} slot
  @param {string} frameName
  @param {number} slotSize

  @param {table}
    The created cooldownOverlay
]]--
function me.CreateCooldownOverlay(slot, frameName, slotSize)
  local cooldownOverlay = CreateFrame(
    "Cooldown",
    frameName,
    slot,
    "CooldownFrameTemplate"
  )

  cooldownOverlay:SetAllPoints(slot)
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
  Create a highlight frame and attach it to the passed slot

  @param {table} slot

  @return {table}
    The created highlightFrame
]]--
function me.CreateHighlightFrame(slot)
  local highlightFrame = CreateFrame("FRAME", nil, slot, "BackdropTemplate")
  highlightFrame:SetFrameLevel(slot:GetFrameLevel() + 1)
  highlightFrame:SetPoint("TOPLEFT", slot, "TOPLEFT")
  highlightFrame:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT")

  local innerBackdrop = {
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    edgeFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_inner_glow",
    tile = false,
    tileSize = 16,
    edgeSize = 16,
    insets = {
      left = 10,
      right = 10,
      top = 10,
      bottom = 10
    }
  }

  highlightFrame:SetBackdrop(innerBackdrop)
  highlightFrame:SetBackdropColor(1, 1, 1, 0)
  highlightFrame:Hide()

  return highlightFrame
end

--[[
  Create a dropwdownbutton for a dropdown menu

  @param {string} text
  @param {string} value
  @param {function} callback

  @return {table} button
]]--
function me.CreateDropdownButton(text, value, callback)
  local button = mod.libUiDropDownMenu.UiDropDownMenu_CreateInfo()

  button.text = text
  button.value = value
  button.func = callback

  return button
end
