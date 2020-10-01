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
  Saves currently created configuration frames for the gearBars
]]--
local gearBarConfigurationFrames = {}
--
local gearBarListContentFrame


--[[
  @param {table} frame
]]--
function me.BuildUi(frame)
  if builtMenu then return end

  me.CreateNewGearBarButton(frame)
  me.CreateGearBarList(frame)
  me.UpdateGearBarMenu()

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
  if not mod.gearBarManager.AddNewGearSlot(gearBar.id) then
    mod.logger.LogError(me.tag, "Failed to add new gearSlot to gearBar with id: " .. gearBar.id)
    return
  end

  mod.gearBar.BuildGearBar(gearBar)
  me.UpdateGearBarMenu() -- update the configuration menu
  mod.gearBar.UpdateGearBar(gearBar) -- update the visual representation of the gearBar
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
  gearBarListContentFrame = gearBarListScrollFrame.scrollContentFrame
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
   -- TODO hardcoded will be dynamic maybe remove it even?
  contentFrame:SetHeight(RGGM_CONSTANTS.GEAR_BAR_LIST_CONTENT_FRAME_HEIGHT)
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

--[[
  Update the gearBar configuration menu. Work through current gearBar configuration and update the ui accordingly
]]--
function me.UpdateGearBarMenu()
  local gearBars = mod.gearBarManager.GetGearBars()
  --[[
    parentFrame is only set if there was a configurationFrame built or found previously. It will then be
    subsequently used as anchorpoint for new configurations frames. They go at the end of the list.
  ]]--
  local parentFrame

  for index, gearBar in pairs(gearBars) do
    local gearBarConfigFrame = gearBarConfigurationFrames[index]

    if gearBarConfigFrame == nil then
      mod.logger.LogDebug(me.tag, "Creating new configFrame because it did not yet exist")

      parentFrame = me.CreateGearBarConfigFrame(parentFrame, gearBarListContentFrame, index, gearBar)
      table.insert(gearBarConfigurationFrames, parentFrame)
    else
      parentFrame = gearBarConfigFrame
      mod.logger.LogDebug(me.tag, "Configframe already exists reusing")
    end


    -- update slot configuration scrolllist
    me.GearSlotConfigurationScrollFrameOnUpdate(parentFrame.scrollFrame)
    --
    me.UpdateGearBarConfigurationFrame(gearBar, parentFrame)
    parentFrame:Show()
  end

  --[[
    When a gearBar is deleted and it is not the only gearBar or the one at the last spot of the list
    all other elements have to adapt and effectively move up in the list. This has the effect that afterwards
    an orphan exists in the list and needs to be cleaned up.
  ]]--
  for index, gearBarConfigurationFrame in pairs(gearBarConfigurationFrames) do
    if index > #gearBars then
      mod.logger.LogDebug(me.tag, "Cleaning up orphaned configurationframe")
      me.ResetGearBarConfigurationFrame(gearBarConfigurationFrame)
      gearBarConfigurationFrame:Hide()
    end
  end
end

--[[
  Update a gearBarConfigFrames properties. This happens because the configframes are reused
  and all necessary properties need to be updated to match the new list entry

  @param {table} gearBar
  @param {table} gearBarConfigurationFrame
]]--
function me.UpdateGearBarConfigurationFrame(gearBar, gearBarConfigurationFrame)
  gearBarConfigurationFrame.gearBarId = gearBar.id
  gearBarConfigurationFrame.deleteButton.gearBarId = gearBar.id
  gearBarConfigurationFrame.title:SetText(RGGM_CONSTANTS.GEAR_BAR_CONFIG_DEFAULT_TITLE .. gearBar.id)

  --if gearBarConfigurationFrame.gearSlotHolder.slots == nil then
    --gearBarConfigurationFrame.gearSlotHolder.slots = {}
  --end

  for position, gearBarSlot in pairs(gearBar.slots) do
    --if gearBarConfigurationFrame.gearSlotHolder.slots[position] == nil then
      -- local gearSlot = me.CreateConfigurationGearSlot(gearBarConfigurationFrame.gearSlotHolder, position)
      -- table.insert(gearBarConfigurationFrame.gearSlotHolder.slots, gearSlot)

    --end

    -- local gearBarConfigurationSlot = gearBarConfigurationFrame.gearSlotHolder.slots[position]
    -- gearBarConfigurationSlot.itemIconHolder:SetTexture(gearBarSlot.textureId)
    -- gearBarConfigurationSlot:Show()
  end

  --[[
    Hide leftover slots. This happens because elements are reused.
    As an example if a gearBar with 10 slots is removed and a new one is created
    it will reuse the deleted gearBar and thus already has 10 created slots even though it
    only needs the default one(1). Make sure to hide all other slots
  ]]--
  --for index, slot in pairs(gearBarConfigurationFrame.gearSlotHolder.slots) do
    --if index > #gearBar.slots then
      --slot:Hide()
    --end
  --end
