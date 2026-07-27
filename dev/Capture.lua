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
  Development-only media capture. Loaded by the development .toc only - it must never
  ship in a release. Walks the generated RGGM_SHOTS manifest, sets the UI up for each
  shot, takes a screenshot and records the target frame's pixel rect so the
  post-process script can crop exactly instead of by eye.

  Static entries are driven by `shot <name>` / `shot all` / `shot next`. Entries marked
  kind = "gif" are ShareX recordings instead: `shot demo <name>` sets the UI up, prints
  the recording region and leaves the chrome hidden until `shot restore`.

  Registers a `shot` sub-command on the production command registry (code/Cmd.lua)
  without a help text key, so it never shows up in /rggm help.

  See the wow-media-capture skill for the full pipeline.
]]--

-- luacheck: globals C_Timer Screenshot SetCVar GetPhysicalScreenSize InCombatLockdown
-- luacheck: globals Settings SettingsPanel CreateFrame UIParent time
-- luacheck: globals GearMenuShotLog RGGM_SHOTS

local mod = rggm
local me = {}
mod.capture = me

me.tag = "Capture"

--[[
  Delay between setting the UI up and taking the screenshot. The frames need a moment
  to lay out - measuring too early yields a rect for the previous layout.
]]--
local SETTLE_DELAY = 0.5
--[[
  Delay before the UI chrome is restored. Must outlast SETTLE_DELAY so the chrome is
  still hidden when the screenshot is actually taken.
]]--
local RESTORE_DELAY = 1.0
--[[
  Spacing between shots in a `shot all` run.
]]--
local BATCH_INTERVAL = 2.5

--[[
  Default UI elements hidden for a clean capture. Guarded by existence - the set
  differs between Classic Era, TBC Anniversary and MoP Classic.
]]--
local CHROME = {
  -- the primary action buttons do not follow MainMenuBar:Hide() on this client
  "ActionButton1",
  "ActionButton2",
  "ActionButton3",
  "ActionButton4",
  "ActionButton5",
  "ActionButton6",
  "ActionButton7",
  "ActionButton8",
  "ActionButton9",
  "ActionButton10",
  "ActionButton11",
  "ActionButton12",
  "MainActionBar",
  "MainActionBar.ActionBarPageNumber",
  "ChatFrame1",
  "ChatFrame1Tab",
  "ChatFrame1ButtonFrame",
  "ChatFrame1EditBox",
  "GeneralDockManager",
  "MinimapCluster",
  "MainMenuBar",
  "MultiBarBottomLeft",
  "MultiBarBottomRight",
  "MultiBarLeft",
  "MultiBarRight",
  "MultiBar5",
  "MultiBar6",
  "MultiBar7",
  "StanceBar",
  "StanceBarFrame",
  "PetActionBar",
  "PetActionBarFrame",
  "PossessActionBar",
  -- the 1.15 client splits the micro menu, bag buttons and xp bar into own frames
  "MicroMenuContainer",
  "MicroButtonAndBagsBar",
  "BagsBar",
  "StatusTrackingBarManager",
  "PlayerFrame",
  "TargetFrame",
  "PetFrame",
  "PartyMemberFrame1",
  "PartyMemberFrame2",
  "PartyMemberFrame3",
  "PartyMemberFrame4",
  "BuffFrame",
  "DebuffFrame",
  "TicketStatusFrame"
}

-- frames hidden by the current shot, restored afterwards
local hidden = {}
-- cursor for the keybind-safe `shot next` driver
local cursor = 1
-- the entry of the last `demo`, so `hide` can apply its chrome/hide configuration
local lastDemoEntry

-- forward declarations
local FindShot
local IsShootable
local RunSetup
local HideChrome
local HideFrames
local RestoreChrome
local ResolveFrame
local MeasureFrame
local MeasureShotRect
local RecordShot
local TakeShot
local HandleShotCommand

