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

-- luacheck: globals STANDARD_TEXT_FONT CreateFrame InCombatLockdown

--[[
  The gearBarMenu (GM_GearBarConfigurationMenu) module has some similarities to the gearBar (GM_GearBar) module.
  It is also heavily interacting with gearBarManager (GM_GearBarManager) module but unlike the gearBar module
  its purpose is to change and create values in the gearBarManager. It is used to give the user a UI to create, delete
  and modify new gearBars and slots.
]]--

--[[
  Module responsible to create a configuration menu for a single gearBar that is reused by all other gearBars
]]--

local mod = rggm
local me = {}

mod.gearBarConfigurationSubMenu = me

me.tag = "GearBarConfigurationSubMenu"

--[[
  Holds a references to all contentFrames that are created. One per gearBarId.
]]
local gearBarConfigurationContentFrames = {}
--[[
  The gearBarId of the gearBar that is currently getting configured
  (changes with switching menu to another gearBar in addon settings)
]]--
local gearBarConfiguration
--[[
  Option texts for checkbutton options
]]--
local lockGearBarMetaData = {
  "LockGearBar",
  rggm.L["window_lock_gear_bar"],
  rggm.L["window_lock_gear_bar_tooltip"]
}

local showKeyBindingsMetaData = {
  "ShowKeyBindings",
  rggm.L["show_keybindings"],
  rggm.L["show_keybindings_tooltip"]
}

local showCooldownsMetaData = {
  "ShowCooldowns",
  rggm.L["show_cooldowns"],
  rggm.L["show_cooldowns_tooltip"]
}

--[[
  The active configuration menu for a gearBar. This is the menu that is currently
  visible to the user. It is used to determine which gearBar is currently getting
  configured.
]]--
local currentActiveGearBarId

--[[
  Callback for when the menu entrypoint is clicked in the interface options. A callback
  like this exists for every separate gearBar that was created.

  @param {table} self
]]--
function me.GearBarConfigurationCategoryContainerOnCallback(self)
  currentActiveGearBarId = self.gearBarId
  -- update the current edited gearBar
  gearBarConfiguration = mod.gearBarManager.GetGearBar(currentActiveGearBarId)

  if me.GetCurrentContentFrame() == nil then
    me.AddGearBarContentFrame(me.BuildGearBarConfigurationSubMenu(self))
  end
end

--[[
  We want to store the created contentFrame for a gearBar so that we can reuse it.

  @param {table} contentFrame
    The contentFrame that should be stored
]]--
function me.AddGearBarContentFrame(contentFrame)
  mod.logger.LogDebug(me.tag, "Adding contentFrame for gearBarId: " .. currentActiveGearBarId)
  gearBarConfigurationContentFrames[currentActiveGearBarId] = contentFrame
end

--[[
  Remove the contentFrame for a gearBarId from the list of stored contentFrames

  @param {number} gearBarId
    The gearBarId for which to remove the contentFrame
]]--
function me.RemoveGearBarContentFrame(gearBarId)
  mod.logger.LogDebug(me.tag, "Removing contentFrame for gearBarId: " .. gearBarId)
  gearBarConfigurationContentFrames[gearBarId] = nil
end

--[[
  Get the currently active contentFrame for the gearBar that is currently getting configured

  @return {table | nil}
    The current active content frame or nil if none is active
]]--
function me.GetCurrentContentFrame()
  return gearBarConfigurationContentFrames[currentActiveGearBarId]
end