end

--[[
  TODO
]]--
function me.CreateGearBarSlotConfigurationList(parentFrame, position)
  local scrollFrame = CreateFrame(
    "ScrollFrame",
    RGGM_CONSTANTS.ELEMENT_GEAR_SLOT_CONFIGURATION_SCROLL_FRAME .. position,
    parentFrame,
    "FauxScrollFrameTemplate"
  )

  --[[
    Store reference of the scroll container for all slot configurations
    on gearBar configuration container
  ]]--
  parentFrame.scrollFrame = scrollFrame

  scrollFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_LIST_CONFIG_CONTENT_FRAME_WIDTH - 25) -- TODO
  -- Formula max rows = GEAR_BAR_LIST_CONFIG_CONTENT_FRAME_HEIGHT - inital position / SLOT_CONFIGURATION_LIST_ROW_HEIGHT
  scrollFrame:SetHeight(
    RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_ROW_HEIGHT * RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_MAX_ROWS -- TODO
  )
  scrollFrame:SetPoint("TOPLEFT", 0, -100)
  scrollFrame:EnableMouseWheel(true)


  scrollFrame:SetBackdrop({
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background", -- TODO development only
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

  scrollFrame:SetBackdropColor(0.37, 0, 0, .4)

  scrollFrame:SetScript("OnVerticalScroll", me.GearBarSlotConfigurationListOnVerticalScroll)

  --[[
    TODO store created rows in gearBarConfigFrame
  ]]--
  parentFrame.rows = {}

  for i = 1, RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_MAX_ROWS do
    table.insert(parentFrame.rows, me.CreateGearSlotConfigurationRowFrame(scrollFrame, i))
  end


  -- scrollFrame:SetFrameLevel(parentFrame:GetFrameLevel() + 1)

  return scrollFrame
end

--[[
  OnVerticalScroll callback for scrollable rule list

  @param {table} self
  @param {number} offset
]]--
function me.GearBarSlotConfigurationListOnVerticalScroll(self, offset)
  self.ScrollBar:SetValue(offset)
  self.offset = math.floor(offset / RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_ROW_HEIGHT + 0.5)
  me.GearSlotConfigurationScrollFrameOnUpdate(self)
end

--[[
  @param {table} frame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateGearSlotConfigurationRowFrame(frame, position)
  local row = CreateFrame("Button", "TODOTEST" .. position, frame) -- TODO
  row:SetSize(frame:GetWidth() -5, RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_ROW_HEIGHT)-- TODO
  row:SetPoint("TOPLEFT", frame, 8, (position -1) * RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_ROW_HEIGHT * -1) -- TODO

  row:SetBackdrop({
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background", -- TODO development only
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

  if math.fmod(position, 2) == 0 then
    row:SetBackdropColor(0.37, 0, 0, .4)
  else
    row:SetBackdropColor(0, .25, .25, .8)
  end

  local itemIcon = row:CreateTexture(nil, "ARTWORK")
  itemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  itemIcon:SetPoint("LEFT", 0, 0)
  itemIcon:SetSize(
    16,
    16
  )

  row.itemIcon = itemIcon -- TODO

  return row
end

--[[
  Update a scrollable list holding configuration frames for gearBar slots

  @param {table} scrollFrame
]]--
function me.GearSlotConfigurationScrollFrameOnUpdate(scrollFrame)
  local gearBarId = scrollFrame:GetParent().gearBarId
  mod.logger.LogError(me.tag, "ScrolLFrame update for gearBarId: " .. gearBarId)
  local gearBar = mod.gearBarManager.GetGearBar(gearBarId)

  local rows = scrollFrame:GetParent().rows
  local maxValue = table.getn(gearBar.slots) or 0

  if maxValue <= RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_MAX_ROWS then -- TODO
    maxValue = RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_MAX_ROWS + 1 -- TODO
  end
  -- Note: maxValue needs to be at least max_rows + 1
  FauxScrollFrame_Update(
    scrollFrame,
    maxValue,
    RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_MAX_ROWS, -- TODO
    RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_ROW_HEIGHT -- TODO
  )

  local offset = FauxScrollFrame_GetOffset(scrollFrame)
  for index = 1, RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_MAX_ROWS do -- TODO
    local value = index + offset

    if value <= table.getn(gearBar.slots) then
      local row = rows[index]

      row.itemIcon:SetTexture(136516) -- TODO hardcoded
      row:Show()
    else
      rows[index]:Hide()
    end
  end
end


--[[
  TODO creates gearslots for the purpose of configuring them
  TODO will need to check if we need a scrollable frame for all those slots
]]--
function me.CreateConfigurationGearSlot(gearSlotHolder, position)
  mod.logger.LogError(me.tag, "Creating a new configuration slot position - " .. position)
  local gearSlot = CreateFrame(
    "FRAME",
    RGGM_CONSTANTS.ELEMENT_CONFIG_FRAME_GEAR_SLOT .. position,
    gearSlotHolder
  )
  local gearBarSlotSize = mod.configuration.GetSlotSize()

  gearSlot:SetFrameLevel(gearSlotHolder:GetFrameLevel() + 1)
  gearSlot:SetSize(gearBarSlotSize, gearBarSlotSize)

  if position == 1 then
    gearSlot:SetPoint("LEFT", 0, -20)
  else
    gearSlot:SetPoint("LEFT", 0, position * -40 -20)
  end


  gearSlot.itemIconHolder = me.CreateItemIconHolder(gearSlot)

  return gearSlot
end

--[[
  Create a frame that holds the items icon

  @param {table} gearSlot

  @return {table}
    The created iconHolderFrame
]]
function me.CreateItemIconHolder(gearSlot)
  local gearBarSlotSize = mod.configuration.GetSlotSize()
  local iconHolder = CreateFrame("Frame", nil, gearSlot)

  iconHolder:SetSize(
    gearBarSlotSize,
    gearBarSlotSize
  )
  iconHolder:SetPoint("LEFT", 40, 0)

  local itemIconHolder = iconHolder:CreateTexture(nil, "ARTWORK")
  itemIconHolder.iconHolder = iconHolder
  itemIconHolder:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  itemIconHolder:SetPoint("CENTER", 0, 0)
  itemIconHolder:SetSize(
    gearBarSlotSize,
    gearBarSlotSize
  )

  return itemIconHolder
end

--[[
  Reset a configuration frame into a default state

  @param {table} gearBarConfigurationFrame
]]--
function me.ResetGearBarConfigurationFrame(gearBarConfigurationFrame)
  gearBarConfigurationFrame.gearBarId = nil
  gearBarConfigurationFrame.deleteButton.gearBarId = nil
  gearBarConfigurationFrame.title:SetText("")
end

--[[
  Creates a frame that holds all elements for configuring a specific gearbar

  @param {table} parentFrame
    Optional frame that is used as a parent for the newly created configurationFrame
  @param {table} contentFrame
    The frame that contains all the configurationFrames
  @param {number} position
  @param {table} gearBar
    A gearbar object containing all metadata related to a gearBar

  @return {table}
    The created configFrame
]]--
function me.CreateGearBarConfigFrame(parentFrame, contentFrame, position, gearBar)
  local gearBarConfigFrame = CreateFrame(
    "Frame",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_FRAME .. position,
    contentFrame
  )

  gearBarConfigFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_LIST_CONFIG_CONTENT_FRAME_WIDTH)
  gearBarConfigFrame:SetHeight(RGGM_CONSTANTS.GEAR_BAR_LIST_CONFIG_CONTENT_FRAME_HEIGHT)

  gearBarConfigFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })

  if math.fmod(position, 2) == 0 then
    gearBarConfigFrame:SetBackdropColor(0.37, 0.37, 0.37, .4)
  else
    gearBarConfigFrame:SetBackdropColor(.25, .25, .25, .8)
  end

  gearBarConfigFrame.position = position -- position in the gearBarList
  gearBarConfigFrame.gearBarId = gearBar.id
  gearBarConfigFrame.title = me.CreateGearBarName(gearBarConfigFrame)
  gearBarConfigFrame.deleteButton = me.CreateDeleteGearBarButton(gearBarConfigFrame)
  gearBarConfigFrame.addGearSlotButton = me.CreateAddGearSlotButton(gearBarConfigFrame)
  gearBarConfigFrame.removeGearSlotButton = me.CreateRemoveGearSlotButton(gearBarConfigFrame)

  me.CreateGearBarSlotConfigurationList(gearBarConfigFrame, position) -- TODO
  me.GearSlotConfigurationScrollFrameOnUpdate(
    _G[RGGM_CONSTANTS.ELEMENT_GEAR_SLOT_CONFIGURATION_SCROLL_FRAME .. position]
  )

  --[[
    Creating a list of frames with different heights each frame should follow after another.
    The first frame in the list is the only one that does not have a parentframe.
  ]]--
  if parentFrame ~= nil then
    gearBarConfigFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -parentFrame:GetHeight())
  else
    gearBarConfigFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
  end

  -- gearBarConfigFrame.gearSlotHolder = me.CreateConfigFrameGearSlotHolder(gearBarConfigFrame) --TODO

  mod.logger.LogDebug(me.tag, "Created new gearbar configframe")

  return gearBarConfigFrame
end

--[[
  @param {table} gearBarConfigFrame

  @return {table}
    The created gearSlot Holder that will hold all configuration elements related to the gearSlot
]]--
function me.CreateConfigFrameGearSlotHolder(gearBarConfigFrame)
  local configFrameGearSlotHolder = CreateFrame(
    "Frame",
    RGGM_CONSTANTS.ELEMENT_CONFIG_FRAME_GEAR_SLOT_HOLDER,
    gearBarConfigFrame
  )

  configFrameGearSlotHolder:SetWidth(RGGM_CONSTANTS.CONFIG_FRAME_GEAR_SLOT_HOLDER_WIDTH)
  configFrameGearSlotHolder:SetHeight(RGGM_CONSTANTS.CONFIG_FRAME_GEAR_SLOT_HOLDER_DEFAULT_HEIGHT)

  configFrameGearSlotHolder:SetPoint("TOPLEFT", gearBarConfigFrame, "TOPLEFT", 0, -50)

  configFrameGearSlotHolder:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })

  configFrameGearSlotHolder:SetBackdropColor(.5, .4, .53, 1)

  return configFrameGearSlotHolder
