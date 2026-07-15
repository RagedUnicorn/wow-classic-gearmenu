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
  Spec for the version broadcast and update notice (code/Comm.lua).

  The module broadcasts the running version over GUILD/RAID/PARTY on roster edges (with a
  cooldown so GROUP_ROSTER_UPDATE bursts stay within the native per-prefix throttle) and, on
  CHAT_MSG_ADDON, shows the localized update notice once per session when a strictly newer
  version is seen from another player, persisting it in GearMenuConfiguration.lastNotifiedVersion.

  The WoW surface (C_ChatInfo, C_AddOns, UnitName, group/guild predicates, GetTime) is stubbed
  via WowStubs; the notice itself is captured through a recorder rggm.logger. The real
  code/Configuration.lua is dofile'd for the SemVer comparator (me.IsVersionBefore) Comm reuses --
  that replaces the bootstrap's no-op rggm.configuration, so it is restored in after_each.
  Re-dofile'ing code/Comm.lua in before_each resets its file-local state (broadcast cooldown,
  notified-this-session flag) per the isolation mechanism documented in test/headless/Bootstrap.lua.

  GearMenuConfiguration is the saved-variables global the module reads and mutates. busted runs
  each spec chunk in a sandboxed environment, so a bareword assignment would land in the sandbox
  rather than the _G the dofile'd module sees -- fixtures are therefore installed via the useConfig
  helper (which writes _G.GearMenuConfiguration) and assertions run against the returned handle.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck cannot verify those
-- fields statically. Suppress warning 143 (accessing undefined field of a global variable).
-- luacheck: globals describe it before_each after_each rggm RGGM_CONSTANTS
-- luacheck: ignore 143

local wowStubs = require("WowStubs")

--[[
  Install a saved-variables fixture as the global and return it for assertions.

  @param {table} config
  @return {table}
]]--
local function useConfig(config)
  _G.GearMenuConfiguration = config
  return config
end

