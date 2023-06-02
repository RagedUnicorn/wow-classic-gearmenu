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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT

local mod = rggm
local me = {}

mod.uiHelper = me

me.tag = "UiHelper"

--[[
  Create a dropdown button for a dropdown menu

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

--[[
  Build a checkbutton option

  @param {table} parentFrame
  @param {string} optionFrameName
  @param {table} position
  @param {function} onShowCallback
  @param {function} onClickCallback
  @param {table} checkBoxMetadata
    A table of {elementName, checkBoxTextLabel, tooltipText}
]]--
function me.BuildCheckButtonOption(
    parentFrame, optionFrameName, position, onShowCallback, onClickCallback, checkBoxMetadata)

  local checkButtonOptionFrame = CreateFrame("CheckButton", optionFrameName, parentFrame, "UICheckButtonTemplate")
  checkButtonOptionFrame:SetSize(
    RGGM_CONSTANTS.CHECK_OPTION_SIZE,
    RGGM_CONSTANTS.CHECK_OPTION_SIZE
  )
  checkButtonOptionFrame:SetPoint(unpack(position))

  for _, region in ipairs({checkButtonOptionFrame:GetRegions()}) do
    if string.find(region:GetName() or "", "Text$") and region:IsObjectType("FontString") then
      region:SetFont(STANDARD_TEXT_FONT, 15)
      region:SetTextColor(.95, .95, .95)
      region:SetText(checkBoxMetadata[2])
      break
    end
  end

  checkButtonOptionFrame:SetScript("OnEnter", function(self)
    me.OptTooltipOnEnter(self, checkBoxMetadata)
  end)
  checkButtonOptionFrame:SetScript("OnLeave", function(self)
    me.OptTooltipOnLeave(self)
  end)
  checkButtonOptionFrame:SetScript("OnShow", onShowCallback)
  checkButtonOptionFrame:SetScript("OnClick", onClickCallback)
  -- load initial state
  onShowCallback(checkButtonOptionFrame)
end

--[[
  OnEnter callback for checkbuttons - show tooltip

  @param {table} self
]]--
function me.OptTooltipOnEnter(self, checkBoxMetadata)
  local name = self:GetName()

  if not name then return end

  mod.tooltip.BuildTooltipForOption(checkBoxMetadata[2], checkBoxMetadata[3])
end

--[[
  OnEnter callback for checkbuttons - hide tooltip
]]--
function me.OptTooltipOnLeave()
  _G[RGGM_CONSTANTS.ELEMENT_TOOLTIP]:Hide()
end

--[[
  Create a slider for changing the size of the gearSlots

  @param {table} parentFrame
  @param {string} sliderName
  @param {table} position
    An object that can be unpacked into SetPoint
  @param {number} sliderMinValue
  @param {number} sliderMaxValue
  @param {number} defaultValue
  @param {string} sliderTitle
  @param {string} sliderTooltip
  @param {function} onShowCallback
  @param {function} OnValueChangedCallback
]]--
function me.CreateSizeSlider(parentFrame, sliderName, position, sliderMinValue, sliderMaxValue, defaultValue,
    sliderTitle, sliderTooltip, onShowCallback, OnValueChangedCallback)

  local sliderFrame = CreateFrame(
    "Slider",
    sliderName,
    parentFrame,
    "OptionsSliderTemplate"
  )
  sliderFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_WIDTH)
  sliderFrame:SetHeight(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_HEIGHT)
  sliderFrame:SetOrientation('HORIZONTAL')
  sliderFrame:SetPoint(unpack(position))
  sliderFrame:SetMinMaxValues(
    sliderMinValue,
    sliderMaxValue
  )
  sliderFrame:SetValueStep(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_STEP)
  sliderFrame:SetObeyStepOnDrag(true)
  sliderFrame:SetValue(defaultValue)

  -- Update slider texts
  _G[sliderFrame:GetName() .. "Low"]:SetText(sliderMinValue)
  _G[sliderFrame:GetName() .. "High"]:SetText(sliderMaxValue)
  _G[sliderFrame:GetName() .. "Text"]:SetText(sliderTitle)
  sliderFrame.tooltipText = sliderTooltip

  local valueFontString = sliderFrame:CreateFontString(nil, "OVERLAY")
  valueFontString:SetFont(STANDARD_TEXT_FONT, 12)
  valueFontString:SetPoint("BOTTOM", 0, -15)
  valueFontString:SetText(sliderFrame:GetValue())

  sliderFrame.valueFontString = valueFontString
  sliderFrame:SetScript("OnValueChanged", OnValueChangedCallback)
  sliderFrame:SetScript("OnShow", onShowCallback)

  -- load initial state
  onShowCallback(sliderFrame)
end

--[[
  Create a texture for the icon of whatever item is currently in the slot

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
