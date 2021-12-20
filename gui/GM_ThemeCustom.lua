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

-- luacheck: globals CreateFrame C_Timer MouseIsOver

local mod = rggm
local me = {}

mod.themeCustom = me

me.tag = "ThemeCustom"

--[[
  Create a single gearSlot. Note that a gearSlot inherits from the SecureActionButtonTemplate to enable the usage
  of clicking items. Because of SetAttribute this function CANNOT be executed while in combat. Callers of this function
  need to check combatState before calling.

  @param {table} gearBarFrame
    The gearBarFrame where the gearSlot gets attached to
  @param {table} gearBar
  @param {number} position
    Position on the gearBar

  @return {table}
    The created gearSlot
]]--
function me.CreateGearSlot(gearBarFrame, gearBar, position)
  local gearSlot = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT .. position,
    gearBarFrame,
    "SecureActionButtonTemplate, BackdropTemplate"
  )

  me.CreateItemTexture(gearSlot, gearBar.gearSlotSize) -- create texture for icon

  gearSlot:SetSize(gearBar.gearSlotSize, gearBar.gearSlotSize)
  gearSlot:SetPoint(
    "LEFT",
    gearBarFrame,
    "LEFT",
    RGGM_CONSTANTS.GEAR_BAR_SLOT_X + (position - 1) * gearBar.gearSlotSize,
    RGGM_CONSTANTS.GEAR_BAR_SLOT_Y
  )

  local backdrop = {
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    edgeFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    tile = false,
    tileSize = 32,
    edgeSize = 20,
    insets = {
      left = 12,
      right = 12,
      top = 12,
      bottom = 12
    }
  }

  local gearSlotMetaData = gearBar.slots[position]

  if gearSlotMetaData ~= nil then
    gearSlot:SetAttribute("type1", "item")
    gearSlot:SetAttribute("item", gearSlotMetaData.slotId)
  end

  gearSlot:SetBackdrop(backdrop)
  gearSlot:SetBackdropColor(0.15, 0.15, 0.15, 1)
  gearSlot:SetBackdropBorderColor(0, 0, 0, 1)

  gearSlot.combatQueueSlot = mod.gearBar.CreateCombatQueueSlot(gearSlot, gearBar.gearSlotSize)
  gearSlot.keyBindingText = mod.gearBar.CreateKeyBindingText(gearSlot, gearBar.gearSlotSize)
  gearSlot.position = position
  gearSlot.highlightFrame = me.CreateHighlightFrame(gearSlot)
  gearSlot.cooldownOverlay = mod.cooldown.CreateCooldownOverlay(
    gearSlot,
    RGGM_CONSTANTS.ELEMENT_SLOT_COOLDOWN_FRAME,
    gearBar.gearSlotSize
  )

  mod.gearBar.UpdateGearSlotTexture(gearSlot, gearSlotMetaData)
  mod.cooldown.UpdateGearSlotCooldown(gearBar, gearSlot, gearSlotMetaData)
  me.UpdateSlotTextureAttributes(gearSlot, gearBar.gearSlotSize)
  mod.gearBar.SetupEvents(gearSlot)

  return gearSlot
end

--[[
  Create a texture for the icon of whatever item is currently in the gearSlot

  @param {table} slot
  @param {number} slotSize
]]--
function me.CreateItemTexture(slot, slotSize)
  slot.itemTexture = slot:CreateTexture()
  slot.itemTexture:SetSize(slotSize - 1, slotSize - 1)
  slot.itemTexture:SetPoint(
    "CENTER",
    0, 0
  )
end

--[[
  Create a highlight frame and attach it to the passed slot

  @param {table} slot

  @return {table}
    The created highlightFrame
]]--
function me.CreateHighlightFrame(slot)
  local highlightFrame = CreateFrame("FRAME", nil, slot, "BackdropTemplate")
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
  Slot prepare texture

  @param {table} slot
  @param {number} slotSize
]]--
function me.UpdateSlotTextureAttributes(slot, slotSize)
  local texture = slot.itemTexture
  texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  texture:SetPoint(
    "TOPLEFT",
    slot,
    "TOPLEFT",
    slotSize * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER,
    slotSize * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER * -1
  )
  texture:SetPoint(
    "BOTTOMRIGHT",
    slot,
    "BOTTOMRIGHT",
    slotSize * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER * -1,
    slotSize * RGGM_CONSTANTS.GEAR_BAR_SLOT_BORDER_MODIFIER
  )
end

--[[
  EVENTS

  Custom theme event implementations
]]--

--[[
  Callback for a gearBarSlot OnClick

  @param {table} self
  @param {string} button
]]--
function me.GearSlotOnClick(self, button)
  self.highlightFrame:Show()

  if button == "LeftButton" then
    self.highlightFrame:SetBackdropBorderColor(unpack(RGGM_CONSTANTS.HIGHLIGHT.highlight))
  elseif button == "RightButton" then
    self.highlightFrame:SetBackdropBorderColor(unpack(RGGM_CONSTANTS.HIGHLIGHT.remove))
  end

  C_Timer.After(.5, function()
    if MouseIsOver(self:GetParent()) then
      self.highlightFrame:SetBackdropBorderColor(unpack(RGGM_CONSTANTS.HIGHLIGHT.hover))
    else
      self.highlightFrame:Hide()
    end
  end)
end

--[[
  Callback for a gearSlot OnEnter

  @param {table} self
]]--
function me.GearSlotOnEnter(self)
  self.highlightFrame:SetBackdropBorderColor(unpack(RGGM_CONSTANTS.HIGHLIGHT.hover))
  self.highlightFrame:Show()
end

--[[
  Callback for a gearSlot OnLeave

  @param {table} self
]]--
function me.GearSlotOnLeave(self)
  self.highlightFrame:Hide()
end
