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

-- luacheck: globals STANDARD_TEXT_FONT CreateFrame StaticPopupDialogs StaticPopup_Show

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

-- track whether the menu was already built
local builtMenu = false

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
  Build the ui for the general menu. The place where new gearBars are created.

  @param {table} frame
    The addon configuration frame to attach to
]]--
function me.BuildUi(frame)
  if builtMenu then return end

  local titleFontString = frame:CreateFontString(RGGM_CONSTANTS.ELEMENT_GENERAL_TITLE, "OVERLAY")
  titleFontString:SetFont(STANDARD_TEXT_FONT, 20)
  titleFontString:SetPoint("TOP", 0, -20)
  titleFontString:SetSize(frame:GetWidth(), 20)
  titleFontString:SetText("GEARBARTITLE TODO")

  me.CreateNewGearBarButton(frame)

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
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIGURATION_ADD_GEAR_BAR,
    gearBarFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_add_gearbar"])
  button:SetPoint("TOPLEFT", 10, -100)
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
  local gearBar = mod.gearBarManager.AddNewGearBar(name)
  -- build visual gearBar representation
  mod.gearBar.BuildGearBar(gearBar)

  local builtCategory = mod.addonConfiguration.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_SUB_CONFIG_FRAME .. gearBar.id,
    _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_CONFIG_FRAME],
    gearBar.displayName .. gearBar.id, -- TODO id only development
    mod.gearBarConfigurationSubMenu.GearBarConfigurationCategoryContainerOnCallback
  )

  builtCategory.gearBarId = gearBar.id

  mod.gearBar.UpdateGearBar(gearBar) -- update visual representation of the newly created gearBar
  mod.addonConfiguration.UpdateAddonPanel()
end

--[[
  Load all configured bar menus in Interfaces Options. This will create an entry for
  each gearBar that is configured
]]--
function me.LoadConfiguredGearBars()
  local gearBars = mod.gearBarManager.GetGearBars()

  for i = 1, #gearBars do
    mod.logger.LogDebug(me.tag, "Loading gearBar with id: " .. gearBars[i].id .. " from configuration")

    local builtCategory = mod.addonConfiguration.BuildCategory(
      RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_SUB_CONFIG_FRAME .. gearBars[i].id,
      _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_CONFIG_FRAME],
      gearBars[i].displayName .. gearBars[i].id, -- TODO id only development
      mod.gearBarConfigurationSubMenu.GearBarConfigurationCategoryContainerOnCallback
    )

    builtCategory.gearBarId = gearBars[i].id
  end
end
