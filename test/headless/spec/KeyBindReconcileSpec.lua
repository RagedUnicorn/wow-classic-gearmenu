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
  Spec for the profile-apply keyBinding reconciliation added to gui/KeyBind.lua
  (me.ApplyGearBarKeyBindings / me.ClearGearBarKeyBindings). Both build the slot
  frame name from configuration data (gearBar.id + slot position) rather than from
  ui frames, so they can be exercised headless with the WoW binding API stubbed.

  gui/KeyBind.lua registers two StaticPopupDialogs at load time whose text is read
  from rggm.L, so before the module is dofile'd we install a StaticPopupDialogs
  table and a permissive rggm.L stub (every key resolves to ""). The collaborators
  the reconcile functions reach (mod.gearBarManager, mod.logger) are replaced with
  recorder / no-op stubs and the WoW binding globals come from a local install.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: globals StaticPopupDialogs
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("KeyBind reconcile", function()
  local keyBind
  local previous
  local restore
  local calls

  before_each(function()
    calls = {
      bound = {},   -- SetBinding(key, action) - two-arg bind
      unbound = {}, -- SetBinding(key)         - one-arg clear
      bindingsSaved = 0,
      bindingActions = {} -- key -> action returned by GetBindingAction (per test)
    }

    -- snapshot everything the load / functions touch so nothing leaks across specs
    previous = {
      keyBind = rggm.keyBind,
      gearBarManager = rggm.gearBarManager,
      logger = rggm.logger,
      L = rggm.L,
      StaticPopupDialogs = _G.StaticPopupDialogs
    }

    -- KeyBind.lua reads rggm.L at load time to build its popup dialogs
    rggm.L = setmetatable({}, { __index = function() return "" end })
    _G.StaticPopupDialogs = {}

    rggm.logger = {
      LogDebug = function() end,
      LogInfo = function() end,
      LogWarn = function() end,
      LogError = function() end,
      PrintUserError = function() end
    }

    restore = wowStubs.install({
      SetBinding = function(key, action)
        if action ~= nil then
          calls.bound[#calls.bound + 1] = { key = key, action = action }
        else
          calls.unbound[#calls.unbound + 1] = key
        end

        return true
      end,
      GetBindingAction = function(key)
        return calls.bindingActions[key] or ""
      end,
      GetCurrentBindingSet = function() return 1 end,
      SaveBindings = function() calls.bindingsSaved = calls.bindingsSaved + 1 end
    })

    dofile("gui/KeyBind.lua")
    keyBind = rggm.keyBind
  end)

  after_each(function()
    restore()

    rggm.keyBind = previous.keyBind
    rggm.gearBarManager = previous.gearBarManager
    rggm.logger = previous.logger
    rggm.L = previous.L
    _G.StaticPopupDialogs = previous.StaticPopupDialogs
  end)

  describe("ApplyGearBarKeyBindings", function()
    it("binds every slot keyBinding to its CLICK action and saves once", function()
      rggm.gearBarManager = {
        GetGearBars = function()
          return {
            { id = 3, slots = { [1] = { keyBinding = "T" }, [2] = { keyBinding = nil } } },
            { id = 7, slots = { [1] = { keyBinding = "CTRL-Q" } } }
          }
        end
      }

      keyBind.ApplyGearBarKeyBindings()

      assert.are.equal(2, #calls.bound)
      -- order of pairs() over slots is unspecified; assert membership
      local byKey = {}
      for _, entry in ipairs(calls.bound) do byKey[entry.key] = entry.action end

      assert.are.equal("CLICK GM_GearBarFrame_3Slot_1:LeftButton", byKey["T"])
      assert.are.equal("CLICK GM_GearBarFrame_7Slot_1:LeftButton", byKey["CTRL-Q"])
      assert.are.equal(1, calls.bindingsSaved)
    end)

    it("skips slots without a keyBinding and does not save when nothing was bound", function()
      rggm.gearBarManager = {
        GetGearBars = function()
          return { { id = 1, slots = { [1] = { keyBinding = nil }, [2] = { keyBinding = "" } } } }
        end
      }

      keyBind.ApplyGearBarKeyBindings()

      assert.are.equal(0, #calls.bound)
      assert.are.equal(0, calls.bindingsSaved)
    end)
  end)

  describe("ClearGearBarKeyBindings", function()
    it("unbinds only bindings whose action matches GearMenus own pattern", function()
      -- "T" is one of ours, "P" belongs to some other action and must be left alone
      calls.bindingActions["T"] = "CLICK GM_GearBarFrame_1Slot_1:LeftButton"
      calls.bindingActions["P"] = "TOGGLEWORLDMAP"

      local gearBars = {
        { id = 1, slots = { [1] = { keyBinding = "T" }, [2] = { keyBinding = "P" } } }
      }

      keyBind.ClearGearBarKeyBindings(gearBars)

      assert.are.equal(1, #calls.unbound)
      assert.are.equal("T", calls.unbound[1])
    end)

    it("ignores a nil argument", function()
      assert.has_no.errors(function() keyBind.ClearGearBarKeyBindings(nil) end)
      assert.are.equal(0, #calls.unbound)
    end)
  end)
end)
