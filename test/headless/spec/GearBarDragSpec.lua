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
  Spec for moving a gearBar frame in gui/GearBar.lua (me.StartDragFrame, me.StopDragFrame,
  me.StopPendingDragFrames).

  The gearBarFrame is the anchor parent of its gearSlots, which inherit from the
  SecureActionButtonTemplate. Moving a frame that protected frames are anchored to is a protected
  operation, so a drag must be refused during combat lockdown and a drag that combat interrupts
  must be finished once the player leaves combat instead of on the (in combat) mouse up.

  gui/GearBar.lua has no load-time WoW api surface, so it can be dofile'd with the collaborator
  modules (gearBarManager, gearBarStorage, logger) replaced by recorder / no-op stubs and the
  gearBarFrame faked as a recording table.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

local GEAR_BAR_ID = 1

-- forward declarations
local CreateFakeGearBarFrame

--[[
  Build a fake gearBarFrame that records every widget call made against it

  @param {number} id
    the gearBar id the frame represents

  @return {table}
    the fake gearBarFrame with `startMoving` and `stopMoving` counters
]]--
CreateFakeGearBarFrame = function(id)
  local gearBarFrame = {
    id = id,
    startMoving = 0,
    stopMoving = 0
  }

  function gearBarFrame:StartMoving()
    self.startMoving = self.startMoving + 1
  end

  function gearBarFrame:StopMovingOrSizing()
    self.stopMoving = self.stopMoving + 1
  end

  function gearBarFrame.GetPoint()
    return "CENTER", nil, "CENTER", 10, -20
  end

  return gearBarFrame
end

