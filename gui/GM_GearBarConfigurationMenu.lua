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

-- luacheck: globals STANDARD_TEXT_FONT CreateFrame StaticPopupDialogs StaticPopup_Show
-- luacheck: globals FauxScrollFrame_Update FauxScrollFrame_GetOffset

--[[
  The gearBarMenu (GM_GearBarConfigurationMenu) module has some similarities to the gearBar (GM_GearBar) module.
  It is also heavily interacting with gearBarManager (GM_GearBarManager) module but unlike the gearBar module
  its purpose is to change and create values in the gearBarManager. It is used to give the user a UI to create, delete
  and modify new gearBars and slots.
]]--

--[[
  Module for responsible for creating new gearBars and the submenus needed to configure them
]]--

local mod = rggm
local me = {}

mod.gearBarConfigurationMenu = me

me.tag = "GearBarConfigurationMenu"

--[[
  Reference to the scrollable gearBar list
]]--
local gearBarList

-- track whether the menu was already built
local builtMenu = false

--[[
  Holds the gearBarId to delete after clicking on the delete button. The static popup
  to confirm the deletion will use this to delete the propere url if the user confirms
  the deletion
]]
local deleteGearBarId;

--[[
  Popup dialog for choosing a profile name
]]--
StaticPopupDialogs["RGGM_CHOOSE_GEAR_BAR_NAME"] = {
  text = rggm.L["gear_bar_choose_name"],
  button1 = rggm.L["gear_bar_choose_name_accept_button"],
  button2 = rggm.L["gear_bar_choose_name_cancel_button"],
  OnShow = function(self)
    local editBox = self:GetParent().editBox
    local button1 = self:GetParent().button1

    if editBox ~= nil and button1 ~= nil then
      button1:Disable()
      editBox:SetText("") -- reset text to empty
    end
  end,
  OnAccept = function(self)
    me.CreateNewGearBar(self.editBox:GetText())
    me.GearBarListOnUpdate(gearBarList)
  end,
  EditBoxOnTextChanged = function(self)
    local editBox = self:GetParent().editBox
    local button1 = self:GetParent().button1

    if editBox ~= nil and button1 ~= nil then
      if string.len(editBox:GetText()) > 0 then
        button1:Enable()
      else
        button1:Disable()
      end
    end
  end,
  timeout = 0,
  whileDead = true,
  preferredIndex = 3,
  hasEditBox = true,
  maxLetters = RGGM_CONSTANTS.GEAR_BAR_NAME_MAX_LENGTH
}

--[[
  Popup dialog for confirming the deletion of a gearBar
]]--
StaticPopupDialogs["RGGM_GEAR_BAR_CONFIRM_DELETE"] = {
  text = rggm.L["gear_bar_confirm_delete"],
  button1 = rggm.L["gear_bar_confirm_delete_yes_button"],
  button2 = rggm.L["gear_bar_confirm_delete_no_button"],
  OnAccept = function()
    if deleteGearBarId then
      mod.gearBarManager.RemoveGearBar(deleteGearBarId)
      mod.gearBarStorage.RemoveGearBar(deleteGearBarId)
      me.GearBarListOnUpdate(gearBarList)
      mod.addonConfiguration.InterfaceOptionsRemoveCategory(deleteGearBarId)
      mod.gearBarConfigurationSubMenu.RemoveGearBarContentFrame(deleteGearBarId)

      deleteGearBarId = nil
    end
  end,
  timeout = 0,
  whileDead = true,
  preferredIndex = 3
}

--[[
  Build the ui for the general menu. The place where new gearBars are created.

  @param {table} parentFrame
    The addon configuration frame to attach to
]]--
function me.BuildUi(parentFrame)
  if builtMenu then return end

  local gearBarConfigurationContentFrame = CreateFrame(
    "Frame", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_MENU, parentFrame)
  gearBarConfigurationContentFrame:SetWidth(RGGM_CONSTANTS.INTERFACE_PANEL_CONTENT_FRAME_WIDTH)
  gearBarConfigurationContentFrame:SetHeight(RGGM_CONSTANTS.INTERFACE_PANEL_CONTENT_FRAME_HEIGHT)
  gearBarConfigurationContentFrame:SetPoint("TOPLEFT", parentFrame, 5, -7)

  me.CreateConfigurationMenuTitle(gearBarConfigurationContentFrame)
  me.CreateNewGearBarButton(gearBarConfigurationContentFrame)
  gearBarList = me.CreateGearBarList(gearBarConfigurationContentFrame)
  me.GearBarListOnUpdate(gearBarList)

  builtMenu = true
