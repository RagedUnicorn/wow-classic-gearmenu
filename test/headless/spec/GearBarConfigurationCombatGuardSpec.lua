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
  Spec for the combat guards of the gearBar configuration submenu in
  gui/GearBarConfigurationSubMenu.lua (me.GearSlotSizeSliderOnValueChanged).

  Resizing the gearSlots resizes and re-anchors buttons that inherit from the SecureActionButtonTemplate,
  which is blocked in combat. The guard refuses the change during combat lockdown, tells the user and
  keeps the displayed control in sync with the stored (unchanged) state.

  gui/GearBarConfigurationSubMenu.lua only indexes rggm.L at load time, so it can be dofile'd with an
  empty localization table and the collaborator modules (gearBarManager, logger) replaced by
  recorder stubs.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

local GEAR_BAR_ID = 1
local STORED_SLOT_SIZE = 40

-- forward declarations
local CreateFakeSlider

--[[
  Build a fake size slider that records every SetValue call made against it

  @param {number} gearBarId
    the gearBarId reported by the slider's parent frame

  @return {table}
    the fake slider with a `setValues` recorder
]]--
CreateFakeSlider = function(gearBarId)
  local slider = {
    parent = { gearBarId = gearBarId },
    setValues = {}
  }

  function slider:GetParent()
    return self.parent
  end

  function slider:SetValue(value)
    self.setValues[#self.setValues + 1] = value
  end

  return slider
end

describe("GearBarConfigurationSubMenu combat guards", function()
  local subMenu
  local previous
  local restore
  local calls

  before_each(function()
    calls = {
      slotSizes = {}, -- gearBarManager.SetGearSlotSize(gearBarId, value)
      userErrors = 0  -- logger.PrintUserError(msg)
    }

    -- snapshot everything the load / functions touch so nothing leaks across specs
    previous = {
      gearBarConfigurationSubMenu = rggm.gearBarConfigurationSubMenu,
      gearBarManager = rggm.gearBarManager,
      logger = rggm.logger,
      L = rggm.L
    }

    rggm.L = {}

    rggm.gearBarManager = {
      GetGearSlotSize = function()
        return STORED_SLOT_SIZE
      end,
      SetGearSlotSize = function(gearBarId, value)
        calls.slotSizes[#calls.slotSizes + 1] = { gearBarId = gearBarId, value = value }
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
      InCombatLockdown = wowStubs.stubs.InCombatLockdown(false)
    })

    dofile("gui/GearBarConfigurationSubMenu.lua")
    subMenu = rggm.gearBarConfigurationSubMenu
  end)

  after_each(function()
    restore()

    rggm.gearBarConfigurationSubMenu = previous.gearBarConfigurationSubMenu
    rggm.gearBarManager = previous.gearBarManager
    rggm.logger = previous.logger
    rggm.L = previous.L
  end)

  describe("GearSlotSizeSliderOnValueChanged", function()
    it("stores the new gearSlot size out of combat", function()
      local slider = CreateFakeSlider(GEAR_BAR_ID)

      subMenu.GearSlotSizeSliderOnValueChanged(slider, 50)

      assert.are.same({ { gearBarId = GEAR_BAR_ID, value = 50 } }, calls.slotSizes)
      assert.are.equal(0, #slider.setValues)
      assert.are.equal(0, calls.userErrors)
    end)

    it("refuses the change during combat lockdown, tells the user and snaps the slider back", function()
      local restoreCombat = wowStubs.install({
        InCombatLockdown = wowStubs.stubs.InCombatLockdown(true)
      })
      local slider = CreateFakeSlider(GEAR_BAR_ID)

      subMenu.GearSlotSizeSliderOnValueChanged(slider, 50)

      assert.are.equal(0, #calls.slotSizes)
      assert.are.same({ STORED_SLOT_SIZE }, slider.setValues)
      assert.are.equal(1, calls.userErrors)

      restoreCombat()
    end)

    it("treats the snap back re-entry with the stored size as a no-op during combat lockdown", function()
      local restoreCombat = wowStubs.install({
        InCombatLockdown = wowStubs.stubs.InCombatLockdown(true)
      })
      local slider = CreateFakeSlider(GEAR_BAR_ID)

      subMenu.GearSlotSizeSliderOnValueChanged(slider, STORED_SLOT_SIZE)

      assert.are.equal(0, #calls.slotSizes)
      assert.are.equal(0, #slider.setValues)
      assert.are.equal(0, calls.userErrors)

      restoreCombat()
    end)
  end)
end)
