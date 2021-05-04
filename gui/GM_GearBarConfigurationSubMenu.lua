--[[
  MIT License

  Copyright (c) 2021 Michael Wiesendanger

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
  {"LockGearBar", rggm.L["window_lock_gear_bar"], rggm.L["window_lock_gear_bar_tooltip"]},
  {"ShowKeyBindings", rggm.L["show_keybindings"], rggm.L["show_keybindings_tooltip"]},
  {"ShowCooldowns", rggm.L["show_cooldowns"], rggm.L["show_cooldowns_tooltip"]}
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
  -- me.CreateLockGearBarCheckButton(gearBarConfigurationContentFrame)

  me.BuildCheckButtonOption(
    gearBarConfigurationContentFrame,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_OPT_LOCK_GEAR_BAR,
    {"TOPLEFT", 20, -50},
    me.LockWindowGearBarOnShow,
    me.LockWindowGearBarOnClick
  )

  me.BuildCheckButtonOption(
    gearBarConfigurationContentFrame,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_OPT_SHOW_KEY_BINDINGS,
    {"TOPLEFT", 20, -80},
    me.ShowKeyBindingsOnShow,
    me.ShowKeyBindingsOnClick
  )

  me.BuildCheckButtonOption(
    gearBarConfigurationContentFrame,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_OPT_SHOW_COOLDOWNS,
    {"TOPLEFT", 20, -110},
    me.ShowCooldownsOnShow,
    me.ShowCooldownsOnClick
  )

  me.CreateSizeSlider(gearBarConfigurationContentFrame)

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
  button:SetPoint("TOPLEFT", 20, -210)
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

  if not mod.gearBarManager.AddGearSlot(gearBarConfiguration.id) then
    mod.logger.LogError(me.tag, "Failed to add new gearSlot to gearBar with id: " .. gearBarConfiguration.id)
    return
  end

  me.UpdateGearBarConfigurationMenu()
  mod.gearBar.UpdateGearBar(gearBarConfiguration)
end

--[[
  Build a checkbutton option

  @param {table} parentFrame
  @param {string} optionFrameName
  @param {table} position
  @param {function} onShowCallback
  @param {function} onClickCallback
]]--
function me.BuildCheckButtonOption(parentFrame, optionFrameName, position, onShowCallback, onClickCallback)
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
    if name == RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_OPT_TOOLTIP .. options[i][1] then
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
  OnShow callback for checkbuttons - show keyBindings

  @param {table} self
]]--
function me.ShowKeyBindingsOnShow(self)
  if mod.gearBarManager.IsShowKeyBindingsEnabled(self:GetParent():GetParent().gearBarId) then
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
  local gearBarId = self:GetParent():GetParent().gearBarId

  if enabled then
    mod.gearBarManager.EnableShowKeyBindings(gearBarId)
  else
    mod.gearBarManager.DisableShowKeyBindings(gearBarId)
  end
end

--[[
  OnShow callback for checkbuttons - show cooldowns

  @param {table} self
]]--
function me.ShowCooldownsOnShow(self)
  if mod.gearBarManager.IsShowCooldownsEnabled(self:GetParent():GetParent().gearBarId) then
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
  local gearBarId = self:GetParent():GetParent().gearBarId

  if enabled then
    mod.gearBarManager.EnableShowCooldowns(gearBarId)
  else
    mod.gearBarManager.DisableShowCooldowns(gearBarId)
  end
end

--[[
  Create a slider for changing the size of the gearSlots

  @param {table} frame
]]--
function me.CreateSizeSlider(frame)
  local sizeSlider = CreateFrame(
    "Slider",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SIZE_SLIDER,
    frame,
    "OptionsSliderTemplate"
  )
  sizeSlider:SetWidth(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_WIDTH)
  sizeSlider:SetHeight(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_HEIGHT)
  sizeSlider:SetOrientation('HORIZONTAL')
  sizeSlider:SetPoint("TOPLEFT", 20, -150)
  sizeSlider:SetMinMaxValues(
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MIN,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MAX
  )
  sizeSlider:SetValueStep(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_STEP)
  sizeSlider:SetObeyStepOnDrag(true)
  sizeSlider:SetValue(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE)

  -- Update slider texts
  _G[sizeSlider:GetName() .. "Low"]:SetText(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MIN)
  _G[sizeSlider:GetName() .. "High"]:SetText(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MAX)
  _G[sizeSlider:GetName() .. "Text"]:SetText(rggm.L["size_slider_title"])
  sizeSlider.tooltipText = rggm.L["size_slider_tooltip"]

  local valueFontString = sizeSlider:CreateFontString(nil, "OVERLAY")
  valueFontString:SetFont(STANDARD_TEXT_FONT, 12)
  valueFontString:SetPoint("BOTTOM", 0, -15)
  valueFontString:SetText(sizeSlider:GetValue())

  sizeSlider.valueFontString = valueFontString
  sizeSlider:SetScript("OnValueChanged", me.GearSlotSizeSliderOnValueChange)
  sizeSlider:SetScript("OnShow", me.GearSlotSizeSliderOnShow)

  -- load initial state
  me.GearSlotSizeSliderOnShow(sizeSlider)
end

--[[
  OnValueChanged callback for size slider

  @param {table} self
  @param {number} value
]]--
function me.GearSlotSizeSliderOnValueChange(self, value)
  local gearBarId = self:GetParent():GetParent().gearBarId

  mod.gearBarManager.SetGearSlotSize(gearBarId, value)
  self.valueFontString:SetText(value)
end

