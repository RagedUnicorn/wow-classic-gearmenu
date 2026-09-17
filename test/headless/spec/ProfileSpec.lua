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
  Tests for the GearMenu profile envelope, export/import, the named-profile store and
  the live active profile (code/Profile.lua). GearMenuConfiguration and the no-op
  rggm.configuration stub are provided by test/headless/Bootstrap.lua.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each
-- luacheck: ignore 143

--[[
  Read a source file from the repo root (the expected busted cwd).

  @param {string} path
  @return {string}
]]--
local function readSource(path)
  local handle = assert(io.open(path, "r"))
  local content = handle:read("*a")
  handle:close()

  return content
end

--[[
  EnsureDefaultProfile seeds the default profile from the shipped defaults, which live in
  code/Configuration.lua. dofile the real module once to capture its GetDefaults, then put the
  namespace back so the no-op stub installed per test stays in charge of SetupConfiguration.

  @return {function}
]]--
local function captureGetDefaults()
  local previous = rggm.configuration

  dofile("code/Configuration.lua")

  local getDefaults = rggm.configuration.GetDefaults
  rggm.configuration = previous

  return getDefaults
end

--[[
  The starter GearBar the real FirstTimeInitialization creates on a fresh install, reduced
  to a recognizable fixture: ResetActiveProfile has to run it between applying the factory
  defaults and mirroring, so the reset ends with this bar in both the live configuration
  and the active profile.
]]--
local STARTER_GEAR_BAR = { id = 100001, displayName = "Default GearBar", slots = { 13, 14, 1 } }