--[[
  Build the UI base for a specific gearBar with all its slots and configuration possibilities

  @param {table} parentFrame
    The menu entry in the interface options

  @return {table}
    The contentFrame for the gearBar
]]
function me.BuildGearBarConfigurationSubMenu(parentFrame)
  parentFrame.subMenuTitle = me.CreateConfigurationMenuTitle(parentFrame)
  me.CreateAddGearSlotButton(parentFrame)

  mod.uiHelper.BuildCheckButtonOption(
    parentFrame,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_OPT_LOCK_GEAR_BAR .. parentFrame.gearBarId,
    {"TOPLEFT", 20, -50},
    me.LockWindowGearBarOnShow,
    me.LockWindowGearBarOnClick,
    lockGearBarMetaData
  )

  mod.uiHelper.BuildCheckButtonOption(
    parentFrame,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_OPT_SHOW_KEY_BINDINGS .. parentFrame.gearBarId,
    {"TOPLEFT", 20, -110},
    me.ShowKeyBindingsOnShow,
    me.ShowKeyBindingsOnClick,
    showKeyBindingsMetaData
  )

  mod.uiHelper.BuildCheckButtonOption(
    parentFrame,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_OPT_SHOW_COOLDOWNS .. parentFrame.gearBarId,
    {"TOPLEFT", 20, -170},
    me.ShowCooldownsOnShow,
    me.ShowCooldownsOnClick,
    showCooldownsMetaData
  )

  mod.uiHelper.CreateSizeSlider(
    parentFrame,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_GEAR_SLOT_SIZE_SLIDER .. parentFrame.gearBarId,
    {"TOPLEFT", 300, -130},
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MIN,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MAX,
    mod.gearBarManager.GetGearSlotSize(parentFrame.gearBarId),
    rggm.L["gear_slot_size_slider_title"],
    rggm.L["gear_slot_size_slider_tooltip"],
    me.GearSlotSizeSliderOnValueChanged
  )

  mod.uiHelper.CreateSizeSlider(
    parentFrame,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_CHANGE_SLOT_SIZE_SLIDER .. parentFrame.gearBarId,
    {"TOPLEFT", 300, -205},
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MIN,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MAX,
    mod.gearBarManager.GetChangeSlotSize(parentFrame.gearBarId),
    rggm.L["change_slot_size_slider_title"],
    rggm.L["change_slot_size_slider_tooltip"],
    me.ChangeSlotSizeSliderOnValueChanged
  )

  me.CreateOrientationLabel(parentFrame)
  parentFrame.orientationDropdown =
    me.CreateOrientationDropdown(parentFrame, parentFrame.gearBarId)

  me.CreateChangeMenuDirectionLabel(parentFrame)
  parentFrame.changeMenuDirectionDropdown =
    me.CreateChangeMenuDirectionDropdown(parentFrame, parentFrame.gearBarId)

  local slotsList = me.CreateGearBarConfigurationSlotsList(parentFrame)
  me.GearBarConfigurationSlotsListOnUpdate(slotsList)

  return parentFrame
end

--[[
  @param {table} contentFrame

  @return {table}
    The created fontString
]]--
function me.CreateConfigurationMenuTitle(contentFrame)
  local titleFontString = contentFrame:CreateFontString(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SUB_MENU_TITLE, "OVERLAY", "GameFontNormalLarge")
  titleFontString:SetPoint("TOPLEFT", 16, -16)
  mod.uiHelper.SetColor(titleFontString, RGGM_CONSTANTS.COLOR.TITLE_GOLD)

  if RGGM_ENVIRONMENT.DEBUG then
    titleFontString:SetText(gearBarConfiguration.displayName .. "_" .. gearBarConfiguration.id)
  else
    titleFontString:SetText(gearBarConfiguration.displayName)
  end

  return titleFontString
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
  button:SetPoint("TOPLEFT", 20, -260)
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
  if InCombatLockdown() then
    -- Adding a slot creates a SecureActionButton (SetAttribute), which is blocked in combat.
    mod.logger.PrintUserError(rggm.L["gear_bar_configuration_add_gearslot_combat"])

    return
  end

  local gearBar = mod.gearBarManager.GetGearBar(gearBarConfiguration.id)

  if #gearBar.slots >= RGGM_CONSTANTS.MAX_GEAR_BAR_SLOTS then
    mod.logger.PrintUserError(rggm.L["gear_bar_max_amount_of_gear_slots_reached"])

    return
  end

  if gearBar == nil then
    mod.logger.LogError(me.tag, "Failed to find gearBar with id: " .. gearBarConfiguration.id)

    return
  end

  if not mod.gearBarManager.AddGearSlot(gearBarConfiguration.id) then
    mod.logger.LogError(me.tag, "Failed to add new gearSlot to gearBar with id: " .. gearBarConfiguration.id)

    return
  end

  me.GearBarConfigurationSlotsListOnUpdate()
