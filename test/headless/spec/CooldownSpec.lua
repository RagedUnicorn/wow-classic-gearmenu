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
  Spec for the cooldown overlay of a slot in gui/Cooldown.lua (me.CreateCooldownOverlay,
  me.UpdateGearSlotCooldown, me.UpdateGearSlotCooldownOverlaySize).

  UpdateGearSlotCooldown decides between showing a cooldown and clearing the overlay: an empty
  slot, a gearBar with cooldowns switched off and an item without a running cooldown all clear
  it. CooldownFrame_Set / CooldownFrame_Clear, C_Container.GetItemCooldown and
  GetInventoryItemID are stubbed; CreateFrame returns a fake Cooldown frame that records the
  swipe setup, its anchors, its size and the font of its countdown text. The overlay layout depends on
  the ui theme: the custom theme fills the slot, the classic theme centers it 2 pixels smaller.
]]--

local wowStubs = require("WowStubs")

local GEAR_BAR_ID = 2
local ITEM_ID = 19950
local SLOT_ID = 13
local SLOT_SIZE = 45
local TEXT_FONT = "Fonts\\FRIZQT__.TTF"
local COOLDOWN_TYPE = 1

--[[
  A fake Cooldown frame recording the calls CreateCooldownOverlay and the layout make

  @return {table}
]]--
local function CreateFakeCooldownFrame(frameType, name, parent, template)
  local frame = {
    frameType = frameType,
    name = name,
    parent = parent,
    template = template,
    points = {},
    font = nil
  }
  local fontString = {
    SetFont = function(_, font, size) frame.font = { font = font, size = size } end
  }

  function frame:SetDrawBling(draw) self.drawBling = draw end
  function frame:SetDrawEdge(draw) self.drawEdge = draw end
  function frame:SetSwipeColor(r, g, b, a) self.swipeColor = { r, g, b, a } end
  function frame:SetHideCountdownNumbers(hide) self.hideCountdownNumbers = hide end
  function frame:ClearAllPoints() self.points = {} end
  function frame:SetAllPoints(relativeTo) self.allPoints = relativeTo end
  function frame:SetSize(width, height) self.size = { width, height } end

  function frame:SetPoint(point, relativeTo, relativePoint, x, y)
    self.points[point] = { relativeTo = relativeTo, relativePoint = relativePoint, x = x, y = y }
  end

  frame.GetRegions = function() return fontString end

  return frame
end