end

--[[
  @param {table} contentFrame
]]--
function me.CreateConfigurationMenuTitle(contentFrame)
  local titleFontString = contentFrame:CreateFontString(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_MENU_TITLE, "OVERLAY")
  titleFontString:SetFont(STANDARD_TEXT_FONT, 20)
  titleFontString:SetPoint("TOP", 0, -20)
  titleFontString:SetSize(contentFrame:GetWidth(), 20)
  titleFontString:SetText(rggm.L["gear_bar_configuration_category_name"])
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
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_CREATE_BUTTON,
    gearBarFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_add_gearbar"])
  button:SetPoint("TOPLEFT", 20, -80)
  button:SetScript('OnClick', function()
    StaticPopup_Show("RGGM_CHOOSE_GEAR_BAR_NAME")
  end)

  local buttonFontString = button:GetFontString()

  button:SetWidth(
    buttonFontString:GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Create a new gearBar with the gearBarManager - then adds a new interface option
  for the created gearBar

  @param {string} name
]]--
function me.CreateNewGearBar(name)
  if #mod.gearBarManager.GetGearBars() >= RGGM_CONSTANTS.MAX_GEAR_BARS then
    mod.logger.PrintUserError(rggm.L["gear_bar_max_amount_of_gear_bars_reached"])
    return
  end

  local gearBar = mod.gearBarManager.AddGearBar(name, true)
  -- build visual gearBar representation
  mod.gearBar.BuildGearBar(gearBar)

  local category, menu = mod.addonConfiguration.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_SUB_CONFIG_FRAME .. gearBar.id,
    mod.addonConfiguration.GetGearBarSubCategory(),
    gearBar.displayName,
    mod.gearBarConfigurationSubMenu.GearBarConfigurationCategoryContainerOnCallback
  )
  menu.gearBarId = gearBar.id
  category.gearBarId = gearBar.id


  mod.gearBar.UpdateGearBarVisual(gearBar) -- update visual representation of the newly created gearBar
end

--[[
  Load all configured bar menus in Interfaces Options. This will create an entry for
  each gearBar that is configured
]]--
function me.LoadConfiguredGearBars()
  local gearBars = mod.gearBarManager.GetGearBars()

  for i = 1, #gearBars do
    mod.logger.LogDebug(me.tag, "Loading gearBar with id: " .. gearBars[i].id .. " from configuration")

    local category, menu = mod.addonConfiguration.BuildCategory(
      RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_SUB_CONFIG_FRAME .. gearBars[i].id,
      mod.addonConfiguration.GetGearBarSubCategory(),
      gearBars[i].displayName,
      mod.gearBarConfigurationSubMenu.GearBarConfigurationCategoryContainerOnCallback
    )
    menu.gearBarId = gearBars[i].id
    category.gearBarId = gearBars[i].id
  end
end

--[[
  @param {table} parentFrame

  @return {table}
    The created scrollFrame
]]--
function me.CreateGearBarList(parentFrame)
  local scrollFrame = CreateFrame(
    "ScrollFrame",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_LIST,
    parentFrame,
    "FauxScrollFrameTemplate"
  )

  scrollFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_LIST_WIDTH)
  scrollFrame:SetHeight(
    RGGM_CONSTANTS.GEAR_BAR_LIST_ROW_HEIGHT
    * RGGM_CONSTANTS.GEAR_BAR_LIST_MAX_ROWS
  )
  scrollFrame:SetPoint("TOPLEFT", 20, -120)
  scrollFrame:EnableMouseWheel(true)

  scrollFrame:SetScript("OnVerticalScroll", me.GearBarListOnVerticalScroll)

  parentFrame.rows = {}

  for i = 1, RGGM_CONSTANTS.GEAR_BAR_LIST_MAX_ROWS do
    table.insert(parentFrame.rows, me.CreateGearBarListRowFrame(scrollFrame, i))
  end

  return scrollFrame
