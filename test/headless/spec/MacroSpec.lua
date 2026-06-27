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
  Spec for code/Macro.lua's CheckSlotValidity. The function resolves the valid gear slots for an
  equip slot through mod.gearManager.GetGearSlotsForType and returns whether the passed slotId is one
  of them. The collaborator is replaced with a recorder stub on the shared rggm namespace and restored
  in after_each so it does not leak into other specs (the pattern used by CombatQueueSpec).

  mod.logger.LogDebug is also stubbed: the real Logger.LogDebug reaches mod.filter and C_AddOns at
  LOG_LEVEL debug, neither of which the headless Bootstrap loads.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

describe("Macro", function()
  local macro
  -- per-test switches the stubs read at call time
  local gearSlots
  local lastRequestedEquipSlot
  -- snapshot of the rggm.* collaborators we overwrite, restored in after_each so the shared namespace
  -- (notably the real rggm.logger from Bootstrap) does not leak into other specs
  local previousModules

  before_each(function()
    gearSlots = {}
    lastRequestedEquipSlot = nil

    previousModules = {
      logger = rggm.logger,
      gearManager = rggm.gearManager
    }

    rggm.logger = { LogDebug = function() end }
    rggm.gearManager = {
      GetGearSlotsForType = function(equipSlot)
        lastRequestedEquipSlot = equipSlot
        return gearSlots
      end
    }

    dofile("code/Macro.lua")
    macro = rggm.macro
  end)

  after_each(function()
    rggm.logger = previousModules.logger
    rggm.gearManager = previousModules.gearManager
  end)

  describe("CheckSlotValidity", function()
    it("returns true when a returned gear slot matches the passed slotId", function()
      gearSlots = { { slotId = 13 }, { slotId = 14 } }

      assert.is_true(macro.CheckSlotValidity("INVTYPE_TRINKET", 14))
    end)

    it("returns false when no returned gear slot matches the passed slotId", function()
      gearSlots = { { slotId = 13 }, { slotId = 14 } }

      assert.is_false(macro.CheckSlotValidity("INVTYPE_TRINKET", 5))
    end)

    it("returns false when there are no valid gear slots for the equip slot", function()
      gearSlots = {}

      assert.is_false(macro.CheckSlotValidity("INVTYPE_TRINKET", 13))
    end)

    it("passes the equip slot through to GetGearSlotsForType", function()
      macro.CheckSlotValidity("INVTYPE_FINGER", 11)

      assert.are.equal("INVTYPE_FINGER", lastRequestedEquipSlot)
    end)
  end)
end)
