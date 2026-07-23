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
  Spec for the gearSlot click handling in gui/GearBar.lua (me.SetupEvents,
  me.UpdateClickHandler, me.GearSlotOnClick). The modern ui engine executes the secure
  action of a button in a single direction only - chosen by the useOnKeyDown attribute
  respectively the ActionButtonUseKeyDown cvar as fallback - so gearSlots must register
  both click directions and map the fastpress option onto the useOnKeyDown attribute.
  GearSlotOnClick in turn gates its insecure work (combatQueue removal, theme feedback)
  to the phase that matches the fastpress configuration so it runs once per activation.

  gui/GearBar.lua has no load-time WoW api surface, so it can be dofile'd with the
  collaborator modules (configuration, combatQueue, themeCoordinator, gearBarStorage,
  logger) replaced by recorder / no-op stubs and gearSlots faked as recording tables.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

-- forward declarations
local CreateFakeGearSlot

--[[
  Build a fake gearSlot that records every widget call made against it

  @param {number} slotId
    the slotId returned for GetAttribute("item")

  @return {table}
    the fake gearSlot with `clicks`, `drags`, `scripts` and `attributes` recorders
]]--
CreateFakeGearSlot = function(slotId)
  local gearSlot = {
    slotId = slotId,
    clicks = {},     -- RegisterForClicks invocations
    drags = {},      -- RegisterForDrag invocations
    scripts = {},    -- scriptType -> handler
    attributes = {}  -- SetAttribute invocations
  }

  function gearSlot:RegisterForClicks(...)
    self.clicks[#self.clicks + 1] = { ... }
  end

  function gearSlot:RegisterForDrag(...)
    self.drags[#self.drags + 1] = { ... }
  end

  function gearSlot:SetScript(scriptType, handler)
    self.scripts[scriptType] = handler
  end

  function gearSlot:SetAttribute(name, value)
    self.attributes[#self.attributes + 1] = { name = name, value = value }
  end

  function gearSlot:GetAttribute(name)
    if name == "item" then
      return self.slotId
    end
  end

  return gearSlot
end

describe("GearBar click handling", function()
  local gearBar
  local previous
  local restore
  local calls
  local fastPress

  before_each(function()
    fastPress = false

    calls = {
      removedFromQueue = {},  -- combatQueue.RemoveFromQueue(slotId)
      themeClicks = {},       -- themeCoordinator.GearSlotOnClick(self, button)
      errorsLogged = 0
    }

    -- snapshot everything the load / functions touch so nothing leaks across specs
    previous = {
      gearBar = rggm.gearBar,
      configuration = rggm.configuration,
      combatQueue = rggm.combatQueue,
      themeCoordinator = rggm.themeCoordinator,
      gearBarStorage = rggm.gearBarStorage,
      logger = rggm.logger
    }

    rggm.configuration = {
      IsFastPressEnabled = function()
        return fastPress
      end
    }

    rggm.combatQueue = {
      RemoveFromQueue = function(slotId)
        calls.removedFromQueue[#calls.removedFromQueue + 1] = slotId
      end
    }

    rggm.themeCoordinator = {
      GearSlotOnClick = function(self, button)
        calls.themeClicks[#calls.themeClicks + 1] = { self = self, button = button }
      end
    }

    rggm.logger = {
      LogDebug = function() end,
      LogInfo = function() end,
      LogWarn = function() end,
      LogError = function() calls.errorsLogged = calls.errorsLogged + 1 end,
      PrintUserError = function() end
    }

    restore = wowStubs.install({
      InCombatLockdown = wowStubs.stubs.InCombatLockdown(false)
    })

    dofile("gui/GearBar.lua")
    gearBar = rggm.gearBar
  end)

  after_each(function()
    restore()

    rggm.gearBar = previous.gearBar
    rggm.configuration = previous.configuration
    rggm.combatQueue = previous.combatQueue
    rggm.themeCoordinator = previous.themeCoordinator
    rggm.gearBarStorage = previous.gearBarStorage
    rggm.logger = previous.logger
  end)

  describe("SetupEvents", function()
    it("registers both click directions for the left and the right button in a single call", function()
      local gearSlot = CreateFakeGearSlot(13)

      gearBar.SetupEvents(gearSlot)

      assert.are.equal(1, #gearSlot.clicks)
      assert.are.same(
        { "LeftButtonDown", "LeftButtonUp", "RightButtonDown", "RightButtonUp" },
        gearSlot.clicks[1]
      )
    end)

    it("sets useOnKeyDown to false when fastpress is disabled", function()
      local gearSlot = CreateFakeGearSlot(13)

      gearBar.SetupEvents(gearSlot)

      assert.are.equal(1, #gearSlot.attributes)
      assert.are.same({ name = "useOnKeyDown", value = false }, gearSlot.attributes[1])
    end)

    it("sets useOnKeyDown to true when fastpress is enabled", function()
      fastPress = true
      local gearSlot = CreateFakeGearSlot(13)

      gearBar.SetupEvents(gearSlot)

      assert.are.equal(1, #gearSlot.attributes)
      assert.are.same({ name = "useOnKeyDown", value = true }, gearSlot.attributes[1])
    end)
  end)

  describe("GearSlotOnClick with fastpress disabled", function()
    it("ignores the buttonDown phase", function()
      local gearSlot = CreateFakeGearSlot(13)

      gearBar.GearSlotOnClick(gearSlot, "RightButton", true)

      assert.are.equal(0, #calls.removedFromQueue)
      assert.are.equal(0, #calls.themeClicks)
    end)

    it("removes the queued item and notifies the theme on the buttonUp phase for the right button", function()
      local gearSlot = CreateFakeGearSlot(13)

      gearBar.GearSlotOnClick(gearSlot, "RightButton", false)

      assert.are.same({ 13 }, calls.removedFromQueue)
      assert.are.equal(1, #calls.themeClicks)
      assert.are.equal(gearSlot, calls.themeClicks[1].self)
      assert.are.equal("RightButton", calls.themeClicks[1].button)
    end)

    it("only notifies the theme on the buttonUp phase for the left button", function()
      local gearSlot = CreateFakeGearSlot(13)

      gearBar.GearSlotOnClick(gearSlot, "LeftButton", false)

      assert.are.equal(0, #calls.removedFromQueue)
      assert.are.equal(1, #calls.themeClicks)
      assert.are.equal("LeftButton", calls.themeClicks[1].button)
    end)
  end)

  describe("GearSlotOnClick with fastpress enabled", function()
    it("acts on the buttonDown phase and ignores the buttonUp phase", function()
      fastPress = true
      local gearSlot = CreateFakeGearSlot(13)

      gearBar.GearSlotOnClick(gearSlot, "RightButton", true)
      gearBar.GearSlotOnClick(gearSlot, "RightButton", false)

      assert.are.same({ 13 }, calls.removedFromQueue)
      assert.are.equal(1, #calls.themeClicks)
    end)
  end)

  describe("UpdateClickHandler", function()
    it("updates the useOnKeyDown attribute on every gearSlot of every gearBar", function()
      fastPress = true
      local slotOne = CreateFakeGearSlot(13)
      local slotTwo = CreateFakeGearSlot(14)
      local slotThree = CreateFakeGearSlot(16)

      rggm.gearBarStorage = {
        GetGearBars = function()
          return {
            { gearSlotReferences = { slotOne, slotTwo } },
            { gearSlotReferences = { slotThree } }
          }
        end
      }

      gearBar.UpdateClickHandler()

      for _, gearSlot in ipairs({ slotOne, slotTwo, slotThree }) do
        assert.are.equal(1, #gearSlot.attributes)
        assert.are.same({ name = "useOnKeyDown", value = true }, gearSlot.attributes[1])
      end
    end)

    it("does not update the attribute during combat lockdown", function()
      local restoreCombat = wowStubs.install({
        InCombatLockdown = wowStubs.stubs.InCombatLockdown(true)
      })

      local gearSlot = CreateFakeGearSlot(13)

      rggm.gearBarStorage = {
        GetGearBars = function()
          return { { gearSlotReferences = { gearSlot } } }
        end
      }

      gearBar.UpdateClickHandler()

      assert.are.equal(0, #gearSlot.attributes)
      assert.are.equal(1, calls.errorsLogged)

      restoreCombat()
    end)
  end)
end)
