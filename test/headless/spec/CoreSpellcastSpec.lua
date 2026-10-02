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
  Spec for the spellcast event handlers in code/Core.lua: UNIT_SPELLCAST_SUCCEEDED forwards the
  cast to QuickChange and processes the combat queue, UNIT_SPELLCAST_INTERRUPTED /
  UNIT_SPELLCAST_CHANNEL_STOP process the queue once a cast or channel ends.

  The handlers are file-local, so the spec loads Core.lua with a recording event bus, runs
  me.OnLoad to capture what it registers and fires the captured handlers directly. QuickChange,
  the combat queue and the comm module are recorder / no-op stubs; UnitChannelInfo is stubbed
  per test.
]]--

local wowStubs = require("WowStubs")

local SPELL_ID = 12345

describe("Core spellcast events", function()
  local handlers
  local calls
  local channelling
  local restore

  --[[
    Fire an event the way the event bus would dispatch it to the handler Core registered

    @param {string} eventName
    @param {vararg} ...
  ]]--
  local function fire(eventName, ...)
    return handlers[eventName](...)
  end

  before_each(function()
    handlers = {}
    calls = { quickChange = {}, queueProcessed = 0 }
    channelling = false

    rggm.event = {
      Register = function(events, handler)
        if type(events) == "string" then events = { events } end

        for _, eventName in ipairs(events) do
          handlers[eventName] = handler
        end
      end,
      Setup = function() end
    }
    rggm.quickChange = {
      OnUnitSpellCastSucceeded = function(unit, castGuid, spellId)
        calls.quickChange[#calls.quickChange + 1] = { unit = unit, castGuid = castGuid, spellId = spellId }
      end
    }
    rggm.combatQueue = {
      ProcessQueue = function() calls.queueProcessed = calls.queueProcessed + 1 end
    }
    rggm.comm = {
      OnChatMsgAddon = function() end,
      BroadcastVersion = function() end
    }

    restore = wowStubs.install({
      UnitChannelInfo = function()
        if channelling then return "Channelled Spell" end

        return nil
      end
    })

    dofile("code/Core.lua")
    rggm.OnLoad({})
  end)

  after_each(function()
    restore()
  end)

  describe("UNIT_SPELLCAST_SUCCEEDED", function()
    it("forwards a player cast to QuickChange and processes the combat queue", function()
      fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", SPELL_ID)

      assert.are.same({ { unit = "player", castGuid = "Cast-1", spellId = SPELL_ID } }, calls.quickChange)
      assert.are.equal(1, calls.queueProcessed)
    end)

    it("forwards a cast to QuickChange while a channel is active but leaves the queue for the channel end", function()
      channelling = true

      fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", SPELL_ID)

      assert.are.same({ { unit = "player", castGuid = "Cast-1", spellId = SPELL_ID } }, calls.quickChange)
      assert.are.equal(0, calls.queueProcessed)
    end)

    it("ignores casts of other units", function()
      fire("UNIT_SPELLCAST_SUCCEEDED", "target", "Cast-1", SPELL_ID)

      assert.are.same({}, calls.quickChange)
      assert.are.equal(0, calls.queueProcessed)
    end)
  end)

  describe("UNIT_SPELLCAST_INTERRUPTED / UNIT_SPELLCAST_CHANNEL_STOP", function()
    it("processes the combat queue once the channel stops", function()
      channelling = true
      fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", SPELL_ID)
      channelling = false

      fire("UNIT_SPELLCAST_CHANNEL_STOP", "player")

      assert.are.equal(1, calls.queueProcessed)
      assert.are.equal(1, #calls.quickChange)
    end)

    it("processes the combat queue when a cast is interrupted", function()
      fire("UNIT_SPELLCAST_INTERRUPTED", "player")

      assert.are.equal(1, calls.queueProcessed)
    end)
  end)
end)
