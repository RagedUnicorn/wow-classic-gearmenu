--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT ReloadUI StaticPopupDialogs StaticPopup_Show

local mod = rggm
local me = {}
mod.generalMenu = me

me.tag = "GeneralMenu"

--[[
  Option texts for checkbutton options
]]--
local enableTooltipsMetaData = {
  "EnableTooltips",
  rggm.L["enable_tooltips"],
  rggm.L["enable_tooltips_tooltip"]
}

local enableSimpleTooltipsMetaData = {
  "EnableSimpleTooltips",
  rggm.L["enable_simple_tooltips"],
  rggm.L["enable_simple_tooltips_tooltip"]
}

local enableDragAndDropMetaData = {
  "EnableDragAndDrop",
  rggm.L["enable_drag_and_drop"],
  rggm.L["enable_drag_and_drop_tooltip"]
}

local enableFastPressMetaData = {
  "EnableFastPress",
  rggm.L["enable_fast_press"],
  rggm.L["enable_fast_press_tooltip"]
}

local enableUnequipSlotMetaData = {
  "EnableUnequipSlot",
  rggm.L["enable_unequip_slot"],
  rggm.L["enable_unequip_slot_tooltip"]
}

-- track whether the menu was already built
local builtMenu = false

--[[
  Popup dialog for reloading interface
]]--

StaticPopupDialogs["RGGM_RELOAD_INTERFACE"] = {
  text = rggm.L["theme_change_confirmation"],
  button1 = rggm.L["theme_change_confirmation_yes"],
  button2 = rggm.L["theme_change_confirmation_no"],
  OnAccept = function(_, data, data2)
    mod.configuration.SetUiTheme(tonumber(data))
    mod.libUiDropDownMenu.UiDropDownMenu_SetSelectedValue(data2, data)
    ReloadUI()
  end,
  timeout = 0,
  whileDead = true,
  preferredIndex = 3
}

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

  mod.uiHelper.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_TOOLTIPS,
    {"TOPLEFT", 20, -80},
    me.EnableTooltipsOnShow,
    me.EnableTooltipsOnClick,
    enableTooltipsMetaData
  )

  mod.uiHelper.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_SIMPLE_TOOLTIPS,
    {"TOPLEFT", 20, -110},
    me.EnableSimpleTooltipsOnShow,
    me.EnableSimpleTooltipsOnClick,
    enableSimpleTooltipsMetaData
  )

  mod.uiHelper.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_DRAG_AND_DROP,
    {"TOPLEFT", 20, -140},
    me.EnableDragAndDropOnShow,
    me.EnableDragAndDropOnClick,
    enableDragAndDropMetaData
  )

  mod.uiHelper.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_FASTPRESS,
    {"TOPLEFT", 20, -170},
    me.EnableFastPressOnShow,
    me.EnableFastPressOnClick,
    enableFastPressMetaData
  )

  --[[
    From here on move options to "second row"
  ]]--
  mod.uiHelper.BuildCheckButtonOption(
    generalMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_UNEQUIP_SLOT,
    {"TOPLEFT", 280, -80},
    me.EnableUnequipSlotOnShow,
    me.EnableUnequipSlotOnClick,
    enableUnequipSlotMetaData
  )

  me.CreateItemQualityLabel(generalMenuContentFrame)
  me.CreateItemQualityDropdown(generalMenuContentFrame)
  me.CreateThemeLabel(generalMenuContentFrame)
  me.CreateChooseThemeDropdown(generalMenuContentFrame)

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
function me.CreateItemQualityDropdown(frame)
  local itemQualityDropdownMenu = mod.libUiDropDownMenu.CreateUiDropDownMenu(
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_FILTER_ITEM_QUALITY,
    frame
  )
  itemQualityDropdownMenu:SetPoint("TOPLEFT", 0, -240)

  mod.libUiDropDownMenu.UiDropDownMenu_SetWidth(itemQualityDropdownMenu, 150)
  mod.libUiDropDownMenu.UiDropDownMenu_Initialize(itemQualityDropdownMenu, me.InitializeItemQualityDropdownMenu)
