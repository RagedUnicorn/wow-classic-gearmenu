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
  Spec for the trinketMenu settings page in gui/TrinketConfigurationMenu.lua: which options
  me.BuildUi creates (once), how the checkbuttons mirror and write the configuration, and that the
  column / slot size sliders store the value before the trinketMenu is resized.

  rggm.uiHelper is a recorder that keeps the callbacks and slider ranges the page hands it, so the
  callbacks are driven directly instead of through widgets. rggm.configuration and rggm.trinketMenu
  record every call in one ordered log.
]]--

local COLUMN_AMOUNT = 4
local SLOT_SIZE = 40

describe("TrinketConfigurationMenu", function()
  local menu
  local previous
  local callLog
  local checkButtons
  local sliders
  local configurationState

  --[[
    A stand-in checkbutton that keeps its checked state

    @param {boolean} checked

    @return {table}
  ]]--
  local function fakeCheckButton(checked)
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
    A module stand-in that logs "<name>.<function>(<first argument>)" for every call

    @param {string} name
    @param {table} overrides
      functions that answer instead of logging

    @return {table}
  ]]--
  local function recorder(name, overrides)
    return setmetatable(overrides or {}, {
      __index = function(module, functionName)
        local stub = function(value)
          local entry = name .. "." .. functionName

          if value ~= nil then entry = entry .. "(" .. tostring(value) .. ")" end

          callLog[#callLog + 1] = entry
        end

        rawset(module, functionName, stub)

        return stub
      end
    })
  end

  local function buildUi()
    menu.BuildUi({
      CreateFontString = function()
        return { SetPoint = function() end, SetText = function() end }
      end
    })
  end

  before_each(function()
    callLog = {}
    checkButtons = {}
    sliders = {}
    configurationState = { trinketMenu = false, locked = false, cooldowns = false }

    previous = {
      trinketConfigurationMenu = rggm.trinketConfigurationMenu,
      configuration = rggm.configuration,
      trinketMenu = rggm.trinketMenu,
      uiHelper = rggm.uiHelper,
      L = rggm.L
    }

    rggm.L = {}
    rggm.configuration = recorder("configuration", {
      IsTrinketMenuEnabled = function() return configurationState.trinketMenu end,
      IsTrinketMenuFrameLocked = function() return configurationState.locked end,
      IsShowCooldownsEnabled = function() return configurationState.cooldowns end,
      GetTrinketMenuColumnAmount = function() return COLUMN_AMOUNT end,
      GetTrinketMenuSlotSize = function() return SLOT_SIZE end
    })
    rggm.trinketMenu = recorder("trinketMenu")
    rggm.uiHelper = {
      SetColor = function() end,
      BuildCheckButtonOption = function(_, frameName, _, onShow, onClick)
        checkButtons[#checkButtons + 1] = { frameName = frameName, onShow = onShow, onClick = onClick }
      end,
      CreateSizeSlider = function(_, sliderName, _, min, max, value, _, _, onValueChanged)
        sliders[#sliders + 1] = {
          sliderName = sliderName, min = min, max = max, value = value, onValueChanged = onValueChanged
        }
      end
    }

    dofile("gui/TrinketConfigurationMenu.lua")
    menu = rggm.trinketConfigurationMenu
  end)

  after_each(function()
    for name, module in pairs(previous) do
      rggm[name] = module
    end
  end)

  describe("BuildUi", function()
    it("creates the enable, lock and show cooldowns checkbuttons", function()
      buildUi()

      assert.are.same({
        RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_OPT_ENABLE_MENU,
        RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_OPT_LOCK_MENU,
        RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_SHOW_COOLDOWNS
      }, { checkButtons[1].frameName, checkButtons[2].frameName, checkButtons[3].frameName })
      assert.are.equal(menu.EnableTrinketMenuOnClick, checkButtons[1].onClick)
      assert.are.equal(menu.LockTrinketMenuOnClick, checkButtons[2].onClick)
      assert.are.equal(menu.ShowCooldownsOnClick, checkButtons[3].onClick)
    end)

    it("creates the sliders with their constant ranges, starting at the configured values", function()
      buildUi()

      assert.are.equal(2, #sliders)
      assert.are.same({
        sliderName = RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_COLUMN_AMOUNT_SLIDER,
        min = RGGM_CONSTANTS.TRINKET_MENU_COLUMN_AMOUNT_SLIDER_MIN,
        max = RGGM_CONSTANTS.TRINKET_MENU_COLUMN_AMOUNT_SLIDER_MAX,
        value = COLUMN_AMOUNT,
        onValueChanged = menu.TrinketMenuColumnAmountSliderOnValueChanged
      }, sliders[1])
      assert.are.same({
        sliderName = RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_SLOT_SIZE_SLIDER,
        min = RGGM_CONSTANTS.TRINKET_MENU_SLOT_SIZE_SLIDER_MIN,
        max = RGGM_CONSTANTS.TRINKET_MENU_SLOT_SIZE_SLIDER_MAX,
        value = SLOT_SIZE,
        onValueChanged = menu.TrinketMenuSlotSizeSliderOnValueChanged
      }, sliders[2])
    end)

    it("builds the page only once", function()
      buildUi()
      buildUi()

      assert.are.equal(3, #checkButtons)
      assert.are.equal(2, #sliders)
    end)
  end)

  -- checkbutton, the configuration state it mirrors and the calls a check / uncheck makes
  local checkButtonCases = {
    {
      name = "enable trinketMenu", state = "trinketMenu", onShow = "EnableTrinketMenuOnShow",
      onClick = "EnableTrinketMenuOnClick",
      checkCall = "configuration.EnableTrinketMenu", uncheckCall = "configuration.DisableTrinketMenu"
    },
    {
      name = "lock trinketMenu", state = "locked", onShow = "LockTrinketMenuOnShow",
      onClick = "LockTrinketMenuOnClick",
      checkCall = "configuration.LockTrinketMenuFrame", uncheckCall = "configuration.UnlockTrinketMenuFrame"
    },
    {
      name = "show cooldowns", state = "cooldowns", onShow = "ShowCooldownsOnShow",
      onClick = "ShowCooldownsOnClick",
      checkCall = "configuration.EnableShowCooldowns", uncheckCall = "configuration.DisableShowCooldowns"
    }
  }

  for _, case in ipairs(checkButtonCases) do
    describe(case.name .. " checkbutton", function()
      it("shows checked when the option is on", function()
        local checkButton = fakeCheckButton(false)

        configurationState[case.state] = true
        menu[case.onShow](checkButton)

        assert.is_true(checkButton.checked)
      end)

      it("shows unchecked when the option is off", function()
        local checkButton = fakeCheckButton(true)

        menu[case.onShow](checkButton)

        assert.is_false(checkButton.checked)
      end)

      it("turns the option on when checked", function()
        menu[case.onClick](fakeCheckButton(true))

        assert.are.same({ case.checkCall }, callLog)
      end)

      it("turns the option off when unchecked", function()
        menu[case.onClick](fakeCheckButton(false))

        assert.are.same({ case.uncheckCall }, callLog)
      end)
    end)
  end

  describe("sliders", function()
    it("stores the column amount before resizing the trinketMenu", function()
      menu.TrinketMenuColumnAmountSliderOnValueChanged({}, 6)

      assert.are.same({
        "configuration.SetTrinketMenuColumnAmount(6)",
        "trinketMenu.UpdateTrinketMenuResize"
      }, callLog)
    end)

    it("stores the slot size before resizing the trinketMenu", function()
      menu.TrinketMenuSlotSizeSliderOnValueChanged({}, 32)

      assert.are.same({
        "configuration.SetTrinketMenuSlotSize(32)",
        "trinketMenu.UpdateTrinketMenuResize"
      }, callLog)
    end)
  end)
end)
