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
  Spec for the simple item tooltip in code/Tooltip.lua (me.UpdateTooltipForItem with the simple
  tooltip option, me.BuildSimpleTooltip). An item the client has not cached yet has no name or
  quality; the tooltip then stays hidden instead of passing a nil quality on or showing an empty
  box.

  The tooltip frame is a recorder installed under RGGM_CONSTANTS.ELEMENT_TOOLTIP. C_Item serves
  the items of a per-test cache, and its GetItemQualityColor raises on a nil quality - the worst
  case of what the client might do with one.
]]--

local wowStubs = require("WowStubs")

local ITEM_ID = 12345

describe("Tooltip simple tooltip", function()
  local tooltipModule
  local tooltip
  -- itemCache[itemId] -> { name, quality } for items the client has cached
  local itemCache
  local restore

  before_each(function()
    itemCache = {}
    tooltip = { lines = {}, shown = false }

    function tooltip.ClearLines(self) self.lines = {} end
    function tooltip.SetOwner() end
    function tooltip.AddLine(self, text, r, g, b)
      self.lines[#self.lines + 1] = { text = text, r = r, g = g, b = b }
    end
    function tooltip.Show(self) self.shown = true end
    function tooltip.Hide(self) self.shown = false end

    rggm.configuration = {
      IsTooltipsEnabled = function() return true end,
      IsSimpleTooltipsEnabled = function() return true end
    }

    restore = wowStubs.install({
      [RGGM_CONSTANTS.ELEMENT_TOOLTIP] = tooltip,
      UIParent = {},
      GameTooltip_SetDefaultAnchor = function() end,
      C_Item = {
        GetItemInfo = function(itemId)
          local item = itemCache[itemId]

          if item == nil then return nil end

          return item.name, nil, item.quality
        end,
        GetItemQualityColor = function(quality)
          assert(quality ~= nil, "bad argument #1 to 'GetItemQualityColor'")

          return 0.64, 0.21, 0.93
        end
      }
    })

    dofile("code/Tooltip.lua")
    tooltipModule = rggm.tooltip
  end)

  after_each(function()
    restore()
  end)

  it("shows the item name in its quality colour for a cached item", function()
    itemCache[ITEM_ID] = { name = "Test Trinket", quality = 4 }

    tooltipModule.UpdateTooltipForItem({ itemId = ITEM_ID })

    assert.is_true(tooltip.shown)
    assert.are.same({ { text = "Test Trinket", r = 0.64, g = 0.21, b = 0.93 } }, tooltip.lines)
  end)

  it("stays hidden without raising for an item the client has not cached yet", function()
    assert.has_no.errors(function() tooltipModule.UpdateTooltipForItem({ itemId = ITEM_ID }) end)

    assert.is_false(tooltip.shown)
    assert.are.same({}, tooltip.lines)
  end)

  it("shows the item once the client has cached it", function()
    tooltipModule.UpdateTooltipForItem({ itemId = ITEM_ID })
    itemCache[ITEM_ID] = { name = "Test Trinket", quality = 4 }

    tooltipModule.UpdateTooltipForItem({ itemId = ITEM_ID })

    assert.is_true(tooltip.shown)
    assert.are.equal(1, #tooltip.lines)
  end)
end)
