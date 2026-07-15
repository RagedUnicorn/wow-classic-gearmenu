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

-- luacheck: globals C_ChatInfo C_AddOns UnitName IsInGuild IsInGroup IsInRaid GetTime

local mod = rggm
local me = {}
mod.comm = me

me.tag = "Comm"

--[[
  Version broadcast and update notice. Every client broadcasts its running version
  over the addon message channel on login and roster edges; when a strictly newer
  version is seen from another player the localized update notice is shown once.
  Uses only the native per-prefix throttle (10 message burst, +1/sec refill) - no
  third-party comm library.
]]--

-- forward declarations
local IsSelfSent
local ShouldNotify

--[[
  Minimum time in seconds between two version broadcasts. GROUP_ROSTER_UPDATE fires
  in bursts while a group forms; the cooldown keeps the broadcasts well within the
  native throttle budget
]]--
local BROADCAST_COOLDOWN = 10

-- time of the last version broadcast
local lastBroadcastTime = 0
-- whether the update notice was already shown this session
local notifiedThisSession = false

--[[
  Register the addon message prefix so the client delivers version broadcasts from
  other players via CHAT_MSG_ADDON
]]--
function me.Initialize()
  C_ChatInfo.RegisterAddonMessagePrefix(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX)
  mod.logger.LogDebug(me.tag,
    "Registered addon message prefix " .. RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX)
end

--[[
  Broadcast the running addon version to guild and group members. Invoked on
  roster edges only (PLAYER_ENTERING_WORLD and GROUP_ROSTER_UPDATE), never in a
  loop, so the native throttle is never exhausted
]]--
function me.BroadcastVersion()
  local version = C_AddOns.GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")

  if version == nil then return end

  if GetTime() - lastBroadcastTime < BROADCAST_COOLDOWN then
    mod.logger.LogDebug(me.tag, "Skipping version broadcast - cooldown active")

    return
  end

  lastBroadcastTime = GetTime()

  if IsInGuild() then
    C_ChatInfo.SendAddonMessage(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, version, "GUILD")
  end

  if IsInRaid() then
    C_ChatInfo.SendAddonMessage(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, version, "RAID")
  elseif IsInGroup() then
    C_ChatInfo.SendAddonMessage(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, version, "PARTY")
  end
end

--[[
  Handle an incoming addon message. Foreign prefixes and self-sent messages are
  dropped; a strictly newer version shows the localized update notice once per
  session and persists the announced version so relogs are not re-nagged.

  @param {string} prefix
  @param {string} message
    the version string of the sending player
  @param {string} _
    the channel the message arrived on (unused)
  @param {string} sender
    sender name, realm-qualified for cross-realm players ("Name-Realm")
]]--
function me.OnChatMsgAddon(prefix, message, _, sender)
  if prefix ~= RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX then return end
  if IsSelfSent(sender) then return end
  if not ShouldNotify(message) then return end

  notifiedThisSession = true
  GearMenuConfiguration.lastNotifiedVersion = message
  mod.logger.PrintUserMessage(string.format(rggm.L["update_available"], message))
end

--[[
  Whether an addon message was sent by the player themself. Defense-in-depth -
  the player's own version is never strictly newer than itself.

  @param {string} sender
    sender name, possibly realm-qualified ("Name-Realm")
  @return {boolean}
    true - if the sender is the player
    false - otherwise
]]--
IsSelfSent = function(sender)
  return string.match(sender or "", "^([^-]+)") == UnitName("player")
end

--[[
  Whether a received version warrants the update notice: strictly newer than the
  running version, not yet announced this session and newer than the persisted
  lastNotifiedVersion.

  @param {string} receivedVersion
  @return {boolean}
    true - if the update notice should be shown
    false - otherwise
]]--
ShouldNotify = function(receivedVersion)
  if notifiedThisSession then return false end

  local version = C_AddOns.GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")

  if not mod.configuration.IsVersionBefore(version, receivedVersion) then return false end

  --[[
    An empty lastNotifiedVersion means nothing was announced yet. IsVersionBefore
    treats an unparseable version as "not before", which would otherwise suppress
    the very first notice
  ]]--
  local lastNotifiedVersion = GearMenuConfiguration.lastNotifiedVersion

  if lastNotifiedVersion ~= nil and lastNotifiedVersion ~= ""
      and not mod.configuration.IsVersionBefore(lastNotifiedVersion, receivedVersion) then
    return false
  end

  return true
end
