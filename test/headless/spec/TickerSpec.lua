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
  Spec for the combatQueue ticker in code/Ticker.lua (me.StartTickerCombatQueue,
  me.StopTickerCombatQueue). The ticker drives mod.combatQueue.ProcessQueue, which cannot change
  gear during combat, so starting it mid-combat - from an enqueue, a resurrection or a loss of
  control ending - is refused; PLAYER_REGEN_ENABLED starts it once combat is over.

  C_Timer.NewTicker is stubbed with fake tickers that record their interval and callback and can
  be cancelled; InCombatLockdown is switched per test.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("Ticker combatQueue", function()
  local ticker
  local tickers
  local inCombat
  local restore

  before_each(function()
    tickers = {}
    inCombat = false

    rggm.logger = {
      LogDebug = function() end,
      LogInfo = function() end
    }
    rggm.combatQueue = { ProcessQueue = function() end }

    restore = wowStubs.install({
      InCombatLockdown = function() return inCombat end,
      C_Timer = {
        NewTicker = function(interval, callback)
          local fakeTicker = { interval = interval, callback = callback, cancelled = false }

          function fakeTicker.Cancel(self) self.cancelled = true end
          function fakeTicker.IsCancelled(self) return self.cancelled end

          tickers[#tickers + 1] = fakeTicker

          return fakeTicker
        end
      }
    })

    -- fresh file-local ticker state
    dofile("code/Ticker.lua")
    ticker = rggm.ticker
  end)

  after_each(function()
    restore()
  end)

  it("starts a ticker driving ProcessQueue out of combat", function()
    ticker.StartTickerCombatQueue()

    assert.are.equal(1, #tickers)
    assert.are.equal(RGGM_CONSTANTS.COMBAT_QUEUE_UPDATE_INTERVAL, tickers[1].interval)
    assert.are.equal(rggm.combatQueue.ProcessQueue, tickers[1].callback)
  end)

  it("does not start a second ticker while one is running", function()
    ticker.StartTickerCombatQueue()
    ticker.StartTickerCombatQueue()

    assert.are.equal(1, #tickers)
  end)

  it("refuses to start during combat lockdown", function()
    inCombat = true

    ticker.StartTickerCombatQueue()

    assert.are.equal(0, #tickers)
  end)

  it("stays stopped when a mid-combat caller tries to restart it after combat began", function()
    ticker.StartTickerCombatQueue()
    -- PLAYER_REGEN_DISABLED
    inCombat = true
    ticker.StopTickerCombatQueue()

    -- a resurrection or a loss of control ending mid-fight
    ticker.StartTickerCombatQueue()

    assert.are.equal(1, #tickers)
    assert.is_true(tickers[1].cancelled)
  end)

  it("starts again once combat is over", function()
    inCombat = true
    ticker.StartTickerCombatQueue()

    -- PLAYER_REGEN_ENABLED
    inCombat = false
    ticker.StartTickerCombatQueue()

    assert.are.equal(1, #tickers)
    assert.is_false(tickers[1].cancelled)
  end)
end)
