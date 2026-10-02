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
  Spec for the wiring between code/Core.lua and the real event bus in code/Event.lua: which
  events me.OnLoad subscribes the main frame to, and the readiness gate PLAYER_ENTERING_WORLD
  opens once Initialize ran - also when an initialization step raises (a gate left closed would
  switch off every gated handler for the whole session). UPDATE_BINDINGS is the one event besides
  PLAYER_ENTERING_WORLD that is not gated: it only schedules the delayed key binding refresh.

  CoreInitializeSpec covers the order of the steps inside Initialize against a recording bus;
  this spec drives Core only through me.OnEvent so the real bus decides what runs. Every module
  Initialize and the handlers reach is a recorder that accepts any call and logs it.
]]--

local wowStubs = require("WowStubs")

-- events subscribed with RegisterEvent
local FRAME_EVENTS = {
  "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT", "BAG_UPDATE", "ITEM_LOCK_CHANGED",
  "PLAYER_EQUIPMENT_CHANGED", "BAG_UPDATE_COOLDOWN", "UPDATE_BINDINGS", "LOSS_OF_CONTROL_ADDED",
  "LOSS_OF_CONTROL_UPDATE", "PLAYER_REGEN_ENABLED", "PLAYER_UNGHOST", "PLAYER_ALIVE",
  "PLAYER_REGEN_DISABLED", "PLAYER_TARGET_CHANGED", "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE"
}

-- the events the bus delivers before initialization ran
local UNGATED_EVENTS = { PLAYER_ENTERING_WORLD = true, UPDATE_BINDINGS = true }

-- events subscribed with RegisterUnitEvent for the player only
local PLAYER_UNIT_EVENTS = {
  "UNIT_INVENTORY_CHANGED", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_INTERRUPTED",
  "UNIT_SPELLCAST_CHANNEL_STOP"
}

