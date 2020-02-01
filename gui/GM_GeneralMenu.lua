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
-- luacheck: globals UIDropDownMenu_SetSelectedValue STANDARD_TEXT_FONT

local mod = rggm
local me = {}
mod.generalMenu = me

me.tag = "GeneralMenu"

--[[
  Option texts for checkbutton options
]]--
local options = {
  {"WindowLockGearBar", rggm.L["window_lock_gear_bar"], rggm.L["window_lock_gear_bar_tooltip"]},
  {"ShowKeyBindings", rggm.L["show_keybindings"], rggm.L["show_keybindings_tooltip"]},
  {"ShowCooldowns", rggm.L["show_cooldowns"], rggm.L["show_cooldowns_tooltip"]},
  {"EnableTooltips", rggm.L["enable_tooltips"], rggm.L["enable_tooltips_tooltip"]},
  {"EnableSimpleTooltips", rggm.L["enable_simple_tooltips"], rggm.L["enable_simple_tooltips_tooltip"]},
  {"EnableDragAndDrop", rggm.L["enable_drag_and_drop"], rggm.L["enable_drag_and_drop_tooltip"]},
  {"EnableFastpress", rggm.L["enable_fastpress"], rggm.L["enable_fastpress_tooltip"]}
}

-- track whether the menu was already built
local builtMenu = false

--[[
  Build the ui for the general menu

  @param {table} frame
    The addon configuration frame to attach to
]]--
function me.BuildUi(frame)
  if builtMenu then return end

  local titleFontString = frame:CreateFontString(RGGM_CONSTANTS.ELEMENT_GENERAL_TITLE, "OVERLAY")
  titleFontString:SetFont(STANDARD_TEXT_FONT, 20)
  titleFontString:SetPoint("TOP", 0, -20)
  titleFontString:SetSize(frame:GetWidth(), 20)
  titleFontString:SetText(rggm.L["general_title"])

  me.BuildCheckButtonOption(
    frame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_WINDOW_LOCK_GEAR_BAR,
    20,
    -80,
    me.LockWindowGearBarOnShow,
    me.LockWindowGearBarOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_SHOW_KEY_BINDINGS,
    20,
    -110,
    me.ShowKeyBindingsOnShow,
    me.ShowKeyBindingsOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_SHOW_COOLDOWNS,
    20,
    -140,
    me.ShowCooldownsOnShow,
    me.ShowCooldownsOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_TOOLTIPS,
    20,
    -170,
    me.EnableTooltipsOnShow,
    me.EnableTooltipsOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_SIMPLE_TOOLTIPS,
    20,
    -200,
    me.EnableSimpleTooltipsOnShow,
    me.EnableSimpleTooltipsOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_DRAG_AND_DROP,
    20,
    -230,
    me.EnableDragAndDropOnShow,
    me.EnableDragAndDropOnClick
  )

  me.BuildCheckButtonOption(
    frame,
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_ENABLE_FASTPRESS,
    20,
    -260,
    me.EnableFastPressOnShow,
    me.EnableFastPressOnClick
  )

  me.CreateItemQualityLabel(frame)
  me.CreateItemQualityDropdown(frame)
  me.CreateSizeSlider(frame)

  builtMenu = true
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
    RGGM_CONSTANTS.GENERAL_CHECK_OPTION_SIZE,
    RGGM_CONSTANTS.GENERAL_CHECK_OPTION_SIZE
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
  filterItemQualityLabel:SetPoint("TOPLEFT", 20, -300)
  filterItemQualityLabel:SetFont(STANDARD_TEXT_FONT, 12)
  filterItemQualityLabel:SetTextColor(1, 1, 1)
  filterItemQualityLabel:SetText(rggm.L["filter_item_quality"])
end

--[[
  @param {table} frame
]]--
function me.CreateItemQualityDropdown(frame)
  local itemQualityDropdownMenu = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_FILTER_ITEM_QUALITY,
    frame,
    "UIDropDownMenuTemplate"
  )
  itemQualityDropdownMenu:SetPoint("TOPLEFT", 20, -320)

  UIDropDownMenu_Initialize(itemQualityDropdownMenu, me.InitializeDropdownMenu)
end

