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
  Spec for the trinketMenu drag and drop handling in gui/TrinketMenu.lua (me.SetupEvents,
  me.TrinketMenuSlotOnDragStart, me.TrinketMenuSlotOnReceiveDrag) plus a regression guard on
  the untouched click path (me.TrinketMenuSlotOnClick).

  Both directions mirror the gearSlots of a gearBar: dragging a trinket out of the menu picks
  the bag copy up onto the cursor, dropping a cursor held trinket onto the menu places it into
  the first free bag slot (unequipping it when it was worn). Both are gated behind the drag and
  drop option.

  gui/TrinketMenu.lua has no load-time WoW api surface, so it can be dofile'd with the
  collaborator modules (configuration, itemManager, themeCoordinator, tooltip, logger) replaced
  by recorder / no-op stubs and trinketSlots faked as recording tables.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: globals INVSLOT_TRINKET1 INVSLOT_TRINKET2
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

local TRINKET_ITEM_ID = 12345
local WEAPON_ITEM_ID = 67890

-- forward declarations
local CreateFakeTrinketSlot

--[[
  Build a fake trinketSlot that records every widget call made against it

  @param {number} itemId
    Optional itemId the slot represents

  @return {table}
    the fake trinketSlot with `clicks`, `drags` and `scripts` recorders
]]--
CreateFakeTrinketSlot = function(itemId)
  local trinketSlot = {
    itemId = itemId,
    clicks = {},  -- RegisterForClicks invocations
    drags = {},   -- RegisterForDrag invocations
    scripts = {}  -- scriptType -> handler
  }

  function trinketSlot:RegisterForClicks(...)
    self.clicks[#self.clicks + 1] = { ... }
  end

  function trinketSlot:RegisterForDrag(...)
    self.drags[#self.drags + 1] = { ... }
  end

  function trinketSlot:SetScript(scriptType, handler)
    self.scripts[scriptType] = handler
  end

  return trinketSlot
end

describe("TrinketMenu drag and drop", function()
  local trinketMenu
  local previous
  local restore
  local calls
  local dragAndDrop
  -- backs the mod.itemManager.FindItemInBag stub - nil means the item is not in the bags
  local bagLocation
  -- isLocked reported by C_Container.GetContainerItemInfo, nil means the slot holds no item
  local containerItemInfo
  -- backs the GetCursorInfo stub
  local cursorItemId
  -- failure reason returned by the mod.itemManager.PlaceCursorItemInBag stub
  local placementFailure

  before_each(function()
    dragAndDrop = true
    bagLocation = { bagNumber = 0, bagPos = 3 }
    containerItemInfo = { isLocked = false }
    cursorItemId = nil
    placementFailure = nil

    calls = {
      findItemInBag = {},        -- itemManager.FindItemInBag(itemId, enchantId, runeAbilityId)
      pickedUpContainerItems = {}, -- C_Container.PickupContainerItem(bagNumber, bagPos)
      placedInBag = {},          -- itemManager.PlaceCursorItemInBag(itemId)
      equipped = {},             -- itemManager.EquipItemByItemAndEnchantId(item)
      themeClicks = {},          -- themeCoordinator.TrinketMenuSlotOnClick(self, button)
      menuUpdates = 0            -- trinketMenu.UpdateTrinketMenu()
    }

    -- snapshot everything the load / functions touch so nothing leaks across specs
    previous = {
      trinketMenu = rggm.trinketMenu,
      configuration = rggm.configuration,
      itemManager = rggm.itemManager,
      themeCoordinator = rggm.themeCoordinator,
      tooltip = rggm.tooltip,
      logger = rggm.logger
    }

    rggm.configuration = {
      IsDragAndDropEnabled = function()
        return dragAndDrop
      end
    }

    rggm.itemManager = {
      FindItemInBag = function(itemId, enchantId, runeAbilityId)
        calls.findItemInBag[#calls.findItemInBag + 1] = {
          itemId = itemId, enchantId = enchantId, runeAbilityId = runeAbilityId
        }

        if bagLocation == nil then return nil, nil, false end

        return bagLocation.bagNumber, bagLocation.bagPos, false
      end,
      PlaceCursorItemInBag = function(itemId)
        calls.placedInBag[#calls.placedInBag + 1] = itemId

        return placementFailure
      end,
      EquipItemByItemAndEnchantId = function(item)
        calls.equipped[#calls.equipped + 1] = item
      end
    }

    rggm.themeCoordinator = {
      TrinketMenuSlotOnClick = function(self, button)
        calls.themeClicks[#calls.themeClicks + 1] = { self = self, button = button }
      end
    }

    rggm.tooltip = {
      UpdateTooltipForBagItem = function() end,
      TooltipClear = function() end
    }

    rggm.logger = {
      LogDebug = function() end,
      LogInfo = function() end,
      LogWarn = function() end,
      LogError = function() end
    }

    restore = wowStubs.install({
      C_Item = wowStubs.stubs.C_Item({}, {
        -- GetItemInfoInstant: itemID, itemType, itemSubType, itemEquipLoc (the 4th is read)
        [TRINKET_ITEM_ID] = { TRINKET_ITEM_ID, "Armor", "Miscellaneous", "INVTYPE_TRINKET" },
        [WEAPON_ITEM_ID] = { WEAPON_ITEM_ID, "Weapon", "Two-Handed Swords", "INVTYPE_2HWEAPON" }
      }),
      C_Container = {
        GetContainerItemInfo = function()
          return containerItemInfo
        end,
        PickupContainerItem = function(bagNumber, bagPos)
          calls.pickedUpContainerItems[#calls.pickedUpContainerItems + 1] = {
            bagNumber = bagNumber, bagPos = bagPos
          }
        end
      },
      GetCursorInfo = function()
        if cursorItemId == nil then return nil end

        return "item", cursorItemId, "|cffffffff|Hitem:" .. cursorItemId .. "|h[Test]|h|r"
      end
    })

    dofile("gui/TrinketMenu.lua")
    trinketMenu = rggm.trinketMenu
    -- the ui is never built headlessly - record the refresh instead of walking the slot pool
    trinketMenu.UpdateTrinketMenu = function()
      calls.menuUpdates = calls.menuUpdates + 1
    end
  end)

  after_each(function()
    restore()

    rggm.trinketMenu = previous.trinketMenu
    rggm.configuration = previous.configuration
    rggm.itemManager = previous.itemManager
    rggm.themeCoordinator = previous.themeCoordinator
    rggm.tooltip = previous.tooltip
    rggm.logger = previous.logger
  end)

  describe("SetupEvents", function()
    it("registers the left button for dragging", function()
      local trinketSlot = CreateFakeTrinketSlot(TRINKET_ITEM_ID)

      trinketMenu.SetupEvents(trinketSlot)

      assert.are.equal(1, #trinketSlot.drags)
      assert.are.same({ "LeftButton" }, trinketSlot.drags[1])
    end)

    it("wires both drag directions alongside the existing click handlers", function()
      local trinketSlot = CreateFakeTrinketSlot(TRINKET_ITEM_ID)

      trinketMenu.SetupEvents(trinketSlot)

      assert.is_function(trinketSlot.scripts["OnDragStart"])
      assert.is_function(trinketSlot.scripts["OnReceiveDrag"])
      assert.is_function(trinketSlot.scripts["OnClick"])
      assert.is_function(trinketSlot.scripts["OnEnter"])
      assert.is_function(trinketSlot.scripts["OnLeave"])
    end)

    it("keeps registering both click directions for the left and the right button", function()
      local trinketSlot = CreateFakeTrinketSlot(TRINKET_ITEM_ID)

      trinketMenu.SetupEvents(trinketSlot)

      assert.are.equal(1, #trinketSlot.clicks)
      assert.are.same({ "LeftButtonUp", "RightButtonUp" }, trinketSlot.clicks[1])
    end)

    it("dispatches the wired OnDragStart handler to the drag start callback", function()
      local trinketSlot = CreateFakeTrinketSlot(TRINKET_ITEM_ID)

      trinketMenu.SetupEvents(trinketSlot)
      trinketSlot.scripts["OnDragStart"](trinketSlot)

      assert.are.same({ { bagNumber = 0, bagPos = 3 } }, calls.pickedUpContainerItems)
    end)

    it("dispatches the wired OnReceiveDrag handler to the receive drag callback", function()
      cursorItemId = TRINKET_ITEM_ID
      local trinketSlot = CreateFakeTrinketSlot(TRINKET_ITEM_ID)

      trinketMenu.SetupEvents(trinketSlot)
      trinketSlot.scripts["OnReceiveDrag"](trinketSlot)

      assert.are.same({ TRINKET_ITEM_ID }, calls.placedInBag)
    end)
  end)

  describe("TrinketMenuSlotOnDragStart", function()
    it("picks the bag copy of the trinket up onto the cursor", function()
      trinketMenu.TrinketMenuSlotOnDragStart(CreateFakeTrinketSlot(TRINKET_ITEM_ID))

      assert.are.same({ { bagNumber = 0, bagPos = 3 } }, calls.pickedUpContainerItems)
    end)

    it("matches on the itemId alone because trinkets carry no enchant or rune", function()
      trinketMenu.TrinketMenuSlotOnDragStart(CreateFakeTrinketSlot(TRINKET_ITEM_ID))

      assert.are.equal(1, #calls.findItemInBag)
      assert.are.same(
        { itemId = TRINKET_ITEM_ID, enchantId = 0, runeAbilityId = 0 },
        calls.findItemInBag[1]
      )
    end)

    it("does nothing when drag and drop is disabled", function()
      dragAndDrop = false

      trinketMenu.TrinketMenuSlotOnDragStart(CreateFakeTrinketSlot(TRINKET_ITEM_ID))

      assert.are.equal(0, #calls.findItemInBag)
      assert.are.equal(0, #calls.pickedUpContainerItems)
    end)

    it("does nothing for a slot that represents no item", function()
      trinketMenu.TrinketMenuSlotOnDragStart(CreateFakeTrinketSlot(nil))

      assert.are.equal(0, #calls.findItemInBag)
      assert.are.equal(0, #calls.pickedUpContainerItems)
    end)

    it("does nothing when the item can no longer be found in the bags", function()
      bagLocation = nil

      trinketMenu.TrinketMenuSlotOnDragStart(CreateFakeTrinketSlot(TRINKET_ITEM_ID))

      assert.are.equal(1, #calls.findItemInBag)
      assert.are.equal(0, #calls.pickedUpContainerItems)
    end)

    it("does not pick up a container item that is locked", function()
      containerItemInfo = { isLocked = true }

      trinketMenu.TrinketMenuSlotOnDragStart(CreateFakeTrinketSlot(TRINKET_ITEM_ID))

      assert.are.equal(0, #calls.pickedUpContainerItems)
    end)

    it("does not pick up when the bag slot reports no item info", function()
      containerItemInfo = nil

      trinketMenu.TrinketMenuSlotOnDragStart(CreateFakeTrinketSlot(TRINKET_ITEM_ID))

      assert.are.equal(0, #calls.pickedUpContainerItems)
    end)
  end)

  describe("TrinketMenuSlotOnReceiveDrag", function()
    it("places a cursor held trinket into a free bag slot and refreshes the menu", function()
      cursorItemId = TRINKET_ITEM_ID

      trinketMenu.TrinketMenuSlotOnReceiveDrag()

      assert.are.same({ TRINKET_ITEM_ID }, calls.placedInBag)
      assert.are.equal(1, calls.menuUpdates)
    end)

    it("does nothing when drag and drop is disabled", function()
      dragAndDrop = false
      cursorItemId = TRINKET_ITEM_ID

      trinketMenu.TrinketMenuSlotOnReceiveDrag()

      assert.are.equal(0, #calls.placedInBag)
      assert.are.equal(0, calls.menuUpdates)
    end)

    it("does nothing when the cursor holds no item", function()
      trinketMenu.TrinketMenuSlotOnReceiveDrag()

      assert.are.equal(0, #calls.placedInBag)
      assert.are.equal(0, calls.menuUpdates)
    end)

    it("leaves an item that is not a trinket untouched on the cursor", function()
      cursorItemId = WEAPON_ITEM_ID

      trinketMenu.TrinketMenuSlotOnReceiveDrag()

      assert.are.equal(0, #calls.placedInBag)
      assert.are.equal(0, calls.menuUpdates)
    end)

    it("does not refresh the menu when the item could not be placed into a bag", function()
      cursorItemId = TRINKET_ITEM_ID
      placementFailure = "NO_BAG_SPACE"

      trinketMenu.TrinketMenuSlotOnReceiveDrag()

      assert.are.same({ TRINKET_ITEM_ID }, calls.placedInBag)
      assert.are.equal(0, calls.menuUpdates)
    end)
  end)

  describe("TrinketMenuSlotOnClick", function()
    it("still equips into the first trinket slot on a left click", function()
      trinketMenu.TrinketMenuSlotOnClick(CreateFakeTrinketSlot(TRINKET_ITEM_ID), "LeftButton")

      assert.are.equal(1, #calls.equipped)
      assert.are.equal(TRINKET_ITEM_ID, calls.equipped[1].itemId)
      assert.are.equal(INVSLOT_TRINKET1, calls.equipped[1].slotId)
      assert.are.equal(1, #calls.themeClicks)
    end)

    it("still equips into the second trinket slot on a right click", function()
      trinketMenu.TrinketMenuSlotOnClick(CreateFakeTrinketSlot(TRINKET_ITEM_ID), "RightButton")

      assert.are.equal(1, #calls.equipped)
      assert.are.equal(TRINKET_ITEM_ID, calls.equipped[1].itemId)
      assert.are.equal(INVSLOT_TRINKET2, calls.equipped[1].slotId)
      assert.are.equal(1, #calls.themeClicks)
    end)
  end)
end)
