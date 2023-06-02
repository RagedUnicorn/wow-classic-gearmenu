--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

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

-- luacheck: globals GetAddOnMetadata ChannelInfo C_Timer

rggm = rggm or {}
local me = rggm

me.tag = "Core"

local initializationDone = false

--[[
  Hook GetLocale to return a fixed value. This is used for testing only.
]]--

--[[
local _G = getfenv(0)

function _G.GetLocale()
  return "[language code]"
end
]]--

--[[
  Addon load

  @param {table} self
]]--
function me.OnLoad(self)
  me.RegisterEvents(self)
end

--[[
  Register addon events

  @param {table} self
]]--
function me.RegisterEvents(self)
  -- Fired when the player logs in, /reloads the UI, or zones between map instances
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  -- Fires when a bags inventory changes
  self:RegisterEvent("BAG_UPDATE")
  -- Fires when the player equips or unequips an item
  self:RegisterEvent("UNIT_INVENTORY_CHANGED")
  -- Fires when the player leaves combat status
  self:RegisterEvent("PLAYER_REGEN_ENABLED")
  -- Fires when the player enters combat status
  self:RegisterEvent("PLAYER_REGEN_DISABLED")
  -- Fires when a player resurrects after being in spirit form
  self:RegisterEvent("PLAYER_UNGHOST")
  -- Fires when the player's spirit is released after death or when the player accepts a resurrection without releasing
  self:RegisterEvent("PLAYER_ALIVE")
  -- Fires when a cooldown update call is sent to a bag
  self:RegisterEvent("BAG_UPDATE_COOLDOWN")
  -- Fires when the keybindings are changed.
  self:RegisterEvent("UPDATE_BINDINGS")
  -- Fires when a spell is cast successfully. Event is received even if spell is resisted.
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
  -- Fires when a unit's spellcast is interrupted
  self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
  -- Fires when the player is affected by some sort of control loss
  self:RegisterEvent("LOSS_OF_CONTROL_ADDED")
  -- Fires when the a loss of control is updated (or removed)
  self:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
  -- Register to the event that fires when the players target changes
  self:RegisterEvent("PLAYER_TARGET_CHANGED")
  -- Fired when a unit stops channeling
  self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
end

