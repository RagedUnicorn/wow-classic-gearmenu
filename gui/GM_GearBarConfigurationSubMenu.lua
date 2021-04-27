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

-- luacheck: globals STANDARD_TEXT_FONT CreateFrame FauxScrollFrame_Update FauxScrollFrame_GetOffset
-- luacheck: globals UIDropDownMenu_Initialize UIDropDownMenu_AddButton UIDropDownMenu_SetSelectedValue

--[[
  The gearBarMenu (GM_GearBarConfigurationMenu) module has some similarities to the gearBar (GM_GearBar) module.
  It is also heavily interacting with gearBarManager (GM_GearBarManager) module but unlike the gearBar module
  its purpose is to change and create values in the gearBarManager. It is used to give the user a UI to create, delete
  and modify new gearBars and slots.
]]--

--[[
  Module for responsible to create a configuration menu for a single gearBar that is reused by all other
  gearBars
]]--

local mod = rggm
local me = {}

mod.gearBarConfigurationSubMenu = me

me.tag = "GearBarConfigurationSubMenu"

--[[
  Reference to the scrollable slots list
]]--
local gearBarConfigurationSlotsList

--[[
  Holds a reference to the reusable configuration content frame. This frame holds a list
  of slots that are configurable. More slots can be added or removed. When this frame is reused
  the parent needs to be adapted and the ui update to represent the state of the gearBar
]]
local gearBarConfigurationContentFrame = nil

--[[
  The gearBarId of the gearBar that is currently getting configured
  (changes with switching menu to another gearBar in addon settings)
]]--
local gearBarConfiguration = nil

--[[
  Option texts for checkbutton options
]]--
local options = {
  {"LockGearBar", rggm.L["window_lock_gear_bar"], rggm.L["window_lock_gear_bar_tooltip"]}
}

--[[
  Callback for when the menu entrypoint is clicked in the interface options. A callback
  like this exists for every separate gearBar that was created.

  @param {table} self
]]--
function me.GearBarConfigurationCategoryContainerOnCallback(self)
  -- update the current edited gearBar
  gearBarConfiguration = mod.gearBarManager.GetGearBar(self.gearBarId)

  if gearBarConfigurationContentFrame ~= nil then
    -- update parent of the reused container
    gearBarConfigurationContentFrame:SetParent(self)
    -- trigger visual update
    me.GearBarConfigurationSlotsListOnUpdate(gearBarConfigurationSlotsList)
  else
    -- menu was not yet created
    me.BuildGearBarConfigurationMenu(self)
  end
end

--[[
  Build the UI base for a specific gearBar with all its slots and configuration possibilities

  @param {table} parentFrame
    The menu entry in the interface options
]]
function me.BuildGearBarConfigurationMenu(parentFrame)
  gearBarConfigurationContentFrame = CreateFrame(
    "Frame", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SUB_MENU, parentFrame)
  gearBarConfigurationContentFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SUB_MENU_CONTENT_FRAME_WIDTH)
  gearBarConfigurationContentFrame:SetHeight(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SUB_MENU_CONTENT_FRAME_HEIGHT)
  gearBarConfigurationContentFrame:SetPoint("TOPLEFT", parentFrame, 5, -7)

  local titleFontString =
    gearBarConfigurationContentFrame:CreateFontString(RGGM_CONSTANTS.ELEMENT_GENERAL_TITLE, "OVERLAY")
  titleFontString:SetFont(STANDARD_TEXT_FONT, 20)
  titleFontString:SetPoint("TOP", 0, -20)
  titleFontString:SetSize(parentFrame:GetWidth(), 20)

  if RGGM_ENVIRONMENT.DEBUG then
    titleFontString:SetText(gearBarConfiguration.displayName .. "_" .. gearBarConfiguration.id)
  else
    titleFontString:SetText(gearBarConfiguration.displayName)
  end

  me.CreateAddGearSlotButton(gearBarConfigurationContentFrame)
  me.CreateRemoveGearSlotButton(gearBarConfigurationContentFrame)
  me.CreateLockGearBarCheckButton(gearBarConfigurationContentFrame)

  gearBarConfigurationSlotsList = me.CreateGearBarConfigurationSlotsList(gearBarConfigurationContentFrame)
  me.GearBarConfigurationSlotsListOnUpdate(gearBarConfigurationSlotsList)
end

--[[
  Add a button to the gearBar configurationFrame that allows for adding more
  slots to the gearBar

  @param {table} parentFrame

  @return {table}
    The created button
]]--
function me.CreateAddGearSlotButton(parentFrame)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_ADD_SLOT_BUTTON,
    parentFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_add_gearslot"])
  button:SetPoint("TOPLEFT", 50, -50)
  button:SetScript('OnClick', me.AddGearSlot)
  -- Attach gearBarId to the button
  button.gearBarId = parentFrame.gearBarId

  local buttonFontString = button:GetFontString()

  button:SetWidth(
    buttonFontString:GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Add a new gearSlot to a gearBar based on the gearBarId on the clicked button
]]--
function me.AddGearSlot()
  local gearBar = mod.gearBarManager.GetGearBar(gearBarConfiguration.id)

  if gearBar == nil then
    mod.logger.LogError(me.tag, "Failed to find gearBar with id: " .. gearBarConfiguration.id)
    return
  end

  if not mod.gearBarManager.AddNewGearSlot(gearBarConfiguration.id) then
    mod.logger.LogError(me.tag, "Failed to add new gearSlot to gearBar with id: " .. gearBarConfiguration.id)
    return
  end

  me.UpdateGearBarConfigurationMenu()
  mod.gearBar.UpdateGearBar(gearBarConfiguration)
