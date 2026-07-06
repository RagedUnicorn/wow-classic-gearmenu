--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

--[[
  GearMenu configuration profiles.

  Owns everything that makes a "GearMenu profile": which configuration fields are
  part of a profile, snapshotting the live config into a profile and applying a
  profile back, encoding a profile to / from a portable string (via the generic
  rggm.serializer + rggm.encoder modules), and the per-character named-profile
  store kept in GearMenuConfiguration.profiles.
]]--

local mod = rggm
local me = {}
mod.profile = me

me.tag = "Profile"

--[[
  Bumped when the on-the-wire profile payload changes shape. Import refuses any
  string whose schemaVersion is newer than this build understands.
]]--
local SCHEMA_VERSION = 1
--[[
  Identifies a GearMenu profile string and lets import fast-reject foreign
  strings before any decoding. The authoritative provenance check is the
  envelope's addon/schemaVersion fields.
]]--
local EXPORT_PREFIX = "GearMenu1:"
local ADDON_TAG = "GearMenu"

--[[
  The single source of truth for what a profile contains: each entry pairs a
  configurable field with the Lua type it must have. Snapshot and apply iterate
  the derived name list (me.PROFILE_FIELDS); import validates each present payload
  field against the derived type map (PROFILE_FIELD_TYPES). Adding a configurable
  option is therefore a one-line change here. Deliberately excludes bookkeeping
  (addonVersion, firstTimeInitializationDone) and the profile store itself
  (profiles). Types mirror the defaults in code/Configuration.lua (note gearBars
  defaults to nil there, hence the explicit "table").
]]--
local PROFILE_FIELD_SPEC = {
  { ["name"] = "enableTooltips",           ["type"] = "boolean" },
  { ["name"] = "enableSimpleTooltips",     ["type"] = "boolean" },
  { ["name"] = "enableDragAndDrop",        ["type"] = "boolean" },
  { ["name"] = "enableFastPress",          ["type"] = "boolean" },
  { ["name"] = "enableUnequipSlot",        ["type"] = "boolean" },
  { ["name"] = "filterItemQuality",        ["type"] = "number"  },
  { ["name"] = "gearBars",                 ["type"] = "table"   },
  { ["name"] = "quickChangeRules",         ["type"] = "table"   },
  { ["name"] = "frames",                   ["type"] = "table"   },
  { ["name"] = "enableTrinketMenu",        ["type"] = "boolean" },
  { ["name"] = "lockTrinketMenuFrame",     ["type"] = "boolean" },
  { ["name"] = "trinketMenuShowCooldowns", ["type"] = "boolean" },
  { ["name"] = "trinketMenuColumns",       ["type"] = "number"  },
  { ["name"] = "trinketMenuSlotSize",      ["type"] = "number"  },
  { ["name"] = "uiTheme",                  ["type"] = "number"  },
  { ["name"] = "enableRuneSlots",          ["type"] = "boolean" }
}

--[[
  Ordered list of profile field names, derived from PROFILE_FIELD_SPEC. Public so
  BuildSnapshot / ApplySnapshot can iterate it.
]]--
me.PROFILE_FIELDS = {}
--[[
  Field name -> expected Lua type, derived from PROFILE_FIELD_SPEC. Import validates
  each present payload field against this map before it can touch the live config, so
  a crafted or corrupt string of the wrong shape (e.g. gearBars = "x") is rejected at
  the envelope boundary instead of bricking the configuration when a later consumer
  iterates it.
]]--
local PROFILE_FIELD_TYPES = {}

