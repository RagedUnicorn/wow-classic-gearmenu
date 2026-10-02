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
  Spec for the store of built gearBar ui elements in gui/GearBarStorage.lua: adding a gearBar,
  appending its gearSlots, looking it up by id and removing it again (frames cannot be destroyed,
  so removing hides the gearBar frame and drops the reference).

  The store is a file-local table, so the module is dofile'd per test for an empty store.
]]--

local GEAR_BAR_ID = 2

describe("GearBarStorage", function()
  local storage
  local previousLogger
  local previousStorage
  local warnings

  --[[
    A stand-in gearBar frame that records whether it was hidden

    @return {table}
  ]]--
  local function fakeGearBarFrame()
    local frame = { hidden = false }

    function frame:Hide()
      self.hidden = true
    end

    return frame
  end

  before_each(function()
    warnings = 0
    previousLogger = rggm.logger
    previousStorage = rggm.gearBarStorage

    rggm.logger = {
      LogDebug = function() end,
      LogWarn = function() warnings = warnings + 1 end
    }

    dofile("gui/GearBarStorage.lua")
    storage = rggm.gearBarStorage
  end)

  after_each(function()
    rggm.logger = previousLogger
    rggm.gearBarStorage = previousStorage
  end)

  it("starts empty", function()
    assert.are.same({}, storage.GetGearBars())
  end)

  it("stores a gearBar under its id with no gearSlots yet", function()
    local frame = fakeGearBarFrame()

    storage.AddGearBar(GEAR_BAR_ID, frame)

    local gearBar = storage.GetGearBar(GEAR_BAR_ID)

    assert.are.equal(frame, gearBar.gearBarReference)
    assert.are.same({}, gearBar.gearSlotReferences)
    assert.are.equal(gearBar, storage.GetGearBars()[GEAR_BAR_ID])
  end)

  it("appends gearSlots to their gearBar in the order they were added", function()
    local firstSlot, secondSlot = {}, {}

    storage.AddGearBar(GEAR_BAR_ID, fakeGearBarFrame())
    storage.AddGearSlot(GEAR_BAR_ID, firstSlot)
    storage.AddGearSlot(GEAR_BAR_ID, secondSlot)

    local slots = storage.GetGearBar(GEAR_BAR_ID).gearSlotReferences

    assert.are.equal(2, #slots)
    assert.are.equal(firstSlot, slots[1])
    assert.are.equal(secondSlot, slots[2])
  end)

  it("starts with a fresh gearSlot list when a gearBar id is added again", function()
    storage.AddGearBar(GEAR_BAR_ID, fakeGearBarFrame())
    storage.AddGearSlot(GEAR_BAR_ID, {})

    storage.AddGearBar(GEAR_BAR_ID, fakeGearBarFrame())

    assert.are.same({}, storage.GetGearBar(GEAR_BAR_ID).gearSlotReferences)
  end)

  it("returns nil and warns for an unknown gearBar", function()
    assert.is_nil(storage.GetGearBar(GEAR_BAR_ID))
    assert.are.equal(1, warnings)
  end)

  it("ignores a gearSlot for an unknown gearBar without creating it", function()
    storage.AddGearSlot(GEAR_BAR_ID, {})

    assert.are.equal(1, warnings)
    assert.are.same({}, storage.GetGearBars())
  end)

  it("hides the gearBar frame and forgets the gearBar on removal", function()
    local frame = fakeGearBarFrame()

    storage.AddGearBar(GEAR_BAR_ID, frame)
    storage.AddGearBar(GEAR_BAR_ID + 1, fakeGearBarFrame())
    storage.RemoveGearBar(GEAR_BAR_ID)

    assert.is_true(frame.hidden)
    assert.is_nil(storage.GetGearBars()[GEAR_BAR_ID])
    assert.is_table(storage.GetGearBars()[GEAR_BAR_ID + 1])
  end)
end)
