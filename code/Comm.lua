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

-- luacheck: read globals C_ChatInfo C_AddOns UnitName IsInGuild IsInGroup IsInRaid GetTime C_Timer
-- luacheck: read globals LE_PARTY_CATEGORY_HOME LE_PARTY_CATEGORY_INSTANCE

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

--[[
  Minimum time in seconds between two version broadcasts. GROUP_ROSTER_UPDATE fires
  in bursts while a group forms; the cooldown keeps the broadcasts well within the
  native throttle budget
]]--
local BROADCAST_COOLDOWN = 10

--[[
  The channels BroadcastVersion sends on. A version arriving on any other channel (a
  WHISPER from an arbitrary player) is not a broadcast and is ignored
]]--
local BROADCAST_CHANNELS = {
  ["GUILD"] = true,
  ["RAID"] = true,
  ["PARTY"] = true,
  ["INSTANCE_CHAT"] = true
}

-- upper bound for a received version string - "v999.999.999" is 12 characters
local MAX_VERSION_LENGTH = 16

-- time of the last version broadcast
local lastBroadcastTime = 0
-- whether a broadcast suppressed by the cooldown is scheduled to run once it elapsed
local broadcastPending = false
-- whether the scheduled broadcast has to include the guild
local pendingIncludesGuild = false
-- whether the update notice was already shown this session
local notifiedThisSession = false

--[[
  Send the version on one channel. A refused send (a channel the player is not in, the
  throttle) is only logged - the next roster edge broadcasts again

  @param {string} version
  @param {string} channel
]]--
local function SendOnChannel(version, channel)
  local result = C_ChatInfo.SendAddonMessage(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, version, channel)

  -- true (older clients) or 0 (Enum.SendAddonMessageResult.Success) mean the message was sent
  if result ~= nil and result ~= true and result ~= 0 then
    mod.logger.LogDebug(me.tag, "Version broadcast on " .. channel .. " was not sent: " .. tostring(result))
  end
end

--[[
  Send the running addon version over the guild (optionally) and the raid or party. Uses only
  the native per-prefix throttle, which a broadcast per BROADCAST_COOLDOWN never exhausts

  @param {boolean} includeGuild
]]--
local function SendVersion(includeGuild)
  local version = C_AddOns.GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")

  if version == nil then return end

  lastBroadcastTime = GetTime()

  if includeGuild and IsInGuild() then
    SendOnChannel(version, "GUILD")
  end

  --[[
    RAID / PARTY reach the player's own group only. Inside a battleground the instance group
    is separate and only INSTANCE_CHAT reaches it - a player queued with their party is in both
  ]]--
  if IsInRaid(LE_PARTY_CATEGORY_HOME) then
    SendOnChannel(version, "RAID")
  elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
    SendOnChannel(version, "PARTY")
  end

  if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
    SendOnChannel(version, "INSTANCE_CHAT")
  end
end

--[[
  Send the version now, or - within BROADCAST_COOLDOWN of the last broadcast - once the
  cooldown elapsed. A roster burst coalesces into a single trailing broadcast instead of being
  dropped, so a player joining right after another roster change still receives the version.
  The trailing broadcast includes the guild if any of the calls it stands in for did.

  @param {boolean} includeGuild
]]--
local function RequestBroadcast(includeGuild)
  local elapsed = GetTime() - lastBroadcastTime

  if not broadcastPending and elapsed >= BROADCAST_COOLDOWN then
    SendVersion(includeGuild)

    return
  end

  pendingIncludesGuild = pendingIncludesGuild or includeGuild

  if broadcastPending then return end

  mod.logger.LogDebug(me.tag, "Delaying version broadcast - cooldown active")
  broadcastPending = true

  C_Timer.After(BROADCAST_COOLDOWN - elapsed, function()
    local guild = pendingIncludesGuild

    broadcastPending = false
    pendingIncludesGuild = false
    SendVersion(guild)
  end)
end

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
  Broadcast the running addon version to guild and group members. Invoked on login and
  /reload only - the guild does not change with the group, so it is told once per session
]]--
function me.BroadcastVersion()
  RequestBroadcast(true)
end

--[[
  Broadcast the running addon version to the raid or party only. Invoked on roster edges
  (GROUP_ROSTER_UPDATE) and when zoning, where only the group may have new members
]]--
function me.BroadcastGroupVersion()
  RequestBroadcast(false)
end

--[[
  Reduce a received version to its canonical "vMAJOR.MINOR.PATCH" form. Anything else -
  a non-string, an oversized message, trailing or leading text - is rejected.

  @param {string} message
  @return {string | nil}
    the normalized version, or nil if the message is not a well-formed version
]]--
local function NormalizeVersion(message)
  if type(message) ~= "string" or #message > MAX_VERSION_LENGTH then return nil end

  local major, minor, patch = string.match(message, "^v?(%d+)%.(%d+)%.(%d+)$")

  if major == nil then return nil end

  return string.format("v%d.%d.%d", tonumber(major), tonumber(minor), tonumber(patch))
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
local function IsSelfSent(sender)
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
local function ShouldNotify(receivedVersion)
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

--[[
  Handle an incoming addon message. Foreign prefixes, messages outside the broadcast
  channels and self-sent messages are dropped. The message is untrusted input from
  another player: only a well-formed version is accepted, and only its normalized form
  is persisted and printed, so sender-controlled text never reaches the saved
  variables or the chat. A strictly newer version shows the localized update notice
  once per session and persists the announced version so relogs are not re-nagged.

  @param {string} prefix
  @param {string} message
    the version string of the sending player
  @param {string} channel
    the channel the message arrived on
  @param {string} sender
    sender name, realm-qualified for cross-realm players ("Name-Realm")
]]--
function me.OnChatMsgAddon(prefix, message, channel, sender)
  if prefix ~= RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX then return end
  if not BROADCAST_CHANNELS[channel] then return end
  if IsSelfSent(sender) then return end

  local version = NormalizeVersion(message)

  if version == nil or not ShouldNotify(version) then return end

  notifiedThisSession = true
  GearMenuConfiguration.lastNotifiedVersion = version
  mod.logger.PrintUserMessage(string.format(rggm.L["update_available"], version))
end
