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
  Spec for the general options page in gui/GeneralMenu.lua: which check buttons BuildUi wires to
  which OnShow / OnClick handlers, that each handler mirrors and writes the matching configuration
  toggle, the SoD-only rune slot check button, the item quality filter dropdown and the theme dropdown with
  its reload confirmation.

  The module indexes rggm.L at load time, so it is dofile'd per test with a localization table that
  echoes its keys. uiHelper and configuration are replaced by recorders; the layout itself (points,
  fonts, colors) is not asserted.
]]--

-- luacheck: read globals StaticPopupDialogs

local wowStubs = require("WowStubs")

--[[
  The check button options in BuildUi order: element name, the configuration getter the OnShow
  handler mirrors and the enable / disable pair the OnClick handler calls
]]--
local CHECK_BUTTON_OPTIONS = {
  { "ELEMENT_GENERAL_OPT_ENABLE_TOOLTIPS", "EnableTooltips", "IsTooltipsEnabled", "Tooltips" },
  {
    "ELEMENT_GENERAL_OPT_ENABLE_SIMPLE_TOOLTIPS", "EnableSimpleTooltips", "IsSimpleTooltipsEnabled",
    "SimpleTooltips"
  },
  { "ELEMENT_GENERAL_OPT_ENABLE_DRAG_AND_DROP", "EnableDragAndDrop", "IsDragAndDropEnabled", "DragAndDrop" },
  { "ELEMENT_GENERAL_OPT_ENABLE_FASTPRESS", "EnableFastPress", "IsFastPressEnabled", "FastPress" },
  { "ELEMENT_GENERAL_OPT_ENABLE_UNEQUIP_SLOT", "EnableUnequipSlot", "IsUnequipSlotEnabled", "UnequipSlot" },
  {
    "ELEMENT_GENERAL_OPT_ENABLE_FALLBACK_TO_BASE_ITEM", "EnableFallbackToBaseItem",
    "IsFallbackToBaseItemEnabled", "FallbackToBaseItem"
  }
}

--[[
  A fake check button that keeps its checked state

  @param {boolean} checked

  @return {table}
]]--
local function CreateFakeCheckButton(checked)
  local checkButton = { checked = checked }

  function checkButton:SetChecked(value)
    self.checked = value
  end

  function checkButton:GetChecked()
    return self.checked
  end

  return checkButton
end

--[[
  A fake parent frame whose font strings accept every layout call

  @return {table}
]]--
local function CreateFakeParentFrame()
  local fontString = setmetatable({}, { __index = function() return function() end end })

  return {
    CreateFontString = function() return fontString end
  }
end

-- the rune slot check button BuildUi adds after the others while Season of Discovery is active
local RUNE_SLOT_OPTION = {
  "ELEMENT_GENERAL_OPT_ENABLE_RUNE_SLOTS", "EnableRuneSlots", "IsRuneSlotsEnabled", "RuneSlots"
}

-- every check button whose OnShow / OnClick pair is exercised, the rune slot one included
local HANDLER_OPTIONS = { RUNE_SLOT_OPTION }