--[[
  Setup verbs referenced by the manifest's capture.setup array. Keep this vocabulary
  small - add a verb only when a shot genuinely needs it.
]]--
local setupVerbs = {
  --[[
    Open a Settings subcategory. Settings.OpenToCategory requires the numeric category
    id - passing a name errors ("outside of expected range"). The AddOn exposes its ids
    via mod.addonConfiguration.GetCategoryId(key).
  ]]--
  ["openCategory"] = function(key)
    local id = mod.addonConfiguration.GetCategoryId(key)

    if id == nil then
      mod.logger.PrintUserError("Unknown category key: " .. tostring(key))
      return
    end

    Settings.OpenToCategory(id)
  end,

  --[[
    Open the first configured gearBar's own configuration sub-panel. The per-bar
    subcategories are created dynamically per gearBar, so their ids cannot be part of
    the static category-id accessor - they are resolved through the gearBar
    subcategory's children instead.
  ]]--
  ["openGearBarConfig"] = function()
    local gearBarSubCategory = mod.addonConfiguration.GetGearBarSubCategory()
    local subcategories = gearBarSubCategory and gearBarSubCategory.subcategories

    if subcategories == nil or subcategories[1] == nil then
      mod.logger.PrintUserError("No gearBar subcategory found - create a gearBar first")
      return
    end

    Settings.OpenToCategory(subcategories[1].ID)
  end,

  ["closeSettings"] = function()
    if SettingsPanel ~= nil then
      SettingsPanel:Hide()
    end
  end,

  ["showFrame"] = function(name)
    local frame = _G[name]

    if frame ~= nil then
      frame:Show()
    end
  end
}

--[[
  @param {string} name

  @return {table}, {number}
    The manifest entry and its index, or nil
]]--
FindShot = function(name)
  for i = 1, #RGGM_SHOTS do
    if RGGM_SHOTS[i].name == name or RGGM_SHOTS[i].shot == name then
      return RGGM_SHOTS[i], i
    end
  end

  return nil, nil
end

--[[
  Whether an entry is driven by the screenshot drivers. Gif entries are ShareX
  recordings - the `demo` driver supplies their region instead.

  @param {table} entry

  @return {boolean}
]]--
IsShootable = function(entry)
  return entry.kind ~= "gif"
end

--[[
  @param {table} entry
]]--
RunSetup = function(entry)
  for _, step in ipairs(entry.setup) do
    local verb, argument = string.match(step, "^(%w+):?(.*)$")
    local handler = setupVerbs[verb]

    if handler == nil then
      mod.logger.PrintUserError("Unknown setup verb: " .. tostring(verb))
    else
      handler(argument)
    end
  end
end

--[[
  Hide the default chrome for a clean capture. Frames named in keepFrames (the shot's
  capture.includeFrames) are spared so a shot can deliberately keep, e.g., the
  TrinketMenu next to the settings window.

  @param {table | nil} keepFrames
    Array of frame names to leave visible
]]--
HideChrome = function(keepFrames)
  local keep = {}

  if keepFrames ~= nil then
    for _, name in ipairs(keepFrames) do
      keep[name] = true
    end
  end

  for _, name in ipairs(CHROME) do
    if not keep[name] then
      local frame = ResolveFrame(name)

      if frame ~= nil and frame.IsShown ~= nil and frame:IsShown() then
        -- alpha 0 on top of Hide: the modern action bar controller re-Shows bars on
        -- state changes (stance, paging) mid-recording - the alpha keeps them invisible
        frame:SetAlpha(0)
        frame:Hide()
        table.insert(hidden, frame)
      end
    end
  end
end

RestoreChrome = function()
  for _, frame in ipairs(hidden) do
    frame:SetAlpha(1)
    frame:Show()
  end

  hidden = {}
end

