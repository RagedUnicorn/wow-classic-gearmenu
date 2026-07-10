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
  Tests for the central event bus (code/Event.lua).
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

describe("Event bus", function()
  local registered
  local registeredUnits
  local stubFrame
  -- snapshot of the real rggm.logger from Bootstrap, restored in after_each so the
  -- shared namespace does not leak a stub into other specs
  local previousLogger

  before_each(function()
    -- Re-dofile the bus so each test starts with fresh handler/ready state.
    dofile("code/Event.lua")

    previousLogger = rggm.logger
    rggm.logger = {
      LogDebug = function() end,
      LogEvent = function() end
    }

    registered = {}
    registeredUnits = {}
    stubFrame = {
      RegisterEvent = function(_, eventName)
        registered[eventName] = true
      end,
      RegisterUnitEvent = function(_, eventName, unit)
        registered[eventName] = true
        registeredUnits[eventName] = unit
      end
    }
  end)

  after_each(function()
    rggm.logger = previousLogger
  end)

  it("Setup registers every declared event on the frame", function()
    rggm.event.Register("PLAYER_ENTERING_WORLD", function() end)
    rggm.event.Register("PLAYER_TARGET_CHANGED", function() end)

    rggm.event.Setup(stubFrame)

    assert.is_true(registered["PLAYER_ENTERING_WORLD"])
    assert.is_true(registered["PLAYER_TARGET_CHANGED"])
  end)

  it("Setup subscribes unit-scoped events via RegisterUnitEvent", function()
    rggm.event.Register("UNIT_INVENTORY_CHANGED", function() end, { unit = "player" })
    rggm.event.Register("BAG_UPDATE", function() end)

    rggm.event.Setup(stubFrame)

    assert.equal("player", registeredUnits["UNIT_INVENTORY_CHANGED"])
    assert.is_nil(registeredUnits["BAG_UPDATE"])
    assert.is_true(registered["BAG_UPDATE"])
  end)

  it("Dispatch invokes the matching handler with the event varargs", function()
    local received

    rggm.event.Register("CUSTOM_EVENT", function(a, b)
      received = { a, b }
    end)

    rggm.event.Dispatch("CUSTOM_EVENT", "unit", 42)

    assert.same({ "unit", 42 }, received)
  end)

  it("Register accepts an array of events sharing one handler", function()
    local calls = 0

    rggm.event.Register({ "EVENT_A", "EVENT_B", "EVENT_C" }, function()
      calls = calls + 1
    end)

    rggm.event.Setup(stubFrame)

    assert.is_true(registered["EVENT_A"])
    assert.is_true(registered["EVENT_B"])
    assert.is_true(registered["EVENT_C"])

    rggm.event.Dispatch("EVENT_A")
    rggm.event.Dispatch("EVENT_C")

    assert.equal(2, calls)
  end)

  it("Register applies the unit option to every event of an array", function()
    rggm.event.Register(
      { "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_STOP" },
      function() end,
      { unit = "player" }
    )

    rggm.event.Setup(stubFrame)

    assert.equal("player", registeredUnits["UNIT_SPELLCAST_INTERRUPTED"])
    assert.equal("player", registeredUnits["UNIT_SPELLCAST_CHANNEL_STOP"])
  end)

  it("Dispatch ignores an unregistered event", function()
    assert.has_no.errors(function()
      rggm.event.Dispatch("UNREGISTERED_EVENT")
    end)
  end)

  it("ungated handlers fire before SetReady", function()
    local calls = 0

    rggm.event.Register("UNGATED", function() calls = calls + 1 end)

    rggm.event.Dispatch("UNGATED")

    assert.equal(1, calls)
  end)

  it("gated handlers are suppressed until SetReady, then fire", function()
    local calls = 0

    rggm.event.Register("GATED", function() calls = calls + 1 end, { gated = true })

    rggm.event.Dispatch("GATED")
    assert.equal(0, calls)

    rggm.event.SetReady()

    rggm.event.Dispatch("GATED")
    assert.equal(1, calls)
  end)
end)