--[[
  MainFrame OnEvent handler

  @param {string} event
  @param {table} vararg
]]--
function me.OnEvent(event, ...)
  if event == "PLAYER_ENTERING_WORLD" then
    me.logger.LogEvent(me.tag, "PLAYER_ENTERING_WORLD")

    local isInitialLogin, isReloadingUi = ...

    if isInitialLogin or isReloadingUi then
      me.Initialize()
    end
  elseif event == "BAG_UPDATE" then
    me.logger.LogEvent(me.tag, "BAG_UPDATE")

    if initializationDone then
      -- trigger UpdateChangeMenu again to update items after an item was equipped
      if _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CHANGE_FRAME]:IsVisible() then
        me.gearBarChangeMenu.UpdateChangeMenu()
      end

      if me.configuration.IsTrinketMenuEnabled() then
        me.trinketMenu.UpdateTrinketMenu()
      end
    end
  elseif event == "UNIT_INVENTORY_CHANGED" then
    me.logger.LogEvent(me.tag, "UNIT_INVENTORY_CHANGED")
    local unit = ...

    if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER and initializationDone then
      me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarVisual)
      if me.configuration.IsTrinketMenuEnabled() then
        me.trinketMenu.UpdateTrinketMenu()
      end
    end
  elseif event == "BAG_UPDATE_COOLDOWN" then
    me.logger.LogEvent(me.tag, "BAG_UPDATE_COOLDOWN")

    if initializationDone then
      me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarGearSlotCooldowns)
      if me.configuration.IsTrinketMenuEnabled() then
        me.trinketMenu.UpdateTrinketMenuSlotCooldowns()
      end
    end
  elseif event == "UPDATE_BINDINGS" then
    me.logger.LogEvent(me.tag, "UPDATE_BINDINGS")

    --[[
      On starting up the addon often times GetBindingAction will not return the correct keybinding set but rather an
      empty string. To prevent this a slight delay is required.

      In case GetBindingAction returns an empty string GearMenu will loose the connection of its keybind. This means
      that GearMenu is unable to show the shortcuts in the GearBar anymore but the keybinds will continue to work.
    ]]--
    C_Timer.After(RGGM_CONSTANTS.KEYBIND_UPDATE_DELAY, me.keyBind.OnUpdateKeyBindings)
  elseif event == "LOSS_OF_CONTROL_ADDED" then
    me.logger.LogEvent(me.tag, "LOSS_OF_CONTROL_ADDED")

    if initializationDone then
      me.combatQueue.UpdateEquipChangeBlockStatus()
    end
  elseif event == "LOSS_OF_CONTROL_UPDATE" then
    me.logger.LogEvent(me.tag, "LOSS_OF_CONTROL_UPDATE")

    if initializationDone then
      me.combatQueue.UpdateEquipChangeBlockStatus()
    end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    me.logger.LogEvent(me.tag, "UNIT_SPELLCAST_SUCCEEDED")
    local unit = ...

    if initializationDone then
      local channelledSpell = ChannelInfo(RGGM_CONSTANTS.UNIT_ID_PLAYER)

      if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER and not channelledSpell then
        me.quickChange.OnUnitSpellCastSucceeded(...)
        me.combatQueue.ProcessQueue()
      end
    end
  elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
    me.logger.LogEvent(me.tag, "UNIT_SPELLCAST_INTERRUPTED")

    local unit = ...

    if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER and initializationDone then
      me.combatQueue.ProcessQueue()
    end
  elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
    me.logger.LogEvent(me.tag, "UNIT_SPELLCAST_CHANNEL_STOP")

    local unit = ...

    if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER and initializationDone then
      me.combatQueue.ProcessQueue()
    end
  elseif (event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE")
    and not me.common.IsPlayerReallyDead() then
      if event == "PLAYER_REGEN_ENABLED" then
        me.logger.LogEvent(me.tag, "PLAYER_REGEN_ENABLED")
      elseif event == "PLAYER_UNGHOST" then
        me.logger.LogEvent(me.tag, "PLAYER_UNGHOST")
      elseif event == "PLAYER_ALIVE" then
        me.logger.LogEvent(me.tag, "PLAYER_ALIVE")
      end

      if initializationDone then
        -- player is alive again or left combat - work through all combat queues
        me.ticker.StartTickerCombatQueue()
      end
  elseif event == "PLAYER_REGEN_DISABLED" then
    me.logger.LogEvent(me.tag, "PLAYER_REGEN_DISABLED")

    if initializationDone then
      me.ticker.StopTickerCombatQueue()
    end
  elseif event == "PLAYER_TARGET_CHANGED" then
    me.logger.LogEvent(me.tag, "PLAYER_TARGET_CHANGED")

    if initializationDone then
      me.target.UpdateCurrentTarget()
    end
  end
end

--[[
  Initialize addon
]]--
function me.Initialize()
  me.logger.LogDebug(me.tag, "Initialize addon")
  -- setup slash commands
  me.cmd.SetupSlashCmdList()
  -- load addon variables
  me.configuration.SetupConfiguration()
  -- setup addon configuration ui
  me.addonConfiguration.SetupAddonConfiguration()
  -- sync up theme (needs to be happening before accessing ui elements)
  me.themeCoordinator.UpdateTheme()
  -- build ui for all gearBars
  me.gearBar.BuildGearBars()
  -- build ui for changeMenu
  me.gearBarChangeMenu.BuildChangeMenu()
  -- update initial view of gearBars after addon initialization
  me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarVisual)

  if me.configuration.IsTrinketMenuEnabled() then
    -- build ui for trinketMenu
    me.trinketMenu.BuildTrinketMenu()
    -- update initial view of trinketMenu
    me.trinketMenu.UpdateTrinketMenu()
  end

  -- initialization is done
  initializationDone = true

  me.ShowWelcomeMessage()
end

--[[
  Show welcome message to user
]]--
function me.ShowWelcomeMessage()
  print(
    string.format("|cFF00FFB0" .. RGGM_CONSTANTS.ADDON_NAME .. rggm.L["help"],
    GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version"))
  )
end