describe("GearBar drag handling", function()
  local gearBar
  local previous
  local restore
  local calls
  local locked
  local uiGearBars

  before_each(function()
    locked = false
    uiGearBars = {}

    calls = {
      positionUpdates = {}, -- gearBarManager.UpdateGearBarPosition(id, point, relativeTo, relativePoint, posX, posY)
      userErrors = 0        -- logger.PrintUserError(msg)
    }

    -- snapshot everything the load / functions touch so nothing leaks across specs
    previous = {
      gearBar = rggm.gearBar,
      gearBarManager = rggm.gearBarManager,
      gearBarStorage = rggm.gearBarStorage,
      logger = rggm.logger,
      L = rggm.L
    }

    rggm.L = {
      gear_bar_move_combat = "gear_bar_move_combat"
    }

    rggm.gearBarManager = {
      IsGearBarLocked = function()
        return locked
      end,
      UpdateGearBarPosition = function(id, point, relativeTo, relativePoint, posX, posY)
        calls.positionUpdates[#calls.positionUpdates + 1] = {
          id = id, point = point, relativeTo = relativeTo, relativePoint = relativePoint, posX = posX, posY = posY
        }
      end
    }

    rggm.gearBarStorage = {
      GetGearBars = function()
        return uiGearBars
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

    dofile("gui/GearBar.lua")
    gearBar = rggm.gearBar
  end)

  after_each(function()
    restore()

    rggm.gearBar = previous.gearBar
    rggm.gearBarManager = previous.gearBarManager
    rggm.gearBarStorage = previous.gearBarStorage
    rggm.logger = previous.logger
    rggm.L = previous.L
  end)

  describe("StartDragFrame", function()
    it("starts moving an unlocked gearBar out of combat", function()
      local gearBarFrame = CreateFakeGearBarFrame(GEAR_BAR_ID)

      gearBar.StartDragFrame(gearBarFrame)

      assert.are.equal(1, gearBarFrame.startMoving)
      assert.is_true(gearBarFrame.isMoving)
      assert.are.equal(0, calls.userErrors)
    end)

    it("does nothing for a locked gearBar", function()
      locked = true
      local gearBarFrame = CreateFakeGearBarFrame(GEAR_BAR_ID)

      gearBar.StartDragFrame(gearBarFrame)

      assert.are.equal(0, gearBarFrame.startMoving)
      assert.is_nil(gearBarFrame.isMoving)
      assert.are.equal(0, calls.userErrors)
    end)

    it("refuses to move the gearBar during combat lockdown and tells the user", function()
      local restoreCombat = wowStubs.install({
        InCombatLockdown = wowStubs.stubs.InCombatLockdown(true)
      })
      local gearBarFrame = CreateFakeGearBarFrame(GEAR_BAR_ID)

      gearBar.StartDragFrame(gearBarFrame)

      assert.are.equal(0, gearBarFrame.startMoving)
      assert.is_nil(gearBarFrame.isMoving)
      assert.are.equal(1, calls.userErrors)

      restoreCombat()
    end)
  end)

  describe("StopDragFrame", function()
    it("stops a moving gearBar and persists its new position", function()
      local gearBarFrame = CreateFakeGearBarFrame(GEAR_BAR_ID)
      gearBar.StartDragFrame(gearBarFrame)

      gearBar.StopDragFrame(gearBarFrame)

      assert.are.equal(1, gearBarFrame.stopMoving)
      assert.is_false(gearBarFrame.isMoving)
      assert.are.equal(1, #calls.positionUpdates)
      assert.are.same({
        id = GEAR_BAR_ID, point = "CENTER", relativeTo = nil, relativePoint = "CENTER", posX = 10, posY = -20
      }, calls.positionUpdates[1])
    end)

    it("does nothing for a gearBar that was never started moving", function()
      local gearBarFrame = CreateFakeGearBarFrame(GEAR_BAR_ID)

      gearBar.StopDragFrame(gearBarFrame)

      assert.are.equal(0, gearBarFrame.stopMoving)
      assert.are.equal(0, #calls.positionUpdates)
    end)

    it("does nothing for a drag that was refused because of combat", function()
      local restoreCombat = wowStubs.install({
        InCombatLockdown = wowStubs.stubs.InCombatLockdown(true)
      })
      local gearBarFrame = CreateFakeGearBarFrame(GEAR_BAR_ID)
      gearBar.StartDragFrame(gearBarFrame)
      restoreCombat()

      gearBar.StopDragFrame(gearBarFrame)

      assert.are.equal(0, gearBarFrame.stopMoving)
      assert.are.equal(0, #calls.positionUpdates)
    end)

    it("keeps a drag that combat interrupted pending and tells the user", function()
      local gearBarFrame = CreateFakeGearBarFrame(GEAR_BAR_ID)
      gearBar.StartDragFrame(gearBarFrame)
      local restoreCombat = wowStubs.install({
        InCombatLockdown = wowStubs.stubs.InCombatLockdown(true)
      })

      gearBar.StopDragFrame(gearBarFrame)

      assert.are.equal(0, gearBarFrame.stopMoving)
      assert.is_true(gearBarFrame.isMoving)
      assert.are.equal(0, #calls.positionUpdates)
      assert.are.equal(1, calls.userErrors)

      restoreCombat()
    end)
  end)

  describe("StopPendingDragFrames", function()
    it("finishes only the drags that are still pending once combat ends", function()
      local pending = CreateFakeGearBarFrame(1)
      local idle = CreateFakeGearBarFrame(2)
      local finished = CreateFakeGearBarFrame(3)
      uiGearBars = {
        { gearBarReference = pending },
        { gearBarReference = idle },
        { gearBarReference = finished }
      }

      gearBar.StartDragFrame(pending)
      gearBar.StartDragFrame(finished)
      gearBar.StopDragFrame(finished)

      gearBar.StopPendingDragFrames()

      assert.are.equal(1, pending.stopMoving)
      assert.is_false(pending.isMoving)
      assert.are.equal(0, idle.stopMoving)
      assert.are.equal(1, finished.stopMoving)
      assert.are.equal(2, #calls.positionUpdates)
      assert.are.equal(3, calls.positionUpdates[1].id)
      assert.are.equal(1, calls.positionUpdates[2].id)
    end)

    it("is a no-op when no gearBar is moving", function()
      uiGearBars = { { gearBarReference = CreateFakeGearBarFrame(GEAR_BAR_ID) } }

      gearBar.StopPendingDragFrames()

      assert.are.equal(0, #calls.positionUpdates)
    end)
  end)
end)
