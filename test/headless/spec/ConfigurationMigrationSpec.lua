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
  Spec for code/Configuration.lua's migration path. The field-rename and slot-mutation logic is
  pure -- it transforms the GearMenuConfiguration table in place -- so the upgrades can be driven
  with hand-built pre-migration fixtures and no WoW client.

  Each upgrade decides whether to run by reading GearMenuConfiguration.addonVersion, so every test
  installs a fixture with the relevant version and then asserts the post-migration shape. The module
  is re-dofile'd in before_each (the isolation mechanism documented in test/headless/Bootstrap.lua)
  so file-local state and the GearMenuConfiguration global start fresh each test.

  GearMenuConfiguration is the saved-variables global the module reads and mutates. busted runs each
  spec chunk in a sandboxed environment, so a bareword assignment would land in the sandbox rather
  than the _G the dofile'd module sees -- fixtures are therefore installed via the useConfig helper
  (which writes _G.GearMenuConfiguration) and assertions run against the returned local handle.

  Collaborators reached via mod.* (logger, gearBarManager, gearManager) are replaced with recorder
  stubs and restored in after_each so the shared rggm namespace does not leak across specs. The
  keybinding / metadata WoW globals the v2.0 migration touches come from wowStubs.install.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- the WoW inventory slot ids used in fixtures are defined by test/headless/Bootstrap.lua at runtime
-- luacheck: globals INVSLOT_HEAD INVSLOT_TRINKET1
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

--[[
  Install a pre-migration fixture as the saved-variables global and return it for assertions.

  @param {table} config
  @return {table}
]]--
local function useConfig(config)
  _G.GearMenuConfiguration = config
  return config
end

