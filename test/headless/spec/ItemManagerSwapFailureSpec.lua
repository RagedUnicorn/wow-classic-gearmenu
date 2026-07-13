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
  Spec for the typed swap-failure paths in code/ItemManager.lua (SwitchItems, UnequipItemToBag)
  together with the FindSpace bag-space precheck feeding them and the once-per-entry
  notification guard in code/CombatQueue.lua. Both modules are
  loaded for real (per the re-dofile isolation convention documented in test/headless/Bootstrap.lua)
  so the interplay - queued swaps report each failure reason exactly once while ProcessQueue keeps
  retrying - is covered end to end. localization/enUS.lua is loaded for real as well so the emitted
  user messages are asserted against the actual localized strings.

  The bag contents are driven by a per-test `bags` fixture backing the C_Container stubs; the
  cursor state is a simple switch that PickupInventoryItem / PutItemInBackpack /
  PickupContainerItem mutate the way the real client would for the exercised paths.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each INVSLOT_MAINHAND INVSLOT_OFFHAND
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("ItemManager swap failures", function()
  local itemManager
  local combatQueue
  local restore
  local previousModules
  -- user-facing chat error messages recorded from mod.logger.PrintUserChatError
  local userChatMessages
  -- user-facing chat warning messages recorded from mod.logger.PrintUserChatWarn
  local userChatWarnMessages
  --[[
    bag fixture: bags[bagNumber] is a list where each entry is either an item table
    ({ itemId, enchantId, rune, locked }) or false for an empty bag slot. Unlisted bags have
    zero slots.
  ]]--
  local bags
  -- equipped[slotId] -> itemId currently worn in that slot
  local equipped
  local cursorHasItem, spellIsTargeting, inventoryLocked
  -- backs the mod.configuration.IsFallbackToBaseItemEnabled stub
  local fallbackEnabled
  -- slotIds passed to PickupInventoryItem, to assert an aborted action never touched the cursor
  local pickedUpInventorySlots

  before_each(function()
    userChatMessages = {}
    userChatWarnMessages = {}
    bags = {}
    equipped = {}
    cursorHasItem, spellIsTargeting, inventoryLocked = false, false, false
    fallbackEnabled = false
    pickedUpInventorySlots = {}

    previousModules = {
      L = rggm.L,
      logger = rggm.logger,
      common = rggm.common,
      engrave = rggm.engrave,
      configuration = rggm.configuration,
      gearManager = rggm.gearManager,
      gearBar = rggm.gearBar,
      ticker = rggm.ticker,
      combatQueue = rggm.combatQueue,
      itemManager = rggm.itemManager
    }

    restore = wowStubs.install({
      C_AddOns = wowStubs.stubs.C_AddOns({ Version = "0.0.0-test" }),
      C_Item = wowStubs.stubs.C_Item(
        { [12345] = { "Test Item" }, [67890] = { "Test 2H" } },
        -- GetItemInfoInstant: itemID, itemType, itemSubType, itemEquipLoc (the 2H precheck reads the 4th)
        { [67890] = { 67890, "Weapon", "Two-Handed Swords", "INVTYPE_2HWEAPON" } }
      ),
      C_Container = {
        GetContainerNumSlots = function(bagNumber)
          return bags[bagNumber] and #bags[bagNumber] or 0
        end,
        GetContainerItemLink = function(bagNumber, bagPos)
          return bags[bagNumber][bagPos] or nil
        end,
        GetContainerItemInfo = function(bagNumber, bagPos)
          local item = bags[bagNumber][bagPos]
          return item and { isLocked = item.locked or false } or nil
        end,
        GetContainerItemID = function(bagNumber, bagPos)
          local item = bags[bagNumber][bagPos]
          return item and item.itemId or nil
        end,
        PickupContainerItem = function()
          -- picking up into an empty bag slot places the held item
          cursorHasItem = false
        end
      },
      CursorHasItem = function() return cursorHasItem end,
      SpellIsTargeting = function() return spellIsTargeting end,
      IsInventoryItemLocked = function() return inventoryLocked end,
      PickupInventoryItem = function(slotId)
        pickedUpInventorySlots[#pickedUpInventorySlots + 1] = slotId
        if equipped[slotId] then cursorHasItem = true end
      end,
      GetInventoryItemID = function(_, slotId) return equipped[slotId] end,
      PutItemInBackpack = function() cursorHasItem = false end,
      ClearCursor = function() end,
      UnitAffectingCombat = function() return false end,
      InCombatLockdown = wowStubs.stubs.InCombatLockdown(false)
    })

    -- real localized strings so the emitted messages are asserted against enUS
    dofile("localization/enUS.lua")

    -- collaborators reached via mod.* -> stubs on the shared rggm namespace
    rggm.logger = {
      LogDebug = function() end,
      LogError = function() end,
      PrintUserChatError = function(message)
        userChatMessages[#userChatMessages + 1] = message
      end,
      PrintUserChatWarn = function(message)
        userChatWarnMessages[#userChatWarnMessages + 1] = message
      end
    }
    rggm.common = {
      GetItemInfo = function(itemLink)
        if not itemLink then return {} end
        return { itemId = itemLink.itemId, enchantId = itemLink.enchantId }
      end,
      IsPlayerCasting = function() return false end,
      IsPlayerReallyDead = function() return false end
    }
    rggm.engrave = {
      GetRuneForInventorySlot = function(bagNumber, bagPos)
        local item = bags[bagNumber] and bags[bagNumber][bagPos]
        return item and item.rune or nil
      end
    }
    rggm.configuration = {
      IsFallbackToBaseItemEnabled = function() return fallbackEnabled end
    }
    rggm.gearManager = {
      GetGearSlots = function() return { { slotId = 13 } } end
    }
    rggm.gearBar = {
      UpdateCombatQueue = function() end
    }
    rggm.ticker = {
      StartTickerCombatQueue = function() end,
      StopTickerCombatQueue = function() end
    }

    -- fresh module tables with empty file-local state (see test/headless/Bootstrap.lua)
    dofile("code/CombatQueue.lua")
    dofile("code/ItemManager.lua")
    combatQueue = rggm.combatQueue
    itemManager = rggm.itemManager
  end)

  after_each(function()
    restore()

    rggm.L = previousModules.L
    rggm.logger = previousModules.logger
    rggm.common = previousModules.common
    rggm.engrave = previousModules.engrave
    rggm.configuration = previousModules.configuration
    rggm.gearManager = previousModules.gearManager
    rggm.gearBar = previousModules.gearBar
    rggm.ticker = previousModules.ticker
    rggm.combatQueue = previousModules.combatQueue
    rggm.itemManager = previousModules.itemManager
  end)

  describe("SwitchItems", function()
    it("returns nil and reports nothing when the swap succeeds", function()
      bags[0] = { { itemId = 12345 } }

      local reason = itemManager.SwitchItems(12345, nil, nil, 13)

      assert.is_nil(reason)
      assert.are.equal(0, #userChatMessages)
    end)

    it("reports CURSOR_BUSY when another item is on the cursor", function()
      cursorHasItem = true

      local reason = itemManager.SwitchItems(12345, nil, nil, 13)

      assert.are.equal(itemManager.failureReason.cursorBusy, reason)
      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_cursor_busy"], "Test Item"), userChatMessages[1])
    end)

    it("reports SPELL_TARGETING while a spell requests a target", function()
      spellIsTargeting = true

      local reason = itemManager.SwitchItems(12345, nil, nil, 13)

      assert.are.equal(itemManager.failureReason.spellTargeting, reason)
      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_spell_targeting"], "Test Item"), userChatMessages[1])
    end)

    it("reports ITEM_NOT_FOUND when the item is neither in the bags nor equipped", function()
      local reason = itemManager.SwitchItems(12345, nil, nil, 13)

      assert.are.equal(itemManager.failureReason.itemNotFound, reason)
      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_item_not_found"], "Test Item"), userChatMessages[1])
    end)

    it("reports ITEM_LOCKED when the container item is locked", function()
      bags[0] = { { itemId = 12345, locked = true } }

      local reason = itemManager.SwitchItems(12345, nil, nil, 13)

      assert.are.equal(itemManager.failureReason.itemLocked, reason)
      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_item_locked"], "Test Item"), userChatMessages[1])
    end)

    it("reports ITEM_LOCKED when the target inventory slot is locked", function()
      bags[0] = { { itemId = 12345 } }
      inventoryLocked = true

      local reason = itemManager.SwitchItems(12345, nil, nil, 13)

      assert.are.equal(itemManager.failureReason.itemLocked, reason)
      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_item_locked"], "Test Item"), userChatMessages[1])
    end)

    it("falls back to the itemId when the item name is not cached", function()
      local reason = itemManager.SwitchItems(99999, nil, nil, 13)

      assert.are.equal(itemManager.failureReason.itemNotFound, reason)
      assert.are.equal(
        string.format(rggm.L["swap_failure_item_not_found"], 99999), userChatMessages[1])
    end)

    it("drops the queued entry after notifying a terminal failure", function()
      combatQueue.AddToQueue(12345, nil, nil, 13)

      itemManager.SwitchItems(12345, nil, nil, 13)

      assert.is_true(combatQueue.IsCombatQueueEmpty())
      assert.are.equal(1, #userChatMessages)
    end)

    it("keeps the queued entry on a cursor-busy abort so it can retry", function()
      combatQueue.AddToQueue(12345, nil, nil, 13)
      cursorHasItem = true

      itemManager.SwitchItems(12345, nil, nil, 13)

      assert.is_false(combatQueue.IsCombatQueueEmpty())
    end)

    it("notifies on every attempt for a direct swap without a queued entry", function()
      cursorHasItem = true

      itemManager.SwitchItems(12345, nil, nil, 13)
      itemManager.SwitchItems(12345, nil, nil, 13)

      assert.are.equal(2, #userChatMessages)
    end)

    it("reports NO_BAG_SPACE before touching the cursor when a 2H would displace the "
      .. "offhand into full bags", function()
      equipped[INVSLOT_OFFHAND] = 22222
      bags[0] = { { itemId = 67890 } }

      local reason = itemManager.SwitchItems(67890, nil, nil, INVSLOT_MAINHAND)

      assert.are.equal(itemManager.failureReason.noBagSpace, reason)
      assert.are.equal(0, #pickedUpInventorySlots)
      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_no_bag_space"], "Test 2H"), userChatMessages[1])
    end)

    it("drops the queued entry when the 2H bag-space precheck aborts the swap", function()
      equipped[INVSLOT_OFFHAND] = 22222
      bags[0] = { { itemId = 67890 } }
      combatQueue.AddToQueue(67890, nil, nil, INVSLOT_MAINHAND)

      itemManager.SwitchItems(67890, nil, nil, INVSLOT_MAINHAND)

      assert.is_true(combatQueue.IsCombatQueueEmpty())
      assert.are.equal(1, #userChatMessages)
    end)

    it("equips a 2H over a worn offhand when a free bag slot exists", function()
      equipped[INVSLOT_OFFHAND] = 22222
      bags[0] = { { itemId = 67890 }, false }

      local reason = itemManager.SwitchItems(67890, nil, nil, INVSLOT_MAINHAND)

      assert.is_nil(reason)
      assert.are.equal(0, #userChatMessages)
    end)

    it("equips a 2H with full bags when no offhand is worn", function()
      bags[0] = { { itemId = 67890 } }

      local reason = itemManager.SwitchItems(67890, nil, nil, INVSLOT_MAINHAND)

      assert.is_nil(reason)
      assert.are.equal(0, #userChatMessages)
    end)

    it("equips a one-handed weapon over a worn offhand with full bags", function()
      equipped[INVSLOT_OFFHAND] = 22222
      bags[0] = { { itemId = 12345 } }

      local reason = itemManager.SwitchItems(12345, nil, nil, INVSLOT_MAINHAND)

      assert.is_nil(reason)
      assert.are.equal(0, #userChatMessages)
    end)
  end)

  describe("fallback to base item", function()
    it("keeps strict matching when the toggle is off and only an inexact copy exists", function()
      bags[0] = { { itemId = 12345, enchantId = 70 } }

      local reason = itemManager.SwitchItems(12345, 60, nil, 13)

      assert.are.equal(itemManager.failureReason.itemNotFound, reason)
      assert.are.equal(0, #userChatWarnMessages)
      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_item_not_found"], "Test Item"), userChatMessages[1])
    end)

    it("equips the plain copy and warns when the requested enchant copy is missing", function()
      fallbackEnabled = true
      bags[0] = { { itemId = 12345 } }

      local reason = itemManager.SwitchItems(12345, 60, nil, 13)

      assert.is_nil(reason)
      assert.are.equal(0, #userChatMessages)
      assert.are.equal(1, #userChatWarnMessages)
      assert.are.equal(
        string.format(rggm.L["swap_fallback_to_base_item"], "Test Item"), userChatWarnMessages[1])
    end)

    it("prefers the exact copy and does not warn when it exists", function()
      fallbackEnabled = true
      bags[0] = { { itemId = 12345, enchantId = 60 } }

      local reason = itemManager.SwitchItems(12345, 60, nil, 13)

      assert.is_nil(reason)
      assert.are.equal(0, #userChatWarnMessages)
      assert.are.equal(0, #userChatMessages)
    end)

    it("still reports ITEM_NOT_FOUND when no copy of the itemId exists at all", function()
      fallbackEnabled = true

      local reason = itemManager.SwitchItems(12345, 60, nil, 13)

      assert.are.equal(itemManager.failureReason.itemNotFound, reason)
      assert.are.equal(0, #userChatWarnMessages)
      assert.are.equal(1, #userChatMessages)
    end)

    it("reports ITEM_LOCKED without warning when the substitute copy is locked", function()
      fallbackEnabled = true
      bags[0] = { { itemId = 12345, locked = true } }

      local reason = itemManager.SwitchItems(12345, 60, nil, 13)

      assert.are.equal(itemManager.failureReason.itemLocked, reason)
      assert.are.equal(0, #userChatWarnMessages)
      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_item_locked"], "Test Item"), userChatMessages[1])
    end)

    it("equips the un-engraved copy and warns when the requested rune copy is missing", function()
      fallbackEnabled = true
      bags[0] = { { itemId = 12345 } }

      local reason = itemManager.SwitchItems(12345, nil, 7, 13)

      assert.is_nil(reason)
      assert.are.equal(0, #userChatMessages)
      assert.are.equal(1, #userChatWarnMessages)
      assert.are.equal(
        string.format(rggm.L["swap_fallback_to_base_item"], "Test Item"), userChatWarnMessages[1])
    end)

    it("keeps strict rune matching when the toggle is off", function()
      bags[0] = { { itemId = 12345, rune = { skillLineAbilityID = 8 } } }

      local reason = itemManager.SwitchItems(12345, nil, 7, 13)

      assert.are.equal(itemManager.failureReason.itemNotFound, reason)
      assert.are.equal(0, #userChatWarnMessages)
    end)

    it("drops the queued entry and warns once when a queued swap falls back", function()
      fallbackEnabled = true
      combatQueue.AddToQueue(12345, 60, nil, 13)
      bags[0] = { { itemId = 12345 } }

      combatQueue.ProcessQueue()

      assert.is_true(combatQueue.IsCombatQueueEmpty())
      assert.are.equal(0, #userChatMessages)
      assert.are.equal(1, #userChatWarnMessages)
    end)
  end)

  describe("once-per-entry notification through ProcessQueue", function()
    it("notifies a queued swap once per reason while the ticker keeps retrying", function()
      combatQueue.AddToQueue(12345, nil, nil, 13)
      cursorHasItem = true

      combatQueue.ProcessQueue()
      combatQueue.ProcessQueue()
      combatQueue.ProcessQueue()

      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_cursor_busy"], "Test Item"), userChatMessages[1])
    end)

    it("notifies again when the failure reason changes and then drops the entry", function()
      combatQueue.AddToQueue(12345, nil, nil, 13)
      cursorHasItem = true

      combatQueue.ProcessQueue()
      combatQueue.ProcessQueue()

      -- cursor is free again but the item is gone from the bags
      cursorHasItem = false
      combatQueue.ProcessQueue()
      combatQueue.ProcessQueue()

      assert.are.equal(2, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_item_not_found"], "Test Item"), userChatMessages[2])
      assert.is_true(combatQueue.IsCombatQueueEmpty())
    end)
  end)

  describe("UnequipItemToBag", function()
    it("reports NO_BAG_SPACE without ever picking the item up when the bags are full", function()
      equipped[13] = 12345
      bags[0] = { { itemId = 11111 } }

      local reason = itemManager.UnequipItemToBag({ slotId = 13 })

      assert.are.equal(itemManager.failureReason.noBagSpace, reason)
      assert.are.equal(0, #pickedUpInventorySlots)
      assert.are.equal(1, #userChatMessages)
      assert.are.equal(
        string.format(rggm.L["swap_failure_no_bag_space"], "Test Item"), userChatMessages[1])
    end)

    it("returns nil and reports nothing when an empty bag slot is found", function()
      equipped[13] = 12345
      bags[0] = { { itemId = 11111 }, false }

      local reason = itemManager.UnequipItemToBag({ slotId = 13 })

      assert.is_nil(reason)
      assert.are.equal(0, #userChatMessages)
    end)

    it("unequips into the single free bag slot when only one is left", function()
      equipped[13] = 12345
      bags[0] = { { itemId = 11111 } }
      bags[1] = { { itemId = 11111 }, false }

      local reason = itemManager.UnequipItemToBag({ slotId = 13 })

      assert.is_nil(reason)
      assert.are.same({ 13 }, pickedUpInventorySlots)
      assert.are.equal(0, #userChatMessages)
    end)

    it("returns nil and reports nothing when the slot is already empty", function()
      bags[0] = { { itemId = 11111 } }

      local reason = itemManager.UnequipItemToBag({ slotId = 13 })

      assert.is_nil(reason)
      assert.are.equal(0, #pickedUpInventorySlots)
      assert.are.equal(0, #userChatMessages)
    end)
  end)

  describe("FindSpace", function()
    it("returns the first free slot of the backpack", function()
      bags[0] = { { itemId = 11111 }, false, false }

      local bagNumber, bagPos = itemManager.FindSpace()

      assert.are.equal(0, bagNumber)
      assert.are.equal(2, bagPos)
    end)

    it("falls through to a later bag when the backpack is full", function()
      bags[0] = { { itemId = 11111 } }
      bags[1] = { { itemId = 11111 } }
      bags[2] = { { itemId = 11111 }, false }

      local bagNumber, bagPos = itemManager.FindSpace()

      assert.are.equal(2, bagNumber)
      assert.are.equal(2, bagPos)
    end)

    it("returns nil when every bag slot is occupied", function()
      bags[0] = { { itemId = 11111 } }
      bags[1] = { { itemId = 11111 }, { itemId = 22222 } }

      local bagNumber, bagPos = itemManager.FindSpace()

      assert.is_nil(bagNumber)
      assert.is_nil(bagPos)
    end)

    it("returns nil when there are no bags at all", function()
      local bagNumber, bagPos = itemManager.FindSpace()

      assert.is_nil(bagNumber)
      assert.is_nil(bagPos)
    end)
  end)
end)