end

--[[
  Create a fontString holder for the name of the GearBar

  @param {table} gearBarConfigFrame

  @return {table}
    The created fontString
]]--
function me.CreateGearBarName(gearBarConfigFrame)
  local gearBarNameFontString = gearBarConfigFrame:CreateFontString(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_FRAME_TITLE,
    "OVERLAY"
  )
  gearBarNameFontString:SetFont(STANDARD_TEXT_FONT, 15)
  gearBarNameFontString:SetPoint("TOPLEFT", gearBarConfigFrame, 25, -20)
  gearBarNameFontString:SetText(RGGM_CONSTANTS.GEAR_BAR_CONFIG_DEFAULT_TITLE .. gearBarConfigFrame.gearBarId)

  return gearBarNameFontString
end

--[[
  @param {table} gearBarConfigFrame

  @return {table}
    The created button
]]--
function me.CreateDeleteGearBarButton(gearBarConfigFrame)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_MENU_BUTTON_DELETE_GEAR_BAR,
    gearBarConfigFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_delete_gearbar"])
  button:SetPoint("TOPRIGHT", -10, -20)
  button:SetScript('OnClick', me.DeleteGearBar)

  button.gearBarId = gearBarConfigFrame.gearBarId

  local buttonFontString = button:GetFontString()

  button:SetWidth(
    buttonFontString:GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Delete a gearBar. This includes both from the gearBarManager and from the gearBarMenu

  @param {table} self

]]--
function me.DeleteGearBar(self)
  mod.gearBarManager.RemoveGearBar(self.gearBarId)
  -- remove the actual ui gearBar element
  mod.gearBar.RemoveGearBar(self.gearBarId)
  --[[
    Remove the configuration for the gearBar from the gearBarMenu by checking the position in the
    gearBar list and hiding it.

    TODO in the end we need a way to reset an entry inside the list that we can then later reuse
  ]]--
  local position = self:GetParent().position
  gearBarConfigurationFrames[position]:Hide()

  me.UpdateGearBarMenu()
  -- TODO should have an updateGearBar that then calls mod.gearBar.RemoveGearBar(self.gearBarId)
