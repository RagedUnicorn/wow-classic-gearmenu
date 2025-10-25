--[[
  MIT License

  Copyright (c) 2025 Michael Wiesendanger

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

-- luacheck: globals GetItemInfo GetItemQualityColor UIParent GameTooltip_SetDefaultAnchor strmatch GetInventoryItemID

local mod = rggm
local me = {}
mod.tooltip = me

me.tag = "Tooltip"

--[[
  Update the tooltip to show the information for the passed item

  @param {table} item
]]--
function me.UpdateTooltipForItem(item)
  if item.itemId == nil then return end
  if not mod.configuration.IsTooltipsEnabled() then return end

  local tooltip = me.PrepareTooltip()

  if mod.configuration.IsSimpleTooltipsEnabled() then
    me.BuildSimpleTooltip(tooltip, item.itemId)
  else
    if item.bag and item.slot then
      tooltip:SetBagItem(item.bag, item.slot)
    else
      tooltip:SetInventoryItem(RGGM_CONSTANTS.UNIT_ID_PLAYER, item.inventorySlotId)
    end
  end

  tooltip:Show()
end

--[[
  Update the tooltip to show the information for the item in the passed slot

  @param {number} inventorySlotId
]]--
function me.UpdateTooltipForSlot(inventorySlotId)
  if inventorySlotId == nil then return end

  local item = {
    inventorySlotId = inventorySlotId,
    itemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, inventorySlotId)
  }

  me.UpdateTooltipForItem(item)
end

--[[
  Update the tooltip to show the information for the item in the bag

  @param {number} itemId
]]--
function me.UpdateTooltipForBagItem(itemId)
  if itemId == nil then return end

  local bag, slot = mod.itemManager.FindItemInBag(itemId)
  if bag == nil or slot == nil then return end

  local item = {
    bag = bag,
    slot = slot,
    itemId = itemId
  }

  me.UpdateTooltipForItem(item)
end

--[[
  Prepare the tooltip for usage

  @return {table}
]]--
function me.PrepareTooltip()
  local tooltip = _G[RGGM_CONSTANTS.ELEMENT_TOOLTIP]
  tooltip:ClearLines()
  tooltip:SetOwner(UIParent)
  GameTooltip_SetDefaultAnchor(tooltip, UIParent)

  return tooltip
end

--[[
  Build a simple tooltip for the passed itemId

  @param {table} tooltip
  @param {number} itemId
]]--
function me.BuildSimpleTooltip(tooltip, itemId)
  local itemName, _, itemRarity = GetItemInfo(itemId)
  local  _, _, _, hexColor = GetItemQualityColor(itemRarity)

  tooltip:AddLine("|c" .. hexColor .. itemName .. "|h|r")
end

--[[
  Remove tooltip after region leave
]]--
function me.TooltipClear()
  _G[RGGM_CONSTANTS.ELEMENT_TOOLTIP]:Hide()
end

--[[
  @param {string} line1
  @param {string} line2
]]--
function me.BuildTooltipForOption(line1, line2)
  local tooltip = _G[RGGM_CONSTANTS.ELEMENT_TOOLTIP]

  tooltip:SetOwner(UIParent)
  GameTooltip_SetDefaultAnchor(tooltip, UIParent)
  tooltip:AddLine(line1)
  tooltip:AddLine(line2, .8, .8, .8, 1)

  tooltip:Show()
end