end

--[[
  Add a button to the gearBar configurationFrame that allows for removing
  slots from a specific gearBar

  @param {table} parentFrame

  @return {table}
    The created button
]]--
function me.CreateRemoveGearSlotButton(parentFrame)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_REMOVE_SLOT_BUTTON,
    parentFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_remove_gearslot"])
  button:SetPoint("TOPLEFT", 80, -50)
  button:SetScript('OnClick', me.RemoveGearSlot)
  -- Attach gearBarId to the button
  button.gearBarId = parentFrame.gearBarId

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

  me.GearBarOnUpdate()
end

--[[
  Checkbox button for locking/unlocking moving of a specific gearBar

  @param {table} parentFrame
]]--
function me.CreateLockGearBarCheckButton(parentFrame)
  local checkButtonOptionFrame = CreateFrame(
    "CheckButton",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_OPT_LOCK_GEAR_BAR,
    parentFrame,
    "UICheckButtonTemplate"
  )
  checkButtonOptionFrame:SetSize(
    RGGM_CONSTANTS.GENERAL_CHECK_OPTION_SIZE,
    RGGM_CONSTANTS.GENERAL_CHECK_OPTION_SIZE
  )
  checkButtonOptionFrame:SetPoint("TOPLEFT", 20, -100)

  for _, region in ipairs({checkButtonOptionFrame:GetRegions()}) do
    if string.find(region:GetName() or "", "Text$") and region:IsObjectType("FontString") then
      region:SetFont(STANDARD_TEXT_FONT, 15)
      region:SetTextColor(.95, .95, .95)
      region:SetText(rggm.L["window_lock_gear_bar"])
      break
    end
  end

  checkButtonOptionFrame:SetScript("OnEnter", me.OptTooltipOnEnter)
  checkButtonOptionFrame:SetScript("OnLeave", me.OptTooltipOnLeave)
  checkButtonOptionFrame:SetScript("OnShow", me.LockWindowGearBarOnShow)
  checkButtonOptionFrame:SetScript("OnClick", me.LockWindowGearBarOnClick)
  -- load initial state
  me.LockWindowGearBarOnShow(checkButtonOptionFrame)
end

--[[
  OnShow callback for checkbuttons - window lock gearBar

  @param {table} self
]]--
function me.LockWindowGearBarOnShow(self)
  if mod.gearBarManager.IsGearBarLocked(self:GetParent():GetParent().gearBarId) then
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
  local gearBarId = self:GetParent():GetParent().gearBarId

  if enabled then
    mod.gearBarManager.LockGearBar(gearBarId)
  else
    mod.gearBarManager.UnlockGearBar(gearBarId)
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
    if name == RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_OPT_TOOLTIP .. options[i][1] then
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
  @param {table} parentFrame

  @return {table}
    The created scrollFrame
]]--
function me.CreateGearBarConfigurationSlotsList(parentFrame)
  local scrollFrame = CreateFrame(
    "ScrollFrame",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_SCROLL_FRAME,
    parentFrame,
    "FauxScrollFrameTemplate"
  )

  --[[
    Store reference of the scroll container for all slot configurations
    on gearBar configuration container
  ]]--
  parentFrame.scrollFrame = scrollFrame

  scrollFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_WIDTH)
  scrollFrame:SetHeight(
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_ROW_HEIGHT
    * RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS
  )
  scrollFrame:SetPoint("TOPLEFT", 20, -200)
  scrollFrame:EnableMouseWheel(true)


  -- TODO development only
  scrollFrame:SetBackdrop({
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })
  scrollFrame:SetBackdropColor(0.37, 0, 0, .4)

  scrollFrame:SetScript("OnVerticalScroll", me.GearBarConfigurationSlotsListOnVerticalScroll)

  parentFrame.rows = {}

  for i = 1, RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS do
    table.insert(parentFrame.rows, me.CreateGearBarConfigurationSlotsListRowFrame(scrollFrame, i))
  end

  return scrollFrame
end

--[[
  OnVerticalScroll callback for scrollable slots list

  @param {table} self
  @param {number} offset
]]--
function me.GearBarConfigurationSlotsListOnVerticalScroll(self, offset)
  self.ScrollBar:SetValue(offset)
  self.offset = math.floor(offset / RGGM_CONSTANTS.SLOT_CONFIGURATION_LIST_ROW_HEIGHT + 0.5)
  me.GearBarConfigurationSlotsListOnUpdate(self)
end