--[[
  Hide specific frames named by the shot's capture.hideFrames, right before the
  screenshot and restored afterwards (queued onto the same `hidden` list as the
  chrome). Used to suppress a frame a setup step forces visible.

  @param {table | nil} names
    Array of frame names to hide
]]--
HideFrames = function(names)
  if names == nil then return end

  for _, name in ipairs(names) do
    local frame = ResolveFrame(name)

    if frame ~= nil and frame.IsShown ~= nil and frame:IsShown() then
      frame:SetAlpha(0)
      frame:Hide()
      table.insert(hidden, frame)
    end
  end
end

--[[
  Resolve a manifest frame name to a live frame. Gear-bar frame names embed the bar's
  persisted id (GM_GearBarFrame_<id>) and ids do not restart at 1 on a character that
  ever deleted a bar - so when no frame exists under the literal name,
  GM_GearBarFrame_<n> is treated positionally as the n-th configured gearBar.

  @param {string} name

  @return {table | nil}
    The frame or nil
]]--
ResolveFrame = function(name)
  local frame = _G[name]

  if frame ~= nil then
    return frame
  end

  --[[
    Dotted paths reach non-global children the retail-style UI stopped exposing as
    globals - e.g. MainMenuBar.ActionBarPageNumber (found via /fstack).
  ]]--
  if string.find(name, ".", 1, true) ~= nil then
    local current = _G

    for part in string.gmatch(name, "[^.]+") do
      current = current[part]

      if current == nil then
        return nil
      end
    end

    return current
  end

  local position = string.match(name, "^" .. RGGM_CONSTANTS.ELEMENT_GEAR_BAR_BASE_FRAME_NAME .. "(%d+)$")

  if position ~= nil then
    local gearBar = mod.gearBarManager.GetGearBars()[tonumber(position)]

    if gearBar ~= nil then
      return _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_BASE_FRAME_NAME .. gearBar.id]
    end
  end

  return nil
end

--[[
  Convert a frame's UI coordinates to screenshot pixel coordinates. Two conversions are
  needed:

    1. WoW UI coordinates live in a virtual space that is a fixed 768 units tall at
       scale 1.0 (UIParent:GetHeight() * UIParent:GetEffectiveScale() == 768),
       independent of the render resolution. A frame's GetLeft/GetTop/GetWidth/GetHeight
       are in that space, so UI units must be mapped up to real pixels via
       screenHeight / 768. Omitting this factor is the classic bug - crops come out
       ~2.6x too small and mispositioned.
    2. The UI origin is bottom-left while the screenshot's is top-left, so the y edge
       is flipped against screenHeight.

  @param {table} frame

  @return {number}, {number}, {number}, {number}, {number}, {number}
    x, y, width, height, screenWidth, screenHeight
]]--
MeasureFrame = function(frame)
  local screenWidth, screenHeight = GetPhysicalScreenSize()

  -- referenceHeight is 768; derived live rather than hardcoded so it survives any
  -- future change to WoW's virtual UI height
  local referenceHeight = UIParent:GetHeight() * UIParent:GetEffectiveScale()
  local uiToPixel = frame:GetEffectiveScale() * (screenHeight / referenceHeight)

  local x = frame:GetLeft() * uiToPixel
  local y = screenHeight - (frame:GetTop() * uiToPixel)
  local width = frame:GetWidth() * uiToPixel
  local height = frame:GetHeight() * uiToPixel

  return x, y, width, height, screenWidth, screenHeight
end

--[[
  Compute the crop rect for a shot: the primary frame's pixel rect, expanded to the
  union of any capture.includeFrames rects. This lets a shot capture a group - e.g. a
  gearBar together with its changeMenu - instead of a single frame. Include frames
  that are missing, hidden or unpositioned are skipped so the crop degrades to the
  primary frame.

  @param {table} entry
  @param {table} frame
    The primary (already validated) frame

  @return {number}, {number}, {number}, {number}, {number}, {number}
    x, y, width, height, screenWidth, screenHeight
]]--
MeasureShotRect = function(entry, frame)
  local x, y, width, height, screenWidth, screenHeight = MeasureFrame(frame)
  local left, top, right, bottom = x, y, x + width, y + height

  if entry.includeFrames ~= nil then
    for _, name in ipairs(entry.includeFrames) do
      local extra = ResolveFrame(name)

      if extra ~= nil and extra.GetLeft ~= nil and extra:GetLeft() ~= nil and extra:IsShown() then
        local ex, ey, ew, eh = MeasureFrame(extra)

        left = math.min(left, ex)
        top = math.min(top, ey)
        right = math.max(right, ex + ew)
        bottom = math.max(bottom, ey + eh)
      end
    end
  end

  return left, top, right - left, bottom - top, screenWidth, screenHeight