end

--[[
  Add a button to the gearBar configurationFrame that allows for adding more
  slots to a specific gearBar

  @param {table} gearBarConfigFrame
    A reference to the gearBarConfigFrame for the specific gearBar

  @return {table}
    The created button
]]--
function me.CreateAddGearSlotButton(gearBarConfigFrame)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_MENU_BUTTON_ADD_SLOT,
    gearBarConfigFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_add_gearslot"])
  button:SetPoint("TOPLEFT", 50, -50)
  button:SetScript('OnClick', me.AddGearSlot)
  -- Attach gearBarId to the button
  button.gearBarId = gearBarConfigFrame.gearBarId

  local buttonFontString = button:GetFontString()

  button:SetWidth(
    buttonFontString:GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Add a new gearSlot to a gearBar based on the gearBarId on the clicked button

  @param {table} self
    A reference to the button that was clicked
]]--
function me.AddGearSlot(self)
  local gearBar = mod.gearBarManager.GetGearBar(self.gearBarId)

  if gearBar == nil then
    mod.logger.LogError(me.tag, "Failed to find gearBar with id: " .. self.gearBarId)
    return
  end

  if not mod.gearBarManager.AddNewGearSlot(self.gearBarId) then
    mod.logger.LogError(me.tag, "Failed to add new gearSlot to gearBar with id: " .. self.id)
    return
  end

  me.UpdateGearBarMenu()
  mod.gearBar.UpdateGearBar(gearBar)