--[[
  Create a slider for changing the size of the gearSlots

  @param {table} frame
]]--
function me.CreateSizeSlider(frame)
  local sizeSlider = CreateFrame(
    "Slider",
    RGGM_CONSTANTS.ELEMENT_GENERAL_SIZE_SLIDER,
    frame,
    "OptionsSliderTemplate"
  )
  sizeSlider:SetWidth(RGGM_CONSTANTS.GENERAL_SIZE_SLIDER_WIDTH)
  sizeSlider:SetHeight(RGGM_CONSTANTS.GENERAL_SIZE_SLIDER_HEIGHT)
  sizeSlider:SetOrientation('HORIZONTAL')
  sizeSlider:SetPoint("TOPLEFT", 20, -380)
  sizeSlider:SetMinMaxValues(RGGM_CONSTANTS.GENERAL_SIZE_SLIDER_MIN, RGGM_CONSTANTS.GENERAL_SIZE_SLIDER_MAX)
  sizeSlider:SetValueStep(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_STEP)
  sizeSlider:SetObeyStepOnDrag(true)
  sizeSlider:SetValue(mod.configuration.GetSlotSize())

  -- Update slider texts
  _G[sizeSlider:GetName() .. "Low"]:SetText(RGGM_CONSTANTS.GENERAL_SIZE_SLIDER_MIN)
  _G[sizeSlider:GetName() .. "High"]:SetText(RGGM_CONSTANTS.GENERAL_SIZE_SLIDER_MAX)
  _G[sizeSlider:GetName() .. "Text"]:SetText(rggm.L["size_slider_title"])
  sizeSlider.tooltipText = rggm.L["size_slider_tooltip"]

  local valueFontString = sizeSlider:CreateFontString(nil, "OVERLAY")
  valueFontString:SetFont(STANDARD_TEXT_FONT, 12)
  valueFontString:SetPoint("BOTTOM", 0, -15)
  valueFontString:SetText(sizeSlider:GetValue())

  sizeSlider.valueFontString = valueFontString
  sizeSlider:SetScript("OnValueChanged", me.SizeSliderOnValueChange)
end

--[[
  OnValueChanged callback for size slider

  @param {table} self
  @param {number} value
]]--
function me.SizeSliderOnValueChange(self, value)
  mod.configuration.SetSlotSize(value)

  --[[
    Update the gearBar and all of its slots. This includes the combatQueue and cooldown frames.
  ]]--
  mod.gearBar.UpdateGearBar()

  --[[
    Updating only the size of the changemenuslots and not the changeMenu that contains
    those slots. The menu itself will automatically update once the player hovers over an
    gearslot and those values need to be recalculated.
  ]]--
  mod.changeMenu.UpdateChangeMenuSlotSize()

  self.valueFontString:SetText(value)
end

--[[
  OnShow callback for checkbuttons - window lock gearBar

  @param {table} self
]]--
function me.LockWindowGearBarOnShow(self)
  if mod.configuration.IsGearBarLocked() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - window lock gearBar

  @param {table} self
]]--
function me.LockWindowGearBarOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.LockGearBar()
  else
    mod.configuration.UnlockGearBar()
  end
end

--[[
  OnShow callback for checkbuttons - show keyBindings

  @param {table} self
]]--
function me.ShowKeyBindingsOnShow(self)
  if mod.configuration.IsShowKeyBindingsEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - show keyBindings

  @param {table} self
]]--
function me.ShowKeyBindingsOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.EnableShowKeyBindings()
  else
    mod.configuration.DisableShowKeyBindings()
  end
end

--[[
  OnShow callback for checkbuttons - show cooldowns

  @param {table} self
]]--
function me.ShowCooldownsOnShow(self)
  if mod.configuration.IsShowCooldownsEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - show cooldowns

  @param {table} self
]]--
function me.ShowCooldownsOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.EnableShowCooldowns()
  else
    mod.configuration.DisableShowCooldowns()
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
  if mod.configuration.IsFastpressEnabled() then
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
    mod.configuration.EnableFastpress()
  else
    mod.configuration.DisableFastpress()
  end
end

--[[
  Initialize dropdownmenus for item quality filter
]]--
function me.InitializeDropdownMenu()
  local button, itemQualityFilter

  itemQualityFilter = mod.configuration.GetFilterItemQuality()

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_poor"],
    RGGM_CONSTANTS.ITEMQUALITY.poor, me.DropDownMenuCallback)
  UIDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_common"],
    RGGM_CONSTANTS.ITEMQUALITY.common, me.DropDownMenuCallback)
  UIDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_uncommon"],
    RGGM_CONSTANTS.ITEMQUALITY.uncommon, me.DropDownMenuCallback)
  UIDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_rare"],
    RGGM_CONSTANTS.ITEMQUALITY.rare, me.DropDownMenuCallback)
  UIDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_epic"],
    RGGM_CONSTANTS.ITEMQUALITY.epic, me.DropDownMenuCallback)
  UIDropDownMenu_AddButton(button)

  button = mod.uiHelper.CreateDropdownButton(rggm.L["item_quality_legendary"],
    RGGM_CONSTANTS.ITEMQUALITY.legendary, me.DropDownMenuCallback)
  UIDropDownMenu_AddButton(button)

  if (UIDropDownMenu_GetSelectedID(_G[RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_FILTER_ITEM_QUALITY]) == nil) then
    UIDropDownMenu_SetSelectedValue(_G[RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_FILTER_ITEM_QUALITY], itemQualityFilter)
  end
end

--[[
  Callback for optionsmenu dropdowns

  @param {table} self
]]
function me.DropDownMenuCallback(self)
  -- update addon setting
  mod.configuration.SetFilterItemQuality(tonumber(self.value))
  -- UIDROPDOWNMENU_OPEN_MENU is the currently open dropdown menu
  UIDropDownMenu_SetSelectedValue(_G[RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_FILTER_ITEM_QUALITY], self.value)
end