--[[
  @param {table} frame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateGearBarConfigurationSlotsListRowFrame(frame, position)
  local row = CreateFrame("Button",  RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_ROW_FRAME .. position, frame)
  row:SetSize(frame:GetWidth(), RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", frame, 0, (position -1) * RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_ROW_HEIGHT * -1)

  -- TODO development only
  row:SetBackdrop({
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

  if math.fmod(position, 2) == 0 then
    row:SetBackdropColor(0.37, 0, 1, 1)
  else
    row:SetBackdropColor(0, .4, .6, 1)
  end

  row.slotIcon = me.CreateGearBarConfigurationSlotIcon(row)
  row.gearSlot = me.CreateGearBarConfigurationSlotDropdown(row, position)
  row.keybindButton = me.CreateGearBarConfigurationSlotKeybindButton(row, position)

  return row
end


--[[
  Create a button that allows the user to set a keyBinding for the gearSlot

  @param {table} row
  @param {number} position
    Position of the slot on the gearBar
]]--
function me.CreateGearBarConfigurationSlotKeybindButton(row, position)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_KEY_BINDING_BUTTON .. position,
    row,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText("todokeybind")
  button:SetPoint("TOPLEFT", 200, 0)
  button:SetScript("OnClick", function()
    mod.keyBind.SetKeyBindingForGearSlot(gearBarConfiguration, position)
  end)

  button:SetWidth(
    button:GetFontString():GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end


--[[
  @param {table} row

  @return {table}
    The created texture
]]--
function me.CreateGearBarConfigurationSlotIcon(row)
  local slotIcon = row:CreateTexture(nil, "ARTWORK")
  slotIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  slotIcon:SetPoint("LEFT", 5, 0)
  slotIcon:SetSize(
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_GEAR_SLOT_ICON_SIZE,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_GEAR_SLOT_ICON_SIZE
  )

  return slotIcon
end

--[[
  @param {table} row
  @param {number} position

  @return {table}
    The created dropdown menu
]]--
function me.CreateGearBarConfigurationSlotDropdown(row, position)
  local gearSlotDropdownMenu = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_GEAR_SLOT_DROPDOWN .. position,
    row,
    "UIDropDownMenuTemplate"
  )
  gearSlotDropdownMenu.position = position
  gearSlotDropdownMenu:SetPoint("TOPLEFT", 20, -5)

  UIDropDownMenu_Initialize(gearSlotDropdownMenu, me.InitializeDropdownMenu)

  return gearSlotDropdownMenu
end

--[[
  Initialize dropdownmenus for slotpositions

  @param {table} self
]]--
function me.InitializeDropdownMenu(self)
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

  UIDropDownMenu_SetSelectedValue(
    _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_GEAR_SLOT_DROPDOWN .. self.position],
    RGGM_CONSTANTS.INVSLOT_NONE
  )
end

--[[
  Callback for optionsmenu dropdowns

  @param {table} self
]]
function me.DropDownMenuCallback(self)
  -- retrieve offset in scrollable list
  local offset = self:GetParent().dropdown:GetParent():GetParent().offset
  -- get position in visible slots (GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS)
  local position = self:GetParent().dropdown.position
  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(self.value)

  -- include offset to position to get the actual position
  mod.gearBarManager.UpdateGearSlot(gearBarConfiguration.id, position + offset, gearSlotMetaData)
  me.GearBarOnUpdate()
  UIDropDownMenu_SetSelectedValue(
    _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_GEAR_SLOT_DROPDOWN .. position], self.value
  )
end

--[[
  Update a scrollable list holding configuration frames for gearBar slots

  @param {table} scrollFrame
]]--
function me.GearBarConfigurationSlotsListOnUpdate(scrollFrame)
  local rows = scrollFrame:GetParent().rows
  local maxValue = table.getn(gearBarConfiguration.slots) or 0

  if maxValue <= RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS then
    maxValue = RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS + 1
  end
  -- Note: maxValue needs to be at least max_rows + 1
  FauxScrollFrame_Update(
    scrollFrame,
    maxValue,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_ROW_HEIGHT
  )

  local offset = FauxScrollFrame_GetOffset(scrollFrame)
  for index = 1, RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS do
    local value = index + offset

    if value <= table.getn(gearBarConfiguration.slots) then
      local row = rows[index]

      local slot = gearBarConfiguration.slots[value]
      if slot == nil then return end -- no more slots available for that gearBar

      row.slotIcon:SetTexture(slot.textureId)
      -- update preselected dropdown value for the slot
      UIDropDownMenu_SetSelectedValue(
        row.gearSlot, slot.slotId
      )
      row:Show()
    else
      rows[index]:Hide()
    end
  end
end

--[[
  Update all gearBars shown to the user
  Update the gearBar configuration of the gearBar that is currently being configured
]]--
function me.GearBarOnUpdate()
  me.UpdateGearBarConfigurationMenu()
  mod.gearBar.UpdateGearBar(gearBarConfiguration)
end

--[[
  Function for updating everything related to the configuration menu. Such as when
  a slot was removed or added
]]--
function me.UpdateGearBarConfigurationMenu()
  me.GearBarConfigurationSlotsListOnUpdate(gearBarConfigurationSlotsList)
end