for _, option in ipairs(CHECK_BUTTON_OPTIONS) do
  HANDLER_OPTIONS[#HANDLER_OPTIONS + 1] = option
end

describe("GeneralMenu", function()
  local menu
  local calls
  -- configuration state the recorder getters answer from
  local enabled
  local filterItemQuality
  local uiTheme
  local sodActive
  local previous
  local restore

  before_each(function()
    calls = {
      checkButtons = {},   -- uiHelper.BuildCheckButtonOption(parent, name, position, onShow, onClick, metaData)
      dropdowns = {},      -- uiHelper.CreateSettingsDropdown(name, parent, position, width, generator)
      generatedMenus = 0,  -- dropdown:GenerateMenu()
      configuration = {},  -- configuration.<Enable|Disable>*()
      popups = {},         -- StaticPopup_Show(name) -> the dialog it returned
      reloads = 0          -- ReloadUI()
    }
    enabled = {}
    filterItemQuality = RGGM_CONSTANTS.ITEMQUALITY.common
    uiTheme = RGGM_CONSTANTS.UI_THEME_CUSTOM
    sodActive = false

    previous = {
      generalMenu = rggm.generalMenu,
      uiHelper = rggm.uiHelper,
      configuration = rggm.configuration,
      season = rggm.season,
      L = rggm.L
    }

    rggm.L = setmetatable({}, { __index = function(_, key) return key end })
    rggm.season = { IsSodActive = function() return sodActive end }

    rggm.uiHelper = {
      SetColor = function() end,
      BuildCheckButtonOption = function(parent, name, _, onShow, onClick, metaData)
        calls.checkButtons[#calls.checkButtons + 1] = {
          parent = parent, name = name, onShow = onShow, onClick = onClick, metaData = metaData
        }
      end,
      CreateSettingsDropdown = function(name, parent, _, _, generator)
        calls.dropdowns[#calls.dropdowns + 1] = { name = name, parent = parent, generator = generator }

        return {
          GenerateMenu = function() calls.generatedMenus = calls.generatedMenus + 1 end
        }
      end
    }

    rggm.configuration = setmetatable({
      GetFilterItemQuality = function() return filterItemQuality end,
      SetFilterItemQuality = function(itemQuality) filterItemQuality = itemQuality end,
      GetUiTheme = function() return uiTheme end,
      SetUiTheme = function(theme) uiTheme = theme end
    }, {
      __index = function(configuration, functionName)
        local stub

        if functionName:find("^Is") then
          stub = function() return enabled[functionName] == true end
        else
          stub = function() calls.configuration[#calls.configuration + 1] = functionName end
        end

        rawset(configuration, functionName, stub)

        return stub
      end
    })

    restore = wowStubs.install({
      -- the module registers its theme reload dialog at load time
      StaticPopupDialogs = {},
      StaticPopup_Show = function(name)
        local dialog = {}

        calls.popups[#calls.popups + 1] = { name = name, dialog = dialog }

        return dialog
      end,
      ReloadUI = function() calls.reloads = calls.reloads + 1 end,
      STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    })

    dofile("gui/GeneralMenu.lua")
    menu = rggm.generalMenu
  end)

  after_each(function()
    restore()

    for name, value in pairs(previous) do
      rggm[name] = value
    end
  end)

  describe("BuildUi", function()
    it("wires every check button option to its OnShow and OnClick handler", function()
      local parent = CreateFakeParentFrame()

      menu.BuildUi(parent)

      assert.are.equal(#CHECK_BUTTON_OPTIONS, #calls.checkButtons)

      for index, option in ipairs(CHECK_BUTTON_OPTIONS) do
        local checkButton = calls.checkButtons[index]

        assert.are.equal(parent, checkButton.parent)
        assert.are.equal(RGGM_CONSTANTS[option[1]], checkButton.name)
        assert.are.equal(menu[option[2] .. "OnShow"], checkButton.onShow)
        assert.are.equal(menu[option[2] .. "OnClick"], checkButton.onClick)
        assert.are.equal(option[2], checkButton.metaData[1])
      end
    end)

    it("adds the rune slot check button only while Season of Discovery is active", function()
      sodActive = true
      menu.BuildUi(CreateFakeParentFrame())

      local checkButton = calls.checkButtons[#CHECK_BUTTON_OPTIONS + 1]

      assert.are.equal(#CHECK_BUTTON_OPTIONS + 1, #calls.checkButtons)
      assert.are.equal(RGGM_CONSTANTS[RUNE_SLOT_OPTION[1]], checkButton.name)
      assert.are.equal(menu.EnableRuneSlotsOnShow, checkButton.onShow)
      assert.are.equal(menu.EnableRuneSlotsOnClick, checkButton.onClick)
    end)

    it("builds the item quality and theme dropdowns and generates each once to show the selection", function()
      local parent = CreateFakeParentFrame()

      menu.BuildUi(parent)

      assert.are.equal(2, #calls.dropdowns)
      assert.are.equal(RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_FILTER_ITEM_QUALITY, calls.dropdowns[1].name)
      assert.are.equal(parent, calls.dropdowns[1].parent)
      assert.are.equal(menu.InitializeItemQualityDropdownMenu, calls.dropdowns[1].generator)
      assert.are.equal(RGGM_CONSTANTS.ELEMENT_GENERAL_OPT_CHOOSE_THEME, calls.dropdowns[2].name)
      assert.are.equal(menu.InitializeChooseThemeDropdownMenu, calls.dropdowns[2].generator)
      assert.are.equal(2, calls.generatedMenus)
    end)

    it("builds the page only once", function()
      menu.BuildUi(CreateFakeParentFrame())
      menu.BuildUi(CreateFakeParentFrame())

      assert.are.equal(#CHECK_BUTTON_OPTIONS, #calls.checkButtons)
      assert.are.equal(2, #calls.dropdowns)
    end)
  end)

  describe("check button handlers", function()
    for _, option in ipairs(HANDLER_OPTIONS) do
      local handler, getter, toggle = option[2], option[3], option[4]

      it(handler .. "OnShow mirrors " .. getter, function()
        local checkButton = CreateFakeCheckButton(nil)

        enabled[getter] = true
        menu[handler .. "OnShow"](checkButton)
        assert.is_true(checkButton.checked)

        enabled[getter] = false
        menu[handler .. "OnShow"](checkButton)
        assert.is_false(checkButton.checked)
      end)

      it(handler .. "OnClick enables or disables " .. toggle, function()
        menu[handler .. "OnClick"](CreateFakeCheckButton(true))
        menu[handler .. "OnClick"](CreateFakeCheckButton(false))

        assert.are.same({ "Enable" .. toggle, "Disable" .. toggle }, calls.configuration)
      end)
    end
  end)

  describe("item quality dropdown", function()
    local function generate()
      local entries = {}
      local rootDescription = {
        CreateRadio = function(_, text, isSelected, onSelect, value)
          entries[#entries + 1] = { text = text, isSelected = isSelected, onSelect = onSelect, value = value }
        end
      }

      menu.InitializeItemQualityDropdownMenu(nil, rootDescription)

      return entries
    end

    it("offers one radio entry per item quality from poor to legendary", function()
      local entries = generate()
      local values = {}

      for index, entry in ipairs(entries) do
        values[index] = entry.value
        assert.are.equal(menu.IsItemQualitySelected, entry.isSelected)
        assert.are.equal(menu.OnItemQualitySelect, entry.onSelect)
      end

      local quality = RGGM_CONSTANTS.ITEMQUALITY

      assert.are.same(
        { quality.poor, quality.common, quality.uncommon, quality.rare, quality.epic, quality.legendary },
        values
      )
      assert.are.equal("item_quality_poor", entries[1].text)
      assert.are.equal("item_quality_legendary", entries[6].text)
    end)

    it("marks only the configured filter as selected", function()
      filterItemQuality = RGGM_CONSTANTS.ITEMQUALITY.rare

      assert.is_true(menu.IsItemQualitySelected(RGGM_CONSTANTS.ITEMQUALITY.rare))
      assert.is_false(menu.IsItemQualitySelected(RGGM_CONSTANTS.ITEMQUALITY.epic))
    end)

    it("stores the selected quality as the new filter", function()
      menu.OnItemQualitySelect(RGGM_CONSTANTS.ITEMQUALITY.epic)

      assert.are.equal(RGGM_CONSTANTS.ITEMQUALITY.epic, filterItemQuality)
      assert.is_true(menu.IsItemQualitySelected(RGGM_CONSTANTS.ITEMQUALITY.epic))
    end)
  end)

  describe("theme dropdown", function()
    it("offers the custom and the classic theme", function()
      local entries = {}
      local rootDescription = {
        CreateRadio = function(_, text, isSelected, onSelect, value)
          entries[#entries + 1] = { text = text, isSelected = isSelected, onSelect = onSelect, value = value }
        end
      }

      menu.InitializeChooseThemeDropdownMenu(nil, rootDescription)

      assert.are.equal(2, #entries)
      assert.are.same({ "theme_custom", RGGM_CONSTANTS.UI_THEME_CUSTOM }, { entries[1].text, entries[1].value })
      assert.are.same({ "theme_classic", RGGM_CONSTANTS.UI_THEME_CLASSIC }, { entries[2].text, entries[2].value })
      assert.are.equal(menu.IsThemeSelected, entries[1].isSelected)
      assert.are.equal(menu.OnThemeSelect, entries[1].onSelect)
    end)

    it("marks only the configured theme as selected", function()
      assert.is_true(menu.IsThemeSelected(RGGM_CONSTANTS.UI_THEME_CUSTOM))
      assert.is_false(menu.IsThemeSelected(RGGM_CONSTANTS.UI_THEME_CLASSIC))
    end)

    it("asks for the reload before a new theme is stored", function()
      menu.OnThemeSelect(RGGM_CONSTANTS.UI_THEME_CLASSIC)

      assert.are.equal(1, #calls.popups)
      assert.are.equal("RGGM_RELOAD_INTERFACE", calls.popups[1].name)
      assert.are.equal(RGGM_CONSTANTS.UI_THEME_CLASSIC, calls.popups[1].dialog.data)
      assert.are.equal(RGGM_CONSTANTS.UI_THEME_CUSTOM, uiTheme)
      assert.are.equal(0, calls.reloads)
    end)

    it("does nothing when the configured theme is picked again", function()
      menu.OnThemeSelect(RGGM_CONSTANTS.UI_THEME_CUSTOM)

      assert.are.equal(0, #calls.popups)
    end)

    it("stores the theme and reloads the ui once the dialog is accepted", function()
      StaticPopupDialogs["RGGM_RELOAD_INTERFACE"].OnAccept(nil, RGGM_CONSTANTS.UI_THEME_CLASSIC)

      assert.are.equal(RGGM_CONSTANTS.UI_THEME_CLASSIC, uiTheme)
      assert.are.equal(1, calls.reloads)
    end)
  end)
end)
