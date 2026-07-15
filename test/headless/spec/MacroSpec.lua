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
  Spec for code/Macro.lua. Covers:

    - CheckSlotValidity: resolves the valid gear slots for an equip slot through
      mod.gearManager.GetGearSlotsForType and returns whether the passed slotId is one of them.
    - CheckItemIdValidity: resolves an itemId to its equip slot through the cache-free
      C_Item.GetItemInfoInstant (4th return), so valid-but-uncached ids work immediately; prints a
      user chat error and returns nil for unknown / non-equippable ids.
    - The public macro globals GM_AddToCombatQueue / GM_RemoveFromCombatQueue: graceful type guards
      that print a localized chat error (rggm.L["macro_invalid_argument"]) and return instead of
      raising a raw Lua assert error, and otherwise forward to mod.combatQueue.
    - The public swap-listener surface GM_RegisterSwapListener / GM_UnregisterSwapListener and the
      FireSwapEvent dispatcher: registration type guard, dispatch order and payload, duplicate
      registration as a no-op, deregistration, and pcall isolation of a throwing listener (the
      error is routed to mod.logger.LogError and remaining listeners still run).

  The collaborators (logger, gearManager, combatQueue) are replaced with recorder stubs on the shared
  rggm namespace and restored in after_each so they do not leak into other specs (the pattern used by
  CombatQueueSpec). C_Item is installed as a WoW global via the WowStubs registry for the duration of
  each test.

  mod.logger.LogDebug is stubbed: the real Logger.LogDebug reaches mod.filter and C_AddOns at
  LOG_LEVEL debug, neither of which the headless Bootstrap loads. rggm.L is stubbed with just the keys
  the code under test formats, so the spec does not depend on the localization files being loaded.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: globals GM_AddToCombatQueue GM_RemoveFromCombatQueue
