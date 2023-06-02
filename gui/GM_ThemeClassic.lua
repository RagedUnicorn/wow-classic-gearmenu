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

-- luacheck: globals CreateFrame

local mod = rggm
local me = {}

mod.themeClassic = me

me.tag = "ThemeClassic"

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
    "SecureActionButtonTemplate"
  )

  gearSlot:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  gearSlot:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
  gearSlot:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

  local normalTexture = gearSlot:GetNormalTexture()
  normalTexture:SetTexCoord(0.19, 0.79, 0.19, 0.79)
  normalTexture:SetSize(gearBar.gearSlotSize, gearBar.gearSlotSize)

  gearSlot:SetSize(gearBar.gearSlotSize, gearBar.gearSlotSize)
  gearSlot:SetPoint(
    "LEFT",
    gearBarFrame,
    "LEFT",
    RGGM_CONSTANTS.GEAR_BAR_SLOT_X + (position - 1) * gearBar.gearSlotSize,
    RGGM_CONSTANTS.GEAR_BAR_SLOT_Y
  )

  local gearSlotMetaData = gearBar.slots[position]

  if gearSlotMetaData ~= nil then
    gearSlot:SetAttribute("type1", "item")
    gearSlot:SetAttribute("item", gearSlotMetaData.slotId)
  end

  mod.uiHelper.CreateItemTexture(gearSlot, gearBar.gearSlotSize)
  gearSlot.combatQueueSlot = mod.gearBar.CreateCombatQueueSlot(gearSlot, gearBar.gearSlotSize)
  gearSlot.keyBindingText = mod.gearBar.CreateKeyBindingText(gearSlot, gearBar.gearSlotSize)
  gearSlot.position = position
  gearSlot.cooldownOverlay = mod.cooldown.CreateCooldownOverlay(
    gearSlot,
    RGGM_CONSTANTS.ELEMENT_SLOT_COOLDOWN_FRAME,
    gearBar.gearSlotSize,
    RGGM_CONSTANTS.UI_THEME_CLASSIC
  )

  mod.gearBar.SetupEvents(gearSlot)

  return gearSlot
end

--[[
  Create a single changeSlot

  @param {table} changeMenuFrame
  @param {number} position

  @return {table}
    The created changeSlot
]]--
function me.CreateChangeSlot(changeMenuFrame, position)
  local changeSlot = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CHANGE_SLOT .. position,
    changeMenuFrame
  )

  changeSlot:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  changeSlot:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
  changeSlot:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

  local normalTexture = changeSlot:GetNormalTexture()
  normalTexture:SetTexCoord(0.19, 0.79, 0.19, 0.79)
  normalTexture:SetSize(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE, RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE)

  mod.uiHelper.CreateItemTexture(changeSlot, RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE)
  changeSlot.cooldownOverlay = mod.cooldown.CreateCooldownOverlay(
    changeSlot,
    RGGM_CONSTANTS.ELEMENT_SLOT_COOLDOWN_FRAME,
    RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE
  )

  mod.gearBarChangeMenu.SetupEvents(changeSlot)

  return changeSlot
end

--[[
  @param {table} trinketMenuFrame
    The trinketMenuFrame to attach the created slot to
  @param {number} position
    Position withing the trinketMenu

  @return {table}
    The created trinketMenuSlot
]]--
function me.CreateTrinketSlot(trinketMenuFrame, position)
  local trinketMenuSlot = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_SLOT .. position,
    trinketMenuFrame
  )

  trinketMenuSlot:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  trinketMenuSlot:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
  trinketMenuSlot:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

  local normalTexture = trinketMenuSlot:GetNormalTexture()
  local trinketMenuSlotSize = mod.configuration.GetTrinketMenuSlotSize()
  normalTexture:SetTexCoord(0.19, 0.79, 0.19, 0.79)
  normalTexture:SetSize(trinketMenuSlotSize, trinketMenuSlotSize)

  mod.uiHelper.CreateItemTexture(trinketMenuSlot, trinketMenuSlotSize)
  trinketMenuSlot.cooldownOverlay = mod.cooldown.CreateCooldownOverlay(
    trinketMenuSlot,
    RGGM_CONSTANTS.ELEMENT_SLOT_COOLDOWN_FRAME,
    trinketMenuSlotSize
  )

  mod.trinketMenu.SetupEvents(trinketMenuSlot)

  return trinketMenuSlot
end

--[[
  Slot prepare texture

  @param {table} slot
  @param {number} slotSize
]]--
function me.UpdateSlotTextureAttributes(slot, slotSize)
  local texture = slot.itemTexture
  texture:SetTexCoord(0.12, 0.88, 0.12, 0.88)
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