end

--[[
  Initialize dropdown menu for item quality filter

  @param {table} self
]]--
function me.InitializeItemQualityDropdownMenu(self)
  local button
  local itemQualityFilter = mod.configuration.GetFilterItemQuality()

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_poor"],
    RGGM_CONSTANTS.ITEMQUALITY.poor, me.ItemQualityDropdownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_common"],
    RGGM_CONSTANTS.ITEMQUALITY.common, me.ItemQualityDropdownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_uncommon"],
    RGGM_CONSTANTS.ITEMQUALITY.uncommon, me.ItemQualityDropdownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_rare"],
    RGGM_CONSTANTS.ITEMQUALITY.rare, me.ItemQualityDropdownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_epic"],
    RGGM_CONSTANTS.ITEMQUALITY.epic, me.ItemQualityDropdownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_legendary"],
    RGGM_CONSTANTS.ITEMQUALITY.legendary, me.ItemQualityDropdownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  if mod.libUiDropDownMenu.UiDropDownMenu_GetSelectedValue(self) == nil then
    mod.libUiDropDownMenu.UiDropDownMenu_SetSelectedValue(self, itemQualityFilter)
  end
end

--[[
  Callback for item quality dropdown

  @param {table} self
]]
function me.ItemQualityDropdownMenuCallback(self)
  -- update addon setting
  mod.configuration.SetFilterItemQuality(tonumber(self.value))
  mod.libUiDropDownMenu.UiDropDownMenu_SetSelectedValue(self:GetParent().dropdown, self.value)
end

--[[
  @param {table} frame
]]--
function me.CreateThemeLabel(frame)
  local chooseThemeLabel = frame:CreateFontString(
    RGGM_CONSTANTS.ELEMENT_GENERAL_LABEL_CHOOSE_THEME,
    "OVERLAY"
  )
  chooseThemeLabel:SetPoint("TOPLEFT", 250, -220)
  chooseThemeLabel:SetFont(STANDARD_TEXT_FONT, 12)
  chooseThemeLabel:SetTextColor(1, 1, 1)
  chooseThemeLabel:SetText(rggm.L["choose_theme"])
end

--[[
  @param {table} frame
]]--
function me.CreateChooseThemeDropdown(frame)
  local chooseThemeDropdownMenu = mod.libUiDropDownMenu.CreateUiDropDownMenu(
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_CHOOSE_THEME,
    frame
  )
  chooseThemeDropdownMenu:SetPoint("TOPLEFT", 230, -240)

  mod.libUiDropDownMenu.UiDropDownMenu_SetWidth(chooseThemeDropdownMenu, 150)
  mod.libUiDropDownMenu.UiDropDownMenu_Initialize(chooseThemeDropdownMenu, me.InitializeChooseThemeDropdownMenu)
end

--[[
  Initialize dropdown menu for choose theme

  @param {table} self
]]--
function me.InitializeChooseThemeDropdownMenu(self)
  local button
  local configuredTheme = mod.configuration.GetUiTheme()

  button = mod.uiHelper.CreateDropdownButton(rggm.L["theme_custom"],
    RGGM_CONSTANTS.UI_THEME_CUSTOM, me.ChooseThemeDropdownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["theme_classic"],
    RGGM_CONSTANTS.UI_THEME_CLASSIC, me.ChooseThemeDropdownMenuCallback)
  mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)

  if mod.libUiDropDownMenu.UiDropDownMenu_GetSelectedValue(self) == nil then
    mod.libUiDropDownMenu.UiDropDownMenu_SetSelectedValue(self, configuredTheme)
  end
end

--[[
  Callback for choose theme dropdown

  @param {table} self
]]
function me.ChooseThemeDropdownMenuCallback(self)
  if self.value == mod.configuration.GetUiTheme() then return end

  -- force reload ui
  local dialog = StaticPopup_Show("RGGM_RELOAD_INTERFACE")
  if dialog then
    dialog.data = self.value
    dialog.data2 = self:GetParent().dropdown
  end
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
