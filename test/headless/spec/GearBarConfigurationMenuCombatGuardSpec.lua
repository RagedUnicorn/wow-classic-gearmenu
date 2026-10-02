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
  Spec for the combat guards of the gearBar configuration menu in gui/GearBarConfigurationMenu.lua
  (me.CreateNewGearBar, me.DeleteGearBar and the delete confirmation popup).

  Creating a gearBar builds gearSlots that inherit from the SecureActionButtonTemplate and deleting
  one hides the frame those gearSlots are parented to - both are blocked in combat. The guards refuse
  the action during combat lockdown and tell the user before any configuration is changed.

  gui/GearBarConfigurationMenu.lua only indexes rggm.L and assigns StaticPopupDialogs at load time, so
  it can be dofile'd with an empty localization table and the collaborator modules replaced by
  recorder stubs.
]]--

local wowStubs = require("WowStubs")

local GEAR_BAR_ID = 3
local GEAR_BAR_NAME = "Tanking"

-- forward declarations
local CreateFakeButton

--[[
  Build a fake UIPanelButtonTemplate button that keeps the scripts set on it

  @return {table}
    the fake button with a `scripts` map of script name to handler
]]--
CreateFakeButton = function()
  local button = { scripts = {} }

  button.SetHeight = function() end
  button.SetWidth = function() end
  button.SetText = function() end
  button.SetPoint = function() end

  function button:SetScript(scriptName, handler)
    self.scripts[scriptName] = handler
  end

  button.GetFontString = function()
    return { GetStringWidth = function() return 0 end }
  end

  return button
end

