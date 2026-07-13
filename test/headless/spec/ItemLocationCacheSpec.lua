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
  Spec for code/ItemLocationCache.lua and its consumption in code/ItemManager.lua
  (FindItemInBag, GetItemsForInventoryType). Both modules are loaded for real (per the re-dofile
  isolation convention documented in test/headless/Bootstrap.lua).

  Covered:
    - cache build (scan order, enchantId capture) and lookup by itemId
    - a lookup between bag changes performs zero per-slot container iteration (stub call counts)
    - Invalidate marks the cache stale and the next lookup rescans the live bags
    - the stale-entry guard: a cache entry whose live container content diverged is never
      returned; the scan retries once against a rebuilt cache instead
    - equivalence: FindItemInBag and GetItemsForInventoryType return the same results as a
      reference reimplementation of the pre-cache full bag rescan for the same bag state

  The bag contents are driven by a per-test `bags` fixture backing the C_Container stubs
  (bags[bagNumber] is a list where each entry is either an item table
  ({ itemId, enchantId, rune }) or false for an empty bag slot; unlisted bags have zero slots).
  The stubs count their invocations so the specs can assert how the cache hits the container API.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("ItemLocationCache", function()
  local itemLocationCache
  local itemManager
  local restore
  local previousModules
  -- bag fixture backing the C_Container stubs (see file comment)
  local bags
  -- static item data backing the C_Item.GetItemInfo stub: itemId -> { name, quality, equipSlot, icon }
  local itemInfoById
  -- C_Container stub invocation counters
  local containerCalls
  -- backs the mod.configuration stubs
  local filterItemQuality, fallbackEnabled

  --[[
    Reference reimplementation of the pre-cache ScanBagsForItem/FindItemInBag full bag rescan.
    Iterates the bag fixture directly so it leaves the container call counters untouched.
  ]]--
  local function referenceScanBagsForItem(itemId, enchantId, runeAbilityId)
    for i = 0, 4 do
      for j = 1, (bags[i] and #bags[i] or 0) do
        local item = bags[i][j]

        if item and item.itemId == itemId then
          local itemInfo = { itemId = item.itemId, enchantId = item.enchantId }

          if itemManager.IsEnchantIdMatching(itemInfo, enchantId)
            and itemManager.IsRuneAbilityIdMatching(item.rune, runeAbilityId) then
            return i, j
          end
        end
      end
    end

    return nil, nil
  end

  local function referenceFindItemInBag(itemId, enchantId, runeAbilityId)
    local bagNumber, bagPos = referenceScanBagsForItem(itemId, enchantId, runeAbilityId)

    if bagNumber ~= nil then
      return bagNumber, bagPos, false
    end

    if fallbackEnabled and not (enchantId == 0 and runeAbilityId == 0) then
      bagNumber, bagPos = referenceScanBagsForItem(itemId, 0, 0)

      if bagNumber ~= nil then
        return bagNumber, bagPos, true
      end
    end

    return nil, nil, false
  end

  --[[
    Reference reimplementation of the pre-cache GetItemsForInventoryType full bag rescan.
  ]]--
  local function referenceGetItemsForInventoryType(inventoryType)
    local items = {}

    for i = 0, 4 do
      for j = 1, (bags[i] and #bags[i] or 0) do
        local item = bags[i][j]

        if item and item.itemId then
          local info = itemInfoById[item.itemId]

          for it = 1, #inventoryType do
            if info.equipSlot == inventoryType[it] and info.quality >= filterItemQuality then
              table.insert(items, {
                bag = i,
                slot = j,
                name = info.name,
                icon = info.icon,
                id = item.itemId,
                equipSlot = info.equipSlot,
                quality = info.quality,
                enchantId = item.enchantId,
                rune = item.rune or nil
              })
            end
          end
        end
      end
    end

    return items
  end

  before_each(function()
    bags = {}
    itemInfoById = {}
    containerCalls = { numSlots = 0, itemLink = 0 }
    filterItemQuality = 0
    fallbackEnabled = false

    previousModules = {
      logger = rggm.logger,
      common = rggm.common,
      engrave = rggm.engrave,
      configuration = rggm.configuration,
      itemLocationCache = rggm.itemLocationCache,
      itemManager = rggm.itemManager
    }

    restore = wowStubs.install({
      C_Container = {
        GetContainerNumSlots = function(bagNumber)
          containerCalls.numSlots = containerCalls.numSlots + 1
          return bags[bagNumber] and #bags[bagNumber] or 0
        end,
        GetContainerItemLink = function(bagNumber, bagPos)
          containerCalls.itemLink = containerCalls.itemLink + 1
          local item = bags[bagNumber] and bags[bagNumber][bagPos]
          return item or nil
        end
      },
      C_Item = {
        GetItemInfo = function(itemId)
          local info = itemInfoById[itemId]
          if not info then return nil end
          return info.name, nil, info.quality, nil, nil, nil, nil, nil, info.equipSlot, info.icon
        end
      }
    })

    -- collaborators reached via mod.* -> stubs on the shared rggm namespace
    rggm.logger = {
      LogDebug = function() end,
      LogError = function() end
    }
    rggm.common = {
      GetItemInfo = function(itemLink)
        if not itemLink then return {} end
        return { itemId = itemLink.itemId, enchantId = itemLink.enchantId }
      end
    }
    rggm.engrave = {
      GetRuneForInventorySlot = function(bagNumber, bagPos)
        local item = bags[bagNumber] and bags[bagNumber][bagPos]
        return item and item.rune or nil
      end
    }
    rggm.configuration = {
      GetFilterItemQuality = function() return filterItemQuality end,
      IsFallbackToBaseItemEnabled = function() return fallbackEnabled end
    }

    -- fresh module tables with empty file-local state (see test/headless/Bootstrap.lua)
    dofile("code/ItemLocationCache.lua")
    dofile("code/ItemManager.lua")
    itemLocationCache = rggm.itemLocationCache
    itemManager = rggm.itemManager
  end)

  after_each(function()
    restore()

    rggm.logger = previousModules.logger
    rggm.common = previousModules.common
    rggm.engrave = previousModules.engrave
    rggm.configuration = previousModules.configuration
    rggm.itemLocationCache = previousModules.itemLocationCache
    rggm.itemManager = previousModules.itemManager
  end)

  describe("cache build and lookup", function()
    it("records every occupied bag slot in bag/slot scan order", function()
      bags[0] = { { itemId = 11111 }, false, { itemId = 22222, enchantId = 60 } }
      bags[2] = { { itemId = 11111, enchantId = 70 } }

      assert.are.same({
        { bagNumber = 0, bagPos = 1, itemId = 11111, enchantId = nil },
        { bagNumber = 0, bagPos = 3, itemId = 22222, enchantId = 60 },
        { bagNumber = 2, bagPos = 1, itemId = 11111, enchantId = 70 }
      }, itemLocationCache.GetBagEntries())
    end)

    it("returns all locations holding a copy of the requested item", function()
      bags[0] = { { itemId = 11111 }, { itemId = 22222 } }
      bags[1] = { { itemId = 11111, enchantId = 70 } }

      assert.are.same({
        { bagNumber = 0, bagPos = 1, itemId = 11111, enchantId = nil },
        { bagNumber = 1, bagPos = 1, itemId = 11111, enchantId = 70 }
      }, itemLocationCache.GetItemLocations(11111))
    end)

    it("returns an empty list for an item that is not in the bags", function()
      bags[0] = { { itemId = 11111 } }

      assert.are.same({}, itemLocationCache.GetItemLocations(99999))
    end)
  end)

  describe("caching between bag changes", function()
    it("performs no container scan on a repeated lookup", function()
      bags[0] = { { itemId = 11111 }, { itemId = 22222 } }

      itemLocationCache.GetBagEntries()
      containerCalls.numSlots = 0
      containerCalls.itemLink = 0

      itemLocationCache.GetBagEntries()
      itemLocationCache.GetItemLocations(11111)

      assert.are.equal(0, containerCalls.numSlots)
      assert.are.equal(0, containerCalls.itemLink)
    end)

    it("resolves FindItemInBag without per-slot iteration once the cache is built", function()
      bags[0] = { { itemId = 11111 }, { itemId = 22222 }, { itemId = 33333 } }
      bags[1] = { { itemId = 44444 } }

      itemLocationCache.GetBagEntries()
      containerCalls.numSlots = 0
      containerCalls.itemLink = 0

      local bagNumber, bagPos = itemManager.FindItemInBag(33333, nil, nil)

      assert.are.equal(0, bagNumber)
      assert.are.equal(3, bagPos)
      -- no bag walk; only the single candidate slot is re-read for the stale-entry guard
      assert.are.equal(0, containerCalls.numSlots)
      assert.are.equal(1, containerCalls.itemLink)
    end)
  end)

  describe("invalidation", function()
    it("rescans the live bags on the next lookup after Invalidate", function()
      bags[0] = { { itemId = 11111 } }
      itemLocationCache.GetBagEntries()

      -- the item moves to another bag and the matching bag event invalidates the cache
      bags[0] = { false }
      bags[3] = { { itemId = 11111 } }
      itemLocationCache.Invalidate()

      local bagNumber, bagPos = itemManager.FindItemInBag(11111, nil, nil)

      assert.are.equal(3, bagNumber)
      assert.are.equal(1, bagPos)
    end)
  end)

  describe("stale-entry guard", function()
    it("never returns a location whose live content no longer matches the cache", function()
      bags[0] = { { itemId = 11111 } }
      itemLocationCache.GetBagEntries()

      -- the bag content changes without any invalidation (simulates a missed event)
      bags[0] = { { itemId = 99999 } }

      local bagNumber, bagPos = itemManager.FindItemInBag(11111, nil, nil)

      assert.is_nil(bagNumber)
      assert.is_nil(bagPos)
    end)

    it("finds the item at its new location through the one-shot rescan retry", function()
      bags[0] = { { itemId = 11111 }, false }
      itemLocationCache.GetBagEntries()

      -- the item moves within the bag without any invalidation (simulates a missed event)
      bags[0] = { { itemId = 99999 }, { itemId = 11111 } }

      local bagNumber, bagPos = itemManager.FindItemInBag(11111, nil, nil)

      assert.are.equal(0, bagNumber)
      assert.are.equal(2, bagPos)
    end)
  end)

  describe("equivalence with the pre-cache full bag rescan", function()
    before_each(function()
      itemInfoById = {
        [11111] = { name = "Plain Trinket", quality = 2, equipSlot = "INVTYPE_TRINKET", icon = 1 },
        [22222] = { name = "Epic Trinket", quality = 4, equipSlot = "INVTYPE_TRINKET", icon = 2 },
        [33333] = { name = "Runed Chest", quality = 3, equipSlot = "INVTYPE_CHEST", icon = 3 },
        [44444] = { name = "Enchanted Cloak", quality = 3, equipSlot = "INVTYPE_CLOAK", icon = 4 }
      }
      bags[0] = { { itemId = 11111 }, false, { itemId = 33333, rune = { skillLineAbilityID = 7 } } }
      bags[1] = { { itemId = 44444, enchantId = 60 }, { itemId = 22222 } }
      bags[3] = { { itemId = 11111, enchantId = 70 }, false, { itemId = 33333 } }
    end)

    it("returns identical FindItemInBag results across match modes", function()
      local probes = {
        { 11111, nil, nil }, -- plain hit
        { 11111, 70, nil },  -- enchant match
        { 33333, nil, 7 },   -- rune match
        { 33333, nil, nil }, -- un-runed copy
        { 44444, 50, nil },  -- enchant miss
        { 99999, nil, nil }  -- not in bags
      }

      for _, withFallback in ipairs({ false, true }) do
        fallbackEnabled = withFallback

        for _, probe in ipairs(probes) do
          local expected = { referenceFindItemInBag(probe[1], probe[2], probe[3]) }
          local actual = { itemManager.FindItemInBag(probe[1], probe[2], probe[3]) }

          assert.are.same(expected, actual)
        end
      end
    end)

    it("returns identical GetItemsForInventoryType results", function()
      local inventoryType = { "INVTYPE_TRINKET", "INVTYPE_CHEST" }

      assert.are.same(
        referenceGetItemsForInventoryType(inventoryType),
        itemManager.GetItemsForInventoryType(inventoryType)
      )
    end)

    it("returns identical GetItemsForInventoryType results with a quality filter", function()
      filterItemQuality = 3

      assert.are.same(
        referenceGetItemsForInventoryType({ "INVTYPE_TRINKET" }),
        itemManager.GetItemsForInventoryType({ "INVTYPE_TRINKET" })
      )
    end)
  end)
end)