--[[
  Invoked when the gearSlot size slider is shown. Updates the configured value

  @param {table} self
]]--
function me.GearSlotSizeSliderOnShow(self)
  local gearBarId = self:GetParent():GetParent().gearBarId

  self:SetValue(mod.gearBarManager.GetGearSlotSize(gearBarId))
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
  scrollFrame:SetPoint("TOPLEFT", 20, -240)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

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
  row:SetBackdrop({
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

  if math.fmod(position, 2) == 0 then
    row:SetBackdropColor(0.37, 0.37, 0.37, .4)
  else
    row:SetBackdropColor(.25, .25, .25, .8)
  end

  row.slotIcon = me.CreateGearBarConfigurationSlotIcon(row)
  row.gearSlot = me.CreateGearBarConfigurationSlotDropdown(row, position)
  row.keyBindButton = me.CreateGearBarConfigurationSlotKeybindButton(row, position)
  row.keyBindText = me.CreateKeyBindingText(row, row.keyBindButton)
  row.removeGearSlotButton = me.CreateRemoveGearSlotButton(row)

  return row
end

--[[
  @param {table} row

  @return {table}
    The created texture
]]--
function me.CreateGearBarConfigurationSlotIcon(row)
  local iconHolder = CreateFrame("Frame", nil, row)
  iconHolder:SetSize(
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_GEAR_SLOT_ICON_SIZE + 5,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_GEAR_SLOT_ICON_SIZE + 5
  )
  iconHolder:SetPoint("LEFT", 5, 0)

  local slotIcon = iconHolder:CreateTexture(nil, "ARTWORK")
  slotIcon.iconHolder = iconHolder
  slotIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  slotIcon:SetPoint("CENTER", 0, 0)
  slotIcon:SetSize(
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_GEAR_SLOT_ICON_SIZE,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_GEAR_SLOT_ICON_SIZE
  )

  local backdrop = {
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    edgeFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    tile = false,
    tileSize = 32,
    edgeSize = 20,
    insets = {
      left = 12,
      right = 12,
      top = 12,
      bottom = 12
    }
  }

  iconHolder:SetBackdrop(backdrop)
  iconHolder:SetBackdropBorderColor(0, 0.96, 0.83, 1)

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
  gearSlotDropdownMenu:SetPoint("TOPLEFT", 30, -10)

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
  Create a button that allows the user to set a keyBinding for the gearSlot

  @param {table} row
  @param {number} position
    Position of the slot on the gearBar

  @return {table}
    The created button
]]--
function me.CreateGearBarConfigurationSlotKeybindButton(row, position)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_KEY_BINDING_BUTTON .. position,
    row,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_key_binding_button"])
  button:SetPoint("TOPLEFT", 200, -11)
  button:SetScript("OnClick", function()
    mod.keyBind.SetKeyBindingForGearSlot(gearBarConfiguration, position)
  end)

  button:SetWidth(
    button:GetFontString():GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Create fontstring for title of the spell to configure

  @param {table} row
  @param {table} parentFrame

  @return {table}
    The created fontstring
]]--
function me.CreateKeyBindingText(row, parentFrame)
  local keybindingFontString = row:CreateFontString(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_KEY_BINDING_TEXT, "OVERLAY")
  keybindingFontString:SetFont(STANDARD_TEXT_FONT, 15)
  keybindingFontString:SetWidth(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_KEY_BINDING_TEXT_WIDTH)
  keybindingFontString:SetPoint(
    "LEFT",
    parentFrame,
    "RIGHT",
    0,
    0
  )
  keybindingFontString:SetTextColor(.95, .95, .95)

  return keybindingFontString
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
  button:SetPoint("RIGHT", -5, 0)
  button:SetScript('OnClick', me.RemoveGearSlot)

  local buttonFontString = button:GetFontString()

  button:SetWidth(
    buttonFontString:GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Remove a gearSlot from a gearBar based on the gearBarId and the position of the clicked button

  @param {table} self
]]--
function me.RemoveGearSlot(self)
  local gearBar = mod.gearBarManager.GetGearBar(gearBarConfiguration.id)
  local gearSlotPosition = self:GetParent().position

  if gearBar == nil then
    mod.logger.LogError(me.tag, "Failed to find gearBar with id: " .. gearBarConfiguration.id)
    return
  end

  local gearSlot = gearBar.slots[gearSlotPosition]

  if gearSlot.keyBinding ~= nil and gearSlot.keyBinding ~= "" then
    mod.keyBind.UnsetKeyBindingFromGearSlot(gearSlot)
  end

  if not mod.gearBarManager.RemoveGearSlot(gearBarConfiguration.id, self:GetParent().position) then
    mod.logger.LogError(me.tag, "Failed to remove gearSlot from gearBar with id: " .. gearBarConfiguration.id)
    return
  end

  me.GearBarOnUpdate()
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
    local gearSlotPosition = index + offset

    if gearSlotPosition <= table.getn(gearBarConfiguration.slots) then
      local row = rows[index]

      local slot = gearBarConfiguration.slots[gearSlotPosition]
      if slot == nil then return end -- no more slots available for that gearBar
      row.position = gearSlotPosition -- add actual gearSlot position
      row.slotIcon:SetTexture(slot.textureId)
      -- update preselected dropdown value for the slot
      UIDropDownMenu_SetSelectedValue(
        row.gearSlot, slot.slotId
      )
      -- update keybinding text
      if slot.keyBinding ~= nil then
        row.keyBindText:SetText(slot.keyBinding)
      else
        row.keyBindText:SetText(rggm.L["gear_bar_configuration_key_binding_not_set"])
      end

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
