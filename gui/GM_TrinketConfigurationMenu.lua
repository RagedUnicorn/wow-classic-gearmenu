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
mod.trinketConfigurationMenu = me

me.tag = "TrinketConfigurationMenu"

--[[
  Option texts for checkbutton options
]]--
local enableTrinketMenuMetaData = {
  RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_OPT .. "EnableTrinketMenu",
  rggm.L["enable_trinket_menu"],
  rggm.L["enable_trinket_menu_tooltip"]
}

local lockWindowTrinketMenuMetaData = {
  RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_OPT .. "LockTrinketMenu",
  rggm.L["window_lock_trinket_menu"],
  rggm.L["window_lock_trinket_menu_tooltip"]
}

local enableShowCooldownsMetaData = {
  RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_OPT .. "ShowCooldowns",
  rggm.L["shoow_cooldowns_trinket_menu"],
  rggm.L["shoow_cooldowns_trinket_menu_tooltip"]
}

-- track whether the menu was already built
local builtMenu = false

--[[
  Build the ui for the general menu

  @param {table} parentFrame
    The addon configuration frame to attach to
]]--
function me.BuildUi(parentFrame)
  if builtMenu then return end

  local trinketMenuContentFrame = CreateFrame(
    "Frame", RGGM_CONSTANTS.ELEMENT_TRINKET_MENU, parentFrame)
  trinketMenuContentFrame:SetWidth(RGGM_CONSTANTS.INTERFACE_PANEL_CONTENT_FRAME_WIDTH)
  trinketMenuContentFrame:SetHeight(RGGM_CONSTANTS.INTERFACE_PANEL_CONTENT_FRAME_HEIGHT)
  trinketMenuContentFrame:SetPoint("TOPLEFT", parentFrame, 5, -7)

  me.CreateTrinketMenuTitle(trinketMenuContentFrame)

  mod.uiHelper.BuildCheckButtonOption(
    trinketMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_OPT_ENABLE_MENU,
    {"TOPLEFT", 20, -80},
    me.EnableTrinketMenuOnShow,
    me.EnableTrinketMenuOnClick,
    enableTrinketMenuMetaData
  )

  mod.uiHelper.BuildCheckButtonOption(
    trinketMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_OPT_LOCK_MENU,
    {"TOPLEFT", 20, -110},
    me.LockTrinketMenuOnShow,
    me.LockTrinketMenuOnClick,
    lockWindowTrinketMenuMetaData
  )

  mod.uiHelper.BuildCheckButtonOption(
    trinketMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_SHOW_COOLDOWNS,
    {"TOPLEFT", 20, -140},
    me.ShowCooldownsOnShow,
    me.ShowCooldownsOnClick,
    enableShowCooldownsMetaData
  )

  mod.uiHelper.CreateSizeSlider(
    trinketMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_COLUMN_AMOUNT_SLIDER,
    {"TOPLEFT", 20, -190},
    RGGM_CONSTANTS.TRINKET_MENU_COLUMN_AMOUNT_SLIDER_MIN,
    RGGM_CONSTANTS.TRINKET_MENU_COLUMN_AMOUNT_SLIDER_MAX,
    RGGM_CONSTANTS.TRINKET_MENU_DEFAULT_COLUMN_AMOUNT,
    rggm.L["trinket_menu_column_amount_slider_title"],
    rggm.L["trinket_menu_column_amount_slider_tooltip"],
    me.TrinketMenuColumnAmountSliderOnShow,
    me.TrinketMenuColumnAmountSliderOnValueChanged
  )

  mod.uiHelper.CreateSizeSlider(
    trinketMenuContentFrame,
    RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_SLOT_SIZE_SLIDER,
    {"TOPLEFT", 20, -250},
    RGGM_CONSTANTS.TRINKET_MENU_SLOT_SIZE_SLIDER_MIN,
    RGGM_CONSTANTS.TRINKET_MENU_SLOT_SIZE_SLIDER_MAX,
    RGGM_CONSTANTS.TRINKET_MENU_DEFAULT_SLOT_SIZE,
    rggm.L["trinket_menu_slot_size_slider_title"],
    rggm.L["trinket_menu_slot_size_slider_tooltip"],
    me.TrinketMenuSlotSizeSliderOnShow,
    me.TrinketMenuSlotSizeSliderOnValueChanged
  )

  builtMenu = true
end

--[[
  @param {table} contentFrame
]]--
function me.CreateTrinketMenuTitle(contentFrame)
  local titleFontString = contentFrame:CreateFontString(RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_TITLE, "OVERLAY")
  titleFontString:SetFont(STANDARD_TEXT_FONT, 20)
  titleFontString:SetPoint("TOP", 0, -20)
  titleFontString:SetSize(contentFrame:GetWidth(), 20)
  titleFontString:SetText(rggm.L["trinket_menu_title"])
end

--[[
  OnShow callback for checkbuttons - enable trinket menu

  @param {table} self
]]--
function me.EnableTrinketMenuOnShow(self)
  if mod.configuration.IsTrinketMenuEnabled() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - enable trinket menu

  @param {table} self
]]--
function me.EnableTrinketMenuOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.EnableTrinketMenu()
  else
    mod.configuration.DisableTrinketMenu()
  end
end

--[[
  OnShow callback for checkbuttons - lock trinket menu

  @param {table} self
]]--
function me.LockTrinketMenuOnShow(self)
  if mod.configuration.IsTrinketMenuFrameLocked() then
    self:SetChecked(true)
  else
    self:SetChecked(false)
  end
end

--[[
  OnClick callback for checkbuttons - lock trinket menu

  @param {table} self
]]--
function me.LockTrinketMenuOnClick(self)
  local enabled = self:GetChecked()

  if enabled then
    mod.configuration.LockTrinketMenuFrame()
  else
    mod.configuration.UnlockTrinketMenuFrame()
  end
end

--[[
  OnShow callback for checkbuttons - show cooldowns

  @param {table} self
]]--
function me.ShowCooldownsOnShow(self)
  if mod.configuration.IsShowCooldownsEnabled() then
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

  if enabled then
    mod.configuration.EnableShowCooldowns()
  else
    mod.configuration.DisableShowCooldowns()
  end
end

--[[
  OnValueChanged callback for the trinketMenu column slider

  @param {table} self
  @param {number} value
]]--
function me.TrinketMenuColumnAmountSliderOnValueChanged(self, value)
  mod.configuration.SetTrinketMenuColumnAmount(value)
  mod.trinketMenu.UpdateTrinketMenuResize()
  self.valueFontString:SetText(value)
end

--[[
  Invoked when the trinketMenu column slider is shown. Updates the configured value

  @param {table} self
]]--
function me.TrinketMenuColumnAmountSliderOnShow(self)
  self:SetValue(mod.configuration.GetTrinketMenuColumnAmount())
end

--[[
  OnValueChanged callback for the trinketMenu size slider

  @param {table} self
  @param {number} value
]]--
function me.TrinketMenuSlotSizeSliderOnValueChanged(self, value)
  mod.configuration.SetTrinketMenuSlotSize(value)
  mod.trinketMenu.UpdateTrinketMenuResize()
  self.valueFontString:SetText(value)
end

--[[
  Invoked when the trinketMenu size slider is shown. Updates the configured value

  @param {table} self
]]--
function me.TrinketMenuSlotSizeSliderOnShow(self)
  self:SetValue(mod.configuration.GetTrinketMenuSlotSize())
end
