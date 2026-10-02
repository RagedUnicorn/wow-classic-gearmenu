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
  Spec for the Season of Discovery check in code/Season.lua (me.IsSodActive). Rune slots, the
  engraving api and the rune slot option all hang off this answer. C_Seasons and Enum.SeasonID are
  stubbed per test; clients that predate the SeasonOfDiscovery enum name call it Placeholder.
]]--

local wowStubs = require("WowStubs")

local SEASON_OF_DISCOVERY = 2
local HARDCORE = 3

describe("Season", function()
  local season
  local hasActiveSeason
  local activeSeason
  local seasonIds
  local restore

  before_each(function()
    hasActiveSeason = true
    activeSeason = SEASON_OF_DISCOVERY
    seasonIds = { SeasonOfDiscovery = SEASON_OF_DISCOVERY, Hardcore = HARDCORE }

    restore = wowStubs.install({
      C_Seasons = {
        HasActiveSeason = function() return hasActiveSeason end,
        GetActiveSeason = function() return activeSeason end
      },
      Enum = { SeasonID = seasonIds }
    })

    dofile("code/Season.lua")
    season = rggm.season
  end)

  after_each(function()
    restore()
  end)

  it("is active on a Season of Discovery realm", function()
    assert.is_true(season.IsSodActive())
  end)

  it("is not active on another seasonal realm", function()
    activeSeason = HARDCORE

    assert.is_false(season.IsSodActive())
  end)

  it("is not active without a season", function()
    hasActiveSeason = false

    assert.is_false(season.IsSodActive())
  end)

  it("falls back to the Placeholder season id on clients without the SeasonOfDiscovery name", function()
    seasonIds.SeasonOfDiscovery = nil
    seasonIds.Placeholder = SEASON_OF_DISCOVERY

    assert.is_true(season.IsSodActive())
  end)
end)
