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
  Spec for the slot highlight of the custom theme in gui/ThemeCustom.lua. A click flashes the
  gearSlot border - yellow for a left click, red for a right click (dropping a queued swap) - and
  half a second later the border goes back to the hover color while the mouse is still over the
  gearBar, or hides. Hover and leave show and hide the border of every slot kind. The slot
  constructors only build frames and are not covered here (see DEVELOPMENT.md).
]]--

local wowStubs = require("WowStubs")

describe("ThemeCustom", function()
  local theme
  local timers
  local mouseOver
  local restore

  --[[
    A slot whose highlight frame records its shown state and border color

    @return {table}
  ]]--
  local function FakeSlot()
    local highlightFrame = { shown = false }

    function highlightFrame:Show() self.shown = true end
    function highlightFrame:Hide() self.shown = false end
    function highlightFrame:SetBackdropBorderColor(...) self.color = { ... } end

    return {
      highlightFrame = highlightFrame,
      GetParent = function() return "gearBarFrame" end
    }
  end

  before_each(function()
    timers = {}
    mouseOver = false

    restore = wowStubs.install({
      C_Timer = {
        After = function(delay, callback) timers[#timers + 1] = { delay = delay, callback = callback } end
      },
      MouseIsOver = function(frame)
        assert.are.equal("gearBarFrame", frame)
        return mouseOver
      end,
      -- the client's Lua 5.1 global the theme unpacks its colors with
      unpack = unpack or rawget(table, "unpack")
    })

    dofile("gui/ThemeCustom.lua")
    theme = rggm.themeCustom
  end)

  after_each(function()
    restore()
  end)

  describe("gearSlot click", function()
    it("flashes the border yellow on a left click", function()
      local slot = FakeSlot()

      theme.GearSlotOnClick(slot, "LeftButton")

      assert.is_true(slot.highlightFrame.shown)
      assert.are.same(RGGM_CONSTANTS.HIGHLIGHT.highlight, slot.highlightFrame.color)
    end)

    it("flashes the border red on a right click", function()
      local slot = FakeSlot()

      theme.GearSlotOnClick(slot, "RightButton")

      assert.are.same(RGGM_CONSTANTS.HIGHLIGHT.remove, slot.highlightFrame.color)
    end)

    it("goes back to the hover color after half a second while the mouse is over the gearBar", function()
      local slot = FakeSlot()

      mouseOver = true
      theme.GearSlotOnClick(slot, "LeftButton")

      assert.are.equal(0.5, timers[1].delay)

      timers[1].callback()

      assert.is_true(slot.highlightFrame.shown)
      assert.are.same(RGGM_CONSTANTS.HIGHLIGHT.hover, slot.highlightFrame.color)
    end)

    it("hides the border after half a second once the mouse left the gearBar", function()
      local slot = FakeSlot()

      theme.GearSlotOnClick(slot, "LeftButton")
      timers[1].callback()

      assert.is_false(slot.highlightFrame.shown)
    end)
  end)

  describe("hover", function()
    for _, slotKind in ipairs({ "GearSlot", "ChangeSlot", "TrinketMenuSlot" }) do
      it("shows the border while a " .. slotKind .. " is hovered and hides it on leave", function()
        local slot = FakeSlot()

        theme[slotKind .. "OnEnter"](slot)
        assert.is_true(slot.highlightFrame.shown)

        theme[slotKind .. "OnLeave"](slot)
        assert.is_false(slot.highlightFrame.shown)
      end)
    end

    it("hides the border of a reset changeMenu and trinketMenu slot", function()
      local changeSlot = FakeSlot()
      local trinketSlot = FakeSlot()

      changeSlot.highlightFrame:Show()
      trinketSlot.highlightFrame:Show()

      theme.ChangeMenuSlotReset(changeSlot)
      theme.TrinketMenuSlotReset(trinketSlot)

      assert.is_false(changeSlot.highlightFrame.shown)
      assert.is_false(trinketSlot.highlightFrame.shown)
    end)
  end)
end)
