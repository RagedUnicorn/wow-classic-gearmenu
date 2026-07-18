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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT Settings MinimalSliderWithSteppersMixin ScrollUtil

local mod = rggm
local me = {}

mod.uiHelper = me

me.tag = "UiHelper"

local CreateSliderOptions

--[[
  Apply one of the RGGM_CONSTANTS.COLOR { r, g, b } tokens to a font string.

  @param {table} fontString
  @param {table} color
]]--
function me.SetColor(fontString, color)
  fontString:SetTextColor(color[1], color[2], color[3])
end

--[[
  Apply the shared bordered box backdrop used by panel content containers. The frame
  must have been created with the "BackdropTemplate" mixin.

  @param {table} frame
]]--
function me.ApplyBorderBackdrop(frame)
  frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  frame:SetBackdropColor(0, 0, 0, 0.4)
  frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
end

--[[
  Create a bordered, scrollable list container in the style of the stock configuration
  menus. Rows attach to the returned container's content frame - a scroll child driven
  by a MinimalScrollBar. The consumer is responsible for updating the content frame's
  height to the amount of rows it holds (scroll range = content height - visible height).

  @param {string} listName
    Name for the container frame; may use $parent which resolves against the passed parent.
    The content frame is named after the resolved container name suffixed with "Content"
  @param {table} parent
  @param {table} position
    An object containing configuration parameters for a SetPoint function call
  @param {number} listWidth
  @param {number} listHeight

  @return {table}
    The created container with .scrollFrame and .content attached
]]--
function me.CreateScrollList(listName, parent, position, listWidth, listHeight)
  local listContainer = CreateFrame("Frame", listName, parent, "BackdropTemplate")
  listContainer:SetSize(listWidth, listHeight)
  listContainer:SetPoint(unpack(position))
  me.ApplyBorderBackdrop(listContainer)

  local scrollFrame = CreateFrame("ScrollFrame", nil, listContainer)
  scrollFrame:SetPoint("TOPLEFT", 6, -6)
  scrollFrame:SetPoint("BOTTOMRIGHT", -22, 6)

  local scrollBar = CreateFrame("EventFrame", nil, listContainer, "MinimalScrollBar")
  scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 8, 0)
  scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 8, 0)
  ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar)

  local contentFrame = CreateFrame("Frame", listContainer:GetName() .. "Content", scrollFrame)
  contentFrame:SetSize(listWidth - 28, listHeight)
  scrollFrame:SetScrollChild(contentFrame)

  listContainer.scrollFrame = scrollFrame
  listContainer.content = contentFrame

  return listContainer
end

--[[
  Create a dropdown in the dark style of the stock configuration menus (WowStyle2, without
  the stepper buttons the settings panel adds around some of its dropdowns)

  @param {string} frameName
  @param {table} parent
  @param {table} position
    An object containing configuration parameters for a SetPoint function call
  @param {number} width
  @param {function} menuGenerator
    Menu generator passed to SetupMenu - receives (dropdown, rootDescription)

  @return {table}
    The created dropdown
]]--
function me.CreateSettingsDropdown(frameName, parent, position, width, menuGenerator)
  local dropdown = CreateFrame("DropdownButton", frameName, parent, "WowStyle2DropdownTemplate")
  dropdown:SetPoint(unpack(position))
  dropdown:SetWidth(width)
  dropdown:SetupMenu(menuGenerator)

  return dropdown
end

--[[
  Build a checkbutton option

  @param {table} parentFrame
  @param {string} optionFrameName
  @param {table} position
  @param {function} onShowCallback
  @param {function} onClickCallback
  @param {table} checkBoxMetadata
    A table of {elementName, checkBoxTextLabel, description}
]]--
function me.BuildCheckButtonOption(
    parentFrame, optionFrameName, position, onShowCallback, onClickCallback, checkBoxMetadata)

  local checkButtonOptionFrame = CreateFrame("CheckButton", optionFrameName, parentFrame, "SettingsCheckboxTemplate")
  checkButtonOptionFrame:SetSize(
    RGGM_CONSTANTS.CHECK_OPTION_SIZE,
    RGGM_CONSTANTS.CHECK_OPTION_SIZE
  )
  checkButtonOptionFrame:SetPoint(unpack(position))

  --[[ the template's inherited hover scripts drive the settings-list row highlight and
       misbehave outside that list - remove them ]]--
  checkButtonOptionFrame:SetScript("OnEnter", nil)
  checkButtonOptionFrame:SetScript("OnLeave", nil)

  --[[ the template ships no label - the settings list rows normally provide it ]]--
  local labelFontString = checkButtonOptionFrame:CreateFontString(nil, "OVERLAY")
  labelFontString:SetFont(STANDARD_TEXT_FONT, 15)
  me.SetColor(labelFontString, RGGM_CONSTANTS.COLOR.BODY)
  labelFontString:SetPoint("LEFT", checkButtonOptionFrame, "RIGHT", 5, 0)
  labelFontString:SetText(checkBoxMetadata[2])
  checkButtonOptionFrame.text = labelFontString

  local descriptionFontString = checkButtonOptionFrame:CreateFontString(nil, "OVERLAY")
  descriptionFontString:SetFont(STANDARD_TEXT_FONT, 12)
  me.SetColor(descriptionFontString, RGGM_CONSTANTS.COLOR.SUBNOTE)
  descriptionFontString:SetPoint("TOPLEFT", checkButtonOptionFrame, "BOTTOMLEFT", 4, -2)
  descriptionFontString:SetWidth(RGGM_CONSTANTS.CHECK_OPTION_DESCRIPTION_WIDTH)
  descriptionFontString:SetJustifyH("LEFT")
  descriptionFontString:SetText(checkBoxMetadata[3])
  checkButtonOptionFrame.description = descriptionFontString

  checkButtonOptionFrame:SetScript("OnShow", onShowCallback)
  checkButtonOptionFrame:SetScript("OnClick", onClickCallback)
  -- load initial state
  onShowCallback(checkButtonOptionFrame)
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
  Create an always visible description below a slider

  @param {table} sliderFrame
  @param {string} description
]]--
function me.CreateSliderDescription(sliderFrame, description)
  local descriptionFontString = sliderFrame:CreateFontString(nil, "OVERLAY")
  descriptionFontString:SetFont(STANDARD_TEXT_FONT, 12)
  me.SetColor(descriptionFontString, RGGM_CONSTANTS.COLOR.SUBNOTE)
  -- the template renders its min/max value labels below the frame - clear them
  descriptionFontString:SetPoint("TOPLEFT", sliderFrame, "BOTTOMLEFT", 4, -16)
  descriptionFontString:SetWidth(sliderFrame:GetWidth())
  descriptionFontString:SetJustifyH("LEFT")
  descriptionFontString:SetText(description)
  sliderFrame.description = descriptionFontString
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
  @param {string} sliderDescription
  @param {function} onValueChangedCallback
]]--
function me.CreateSizeSlider(parentFrame, sliderName, position, sliderMinValue, sliderMaxValue, defaultValue,
    sliderTitle, sliderDescription, onValueChangedCallback)

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

  me.CreateSliderDescription(sliderFrame, sliderDescription)

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