end

--[[
  OnVerticalScroll callback for scrollable slots list

  @param {table} self
  @param {number} offset
]]--
function me.GearBarListOnVerticalScroll(self, offset)
  self.ScrollBar:SetValue(offset)
  self.offset = math.floor(offset / RGGM_CONSTANTS.GEAR_BAR_LIST_ROW_HEIGHT + 0.5)
  me.GearBarListOnUpdate(self)
end

--[[
  @param {table} frame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateGearBarListRowFrame(frame, position)
  local row = CreateFrame("Button",  RGGM_CONSTANTS.ELEMENT_GEAR_BAR_ROW_FRAME .. position, frame, "BackdropTemplate")
  row:SetSize(frame:GetWidth(), RGGM_CONSTANTS.GEAR_BAR_LIST_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", frame, 0, (position -1) * RGGM_CONSTANTS.GEAR_BAR_LIST_ROW_HEIGHT * -1)
  row:SetBackdrop({
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

  if math.fmod(position, 2) == 0 then
    row:SetBackdropColor(0.37, 0.37, 0.37, .3)
  else
    row:SetBackdropColor(.25, .25, .25, .9)
  end

  row.gearBarName = me.CreateGearBarNameText(row)
  row.removeGearBarButton = me.CreateRemoveGearBarButton(row, row.gearBarName, position)

  return row
end

--[[
  Create a fontstring for the gearbar name

  @param {table} row

  @return {table}
    The created fontstring
]]--
function me.CreateGearBarNameText(row)
  local gearBarNameFontString = row:CreateFontString(RGGM_CONSTANTS.ELEMENT_GEAR_BAR_NAME_TEXT, "OVERLAY")
  gearBarNameFontString:SetFont(STANDARD_TEXT_FONT, 15)
  gearBarNameFontString:SetWidth(RGGM_CONSTANTS.GEAR_BAR_LIST_NAME_TEXT_WIDTH)
  gearBarNameFontString:SetPoint(
    "TOPLEFT",
    row,
    "TOPLEFT",
    20,
    -20
  )
  gearBarNameFontString:SetJustifyH("LEFT");
  gearBarNameFontString:SetTextColor(.95, .95, .95)

  return gearBarNameFontString
end

--[[
  @param {table} row
  @param {table} parentFrame
  @param {number} position

  @return {table}
    The created button
]]--
function me.CreateRemoveGearBarButton(row, parentFrame, position)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_REMOVE_BUTTON .. position,
    row,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_remove_button"])
  button:SetPoint(
    "LEFT",
    parentFrame,
    "RIGHT",
    0,
    0
  )
  button:SetScript("OnClick", function(self)
    deleteGearBarId = self.id

    StaticPopup_Show("RGGM_GEAR_BAR_CONFIRM_DELETE")
  end)

  button:SetWidth(
    button:GetFontString():GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Update a scrollable list holding configuration frames for gearBar slots

  @param {table} scrollFrame
]]--
function me.GearBarListOnUpdate(scrollFrame)
  local rows = scrollFrame:GetParent().rows
  local gearBars = mod.gearBarManager.GetGearBars()
  local maxValue = #gearBars or 0

  if maxValue <= RGGM_CONSTANTS.GEAR_BAR_LIST_MAX_ROWS then
    maxValue = RGGM_CONSTANTS.GEAR_BAR_LIST_MAX_ROWS + 1
  end
  -- Note: maxValue needs to be at least max_rows + 1
  FauxScrollFrame_Update(
    scrollFrame,
    maxValue,
    RGGM_CONSTANTS.GEAR_BAR_LIST_MAX_ROWS,
    RGGM_CONSTANTS.GEAR_BAR_LIST_ROW_HEIGHT
  )

  local offset = FauxScrollFrame_GetOffset(scrollFrame)
  for index = 1, RGGM_CONSTANTS.GEAR_BAR_LIST_MAX_ROWS do
    local rowPosition = index + offset

    if rowPosition <= #gearBars then
      local row = rows[index]
      row.gearBarName:SetText(gearBars[rowPosition].displayName)
      row.removeGearBarButton.id = gearBars[rowPosition].id
      row:Show()
    else
      rows[index]:Hide()
    end
  end
end