describe("Core event wiring", function()
  local callLog
  -- errors the client error handler received
  local reportedErrors
  local registeredEvents
  local registeredUnitEvents
  -- callbacks C_Timer.After was asked to run, with their delay
  local timers
  local restore

  --[[
    A module stub that accepts any function call and appends "<name>.<function>" to callLog

    @param {string} name

    @return {table}
  ]]--
  local function recorder(name)
    return setmetatable({}, {
      __index = function(module, functionName)
        local stub = function()
          callLog[#callLog + 1] = name .. "." .. functionName
        end

        rawset(module, functionName, stub)

        return stub
      end
    })
  end

  local function count(entry)
    local found = 0

    for _, logged in ipairs(callLog) do
      if logged == entry then found = found + 1 end
    end

    return found
  end

  local function sorted(list)
    local copy = {}

    for index, value in ipairs(list) do copy[index] = value end

    table.sort(copy)

    return copy
  end

  local function keys(map)
    local list = {}

    for key in pairs(map) do list[#list + 1] = key end

    return sorted(list)
  end

  local function login()
    rggm.OnEvent("PLAYER_ENTERING_WORLD", true, false)
  end

  before_each(function()
    callLog = {}
    reportedErrors = {}
    registeredEvents = {}
    registeredUnitEvents = {}
    timers = {}

    for _, name in ipairs({
      "engrave", "cmd", "configuration", "profile", "addonConfiguration", "themeCoordinator", "gearBar",
      "gearBarChangeMenu", "trinketMenu", "keyBind", "comm", "target", "ticker", "combatQueue",
      "quickChange", "itemLocationCache", "itemManager", "common"
    }) do
      rggm[name] = recorder(name)
    end

    -- the bus logs every dispatch; keep that out of callLog
    rggm.logger = setmetatable({}, { __index = function() return function() end end })
    rggm.L = { help = " %s" }

    restore = wowStubs.install({
      C_AddOns = wowStubs.stubs.C_AddOns({ Version = "v0.0.0-test" }),
      UnitChannelInfo = function() return nil end,
      C_Timer = {
        After = function(delay, callback) timers[#timers + 1] = { delay = delay, callback = callback } end
      },
      print = function() end,
      geterrorhandler = function()
        return function(err) reportedErrors[#reportedErrors + 1] = err end
      end
    })

    -- fresh bus: no handlers, gate closed
    dofile("code/Event.lua")
    dofile("code/Core.lua")

    rggm.OnLoad({
      RegisterEvent = function(_, eventName)
        registeredEvents[eventName] = true
      end,
      RegisterUnitEvent = function(_, eventName, unit)
        registeredUnitEvents[eventName] = unit
      end
    })
  end)

  after_each(function()
    restore()
  end)

  it("subscribes the main frame to every event Core handles", function()
    assert.are.same(sorted(FRAME_EVENTS), keys(registeredEvents))
  end)

  it("subscribes the UNIT_* events for the player only", function()
    assert.are.same(sorted(PLAYER_UNIT_EVENTS), keys(registeredUnitEvents))

    for _, eventName in ipairs(PLAYER_UNIT_EVENTS) do
      assert.are.equal(RGGM_CONSTANTS.UNIT_ID_PLAYER, registeredUnitEvents[eventName])
    end
  end)

  it("holds back every event but PLAYER_ENTERING_WORLD until initialization ran", function()
    for _, eventName in ipairs(FRAME_EVENTS) do
      if not UNGATED_EVENTS[eventName] then
        rggm.OnEvent(eventName)
      end
    end

    for _, eventName in ipairs(PLAYER_UNIT_EVENTS) do
      rggm.OnEvent(eventName, RGGM_CONSTANTS.UNIT_ID_PLAYER)
    end

    assert.are.same({}, callLog)
  end)

  it("schedules the delayed key binding refresh on UPDATE_BINDINGS even before initialization", function()
    rggm.OnEvent("UPDATE_BINDINGS")

    assert.are.equal(1, #timers)
    assert.are.equal(RGGM_CONSTANTS.KEYBIND_UPDATE_DELAY, timers[1].delay)

    timers[1].callback()

    assert.are.same({ "keyBind.OnUpdateKeyBindings" }, callLog)
  end)

  it("does not open the gate when only zoning between map instances", function()
    rggm.OnEvent("PLAYER_ENTERING_WORLD", false, false)
    rggm.OnEvent("PLAYER_REGEN_DISABLED")

    assert.are.equal(0, count("ticker.StopTickerCombatQueue"))
  end)

  it("opens the gate after initialization on login", function()
    login()
    rggm.OnEvent("PLAYER_REGEN_DISABLED")

    assert.are.equal(1, count("ticker.StopTickerCombatQueue"))
    assert.are.same({}, reportedErrors)
  end)

  it("opens the gate on a /reload", function()
    rggm.OnEvent("PLAYER_ENTERING_WORLD", false, true)
    rggm.OnEvent("PLAYER_REGEN_DISABLED")

    assert.are.equal(1, count("ticker.StopTickerCombatQueue"))
  end)

  it("keeps the gate closed while Initialize is still running", function()
    rggm.gearBar.BuildGearBars = function()
      rggm.OnEvent("PLAYER_REGEN_DISABLED")
    end

    login()

    assert.are.equal(0, count("ticker.StopTickerCombatQueue"))
  end)

  it("still opens the gate and reports the error when an initialization step raises", function()
    rggm.configuration.SetupConfiguration = function() error("configuration setup failed") end

    assert.has_no.errors(login)

    rggm.OnEvent("PLAYER_REGEN_DISABLED")

    assert.are.equal(1, count("ticker.StopTickerCombatQueue"))
    assert.are.equal(1, #reportedErrors)
    assert.is_truthy(tostring(reportedErrors[1]):find("configuration setup failed", 1, true))
  end)

  it("delivers the event arguments to the handler once the gate is open", function()
    login()
    callLog = {}

    rggm.OnEvent("UNIT_SPELLCAST_INTERRUPTED", RGGM_CONSTANTS.UNIT_ID_PLAYER)
    rggm.OnEvent("UNIT_SPELLCAST_INTERRUPTED", "target")

    assert.are.same({ "combatQueue.ProcessQueue" }, callLog)
  end)
end)
