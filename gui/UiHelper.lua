--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT Settings MinimalSliderWithSteppersMixin

local mod = rggm
local me = {}

mod.uiHelper = me

me.tag = "UiHelper"

local CreateSliderOptions
local SetupSliderTooltips

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
  Create slider options for MinimalSliderWithSteppersTemplate

  @param {number} minValue
  @param {number} maxValue
  @param {string} title

  @return {table} sliderOptions
]]--
CreateSliderOptions = function(minValue, maxValue, title)
  local sliderOptions = Settings.CreateSliderOptions(
    minValue,
    maxValue,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_STEP
  )
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value) return value end)
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Max, function() return maxValue end)
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Min, function() return minValue end)
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Top, function() return title end)

  return sliderOptions
end

--[[
  Setup tooltips for a MinimalSliderWithSteppersTemplate slider frame and its sub-elements

  @param {table} sliderFrame
  @param {string} title
  @param {string} tooltip
]]--
SetupSliderTooltips = function(sliderFrame, title, tooltip)
  local function ShowTooltip()
    mod.tooltip.BuildTooltipForOption(title, tooltip)
  end

  local function HideTooltip()
    _G[RGGM_CONSTANTS.ELEMENT_TOOLTIP]:Hide()
  end

  sliderFrame:SetScript("OnEnter", ShowTooltip)
  sliderFrame:SetScript("OnLeave", HideTooltip)

  if sliderFrame.Slider then
    sliderFrame.Slider:SetScript("OnEnter", ShowTooltip)
    sliderFrame.Slider:SetScript("OnLeave", HideTooltip)
  end

  if sliderFrame.Back then
    sliderFrame.Back:SetScript("OnEnter", ShowTooltip)
    sliderFrame.Back:SetScript("OnLeave", HideTooltip)
  end

  if sliderFrame.Forward then
    sliderFrame.Forward:SetScript("OnEnter", ShowTooltip)
    sliderFrame.Forward:SetScript("OnLeave", HideTooltip)
  end
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
  @param {function} onValueChangedCallback
]]--
function me.CreateSizeSlider(parentFrame, sliderName, position, sliderMinValue, sliderMaxValue, defaultValue,
    sliderTitle, sliderTooltip, onValueChangedCallback)

  local sliderOptions = CreateSliderOptions(sliderMinValue, sliderMaxValue, sliderTitle)

  local sliderFrame = CreateFrame(
    "Frame",
    sliderName,
    parentFrame,
    "MinimalSliderWithSteppersTemplate"
  )
  sliderFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_WIDTH)
  sliderFrame:SetPoint(unpack(position))
  sliderFrame:Init(
    defaultValue,
    sliderOptions.minValue,
    sliderOptions.maxValue,
    sliderOptions.steps,
    sliderOptions.formatters
  )

  if onValueChangedCallback then
    sliderFrame:RegisterCallback("OnValueChanged", onValueChangedCallback, sliderFrame)
  end

  SetupSliderTooltips(sliderFrame, sliderTitle, sliderTooltip)

  return sliderFrame
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

--[[
  Create a container wrapper for textures to be able to capture mouse events

  @param {string} frameName
  @param {table} parentFrame

  @return {table} containerFrame
]]--
function me.CreateMouseOverEventContainer(frameName, parentFrame, position)
  local containerFrame = CreateFrame(
    "Frame",
    frameName,
    parentFrame
  )
  containerFrame:SetPoint(unpack(position))
  containerFrame:SetSize(
    16,
    16
  )
  containerFrame:EnableMouse(true)

  return containerFrame
end

--[[
  Create a pool of lazily created, index-addressed frames. The pool only manages
  creation, lookup, iteration and hiding - anchoring and per-frame content stay
  with the consumer.

  @param {function} createFrame
    Invoked as createFrame(index) the first time an index is acquired; must return the frame

  @return {table} pool
]]--
function me.CreateFramePool(createFrame)
  local pool = {}
  local frames = {}

  --[[
    Get the frame at the passed index, creating it on first access

    @param {number} index
    @return {table}
  ]]--
  function pool.Acquire(index)
    if frames[index] == nil then
      frames[index] = createFrame(index)
    end

    return frames[index]
  end

  --[[
    @return {number} the amount of created frames
  ]]--
  function pool.GetSize()
    return #frames
  end

  --[[
    Iterate all created frames in index order

    @param {function} callback
      Invoked as callback(frame, index)
  ]]--
  function pool.ForEach(callback)
    for index = 1, #frames do
      callback(frames[index], index)
    end
  end

  --[[
    Hide all created frames from the passed index onwards

    @param {number} startIndex
    @param {function} resetFrame
      Optional; invoked as resetFrame(frame) after the frame was hidden
  ]]--
  function pool.ReleaseFrom(startIndex, resetFrame)
    for index = startIndex, #frames do
      frames[index]:Hide()

      if resetFrame then
        resetFrame(frames[index])
      end
    end
  end

  --[[
    Hide all created frames

    @param {function} resetFrame
      Optional; invoked as resetFrame(frame) after the frame was hidden
  ]]--
  function pool.ReleaseAll(resetFrame)
    pool.ReleaseFrom(1, resetFrame)
  end

  return pool
end

--[[
  Calculate the x/y offset of a 1-based index in a grid that is columnAmount wide
  and grows row by row

  @param {number} index
  @param {number} columnAmount
  @param {number} slotSize

  @return {number} xPos
  @return {number} yPos
]]--
function me.CalculateGridPosition(index, columnAmount, slotSize)
  local row = math.floor((index - 1) / columnAmount)
  local column = (index - 1) % columnAmount

  return column * slotSize, row * slotSize
end