describe("Profile", function()
  local profile = rggm.profile
  local getDefaults = captureGetDefaults()
  local defaultName = RGGM_CONSTANTS.DEFAULT_PROFILE_NAME
  local previousConfiguration
  local previousLogger

  before_each(function()
    -- EnsureActiveProfile logs the adoption; the real logger reaches the chat frame and the
    -- filter module, neither of which the bootstrap loads, so a silent stub stands in
    previousLogger = rggm.logger
    rggm.logger = { LogInfo = function() end, LogDebug = function() end, LogWarn = function() end }

    -- ApplySnapshot backfills via mod.configuration.SetupConfiguration; other specs dofile the real
    -- configuration module into the shared rggm namespace, so pin a stub for these tests. The
    -- stubbed FirstTimeInitialization seeds the starter GearBar like the real one does.
    previousConfiguration = rggm.configuration
    rggm.configuration = {
      SetupConfiguration = function() end,
      GetDefaults = getDefaults,
      FirstTimeInitialization = function()
        GearMenuConfiguration.gearBars[#GearMenuConfiguration.gearBars + 1] = rggm.common.Clone(STARTER_GEAR_BAR)
        GearMenuConfiguration.firstTimeInitializationDone = true
      end
    }

    GearMenuConfiguration.profiles = {}
    GearMenuConfiguration.activeProfile = nil
    GearMenuConfiguration.enableTooltips = true
    GearMenuConfiguration.enableFastPress = false
    GearMenuConfiguration.filterItemQuality = 2
    GearMenuConfiguration.uiTheme = 2
    GearMenuConfiguration.gearBars = {}
    GearMenuConfiguration.quickChangeRules = {}
    GearMenuConfiguration.frames = {}
  end)

  after_each(function()
    rggm.configuration = previousConfiguration
    rggm.logger = previousLogger
  end)

  it("exports and imports a snapshot round-trip", function()
    local payload = profile.BuildSnapshot()
    local envelope, err = profile.ImportString(profile.ExportString(payload, "MyProfile"))

    assert.is_nil(err)
    assert.is_table(envelope)
    assert.are.equal("GearMenu", envelope.addon)
    assert.are.equal("MyProfile", envelope.name)
    assert.are.same(payload, envelope.payload)
  end)

  it("tolerates whitespace wrapped around the import string", function()
    local exported = profile.ExportString(profile.BuildSnapshot(), "P")

    assert.is_table(profile.ImportString("  \n" .. exported .. "\n  "))
  end)

  it("rejects an empty string", function()
    local _, err = profile.ImportString("")
    assert.are.equal("profile_error_empty", err)
  end)

  it("rejects an unrecognized string", function()
    local _, err = profile.ImportString("not-a-gearmenu-string")
    assert.are.equal("profile_error_invalid", err)
  end)

  it("rejects an envelope from a different addon", function()
    local serialized = rggm.serializer.Serialize({ addon = "Pulse", schemaVersion = 1, payload = {} })
    local _, err = profile.ImportString("GearMenu1:" .. rggm.encoder.Encode(serialized))

    assert.are.equal("profile_error_wrong_addon", err)
  end)

  it("rejects a newer schema version", function()
    local serialized = rggm.serializer.Serialize({ addon = "GearMenu", schemaVersion = 999, payload = {} })
    local _, err = profile.ImportString("GearMenu1:" .. rggm.encoder.Encode(serialized))

    assert.are.equal("profile_error_version", err)
  end)

  it("rejects a payload whose field has the wrong type", function()
    local serialized = rggm.serializer.Serialize({
      addon = "GearMenu",
      schemaVersion = 1,
      -- gearBars must be a table; a string would later error in SetupConfiguration
      payload = { gearBars = "x" }
    })
    local envelope, err = profile.ImportString("GearMenu1:" .. rggm.encoder.Encode(serialized))

    assert.is_nil(envelope)
    assert.are.equal("profile_error_invalid", err)
  end)

  it("rejects a payload whose boolean field is a number", function()
    local serialized = rggm.serializer.Serialize({
      addon = "GearMenu",
      schemaVersion = 1,
      payload = { enableTooltips = 1 }
    })
    local envelope, err = profile.ImportString("GearMenu1:" .. rggm.encoder.Encode(serialized))

    assert.is_nil(envelope)
    assert.are.equal("profile_error_invalid", err)
  end)

  it("rejects a payload whose gearBars carry duplicate ids", function()
    local serialized = rggm.serializer.Serialize({
      addon = "GearMenu",
      schemaVersion = 1,
      -- a corrupt / hand-crafted string can carry two bars sharing an id, which would
      -- clobber gearBarUiStorage and create duplicate GM_GearBarFrame_<id> frames
      payload = { gearBars = { { id = 100001 }, { id = 100001 } } }
    })
    local envelope, err = profile.ImportString("GearMenu1:" .. rggm.encoder.Encode(serialized))

    assert.is_nil(envelope)
    assert.are.equal("profile_error_invalid", err)
  end)

  it("accepts a payload whose gearBars carry unique ids", function()
    local serialized = rggm.serializer.Serialize({
      addon = "GearMenu",
      schemaVersion = 1,
      payload = { gearBars = { { id = 100001 }, { id = 100002 } } }
    })
    local envelope, err = profile.ImportString("GearMenu1:" .. rggm.encoder.Encode(serialized))

    assert.is_nil(err)
    assert.is_table(envelope)
  end)

  it("accepts a partial payload that omits fields", function()
    local serialized = rggm.serializer.Serialize({
      addon = "GearMenu",
      schemaVersion = 1,
      payload = { enableTooltips = false, filterItemQuality = 4 }
    })
    local envelope, err = profile.ImportString("GearMenu1:" .. rggm.encoder.Encode(serialized))

    assert.is_nil(err)
    assert.is_table(envelope)
    assert.is_false(envelope.payload.enableTooltips)
  end)

  it("rejects a corrupt string via the checksum", function()
    local exported = profile.ExportString(profile.BuildSnapshot(), "P")
    local prefixLength = #("GearMenu1:")
    local bodyFirst = string.sub(exported, prefixLength + 1, prefixLength + 1)
    local replacement = bodyFirst == "A" and "B" or "A"
    local corrupted = string.sub(exported, 1, prefixLength) .. replacement .. string.sub(exported, prefixLength + 2)

    local _, err = profile.ImportString(corrupted)

    assert.are.equal("profile_error_checksum", err)
  end)

  it("applies a snapshot onto the live configuration", function()
    profile.ApplySnapshot({ enableTooltips = false, filterItemQuality = 4, uiTheme = 1 })

    assert.is_false(GearMenuConfiguration.enableTooltips)
    assert.are.equal(4, GearMenuConfiguration.filterItemQuality)
    assert.are.equal(1, GearMenuConfiguration.uiTheme)
  end)

  it("does not share table references between profile and live config", function()
    GearMenuConfiguration.frames = { GM_TrinketMenuFrame = { posX = 1 } }
    profile.SaveProfile("snap", profile.BuildSnapshot())
    -- mutating the live config must not bleed into the stored profile
    GearMenuConfiguration.frames.GM_TrinketMenuFrame.posX = 999

    assert.are.equal(1, profile.GetProfile("snap").frames.GM_TrinketMenuFrame.posX)
  end)

  it("stores, lists, renames and deletes named profiles", function()
    profile.SaveProfile("alpha", profile.BuildSnapshot())
    profile.SaveProfile("beta", profile.BuildSnapshot())
    assert.are.same({ "alpha", "beta" }, profile.ListProfiles())
    assert.is_true(profile.ProfileExists("alpha"))

    assert.is_true(profile.RenameProfile("alpha", "gamma"))
    assert.are.same({ "beta", "gamma" }, profile.ListProfiles())

    profile.DeleteProfile("beta")
    assert.are.same({ "gamma" }, profile.ListProfiles())
  end)

  it("never carries the active profile name inside a profile", function()
    GearMenuConfiguration.activeProfile = "Raid"

    assert.is_nil(profile.BuildSnapshot().activeProfile)
    assert.is_nil(profile.BuildDefaultSnapshot().activeProfile)

    for _, field in ipairs(profile.PROFILE_FIELDS) do
      assert.are_not.equal("activeProfile", field)
    end
  end)

  describe("name length", function()
    local maxLength = RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH

    it("accepts a name up to the limit", function()
      assert.is_false(profile.IsNameTooLong(""))
      assert.is_false(profile.IsNameTooLong(string.rep("a", maxLength)))
    end)

    it("refuses a name past the limit", function()
      assert.is_true(profile.IsNameTooLong(string.rep("a", maxLength + 1)))
    end)

    it("counts characters and not bytes so a localized name is not cut short", function()
      -- multibyte characters: every one of them is a single character to the user
      assert.is_false(profile.IsNameTooLong(string.rep("ü", maxLength)))
      assert.is_true(profile.IsNameTooLong(string.rep("ü", maxLength + 1)))
    end)

    it("tolerates a non string name", function()
      assert.is_false(profile.IsNameTooLong(nil))
    end)
  end)

  describe("default profile", function()
    it("seeds the default profile when the store does not hold one yet", function()
      assert.are.same({}, profile.ListProfiles())

      profile.EnsureDefaultProfile()

      assert.are.same({ defaultName }, profile.ListProfiles())
      assert.is_true(profile.ProfileExists(defaultName))
    end)

    it("seeds it from the shipped defaults, not from the live configuration", function()
      -- a customized live configuration must not bleed into the factory baseline
      GearMenuConfiguration.enableTooltips = false
      GearMenuConfiguration.filterItemQuality = 5
      GearMenuConfiguration.uiTheme = RGGM_CONSTANTS.UI_THEME_CLASSIC
      GearMenuConfiguration.gearBars = { { id = 100001, slots = {} } }
      GearMenuConfiguration.frames = { GM_TrinketMenuFrame = { posX = 42 } }

      profile.EnsureDefaultProfile()

      local payload = profile.GetProfile(defaultName)

      assert.is_true(payload.enableTooltips)
      assert.are.equal(2, payload.filterItemQuality)
      assert.are.equal(RGGM_CONSTANTS.UI_THEME_CUSTOM, payload.uiTheme)
      -- the userOwned collections default to empty; the starter GearBar is added by the reset
      assert.are.same({}, payload.gearBars)
      assert.are.same({}, payload.quickChangeRules)
      assert.are.same({}, payload.frames)
    end)

    it("carries every profile field", function()
      profile.EnsureDefaultProfile()

      local payload = profile.GetProfile(defaultName)

      for _, field in ipairs(profile.PROFILE_FIELDS) do
        assert.is_not_nil(payload[field], "default profile is missing " .. field)
      end
    end)

    it("does not share table references with the shipped defaults", function()
      profile.EnsureDefaultProfile()
      -- a later mutation of the seeded payload must not reach CONFIGURATION_DEFAULTS
      profile.GetProfile(defaultName).frames.GM_TrinketMenuFrame = { posX = 1 }

      assert.are.same({}, getDefaults().frames)
    end)

    it("leaves an existing Default alone and seeds it only when absent", function()
      -- Default is the editable home profile: its stored copy holds the player's own
      -- settings, so a login must never overwrite it with the factory defaults
      GearMenuConfiguration.profiles = {
        [defaultName] = {
          enableTooltips = false,
          gearBars = { { id = 100001, slots = {} } }
        }
      }

      profile.EnsureDefaultProfile()

      assert.are.same(
        { enableTooltips = false, gearBars = { { id = 100001, slots = {} } } },
        profile.GetProfile(defaultName)
      )

      GearMenuConfiguration.profiles = {}
      profile.EnsureDefaultProfile()

      assert.are.same(profile.BuildDefaultSnapshot(), profile.GetProfile(defaultName))
    end)

    it("is an editable home profile: loading it resets nothing, ResetActiveProfile does", function()
      profile.EnsureDefaultProfile()
      profile.EnsureActiveProfile()
      GearMenuConfiguration.enableFastPress = true
      GearMenuConfiguration.filterItemQuality = 5
      GearMenuConfiguration.gearBars = { { id = 200001, slots = {} }, { id = 200002, slots = {} } }
      GearMenuConfiguration.quickChangeRules = { { from = 1, to = 2 } }

      -- the edits belong to the active Default, so there is nothing to load
      assert.is_false(profile.SwitchProfile(defaultName))
      assert.is_true(GearMenuConfiguration.enableFastPress)
      assert.are.equal(2, #GearMenuConfiguration.gearBars)

      profile.ResetActiveProfile()

      assert.is_false(GearMenuConfiguration.enableFastPress)
      assert.are.equal(2, GearMenuConfiguration.filterItemQuality)
      assert.are.same({}, GearMenuConfiguration.quickChangeRules)
      -- the factory defaults plus the starter GearBar: the fresh-install state
      assert.are.same({ STARTER_GEAR_BAR }, GearMenuConfiguration.gearBars)
      assert.are.same(profile.BuildSnapshot(), profile.GetProfile(defaultName))
    end)

    it("refuses to delete the default profile", function()
      profile.EnsureDefaultProfile()

      assert.is_false(profile.DeleteProfile(defaultName))
      assert.is_true(profile.ProfileExists(defaultName))
    end)

    it("refuses to rename the default profile", function()
      profile.EnsureDefaultProfile()

      assert.is_false(profile.RenameProfile(defaultName, "MyDefault"))
      assert.is_true(profile.ProfileExists(defaultName))
      assert.is_false(profile.ProfileExists("MyDefault"))
    end)

    it("refuses to rename another profile onto the default name", function()
      profile.EnsureDefaultProfile()
      profile.SaveProfile("alpha", profile.BuildSnapshot())

      assert.is_false(profile.RenameProfile("alpha", defaultName))
      assert.is_true(profile.ProfileExists("alpha"))
      assert.are.same(profile.BuildDefaultSnapshot(), profile.GetProfile(defaultName))
    end)

    it("refuses to overwrite the default profile through SaveProfile", function()
      profile.EnsureDefaultProfile()
      GearMenuConfiguration.filterItemQuality = 5

      assert.is_false(profile.SaveProfile(defaultName, profile.BuildSnapshot()))
      assert.are.equal(2, profile.GetProfile(defaultName).filterItemQuality)
    end)

    it("still saves, renames and deletes user created profiles", function()
      profile.EnsureDefaultProfile()

      assert.is_true(profile.SaveProfile("alpha", profile.BuildSnapshot()))
      assert.is_true(profile.RenameProfile("alpha", "beta"))
      assert.is_true(profile.DeleteProfile("beta"))
      assert.are.same({ defaultName }, profile.ListProfiles())
    end)

    it("recognizes only the reserved name as the default profile", function()
      assert.is_true(profile.IsDefaultProfile(defaultName))
      assert.is_false(profile.IsDefaultProfile("default"))
      assert.is_false(profile.IsDefaultProfile(nil))
    end)
  end)

  describe("active profile", function()
    it("has none until one is adopted, and the defaults never name one", function()
      assert.is_nil(profile.GetActiveProfileName())
      assert.is_nil(getDefaults().activeProfile)

      profile.EnsureDefaultProfile()
      assert.is_nil(profile.GetActiveProfileName())

      profile.EnsureActiveProfile()

      assert.are.equal(defaultName, profile.GetActiveProfileName())
      assert.are.same(profile.BuildSnapshot(), profile.GetProfile(defaultName))
    end)

    it("mirrors the live configuration into the active profile, a missing or dangling name repaired to Default",
      function()
      profile.EnsureDefaultProfile()
      GearMenuConfiguration.enableTooltips = false

      -- no active name yet: the mirror lands in Default
      assert.are.equal(defaultName, profile.SaveActiveProfile())
      assert.are.equal(defaultName, profile.GetActiveProfileName())
      assert.is_false(profile.GetProfile(defaultName).enableTooltips)

      profile.SaveProfile("Raid", profile.BuildSnapshot())
      GearMenuConfiguration.activeProfile = "Raid"
      GearMenuConfiguration.enableFastPress = true

      assert.are.equal("Raid", profile.SaveActiveProfile())
      assert.is_true(profile.GetProfile("Raid").enableFastPress)
      assert.is_false(profile.GetProfile(defaultName).enableFastPress)

      -- the mirrored copy is its own table
      GearMenuConfiguration.gearBars[1] = { id = 100001, slots = {} }
      assert.are.same({}, profile.GetProfile("Raid").gearBars)

      -- a name whose profile went is repaired to Default
      GearMenuConfiguration.activeProfile = "Gone"
      assert.are.equal(defaultName, profile.SaveActiveProfile())
      assert.are.equal(defaultName, profile.GetActiveProfileName())
      assert.is_true(profile.GetProfile(defaultName).enableFastPress)
    end)

    it("adopts the profile the player applied and left untouched on a store without an active name", function()
      -- the upgrade from the snapshot model: the player applied Raid before the update and
      -- changed nothing since, so the live configuration still equals its stored copy
      profile.EnsureDefaultProfile()
      GearMenuConfiguration.enableFastPress = true
      GearMenuConfiguration.gearBars = { { id = 100001, slots = { 13, 14 } } }
      profile.SaveProfile("Raid", profile.BuildSnapshot())
      profile.SaveProfile("PvP", profile.BuildSnapshot())
      -- PvP drifted from the live configuration by one field
      profile.GetProfile("PvP").enableTooltips = false

      profile.EnsureActiveProfile()

      assert.are.equal("Raid", profile.GetActiveProfileName())
      assert.are.same(profile.BuildSnapshot(), profile.GetProfile("Raid"))
      assert.is_true(profile.GetProfile(defaultName).enableTooltips)
      assert.is_false(profile.GetProfile(defaultName).enableFastPress)
    end)

    it("falls back to Default when no stored profile equals the live configuration, on a dangling name too", function()
      profile.EnsureDefaultProfile()
      profile.SaveProfile("Raid", profile.BuildSnapshot())
      -- edited after the apply: the drift makes Raid no match
      GearMenuConfiguration.enableFastPress = true

      profile.EnsureActiveProfile()

      assert.are.equal(defaultName, profile.GetActiveProfileName())
      assert.is_true(profile.GetProfile(defaultName).enableFastPress)
      assert.is_false(profile.GetProfile("Raid").enableFastPress)

      -- a name whose profile went: the same rule, and here the live configuration equals Raid again
      GearMenuConfiguration.activeProfile = "Gone"
      GearMenuConfiguration.enableFastPress = false

      profile.EnsureActiveProfile()

      assert.are.equal("Raid", profile.GetActiveProfileName())
    end)

    it("keeps an active profile that exists and mirrors the live configuration into it at every login", function()
      profile.EnsureDefaultProfile()
      profile.SaveProfile("Raid", profile.BuildSnapshot())
      GearMenuConfiguration.activeProfile = "Raid"
      -- an edit no logout mirrored (a crash)
      GearMenuConfiguration.enableTooltips = false

      profile.EnsureActiveProfile()

      assert.are.equal("Raid", profile.GetActiveProfileName())
      assert.is_false(profile.GetProfile("Raid").enableTooltips)
      assert.is_true(profile.GetProfile(defaultName).enableTooltips)
    end)

    it("switches by mirroring the active profile first, then applying and activating the target", function()
      profile.EnsureDefaultProfile()
      profile.EnsureActiveProfile()
      profile.SaveProfile("Raid", profile.BuildSnapshot())
      profile.GetProfile("Raid").enableFastPress = true
      profile.GetProfile("Raid").gearBars = { { id = 100001, slots = { 13 } } }
      -- an edit that belongs to the active Default
      GearMenuConfiguration.enableTooltips = false

      assert.is_true(profile.SwitchProfile("Raid"))

      assert.are.equal("Raid", profile.GetActiveProfileName())
      assert.is_true(GearMenuConfiguration.enableFastPress)
      assert.are.same({ { id = 100001, slots = { 13 } } }, GearMenuConfiguration.gearBars)
      assert.is_true(GearMenuConfiguration.enableTooltips)
      assert.is_false(profile.GetProfile(defaultName).enableTooltips)

      -- the active profile and an unknown name are no switch, and nothing is mirrored either
      GearMenuConfiguration.filterItemQuality = 5
      assert.is_false(profile.SwitchProfile("Raid"))
      assert.is_false(profile.SwitchProfile("Gone"))
      assert.are.equal("Raid", profile.GetActiveProfileName())
      assert.are.equal(5, GearMenuConfiguration.filterItemQuality)
      assert.are.equal(2, profile.GetProfile("Raid").filterItemQuality)
    end)

    it("creates a profile as a copy of the current settings and activates it, the live configuration untouched",
      function()
      profile.EnsureDefaultProfile()
      profile.EnsureActiveProfile()
      GearMenuConfiguration.enableFastPress = true
      GearMenuConfiguration.gearBars = { { id = 100001, slots = { 13 } } }

      assert.is_true(profile.CreateProfile("Raid"))

      assert.are.equal("Raid", profile.GetActiveProfileName())
      assert.are.same(profile.BuildSnapshot(), profile.GetProfile("Raid"))
      assert.is_true(profile.GetProfile("Raid").enableFastPress)
      assert.are.equal(1, #GearMenuConfiguration.gearBars)
      -- Default was mirrored before the copy, so both hold the same settings in separate tables
      assert.are.same(profile.GetProfile("Raid"), profile.GetProfile(defaultName))
      profile.GetProfile("Raid").gearBars[1].slots[1] = 1
      assert.are.equal(13, profile.GetProfile(defaultName).gearBars[1].slots[1])
      assert.are.equal(13, GearMenuConfiguration.gearBars[1].slots[1])

      assert.is_false(profile.CreateProfile("Raid"))
      assert.is_false(profile.CreateProfile(defaultName))
      assert.is_false(profile.CreateProfile(""))
      assert.is_false(profile.CreateProfile(nil))
      assert.are.same({ defaultName, "Raid" }, profile.ListProfiles())
      assert.are.equal("Raid", profile.GetActiveProfileName())
    end)

    it("deleting the active profile falls back to Default and says so, deleting another does not", function()
      profile.EnsureDefaultProfile()
      profile.EnsureActiveProfile()
      GearMenuConfiguration.enableFastPress = true
      profile.CreateProfile("Raid")
      profile.CreateProfile("PvP")
      -- an edit of the active PvP
      GearMenuConfiguration.enableTooltips = false

      local deleted, fellBack = profile.DeleteProfile("Raid")

      assert.is_true(deleted)
      assert.is_false(fellBack)
      assert.are.equal("PvP", profile.GetActiveProfileName())
      assert.is_false(GearMenuConfiguration.enableTooltips)

      deleted, fellBack = profile.DeleteProfile("PvP")

      assert.is_true(deleted)
      assert.is_true(fellBack)
      assert.are.equal(defaultName, profile.GetActiveProfileName())
      assert.is_nil(profile.GetProfile("PvP"))
      -- Default's stored copy took over the live configuration, the edit went with PvP
      assert.is_true(GearMenuConfiguration.enableFastPress)
      assert.is_true(GearMenuConfiguration.enableTooltips)
      assert.are.same(profile.GetProfile(defaultName), profile.BuildSnapshot())
      assert.are.same({ defaultName }, profile.ListProfiles())

      assert.is_false(profile.DeleteProfile(defaultName))
      assert.are.equal(defaultName, profile.GetActiveProfileName())
    end)

    it("renaming the active profile moves the active name along", function()
      profile.EnsureDefaultProfile()
      profile.EnsureActiveProfile()
      profile.CreateProfile("Raid")
      profile.SaveProfile("PvP", profile.BuildSnapshot())

      assert.is_true(profile.RenameProfile("PvP", "Arena"))
      assert.are.equal("Raid", profile.GetActiveProfileName())

      assert.is_true(profile.RenameProfile("Raid", "Raid Night"))
      assert.are.equal("Raid Night", profile.GetActiveProfileName())
      assert.are.equal("Raid Night", profile.SaveActiveProfile())
      assert.are.same({ defaultName, "Arena", "Raid Night" }, profile.ListProfiles())
    end)

    it("resets the active profile to the factory state plus the starter GearBar and mirrors it", function()
      profile.EnsureDefaultProfile()
      profile.EnsureActiveProfile()
      GearMenuConfiguration.enableTooltips = false
      profile.CreateProfile("Raid")
      GearMenuConfiguration.enableFastPress = true
      GearMenuConfiguration.filterItemQuality = 5
      GearMenuConfiguration.gearBars = { { id = 200001, slots = {} }, { id = 200002, slots = {} } }
      GearMenuConfiguration.quickChangeRules = { { from = 1, to = 2 } }
      GearMenuConfiguration.firstTimeInitializationDone = true

      profile.ResetActiveProfile()

      assert.are.equal("Raid", profile.GetActiveProfileName())
      assert.is_false(GearMenuConfiguration.enableFastPress)
      assert.is_true(GearMenuConfiguration.enableTooltips)
      assert.are.equal(2, GearMenuConfiguration.filterItemQuality)
      assert.are.same({}, GearMenuConfiguration.quickChangeRules)
      -- the starter GearBar is back like on a fresh install, and it went into the mirror
      assert.are.same({ STARTER_GEAR_BAR }, GearMenuConfiguration.gearBars)
      assert.are.same(profile.BuildSnapshot(), profile.GetProfile("Raid"))
      assert.are.same({ STARTER_GEAR_BAR }, profile.GetProfile("Raid").gearBars)
      -- the other profiles are untouched
      assert.is_false(profile.GetProfile(defaultName).enableTooltips)
    end)

    it("lists Default first and the rest sorted", function()
      profile.EnsureDefaultProfile()
      profile.SaveProfile("Zulu", profile.BuildSnapshot())
      profile.SaveProfile("Alpha", profile.BuildSnapshot())
      profile.SaveProfile("alts", profile.BuildSnapshot())

      assert.are.same({ defaultName, "Alpha", "Zulu", "alts" }, profile.ListProfiles())
    end)
  end)

  it("imports a payload as data without executing it", function()
    local serialized = rggm.serializer.Serialize({
      addon = "GearMenu",
      schemaVersion = 1,
      payload = { enableTooltips = true }
    })
    local envelope = profile.ImportString("GearMenu1:" .. rggm.encoder.Encode(serialized))

    assert.is_table(envelope)
    assert.is_true(envelope.payload.enableTooltips)
  end)

  it("never uses loadstring/load in the serialization / import path", function()
    local sources = { "code/Serializer.lua", "code/Encoder.lua", "code/Profile.lua" }

    for _, path in ipairs(sources) do
      local src = readSource(path)
      -- match invocations, not the prose in comments that documents the no-loadstring contract:
      -- require a call paren, and the %f[%a] frontier on load( excludes payload( etc.
      assert.is_nil(string.find(src, "loadstring%s*%("), path .. " must not call loadstring")
      assert.is_nil(string.find(src, "%f[%a]load%s*%("), path .. " must not call load()")
    end
  end)
end)
