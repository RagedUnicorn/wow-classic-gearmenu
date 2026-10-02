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
  Spec for the rune slots in gui/EngraveFrame.lua: which rune icon a gearSlot and a changeSlot
  show. Outside Season of Discovery nothing is created or touched; with the rune slot option off
  the icon is cleared; otherwise it shows the rune engraved on the item, or nothing for an item
  without a rune or a slot that cannot be engraved. mod.engrave, mod.season and the configuration
  are stubs; the rune slot is a fake whose icon keeps the last texture set.
]]--

local wowStubs = require("WowStubs")

local SLOT_ID = 5
local RUNE = { iconTexture = 236000 }

describe("EngraveFrame", function()
  local engraveFrame
  local sodActive
  local runeSlotsEnabled
  local engravable
  local rune
  local createdFrames
  local previous
  local restore

  --[[
    A slot carrying a rune slot whose icon remembers its texture

    @param {any} texture
      the texture the icon starts with

    @return {table}
  ]]--
  local function FakeSlot(texture)
    local icon = { texture = texture }

    function icon:SetTexture(value)
      self.texture = value
    end

    return { runeSlot = { icon = icon } }
  end

  before_each(function()
    sodActive = true
    runeSlotsEnabled = true
    engravable = true
    rune = RUNE
    createdFrames = 0

    previous = {
      engraveFrame = rggm.engraveFrame,
      season = rggm.season,
      engrave = rggm.engrave,
      configuration = rggm.configuration,
      gearBarStorage = rggm.gearBarStorage,
      logger = rggm.logger
    }

    rggm.season = { IsSodActive = function() return sodActive end }
    rggm.engrave = {
      IsEngravingActive = function() return sodActive end,
      IsEquipmentSlotEngravable = function(slotId)
        assert.are.equal(SLOT_ID, slotId)
        return engravable
      end,
      GetRuneForEquipmentSlot = function() return rune end
    }
    rggm.configuration = { IsRuneSlotsEnabled = function() return runeSlotsEnabled end }
    rggm.logger = { LogDebug = function() end }

    restore = wowStubs.install({
      CreateFrame = function()
        createdFrames = createdFrames + 1
      end
    })

    dofile("gui/EngraveFrame.lua")
    engraveFrame = rggm.engraveFrame
  end)

  after_each(function()
    restore()

    for name, module in pairs(previous) do
      rggm[name] = module
    end
  end)

  describe("gearSlot rune", function()
    it("shows the rune engraved on the equipped item", function()
      local slot = FakeSlot(nil)

      engraveFrame.UpdateRuneSlotTexture(slot, { slotId = SLOT_ID })

      assert.are.equal(RUNE.iconTexture, slot.runeSlot.icon.texture)
    end)

    it("clears the icon of an item without a rune", function()
      local slot = FakeSlot(RUNE.iconTexture)

      rune = nil
      engraveFrame.UpdateRuneSlotTexture(slot, { slotId = SLOT_ID })

      assert.is_nil(slot.runeSlot.icon.texture)
    end)

    it("clears the icon while the rune slot option is off", function()
      local slot = FakeSlot(RUNE.iconTexture)

      runeSlotsEnabled = false
      engraveFrame.UpdateRuneSlotTexture(slot, { slotId = SLOT_ID })

      assert.is_nil(slot.runeSlot.icon.texture)
    end)

    it("leaves a slot that cannot be engraved untouched", function()
      local slot = FakeSlot("unchanged")

      engravable = false
      engraveFrame.UpdateRuneSlotTexture(slot, { slotId = SLOT_ID })

      assert.are.equal("unchanged", slot.runeSlot.icon.texture)
    end)

    it("updates every gearSlot of a gearBar in Season of Discovery only", function()
      local slot = FakeSlot(nil)

      rggm.gearBarStorage = {
        GetGearBar = function() return { gearSlotReferences = { slot } } end
      }

      sodActive = false
      engraveFrame.UpdateGearBarRuneSlotTextures({ id = 1, slots = { { slotId = SLOT_ID } } })
      assert.is_nil(slot.runeSlot.icon.texture)

      sodActive = true
      engraveFrame.UpdateGearBarRuneSlotTextures({ id = 1, slots = { { slotId = SLOT_ID } } })
      assert.are.equal(RUNE.iconTexture, slot.runeSlot.icon.texture)
    end)
  end)

  describe("changeSlot rune", function()
    it("shows the rune of the offered item", function()
      local slot = FakeSlot(nil)

      engraveFrame.UpdateChangeMenuRuneSlotTexture(slot, { rune = RUNE })

      assert.are.equal(RUNE.iconTexture, slot.runeSlot.icon.texture)
    end)

    it("clears the icon of an item without a rune or while the option is off", function()
      local slot = FakeSlot(RUNE.iconTexture)

      engraveFrame.UpdateChangeMenuRuneSlotTexture(slot, {})
      assert.is_nil(slot.runeSlot.icon.texture)

      slot.runeSlot.icon.texture = RUNE.iconTexture
      runeSlotsEnabled = false
      engraveFrame.UpdateChangeMenuRuneSlotTexture(slot, { rune = RUNE })
      assert.is_nil(slot.runeSlot.icon.texture)
    end)
  end)

  describe("outside Season of Discovery", function()
    before_each(function()
      sodActive = false
    end)

    it("creates no rune slot", function()
      assert.is_nil(engraveFrame.CreateRuneSlot({}, 40))
      assert.are.equal(0, createdFrames)
    end)

    it("leaves the changeSlot icon untouched - a slot built outside SoD has no rune slot", function()
      assert.has_no.errors(function()
        engraveFrame.UpdateChangeMenuRuneSlotTexture({}, { rune = RUNE })
        engraveFrame.ClearChangeMenuRuneSlotTexture({})
      end)
    end)
  end)
end)
