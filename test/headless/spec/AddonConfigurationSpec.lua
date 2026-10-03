--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

--[[
  Spec for the settings registration in gui/AddonConfiguration.lua: the main category and its
  subcategories registered with the Settings API, the category ids callers navigate by, the panels
  building their page when first shown, and removing a gearBar subcategory.

  Settings is replaced by an in-memory category tree, CreateFrame by the recording FrameRegistry
  (its Show / Hide run OnShow / OnHide), and the page builders by recorders.
]]--

local wowStubs = require("WowStubs")

--[[
  An in-memory stand-in for the Settings API: categories get increasing numeric IDs, subcategories
  are appended to their parent and every OpenToCategory call is recorded.

  @return {table}
]]--
local function CreateFakeSettings()
  local settings = { categories = {}, registeredAddOnCategories = {}, opened = {}, nextId = 100 }

  local function newCategory(frame, name)
    settings.nextId = settings.nextId + 1

    local category = { ID = settings.nextId, name = name, frame = frame, subcategories = {} }

    settings.categories[category.ID] = category

    return category
  end

  function settings.RegisterCanvasLayoutCategory(frame, name)
    return newCategory(frame, name)
  end

  function settings.RegisterCanvasLayoutSubcategory(parent, frame, name)
    local subcategory = newCategory(frame, name)

    parent.subcategories[#parent.subcategories + 1] = subcategory

    return subcategory
  end

  function settings.RegisterAddOnCategory(category)
    settings.registeredAddOnCategories[#settings.registeredAddOnCategories + 1] = category
  end

  function settings.GetCategory(categoryId)
    return settings.categories[categoryId]
  end

  function settings.OpenToCategory(categoryId)
    settings.opened[#settings.opened + 1] = categoryId
  end

  return settings
end

describe("AddonConfiguration", function()
  local addonConfiguration
  local settings
  local frames
  local calls
  local previous
  local restore

  --[[
    A page module whose BuildUi records the frame it was shown with

    @param {string} name

    @return {table}
  ]]--
  local function page(name)
    return {
      BuildUi = function(frame)
        calls.builtPages[#calls.builtPages + 1] = { name = name, frame = frame }
      end
    }
  end

  local function subcategoryNamed(name)
    for _, subcategory in ipairs(addonConfiguration.GetMainCategory().subcategories) do
      if subcategory.name == name then return subcategory end
    end

    return nil
  end

  before_each(function()
    calls = {
      aboutContent = {},        -- aboutContent.BuildAboutContent(frame)
      builtPages = {},          -- <page>.BuildUi(frame)
      loadedGearBars = 0        -- gearBarConfigurationMenu.LoadConfiguredGearBars()
    }

    previous = {
      addonConfiguration = rggm.addonConfiguration,
      aboutContent = rggm.aboutContent,
      generalMenu = rggm.generalMenu,
      trinketConfigurationMenu = rggm.trinketConfigurationMenu,
      quickChangeMenu = rggm.quickChangeMenu,
      profileMenu = rggm.profileMenu,
      gearBarConfigurationMenu = rggm.gearBarConfigurationMenu,
      L = rggm.L
    }

    rggm.L = setmetatable({}, { __index = function(_, key) return key end })
    rggm.aboutContent = {
      BuildAboutContent = function(frame) calls.aboutContent[#calls.aboutContent + 1] = frame end
    }
    rggm.generalMenu = page("general")
    rggm.trinketConfigurationMenu = page("trinketMenu")
    rggm.quickChangeMenu = page("quickChange")
    rggm.profileMenu = page("profile")
    rggm.gearBarConfigurationMenu = page("gearBar")
    rggm.gearBarConfigurationMenu.LoadConfiguredGearBars = function()
      calls.loadedGearBars = calls.loadedGearBars + 1
    end

    settings = CreateFakeSettings()
    frames = wowStubs.stubs.FrameRegistry()
    restore = wowStubs.install({ Settings = settings, CreateFrame = frames.CreateFrame })

    -- fresh module: no category ids captured yet
    dofile("gui/AddonConfiguration.lua")
    addonConfiguration = rggm.addonConfiguration
  end)

  after_each(function()
    restore()

    for name, value in pairs(previous) do
      rggm[name] = value
    end
  end)

  describe("before SetupAddonConfiguration", function()
    it("knows no categories", function()
      assert.is_nil(addonConfiguration.GetMainCategory())
      assert.is_nil(addonConfiguration.GetCategoryId("main"))
    end)

    it("does not try to open the settings panel", function()
      addonConfiguration.OpenMainCategory()

      assert.are.same({}, settings.opened)
    end)
  end)

  describe("SetupAddonConfiguration", function()
    before_each(function()
      addonConfiguration.SetupAddonConfiguration()
    end)

    it("registers the main category with the about content", function()
      local mainCategory = addonConfiguration.GetMainCategory()

      assert.are.equal("addon_name", mainCategory.name)
      assert.are.equal(frames.frames[RGGM_CONSTANTS.ELEMENT_ADDON_PANEL], mainCategory.frame)
      assert.are.same({ mainCategory.frame }, calls.aboutContent)
      assert.are.equal(mainCategory, settings.registeredAddOnCategories[1])
    end)

    it("registers the five subcategories under the main category in order", function()
      local names = {}

      for index, subcategory in ipairs(addonConfiguration.GetMainCategory().subcategories) do
        names[index] = subcategory.name
      end

      assert.are.same({
        "options_category_name", "trinket_menu_category_name", "quick_change_category_name",
        "profile_category_name", "gear_bar_configuration_panel_text"
      }, names)
      assert.are.equal(6, #settings.registeredAddOnCategories)
    end)

    it("resolves every navigation key to the id of its category", function()
      local expected = {
        main = addonConfiguration.GetMainCategory(),
        general = subcategoryNamed("options_category_name"),
        trinketMenu = subcategoryNamed("trinket_menu_category_name"),
        quickChange = subcategoryNamed("quick_change_category_name"),
        profile = subcategoryNamed("profile_category_name"),
        gearBar = subcategoryNamed("gear_bar_configuration_panel_text")
      }

      for key, category in pairs(expected) do
        assert.are.equal(category.ID, addonConfiguration.GetCategoryId(key))
      end

      assert.is_nil(addonConfiguration.GetCategoryId("unknown"))
    end)

    it("finds the gearBar configuration subcategory", function()
      assert.are.equal(
        subcategoryNamed("gear_bar_configuration_panel_text"),
        addonConfiguration.GetGearBarSubCategory()
      )
    end)

    it("hides every panel and builds none of the pages before they are shown", function()
      for _, frame in pairs(frames.frames) do
        assert.is_true(frame.hidden)
      end

      assert.are.same({}, calls.builtPages)
    end)

    it("builds a page when its panel is shown", function()
      local generalFrame = frames.frames[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GENERAL_OPTIONS_FRAME]
      local profileFrame = frames.frames[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_PROFILE_FRAME]

      generalFrame:Show()
      profileFrame:Show()

      assert.are.same(
        { { name = "general", frame = generalFrame }, { name = "profile", frame = profileFrame } },
        calls.builtPages
      )
    end)

    it("loads the configured gearBars once the gearBar panel exists", function()
      assert.are.equal(1, calls.loadedGearBars)
    end)

    it("opens the main category", function()
      addonConfiguration.OpenMainCategory()

      assert.are.same({ addonConfiguration.GetCategoryId("main") }, settings.opened)
    end)
  end)

  describe("InterfaceOptionsRemoveCategory", function()
    local gearBarCategories

    before_each(function()
      addonConfiguration.SetupAddonConfiguration()

      gearBarCategories = addonConfiguration.GetGearBarSubCategory().subcategories

      for gearBarId = 1, 3 do
        gearBarCategories[gearBarId] = { name = "gearBar" .. gearBarId, gearBarId = gearBarId }
      end
    end)

    local function remainingGearBarIds()
      local ids = {}

      for index, category in ipairs(gearBarCategories) do
        ids[index] = category.gearBarId
      end

      return ids
    end

    it("removes a gearBar from the middle and closes the gap", function()
      addonConfiguration.InterfaceOptionsRemoveCategory(2)

      assert.are.same({ 1, 3 }, remainingGearBarIds())
      assert.are.equal(2, #gearBarCategories)
    end)

    it("removes the first and the last gearBar", function()
      addonConfiguration.InterfaceOptionsRemoveCategory(1)
      addonConfiguration.InterfaceOptionsRemoveCategory(3)

      assert.are.same({ 2 }, remainingGearBarIds())
    end)

    it("keeps the list untouched for an unknown gearBar", function()
      addonConfiguration.InterfaceOptionsRemoveCategory(42)

      assert.are.same({ 1, 2, 3 }, remainingGearBarIds())
    end)

    it("bounces through the general options to make the panel rebuild its category tree", function()
      addonConfiguration.InterfaceOptionsRemoveCategory(2)

      assert.are.same(
        { addonConfiguration.GetCategoryId("general"), addonConfiguration.GetCategoryId("main") },
        settings.opened
      )
    end)
  end)
end)