end

--[[
  Append a shot record to the SavedVariable. Written as a JSON string so the
  post-process script needs no Lua table parser.

  @param {table} entry
  @param {table} frame
]]--
RecordShot = function(entry, frame)
  if GearMenuShotLog == nil then
    GearMenuShotLog = {}
  end

  local x, y, width, height, screenWidth, screenHeight = MeasureShotRect(entry, frame)

  table.insert(GearMenuShotLog, string.format(
    '{"name":"%s","x":%d,"y":%d,"w":%d,"h":%d,"padding":%d,'
      .. '"uiScale":%.4f,"screenW":%d,"screenH":%d,"ts":%d}',
    entry.name,
    math.floor(x),
    math.floor(y),
    math.floor(width),
    math.floor(height),
    entry.padding,
    frame:GetEffectiveScale(),
    screenWidth,
    screenHeight,
    time()
  ))
end

--[[
  @param {table} entry
]]--
TakeShot = function(entry)
  if InCombatLockdown() then
    mod.logger.PrintUserError("Refusing to capture in combat - hiding protected frames would taint the UI")
    return
  end

  RunSetup(entry)

  C_Timer.After(SETTLE_DELAY, function()
    local frame = ResolveFrame(entry.frame)

    if frame == nil then
      mod.logger.PrintUserError("Frame not found: " .. entry.frame .. " (is it shown?)")
      return
    end

    if frame:GetLeft() == nil then
      mod.logger.PrintUserError("Frame has no position: " .. entry.frame .. " (it is probably hidden)")
      return
    end

    if entry.hideChrome then
      HideChrome(entry.includeFrames)
    end

    HideFrames(entry.hideFrames)

    RecordShot(entry, frame)
    Screenshot()

    print("|cFF00FFB0GearMenu:|r captured " .. entry.name)
  end)

  C_Timer.After(RESTORE_DELAY, RestoreChrome)
end

--[[
  Capture a single static shot by name. Gif entries are rejected - their region comes
  from the `demo` driver and ShareX does the recording.

  @param {string} name
]]--
function me.Shot(name)
  local entry = FindShot(name)

  if entry == nil then
    mod.logger.PrintUserError("Unknown shot: " .. tostring(name) .. " - try /rggm shot list")
    return
  end

  if not IsShootable(entry) then
    mod.logger.PrintUserError(entry.name .. " is a gif - use /rggm shot demo " .. entry.name)
    return
  end

  TakeShot(entry)
end

