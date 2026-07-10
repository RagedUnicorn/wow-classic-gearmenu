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
  Spec for code/Cmd.lua - the slash sub-command registry. Covers:

    - SetupSlashCmdList: registers both slash aliases (/rggm, /gearmenu) and installs the
      dispatch handler into SlashCmdList["GEARMENU"].
    - Built-in dispatch: bare input / whitespace-only input / "help" print the info block,
      "rl" and "reload" both reload the UI, "opt" opens the settings main category, and any
      unknown argument prints the localized invalid-argument user error.
    - RegisterCommand: a single call adds a dispatchable sub-command that automatically shows
      up in the generated help output; handlers receive the remaining arguments (command name
      removed); aliases dispatch to the same handler without duplicating the help line;
      invalid registrations (missing name or handler) are rejected without raising.

  The collaborators (logger, addonConfiguration) are replaced with recorder stubs on the shared
  rggm namespace and restored in after_each so they do not leak into other specs (the pattern
  used by MacroSpec). SlashCmdList, ReloadUI and print are installed as WoW/Lua globals via the
  WowStubs registry for the duration of each test - stubbing print captures the info block that
  ShowInfoMessage emits. rggm.L is stubbed with just the keys the code under test prints.

  Cmd.lua registers its built-in commands (reload, opt) in module scope, so re-dofile'ing it in
  before_each yields a fresh registry per test.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: globals SLASH_GEARMENU1 SLASH_GEARMENU2 SlashCmdList
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

describe("Cmd", function()
  local cmd
  -- recorders populated by the stubbed collaborators and globals
  local printed
  local reloadCount
  local openMainCategoryCount
  local userErrors
  -- snapshot of the rggm.* collaborators we overwrite, restored in after_each so the shared
  -- namespace (notably the real rggm.logger from Bootstrap) does not leak into other specs
  local previousModules
  -- restore function for the installed globals
  local restoreGlobals

  local function dispatch(msg)
    SlashCmdList["GEARMENU"](msg)
  end

  before_each(function()
    printed = {}
    reloadCount = 0
    openMainCategoryCount = 0
    userErrors = {}

    previousModules = {
      logger = rggm.logger,
      addonConfiguration = rggm.addonConfiguration,
      L = rggm.L
    }

    rggm.logger = {
      LogDebug = function() end,
      LogError = function() end,
      PrintUserError = function(message)
        userErrors[#userErrors + 1] = message
      end
    }
    rggm.addonConfiguration = {
      OpenMainCategory = function()
        openMainCategoryCount = openMainCategoryCount + 1
      end
    }
    rggm.L = {
      info_title = "GearMenu:",
      reload = "reload - reload UI",
      opt = "opt - display Optionsmenu",
      invalid_argument = "Invalid argument passed",
      equipset_help = "equipset - equip a gear set"
    }

    restoreGlobals = wowStubs.install({
      SlashCmdList = {},
      ReloadUI = function()
        reloadCount = reloadCount + 1
      end,
      print = function(message)
        printed[#printed + 1] = message
      end
    })

    -- fresh module table and command registry per test (Bootstrap module-state reset convention)
    dofile("code/Cmd.lua")
    cmd = rggm.cmd
    cmd.SetupSlashCmdList()
  end)

  after_each(function()
    restoreGlobals()
    _G.SLASH_GEARMENU1 = nil
    _G.SLASH_GEARMENU2 = nil
    rggm.logger = previousModules.logger
    rggm.addonConfiguration = previousModules.addonConfiguration
    rggm.L = previousModules.L
  end)

  it("registers both slash aliases and the dispatch handler", function()
    assert.equal("/rggm", SLASH_GEARMENU1)
    assert.equal("/gearmenu", SLASH_GEARMENU2)
    assert.equal("function", type(SlashCmdList["GEARMENU"]))
  end)

  it("prints the info block for a bare command", function()
    dispatch("")

    assert.same({
      "GearMenu:",
      "reload - reload UI",
      "opt - display Optionsmenu"
    }, printed)
  end)

  it("prints the info block for whitespace-only input", function()
    dispatch("   ")

    assert.same({
      "GearMenu:",
      "reload - reload UI",
      "opt - display Optionsmenu"
    }, printed)
  end)

  it("prints the info block for the help command", function()
    dispatch("help")

    assert.same({
      "GearMenu:",
      "reload - reload UI",
      "opt - display Optionsmenu"
    }, printed)
  end)

  it("reloads the ui for both the reload command and its rl alias", function()
    dispatch("reload")
    dispatch("rl")

    assert.equal(2, reloadCount)
  end)

  it("opens the settings main category for the opt command", function()
    dispatch("opt")

    assert.equal(1, openMainCategoryCount)
  end)

  it("prints the localized user error for an unknown command", function()
    dispatch("unknowncommand")

    assert.same({ "Invalid argument passed" }, userErrors)
    assert.same({}, printed)
    assert.equal(0, reloadCount)
    assert.equal(0, openMainCategoryCount)
  end)

  it("dispatches a newly registered command with the remaining arguments", function()
    local receivedArgs

    cmd.RegisterCommand("equipset", function(args)
      receivedArgs = args
    end, "equipset_help")

    dispatch("equipset pve second")

    assert.same({ "pve", "second" }, receivedArgs)
  end)

  it("includes a newly registered command in the generated help output", function()
    cmd.RegisterCommand("equipset", function() end, "equipset_help")

    dispatch("help")

    assert.same({
      "GearMenu:",
      "reload - reload UI",
      "opt - display Optionsmenu",
      "equipset - equip a gear set"
    }, printed)
  end)

  it("dispatches registered aliases without duplicating the help line", function()
    local callCount = 0

    cmd.RegisterCommand("equipset", function()
      callCount = callCount + 1
    end, "equipset_help", { "es" })

    dispatch("equipset")
    dispatch("es")

    assert.equal(2, callCount)

    dispatch("help")

    assert.same({
      "GearMenu:",
      "reload - reload UI",
      "opt - display Optionsmenu",
      "equipset - equip a gear set"
    }, printed)
  end)

  it("omits commands without a helpTextKey from the help output", function()
    cmd.RegisterCommand("hidden", function() end)

    dispatch("help")

    assert.same({
      "GearMenu:",
      "reload - reload UI",
      "opt - display Optionsmenu"
    }, printed)
  end)

  it("rejects invalid registrations without raising", function()
    cmd.RegisterCommand(nil, function() end)
    cmd.RegisterCommand("broken", nil)

    dispatch("broken")

    assert.same({ "Invalid argument passed" }, userErrors)
  end)
end)
