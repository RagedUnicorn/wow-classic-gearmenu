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
  Spec for code/GearBarManager.lua. The module is pure table manipulation -- it mutates the gearBars
  stored on the GearMenuConfiguration saved-variables global and reaches every UI side effect through
  mod.* collaborators -- so it can be driven entirely in memory with no WoW client.

  All bar/slot state lives on GearMenuConfiguration.gearBars (not file-local), so isolation is a
  fresh _G.GearMenuConfiguration = { gearBars = {} } in before_each rather than a re-dofile of the
  store. The module itself is still re-dofile'd (the convention documented in
  test/headless/Bootstrap.lua) so mod.gearBarManager points at a fresh table each test.

  busted runs each spec chunk in a sandboxed environment, so the saved-variables global is written as
  _G.GearMenuConfiguration (a bareword assignment would land in the sandbox, not the _G the dofile'd
  module sees). Collaborators reached via mod.* (logger, gearBar, gearManager, ticker, keyBind) are
  replaced with recorder stubs and restored in after_each so the shared rggm namespace -- notably the
  real rggm.logger from Bootstrap -- does not leak across specs.

  No WoW globals are stubbed: GearBarManager makes no direct Blizzard API calls.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- the WoW inventory slot ids used in fixtures are defined by test/headless/Bootstrap.lua at runtime
-- luacheck: globals INVSLOT_TRINKET1
-- luacheck: ignore 143

