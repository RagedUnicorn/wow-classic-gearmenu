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
  Spec for code/GearManager.lua, focused on GM-0021: GetGearSlotForSlotId must hand out an
  independent deep copy of the static gearSlots metadata so callers can mutate / persist it
  without aliasing the canonical table (two slots on the same slotId sharing one instance,
  or a keyBinding written onto the static entry).

  The static gearSlots table is built at file load: the off-hand entry runs an IIFE that calls
  UnitClass (and, only on the SHAMAN branch, rggm.season.IsSodActive). Both are stubbed before the
  dofile -- UnitClass returns a non-shaman class so the season path is skipped, but rggm.season is
  provided anyway for robustness. The real rggm.common.Clone (dofile'd from code/Common.lua) is used
  so the test exercises the actual copy path rather than a stand-in.

  busted runs each spec chunk sandboxed, so WoW-global stubs are written on _G (a bareword assignment
  would land in the sandbox, not the _G the dofile'd module sees). The rggm.* collaborators we install
  are snapshotted and restored in after_each so the shared namespace does not leak into other specs.
]]--

-- busted extends `assert` with .same / .equal / .are_not at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- WoW inventory slot ids are defined by test/headless/Bootstrap.lua at runtime
-- luacheck: globals INVSLOT_HEAD INVSLOT_TRINKET1
-- UnitClass is a WoW global stubbed on _G for the off-hand slot's load-time IIFE
-- luacheck: globals UnitClass
-- luacheck: ignore 143

describe("GearManager", function()
  local gearManager
  -- snapshot of the rggm.* collaborators and WoW globals we overwrite, restored in after_each
  local previousModules
  local previousUnitClass

  before_each(function()
    previousModules = {
      common = rggm.common,
      season = rggm.season
    }
    previousUnitClass = _G.UnitClass

    -- real deep-copy helper under test (defines rggm.common; no WoW deps at load)
    dofile("code/Common.lua")
    -- off-hand IIFE reads the player class at load; a non-shaman class skips the season branch
    _G.UnitClass = function() return "Warrior", "WARRIOR" end
    -- provided for robustness even though the non-shaman class avoids the IsSodActive call
    rggm.season = { IsSodActive = function() return false end }

    -- fresh module table (the dofile convention documented in test/headless/Bootstrap.lua); the
    -- static gearSlots table is rebuilt here, after the stubs above are in place
    dofile("code/GearManager.lua")
    gearManager = rggm.gearManager
  end)

  after_each(function()
    rggm.common = previousModules.common
    rggm.season = previousModules.season
    _G.UnitClass = previousUnitClass
  end)

  describe("GetGearSlotForSlotId", function()
    it("returns an independent copy on each call (never the shared static reference)", function()
      local first = gearManager.GetGearSlotForSlotId(INVSLOT_HEAD)
      local second = gearManager.GetGearSlotForSlotId(INVSLOT_HEAD)

      assert.is_not_nil(first)
      assert.is_not_nil(second)
      -- distinct table instances ...
      assert.are_not.equal(first, second)
      -- ... carrying equal data
      assert.are.same(first, second)
    end)

    it("returns a copy whose type subtable is also a distinct instance", function()
      local first = gearManager.GetGearSlotForSlotId(INVSLOT_HEAD)
      local second = gearManager.GetGearSlotForSlotId(INVSLOT_HEAD)

      assert.are_not.equal(first.type, second.type)
      assert.are.same(first.type, second.type)
    end)

    it("does not leak a mutation of the returned copy into the static metadata", function()
      local returned = gearManager.GetGearSlotForSlotId(INVSLOT_TRINKET1)
      -- this is exactly what the dropdown callback does before persisting the slot
      returned.keyBinding = "SHIFT-T"

      local fresh = gearManager.GetGearSlotForSlotId(INVSLOT_TRINKET1)
      assert.is_nil(fresh.keyBinding)
    end)

    it("returns nil when no gearSlot matches the slotId", function()
      assert.is_nil(gearManager.GetGearSlotForSlotId(-1))
    end)
  end)
end)
