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
  Spec for the equipment event handlers in code/Core.lua. One equip fires both
  PLAYER_EQUIPMENT_CHANGED and UNIT_INVENTORY_CHANGED (the latter kept as the login fallback);
  both request the same full gearBar visual refresh, which runs once on the next frame.

  Core.lua is loaded with a recording event bus, me.OnLoad registers the handlers and the spec
  fires them directly. C_Timer.After is queued and flushed by the spec, and the gearBar module
  records every UpdateGearBars call.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("Core equipment events", function()
  local handlers
  local refreshes
  local pendingTimers
  local restore

  local function flushTimers()
    local timers = pendingTimers

    pendingTimers = {}

    for _, timer in ipairs(timers) do
      timer.callback()
    end
  end

  before_each(function()
    handlers = {}
    refreshes = {}
    pendingTimers = {}

    rggm.event = {
      Register = function(events, handler)
        if type(events) == "string" then events = { events } end

        for _, eventName in ipairs(events) do
          handlers[eventName] = handler
        end
      end,
      Setup = function() end
    }
    rggm.gearBar = {
      UpdateGearBarVisual = function() end,
      UpdateGearBars = function(callback) refreshes[#refreshes + 1] = callback end
    }
    rggm.comm = {
      OnChatMsgAddon = function() end,
      BroadcastGroupVersion = function() end
    }

    restore = wowStubs.install({
      C_Timer = {
        After = function(delay, callback)
          pendingTimers[#pendingTimers + 1] = { delay = delay, callback = callback }
        end
      }
    })

    dofile("code/Core.lua")
    rggm.OnLoad({})
  end)

  after_each(function()
    restore()
  end)

  it("refreshes the gearBar visuals once for an equip firing both events", function()
    handlers["PLAYER_EQUIPMENT_CHANGED"]()
    handlers["UNIT_INVENTORY_CHANGED"]("player")

    assert.are.equal(0, #refreshes)
    assert.are.equal(1, #pendingTimers)
    assert.are.equal(0, pendingTimers[1].delay)

    flushTimers()

    assert.are.same({ rggm.gearBar.UpdateGearBarVisual }, refreshes)
  end)

  it("refreshes on UNIT_INVENTORY_CHANGED alone as the login fallback", function()
    handlers["UNIT_INVENTORY_CHANGED"]("player")
    flushTimers()

    assert.are.equal(1, #refreshes)
  end)

  it("ignores inventory changes of other units", function()
    handlers["UNIT_INVENTORY_CHANGED"]("target")

    assert.are.equal(0, #pendingTimers)
  end)

  it("schedules a new refresh for an equip after the previous refresh ran", function()
    handlers["PLAYER_EQUIPMENT_CHANGED"]()
    flushTimers()

    handlers["PLAYER_EQUIPMENT_CHANGED"]()
    flushTimers()

    assert.are.equal(2, #refreshes)
  end)
end)
