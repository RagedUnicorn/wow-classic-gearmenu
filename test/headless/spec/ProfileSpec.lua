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
  Tests for the GearMenu profile envelope, export/import and named-profile store
  (code/Profile.lua). GearMenuConfiguration and the no-op rggm.configuration stub
  are provided by test/headless/Bootstrap.lua.
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

describe("Profile", function()
  local profile = rggm.profile
  local previousConfiguration

  before_each(function()
    -- ApplySnapshot backfills via mod.configuration.SetupConfiguration; other specs dofile the real
    -- configuration module into the shared rggm namespace, so pin a no-op stub for these tests.
    previousConfiguration = rggm.configuration
    rggm.configuration = { SetupConfiguration = function() end }

    GearMenuConfiguration.profiles = {}
    GearMenuConfiguration.enableTooltips = true
    GearMenuConfiguration.filterItemQuality = 2
    GearMenuConfiguration.uiTheme = 2
    GearMenuConfiguration.gearBars = {}
    GearMenuConfiguration.quickChangeRules = {}
    GearMenuConfiguration.frames = {}
  end)

  after_each(function()
    rggm.configuration = previousConfiguration
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