describe("Configuration migration", function()
  local configuration
  local previousModules
  local previousConfig
  local restore
  -- recorder state for the v2.0 collaborators / keybinding side effects
  local calls

  before_each(function()
    calls = {
      addGearBar = { count = 0, args = nil },
      gearSlotsRequested = {},
      bindingsSaved = 0,
      unboundKeys = {},
      boundClicks = {}
    }

    previousModules = {
      logger = rggm.logger,
      gearBarManager = rggm.gearBarManager,
      gearManager = rggm.gearManager
    }
    -- snapshot the global the upgrades mutate so it does not leak into other specs
    previousConfig = _G.GearMenuConfiguration

    -- silence the migration logging
    rggm.logger = {
      LogDebug = function() end,
      LogInfo = function() end,
      LogError = function() end
    }
    -- AddGearBar returns the bar table the v2.0 migration then mutates in place. Mirrors the real
    -- GearBarManager.AddGearBar by appending to GearMenuConfiguration.gearBars (the real
    -- SetupConfiguration nil-check initialises that list to {} before any migration runs).
    rggm.gearBarManager = {
      AddGearBar = function(displayName, isLocked)
        calls.addGearBar.count = calls.addGearBar.count + 1
        calls.addGearBar.args = { displayName = displayName, isLocked = isLocked }
        local gearBar = { id = 1, slots = {} }
        table.insert(_G.GearMenuConfiguration.gearBars, gearBar)
        return gearBar
      end
    }
    -- GetGearSlotForSlotId returns a fresh gearSlot the migration inserts into gearBar.slots
    rggm.gearManager = {
      GetGearSlotForSlotId = function(slotId)
        calls.gearSlotsRequested[#calls.gearSlotsRequested + 1] = slotId
        return { slotId = slotId }
      end
    }

    restore = wowStubs.install({
      C_AddOns = wowStubs.stubs.C_AddOns({ Version = "v2.0.0" }),
      -- no keybindings set by default; individual tests can override before calling the upgrade
      GetBindingKey = function() return nil end,
      SetBinding = function(key) calls.unboundKeys[#calls.unboundKeys + 1] = key end,
      SetBindingClick = function(key, action)
        calls.boundClicks[#calls.boundClicks + 1] = { key = key, action = action }
      end,
      GetCurrentBindingSet = function() return 1 end,
      SaveBindings = function() calls.bindingsSaved = calls.bindingsSaved + 1 end
    })

    dofile("code/Configuration.lua")
    configuration = rggm.configuration
  end)

  after_each(function()
    restore()

    rggm.logger = previousModules.logger
    rggm.gearBarManager = previousModules.gearBarManager
    rggm.gearManager = previousModules.gearManager
    _G.GearMenuConfiguration = previousConfig
  end)

  describe("UpgradeToV1_3_0", function()
    it("rewrites inactive slot value 0 to INVSLOT_NONE for an outdated version", function()
      local config = useConfig({
        addonVersion = "v1.2.0",
        slots = { [1] = 0, [2] = INVSLOT_HEAD, [3] = 0, [4] = INVSLOT_TRINKET1 }
      })

      configuration.UpgradeToV1_3_0()

      assert.are.equal(RGGM_CONSTANTS.INVSLOT_NONE, config.slots[1])
      assert.are.equal(INVSLOT_HEAD, config.slots[2])
      assert.are.equal(RGGM_CONSTANTS.INVSLOT_NONE, config.slots[3])
      assert.are.equal(INVSLOT_TRINKET1, config.slots[4])
    end)

    it("does not run for a version at or past v1.3.0 (leaves slot 0 untouched)", function()
      local config = useConfig({
        addonVersion = "v1.3.0",
        slots = { [1] = 0 }
      })

      configuration.UpgradeToV1_3_0()

      assert.are.equal(0, config.slots[1])
    end)
  end)

  describe("UpgradeToV1_4_0", function()
    it("renames enableFastpress to enableFastPress for an outdated version", function()
      local config = useConfig({
        addonVersion = "v1.3.0",
        enableFastpress = true
      })

      configuration.UpgradeToV1_4_0()

      assert.is_true(config.enableFastPress)
      assert.is_nil(config.enableFastpress)
    end)

    it("carries a false value through the rename", function()
      local config = useConfig({
        addonVersion = "v1.0.0",
        enableFastpress = false
      })

      configuration.UpgradeToV1_4_0()

      assert.is_false(config.enableFastPress)
      assert.is_nil(config.enableFastpress)
    end)

    it("does not run for a version at or past v1.4.0", function()
      local config = useConfig({
        addonVersion = "v1.4.0",
        enableFastpress = true,
        enableFastPress = false
      })

      configuration.UpgradeToV1_4_0()

      -- untouched: the legacy key is left as-is and the new key keeps its value
      assert.is_true(config.enableFastpress)
      assert.is_false(config.enableFastPress)
    end)
  end)

  describe("UpgradeToV2_0_0", function()
    --[[
      Builds a v1.x pre-migration config: the legacy flat gearBar fields plus a saved GM_GearBar
      frame position and a slots list. `slots` defaults to one active and one inactive slot.
      gearBars starts as {} -- the real SetupConfiguration initialises it before migrations run.
    ]]--
    local function legacyConfig(overrides)
      local config = {
        addonVersion = "v1.6.0",
        gearBars = {},
        lockGearBar = true,
        showKeyBindings = true,
        showCooldowns = false,
        slotSize = 32,
        slots = { INVSLOT_HEAD, RGGM_CONSTANTS.INVSLOT_NONE, INVSLOT_TRINKET1 },
        frames = {
          GM_GearBar = { point = "CENTER", relativePoint = "CENTER", posX = 10, posY = 20 }
        }
      }

      for key, value in pairs(overrides or {}) do
        config[key] = value
      end

      return config
    end

    it("creates a single gearBar carrying the migrated flat fields", function()
      local config = useConfig(legacyConfig())

      configuration.UpgradeToV2_0_0()

      assert.are.equal(1, calls.addGearBar.count)
      assert.are.equal(1, #config.gearBars)

      local gearBar = config.gearBars[1]
      assert.is_true(gearBar.isLocked)
      assert.is_true(gearBar.showKeyBindings)
      assert.is_false(gearBar.showCooldowns)
      assert.are.equal(32, gearBar.gearSlotSize)
      assert.are.equal(32, gearBar.changeSlotSize)
    end)

    it("migrates the GM_GearBar frame position onto the gearBar", function()
      local config = useConfig(legacyConfig())

      configuration.UpgradeToV2_0_0()

      local position = config.gearBars[1].position
      assert.are.equal("CENTER", position.point)
      assert.are.equal("CENTER", position.relativePoint)
      assert.are.equal(10, position.posX)
      assert.are.equal(20, position.posY)
    end)

    it("carries only the active (non INVSLOT_NONE) slots over to the gearBar", function()
      local config = useConfig(legacyConfig())

      configuration.UpgradeToV2_0_0()

      local slots = config.gearBars[1].slots
      assert.are.equal(2, #slots)
      assert.are.equal(INVSLOT_HEAD, slots[1].slotId)
      assert.are.equal(INVSLOT_TRINKET1, slots[2].slotId)
    end)

    it("clears the no-longer-used flat properties", function()
      local config = useConfig(legacyConfig())

      configuration.UpgradeToV2_0_0()

      assert.is_nil(config.lockGearBar)
      assert.is_nil(config.showKeyBindings)
      assert.is_nil(config.showCooldowns)
      assert.is_nil(config.slotSize)
      assert.is_nil(config.frames)
      assert.is_nil(config.slots)
    end)

    it("migrates a slot keybinding onto the new gearBar slot frame and saves bindings", function()
      local config = useConfig(legacyConfig({ slots = { INVSLOT_HEAD } }))
      -- the first slot has a keybinding configured under the old frame name
      wowStubs.install({
        GetBindingKey = function(action)
          if action == "CLICK GM_GearBarSlot_1:LeftButton" then return "SHIFT-1" end
          return nil
        end
      })

      configuration.UpgradeToV2_0_0()

      -- old binding cleared, new click binding installed onto the v2 slot frame
      assert.is_true(#calls.unboundKeys >= 1)
      assert.are.equal(1, #calls.boundClicks)
      assert.are.equal("SHIFT-1", calls.boundClicks[1].key)
      assert.are.equal(
        RGGM_CONSTANTS.ELEMENT_GEAR_BAR_BASE_FRAME_NAME .. "1Slot_1",
        calls.boundClicks[1].action
      )
      assert.are.equal("SHIFT-1", config.gearBars[1].slots[1].keyBinding)
      assert.are.equal(1, calls.bindingsSaved)
    end)

    it("aborts to an empty gearBar list when no GM_GearBar frame is present", function()
      local config = useConfig(legacyConfig({ frames = {} }))

      configuration.UpgradeToV2_0_0()

      assert.are.equal(0, calls.addGearBar.count)
      assert.are.equal(0, #config.gearBars)
    end)

    it("does not run for a version at or past v2.0.0", function()
      local config = useConfig(legacyConfig({ addonVersion = "v2.0.0" }))

      configuration.UpgradeToV2_0_0()

      assert.are.equal(0, calls.addGearBar.count)
      -- the flat fields are left untouched because the upgrade bailed early
      assert.is_true(config.lockGearBar)
      assert.is_not_nil(config.slots)
    end)
  end)

  describe("SetupConfiguration", function()
    -- SetupConfiguration backfills per-bar orientation / changeMenuDirection through the
    -- gearBarManager pure helpers. The migration before_each only stubs AddGearBar, so augment the
    -- stub with the two helpers (their own behaviour is covered by GearBarManagerSpec); the outer
    -- after_each restores the original module table.
    before_each(function()
      rggm.gearBarManager.IsChangeMenuDirectionValidForOrientation = function(direction, orientation)
        if orientation == RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_VERTICAL then
          return direction == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_LEFT
            or direction == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_RIGHT
        end

        return direction == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_UP
          or direction == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_DOWN
      end
      rggm.gearBarManager.GetDefaultChangeMenuDirection = function(orientation)
        if orientation == RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_VERTICAL then
          return RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_RIGHT
        end

        return RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_UP
      end
    end)

    it("backfills a nil orientation to horizontal", function()
      local config = useConfig({ gearBars = { { id = 1, slots = {} } } })

      configuration.SetupConfiguration()

      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_HORIZONTAL, config.gearBars[1].orientation)
    end)

    it("normalizes a now-invalid change menu direction to the orientation default", function()
      -- LEFT is invalid for a (backfilled) horizontal bar, so it resets to UP
      local config = useConfig({
        gearBars = { { id = 1, slots = {}, changeMenuDirection = RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_LEFT } }
      })

      configuration.SetupConfiguration()

      assert.are.equal(
        RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_UP, config.gearBars[1].changeMenuDirection)
    end)

    it("backfills a nil change menu direction to the orientation default", function()
      local config = useConfig({
        gearBars = { { id = 1, slots = {}, orientation = RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_VERTICAL } }
      })

      configuration.SetupConfiguration()

      assert.are.equal(
        RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_RIGHT, config.gearBars[1].changeMenuDirection)
    end)

    it("leaves a valid orientation / direction pair untouched", function()
      local config = useConfig({
        gearBars = {
          {
            id = 1,
            slots = {},
            orientation = RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_VERTICAL,
            changeMenuDirection = RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_LEFT
          }
        }
      })

      configuration.SetupConfiguration()

      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_VERTICAL, config.gearBars[1].orientation)
      assert.are.equal(
        RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_LEFT, config.gearBars[1].changeMenuDirection)
    end)

    -- the defaults-backfill fixtures set firstTimeInitializationDone so SetAddonVersion does not
    -- run FirstTimeInitialization (its AddGearSlot/UpdateGearSlot collaborators are not stubbed)
    it("backfills a missing scalar field with its declared default", function()
      local config = useConfig({ firstTimeInitializationDone = true })

      configuration.SetupConfiguration()

      assert.is_true(config.enableTooltips)
      assert.are.equal(2, config.filterItemQuality)
      assert.are.same({}, config.gearBars)
    end)

    it("backfills a missing boolean false default as false, not merely truthy", function()
      local config = useConfig({ firstTimeInitializationDone = true })

      configuration.SetupConfiguration()

      assert.is_false(config.enableSimpleTooltips)
      assert.is_false(config.enableFastPress)
      assert.is_false(config.lockTrinketMenuFrame)
    end)

    it("preserves a saved false value for a field whose default is true", function()
      local config = useConfig({ firstTimeInitializationDone = true, enableTooltips = false })

      configuration.SetupConfiguration()

      assert.is_false(config.enableTooltips)
    end)

    it("leaves user-owned collection content untouched", function()
      local config = useConfig({
        firstTimeInitializationDone = true,
        profiles = { raid = { enableTooltips = false, filterItemQuality = 4 } },
        quickChangeRules = { { changeFromItemId = 1, changeToItemId = 2, delay = 0 } },
        frames = { GM_TrinketMenu = { point = "CENTER", posX = 5, posY = 10 } }
      })

      configuration.SetupConfiguration()

      assert.are.same({ raid = { enableTooltips = false, filterItemQuality = 4 } }, config.profiles)
      assert.are.same({ { changeFromItemId = 1, changeToItemId = 2, delay = 0 } }, config.quickChangeRules)
      assert.are.same({ GM_TrinketMenu = { point = "CENTER", posX = 5, posY = 10 } }, config.frames)
    end)

    it("produces the same effective configuration for a fresh install and an upgrade", function()
      local freshConfig = useConfig({ firstTimeInitializationDone = true })
      configuration.SetupConfiguration()

      -- an upgraded player carries some fields from the previous version; the rest are missing
      local upgradedConfig = useConfig({
        firstTimeInitializationDone = true,
        addonVersion = "v2.0.0",
        enableTooltips = true,
        filterItemQuality = 2
      })
      configuration.SetupConfiguration()

      assert.are.same(freshConfig, upgradedConfig)
    end)

    it("backfills each bar independently", function()
      local config = useConfig({
        gearBars = {
          { id = 1, slots = {} },
          {
            id = 2,
            slots = {},
            orientation = RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_VERTICAL,
            changeMenuDirection = RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_RIGHT
          }
        }
      })

      configuration.SetupConfiguration()

      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_HORIZONTAL, config.gearBars[1].orientation)
      assert.are.equal(
        RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_UP, config.gearBars[1].changeMenuDirection)
      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_ORIENTATION_VERTICAL, config.gearBars[2].orientation)
      assert.are.equal(
        RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_RIGHT, config.gearBars[2].changeMenuDirection)
    end)
  end)

  describe("MergeDefaults", function()
    it("fills a missing nested key while preserving present sibling values", function()
      local target = { window = { posX = 10 } }
      local defaults = { window = { posX = 0, posY = 0 }, scale = 1 }

      configuration.MergeDefaults(target, defaults)

      assert.are.equal(10, target.window.posX)
      assert.are.equal(0, target.window.posY)
      assert.are.equal(1, target.scale)
    end)

    it("treats false as a present value and never overwrites it", function()
      local target = { enabled = false }

      configuration.MergeDefaults(target, { enabled = true })

      assert.is_false(target.enabled)
    end)

    it("deep-copies a backfilled table so the defaults are never aliased", function()
      local target = {}
      local defaults = { window = { posX = 0 } }

      configuration.MergeDefaults(target, defaults)
      target.window.posX = 42

      assert.are.equal(0, defaults.window.posX)
    end)
  end)

  describe("MigrationPath", function()
    it("is a no-op for an up-to-date configuration", function()
      local config = useConfig({
        addonVersion = "v2.0.0",
        enableFastpress = true,
        slots = { [1] = 0 },
        frames = { GM_GearBar = { point = "CENTER", relativePoint = "CENTER", posX = 0, posY = 0 } }
      })

      configuration.MigrationPath()

      assert.are.equal(0, calls.addGearBar.count)
      assert.is_true(config.enableFastpress)
      assert.are.equal(0, config.slots[1])
    end)

    it("runs every applicable upgrade for a legacy v1.0.0 configuration", function()
      local config = useConfig({
        addonVersion = "v1.0.0",
        gearBars = {},
        enableFastpress = true,
        lockGearBar = false,
        showKeyBindings = true,
        showCooldowns = true,
        slotSize = 40,
        slots = { INVSLOT_HEAD, 0, INVSLOT_TRINKET1 },
        frames = {
          GM_GearBar = { point = "TOP", relativePoint = "TOP", posX = 5, posY = 5 }
        }
      })

      configuration.MigrationPath()

      -- v1.4.0 rename ran
      assert.is_true(config.enableFastPress)
      assert.is_nil(config.enableFastpress)
      -- v2.0.0 gearBar build ran; v1.3.0 turned slot 0 into INVSLOT_NONE so it was dropped, leaving
      -- the two active slots
      assert.are.equal(1, #config.gearBars)
      assert.are.equal(2, #config.gearBars[1].slots)
      -- v2.0.0 cleared the legacy flat fields
      assert.is_nil(config.slots)
      assert.is_nil(config.frames)
      assert.is_nil(config.slotSize)
    end)
  end)
end)
