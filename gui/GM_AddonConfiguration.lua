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

-- luacheck: globals CreateFrame UIParent Settings

local mod = rggm
local me = {}

mod.addonConfiguration = me

me.tag = "AddonConfiguration"

--[[
  Holds the id reference to the main category of the addon. Can be used with Settings.OpenToCategory({number})
  {number}
]]--
local mainCategoryId
--[[
  Holds the id reference to the gearBar configuration subcategory
  {number}
]]--
local gearBarSubCategoryId

--[[
  Retrieve a reference to the main category of the addon

  @return {table | nil}
    The main category of the addon or nil if not found
]]--
function me.GetMainCategory()
  if mainCategoryId ~= nil then
    return Settings.GetCategory(mainCategoryId)
  end

  return nil
end

--[[
  Searches for the specific gearBar configuration subcategory and returns it

  @return {table | nil}
    The gearBar configuration subcategory or nil if not found
]]--
function me.GetGearBarSubCategory()
  local mainCategory = me.GetMainCategory()

  for i = 1, #mainCategory.subcategories do
    if mainCategory.subcategories[i].ID == gearBarSubCategoryId then
      return mainCategory.subcategories[i]
    end
  end

  return nil
end

--[[
  Create addon configuration menu(s)
]]--
function me.SetupAddonConfiguration()
  -- initialize the main addon category
  local category, menu = me.BuildCategory(RGGM_CONSTANTS.ELEMENT_ADDON_PANEL, nil, rggm.L["addon_name"])
  -- add about content into main category
  mod.aboutContent.BuildAboutContent(menu)

  me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GENERAL_OPTIONS_FRAME,
    category,
    rggm.L["general_category_name"],
    mod.generalMenu.BuildUi
  )
  me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_TRINKET_MENU_FRAME,
    category,
    rggm.L["trinket_menu_category_name"],
    mod.trinketConfigurationMenu.BuildUi
  )
  me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_QUICK_CHANGE_FRAME,
    category,
    rggm.L["quick_change_category_name"],
    mod.quickChangeMenu.BuildUi
  )
  local gearBarConfigurationSubCategory = me.BuildCategory(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_CONFIG_FRAME,
    category,
    rggm.L["gear_bar_configuration_panel_text"],
    mod.gearBarConfigurationMenu.BuildUi
  )
  gearBarSubCategoryId = gearBarConfigurationSubCategory.ID
  --[[
   load configured gearBars after the menu RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_CONFIG_FRAME was
   created to attach to
 ]]--
  mod.gearBarConfigurationMenu.LoadConfiguredGearBars()
end

--[[
  Builds main and subcategories

  @param {string} frameName
  @param {table} parent
  @param {string} panelText
  @param {function} onShowCallback

  @return {table}, {table}
    category, menu
]]--
function me.BuildCategory(frameName, parent, panelText, onShowCallback)
  local category
  local menu

  if parent == nil then
    menu = CreateFrame("Frame", frameName)
    category = Settings.RegisterCanvasLayoutCategory(menu, panelText)
    mainCategoryId = category.ID
    Settings.RegisterAddOnCategory(category)
  else
    menu = CreateFrame("Frame", frameName, nil)
    menu.parent = parent.name
    local subcategory = Settings.RegisterCanvasLayoutSubcategory(parent, menu, frameName)
    subcategory.name = panelText
    category = subcategory
    Settings.RegisterAddOnCategory(subcategory)
  end

  if onShowCallback ~= nil then
    menu:SetScript("OnShow", onShowCallback)
  end

  --[[
   Important to hide panel initially. Interface addon options will take care of showing the menu.
   If this is not done OnShow callbacks will not be invoked correctly.
  ]]--
  menu:Hide()

  return category, menu
end

--[[
  Open the Blizzard addon configurations panel for the addon
]]--
function me.OpenMainCategory()
  if mainCategoryId ~= nil then
    Settings.OpenToCategory(mainCategoryId)
  end
end

--[[
  Loops through the interface categories and searches for a matching gearBar. If one
  can be found it is getting deleted.

  @param {number} gearBarId
]]--
function me.InterfaceOptionsRemoveCategory(gearBarId)
  local categories = me.GetGearBarSubCategory().subcategories

  for i = 1, #categories do
    local interfaceCategory = categories[i]

    if interfaceCategory.gearBarId == gearBarId then
      categories[i] = nil -- delete category
      break
    end
  end

  local currentIndex = 0

  for i = 1, #categories do
    if categories[i] ~= nil then
      currentIndex = currentIndex + 1
      categories[currentIndex] = categories[i]
    end
  end

  for i = currentIndex + 1, #categories do
    categories[i] = nil
  end

  me.UpdateAddonPanel()
end

--[[
    This is a workaround to force a refresh of the interface addon panel after a gearBar was deleted.
    Moving to another category in the Blizzard settings and back to the addon panel will refresh the
    panel and show the updated gearBar list.
  ]]--
function me.UpdateAddonPanel()
  Settings.OpenToCategory(11)
  me.OpenMainCategory()
end
