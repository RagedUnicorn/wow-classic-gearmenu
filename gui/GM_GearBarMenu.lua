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

-- luacheck: globals CreateFrame UIParent InCombatLockdown STANDARD_TEXT_FONT C_Timer

local mod = rggm
local me = {}

mod.gearBarMenu = me

me.tag = "GearBarMenu"

-- track whether the menu was already built
local builtMenu = false


--[[
  @param {table} frame
]]--
function me.BuildUi(frame)
  if builtMenu then return end

  me.CreateNewGearBarButton(frame)
  me.CreateGearBarList(frame)

  builtMenu = true
end

--[[
  Create a button to create new gearBars

  @param {table} gearBarFrame

  @return {table}
    The created button
]]--
function me.CreateNewGearBarButton(gearBarFrame)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_MENU_BUTTON_ADD_GEAR_BAR,
    gearBarFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_add_gearbar"])
  button:SetPoint("TOPLEFT", 10, 10)
  button:SetScript('OnClick', me.CreateNewGearBar)

  local buttonFontString = button:GetFontString()

  button:SetWidth(
    buttonFontString:GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Creating a new gearBar includes storing this info in the mod.configuration module
]]--
function me.CreateNewGearBar()
  local gearBar = mod.gearBarManager.GetNewGearBar()
  gearBar.displayName = "TODO some displayName"
  gearBar.position = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_POSITION
  -- make new gearBar known to the configuration module
  mod.gearBarManager.AddNewGearBar(gearBar)

  -- create an initial GearSlot (every GearBar needs to have at least one GearSlot)
  mod.gearBarManager.AddNewGearSlot(gearBar.id)

  mod.gearBar.BuildGearBar(gearBar)
end

--[[
  Create the list that contains the visual representation of all configurations for all the gearBars

  @param {table} frame
]]--
function me.CreateGearBarList(frame)
  local gearBarListScrollFrame = CreateFrame(
    "ScrollFrame",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_LIST_SCROLL_FRAME,
    frame
  )

  gearBarListScrollFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_LIST_CONTENT_FRAME_WIDTH)
  gearBarListScrollFrame:SetHeight(RGGM_CONSTANTS.GEAR_BAR_LIST_CONTENT_FRAME_HEIGHT)
  gearBarListScrollFrame:SetPoint("TOPLEFT", 10, -50)
  gearBarListScrollFrame:EnableMouseWheel(true)
  gearBarListScrollFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })

  gearBarListScrollFrame:SetScript("OnMouseWheel", me.ScrollFrameOnMouseWheel)

  gearBarListScrollFrame.scrollContentFrame = me.CreateGearBarContentFrame(gearBarListScrollFrame)
  gearBarListScrollFrame.frameSlider = me.CreateGearBarListFrameSlider(gearBarListScrollFrame)
end

--[[
  Scroll callback for scrollable content. Also updates the associated
  scrollFrameSlider to its new position

  @param {table} self
  @param {number} arg1
    1 for spinning up
    -1 for spinning down

]]--
function me.ScrollFrameOnMouseWheel(self, arg1)
  local maxScroll = self:GetVerticalScrollRange()
  local scroll = self:GetVerticalScroll()
  local toScroll = (scroll - (20 * arg1))
  local scrollFrameSlider

  for _, child in ipairs({self:GetChildren()}) do
    if child:GetObjectType() == "Slider" then
      scrollFrameSlider = child
    end
  end

  if toScroll < 0 then
    self:SetVerticalScroll(0)
    me.UpdateSliderPosition(scrollFrameSlider, 0, maxScroll)
  elseif toScroll > maxScroll then
    self:SetVerticalScroll(maxScroll)
    me.UpdateSliderPosition(scrollFrameSlider, maxScroll, maxScroll)
  else
    self:SetVerticalScroll(toScroll)
    me.UpdateSliderPosition(scrollFrameSlider, toScroll, maxScroll)
  end
end

--[[
  Update scrollframeslider position

  @param {table} scrollFrameSlider
    reference to the scrollframeslider that should get updated
  @param {number} scrollPosition
  @param {number} maxScroll
]]--
function me.UpdateSliderPosition(scrollFrameSlider, scrollPosition, maxScroll)
  local position

  mod.logger.LogDebug(me.tag, "Content scrollposition: " .. scrollPosition)

  if scrollFrameSlider == nil then
    mod.logger.LogError(me.tag, "Unable to find frameslider for current scrollframe")
    return
  end

  position = 100 / (maxScroll / math.floor(scrollPosition))
  mod.logger.LogDebug(me.tag, "New Slider scrollposition: " .. math.ceil(position))
  scrollFrameSlider:SetValue(math.ceil(position))
end

--[[
  Creates a contentFrame for the scrollFrame

  @param {table} scrollFrame

  @return {table}
    The created contentFrame
]]--
function me.CreateGearBarContentFrame(scrollFrame)
  local contentFrame = CreateFrame(
    "Frame",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_LIST_CONTENT_FRAME,
    scrollFrame
  )

  contentFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_LIST_CONTENT_FRAME_WIDTH)
  contentFrame:SetHeight(320) -- TODO hardcoded will be dynamic maybe remove it even?
  scrollFrame:SetScrollChild(contentFrame)

  return contentFrame
end

--[[
  Creates a draggable slider for the scrollFrame

  @param {table} scrollFrame

  @return {table}
    The created frameSlider
]]--
function me.CreateGearBarListFrameSlider(scrollFrame)
  local scrollFrameSlider = CreateFrame(
    "Slider",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_LIST_SCROLL_FRAME_SLIDER,
    scrollFrame,
    "UIPanelScrollBarTemplate"
  )

  scrollFrameSlider:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
  scrollFrameSlider:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
  scrollFrameSlider:SetMinMaxValues(
    RGGM_CONSTANTS.GEAR_BAR_LIST_SLIDER_MIN_VALUE,
    RGGM_CONSTANTS.GEAR_BAR_LIST_SLIDER_MAX_VALUE
  )
  scrollFrameSlider:SetValueStep(1)
  scrollFrameSlider:SetValue(0)
  scrollFrameSlider:SetWidth(16)
  -- sets the stepsize that is made when clicking on up or down arrow button
  scrollFrameSlider:SetHeight(10)
  scrollFrameSlider:SetScript("OnValueChanged", me.ScrollFrameSliderOnValueChanged)

  local scrollBackground = scrollFrameSlider:CreateTexture(nil, "BACKGROUND")
  scrollBackground:SetAllPoints(scrollFrameSlider)
  scrollBackground:SetTexture(0, 0, 0, 0.4)

  return scrollFrameSlider
end

--[[
  Callback for slider - called each time the value of the slider changes

  @param {table} self
]]--
function me.ScrollFrameSliderOnValueChanged(self)
  local maxScroll, stepSize
  local scrollFrame = self:GetParent()

  if scrollFrame == nil then
    mod.logger.LogError(me.tag, "Unable to find scrollFrame")
    return
  end
  -- getmaxscroll of scrollFrame
  maxScroll = scrollFrame:GetVerticalScrollRange()
  -- translate max/min 0 - 100 to maxScroll
  stepSize = maxScroll / RGGM_CONSTANTS.GEAR_BAR_LIST_SLIDER_MAX_VALUE
  -- set vertical scroll of the contenframe - (currentslider value * stepsize)
  scrollFrame:SetVerticalScroll(self:GetValue() * stepSize)
end
