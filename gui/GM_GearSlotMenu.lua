--[[
  MIT License

  Copyright (c) 2020 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

-- luacheck: globals CreateFrame UIDropDownMenu_Initialize UIDropDownMenu_AddButton UIDropDownMenu_GetSelectedID
-- luacheck: globals STANDARD_TEXT_FONT UIDropDownMenu_GetSelectedValue UIDropDownMenu_SetSelectedValue

local mod = rggm
local me = {}
mod.gearSlotMenu = me

me.tag = "GearSlotMenu"

-- track whether the menu was already built
local builtMenu = false

--[[
  Build the ui for the gearslot menu

  @param {table} frame
    The addon configuration frame to attach to
]]--
function me.BuildUi(frame)
  if builtMenu then return end

  for i = 1, RGGM_CONSTANTS.GEAR_BAR_SLOT_AMOUNT do
    local gearSlotDropdownMenu = me.CreateGearSlotDropdown(frame, i)
    me.CreateGearSlotLabel(frame, gearSlotDropdownMenu, i)
  end

  builtMenu = true
end

--[[
  @param {table} frame
  @param {number} position

  @return {table}
    The created dropdown menu
]]--
function me.CreateGearSlotDropdown(frame, position)
  local gearSlotDropdownMenu = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_SLOT_OPT_SLOT .. position,
    frame,
    "UIDropDownMenuTemplate"
  )
  gearSlotDropdownMenu.position = position

  if math.fmod(position, 2) == 0 then
    gearSlotDropdownMenu:SetPoint("TOPLEFT", 200, -(position -1) * 31)
  else
    gearSlotDropdownMenu:SetPoint("TOPLEFT", 20, -position * 31)
  end

  UIDropDownMenu_Initialize(gearSlotDropdownMenu, me.InitializeDropdownMenu)

  return gearSlotDropdownMenu
end

--[[
  @param {table} frame
  @param {table} gearSlotDropdownMenu
  @param {number} position
]]--
function me.CreateGearSlotLabel(frame, gearSlotDropdownMenu, position)
  local gearSlotLabel = frame:CreateFontString(RGGM_CONSTANTS.ELEMENT_GEAR_SLOT_OPT_SLOT_LABEL .. position, "OVERLAY")
  gearSlotLabel:SetFont(STANDARD_TEXT_FONT, 15)
  gearSlotLabel:SetPoint("TOP", gearSlotDropdownMenu, 25, 20)
  gearSlotLabel:SetText(rggm.L["titleslot_" .. position])
end

--[[
  Initialize dropdownmenus for slotpositions

  @param {table} self
]]--
function me.InitializeDropdownMenu(self)
  local slot = mod.configuration.GetSlotForPosition(self.position)
  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)
  local gearSlots = mod.gearManager.GetGearSlots()

  for _, gearSlot in pairs(gearSlots) do
    local button = mod.uiHelper.CreateDropdownButton(
      rggm.L[gearSlot.name],
      gearSlot.slotId,
      me.DropDownMenuCallback
    )
    UIDropDownMenu_AddButton(button)
  end

  -- create an option to disable the slot completely
  local emptyButton = mod.uiHelper.CreateDropdownButton("None", RGGM_CONSTANTS.INVSLOT_NONE, me.DropDownMenuCallback)
  UIDropDownMenu_AddButton(emptyButton)

  if (UIDropDownMenu_GetSelectedValue(_G[RGGM_CONSTANTS.ELEMENT_GEAR_SLOT_OPT_SLOT .. self.position]) == nil) then
    if gearSlotMetaData then
      UIDropDownMenu_SetSelectedValue(_G[RGGM_CONSTANTS.ELEMENT_GEAR_SLOT_OPT_SLOT .. self.position], slot)
    else
      UIDropDownMenu_SetSelectedValue(
        _G[RGGM_CONSTANTS.ELEMENT_GEAR_SLOT_OPT_SLOT .. self.position],
        RGGM_CONSTANTS.INVSLOT_NONE
      )
    end
  end
end

--[[
  Callback for optionsmenu dropdowns
]]
function me.DropDownMenuCallback(self)
  local position = self:GetParent().dropdown.position -- get slot position

  mod.configuration.SetSlotForPosition(position, self.value)
  mod.gearBar.UpdateGearBar()
  UIDropDownMenu_SetSelectedValue(_G[RGGM_CONSTANTS.ELEMENT_GEAR_SLOT_OPT_SLOT .. position], self.value)
end