end

--[[
  OnShow callback for checkbuttons - window lock gearBar

  @param {table} self
]]--
function me.LockWindowGearBarOnShow(self)
  if mod.gearBarManager.IsGearBarLocked(self:GetParent().gearBarId) then
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
  local gearBarId = self:GetParent().gearBarId

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
  if mod.gearBarManager.IsShowKeyBindingsEnabled(self:GetParent().gearBarId) then
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
  local gearBarId = self:GetParent().gearBarId

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
  if mod.gearBarManager.IsShowCooldownsEnabled(self:GetParent().gearBarId) then
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
  local gearBarId = self:GetParent().gearBarId

  if enabled then
    mod.gearBarManager.EnableShowCooldowns(gearBarId)
  else
    mod.gearBarManager.DisableShowCooldowns(gearBarId)
  end
end

--[[
  OnValueChanged callback for the gearSlot size slider

  @param {table} self
  @param {number} value
]]--
function me.GearSlotSizeSliderOnValueChanged(self, value)
  local gearBarId = self:GetParent().gearBarId

  mod.gearBarManager.SetGearSlotSize(gearBarId, value)
end

--[[
  OnValueChanged callback for the changeSlot size slider

  @param {table} self
  @param {number} value
]]--
function me.ChangeSlotSizeSliderOnValueChanged(self, value)
  local gearBarId = self:GetParent().gearBarId

  mod.gearBarManager.SetChangeSlotSize(gearBarId, value)
end

--[[
  Create a label for the orientation dropdown

  @param {table} parentFrame
]]--
function me.CreateOrientationLabel(parentFrame)
  local orientationLabel = parentFrame:CreateFontString(nil, "OVERLAY")
  -- clears the 230px wide checkbox descriptions in the left column (they end at x ~254)
  orientationLabel:SetPoint("TOPLEFT", 260, -52)
  orientationLabel:SetFont(STANDARD_TEXT_FONT, 15)
  mod.uiHelper.SetColor(orientationLabel, RGGM_CONSTANTS.COLOR.BODY)
  orientationLabel:SetText(rggm.L["gearbar_orientation"])
end

