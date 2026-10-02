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
  Spec for the frame size of the trinketMenu in gui/TrinketMenu.lua (me.UpdateTrinketMenuSize).
  The height follows the slots that are actually shown - at most TRINKET_MENU_DEFAULT_SLOT_AMOUNT,
  and at least one row so an empty trinketMenu can still be grabbed and moved.

  me.BuildTrinketMenu runs against a fake CreateFrame whose frame accepts any call and records
  SetHeight / SetWidth. The grid math is the real gui/UiHelper.lua; the slot pool, drag setup and
  slot layout are stubbed out because they are not under test.
]]--

local wowStubs = require("WowStubs")

local SLOT_SIZE = 40
local COLUMNS = 4

describe("TrinketMenu size", function()
  local trinketMenu
  local frame
  local restore

  --[[
    The height the trinketMenu should have for a number of rows

    @param {number} rows

    @return {number}
  ]]--
  local function heightForRows(rows)
    return rows * SLOT_SIZE
  end

  before_each(function()
    -- a frame that ignores every call except the size it is given
    frame = setmetatable({}, {
      __index = function(_, method)
        if method == "SetHeight" then
          return function(self, height) self.height = height end
        elseif method == "SetWidth" then
          return function(self, width) self.width = width end
        elseif method == "GetName" then
          return function() return RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_FRAME_NAME end
        end

        return function() end
      end
    })

    rggm.configuration = {
      GetTrinketMenuSlotSize = function() return SLOT_SIZE end,
      GetTrinketMenuColumnAmount = function() return COLUMNS end,
      GetUserPlacedFramePosition = function() return nil end
    }
    rggm.itemManager = { GetItemsForInventoryType = function() return {} end }

    restore = wowStubs.install({
      CreateFrame = function() return frame end,
      UIParent = {},
      -- WoW keeps the Lua 5.1 global the default position is spread with
      unpack = unpack or table.unpack -- luacheck: ignore 143 (Lua 5.4 field, the std is lua51)
    })

    dofile("gui/UiHelper.lua")
    rggm.uiHelper.CreateFramePool = function()
      return { Acquire = function() return frame end }
    end

    dofile("gui/TrinketMenu.lua")
    trinketMenu = rggm.trinketMenu
    trinketMenu.SetupDragFrame = function() end
    trinketMenu.CreateTrinketMenuSlots = function() end
    trinketMenu.UpdateTrinketMenuLockedState = function() end
    trinketMenu.UpdateTrinketMenuSlotSize = function() end
    trinketMenu.BuildTrinketMenu()
  end)

  after_each(function()
    restore()
  end)

  it("sizes the height to the rows the trinkets fill", function()
    trinketMenu.UpdateTrinketMenuSize(6)

    assert.are.equal(heightForRows(2), frame.height)
  end)

  it("keeps one row of height for an empty trinketMenu so it can still be moved", function()
    trinketMenu.UpdateTrinketMenuSize(0)

    assert.is_true(frame.height > 0)
    assert.are.equal(heightForRows(1), frame.height)
  end)

  it("stops growing past the slots that are actually shown", function()
    local maxRows = math.ceil(RGGM_CONSTANTS.TRINKET_MENU_DEFAULT_SLOT_AMOUNT / COLUMNS)

    trinketMenu.UpdateTrinketMenuSize(RGGM_CONSTANTS.TRINKET_MENU_DEFAULT_SLOT_AMOUNT + 25)

    assert.are.equal(heightForRows(maxRows), frame.height)
  end)
end)
