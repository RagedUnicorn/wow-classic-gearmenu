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
  Headless test bootstrap (busted helper, wired via the `helper` key in `.busted`).

  GearMenu modules have no package system: each file does `local mod = rggm; local me = {};
  mod.<name> = me` and is executed in `GearMenu.toc` load order. This bootstrap reproduces the
  minimal slice of that environment so the pure / lightly-stubbed modules load with no WoW client
  present:

    1. the WoW slot globals the data tables read at load time (only INVSLOT_HEAD is strictly
       required by Constants.lua today; the full standard set is defined for forward-compat),
    2. the `rggm` namespace table (normally created by Core.lua),
    3. RGGM_ENVIRONMENT, shimmed directly here (mirrors the *development* code/Environment.lua) so
       tests do not depend on `mvn generate-resources` or the build-generated file,
    4. the pure modules Constants.lua and Logger.lua, dofile'd in TOC dependency order,
    5. a minimal GearMenuConfiguration stand-in plus a no-op rggm.configuration, and the
       serialization modules (Serializer, Encoder, Profile) the profile specs exercise.

  It also prepends test/headless to package.path so specs can `require("WowStubs")` for the opt-in
  WoW-global stub registry.

  Module-state reset convention for specs: because modules load via dofile (not require /
  package.loaded), re-dofile a module inside before_each to get a fresh module table -- e.g.
  `dofile("code/CombatQueue.lua")` re-runs `mod.combatQueue = {}`, clearing its file-local state.

  Expected cwd: addon repo root. Run from elsewhere and the dofile()s will fail.
]]--

-- luacheck: globals rggm RGGM_ENVIRONMENT GearMenuConfiguration
-- luacheck: globals INVSLOT_AMMO INVSLOT_HEAD INVSLOT_NECK INVSLOT_SHOULDER INVSLOT_BODY
-- luacheck: globals INVSLOT_CHEST INVSLOT_WAIST INVSLOT_LEGS INVSLOT_FEET INVSLOT_WRIST
-- luacheck: globals INVSLOT_HAND INVSLOT_FINGER1 INVSLOT_FINGER2 INVSLOT_TRINKET1 INVSLOT_TRINKET2
-- luacheck: globals INVSLOT_BACK INVSLOT_MAINHAND INVSLOT_OFFHAND INVSLOT_RANGED INVSLOT_TABARD

-- allow specs to require the opt-in WoW-global stub registry as `require("WowStubs")`
package.path = "./test/headless/?.lua;" .. package.path

-- WoW inventory slot ids (plain numbers). Constants.lua reads INVSLOT_HEAD at load time.
INVSLOT_AMMO = 0
INVSLOT_HEAD = 1
INVSLOT_NECK = 2
INVSLOT_SHOULDER = 3
INVSLOT_BODY = 4
INVSLOT_CHEST = 5
INVSLOT_WAIST = 6
INVSLOT_LEGS = 7
INVSLOT_FEET = 8
INVSLOT_WRIST = 9
INVSLOT_HAND = 10
INVSLOT_FINGER1 = 11
INVSLOT_FINGER2 = 12
INVSLOT_TRINKET1 = 13
INVSLOT_TRINKET2 = 14
INVSLOT_BACK = 15
INVSLOT_MAINHAND = 16
INVSLOT_OFFHAND = 17
INVSLOT_RANGED = 18
INVSLOT_TABARD = 19

-- the addon namespace, normally created by code/Core.lua
rggm = {}

-- shimmed environment, mirroring the development build of code/Environment.lua
RGGM_ENVIRONMENT = {
  ADDON_IDENTIFIER = "com.ragedunicorn.wow.classic.gearmenu-addon",
  LOG_LEVEL = 4,
  LOG_EVENT = true,
  DEBUG = true
}

-- load the pure modules in GearMenu.toc dependency order
dofile("code/Constants.lua") -- defines RGGM_CONSTANTS
dofile("code/Event.lua")     -- defines rggm.event (reaches rggm.logger only at Dispatch time)
dofile("code/Logger.lua")    -- defines rggm.logger (reads RGGM_ENVIRONMENT at load time)
dofile("code/Common.lua")    -- defines rggm.common (Clone; used by Configuration.SetupConfiguration)

-- a minimal stand-in for the per-character saved variables, carrying the fields a profile snapshots
GearMenuConfiguration = {
  addonVersion = "v2.7.0",
  enableTooltips = true,
  enableSimpleTooltips = false,
  enableDragAndDrop = true,
  enableFastPress = false,
  enableUnequipSlot = true,
  filterItemQuality = 2,
  gearBars = {},
  quickChangeRules = {},
  frames = {},
  enableTrinketMenu = true,
  lockTrinketMenuFrame = false,
  trinketMenuShowCooldowns = true,
  trinketMenuColumns = 4,
  trinketMenuSlotSize = 40,
  uiTheme = 2,
  enableRuneSlots = true,
  profiles = {}
}

-- Profile.ApplySnapshot calls back into the configuration module to backfill
-- defaults; a no-op stub is enough for the headless tests
rggm.configuration = {
  SetupConfiguration = function() end
}

-- load the serialization modules under test (dependency order)
dofile("code/Serializer.lua")
dofile("code/Encoder.lua")
dofile("code/Profile.lua")