--[[
  Create a dropdown that allows switching the orientation of the gearBar between
  horizontal and vertical

  @param {table} parentFrame
  @param {number} gearBarId
    The id of the gearBar this dropdown configures

  @return {table}
    The created dropdown menu
]]--
function me.CreateOrientationDropdown(parentFrame, gearBarId)
  local orientationDropdownMenu = mod.uiHelper.CreateSettingsDropdown(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_ORIENTATION_DROPDOWN .. gearBarId,
    parentFrame,
    {"TOPLEFT", 260, -72},
    150,
    function(_, rootDescription)
      me.BuildOrientationRadios(rootDescription, gearBarId, parentFrame)
    end
  )

  orientationDropdownMenu.gearBarId = gearBarId
  -- generate once so the button shows the current selection before the menu was ever opened
  orientationDropdownMenu:GenerateMenu()

  --[[ hooked instead of set so the template's hover state visuals stay intact ]]--
  orientationDropdownMenu:HookScript("OnEnter", function()
    mod.tooltip.BuildTooltipForOption(rggm.L["gearbar_orientation"], rggm.L["gearbar_orientation_tooltip"])
  end)
  orientationDropdownMenu:HookScript("OnLeave", function()
    _G[RGGM_CONSTANTS.ELEMENT_TOOLTIP]:Hide()
  end)

  return orientationDropdownMenu
end

--[[
  Fill the orientation dropdown root description with a radio entry per orientation

  @param {table} rootDescription
  @param {number} gearBarId
    The id of the gearBar the dropdown configures
  @param {table} contentFrame
    The gearBar configuration content frame holding the dropdown references
]]--
function me.BuildOrientationRadios(rootDescription, gearBarId, contentFrame)
  local orientations = {
    { value = RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_HORIZONTAL, text = rggm.L["orientation_horizontal"] },
    { value = RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_VERTICAL, text = rggm.L["orientation_vertical"] }
  }

  for _, orientation in ipairs(orientations) do
    rootDescription:CreateRadio(
      orientation.text,
      function(value) return mod.gearBarManager.GetGearBarOrientation(gearBarId) == value end,
      function(value)
        mod.gearBarManager.SetGearBarOrientation(gearBarId, value)
        -- the available change menu directions depend on the orientation - refresh that dropdown so it
        -- shows the correct entries and the (possibly normalized) selected direction
        me.RefreshChangeMenuDirectionDropdown(contentFrame)
      end,
      orientation.value
    )
  end
end

--[[
  Create a label for the change menu direction dropdown

  @param {table} parentFrame
]]--
function me.CreateChangeMenuDirectionLabel(parentFrame)
  local changeMenuDirectionLabel = parentFrame:CreateFontString(nil, "OVERLAY")
  changeMenuDirectionLabel:SetPoint("TOPLEFT", 420, -52)
  changeMenuDirectionLabel:SetFont(STANDARD_TEXT_FONT, 15)
  mod.uiHelper.SetColor(changeMenuDirectionLabel, RGGM_CONSTANTS.COLOR.BODY)
  changeMenuDirectionLabel:SetText(rggm.L["change_menu_direction"])
end

--[[
  Create a dropdown that allows switching the direction in which the change menu opens
  relative to the hovered gearSlot

  @param {table} parentFrame
  @param {number} gearBarId
    The id of the gearBar this dropdown configures

  @return {table}
    The created dropdown menu
]]--
function me.CreateChangeMenuDirectionDropdown(parentFrame, gearBarId)
  local changeMenuDirectionDropdownMenu = mod.uiHelper.CreateSettingsDropdown(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_CHANGE_MENU_DIRECTION_DROPDOWN .. gearBarId,
    parentFrame,
    {"TOPLEFT", 420, -72},
    150,
    function(_, rootDescription)
      me.BuildChangeMenuDirectionRadios(rootDescription, gearBarId)
    end
  )

  changeMenuDirectionDropdownMenu.gearBarId = gearBarId
  -- generate once so the button shows the current selection before the menu was ever opened
  changeMenuDirectionDropdownMenu:GenerateMenu()

  --[[ hooked instead of set so the template's hover state visuals stay intact ]]--
  changeMenuDirectionDropdownMenu:HookScript("OnEnter", function()
    mod.tooltip.BuildTooltipForOption(rggm.L["change_menu_direction"], rggm.L["change_menu_direction_tooltip"])
  end)
  changeMenuDirectionDropdownMenu:HookScript("OnLeave", function()
    _G[RGGM_CONSTANTS.ELEMENT_TOOLTIP]:Hide()
  end)

  return changeMenuDirectionDropdownMenu
end

--[[
  Fill the change menu direction dropdown root description with a radio entry per available
  direction. The available entries depend on the gearBar orientation - horizontal gearBars
  offer up/down, vertical gearBars offer left/right.

  @param {table} rootDescription
  @param {number} gearBarId
    The id of the gearBar the dropdown configures
]]--
function me.BuildChangeMenuDirectionRadios(rootDescription, gearBarId)
  local directions

  if mod.gearBarManager.GetGearBarOrientation(gearBarId) == RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_VERTICAL then
    directions = {
      RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_RIGHT,
      RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_LEFT
    }
  else
    directions = {
      RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_UP,
      RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_DOWN
    }
  end

  for _, direction in ipairs(directions) do
    rootDescription:CreateRadio(
      rggm.L[me.GetChangeMenuDirectionLocaleKey(direction)],
      function(value) return mod.gearBarManager.GetChangeMenuDirection(gearBarId) == value end,
      function(value) mod.gearBarManager.SetChangeMenuDirection(gearBarId, value) end,
      direction
    )
  end
end

--[[
  Map a ChangeMenu direction value to its localization key

  @param {number} changeMenuDirection

  @return {string}
]]--
function me.GetChangeMenuDirectionLocaleKey(changeMenuDirection)
  if changeMenuDirection == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_DOWN then
    return "change_menu_direction_down"
  elseif changeMenuDirection == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_LEFT then
    return "change_menu_direction_left"
  elseif changeMenuDirection == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_RIGHT then
    return "change_menu_direction_right"
  end

  return "change_menu_direction_up"
end

--[[
  Refresh the change menu direction dropdown after the orientation changed. Regenerating rebuilds
  the entries for the new orientation and updates the shown selection to the (possibly normalized)
  stored direction.

  @param {table} contentFrame
    The gearBar configuration content frame holding the dropdown reference
]]--
function me.RefreshChangeMenuDirectionDropdown(contentFrame)
  local dropdown = contentFrame.changeMenuDirectionDropdown

  if dropdown == nil then return end

  dropdown:GenerateMenu()
end

--[[
  @param {table} parentFrame

  @return {table}
    The created list container
]]--
function me.CreateGearBarConfigurationSlotsList(parentFrame)
  local listContainer = mod.uiHelper.CreateScrollList(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_SCROLL_FRAME,
    parentFrame,
    {"TOPLEFT", 20, -290},
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_WIDTH,
    RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_ROW_HEIGHT
    * RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS
  )

  --[[
    Store reference of the list container for all slot configurations
    on gearBar configuration container
  ]]--
  parentFrame.slotsList = listContainer
  listContainer.rows = {}

  return listContainer
end

--[[
  @param {table} contentFrame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateGearBarConfigurationSlotsListRowFrame(contentFrame, position)
  local rowOffset = (position - 1) * RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_ROW_HEIGHT * -1
  local row = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_ROW_FRAME .. position,
    contentFrame,
    "BackdropTemplate"
  )
  row:SetHeight(RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, rowOffset)
  row:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, rowOffset)
  row:SetBackdrop({
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

  if math.fmod(position, 2) == 0 then
    row:SetBackdropColor(0.37, 0.37, 0.37, .3)
  else
    row:SetBackdropColor(.25, .25, .25, .9)
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
  local iconHolder = CreateFrame("Frame", nil, row, "BackdropTemplate")
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
  local gearSlotDropdownMenu = mod.uiHelper.CreateSettingsDropdown(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_GEAR_SLOT_DROPDOWN .. position,
    row,
    {"LEFT", 50, 0},
    140,
    me.InitializeGearSlotDropdownMenu
  )

  gearSlotDropdownMenu.position = position

  return gearSlotDropdownMenu
end

--[[
  Menu generator for a slot row dropdown - fills the root description with a radio entry
  per available gearSlot

  @param {table} dropdown
    The dropdown the menu is generated for
  @param {table} rootDescription
]]--
function me.InitializeGearSlotDropdownMenu(dropdown, rootDescription)
  local gearSlots = mod.gearManager.GetGearSlots()

  for _, gearSlot in pairs(gearSlots) do
    rootDescription:CreateRadio(
      rggm.L[gearSlot.name],
      function(slotId) return me.IsGearSlotSelected(dropdown, slotId) end,
      function(slotId) me.OnGearSlotSelect(dropdown, slotId) end,
      gearSlot.slotId
    )
  end
end

--[[
  Whether the passed slotId is the one configured for the row the dropdown belongs to

  @param {table} dropdown
  @param {number} slotId

  @return {boolean}
]]--
function me.IsGearSlotSelected(dropdown, slotId)
  local gearSlotMetaData = mod.gearBarManager.GetGearSlot(gearBarConfiguration.id, dropdown:GetParent().position)

  return gearSlotMetaData ~= nil and gearSlotMetaData.slotId == slotId
end

--[[
  Callback for when a gearSlot is selected in a slot row dropdown

  @param {table} dropdown
  @param {number} slotId
    The slotId of the selected gearSlot
]]--
function me.OnGearSlotSelect(dropdown, slotId)
  -- the row position was updated to the actual gearSlot position (including scroll offset)
  local position = dropdown:GetParent().position
  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slotId)
  local currentMetaData = mod.gearBarManager.GetGearSlot(gearBarConfiguration.id, position)

  --[[
    Preserve keyBinding text if one is present. Note: this is only the text that is displayed. The keyBind itself
    is automatically preserved because the gearSlot frame is not changing. It does not matter to the keyBind
    what slotId the gearSlot has. It will simply "click" the gearSlot
  ]]--
  if currentMetaData ~= nil and currentMetaData.keyBinding ~= nil and currentMetaData ~= "" then
    gearSlotMetaData.keyBinding = currentMetaData.keyBinding
  end

  mod.gearBarManager.UpdateGearSlot(gearBarConfiguration.id, position, gearSlotMetaData)
  me.GearBarConfigurationSlotsListOnUpdate()
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
  button:SetScript("OnClick", function(self)
    mod.keyBind.SetKeyBindingForGearSlot(gearBarConfiguration.id, self:GetParent().position)
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

  me.GearBarConfigurationSlotsListOnUpdate()
end

--[[
  Update the slots list rows to reflect the configured gearSlots. Rows are created
  lazily - one per gearSlot - and surplus rows are hidden.

  @param {table} optional listContainerReference
    The list container to update; defaults to the one of the currently active gearBar
]]--
function me.GearBarConfigurationSlotsListOnUpdate(listContainerReference)
  local listContainer = listContainerReference or me.GetCurrentContentFrame().slotsList
  local rows = listContainer.rows
  local slots = gearBarConfiguration.slots

  for index = 1, math.max(#slots, #rows) do
    if index <= #slots and rows[index] == nil then
      rows[index] = me.CreateGearBarConfigurationSlotsListRowFrame(listContainer.content, index)
    end

    local row = rows[index]

    if index <= #slots then
      local slot = slots[index]

      row.position = index -- rows are never re-purposed - position always matches the gearSlot position
      row.slotIcon:SetTexture(slot.textureId)
      -- regenerate so the dropdown text reflects the slot configured for this row
      row.gearSlot:GenerateMenu()
      -- update keybinding text
      if slot.keyBinding ~= nil then
        row.keyBindText:SetText(slot.keyBinding)
      else
        row.keyBindText:SetText(rggm.L["gear_bar_configuration_key_binding_not_set"])
      end

      row:Show()
    else
      row:Hide()
    end
  end

  listContainer.content:SetHeight(
    math.max(#slots, RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS)
    * RGGM_CONSTANTS.GEAR_BAR_CONFIGURATION_SLOTS_LIST_ROW_HEIGHT
  )
end

--[[
  Register a script with the currently active content frame. This is used for capturing keybindings.

  @param {string} event
  @param {function} callback
]]--
function me.RegisterScriptWithContentFrame(event, callback)
  local activeContentFrame = gearBarConfigurationContentFrames[currentActiveGearBarId]

  if activeContentFrame ~= nil then
    activeContentFrame:SetScript(event, callback)
  else
    mod.logger.LogError(me.tag, "Failed to register script with content frame - content frame is nil")
  end
end

--[[
  Unregister a script with the currently active content frame. This is used for capturing keybindings.

  @param {string} event
]]--
function me.UnregisterScriptWithContentFrame(event)
  local activeContentFrame = gearBarConfigurationContentFrames[currentActiveGearBarId]

  if activeContentFrame ~= nil then
    activeContentFrame:SetScript(event, nil)
  else
    mod.logger.LogError(me.tag, "Failed to unregister script with content frame - content frame is nil")
  end
end

--[[
  Function for updating everything related to the configuration menu. Such as when
  a slot was removed or added
]]--
function me.UpdateGearBarConfigurationMenu()
  me.GearBarConfigurationSlotsListOnUpdate()
end
