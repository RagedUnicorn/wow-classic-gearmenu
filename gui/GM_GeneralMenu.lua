--[[
  MIT License

  Copyright (c) 2021 Michael Wiesendanger

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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT

local mod = rggm
local me = {}
mod.generalMenu = me

me.tag = "GeneralMenu"

--[[
  Option texts for checkbutton options
]]--
local options = {
  {"EnableTooltips", rggm.L["enable_tooltips"], rggm.L["enable_tooltips_tooltip"]},
  {"EnableSimpleTooltips", rggm.L["enable_simple_tooltips"], rggm.L["enable_simple_tooltips_tooltip"]},
  {"EnableDragAndDrop", rggm.L["enable_drag_and_drop"], rggm.L["enable_drag_and_drop_tooltip"]},
  {"EnableFastPress", rggm.L["enable_fast_press"], rggm.L["enable_fast_press_tooltip"]},
  {"EnableUnequipSlot", rggm.L["enable_unequip_slot"], rggm.L["enable_unequip_slot_tooltip"]}
}

-- track whether the menu was already built
local builtMenu = false

--[[
  Build the ui for the general menu

  @param {table} parentFrame
    The addon configuration frame to attach to
]]--
function me.BuildUi(parentFrame)
  if builtMenu then return end

  local generalMenuContentFrame = CreateFrame(
    "Frame", RGGM_CONSTANTS.ELEMENT_GENERAL_MENU, parentFrame)
  generalMenuContentFrame:SetWidth(RGGM_CONSTANTS.INTERFACE_PANEL_CONTENT_FRAME_WIDTH)
  generalMenuContentFrame:SetHeight(RGGM_CONSTANTS.INTERFACE_PANEL_CONTENT_FRAME_HEIGHT)
  generalMenuContentFrame:SetPoint("TOPLEFT", parentFrame, 5, -7)

  me.CreateGeneralMenuTitle(generalMenuContentFrame)

  me.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_TOOLTIPS,
    20,
    -80,
    me.EnableTooltipsOnShow,
    me.EnableTooltipsOnClick
  )

  me.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_SIMPLE_TOOLTIPS,
    20,
    -110,
    me.EnableSimpleTooltipsOnShow,
    me.EnableSimpleTooltipsOnClick
  )

  me.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_DRAG_AND_DROP,
    20,
    -140,
    me.EnableDragAndDropOnShow,
    me.EnableDragAndDropOnClick
  )

  me.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_FASTPRESS,
    20,
    -170,
    me.EnableFastPressOnShow,
    me.EnableFastPressOnClick
  )

  --[[
    From here on move options to "second row"
  ]]--
  me.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_UNEQUIP_SLOT,
    280,
    -80,
    me.EnableUnequipSlotOnShow,
    me.EnableUnequipSlotOnClick
  )

  me.CreateItemQualityLabel(generalMenuContentFrame)
  me.CreateItemQualityDropDown(generalMenuContentFrame)

  builtMenu = true
end

--[[
  @param {table} contentFrame
]]--
function me.CreateGeneralMenuTitle(contentFrame)
  local titleFontString = contentFrame:CreateFontString(RGGM_CONSTANTS.ELEMENT_GENERAL_MENU_TITLE, "OVERLAY")
  titleFontString:SetFont(STANDARD_TEXT_FONT, 20)
  titleFontString:SetPoint("TOP", 0, -20)
  titleFontString:SetSize(contentFrame:GetWidth(), 20)
  titleFontString:SetText(rggm.L["general_title"])
end

--[[
  Build a checkbutton option

  @param {table} parentFrame
  @param {string} optionFrameName
  @param {number} posX
  @param {number} posY
  @param {function} onShowCallback
  @param {function} onClickCallback
]]--
function me.BuildCheckButtonOption(parentFrame, optionFrameName, posX, posY, onShowCallback, onClickCallback)
  local checkButtonOptionFrame = CreateFrame("CheckButton", optionFrameName, parentFrame, "UICheckButtonTemplate")
  checkButtonOptionFrame:SetSize(
    RGGM_CONSTANTS.CHECK_OPTION_SIZE,
    RGGM_CONSTANTS.CHECK_OPTION_SIZE
  )
  checkButtonOptionFrame:SetPoint("TOPLEFT", posX, posY)

  for _, region in ipairs({checkButtonOptionFrame:GetRegions()}) do
    if string.find(region:GetName() or "", "Text$") and region:IsObjectType("FontString") then
      region:SetFont(STANDARD_TEXT_FONT, 15)
      region:SetTextColor(.95, .95, .95)
      region:SetText(me.GetLabelText(checkButtonOptionFrame))
      break
    end
  end

  checkButtonOptionFrame:SetScript("OnEnter", me.OptTooltipOnEnter)
  checkButtonOptionFrame:SetScript("OnLeave", me.OptTooltipOnLeave)
  checkButtonOptionFrame:SetScript("OnShow", onShowCallback)
  checkButtonOptionFrame:SetScript("OnClick", onClickCallback)
  -- load initial state
  onShowCallback(checkButtonOptionFrame)
end

--[[
  Get the label text for the checkbutton

  @param {table} frame

  @return {string}
    The text for the label
]]--
function me.GetLabelText(frame)
  local name = frame:GetName()

  if not name then return end

  for i = 1, table.getn(options) do
    if name == RGGM_CONSTANTS.ELEMENT_GENERAL_OPT .. options[i][1] then
      return options[i][2]
    end
  end