describe("GearBarManager", function()
  local gearBarManager
  local calls
  -- snapshot of the rggm.* collaborators we overwrite plus the saved-variables global, restored in
  -- after_each so neither the shared namespace nor _G leaks into other specs
  local previousModules
  local previousConfig

  --[[
    Add a bar (no default slot) and return its generated id for follow-up assertions.

    @param {string} displayName
    @return {number}
  ]]--
  local function addBar(displayName)
    return gearBarManager.AddGearBar(displayName or "TestBar", false).id
  end

  before_each(function()
    -- per-test recorder state for the UI / collaborator side effects
    calls = {
      updateLockedState = 0,
      updateKeyBindingState = 0,
      updateCooldowns = 0,
      updateGearSlots = 0,
      updateGearSlotSizes = 0,
      updateGearBarSize = 0,
      updateGearBars = 0,
      registerTicker = {},
      unregisterTicker = {},
      checkKeyBindingSlots = {},
      gearSlotsRequested = {}
    }

    previousModules = {
      logger = rggm.logger,
      gearBar = rggm.gearBar,
      gearManager = rggm.gearManager,
      ticker = rggm.ticker,
      keyBind = rggm.keyBind
    }
    -- snapshot the global the module mutates so it does not leak into other specs
    previousConfig = _G.GearMenuConfiguration

    -- fresh, empty saved-variables store (written on _G so the dofile'd module sees it)
    _G.GearMenuConfiguration = { gearBars = {} }

    -- collaborators reached via mod.* -> recorder stubs on the shared rggm namespace
    rggm.logger = {
      LogDebug = function() end,
      LogInfo = function() end,
      LogError = function() end
    }
    rggm.gearBar = {
      UpdateGearBarLockedState = function() calls.updateLockedState = calls.updateLockedState + 1 end,
      UpdateKeyBindingState = function() calls.updateKeyBindingState = calls.updateKeyBindingState + 1 end,
      UpdateGearBarGearSlotCooldowns = function() calls.updateCooldowns = calls.updateCooldowns + 1 end,
      UpdateGearBarGearSlots = function() calls.updateGearSlots = calls.updateGearSlots + 1 end,
      UpdateGearSlotSizes = function() calls.updateGearSlotSizes = calls.updateGearSlotSizes + 1 end,
      UpdateGearBarSize = function() calls.updateGearBarSize = calls.updateGearBarSize + 1 end,
      -- SetSlotKeyBinding passes a per-bar updater through this fan-out; record the invocation only
      UpdateGearBars = function() calls.updateGearBars = calls.updateGearBars + 1 end
    }
    -- AddGearSlot copies the default gearSlot's fields onto the new slot
    rggm.gearManager = {
      GetGearSlotForSlotId = function(slotId)
        calls.gearSlotsRequested[#calls.gearSlotsRequested + 1] = slotId
        return {
          name = "Head",
          type = { "INVTYPE_HEAD" },
          textureId = 12345,
          slotId = slotId
        }
      end
    }
    rggm.ticker = {
      RegisterForTickerRangeCheck = function(id) calls.registerTicker[#calls.registerTicker + 1] = id end,
      UnregisterForTickerRangeCheck = function(id) calls.unregisterTicker[#calls.unregisterTicker + 1] = id end
    }
    rggm.keyBind = {
      CheckKeyBindingSlots = function(id) calls.checkKeyBindingSlots[#calls.checkKeyBindingSlots + 1] = id end
    }

    -- fresh module table (mirrors the isolation convention used by the other specs)
    dofile("code/GearBarManager.lua")
    gearBarManager = rggm.gearBarManager
  end)

  after_each(function()
    rggm.logger = previousModules.logger
    rggm.gearBar = previousModules.gearBar
    rggm.gearManager = previousModules.gearManager
    rggm.ticker = previousModules.ticker
    rggm.keyBind = previousModules.keyBind
    _G.GearMenuConfiguration = previousConfig
  end)

  describe("AddGearBar", function()
    it("appends a bar carrying the documented defaults and returns it", function()
      local gearBar = gearBarManager.AddGearBar("MyBar", false)

      assert.are.equal(1, #_G.GearMenuConfiguration.gearBars)
      assert.are.equal(gearBar, _G.GearMenuConfiguration.gearBars[1])
      assert.are.equal("MyBar", gearBar.displayName)
      assert.is_false(gearBar.isLocked)
      assert.is_true(gearBar.showKeyBindings)
      assert.is_true(gearBar.showCooldowns)
      assert.are.same({}, gearBar.slots)
      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE, gearBar.gearSlotSize)
      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE, gearBar.changeSlotSize)
    end)

    it("seeds the default position from the constant", function()
      local gearBar = gearBarManager.AddGearBar("MyBar", false)

      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_POSITION[1], gearBar.position.point)
      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_POSITION[2], gearBar.position.posX)
      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_POSITION[3], gearBar.position.posY)
    end)

    it("generates a numeric id", function()
      local gearBar = gearBarManager.AddGearBar("MyBar", false)

      assert.is_number(gearBar.id)
    end)

    it("does not add a default slot when addDefaultSlot is false", function()
      local gearBar = gearBarManager.AddGearBar("MyBar", false)

      assert.are.equal(0, #gearBar.slots)
      assert.are.equal(0, #calls.gearSlotsRequested)
    end)

    it("adds a single default slot when addDefaultSlot is true", function()
      local gearBar = gearBarManager.AddGearBar("MyBar", true)

      assert.are.equal(1, #gearBar.slots)
      -- the default slot is added with init=true, so no gear bar ui update is triggered
      assert.are.equal(0, calls.updateGearSlots)
    end)

    it("keeps multiple bars independent in the store", function()
      gearBarManager.AddGearBar("BarA", false)
      gearBarManager.AddGearBar("BarB", false)

      assert.are.equal(2, #_G.GearMenuConfiguration.gearBars)
      assert.are.equal("BarA", _G.GearMenuConfiguration.gearBars[1].displayName)
      assert.are.equal("BarB", _G.GearMenuConfiguration.gearBars[2].displayName)
    end)
  end)

  describe("RemoveGearBar", function()
    it("removes the matching bar and leaves the rest", function()
      local idA = addBar("BarA")
      local idB = addBar("BarB")

      gearBarManager.RemoveGearBar(idA)

      assert.are.equal(1, #_G.GearMenuConfiguration.gearBars)
      assert.are.equal(idB, _G.GearMenuConfiguration.gearBars[1].id)
    end)

    it("is a no-op when no bar matches the id", function()
      addBar("BarA")

      gearBarManager.RemoveGearBar(99999999)

      assert.are.equal(1, #_G.GearMenuConfiguration.gearBars)
    end)
  end)

  describe("GetGearBar", function()
    it("returns the bar with the matching id", function()
      local id = addBar("BarA")

      local gearBar = gearBarManager.GetGearBar(id)

      assert.is_table(gearBar)
      assert.are.equal(id, gearBar.id)
    end)

    it("returns nil when no bar matches", function()
      assert.is_nil(gearBarManager.GetGearBar(99999999))
    end)
  end)

  describe("GetGearBars", function()
    it("returns the backing gearBars list", function()
      addBar("BarA")

      assert.are.equal(_G.GearMenuConfiguration.gearBars, gearBarManager.GetGearBars())
    end)
  end)

  describe("UpdateGearBarPosition", function()
    it("writes all five position fields onto the bar", function()
      local id = addBar("BarA")

      gearBarManager.UpdateGearBarPosition(id, "TOPLEFT", "UIParent", "CENTER", 42, -17)

      local position = gearBarManager.GetGearBar(id).position
      assert.are.equal("TOPLEFT", position.point)
      assert.are.equal("UIParent", position.relativeTo)
      assert.are.equal("CENTER", position.relativePoint)
      assert.are.equal(42, position.posX)
      assert.are.equal(-17, position.posY)
    end)
  end)

  describe("LockGearBar / UnlockGearBar / IsGearBarLocked", function()
    it("starts unlocked on a fresh bar", function()
      local id = addBar("BarA")

      assert.is_false(gearBarManager.IsGearBarLocked(id))
    end)

    it("locks the bar and notifies the ui", function()
      local id = addBar("BarA")

      gearBarManager.LockGearBar(id)

      assert.is_true(gearBarManager.IsGearBarLocked(id))
      assert.are.equal(1, calls.updateLockedState)
    end)

    it("unlocks a locked bar and notifies the ui", function()
      local id = addBar("BarA")
      gearBarManager.LockGearBar(id)

      gearBarManager.UnlockGearBar(id)

      assert.is_false(gearBarManager.IsGearBarLocked(id))
      assert.are.equal(2, calls.updateLockedState)
    end)
  end)

  describe("EnableShowKeyBindings / DisableShowKeyBindings / IsShowKeyBindingsEnabled", function()
    it("is enabled by default", function()
      local id = addBar("BarA")

      assert.is_true(gearBarManager.IsShowKeyBindingsEnabled(id))
    end)

    it("disabling clears the flag, updates the ui and unregisters the range-check ticker", function()
      local id = addBar("BarA")

      gearBarManager.DisableShowKeyBindings(id)

      assert.is_false(gearBarManager.IsShowKeyBindingsEnabled(id))
      assert.are.equal(1, calls.updateKeyBindingState)
      assert.are.same({ id }, calls.unregisterTicker)
    end)

    it("enabling sets the flag, updates the ui and registers the range-check ticker", function()
      local id = addBar("BarA")
      gearBarManager.DisableShowKeyBindings(id)

      gearBarManager.EnableShowKeyBindings(id)

      assert.is_true(gearBarManager.IsShowKeyBindingsEnabled(id))
      assert.are.same({ id }, calls.registerTicker)
    end)
  end)

  describe("EnableShowCooldowns / DisableShowCooldowns / IsShowCooldownsEnabled", function()
    it("is enabled by default", function()
      local id = addBar("BarA")

      assert.is_true(gearBarManager.IsShowCooldownsEnabled(id))
    end)

    it("disabling clears the flag and refreshes the cooldowns", function()
      local id = addBar("BarA")

      gearBarManager.DisableShowCooldowns(id)

      assert.is_false(gearBarManager.IsShowCooldownsEnabled(id))
      assert.are.equal(1, calls.updateCooldowns)
    end)

    it("enabling sets the flag and refreshes the cooldowns", function()
      local id = addBar("BarA")
      gearBarManager.DisableShowCooldowns(id)

      gearBarManager.EnableShowCooldowns(id)

      assert.is_true(gearBarManager.IsShowCooldownsEnabled(id))
      assert.are.equal(2, calls.updateCooldowns)
    end)
  end)

  describe("AddGearSlot", function()
    it("appends a slot populated from the default gearSlot and returns it", function()
      local id = addBar("BarA")

      local gearSlot = gearBarManager.AddGearSlot(id, false)

      assert.is_table(gearSlot)
      assert.are.equal("Head", gearSlot.name)
      assert.are.equal(12345, gearSlot.textureId)
      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_GEAR_SLOT_DEFAULT_VALUE, gearSlot.slotId)
      assert.are.equal(1, #gearBarManager.GetGearBar(id).slots)
    end)

    it("triggers a gear bar ui update when init is false", function()
      local id = addBar("BarA")

      gearBarManager.AddGearSlot(id, false)

      assert.are.equal(1, calls.updateGearSlots)
    end)

    it("does not trigger a ui update when init is true", function()
      local id = addBar("BarA")

      gearBarManager.AddGearSlot(id, true)

      assert.are.equal(0, calls.updateGearSlots)
    end)

    it("returns nil for an unknown gearBar id", function()
      assert.is_nil(gearBarManager.AddGearSlot(99999999, false))
    end)
  end)

  describe("RemoveGearSlot", function()
    it("removes the slot at the given position and returns true", function()
      local id = addBar("BarA")
      gearBarManager.AddGearSlot(id, true)
      gearBarManager.AddGearSlot(id, true)

      local result = gearBarManager.RemoveGearSlot(id, 1)

      assert.is_true(result)
      assert.are.equal(1, #gearBarManager.GetGearBar(id).slots)
    end)

    it("refreshes the gear bar, keybinding slots and keybinding state", function()
      local id = addBar("BarA")
      gearBarManager.AddGearSlot(id, true)

      gearBarManager.RemoveGearSlot(id, 1)

      assert.are.equal(1, calls.updateGearSlots)
      assert.are.same({ id }, calls.checkKeyBindingSlots)
      assert.are.equal(1, calls.updateKeyBindingState)
    end)

    it("returns false for an unknown gearBar id", function()
      assert.is_false(gearBarManager.RemoveGearSlot(99999999, 1))
    end)
  end)

  describe("GetGearSlot", function()
    it("returns the slot at the given position", function()
      local id = addBar("BarA")
      local added = gearBarManager.AddGearSlot(id, true)

      assert.are.equal(added, gearBarManager.GetGearSlot(id, 1))
    end)

    it("returns nil for an unknown gearBar id", function()
      assert.is_nil(gearBarManager.GetGearSlot(99999999, 1))
    end)
  end)

  describe("UpdateGearSlot", function()
    it("overwrites the slot at the position and returns true", function()
      local id = addBar("BarA")
      gearBarManager.AddGearSlot(id, true)
      local replacement = { name = "Trinket", slotId = INVSLOT_TRINKET1, type = {}, keyBinding = nil }

      local result = gearBarManager.UpdateGearSlot(id, 1, replacement, false)

      assert.is_true(result)
      assert.are.equal(replacement, gearBarManager.GetGearSlot(id, 1))
      assert.are.equal(1, calls.updateGearSlots)
    end)

    it("does not trigger a ui update when init is true", function()
      local id = addBar("BarA")
      gearBarManager.AddGearSlot(id, true)

      gearBarManager.UpdateGearSlot(id, 1, { slotId = INVSLOT_TRINKET1 }, true)

      assert.are.equal(0, calls.updateGearSlots)
    end)

    it("does nothing for a position that has no slot", function()
      local id = addBar("BarA")

      local result = gearBarManager.UpdateGearSlot(id, 1, { slotId = INVSLOT_TRINKET1 }, false)

      assert.is_nil(result)
      assert.are.equal(0, calls.updateGearSlots)
    end)
  end)

  describe("SetGearSlotSize / GetGearSlotSize", function()
    it("updates the size and resizes the gear bar frame", function()
      local id = addBar("BarA")

      gearBarManager.SetGearSlotSize(id, 50)

      assert.are.equal(50, gearBarManager.GetGearSlotSize(id))
      assert.are.equal(1, calls.updateGearSlotSizes)
      assert.are.equal(1, calls.updateGearBarSize)
    end)

    it("returns nil for an unknown gearBar id", function()
      assert.is_nil(gearBarManager.GetGearSlotSize(99999999))
    end)
  end)

  describe("SetChangeSlotSize / GetChangeSlotSize", function()
    it("updates the change slot size without a ui update", function()
      local id = addBar("BarA")

      gearBarManager.SetChangeSlotSize(id, 28)

      assert.are.equal(28, gearBarManager.GetChangeSlotSize(id))
      assert.are.equal(0, calls.updateGearSlots)
    end)

    it("returns nil for an unknown gearBar id", function()
      assert.is_nil(gearBarManager.GetChangeSlotSize(99999999))
    end)
  end)

  describe("SetSlotKeyBinding", function()
    it("writes the keybinding onto the slot and fans the update out across bars", function()
      local id = addBar("BarA")
      gearBarManager.AddGearSlot(id, true)

      gearBarManager.SetSlotKeyBinding(id, 1, "SHIFT-1")

      assert.are.equal("SHIFT-1", gearBarManager.GetGearSlot(id, 1).keyBinding)
      assert.are.equal(1, calls.updateGearBars)
    end)

    it("is a no-op when the slot position does not exist", function()
      local id = addBar("BarA")

      gearBarManager.SetSlotKeyBinding(id, 1, "SHIFT-1")

      assert.are.equal(0, calls.updateGearBars)
    end)
  end)
end)