describe("GearBarConfigurationMenu combat guards", function()
  local menu
  local popupDialogs
  local previous
  local restore
  local calls

  before_each(function()
    calls = {
      addedGearBars = {},      -- gearBarManager.AddGearBar(name, isDefault)
      builtGearBars = 0,       -- gearBar.BuildGearBar(gearBar)
      builtCategories = 0,     -- addonConfiguration.BuildCategory(...)
      removedFromTicker = {},  -- ticker.UnregisterForTickerRangeCheck(gearBarId)
      removedFromManager = {}, -- gearBarManager.RemoveGearBar(gearBarId)
      removedFromStorage = {}, -- gearBarStorage.RemoveGearBar(gearBarId)
      removedCategories = {},  -- addonConfiguration.InterfaceOptionsRemoveCategory(gearBarId)
      removedContentFrames = {}, -- gearBarConfigurationSubMenu.RemoveGearBarContentFrame(gearBarId)
      popups = {},             -- StaticPopup_Show(name)
      userErrors = 0           -- logger.PrintUserError(msg)
    }

    -- snapshot everything the load / functions touch so nothing leaks across specs
    previous = {
      gearBarConfigurationMenu = rggm.gearBarConfigurationMenu,
      gearBarConfigurationSubMenu = rggm.gearBarConfigurationSubMenu,
      gearBarManager = rggm.gearBarManager,
      gearBarStorage = rggm.gearBarStorage,
      gearBar = rggm.gearBar,
      addonConfiguration = rggm.addonConfiguration,
      ticker = rggm.ticker,
      logger = rggm.logger,
      L = rggm.L
    }

    rggm.L = {}
    popupDialogs = {}

    rggm.gearBarManager = {
      GetGearBars = function() return {} end,
      AddGearBar = function(name, isDefault)
        calls.addedGearBars[#calls.addedGearBars + 1] = { name = name, isDefault = isDefault }
        return { id = GEAR_BAR_ID, displayName = name }
      end,
      RemoveGearBar = function(gearBarId)
        calls.removedFromManager[#calls.removedFromManager + 1] = gearBarId
      end
    }

    rggm.gearBarStorage = {
      RemoveGearBar = function(gearBarId)
        calls.removedFromStorage[#calls.removedFromStorage + 1] = gearBarId
      end
    }

    rggm.gearBar = {
      BuildGearBar = function() calls.builtGearBars = calls.builtGearBars + 1 end,
      UpdateGearBarVisual = function() end
    }

    rggm.addonConfiguration = {
      GetGearBarSubCategory = function() return {} end,
      BuildCategory = function()
        calls.builtCategories = calls.builtCategories + 1
        return {}, {}
      end,
      InterfaceOptionsRemoveCategory = function(gearBarId)
        calls.removedCategories[#calls.removedCategories + 1] = gearBarId
      end
    }

    rggm.gearBarConfigurationSubMenu = {
      GearBarConfigurationCategoryContainerOnCallback = function() end,
      RemoveGearBarContentFrame = function(gearBarId)
        calls.removedContentFrames[#calls.removedContentFrames + 1] = gearBarId
      end
    }

    rggm.ticker = {
      UnregisterForTickerRangeCheck = function(gearBarId)
        calls.removedFromTicker[#calls.removedFromTicker + 1] = gearBarId
      end
    }

    rggm.logger = {
      LogDebug = function() end,
      LogInfo = function() end,
      LogWarn = function() end,
      LogError = function() end,
      PrintUserError = function() calls.userErrors = calls.userErrors + 1 end
    }

    restore = wowStubs.install({
      InCombatLockdown = wowStubs.stubs.InCombatLockdown(false),
      StaticPopupDialogs = popupDialogs,
      StaticPopup_Show = function(name) calls.popups[#calls.popups + 1] = name end,
      CreateFrame = function() return CreateFakeButton() end
    })

    dofile("gui/GearBarConfigurationMenu.lua")
    menu = rggm.gearBarConfigurationMenu
    -- the gearBar list is never built headlessly
    menu.GearBarListOnUpdate = function() end
  end)

  after_each(function()
    restore()

    rggm.gearBarConfigurationMenu = previous.gearBarConfigurationMenu
    rggm.gearBarConfigurationSubMenu = previous.gearBarConfigurationSubMenu
    rggm.gearBarManager = previous.gearBarManager
    rggm.gearBarStorage = previous.gearBarStorage
    rggm.gearBar = previous.gearBar
    rggm.addonConfiguration = previous.addonConfiguration
    rggm.ticker = previous.ticker
    rggm.logger = previous.logger
    rggm.L = previous.L
  end)

  --[[
    Enter combat lockdown for the rest of the current test

    @return {function}
      restores the out of combat stub
  ]]--
  local function enterCombat()
    return wowStubs.install({
      InCombatLockdown = wowStubs.stubs.InCombatLockdown(true)
    })
  end

  --[[
    Assert that no part of the gearBar was removed
  ]]--
  local function assertNothingRemoved()
    assert.are.equal(0, #calls.removedFromTicker)
    assert.are.equal(0, #calls.removedFromManager)
    assert.are.equal(0, #calls.removedFromStorage)
    assert.are.equal(0, #calls.removedCategories)
    assert.are.equal(0, #calls.removedContentFrames)
  end

  describe("CreateNewGearBar", function()
    it("creates and builds the gearBar out of combat", function()
      menu.CreateNewGearBar(GEAR_BAR_NAME)

      assert.are.same({ { name = GEAR_BAR_NAME, isDefault = true } }, calls.addedGearBars)
      assert.are.equal(1, calls.builtGearBars)
      assert.are.equal(1, calls.builtCategories)
      assert.are.equal(0, calls.userErrors)
    end)

    it("refuses the creation during combat lockdown and tells the user", function()
      local restoreCombat = enterCombat()

      menu.CreateNewGearBar(GEAR_BAR_NAME)

      assert.are.equal(0, #calls.addedGearBars)
      assert.are.equal(0, calls.builtGearBars)
      assert.are.equal(0, calls.builtCategories)
      assert.are.equal(1, calls.userErrors)

      restoreCombat()
    end)
  end)

  describe("DeleteGearBar", function()
    it("removes the gearBar everywhere out of combat", function()
      menu.DeleteGearBar(GEAR_BAR_ID)

      assert.are.same({ GEAR_BAR_ID }, calls.removedFromTicker)
      assert.are.same({ GEAR_BAR_ID }, calls.removedFromManager)
      assert.are.same({ GEAR_BAR_ID }, calls.removedFromStorage)
      assert.are.same({ GEAR_BAR_ID }, calls.removedCategories)
      assert.are.same({ GEAR_BAR_ID }, calls.removedContentFrames)
      assert.are.equal(0, calls.userErrors)
    end)

    it("refuses the deletion during combat lockdown and tells the user", function()
      local restoreCombat = enterCombat()

      menu.DeleteGearBar(GEAR_BAR_ID)

      assertNothingRemoved()
      assert.are.equal(1, calls.userErrors)

      restoreCombat()
    end)
  end)

  describe("delete confirmation popup", function()
    --[[
      Click the remove button of the gearBar row and confirm the popup
    ]]--
    local function removeAndConfirm()
      local button = menu.CreateRemoveGearBarButton({}, {}, 1)

      button.id = GEAR_BAR_ID
      button.scripts.OnClick(button)
      popupDialogs["RGGM_GEAR_BAR_CONFIRM_DELETE"].OnAccept()
    end

    it("deletes the gearBar of the clicked row when confirmed out of combat", function()
      removeAndConfirm()

      assert.are.same({ "RGGM_GEAR_BAR_CONFIRM_DELETE" }, calls.popups)
      assert.are.same({ GEAR_BAR_ID }, calls.removedFromManager)
      assert.are.same({ GEAR_BAR_ID }, calls.removedFromStorage)
      assert.are.equal(0, calls.userErrors)
    end)

    it("keeps the gearBar when combat started before the deletion was confirmed", function()
      local restoreCombat = enterCombat()

      removeAndConfirm()

      assertNothingRemoved()
      assert.are.equal(1, calls.userErrors)

      restoreCombat()
    end)

    it("does not delete the refused gearBar on a later confirmation", function()
      local restoreCombat = enterCombat()

      removeAndConfirm()
      restoreCombat()
      popupDialogs["RGGM_GEAR_BAR_CONFIRM_DELETE"].OnAccept()

      assertNothingRemoved()
    end)
  end)
end)