end

--[[
  OnEnter callback for checkbuttons - show tooltip

  @param {table} self
]]--
function me.OptTooltipOnEnter(self)
  local name = self:GetName()

  if not name then return end

  for i = 1, table.getn(options) do
    if name == RGGM_CONSTANTS.ELEMENT_GENERAL_OPT .. options[i][1] then
      mod.tooltip.BuildTooltipForOption(options[i][2], options[i][3])
      break
    end
  end
end

--[[
  OnEnter callback for checkbuttons - hide tooltip
]]--
function me.OptTooltipOnLeave()
  _G[RGGM_CONSTANTS.ELEMENT_TOOLTIP]:Hide()
end

--[[
  @param {table} frame
]]--
function me.CreateItemQualityLabel(frame)
  local filterItemQualityLabel = frame:CreateFontString(
    RGGM_CONSTANTS.ELEMENT_GENERAL_LABEL_FILTER_ITEM_QUALITY,
    "OVERLAY"
  )
  filterItemQualityLabel:SetPoint("TOPLEFT", 20, -220)
  filterItemQualityLabel:SetFont(STANDARD_TEXT_FONT, 12)
  filterItemQualityLabel:SetTextColor(1, 1, 1)
  filterItemQualityLabel:SetText(rggm.L["filter_item_quality"])
end

--[[
  @param {table} frame
]]--
function me.CreateItemQualityDropDown(frame)
  local itemQualityDropDownMenu = mod.libUiDropDownMenu.CreateUiDropDownMenu(
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_FILTER_ITEM_QUALITY,
    frame
  )
  itemQualityDropDownMenu:SetPoint("TOPLEFT", 0, -240)

  mod.libUiDropDownMenu.UiDropDownMenu_SetWidth(itemQualityDropDownMenu, 150)
  mod.libUiDropDownMenu.UiDropDownMenu_Initialize(itemQualityDropDownMenu, me.InitializeDropDownMenu)
end

--[[
  OnShow callback for checkbuttons - enable tooltips

  @param {table} self
]]--
function me.EnableTooltipsOnShow(self)
  if mod.configuration.IsTooltipsEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - enable tooltips

  @param {table} self
]]--
function me.EnableTooltipsOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.EnableTooltips()
  else
    mod.configuration.DisableTooltips()
  end
end

--[[
  OnShow callback for checkbuttons - enable simple tooltips

  @param {table} self
]]--
function me.EnableSimpleTooltipsOnShow(self)
  if mod.configuration.IsSimpleTooltipsEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - enable simple tooltips

  @param {table} self
]]--
function me.EnableSimpleTooltipsOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.EnableSimpleTooltips()
  else
    mod.configuration.DisableSimpleTooltips()
  end
end

--[[
  OnShow callback for checkbuttons - enable drag and drop

  @param {table} self
]]--
function me.EnableDragAndDropOnShow(self)
  if mod.configuration.IsDragAndDropEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - enable drag and drop

  @param {table} self
]]--
function me.EnableDragAndDropOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.EnableDragAndDrop()
  else
    mod.configuration.DisableDragAndDrop()
  end
end

--[[
  OnShow callback for checkbuttons - enable fastpress

  @param {table} self
]]--
function me.EnableFastPressOnShow(self)
  if mod.configuration.IsFastPressEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - enable fastpress

  @param {table} self
]]--
function me.EnableFastPressOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.EnableFastPress()
  else
    mod.configuration.DisableFastPress()
  end
end

--[[
  OnShow callback for checkbuttons - enable unequipSlot

  @param {table} self
]]--
function me.EnableUnequipSlotOnShow(self)
  if mod.configuration.IsUnequipSlotEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - enable unequipSlot

  @param {table} self
]]--
function me.EnableUnequipSlotOnClick(self)
  local enabled = self:GetChecked()
  -- force checkbox to keep checked state until the user decided in the dialog what to do
  if enabled then
    mod.configuration.EnableUnequipSlot()
  else
    mod.configuration.DisableUnequipSlot()
  end
end

--[[
  Initialize dropdownmenus for item quality filter

  @param {table} self
]]--
function me.InitializeDropDownMenu(self)
  local button, itemQualityFilter

  itemQualityFilter = mod.configuration.GetFilterItemQuality()

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_poor"],
    RGGM_CONSTANTS.ITEMQUALITY.poor, me.DropDownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_common"],
    RGGM_CONSTANTS.ITEMQUALITY.common, me.DropDownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_uncommon"],
    RGGM_CONSTANTS.ITEMQUALITY.uncommon, me.DropDownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_rare"],
    RGGM_CONSTANTS.ITEMQUALITY.rare, me.DropDownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_epic"],
    RGGM_CONSTANTS.ITEMQUALITY.epic, me.DropDownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_legendary"],
    RGGM_CONSTANTS.ITEMQUALITY.legendary, me.DropDownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  if mod.libUiDropDownMenu.UiDropDownMenu_GetSelectedValue(self) == nil then
    mod.libUiDropDownMenu.UiDropDownMenu_SetSelectedValue(self, itemQualityFilter)
  end
end

--[[
  Callback for optionsmenu dropdowns

  @param {table} self
]]
function me.DropDownMenuCallback(self)
  -- update addon setting
  mod.configuration.SetFilterItemQuality(tonumber(self.value))
  mod.libUiDropDownMenu.UiDropDownMenu_SetSelectedValue(self:GetParent().dropdown, self.value)
end