-- luacheck: globals GM_RegisterSwapListener GM_UnregisterSwapListener
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("Macro", function()
  local macro
  -- per-test switches the stubs read at call time
  local gearSlots
  local lastRequestedEquipSlot
  -- recorders populated by the stubbed collaborators
  local chatErrors
  local queueAdds
  local queueRemoves
  local loggedErrors
  -- snapshot of the rggm.* collaborators we overwrite, restored in after_each so the shared namespace
  -- (notably the real rggm.logger from Bootstrap) does not leak into other specs
  local previousModules
  -- restore function for the installed C_Item global
  local restoreGlobals

  before_each(function()
    gearSlots = {}
    lastRequestedEquipSlot = nil
    chatErrors = {}
    queueAdds = {}
    queueRemoves = {}
    loggedErrors = {}

    previousModules = {
      logger = rggm.logger,
      gearManager = rggm.gearManager,
      combatQueue = rggm.combatQueue,
      L = rggm.L
    }

    rggm.logger = {
      LogDebug = function() end,
      LogError = function(_, message)
        loggedErrors[#loggedErrors + 1] = message
      end,
      PrintUserChatError = function(message)
        chatErrors[#chatErrors + 1] = message
      end
    }
    rggm.gearManager = {
      GetGearSlotsForType = function(equipSlot)
        lastRequestedEquipSlot = equipSlot
        return gearSlots
      end
    }
    rggm.combatQueue = {
      AddToQueue = function(itemId, enchantId, runeAbilityId, slotId)
        queueAdds[#queueAdds + 1] = { itemId, enchantId, runeAbilityId, slotId }
      end,
      RemoveFromQueue = function(slotId)
        queueRemoves[#queueRemoves + 1] = slotId
      end
    }
    rggm.L = {
      unable_to_find_item = "unable_to_find_item %s",
      unable_to_find_equipslot = "unable_to_find_equipslot %s",
      macro_invalid_argument = "bad argument #%s to '%s' (expected number got %s)",
      macro_invalid_listener = "bad argument #1 to '%s' (expected function got %s)"
    }

    -- GetItemInfoInstant shape: itemID, itemType, itemSubType, itemEquipLoc (4th = equip slot).
    -- 1000 -> equippable trinket, 2000 -> valid but non-equippable (empty equip slot), unknown -> nil.
    restoreGlobals = wowStubs.install({
      C_Item = wowStubs.stubs.C_Item({}, {
        [1000] = { 1000, nil, nil, "INVTYPE_TRINKET" },
        [2000] = { 2000, nil, nil, "" }
      })
    })

    dofile("code/Macro.lua")
    macro = rggm.macro
  end)

  after_each(function()
    restoreGlobals()
    rggm.logger = previousModules.logger
    rggm.gearManager = previousModules.gearManager
    rggm.combatQueue = previousModules.combatQueue
    rggm.L = previousModules.L
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

  describe("CheckItemIdValidity", function()
    it("returns the equip slot from GetItemInfoInstant for a valid itemId", function()
      assert.are.equal("INVTYPE_TRINKET", macro.CheckItemIdValidity(1000))
      assert.are.equal(0, #chatErrors)
    end)

    it("returns nil and prints a chat error for an unknown itemId (nil equip slot)", function()
      assert.is_nil(macro.CheckItemIdValidity(9999))
      assert.are.equal(1, #chatErrors)
    end)

    it("returns nil and prints a chat error for a non-equippable itemId (empty equip slot)", function()
      assert.is_nil(macro.CheckItemIdValidity(2000))
      assert.are.equal(1, #chatErrors)
    end)
  end)

  describe("GM_AddToCombatQueue", function()
    it("queues a valid swap and does not print an error", function()
      gearSlots = { { slotId = 13 }, { slotId = 14 } }

      GM_AddToCombatQueue(1000, 0, 0, 13)

      assert.are.equal(1, #queueAdds)
      assert.are.same({ 1000, 0, 0, 13 }, queueAdds[1])
      assert.are.equal(0, #chatErrors)
    end)

    it("allows nil optional enchantId and runeAbilityId", function()
      gearSlots = { { slotId = 13 } }

      GM_AddToCombatQueue(1000, nil, nil, 13)

      assert.are.equal(1, #queueAdds)
      assert.are.equal(0, #chatErrors)
    end)

    it("rejects a non-number itemId with a chat error and does not queue", function()
      GM_AddToCombatQueue("x", 0, 0, 13)

      assert.are.equal(0, #queueAdds)
      assert.are.equal(1, #chatErrors)
      assert.is_truthy(chatErrors[1]:find("#1", 1, true))
      assert.is_truthy(chatErrors[1]:find("GM_AddToCombatQueue", 1, true))
    end)

    it("rejects a non-number enchantId with a chat error and does not queue", function()
      GM_AddToCombatQueue(1000, "x", 0, 13)

      assert.are.equal(0, #queueAdds)
      assert.are.equal(1, #chatErrors)
      assert.is_truthy(chatErrors[1]:find("#2", 1, true))
    end)

    it("rejects a non-number runeAbilityId with a chat error and does not queue", function()
      GM_AddToCombatQueue(1000, 0, "x", 13)

      assert.are.equal(0, #queueAdds)
      assert.are.equal(1, #chatErrors)
      assert.is_truthy(chatErrors[1]:find("#3", 1, true))
    end)

    it("rejects a non-number slotId with a chat error and does not queue", function()
      GM_AddToCombatQueue(1000, 0, 0, "x")

      assert.are.equal(0, #queueAdds)
      assert.are.equal(1, #chatErrors)
      assert.is_truthy(chatErrors[1]:find("#4", 1, true))
    end)
  end)

  describe("GM_RemoveFromCombatQueue", function()
    it("removes a valid slotId", function()
      GM_RemoveFromCombatQueue(13)

      assert.are.equal(1, #queueRemoves)
      assert.are.equal(13, queueRemoves[1])
      assert.are.equal(0, #chatErrors)
    end)

    it("rejects a non-number slotId with a chat error and does not remove", function()
      GM_RemoveFromCombatQueue("x")

      assert.are.equal(0, #queueRemoves)
      assert.are.equal(1, #chatErrors)
      assert.is_truthy(chatErrors[1]:find("GM_RemoveFromCombatQueue", 1, true))
    end)
  end)

  describe("GM_RegisterSwapListener", function()
    it("delivers fired swap events to a registered listener", function()
      local received = {}

      GM_RegisterSwapListener(function(eventName, slotId, itemId)
        received[#received + 1] = { eventName = eventName, slotId = slotId, itemId = itemId }
      end)

      macro.FireSwapEvent(RGGM_CONSTANTS.SWAP_EVENT_QUEUED, 13, 1000)

      assert.are.equal(1, #received)
      assert.are.same({
        eventName = RGGM_CONSTANTS.SWAP_EVENT_QUEUED,
        slotId = 13,
        itemId = 1000
      }, received[1])
    end)

    it("rejects a non-function callback with a chat error", function()
      GM_RegisterSwapListener("not a function")

      assert.are.equal(1, #chatErrors)
      assert.is_truthy(chatErrors[1]:find("GM_RegisterSwapListener", 1, true))

      macro.FireSwapEvent(RGGM_CONSTANTS.SWAP_EVENT_QUEUED, 13, 1000)
      assert.are.equal(0, #loggedErrors) -- nothing was registered, nothing can fail
    end)

    it("registers the same callback only once", function()
      local callCount = 0
      local listener = function() callCount = callCount + 1 end

      GM_RegisterSwapListener(listener)
      GM_RegisterSwapListener(listener)

      macro.FireSwapEvent(RGGM_CONSTANTS.SWAP_EVENT_QUEUED, 13, 1000)

      assert.are.equal(1, callCount)
    end)

    it("notifies listeners in registration order", function()
      local callOrder = {}

      GM_RegisterSwapListener(function() callOrder[#callOrder + 1] = "first" end)
      GM_RegisterSwapListener(function() callOrder[#callOrder + 1] = "second" end)

      macro.FireSwapEvent(RGGM_CONSTANTS.SWAP_EVENT_COMPLETED, 13, 1000)

      assert.are.same({ "first", "second" }, callOrder)
    end)
  end)

  describe("GM_UnregisterSwapListener", function()
    it("stops delivering events to an unregistered listener", function()
      local callCount = 0
      local listener = function() callCount = callCount + 1 end

      GM_RegisterSwapListener(listener)
      GM_UnregisterSwapListener(listener)

      macro.FireSwapEvent(RGGM_CONSTANTS.SWAP_EVENT_QUEUED, 13, 1000)

      assert.are.equal(0, callCount)
    end)

    it("is a no-op for a callback that was never registered", function()
      GM_UnregisterSwapListener(function() end)

      assert.are.equal(0, #chatErrors)
    end)
  end)

  describe("FireSwapEvent", function()
    it("isolates a throwing listener and still notifies the remaining listeners", function()
      local received = {}

      GM_RegisterSwapListener(function() error("broken listener") end)
      GM_RegisterSwapListener(function(eventName)
        received[#received + 1] = eventName
      end)

      macro.FireSwapEvent(RGGM_CONSTANTS.SWAP_EVENT_UNQUEUED, 13, 1000)

      assert.are.same({ RGGM_CONSTANTS.SWAP_EVENT_UNQUEUED }, received)
      assert.are.equal(1, #loggedErrors)
      assert.is_truthy(loggedErrors[1]:find("broken listener", 1, true))
    end)
  end)
end)