describe("Cooldown", function()
  local cooldown
  local itemId
  local showCooldowns
  local itemCooldown
  local cooldownCalls
  local previous
  local restore

  local function UpdateGearSlot()
    local uiSlot = { cooldownOverlay = {} }

    cooldown.UpdateGearSlotCooldown({ id = GEAR_BAR_ID }, uiSlot, { slotId = SLOT_ID })

    return uiSlot.cooldownOverlay
  end

  before_each(function()
    itemId = ITEM_ID
    showCooldowns = true
    itemCooldown = { 0, 0 }
    cooldownCalls = {}

    previous = { gearBarManager = rggm.gearBarManager }
    rggm.gearBarManager = {
      IsShowCooldownsEnabled = function(gearBarId)
        assert.are.equal(GEAR_BAR_ID, gearBarId)
        return showCooldowns
      end
    }

    restore = wowStubs.install({
      CreateFrame = CreateFakeCooldownFrame,
      STANDARD_TEXT_FONT = TEXT_FONT,
      COOLDOWN_TYPE_NORMAL = COOLDOWN_TYPE,
      GetInventoryItemID = function(unit, slotId)
        assert.are.equal(RGGM_CONSTANTS.UNIT_ID_PLAYER, unit)
        assert.are.equal(SLOT_ID, slotId)
        return itemId
      end,
      C_Container = {
        GetItemCooldown = function() return itemCooldown[1], itemCooldown[2] end
      },
      CooldownFrame_Set = function(overlay, startTime, duration, enable)
        cooldownCalls[#cooldownCalls + 1] = {
          "set", overlay = overlay, startTime = startTime, duration = duration, enable = enable
        }
      end,
      CooldownFrame_Clear = function(overlay)
        cooldownCalls[#cooldownCalls + 1] = { "clear", overlay = overlay }
      end
    })

    dofile("gui/Cooldown.lua")
    cooldown = rggm.cooldown
  end)

  after_each(function()
    restore()
    rggm.gearBarManager = previous.gearBarManager
  end)

  describe("UpdateGearSlotCooldown", function()
    it("shows the running cooldown of the equipped item", function()
      itemCooldown = { 1000, 120 }

      local overlay = UpdateGearSlot()

      assert.are.equal(1, #cooldownCalls)
      assert.are.equal("set", cooldownCalls[1][1])
      assert.are.equal(overlay, cooldownCalls[1].overlay)
      assert.are.equal(1000, cooldownCalls[1].startTime)
      assert.are.equal(120, cooldownCalls[1].duration)
      assert.is_true(cooldownCalls[1].enable)
    end)

    it("clears the overlay when the item has no cooldown running", function()
      local overlay = UpdateGearSlot()

      assert.are.same({ { "clear", overlay = overlay } }, cooldownCalls)
    end)

    it("clears the overlay when the item cooldown is unknown", function()
      itemCooldown = { nil, nil }

      UpdateGearSlot()

      assert.are.equal("clear", cooldownCalls[1][1])
    end)

    it("clears the overlay of an empty slot without asking for a cooldown", function()
      itemId = nil
      itemCooldown = { 1000, 120 }

      UpdateGearSlot()

      assert.are.equal(1, #cooldownCalls)
      assert.are.equal("clear", cooldownCalls[1][1])
    end)

    it("clears the overlay when the gearBar does not show cooldowns", function()
      showCooldowns = false
      itemCooldown = { 1000, 120 }

      UpdateGearSlot()

      assert.are.equal(1, #cooldownCalls)
      assert.are.equal("clear", cooldownCalls[1][1])
    end)
  end)

  describe("CreateCooldownOverlay", function()
    local slot

    local function CreateOverlay(uiTheme)
      return cooldown.CreateCooldownOverlay(slot, RGGM_CONSTANTS.ELEMENT_SLOT_COOLDOWN_FRAME, SLOT_SIZE, uiTheme)
    end

    before_each(function()
      slot = {}
    end)

    it("creates a Cooldown frame from the CooldownFrameTemplate on the slot", function()
      local overlay = CreateOverlay(RGGM_CONSTANTS.UI_THEME_CUSTOM)

      assert.are.equal("Cooldown", overlay.frameType)
      assert.are.equal(RGGM_CONSTANTS.ELEMENT_SLOT_COOLDOWN_FRAME, overlay.name)
      assert.are.equal(slot, overlay.parent)
      assert.are.equal("CooldownFrameTemplate", overlay.template)
    end)

    it("shows the countdown numbers of a normal cooldown", function()
      local overlay = CreateOverlay(RGGM_CONSTANTS.UI_THEME_CUSTOM)

      assert.is_false(overlay.hideCountdownNumbers)
      assert.are.equal(COOLDOWN_TYPE, overlay.currentCooldownType)
    end)

    it("fills the slot in the custom theme and scales the countdown text with the slot size", function()
      local overlay = CreateOverlay(RGGM_CONSTANTS.UI_THEME_CUSTOM)

      assert.are.equal(slot, overlay.allPoints)
      assert.is_nil(overlay.size)
      assert.are.equal(TEXT_FONT, overlay.font.font)
      assert.are.equal(SLOT_SIZE * RGGM_CONSTANTS.GEAR_BAR_COOLDOWN_TEXT_MODIFIER, overlay.font.size)
    end)

    it("sits centered and 2 pixels smaller than the slot in the classic theme", function()
      local overlay = CreateOverlay(RGGM_CONSTANTS.UI_THEME_CLASSIC)

      assert.is_nil(overlay.allPoints)
      assert.are.same({ relativeTo = slot, relativePoint = 0, x = 0 }, overlay.points.CENTER)
      assert.are.same({ SLOT_SIZE - 2, SLOT_SIZE - 2 }, overlay.size)
    end)

    it("resizes the overlay and its text after the slot was resized", function()
      local overlay = CreateOverlay(RGGM_CONSTANTS.UI_THEME_CLASSIC)
      local resized = 30

      slot.cooldownOverlay = overlay
      cooldown.UpdateGearSlotCooldownOverlaySize(slot, resized)

      assert.are.same({ resized, resized }, overlay.size)
      assert.are.equal(resized * RGGM_CONSTANTS.GEAR_BAR_COOLDOWN_TEXT_MODIFIER, overlay.font.size)
    end)
  end)
end)
