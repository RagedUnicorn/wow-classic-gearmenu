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
  Spec for the tracked target in code/Target.lua (me.UpdateCurrentTarget,
  me.GetCurrentTargetGuid). gui/GearBar.lua reads the guid to tell whether the player has a
  target at all, so a target that was cleared must not leave its guid behind.

  CoreInitializeSpec covers the seeding on login; this spec covers the updates that
  PLAYER_TARGET_CHANGED drives afterwards. UnitGUID is stubbed per test.
]]--

local wowStubs = require("WowStubs")

local FIRST_GUID = "Player-1234-00ABCDEF"
local SECOND_GUID = "Creature-0-1234-0-0-5678-0000ABCDEF"

describe("Target", function()
  local target
  local targetGuid
  local queriedUnits
  local previousLogger
  local restore

  before_each(function()
    targetGuid = nil
    queriedUnits = {}

    previousLogger = rggm.logger
    rggm.logger = { LogDebug = function() end }

    restore = wowStubs.install({
      UnitGUID = function(unit)
        queriedUnits[#queriedUnits + 1] = unit
        return targetGuid
      end
    })

    -- fresh file-local target state
    dofile("code/Target.lua")
    target = rggm.target
  end)

  after_each(function()
    restore()
    rggm.logger = previousLogger
  end)

  it("starts without a target before the first update", function()
    assert.are.equal("", target.GetCurrentTargetGuid())
  end)

  it("reads the guid of the target unit", function()
    targetGuid = FIRST_GUID

    target.UpdateCurrentTarget()

    assert.are.same({ RGGM_CONSTANTS.UNIT_ID_TARGET }, queriedUnits)
    assert.are.equal(FIRST_GUID, target.GetCurrentTargetGuid())
  end)

  it("follows the player to a new target", function()
    targetGuid = FIRST_GUID
    target.UpdateCurrentTarget()

    targetGuid = SECOND_GUID
    target.UpdateCurrentTarget()

    assert.are.equal(SECOND_GUID, target.GetCurrentTargetGuid())
  end)

  it("forgets the previous guid once the target is cleared", function()
    targetGuid = FIRST_GUID
    target.UpdateCurrentTarget()

    targetGuid = nil
    target.UpdateCurrentTarget()

    assert.are.equal("", target.GetCurrentTargetGuid())
  end)
end)
