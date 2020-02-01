--[[
  MIT License

  Copyright (c) 2020 Michael Wiesendanger

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

-- luacheck: globals GetContainerItemLink GetItemInfo GetItemQualityColor GetInventoryItemLink
-- luacheck: globals UIParent GameTooltip_SetDefaultAnchor

local mod = rggm
local me = {}
mod.tooltip = me

me.tag = "Tooltip"

local TOOLTIP_TYPE_BAG = "Bag"
local TOOLTIP_TYPE_ITEMSLOT = "ItemSlot"

--[[
  Build tooltip for an item in the players bag

  @param {number} slotId
  @param {number} itemId
]]--
function me.BuildTooltipForBaggedItem(slotId, itemId)
  me.TooltipUpdate(TOOLTIP_TYPE_BAG, slotId, itemId)
end

--[[
  Build tooltip for an item that is worn by the player

  @param {number} slotId
]]--
function me.BuildTooltipForWornItem(slotId)
  me.TooltipUpdate(TOOLTIP_TYPE_ITEMSLOT, slotId)
end

--[[
  Update the tooltip for either an item in the players bag or an item that he is currently wearing.

  @param {string} tooltipType
  @param {number} slotId
  @param {number} itemId

]]--
function me.TooltipUpdate(tooltipType, slotId, itemId)
  if not mod.configuration.IsTooltipsEnabled() then return end

  local tooltip = _G[RGGM_CONSTANTS.ELEMENT_TOOLTIP]
  tooltip:ClearLines()
  tooltip:SetOwner(UIParent)
  GameTooltip_SetDefaultAnchor(tooltip, UIParent)

  if tooltipType == TOOLTIP_TYPE_BAG then
    local bagNumber, bagPos = mod.itemManager.FindItemInBag(itemId)
    if mod.configuration.IsSimpleTooltipsEnabled() then
      if not bagNumber or not bagPos then return end

      local itemLink = GetContainerItemLink(bagNumber, bagPos)

      if itemLink then
        local itemName, _, itemRarity = GetItemInfo(itemLink)
        local _, _, _, hexColor = GetItemQualityColor(itemRarity)

        tooltip:AddLine("|c" .. hexColor .. itemName .. "|h|r")
      end
    else
      tooltip:SetBagItem(bagNumber, bagPos)
    end
  else
    if mod.configuration.IsSimpleTooltipsEnabled() then
      local itemLink = GetInventoryItemLink(RGGM_CONSTANTS.UNIT_ID_PLAYER, slotId)
      if itemLink then
        local itemName, _, itemRarity = GetItemInfo(itemLink)
        local _, _, _, hexColor = GetItemQualityColor(itemRarity)

        tooltip:AddLine("|c" .. hexColor .. itemName .. "|h|r")
      end
    else
      tooltip:SetInventoryItem(RGGM_CONSTANTS.UNIT_ID_PLAYER, slotId)
    end
  end

  tooltip:Show()
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
