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
  Pilot spec for code/CombatQueue.lua. Exercises the queue-store logic (AddToQueue, RemoveFromQueue,
  IsCombatQueueEmpty, GetCombatQueueStore) plus ProcessQueue and UpdateEquipChangeBlockStatus.

  combatQueueStore is a file-local table, so before_each re-dofiles the module to get a fresh,
  empty store (the isolation mechanism documented in test/headless/Bootstrap.lua). All collaborators
  reached through mod.* are replaced with recorder stubs on the shared rggm namespace; the WoW
  globals InCombatLockdown and C_LossOfControl come from the test/headless/WowStubs.lua registry.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("CombatQueue", function()
  local combatQueue
  local calls
  local inCombat, isCasting, isDead
  local restore
  -- snapshot of the rggm.* collaborators we overwrite, restored in after_each so the shared
  -- namespace (notably the real rggm.logger from Bootstrap) does not leak into other specs
  local previousModules

  before_each(function()
    -- per-test recorder state and collaborator switches
    calls = {
      updateCombatQueue = { count = 0, last = nil },
      startTicker = 0,
      stopTicker = 0,
      equipped = {}
    }
    inCombat, isCasting, isDead = false, false, false

    previousModules = {
      logger = rggm.logger,
      gearBar = rggm.gearBar,
      ticker = rggm.ticker,
      common = rggm.common,
      gearManager = rggm.gearManager,
      itemManager = rggm.itemManager
    }

    -- collaborators reached via mod.* -> recorder stubs on the shared rggm namespace
    rggm.logger = { LogDebug = function() end }
    rggm.gearBar = {
      UpdateCombatQueue = function(itemId, enchantId, runeAbilityId, slotId)
        calls.updateCombatQueue.count = calls.updateCombatQueue.count + 1
        calls.updateCombatQueue.last = {
          itemId = itemId,
          enchantId = enchantId,
          runeAbilityId = runeAbilityId,
          slotId = slotId
        }
      end
    }
    rggm.ticker = {
      StartTickerCombatQueue = function() calls.startTicker = calls.startTicker + 1 end,
      StopTickerCombatQueue = function() calls.stopTicker = calls.stopTicker + 1 end
    }
    rggm.common = {
      IsPlayerCasting = function() return isCasting end,
      IsPlayerReallyDead = function() return isDead end
    }
    rggm.gearManager = {
      GetGearSlots = function() return {} end
    }
    rggm.itemManager = {
      EquipItemByItemAndEnchantId = function(item)
        calls.equipped[#calls.equipped + 1] = item
      end
    }

    -- WoW globals; InCombatLockdown reads the local `inCombat` switch at call time
    restore = wowStubs.install({
      InCombatLockdown = function() return inCombat end,
      C_LossOfControl = wowStubs.stubs.C_LossOfControl({})
    })

    -- fresh module table with an empty combatQueueStore (clears file-local state)
    dofile("code/CombatQueue.lua")
    combatQueue = rggm.combatQueue
  end)

  after_each(function()
    restore()

    rggm.logger = previousModules.logger
    rggm.gearBar = previousModules.gearBar
    rggm.ticker = previousModules.ticker
    rggm.common = previousModules.common
    rggm.gearManager = previousModules.gearManager
    rggm.itemManager = previousModules.itemManager
  end)

  describe("GetCombatQueueStore", function()
    it("returns a table", function()
      assert.is_table(combatQueue.GetCombatQueueStore())
    end)

    it("is empty on a freshly loaded module", function()
      assert.is_nil(next(combatQueue.GetCombatQueueStore()))
    end)
  end)

  describe("AddToQueue", function()
    it("stores the item keyed by slotId as {itemId, enchantId, runeAbilityId}", function()
      combatQueue.AddToQueue(12345, 60, 7, 5)

      local entry = combatQueue.GetCombatQueueStore()[5]
      assert.is_table(entry)
      assert.are.equal(12345, entry[1])
      assert.are.equal(60, entry[2])
      assert.are.equal(7, entry[3])
    end)

    it("stores nil enchantId and runeAbilityId", function()
      combatQueue.AddToQueue(12345, nil, nil, 5)

      local entry = combatQueue.GetCombatQueueStore()[5]
      assert.are.equal(12345, entry[1])
      assert.is_nil(entry[2])
      assert.is_nil(entry[3])
    end)

    it("keeps only one item per slot (overwrites)", function()
      combatQueue.AddToQueue(111, nil, nil, 5)
      combatQueue.AddToQueue(222, nil, nil, 5)

      assert.are.equal(222, combatQueue.GetCombatQueueStore()[5][1])
    end)

    it("is a no-op when itemId is nil", function()
      combatQueue.AddToQueue(nil, nil, nil, 5)

      assert.is_true(combatQueue.IsCombatQueueEmpty())
      assert.are.equal(0, calls.updateCombatQueue.count)
      assert.are.equal(0, calls.startTicker)
    end)

    it("is a no-op when slotId is nil", function()
      combatQueue.AddToQueue(12345, nil, nil, nil)

      assert.is_true(combatQueue.IsCombatQueueEmpty())
      assert.are.equal(0, calls.updateCombatQueue.count)
      assert.are.equal(0, calls.startTicker)
    end)

    it("notifies the gear bar and starts the ticker", function()
      combatQueue.AddToQueue(12345, nil, nil, 5)

      assert.are.equal(1, calls.updateCombatQueue.count)
      assert.are.equal(12345, calls.updateCombatQueue.last.itemId)
      assert.are.equal(5, calls.updateCombatQueue.last.slotId)
      assert.are.equal(1, calls.startTicker)
    end)
  end)

  describe("RemoveFromQueue", function()
    it("removes the queued item for the slot", function()
      combatQueue.AddToQueue(12345, nil, nil, 5)
      combatQueue.RemoveFromQueue(5)

      assert.is_nil(combatQueue.GetCombatQueueStore()[5])
      assert.is_true(combatQueue.IsCombatQueueEmpty())
    end)

    it("notifies the gear bar with nils on a real removal", function()
      combatQueue.AddToQueue(12345, nil, nil, 5)
      combatQueue.RemoveFromQueue(5)

      assert.is_nil(calls.updateCombatQueue.last.itemId)
      assert.are.equal(5, calls.updateCombatQueue.last.slotId)
    end)

    it("is a no-op (no gear bar call) when the slot has no queued item", function()
      combatQueue.RemoveFromQueue(7)

      assert.are.equal(0, calls.updateCombatQueue.count)
    end)

    it("is a no-op when slotId is nil", function()
      combatQueue.RemoveFromQueue(nil)

      assert.are.equal(0, calls.updateCombatQueue.count)
    end)
  end)

  describe("IsCombatQueueEmpty", function()
    it("is true when nothing is queued", function()
      assert.is_true(combatQueue.IsCombatQueueEmpty())
    end)

    it("is false once an item is queued", function()
      combatQueue.AddToQueue(12345, nil, nil, 5)

      assert.is_false(combatQueue.IsCombatQueueEmpty())
    end)
  end)

  describe("store isolation between it() blocks", function()
    it("queues an item in the first block", function()
      combatQueue.AddToQueue(12345, nil, nil, 5)

      assert.is_false(combatQueue.IsCombatQueueEmpty())
    end)

    it("does not see the previous block's item", function()
      assert.is_true(combatQueue.IsCombatQueueEmpty())
      assert.is_nil(combatQueue.GetCombatQueueStore()[5])
    end)
  end)

  describe("ProcessQueue", function()
    it("stops the ticker and equips nothing when the queue is empty", function()
      combatQueue.ProcessQueue()

      assert.are.equal(1, calls.stopTicker)
      assert.are.equal(0, #calls.equipped)
    end)

    it("does not equip while in combat", function()
      combatQueue.AddToQueue(12345, nil, nil, 5)
      rggm.gearManager.GetGearSlots = function() return { { slotId = 5 } } end
      inCombat = true

      combatQueue.ProcessQueue()

      assert.are.equal(0, #calls.equipped)
    end)

    it("does not equip while casting", function()
      combatQueue.AddToQueue(12345, nil, nil, 5)
      rggm.gearManager.GetGearSlots = function() return { { slotId = 5 } } end
      isCasting = true

      combatQueue.ProcessQueue()

      assert.are.equal(0, #calls.equipped)
    end)

    it("does not equip while really dead", function()
      combatQueue.AddToQueue(12345, nil, nil, 5)
      rggm.gearManager.GetGearSlots = function() return { { slotId = 5 } } end
      isDead = true

      combatQueue.ProcessQueue()

      assert.are.equal(0, #calls.equipped)
    end)

    it("equips the queued item for a matching gear slot when unblocked", function()
      combatQueue.AddToQueue(12345, 60, 7, 5)
      rggm.gearManager.GetGearSlots = function() return { { slotId = 5 } } end

      combatQueue.ProcessQueue()

      assert.are.equal(1, #calls.equipped)
      local item = calls.equipped[1]
      assert.are.equal(12345, item.itemId)
      assert.are.equal(60, item.enchantId)
      assert.are.equal(7, item.runeAbilityId)
      assert.are.equal(5, item.slotId)
    end)
  end)

  describe("UpdateEquipChangeBlockStatus / IsEquipChangeBlocked", function()
    --[[
      Installs a C_LossOfControl stub reporting `events` for the duration of `fn`, then restores it.
    ]]--
    local function withLossOfControl(events, fn)
      local restoreLoc = wowStubs.install({
        C_LossOfControl = wowStubs.stubs.C_LossOfControl(events)
      })
      fn()
      restoreLoc()
    end

    it("blocks equipment changes on a relevant locType (STUN)", function()
      withLossOfControl({ { locType = "STUN" } }, function()
        combatQueue.UpdateEquipChangeBlockStatus()
      end)

      assert.is_true(combatQueue.IsEquipChangeBlocked())
    end)

    it("does not block on an irrelevant locType (ROOT) and restarts the ticker", function()
      withLossOfControl({ { locType = "ROOT" } }, function()
        combatQueue.UpdateEquipChangeBlockStatus()
      end)

      assert.is_false(combatQueue.IsEquipChangeBlocked())
      assert.are.equal(1, calls.startTicker)
    end)

    it("does not block when there are no active loss-of-control events", function()
      withLossOfControl({}, function()
        combatQueue.UpdateEquipChangeBlockStatus()
      end)

      assert.is_false(combatQueue.IsEquipChangeBlocked())
    end)
  end)
end)
