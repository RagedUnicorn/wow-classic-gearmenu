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
  Key-set parity across the localization files. A recurring bug is a string added to enUS but not
  mirrored to the other locales (and vice versa); this spec makes the "add new strings to all
  locales" rule automatic instead of relying on review.

  Each localization/*.lua does `rggm.L = {}` (enUS) or, for the non-default locales, the same inside
  an `if (GetLocale() == "<locale>") then ... end` guard, followed by a series of
  `rggm.L["key"] = "value"` assignments. To capture a locale's key set we stub GetLocale() to return
  that file's own locale code (derived from its basename), stub C_AddOns (the "version" string reads
  GetAddOnMetadata at load time), reset rggm.L, dofile the file, and snapshot the resulting keys.

  enUS is the declared source of truth (see "Localization" in DEVELOPMENT.md); every other locale is
  compared against it and must have exactly the same key set -- no missing keys, no extra keys. The
  locale list is globbed from localization/*.lua so a future locale file is covered without editing
  this spec.

  On top of key parity, each shared key's string.format placeholder set is compared: a translation
  must consume the same arguments as enUS (e.g. enUS "(%s)" with a stray placeholder dropped, or an
  extra one added, in a translation would crash the formatting call at runtime). Placeholders are
  compared as a sorted multiset so a translator may legitimately reorder them.

  Finally every enUS key must be referenced as a quoted literal somewhere in code/ or gui/, so a key
  whose UI was removed is caught instead of being kept alive by translators.
]]--

local wowStubs = require("WowStubs")

local REFERENCE_LOCALE = "enUS"

--[[
  Glob localization/*.lua (cwd is the addon repo root, as for every spec) and return a list of
  { path, locale } where locale is the basename without the .lua extension.

  @return {table}
]]--
local function discoverLocaleFiles()
  local files = {}
  local handle = io.popen("ls localization/*.lua 2>/dev/null")

  if not handle then
    return files
  end

  for path in handle:lines() do
    local locale = path:match("([^/\\]+)%.lua$")
    files[#files + 1] = { path = path, locale = locale }
  end

  handle:close()

  return files
end

--[[
  Load a single locale file under stubbed globals and return a shallow copy of its rggm.L table
  (key -> string). Restores the globals it touched afterwards so nothing leaks across loads.

  @param {table} file
    { path, locale }
  @return {table}
]]--
local function loadLocale(file)
  local restore = wowStubs.install({
    GetLocale = wowStubs.stubs.GetLocale(file.locale),
    C_AddOns  = wowStubs.stubs.C_AddOns({ Version = "0.0.0-test" })
  })

  local previousL = rggm.L

  rggm.L = nil
  dofile(file.path)

  local loaded = rggm.L
  rggm.L = previousL
  restore()

  assert(
    type(loaded) == "table",
    file.path .. " did not populate rggm.L when GetLocale() == '" .. tostring(file.locale) .. "'"
  )

  local strings = {}
  for key, value in pairs(loaded) do
    strings[key] = value
  end

  return strings
end

--[[
  Return the key set (key -> true) of a locale's string table.

  @param {table} strings
  @return {table}
]]--
local function keySet(strings)
  local keys = {}
  for key in pairs(strings) do
    keys[key] = true
  end

  return keys
end

--[[
  Extract the string.format placeholders from a localized string as a sorted list, so two strings
  can be compared as a multiset (a reorder by a translator is allowed, a count/type change is not).

  Escaped "%%" (a literal percent) is stripped first so it is not mistaken for a placeholder. The
  remaining specifiers are matched as "%" + optional positional index ("1$") + optional
  flags/width/precision + a conversion letter, covering plain ("%s"), typed ("%d") and positional
  ("%1$s") forms.

  @param {string} value
  @return {table}
]]--
local function extractPlaceholders(value)
  local specifiers = {}

  for spec in value:gsub("%%%%", ""):gmatch("%%[%d%$%-%+ #%.]*[diouxXeEfgGqcsaA]") do
    specifiers[#specifiers + 1] = spec
  end
  table.sort(specifiers)

  return specifiers
end

--[[
  Read the Lua and XML source the addon ships (code/ and gui/, cwd is the addon repo root) into one
  string, so a locale key can be looked up as a quoted literal. Localization keys are only ever
  indexed with string literals, so a key that does not appear here is dead.

  @return {string}
]]--
local function readAddonSource()
  local chunks = {}
  local handle = io.popen("ls code/*.lua gui/*.lua gui/*.xml 2>/dev/null")

  if not handle then
    return ""
  end

  for path in handle:lines() do
    local file = io.open(path, "r")

    if file then
      chunks[#chunks + 1] = file:read("*a")
      file:close()
    end
  end

  handle:close()

  return table.concat(chunks, "\n")
end

--[[
  Return the keys present in `a` but absent from `b`, sorted for a stable failure message.

  @param {table} a
  @param {table} b
  @return {table}
]]--
local function difference(a, b)
  local missing = {}
  for key in pairs(a) do
    if not b[key] then
      missing[#missing + 1] = key
    end
  end
  table.sort(missing)

  return missing
end

describe("localization parity", function()
  local localeFiles = discoverLocaleFiles()
  local localeStrings = {}

  setup(function()
    for _, file in ipairs(localeFiles) do
      localeStrings[file.locale] = loadLocale(file)
    end
  end)

  it("discovers the localization files and the reference locale", function()
    assert.is_true(#localeFiles > 0, "no localization/*.lua files were discovered")

    local hasReference = false
    for _, file in ipairs(localeFiles) do
      if file.locale == REFERENCE_LOCALE then
        hasReference = true
      end
    end
    assert.is_true(hasReference, "reference locale " .. REFERENCE_LOCALE .. " was not discovered")
  end)

  it("every " .. REFERENCE_LOCALE .. " key is referenced by the addon source", function()
    local source = readAddonSource()
    local unused = {}

    assert.is_true(#source > 0, "no addon source was read from code/ and gui/")

    for key in pairs(localeStrings[REFERENCE_LOCALE]) do
      if not source:find('"' .. key .. '"', 1, true) then
        unused[#unused + 1] = key
      end
    end
    table.sort(unused)

    assert.is_true(
      #unused == 0,
      REFERENCE_LOCALE .. " defines keys the addon never uses: " .. table.concat(unused, ", ")
    )
  end)

  for _, file in ipairs(localeFiles) do
    if file.locale ~= REFERENCE_LOCALE then
      it("locale " .. file.locale .. " has the same keys as " .. REFERENCE_LOCALE, function()
        local reference = keySet(localeStrings[REFERENCE_LOCALE])
        local locale = keySet(localeStrings[file.locale])

        local missing = difference(reference, locale) -- in reference, absent from this locale
        local extra = difference(locale, reference)   -- in this locale, absent from reference

        assert.is_true(
          #missing == 0,
          file.locale .. " is missing keys present in " .. REFERENCE_LOCALE .. ": "
            .. table.concat(missing, ", ")
        )
        assert.is_true(
          #extra == 0,
          file.locale .. " has keys not present in " .. REFERENCE_LOCALE .. ": "
            .. table.concat(extra, ", ")
        )
      end)

      it("locale " .. file.locale .. " has the same format placeholders as " .. REFERENCE_LOCALE, function()
        local reference = localeStrings[REFERENCE_LOCALE]
        local locale = localeStrings[file.locale]

        local mismatches = {}
        local sharedKeys = {}
        for key in pairs(reference) do
          if locale[key] ~= nil then
            sharedKeys[#sharedKeys + 1] = key
          end
        end
        table.sort(sharedKeys)

        for _, key in ipairs(sharedKeys) do
          local referenceSpecs = extractPlaceholders(reference[key])
          local localeSpecs = extractPlaceholders(locale[key])

          if table.concat(referenceSpecs, ",") ~= table.concat(localeSpecs, ",") then
            mismatches[#mismatches + 1] = string.format(
              "%s (%s expects [%s], %s has [%s])",
              key,
              REFERENCE_LOCALE, table.concat(referenceSpecs, ","),
              file.locale, table.concat(localeSpecs, ",")
            )
          end
        end

        assert.is_true(
          #mismatches == 0,
          file.locale .. " has format-placeholder mismatches vs " .. REFERENCE_LOCALE .. ": "
            .. table.concat(mismatches, "; ")
        )
      end)
    end
  end
end)

describe("Localization enUS fallback", function()
  --[[
    Load enUS and then the passed locale the way the TOC does, with an extra key only enUS
    carries, and return the resulting rggm.L. Restores rggm.L and the stubbed globals.

    @param {string} locale

    @return {table}
  ]]--
  local function loadInGameOrder(locale)
    local restore = wowStubs.install({
      GetLocale = wowStubs.stubs.GetLocale(locale),
      C_AddOns  = wowStubs.stubs.C_AddOns({ Version = "0.0.0-test" })
    })
    local previousL = rggm.L

    rggm.L = nil
    dofile("localization/enUS.lua")
    rggm.L["spec_untranslated_key"] = "english only"
    dofile("localization/" .. locale .. ".lua")

    local loaded = rggm.L

    rggm.L = previousL
    restore()

    return loaded
  end

  for _, locale in ipairs({ "deDE", "ruRU", "zhCN" }) do
    it("resolves a key " .. locale .. " lacks to the enUS string", function()
      local strings = loadInGameOrder(locale)

      assert.are.equal("english only", strings["spec_untranslated_key"])
      -- the fallback is not a key of the locale, so the parity checks above still report it
      assert.is_nil(rawget(strings, "spec_untranslated_key"))
    end)

    it("keeps its own translation over the enUS string in " .. locale, function()
      local strings = loadInGameOrder(locale)

      assert.is_not_nil(rawget(strings, "options_title"))
      assert.are_not.equal("Options", strings["options_title"])
    end)
  end
end)