end

--[[
  Add a button to the gearBar configurationFrame that allows for removing
  slots from a specific gearBar

  @param {table} gearBarConfigFrame
    A reference to the gearBarConfigFrame for the specific gearBar

  @return {table}
    The created button
]]--
function me.CreateRemoveGearSlotButton(gearBarConfigFrame)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_MENU_BUTTON_REMOVE_SLOT,
    gearBarConfigFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_remove_gearslot"])
  button:SetPoint("TOPLEFT", 80, -50)
  button:SetScript('OnClick', me.RemoveGearSlot)
  -- Attach gearBarId to the button
  button.gearBarId = gearBarConfigFrame.gearBarId

  local buttonFontString = button:GetFontString()

  button:SetWidth(
    buttonFontString:GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Remove a gearSlot from a gearBar based on the gearBarId on the clicked button
  Will always remove the highest index in the gearBar

  @param {table} self
    A reference to the button that was clicked
]]--
function me.RemoveGearSlot(self)
  local gearBar = mod.gearBarManager.GetGearBar(self.gearBarId)

  if gearBar == nil then
    mod.logger.LogError(me.tag, "Failed to find gearBar with id: " .. self.gearBarId)
    return
  end

  if not mod.gearBarManager.RemoveGearSlot(self.gearBarId, #gearBar.slots) then
    mod.logger.LogError(me.tag, "Failed to remove gearSlot from gearBar with id: " .. self.id)
    return
  end

  me.UpdateGearBarMenu()
  mod.gearBar.UpdateGearBar(gearBar)
end
