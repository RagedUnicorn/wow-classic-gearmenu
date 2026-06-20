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

  enUS is the declared source of truth (see CLAUDE.md); every other locale is compared against it and
  must have exactly the same key set -- no missing keys, no extra keys. The locale list is globbed
  from localization/*.lua so a future locale file is covered without editing this spec.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each setup
-- luacheck: ignore 143

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
  Load a single locale file under stubbed globals and return its rggm.L key set as a set
  (key -> true). Restores the globals it touched afterwards so nothing leaks across loads.

  @param {table} file
    { path, locale }
  @return {table}
]]--
local function loadLocaleKeys(file)
  local restore = wowStubs.install({
    GetLocale = wowStubs.stubs.GetLocale(file.locale),
    C_AddOns  = wowStubs.stubs.C_AddOns({ Version = "0.0.0-test" })
  })

  rggm.L = nil
  dofile(file.path)

  local loaded = rggm.L
  rggm.L = nil
  restore()

  assert(
    type(loaded) == "table",
    file.path .. " did not populate rggm.L when GetLocale() == '" .. tostring(file.locale) .. "'"
  )

  local keys = {}
  for key in pairs(loaded) do
    keys[key] = true
  end

  return keys
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
  local localeKeys = {}

  setup(function()
    for _, file in ipairs(localeFiles) do
      localeKeys[file.locale] = loadLocaleKeys(file)
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

  for _, file in ipairs(localeFiles) do
    if file.locale ~= REFERENCE_LOCALE then
      it("locale " .. file.locale .. " has the same keys as " .. REFERENCE_LOCALE, function()
        local reference = localeKeys[REFERENCE_LOCALE]
        local locale = localeKeys[file.locale]

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
    end
  end
end)
