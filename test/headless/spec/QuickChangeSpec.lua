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
  Spec for executing a QuickChange rule in code/QuickChange.lua (me.ExecuteQuickChangeRule). A
  rule swaps changeFromItemId for changeToItemId after its delay; the rule is checked when it is
  triggered and again when the delay has passed, so a change the player made in between - an
  equip, or an item queued for the slot during combat - is not swapped back.

  C_Timer.After is queued and flushed by the spec, the worn items and the combatQueue store are
  plain tables, and mod.itemManager records the equips the rule requests.
]]--

local wowStubs = require("WowStubs")

local SLOT_ID = 13
local FROM_ITEM_ID = 11111
local TO_ITEM_ID = 22222
local OTHER_ITEM_ID = 33333

describe("QuickChange", function()
  local quickChange
  local restore
  local pendingTimers
  -- equipped[slotId] -> itemId worn in that slot
  local equipped
  -- combatQueueStore[slotId] -> { itemId, enchantId }
  local combatQueueStore
  local equips
  local rule

  -- the slot metadata as CollectEligibleSlotIds builds it when the rule is triggered
  local function eligibleSlots()
    return { { slotId = SLOT_ID, itemId = equipped[SLOT_ID] } }
  end

  local function flushTimers()
    local timers = pendingTimers

    pendingTimers = {}

    for _, timer in ipairs(timers) do
      timer.callback()
    end
  end

  before_each(function()
    pendingTimers = {}
    equipped = { [SLOT_ID] = FROM_ITEM_ID }
    combatQueueStore = {}
    equips = {}
    rule = { changeFromItemId = FROM_ITEM_ID, changeToItemId = TO_ITEM_ID, changeToItemEnchantId = 5, delay = 10 }

    rggm.logger = { LogDebug = function() end }
    rggm.combatQueue = { GetCombatQueueStore = function() return combatQueueStore end }
    rggm.itemManager = {
      EquipItemByItemAndEnchantId = function(item) equips[#equips + 1] = item end
    }

    restore = wowStubs.install({
      GetInventoryItemID = function(_, slotId) return equipped[slotId] end,
      C_Item = {
        IsEquippedItem = function(itemId)
          for _, wornItemId in pairs(equipped) do
            if wornItemId == itemId then return true end
          end

          return false
        end
      },
      C_Timer = {
        After = function(delay, callback)
          pendingTimers[#pendingTimers + 1] = { delay = delay, callback = callback }
        end
      }
    })

    dofile("code/QuickChange.lua")
    quickChange = rggm.quickChange
  end)

  after_each(function()
    restore()
  end)

  it("equips the item to change to once the delay has passed", function()
    quickChange.ExecuteQuickChangeRule(rule, eligibleSlots())

    assert.are.equal(1, #pendingTimers)
    assert.are.equal(10, pendingTimers[1].delay)
    assert.are.same({}, equips)

    flushTimers()

    assert.are.same({ { itemId = TO_ITEM_ID, enchantId = 5, slotId = SLOT_ID } }, equips)
  end)

  it("does not schedule a rule when the slot does not hold the item to change from", function()
    equipped[SLOT_ID] = OTHER_ITEM_ID

    quickChange.ExecuteQuickChangeRule(rule, eligibleSlots())

    assert.are.equal(0, #pendingTimers)
  end)

  it("skips the delayed swap when the player equipped another item during the delay", function()
    quickChange.ExecuteQuickChangeRule(rule, eligibleSlots())

    equipped[SLOT_ID] = OTHER_ITEM_ID
    flushTimers()

    assert.are.same({}, equips)
  end)

  it("skips the delayed swap when the item to change to was equipped during the delay", function()
    quickChange.ExecuteQuickChangeRule(rule, eligibleSlots())

    -- equipped into the other trinket slot by hand
    equipped[14] = TO_ITEM_ID
    flushTimers()

    assert.are.same({}, equips)
  end)

  it("skips the delayed swap when the player queued another item for the slot during the delay", function()
    quickChange.ExecuteQuickChangeRule(rule, eligibleSlots())

    combatQueueStore[SLOT_ID] = { OTHER_ITEM_ID }
    flushTimers()

    assert.are.same({}, equips)
  end)

  it("still fires when the item to change to is the one already queued for the slot", function()
    quickChange.ExecuteQuickChangeRule(rule, eligibleSlots())

    combatQueueStore[SLOT_ID] = { TO_ITEM_ID, 5 }
    flushTimers()

    assert.are.equal(1, #equips)
  end)
end)
