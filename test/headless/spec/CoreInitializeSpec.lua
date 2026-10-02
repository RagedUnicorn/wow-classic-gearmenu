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
  Spec for the initialization in code/Core.lua that PLAYER_ENTERING_WORLD runs on login and
  /reload. It covers the state Initialize has to seed itself because the gated events that
  normally maintain it are not dispatched yet - today the current target of code/Target.lua.

  Core.lua is loaded with a recording event bus; me.OnLoad registers the handlers and the spec
  fires PLAYER_ENTERING_WORLD directly. code/Target.lua is loaded for real against stubbed
  UnitGUID; every other module Initialize reaches is a recorder that accepts any call
  and logs it, so the spec can also assert where in the sequence the target is seeded.
]]--

local wowStubs = require("WowStubs")

local TARGET_GUID = "Player-1234-00ABCDEF"

describe("Core initialize", function()
  local handlers
  local callLog
  -- errors the client error handler received
  local reportedErrors
  local targetGuid
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

  local function indexOf(entry)
    for index, logged in ipairs(callLog) do
      if logged == entry then return index end
    end

    return nil
  end

  before_each(function()
    handlers = {}
    callLog = {}
    reportedErrors = {}
    targetGuid = TARGET_GUID

    for _, name in ipairs({
      "logger", "engrave", "cmd", "configuration", "profile", "addonConfiguration", "themeCoordinator", "gearBar",
      "gearBarChangeMenu", "trinketMenu", "keyBind", "comm"
    }) do
      rggm[name] = recorder(name)
    end

    rggm.event = {
      Register = function(events, handler)
        if type(events) == "string" then events = { events } end

        for _, eventName in ipairs(events) do
          handlers[eventName] = handler
        end
      end,
      Setup = function() end,
      SetReady = function() callLog[#callLog + 1] = "event.SetReady" end
    }
    rggm.L = { help = " %s" }

    restore = wowStubs.install({
      UnitGUID = function() return targetGuid end,
      C_AddOns = wowStubs.stubs.C_AddOns({ Version = "v0.0.0-test" }),
      print = function() end,
      geterrorhandler = function()
        return function(err) reportedErrors[#reportedErrors + 1] = err end
      end
    })

    dofile("code/Target.lua")
    -- log the seed on top of running the real module
    local updateCurrentTarget = rggm.target.UpdateCurrentTarget
    rggm.target.UpdateCurrentTarget = function()
      callLog[#callLog + 1] = "target.UpdateCurrentTarget"
      updateCurrentTarget()
    end

    dofile("code/Core.lua")
    rggm.OnLoad({})
  end)

  after_each(function()
    restore()
  end)

  it("seeds a target selected before the login or /reload", function()
    handlers["PLAYER_ENTERING_WORLD"](false, true)

    assert.are.equal(TARGET_GUID, rggm.target.GetCurrentTargetGuid())
  end)

  it("keeps the target empty when nothing is targeted", function()
    targetGuid = nil

    handlers["PLAYER_ENTERING_WORLD"](true, false)

    assert.are.equal("", rggm.target.GetCurrentTargetGuid())
  end)

  it("seeds the target after the gearBars are built and before their first visual update", function()
    handlers["PLAYER_ENTERING_WORLD"](false, true)

    local seeded = indexOf("target.UpdateCurrentTarget")

    assert.is_truthy(seeded)
    assert.is_true(indexOf("gearBar.BuildGearBars") < seeded)
    assert.is_true(seeded < indexOf("gearBar.UpdateGearBars"))
  end)

  it("refreshes the gearBar visuals once, after the TrinketMenu is built", function()
    handlers["PLAYER_ENTERING_WORLD"](false, true)

    local refreshes = 0

    for _, logged in ipairs(callLog) do
      if logged == "gearBar.UpdateGearBars" then refreshes = refreshes + 1 end
    end

    assert.are.equal(1, refreshes)
    assert.is_true(indexOf("configuration.IsTrinketMenuEnabled") < indexOf("gearBar.UpdateGearBars"))
  end)

  it("opens the event gate once initialization completed", function()
    handlers["PLAYER_ENTERING_WORLD"](true, false)

    assert.is_true(indexOf("gearBar.BuildGearBars") < indexOf("event.SetReady"))
    assert.are.same({}, reportedErrors)
  end)

  it("still opens the event gate and reports the error when an initialization step raises", function()
    rggm.gearBar.BuildGearBars = function() error("gearBar build failed") end

    assert.has_no.errors(function() handlers["PLAYER_ENTERING_WORLD"](false, true) end)

    assert.is_truthy(indexOf("event.SetReady"))
    assert.is_truthy(indexOf("comm.BroadcastVersion"))
    assert.are.equal(1, #reportedErrors)
    assert.is_truthy(tostring(reportedErrors[1]):find("gearBar build failed", 1, true))
  end)

  it("does not re-initialize when only zoning between map instances", function()
    handlers["PLAYER_ENTERING_WORLD"](false, false)

    assert.is_nil(indexOf("target.UpdateCurrentTarget"))
    assert.are.equal("", rggm.target.GetCurrentTargetGuid())
  end)

  it("broadcasts the version to guild and group once on login or /reload", function()
    handlers["PLAYER_ENTERING_WORLD"](true, false)

    assert.is_truthy(indexOf("comm.BroadcastVersion"))
    assert.is_nil(indexOf("comm.BroadcastGroupVersion"))
  end)

  it("tells only the group when zoning between map instances", function()
    handlers["PLAYER_ENTERING_WORLD"](false, false)

    assert.is_nil(indexOf("comm.BroadcastVersion"))
    assert.is_truthy(indexOf("comm.BroadcastGroupVersion"))
  end)

  it("tells only the group on a roster change", function()
    handlers["GROUP_ROSTER_UPDATE"]()

    assert.are.same({ "comm.BroadcastGroupVersion" }, callLog)
  end)
end)
