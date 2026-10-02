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
  Spec for the rune lookups in code/Engrave.lua. Every lookup is gated on Season of Discovery being
  active (mod.season.IsSodActive) and on the slot being engravable, so outside SoD - and for a slot
  that cannot hold a rune - C_Engraving is never asked for a rune and the lookup yields nil.
  C_Engraving records its calls; mod.season and mod.logger are stubs.
]]--

local wowStubs = require("WowStubs")

local RUNE = { skillLineAbilityID = 6720 }
local BAG = 1
local BAG_POS = 4
local SLOT_ID = 5

describe("Engrave", function()
  local engrave
  local sodActive
  local engravable
  local calls
  local previous
  local restore

  --[[
    A C_Engraving function that records its call and answers through the passed result function

    @param {string} name
    @param {function} result

    @return {function}
  ]]--
  local function record(name, result)
    return function(...)
      calls[#calls + 1] = { name, ... }

      return result()
    end
  end

  before_each(function()
    sodActive = true
    engravable = true
    calls = {}

    previous = { season = rggm.season, logger = rggm.logger }
    rggm.season = { IsSodActive = function() return sodActive end }
    rggm.logger = { LogDebug = function() end }

    restore = wowStubs.install({
      C_Engraving = {
        IsEquipmentSlotEngravable = record("IsEquipmentSlotEngravable", function() return engravable end),
        IsInventorySlotEngravable = record("IsInventorySlotEngravable", function() return engravable end),
        GetRuneForEquipmentSlot = record("GetRuneForEquipmentSlot", function() return RUNE end),
        GetRuneForInventorySlot = record("GetRuneForInventorySlot", function() return RUNE end),
        RefreshRunesList = record("RefreshRunesList", function() end)
      }
    })

    dofile("code/Engrave.lua")
    engrave = rggm.engrave
  end)

  after_each(function()
    restore()

    for name, module in pairs(previous) do
      rggm[name] = module
    end
  end)

  it("follows the Season of Discovery check", function()
    assert.is_true(engrave.IsEngravingActive())

    sodActive = false

    assert.is_false(engrave.IsEngravingActive())
  end)

  describe("outside Season of Discovery", function()
    before_each(function()
      sodActive = false
    end)

    it("never asks the engraving api", function()
      assert.is_nil(engrave.GetRuneForEquipmentSlot(SLOT_ID))
      assert.is_nil(engrave.GetRuneForInventorySlot(BAG, BAG_POS))
      assert.is_nil(engrave.IsEquipmentSlotEngravable(SLOT_ID))
      assert.is_nil(engrave.IsInventorySlotEngravable(BAG, BAG_POS))
      engrave.RefreshRunes()

      assert.are.same({}, calls)
    end)
  end)

  describe("in Season of Discovery", function()
    it("returns the rune of an engravable equipment slot", function()
      assert.are.equal(RUNE, engrave.GetRuneForEquipmentSlot(SLOT_ID))
      assert.are.same({
        { "IsEquipmentSlotEngravable", SLOT_ID },
        { "GetRuneForEquipmentSlot", SLOT_ID }
      }, calls)
    end)

    it("returns the rune of an engravable bag slot", function()
      assert.are.equal(RUNE, engrave.GetRuneForInventorySlot(BAG, BAG_POS))
      assert.are.same({
        { "IsInventorySlotEngravable", BAG, BAG_POS },
        { "GetRuneForInventorySlot", BAG, BAG_POS }
      }, calls)
    end)

    it("does not ask for the rune of a slot that cannot be engraved", function()
      engravable = false

      assert.is_nil(engrave.GetRuneForEquipmentSlot(SLOT_ID))
      assert.is_nil(engrave.GetRuneForInventorySlot(BAG, BAG_POS))
      assert.are.same({
        { "IsEquipmentSlotEngravable", SLOT_ID },
        { "IsInventorySlotEngravable", BAG, BAG_POS }
      }, calls)
    end)

    it("refreshes the rune list", function()
      engrave.RefreshRunes()

      assert.are.same({ { "RefreshRunesList" } }, calls)
    end)
  end)
end)