for _, spec in ipairs(PROFILE_FIELD_SPEC) do
  me.PROFILE_FIELDS[#me.PROFILE_FIELDS + 1] = spec.name
  PROFILE_FIELD_TYPES[spec.name] = spec.type
end

--[[
  Validate that every field present in a payload has the expected Lua type.
  Fields left out are fine - SetupConfiguration backfills them with defaults.

  @param {table} payload
  @return {boolean}
    true if all present fields are well typed, false on the first mismatch
]]--
local function IsPayloadWellTyped(payload)
  for field, expectedType in pairs(PROFILE_FIELD_TYPES) do
    if payload[field] ~= nil and type(payload[field]) ~= expectedType then
      return false
    end
  end

  return true
end

--[[
  Verify that the gearBars carried by a payload have mutually unique ids. A
  well-formed export is always internally consistent (AddGearBar guarantees unique
  ids), so a duplicate here means a corrupt or hand-crafted string. Accepting it
  would let gearBarUiStorage[id] silently overwrite another bar's UI references and
  produce duplicate GM_GearBarFrame_<id> frames after the reload.

  A missing or non-table gearBars field is treated as unique-by-vacuity here; the
  table-type check lives in IsPayloadWellTyped.

  @param {table} payload
  @return {boolean}
    true if no two gearBars share an id, false otherwise
]]--
local function HasUniqueGearBarIds(payload)
  if type(payload.gearBars) ~= "table" then
    return true
  end

  local seen = {}

  for _, gearBar in pairs(payload.gearBars) do
    if type(gearBar) == "table" and gearBar.id ~= nil then
      if seen[gearBar.id] then
        return false
      end

      seen[gearBar.id] = true
    end
  end

  return true
end

--[[
  Lazily access the per-character profile store.

  @return {table}
    map of profileName -> payload snapshot
]]--
local function GetStore()
  if GearMenuConfiguration.profiles == nil then
    GearMenuConfiguration.profiles = {}
  end

  return GearMenuConfiguration.profiles
end

--[[
  Build a snapshot of the configurable fields out of the live
  GearMenuConfiguration.

  @return {table}
]]--
function me.BuildSnapshot()
  local snapshot = {}

  for _, field in ipairs(me.PROFILE_FIELDS) do
    snapshot[field] = mod.common.Clone(GearMenuConfiguration[field])
  end

  return snapshot
end

--[[
  Overwrite the configurable fields of the live GearMenuConfiguration from a
  snapshot. Missing fields are left for Configuration.SetupConfiguration to
  backfill with defaults, so an older-schema profile applies cleanly. The
  caller is responsible for refreshing the UI afterwards (a ReloadUI).

  @param {table} payload
]]--
function me.ApplySnapshot(payload)
  if type(payload) ~= "table" then return end

  for _, field in ipairs(me.PROFILE_FIELDS) do
    if payload[field] ~= nil then
      GearMenuConfiguration[field] = mod.common.Clone(payload[field])
    end
  end

  -- backfill any field the imported profile did not carry
  mod.configuration.SetupConfiguration()
end

--[[
  Encode a profile payload into a portable, copy-pasteable string.

  @param {table} payload
    a snapshot as produced by me.BuildSnapshot
  @param {string} name
    the profile name, carried in the envelope so import can suggest it

  @return {string}
]]--
function me.ExportString(payload, name)
  local envelope = {
    addon = ADDON_TAG,
    schemaVersion = SCHEMA_VERSION,
    addonVersion = GearMenuConfiguration.addonVersion,
    name = name,
    payload = payload
  }

  return EXPORT_PREFIX .. mod.encoder.Encode(mod.serializer.Serialize(envelope))
end

--[[
  Decode and validate a profile string. Never raises - returns a localization
  error key on any failure and leaves all state untouched.

  @param {string} encoded

  @return {table | nil}, {string | nil}
    the decoded envelope { addon, schemaVersion, addonVersion, name, payload },
    or nil plus a localization key describing the failure
]]--
function me.ImportString(encoded)
  if type(encoded) ~= "string" then
    return nil, "profile_error_invalid"
  end

  -- strip any whitespace a paste may have wrapped around / into the string
  encoded = string.gsub(encoded, "%s+", "")

  if encoded == "" then
    return nil, "profile_error_empty"
  end

  if string.sub(encoded, 1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
    return nil, "profile_error_invalid"
  end

  local serialized, decodeErr = mod.encoder.Decode(string.sub(encoded, #EXPORT_PREFIX + 1))

  if not serialized then
    if decodeErr == "checksum" then
      return nil, "profile_error_checksum"
    end

    return nil, "profile_error_invalid"
  end

  local envelope = mod.serializer.Deserialize(serialized)

  if type(envelope) ~= "table" then
    return nil, "profile_error_invalid"
  end

  if envelope.addon ~= ADDON_TAG then
    return nil, "profile_error_wrong_addon"
  end

  if type(envelope.schemaVersion) ~= "number" or envelope.schemaVersion > SCHEMA_VERSION then
    return nil, "profile_error_version"
  end

  if type(envelope.payload) ~= "table" then
    return nil, "profile_error_invalid"
  end

  if not IsPayloadWellTyped(envelope.payload) then
    return nil, "profile_error_invalid"
  end

  if not HasUniqueGearBarIds(envelope.payload) then
    return nil, "profile_error_invalid"
  end

  return envelope
end

--[[
  @return {table}
    alphabetically sorted list of saved profile names
]]--
function me.ListProfiles()
  local names = {}

  for name in pairs(GetStore()) do
    names[#names + 1] = name
  end

  table.sort(names)

  return names
end

--[[
  @param {string} name
  @return {boolean}
]]--
function me.ProfileExists(name)
  return GetStore()[name] ~= nil
end

--[[
  @param {string} name
  @return {table | nil}
    the stored payload snapshot, or nil if no such profile
]]--
function me.GetProfile(name)
  return GetStore()[name]
end

--[[
  Store (or overwrite) a named profile from a payload snapshot.

  @param {string} name
  @param {table} payload
]]--
function me.SaveProfile(name, payload)
  GetStore()[name] = mod.common.Clone(payload)
end

--[[
  @param {string} name
]]--
function me.DeleteProfile(name)
  GetStore()[name] = nil
end

--[[
  Rename a stored profile.

  @param {string} oldName
  @param {string} newName

  @return {boolean}
    true on success, false if oldName does not exist
]]--
function me.RenameProfile(oldName, newName)
  local store = GetStore()

  if store[oldName] == nil then
    return false
  end

  store[newName] = store[oldName]
  store[oldName] = nil

  return true
end
