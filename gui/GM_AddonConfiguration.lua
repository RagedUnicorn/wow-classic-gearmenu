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

-- luacheck: globals CreateFrame UIParent InterfaceOptions_AddCategory InterfaceOptionsFrame_OpenToCategory

local mod = rggm
local me = {}

mod.addonConfiguration = me

me.tag = "AddonConfiguration"

--[[
  Create addon configuration menu(s)
]]--
function me.SetupAddonConfiguration()
  local panel = {}

  panel.main = me.BuildCategory(RGGM_CONSTANTS.ELEMENT_ADDON_PANEL, nil, rggm.L["addon_name"])
  me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GENERAL_SUB_OPTION_FRAME,
    panel.main,
    rggm.L["general_category_name"],
    mod.generalMenu.BuildUi
  )
  me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_SLOTS_SUB_OPTION_FRAME,
    panel.main, rggm.L["gearslot_category_name"],
    mod.gearSlotMenu.BuildUi
  )
  me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_SUB_OPTION_FRAME,
    panel.main,
    rggm.L["quick_change_category_name"],
    mod.quickChangeMenu.BuildUi
  )
  --[[
    For development purpose the InterfaceOptionsFrame_OpenToCategory function can be used to directly
    open a specific category. Because of a blizzard bug this usually has to be called twice to actually work.

    Example:

    InterfaceOptionsFrame_OpenToCategory(generalMenu)
    InterfaceOptionsFrame_OpenToCategory(generalMenu)

    Note: The behavior with how events fire might change quite a bit when using the above debug method.
    Because of this it is important that the "normal" manuall way of opening the menu is tested as well.
  ]]--
  mod.aboutContent.BuildAboutContent(panel.main)
end

--[[
  @param {string} frameName
  @param {table} parent
  @param {string} panelText
  @param {function} onShowCallback

  @return {table}
]]--
function me.BuildCategory(frameName, parent, panelText, onShowCallback)
  local menu

  if parent == nil then
    menu = CreateFrame("Frame", frameName, UIParent)
  else
    menu = CreateFrame("Frame", frameName, parent)
    menu.parent = parent.name
  end

  menu.name = panelText

  if onShowCallback ~= nil then
    menu:SetScript("OnShow", onShowCallback)
  end

  -- Important to hide panel initially. Interface addon options will take care of showing the menu
  menu:Hide()

  -- Add the child to the Interface Options
  InterfaceOptions_AddCategory(menu)

  return menu
end

--[[
  Open the Blizzard addon configurations panel for the addon
]]--
function me.OpenAddonPanel()
  -- Because of a blizzard bug this usually has to be called twice to actually work
  InterfaceOptionsFrame_OpenToCategory(_G[RGGM_CONSTANTS.ELEMENT_ADDON_PANEL])
  InterfaceOptionsFrame_OpenToCategory(_G[RGGM_CONSTANTS.ELEMENT_ADDON_PANEL])
end
