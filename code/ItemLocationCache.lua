--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- luacheck: globals C_Container

--[[
  In-memory cache of where items sit in the players bags. One full scan over bags 0-4 records
  every occupied slot as an entry { bagNumber, bagPos, itemId, enchantId }; consumers iterate
  those entries instead of walking every bag slot per lookup (ItemManager.FindItemInBag runs on
  the combat queue ticker, ItemManager.GetItemsForInventoryType per menu refresh).

  The cache starts dirty and rebuilds lazily on the next lookup after Invalidate. Core marks it
  dirty on BAG_UPDATE and ITEM_LOCK_CHANGED. Rune engravings are deliberately not cached - a rune
  changes through engraving without any bag event firing, so consumers read runes live per
  candidate slot.
]]--
local mod = rggm
local me = {}
mod.itemLocationCache = me

me.tag = "ItemLocationCache"

-- occupied bag slots in scan order (bag 0-4, slot 1-n); each entry is { bagNumber, bagPos, itemId, enchantId }
local bagEntries = {}
-- entries grouped by itemId, preserving scan order within each group
local bagEntriesByItemId = {}
-- whether the cached entries no longer reflect the live bag contents
local dirty = true

-- forward declarations
local RebuildCache

--[[
  Mark the cached entries as stale. The next lookup rebuilds the cache with a full bag scan.
]]--
function me.Invalidate()
  dirty = true
end

--[[
  Retrieve all occupied bag slots in bag/slot scan order, rebuilding the cache first if it is stale.

  @return {table}
    list of { bagNumber, bagPos, itemId, enchantId } entries
]]--
function me.GetBagEntries()
  if dirty then
    RebuildCache()
  end

  return bagEntries
end

--[[
  Retrieve the bag locations holding a copy of the passed item, rebuilding the cache first if it
  is stale.

  @param {number} itemId

  @return {table}
    list of { bagNumber, bagPos, itemId, enchantId } entries; empty if the item is not in the bags
]]--
function me.GetItemLocations(itemId)
  if dirty then
    RebuildCache()
  end

  return bagEntriesByItemId[itemId] or {}
end

--[[
  Rebuild the cached entries with a single full scan over bags 0-4.
]]--
RebuildCache = function()
  bagEntries = {}
  bagEntriesByItemId = {}

  for bagNumber = 0, 4 do
    for bagPos = 1, C_Container.GetContainerNumSlots(bagNumber) do
      local itemInfo = mod.common.GetItemInfo(C_Container.GetContainerItemLink(bagNumber, bagPos))

      if itemInfo.itemId then
        local entry = {
          bagNumber = bagNumber,
          bagPos = bagPos,
          itemId = itemInfo.itemId,
          enchantId = itemInfo.enchantId
        }

        table.insert(bagEntries, entry)

        if not bagEntriesByItemId[entry.itemId] then
          bagEntriesByItemId[entry.itemId] = {}
        end

        table.insert(bagEntriesByItemId[entry.itemId], entry)
      end
    end
  end

  dirty = false
  mod.logger.LogDebug(me.tag, "Rebuilt item location cache with " .. #bagEntries .. " entries")
end
