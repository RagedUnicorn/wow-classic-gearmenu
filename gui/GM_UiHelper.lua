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

-- luacheck: globals CreateFrame GetTime UIDropDownMenu_CreateInfo STANDARD_TEXT_FONT

local mod = rggm
local me = {}

mod.uiHelper = me

me.tag = "UiHelper"

--[[
  Slot prepare texture

  @param {table} slot
]]--
function me.UpdateSlotTextureAttributes(slot)
  if slot:GetNormalTexture() == nil then
    -- set a dummy texture - otherwise GetNormalTexture will return nil
    slot:SetNormalTexture("//dummy")
  end

  local texture = slot:GetNormalTexture()
  texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  texture:SetPoint(
    "TOPLEFT",
    slot,
    "TOPLEFT",
    mod.configuration.GetSlotSize() * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER,
    mod.configuration.GetSlotSize() * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER * -1
  )
  texture:SetPoint(
    "BOTTOMRIGHT",
    slot,
    "BOTTOMRIGHT",
    mod.configuration.GetSlotSize() * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER * -1,
    mod.configuration.GetSlotSize() * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER
  )
end

--[[
  Create a cooldown overlay and attach it to the passed slot

  @param {table} slot
  @param {string} frameName
  @param {number} slotSize
]]--
function me.CreateCooldownOverlay(slot, frameName, slotSize)
  local cooldownOverlay = CreateFrame(
    "Cooldown",
    frameName,
    slot,
    "CooldownFrameTemplate"
  )
  cooldownOverlay:SetSize(slotSize, slotSize)
  cooldownOverlay:SetAllPoints()
  cooldownOverlay:Hide()
  -- set fontsize based on slotsize
  cooldownOverlay:GetRegions()
    :SetFont(
      STANDARD_TEXT_FONT,
      mod.configuration.GetSlotSize() * RGGM_CONSTANTS.GEAR_BAR_CHANGE_COOLDOWN_TEXT_MODIFIER
    )

  slot.cooldownOverlay = cooldownOverlay
end

--[[
  Create a highlight frame and attach it to the passed slot

  @param {table} slot
]]--
function me.CreateHighlightFrame(slot)
  local highlightFrame = CreateFrame("FRAME", nil, slot)
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

  slot.highlightFrame = highlightFrame
end

--[[
  Update visible cooldowns for slots on both the gearBar and the changeMenu
]]--
function me.UpdateSlotCooldown()
  mod.gearBar.UpdateGearSlotCooldown()
  mod.changeMenu.UpdateChangeMenuCooldownState()
end

--[[
  @param {widget} frame
  @param {number} start
  @param {number} duration
]]--
function me.SetCooldown(frame, start, duration)
  local cooldown = duration - (GetTime() - start)
  local cooldownText

  if start == 0 then
    -- item has no cooldown
    frame:SetText("")
  elseif cooldown < 3 and not frame:GetText() then
    -- do not display global cooldown
    -- if there is already a text it is just a cooldown that entered into this state
    return
  else
    if cooldown < 60 then
      cooldownText = math.floor(cooldown + .5) .. " s"
    elseif cooldown < 3600 then
      cooldownText = math.ceil(cooldown / 60) .. " m"
    else
      cooldownText = math.ceil(cooldown / 3600) .. " h"
    end

    frame:SetText(cooldownText)
  end
end

--[[
  Create a dropwdownbutton for a dropdown menu

  @param {string} text
  @param {string} value
  @param {function} callback

  @return {table} button
]]--
function me.CreateDropdownButton(text, value, callback)
  local button = UIDropDownMenu_CreateInfo()

  button.text = text
  button.value = value
  button.func = callback

  return button
end

--[[
  Load a frames position from SavedVariablesPerCharacter

  @param {table} slot
]]--
function me.LoadFramePosition(frame, frameName)
  local framePosition = mod.configuration.GetUserPlacedFramePosition(frameName)
  --[[
    Set user frame position if there is one saved
  ]]--
  if framePosition ~= nil then
    frame:ClearAllPoints() -- very important to clear all points first
    frame:SetPoint(
      framePosition.point,
      framePosition.relativeTo,
      framePosition.relativePoint,
      framePosition.posX,
      framePosition.posY
    )
  else
    -- initial position for first time use
    frame:SetPoint("CENTER", 0, 0)
  end
end

--[[
  Hide cooldowns for both bagged and worn items
]]--
function me.HideCooldowns()
  mod.gearBar.HideCooldowns()
  mod.changeMenu.HideCooldowns()
end

--[[
  Show cooldowns for both bagged and worn items
]]--
function me.ShowCooldowns()
  mod.gearBar.ShowCooldowns()
  mod.gearBar.UpdateGearSlotCooldown()
  mod.changeMenu.ShowCooldowns()
end
