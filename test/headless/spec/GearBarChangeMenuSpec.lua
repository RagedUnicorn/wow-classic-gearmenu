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
  Spec for the refresh path of the changeMenu in gui/GearBarChangeMenu.lua (me.UpdateChangeMenu,
  me.UpdateChangeMenuProperties). A refresh without arguments - the debounced BAG_UPDATE refresh
  in code/ItemManager.lua - falls back to the gearBar the changeMenu was last opened for, which
  may have been deleted in the meantime.

  The changeMenu frame comes from a fake CreateFrame and the slot pool from a no-op stub, so
  me.BuildChangeMenu runs headlessly. The gearBars have no configured gearSlot at the hovered
  position, which keeps UpdateChangeMenu off the item and layout code that is not under test.
]]--

local wowStubs = require("WowStubs")

local GEAR_BAR_ID = 100001

--[[
  A frame that records whether it is shown and accepts the layout calls BuildChangeMenu makes
]]--
local function CreateFakeFrame()
  local frame = { shown = true }

  function frame.Hide(self) self.shown = false end
  function frame.Show(self) self.shown = true end
  function frame.IsMouseOver() return false end
  function frame.SetWidth() end
  function frame.SetHeight() end
  function frame.SetPoint() end
  function frame.SetBackdropColor() end
  function frame.SetBackdropBorderColor() end
  function frame.SetScript() end

  return frame
end

describe("GearBarChangeMenu refresh", function()
  local changeMenu
  local changeMenuFrame
  local restore
  local gearBars
  local calls

  before_each(function()
    gearBars = { [GEAR_BAR_ID] = { id = GEAR_BAR_ID, showCooldowns = true, slots = {} } }
    calls = { tickerStops = 0, warnings = {} }

    rggm.logger = {
      LogDebug = function() end,
      LogInfo = function() end,
      LogWarn = function(_, message) calls.warnings[#calls.warnings + 1] = message end
    }
    -- mirrors the real manager: an unknown id logs, and IsShowCooldownsEnabled indexes the result
    rggm.gearBarManager = {
      GetGearBar = function(gearBarId)
        if gearBars[gearBarId] == nil then
          rggm.logger.LogWarn("GearBarManager", "Could not find GearBar with id: " .. gearBarId)
        end

        return gearBars[gearBarId]
      end,
      IsShowCooldownsEnabled = function(gearBarId)
        return rggm.gearBarManager.GetGearBar(gearBarId).showCooldowns
      end,
      GetChangeSlotSize = function() return 32 end
    }
    rggm.common = { GetUiScale = function() return 1 end }
    rggm.gearBarStorage = { GetGearBar = function() return nil end }
    rggm.uiHelper = {
      CreateFramePool = function()
        return {
          Acquire = function() return CreateFakeFrame() end,
          ReleaseAll = function() end
        }
      end
    }
    rggm.ticker = {
      StartTickerChangeMenu = function() end,
      StopTickerChangeMenu = function() calls.tickerStops = calls.tickerStops + 1 end
    }

    restore = wowStubs.install({
      CreateFrame = function()
        changeMenuFrame = CreateFakeFrame()

        return changeMenuFrame
      end
    })

    dofile("gui/GearBarChangeMenu.lua")
    changeMenu = rggm.gearBarChangeMenu
    changeMenu.BuildChangeMenu()
  end)

  after_each(function()
    restore()
  end)

  it("remembers the hovered gearBar and gearSlot for a later refresh", function()
    changeMenu.UpdateChangeMenu(1, GEAR_BAR_ID)

    assert.are.equal(GEAR_BAR_ID, changeMenuFrame.gearBarId)
    assert.are.equal(1, changeMenuFrame.gearSlotPosition)
    assert.is_true(changeMenuFrame.showCooldowns)

    changeMenu.UpdateChangeMenu()

    assert.are.equal(0, calls.tickerStops)
    assert.are.same({}, calls.warnings)
  end)

  it("closes the changeMenu instead of raising when its gearBar was deleted", function()
    changeMenu.UpdateChangeMenu(1, GEAR_BAR_ID)
    changeMenuFrame:Show()
    gearBars[GEAR_BAR_ID] = nil

    assert.has_no.errors(function() changeMenu.UpdateChangeMenu() end)

    assert.is_false(changeMenuFrame.shown)
    assert.are.equal(1, calls.tickerStops)
    assert.is_nil(changeMenuFrame.gearBarId)
    assert.is_nil(changeMenuFrame.gearSlotPosition)
  end)

  it("stays quiet on later refreshes once the deleted gearBar was forgotten", function()
    changeMenu.UpdateChangeMenu(1, GEAR_BAR_ID)
    gearBars[GEAR_BAR_ID] = nil
    changeMenu.UpdateChangeMenu()
    calls.warnings = {}

    assert.has_no.errors(function() changeMenu.UpdateChangeMenu() end)

    assert.are.same({}, calls.warnings)
  end)

  it("closes the changeMenu for a refresh before any gearSlot was hovered", function()
    assert.has_no.errors(function() changeMenu.UpdateChangeMenu() end)

    assert.are.equal(1, calls.tickerStops)
  end)
end)