describe("Comm", function()
  local comm
  local config
  local restore
  local previousModules
  local previousConfig
  -- captured C_ChatInfo traffic and update notices
  local registeredPrefixes
  local sentMessages
  local notices
  -- controllable stub state
  local now
  local inGuild
  local inRaid
  local inGroup

  before_each(function()
    registeredPrefixes = {}
    sentMessages = {}
    notices = {}
    now = 1000
    inGuild = false
    inRaid = false
    inGroup = false

    previousModules = {
      logger = rggm.logger,
      configuration = rggm.configuration,
      comm = rggm.comm,
      L = rggm.L
    }
    previousConfig = _G.GearMenuConfiguration

    -- silence the configuration module's logging and capture the user facing notice
    rggm.logger = {
      LogDebug = function() end,
      LogInfo = function() end,
      LogError = function() end,
      PrintUserMessage = function(msg) notices[#notices + 1] = msg end
    }
    rggm.L = { update_available = "New version %s is available" }

    restore = wowStubs.install({
      C_AddOns = wowStubs.stubs.C_AddOns({ Version = "v2.7.0" }),
      C_ChatInfo = {
        RegisterAddonMessagePrefix = function(prefix)
          registeredPrefixes[#registeredPrefixes + 1] = prefix
        end,
        SendAddonMessage = function(prefix, message, channel)
          sentMessages[#sentMessages + 1] = { prefix = prefix, message = message, channel = channel }
        end
      },
      UnitName = function() return "Selfplayer" end,
      IsInGuild = function() return inGuild end,
      IsInRaid = function() return inRaid end,
      IsInGroup = function() return inGroup end,
      GetTime = function() return now end
    })

    -- the real comparator (rggm.configuration.IsVersionBefore) replacing the bootstrap no-op
    dofile("code/Configuration.lua")
    -- fresh file-local state (broadcast cooldown, notified-this-session flag)
    dofile("code/Comm.lua")
    comm = rggm.comm

    -- firstTimeInitializationDone keeps SetAddonVersion from running FirstTimeInitialization
    -- (its gearBarManager collaborators are not stubbed); the defaults-backfill then seeds
    -- lastNotifiedVersion = ""
    config = useConfig({ firstTimeInitializationDone = true })
    rggm.configuration.SetupConfiguration()
  end)

  after_each(function()
    restore()
    rggm.logger = previousModules.logger
    rggm.configuration = previousModules.configuration
    rggm.comm = previousModules.comm
    rggm.L = previousModules.L
    _G.GearMenuConfiguration = previousConfig
  end)

  describe("Initialize", function()
    it("registers the addon message prefix", function()
      comm.Initialize()

      assert.are.same({ RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX }, registeredPrefixes)
    end)
  end)

  describe("BroadcastVersion", function()
    it("broadcasts over GUILD and RAID when in a guild and a raid", function()
      inGuild = true
      inRaid = true

      comm.BroadcastVersion()

      assert.are.equal(2, #sentMessages)
      assert.are.same(
        { prefix = RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, message = "v2.7.0", channel = "GUILD" },
        sentMessages[1]
      )
      assert.are.same(
        { prefix = RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, message = "v2.7.0", channel = "RAID" },
        sentMessages[2]
      )
    end)

    it("broadcasts over GUILD and PARTY when in a guild and a party", function()
      inGuild = true
      inGroup = true

      comm.BroadcastVersion()

      assert.are.equal(2, #sentMessages)
      assert.are.equal("GUILD", sentMessages[1].channel)
      assert.are.equal("PARTY", sentMessages[2].channel)
    end)

    it("broadcasts nothing when solo and unguilded", function()
      comm.BroadcastVersion()

      assert.are.same({}, sentMessages)
    end)

    it("skips a broadcast within the cooldown and sends again after it elapsed", function()
      inGuild = true

      comm.BroadcastVersion()
      assert.are.equal(1, #sentMessages)

      -- a roster burst right after the first broadcast is swallowed by the cooldown
      comm.BroadcastVersion()
      assert.are.equal(1, #sentMessages)

      now = now + 60
      comm.BroadcastVersion()
      assert.are.equal(2, #sentMessages)
    end)
  end)

  describe("OnChatMsgAddon", function()
    it("notifies once for a strictly newer version and persists it", function()
      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.8.0", "GUILD", "Otherplayer")

      assert.are.same({ "New version v2.8.0 is available" }, notices)
      assert.are.equal("v2.8.0", config.lastNotifiedVersion)

      -- even a newer version stays silent for the rest of the session
      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.9.0", "GUILD", "Otherplayer")

      assert.are.equal(1, #notices)
    end)

    it("does not suppress the very first notice on the empty string default", function()
      assert.are.equal("", config.lastNotifiedVersion)

      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.7.1", "PARTY", "Otherplayer")

      assert.are.equal(1, #notices)
    end)

    it("ignores an equal version", function()
      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.7.0", "GUILD", "Otherplayer")

      assert.are.same({}, notices)
    end)

    it("ignores an older version", function()
      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.6.9", "GUILD", "Otherplayer")

      assert.are.same({}, notices)
    end)

    it("ignores a foreign prefix", function()
      comm.OnChatMsgAddon("SOME_OTHER_ADDON", "v9.9.9", "GUILD", "Otherplayer")

      assert.are.same({}, notices)
    end)

    it("ignores self-sent messages, realm-qualified or not", function()
      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.8.0", "GUILD", "Selfplayer")
      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.8.0", "GUILD", "Selfplayer-SomeRealm")

      assert.are.same({}, notices)
    end)

    it("does not re-nag after a reload for a version already announced", function()
      config.lastNotifiedVersion = "v2.8.0"

      -- simulate a /reload: fresh file-local session state, persisted saved variables
      dofile("code/Comm.lua")
      comm = rggm.comm

      -- the announced version and anything older than it stay silent
      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.8.0", "GUILD", "Otherplayer")
      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.7.5", "GUILD", "Otherplayer")
      assert.are.same({}, notices)

      -- a version newer than the announced one notifies again
      comm.OnChatMsgAddon(RGGM_CONSTANTS.ADDON_MESSAGE_PREFIX, "v2.9.0", "GUILD", "Otherplayer")
      assert.are.same({ "New version v2.9.0 is available" }, notices)
    end)
  end)

  describe("IsVersionBefore", function()
    it("compares major, minor and patch numerically", function()
      assert.is_true(rggm.configuration.IsVersionBefore("v2.7.0", "v2.7.1"))
      assert.is_true(rggm.configuration.IsVersionBefore("v2.7.9", "v2.10.0"))
      assert.is_true(rggm.configuration.IsVersionBefore("v2.9.9", "v10.0.0"))
      assert.is_false(rggm.configuration.IsVersionBefore("v2.7.0", "v2.7.0"))
      assert.is_false(rggm.configuration.IsVersionBefore("v2.8.0", "v2.7.9"))
    end)

    it("accepts versions with and without the leading v", function()
      assert.is_true(rggm.configuration.IsVersionBefore("2.7.0", "v2.8.0"))
      assert.is_true(rggm.configuration.IsVersionBefore("v2.7.0", "2.8.0"))
    end)

    it("treats an unparseable version on either side as not before", function()
      assert.is_false(rggm.configuration.IsVersionBefore(nil, "v2.8.0"))
      assert.is_false(rggm.configuration.IsVersionBefore("garbage", "v2.8.0"))
      assert.is_false(rggm.configuration.IsVersionBefore("v2.7.0", "garbage"))
    end)
  end)
end)