--[[
  Capture every static shot in the manifest, spaced far enough apart that each one
  settles. Gif entries are skipped. Requires Screenshot() to work from a timer
  callback - if it does not, use me.Next() bound to a key instead.
]]--
function me.ShotAll()
  me.Clear()

  local shootable = {}

  for i = 1, #RGGM_SHOTS do
    if IsShootable(RGGM_SHOTS[i]) then
      table.insert(shootable, RGGM_SHOTS[i])
    end
  end

  for i = 1, #shootable do
    C_Timer.After(BATCH_INTERVAL * (i - 1), function()
      TakeShot(shootable[i])
    end)
  end

  print("|cFF00FFB0GearMenu:|r capturing " .. #shootable .. " shot(s), /reload when done")
end

--[[
  Keybind-safe driver: capture the static shot at the cursor and advance. Use this when
  Screenshot() turns out to require a hardware event - and for shots that need the
  mouse to stay where it is, like a hovered changeMenu.
]]--
function me.Next()
  while cursor <= #RGGM_SHOTS and not IsShootable(RGGM_SHOTS[cursor]) do
    cursor = cursor + 1
  end

  if cursor > #RGGM_SHOTS then
    print("|cFF00FFB0GearMenu:|r all shots captured - /reload to flush the log")
    return
  end

  local entry = RGGM_SHOTS[cursor]
  cursor = cursor + 1

  print("|cFF00FFB0GearMenu:|r shot " .. (cursor - 1) .. "/" .. #RGGM_SHOTS .. " - " .. entry.name)
  TakeShot(entry)
end

--[[
  Capture a static shot after a delay - for scenes the mouse has to hold open when the
  screenshot fires, like a hovered changeMenu: type the command, then hover until the
  shot announces itself.

  @param {number} delay
    Seconds before the shot is set up and taken
  @param {string} name
]]--
function me.ShotIn(delay, name)
  if type(delay) ~= "number" or delay <= 0 then
    mod.logger.PrintUserError("Usage: /rggm shot in <seconds> <name>")
    return
  end

  local entry = FindShot(name)

  if entry == nil then
    mod.logger.PrintUserError("Unknown shot: " .. tostring(name) .. " - try /rggm shot list")
    return
  end

  if not IsShootable(entry) then
    mod.logger.PrintUserError(entry.name .. " is a gif - use /rggm shot demo " .. entry.name)
    return
  end

  print("|cFF00FFB0GearMenu:|r capturing " .. entry.name .. " in " .. delay .. "s - set up the scene now")

  C_Timer.After(delay, function()
    TakeShot(entry)
  end)
end

--[[
  Set the UI up for a gif recording and print the recording region for ShareX. The
  chrome stays VISIBLE so the printed region is readable in chat - hide it with
  `/rggm shot hide` right before recording (chrome does not affect the measured
  geometry). Unlike static shots nothing is written to the shot log, so a demo cannot
  break the post-process pairing.

  The optional delay postpones the measurement so hover-driven frames can be held open
  when it happens - a shown includeFrames member (the changeMenu) is unioned into the
  printed region, while a hidden one is skipped. With many eligible items the changeMenu
  is far taller than the bar, so measure it open: /rggm shot demo switch_items 4, hover.

  @param {string} name
  @param {string | nil} delay
    Optional seconds before the region is measured
]]--
function me.Demo(name, delay)
  local entry = FindShot(name)

  if entry == nil then
    mod.logger.PrintUserError("Unknown shot: " .. tostring(name) .. " - try /rggm shot list")
    return
  end

  delay = tonumber(delay) or SETTLE_DELAY

  RunSetup(entry)

  if delay > SETTLE_DELAY then
    print("|cFF00FFB0GearMenu:|r measuring " .. entry.name .. " in " .. delay
      .. "s - hover now if the shot includes the changeMenu")
  end

  C_Timer.After(delay, function()
    local frame = ResolveFrame(entry.frame)

    if frame == nil or frame:GetLeft() == nil then
      mod.logger.PrintUserError("Frame not found or hidden: " .. entry.frame)
      return
    end

    lastDemoEntry = entry

    -- unlike static shots the padding is applied here: the printed rect is what the
    -- user types into the ShareX region, so it must be final and clamped to the screen
    local x, y, width, height, screenWidth, screenHeight = MeasureShotRect(entry, frame)
    local padding = entry.padding or 0
    local left = math.max(0, math.floor(x) - padding)
    local top = math.max(0, math.floor(y) - padding)
    local right = math.min(screenWidth, math.floor(x + width) + padding)
    local bottom = math.min(screenHeight, math.floor(y + height) + padding)

    print(string.format(
      "|cFF00FFB0GearMenu:|r demo region for %s: X=%d Y=%d W=%d H=%d (screen %dx%d)",
      entry.name, left, top, right - left, bottom - top, screenWidth, screenHeight
    ))
    print("|cFF00FFB0GearMenu:|r set the ShareX region, then /rggm shot hide - record - /rggm shot restore")
  end)
end

--[[
  Hide the chrome for the recording of the last `demo` (falls back to the plain chrome
  set when no demo ran). Kept separate from me.Demo so the printed region stays
  readable in chat until the user is ready to record.
]]--
function me.Hide()
  if InCombatLockdown() then
    mod.logger.PrintUserError("Refusing to hide frames in combat - it would taint the UI")
    return
  end

  if lastDemoEntry ~= nil then
    if lastDemoEntry.hideChrome then
      HideChrome(lastDemoEntry.includeFrames)
    end

    HideFrames(lastDemoEntry.hideFrames)
  else
    HideChrome(nil)
  end

  print("|cFF00FFB0GearMenu:|r chrome hidden - record now, then /rggm shot restore")
end

--[[
  Restore the chrome a `hide` left hidden.
]]--
function me.Restore()
  RestoreChrome()
  print("|cFF00FFB0GearMenu:|r chrome restored")
end

--[[
  Reset the shot log and the cursor. The post-process script pairs log records with the
  newest screenshot files, so a stale log breaks the pairing.
]]--
function me.Clear()
  GearMenuShotLog = {}
  cursor = 1
end

--[[
  Print the manifest.
]]--
function me.List()
  print("|cFF00FFB0GearMenu:|r " .. #RGGM_SHOTS .. " shot(s)")

  for i = 1, #RGGM_SHOTS do
    local entry = RGGM_SHOTS[i]
    local marker = IsShootable(entry) and "" or " |cFFFF6060(gif)|r"

    print("  |cFFFFC300" .. entry.name .. "|r" .. marker .. " - " .. entry.shows .. " (" .. entry.frame .. ")")
  end
end

--[[
  Handle the `shot` sub-command of /rggm. Receives the remaining arguments from the
  command registry, the sub-command name already removed.

  @param {table} args
]]--
HandleShotCommand = function(args)
  if args[1] == nil or args[1] == "help" then
    print("|cFF00FFB0GearMenu:|r media capture (development only)")
    print("  |cFFFFC300list|r - show the shot manifest")
    print("  |cFFFFC300all|r - capture every static shot")
    print("  |cFFFFC300next|r - capture the next static shot (bind this if `all` does not work)")
    print("  |cFFFFC300in <seconds> <name>|r - capture a static shot after a delay (hover time)")
    print("  |cFFFFC300demo <name> [seconds]|r - set up a gif recording and print its region"
      .. " (delay to hover the changeMenu open first)")
    print("  |cFFFFC300hide|r - hide the chrome right before recording")
    print("  |cFFFFC300restore|r - restore the chrome after a recording")
    print("  |cFFFFC300clear|r - reset the shot log")
    print("  |cFFFFC300<name>|r - capture a single static shot")
  elseif args[1] == "list" then
    me.List()
  elseif args[1] == "all" then
    me.ShotAll()
  elseif args[1] == "next" then
    me.Next()
  elseif args[1] == "in" then
    me.ShotIn(tonumber(args[2]), args[3])
  elseif args[1] == "demo" then
    me.Demo(args[2], args[3])
  elseif args[1] == "hide" then
    me.Hide()
  elseif args[1] == "restore" then
    me.Restore()
  elseif args[1] == "clear" then
    me.Clear()
    print("|cFF00FFB0GearMenu:|r shot log cleared")
  else
    me.Shot(args[1])
  end
end

--[[
  The dev module cannot hook into code/Core.lua's initialization without touching a
  production file, so it drives its own PLAYER_LOGIN setup.
]]--
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
  --[[
    Screenshots default to JPEG, which is lossy on UI panels. PNG is the right format
    for media that ends up in a README.
  ]]--
  SetCVar("screenshotFormat", "png")
  -- no helpTextKey - the dev-only command must not show up in /rggm help
  mod.cmd.RegisterCommand("shot", HandleShotCommand)
end)
