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
  Tests for the shared frame pool and grid position helpers (gui/UiHelper.lua).

  The grid parity blocks re-implement the legacy per-widget layout loops that
  CalculateGridPosition replaced (change menu block loop, trinket menu loop with
  its columnAmount == 1 special case, profile row list) and assert the helper
  produces identical offsets.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each
-- luacheck: ignore 143

-- UiHelper.lua has no load-time WoW api calls; it only needs the rggm namespace from Bootstrap
dofile("gui/UiHelper.lua")

--[[
  Build a stub frame that records whether it was hidden

  @param {number} index
  @return {table}
]]--
local function CreateStubFrame(index)
  local frame = { index = index, hidden = false }

  function frame.Hide()
    frame.hidden = true
  end

  return frame
end

describe("UiHelper frame pool", function()
  local uiHelper = rggm.uiHelper
  local createdIndexes
  local pool

  before_each(function()
    createdIndexes = {}
    pool = uiHelper.CreateFramePool(function(index)
      table.insert(createdIndexes, index)
      return CreateStubFrame(index)
    end)
  end)

  it("creates a frame on first acquire and passes the index to the factory", function()
    local frame = pool.Acquire(3)

    assert.are.equal(3, frame.index)
    assert.are.same({3}, createdIndexes)
  end)

  it("memoizes acquired frames instead of recreating them", function()
    local first = pool.Acquire(1)
    local second = pool.Acquire(1)

    assert.are.equal(first, second)
    assert.are.same({1}, createdIndexes)
  end)

  it("reports the amount of created frames", function()
    assert.are.equal(0, pool.GetSize())

    for index = 1, 4 do
      pool.Acquire(index)
    end

    assert.are.equal(4, pool.GetSize())
  end)

  it("iterates all created frames in index order", function()
    for index = 1, 3 do
      pool.Acquire(index)
    end

    local visited = {}

    pool.ForEach(function(frame, index)
      table.insert(visited, {frame.index, index})
    end)

    assert.are.same({{1, 1}, {2, 2}, {3, 3}}, visited)
  end)

  it("hides every created frame on ReleaseAll", function()
    for index = 1, 3 do
      pool.Acquire(index)
    end

    pool.ReleaseAll()

    pool.ForEach(function(frame)
      assert.is_true(frame.hidden)
    end)
  end)

  it("invokes the reset callback after hiding each frame", function()
    for index = 1, 2 do
      pool.Acquire(index)
    end

    local resetOrder = {}

    pool.ReleaseAll(function(frame)
      -- the frame must already be hidden when the reset callback runs
      table.insert(resetOrder, {frame.index, frame.hidden})
    end)

    assert.are.same({{1, true}, {2, true}}, resetOrder)
  end)

  it("only hides frames from the passed index onwards on ReleaseFrom", function()
    for index = 1, 4 do
      pool.Acquire(index)
    end

    pool.ReleaseFrom(3)

    assert.is_false(pool.Acquire(1).hidden)
    assert.is_false(pool.Acquire(2).hidden)
    assert.is_true(pool.Acquire(3).hidden)
    assert.is_true(pool.Acquire(4).hidden)
  end)

  it("is a no-op when ReleaseFrom starts beyond the created frames", function()
    for index = 1, 2 do
      pool.Acquire(index)
    end

    pool.ReleaseFrom(3)

    assert.is_false(pool.Acquire(1).hidden)
    assert.is_false(pool.Acquire(2).hidden)
  end)
end)

describe("UiHelper grid position", function()
  local uiHelper = rggm.uiHelper

  --[[
    Legacy change menu layout (gui/GearBarChangeMenu.lua UpdateChangeSlots before the refactor):
    iterate items in blocks of columnAmount, row derived from the block start index

    @param {number} itemCount
    @param {number} columnAmount
    @param {number} slotSize
    @return {table} positions indexed by item index, each {xPos, yPos}
  ]]--
  local function LegacyChangeMenuPositions(itemCount, columnAmount, slotSize)
    local positions = {}

    for index = 1, itemCount, columnAmount do
      local row = math.floor(index / columnAmount)

      for column = 1, columnAmount do
        local actualIndex = index + column - 1

        if actualIndex > itemCount then break end

        positions[actualIndex] = {(column - 1) * slotSize, row * slotSize}
      end
    end

    return positions
  end

  --[[
    Legacy trinket menu layout (gui/TrinketMenu.lua UpdateTrinketMenuSlotSize before the
    refactor) including its columnAmount == 1 row correction

    @param {number} slotAmount
    @param {number} columnAmount
    @param {number} slotSize
    @return {table} positions indexed by slot index, each {xPos, yPos}
  ]]--
  local function LegacyTrinketMenuPositions(slotAmount, columnAmount, slotSize)
    local positions = {}

    for index = 1, slotAmount, columnAmount do
      local row = math.floor(index / columnAmount)

      if columnAmount == 1 then
        row = row - 1
      end

      for column = 1, columnAmount do
        if index + column - 1 > slotAmount then break end

        positions[index + column - 1] = {(column - 1) * slotSize, row * slotSize}
      end
    end

    return positions
  end

  it("matches the legacy change menu block loop", function()
    local slotSize = 32

    for _, itemCount in ipairs({1, 2, 3, 4, 6, 7, 40}) do
      local legacy = LegacyChangeMenuPositions(itemCount, 3, slotSize)

      for index = 1, itemCount do
        local xPos, yPos = uiHelper.CalculateGridPosition(index, 3, slotSize)

        assert.are.same(legacy[index], {xPos, yPos})
      end
    end
  end)

  it("matches the legacy change menu empty slot placement", function()
    local slotSize = 40

    -- displayedItems exactly filling a row (3), mid-row (4) and the 40 item cap
    for _, displayedItems in ipairs({0, 3, 4, 40}) do
      local xPos, yPos = uiHelper.CalculateGridPosition(displayedItems + 1, 3, slotSize)
      local expectedRow = math.floor(displayedItems / 3)
      local expectedColumn = displayedItems % 3

      assert.are.equal(expectedColumn * slotSize, xPos)
      assert.are.equal(expectedRow * slotSize, yPos)
    end
  end)

  it("matches the legacy trinket menu loop across column amounts", function()
    local slotSize = 40

    for _, columnAmount in ipairs({1, 2, 3, 4, 5, 10}) do
      local legacy = LegacyTrinketMenuPositions(30, columnAmount, slotSize)

      for index = 1, 30 do
        local xPos, yPos = uiHelper.CalculateGridPosition(index, columnAmount, slotSize)

        assert.are.same(legacy[index], {xPos, yPos})
      end
    end
  end)

  it("matches the legacy profile row offsets as a single column grid", function()
    local rowHeight = 20

    for index = 1, 10 do
      local xPos, yPos = uiHelper.CalculateGridPosition(index, 1, rowHeight)

      assert.are.equal(0, xPos)
      -- legacy anchor was -(index - 1) * rowHeight; the consumer negates yPos
      assert.are.equal((index - 1) * rowHeight, yPos)
    end
  end)
end)
