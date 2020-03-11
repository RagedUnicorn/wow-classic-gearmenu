--[[
  MIT License

  Copyright (c) 2020 Michael Wiesendanger

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

-- luacheck: globals GetAddOnMetadata

rggm = rggm or {}
local me = rggm

me.tag = "Core"

local initializationDone = false

--[[
  Testing
  Hook GetLocale to return a fixed value.
  Note: This is used for testing only. If the locale doesn't match with the actual
  locale of the combatlog the addon is unable to parse the log.
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
  -- Register to player login event also fires on /reload
  self:RegisterEvent("PLAYER_LOGIN")
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
end

--[[
  MainFrame OnEvent handler

  @param {string} event
  @param {table} vararg
]]--
function me.OnEvent(event, ...)
  if event == "PLAYER_LOGIN" then
    me.logger.LogEvent(me.tag, "PLAYER_LOGIN")
    me.Initialize()
  elseif event == "BAG_UPDATE" then
    me.logger.LogEvent(me.tag, "BAG_UPDATE")
    if initializationDone then
      me.gearBar.UpdateGearBarTextures()
      -- trigger UpdateChangeMenu again to update items after an item was equiped
      if _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CHANGE_FRAME]:IsVisible() then
        me.changeMenu.UpdateChangeMenu()
      end
    end
  elseif event == "UNIT_INVENTORY_CHANGED" then
    me.logger.LogEvent(me.tag, "UNIT_INVENTORY_CHANGED")
    if initializationDone then
      me.gearBar.UpdateGearBarTextures()
      me.gearBar.UpdateGearSlotCooldown()
    end
  elseif event == "BAG_UPDATE_COOLDOWN" then
    me.logger.LogEvent(me.tag, "BAG_UPDATE_COOLDOWN")
    if initializationDone then
      me.gearBar.UpdateGearSlotCooldown()
    end
  elseif event == "UPDATE_BINDINGS" then
    me.logger.LogEvent(me.tag, "UPDATE_BINDINGS")
    if initializationDone then
      me.gearBar.UpdateKeyBindings()
    end
  elseif event == "LOSS_OF_CONTROL_ADDED" then
    me.logger.LogEvent(me.tag, "LOSS_OF_CONTROL_ADDED")
    me.combatQueue.UpdateEquipChangeBlockStatus()
  elseif event == "LOSS_OF_CONTROL_UPDATE" then
    me.logger.LogEvent(me.tag, "LOSS_OF_CONTROL_UPDATE")
    me.combatQueue.UpdateEquipChangeBlockStatus()
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    me.logger.LogEvent(me.tag, "UNIT_SPELLCAST_SUCCEEDED")
    local unit = ...

    if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER then
      me.quickChange.OnUnitSpellCastSucceeded(...)
      me.combatQueue.ProcessQueue()
    end
  elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
    me.logger.LogEvent(me.tag, "UNIT_SPELLCAST_INTERRUPTED")
    local unit = ...

    if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER then
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
      -- player is alive again or left combat - work through all combat queues
      me.ticker.StartTickerCombatQueue()
  elseif event == "PLAYER_REGEN_DISABLED" then
    me.logger.LogEvent(me.tag, "PLAYER_REGEN_DISABLED")
    me.ticker.StopTickerCombatQueue()
  elseif event == "PLAYER_TARGET_CHANGED" then
    me.logger.LogEvent(me.tag, "PLAYER_TARGET_CHANGED")
    me.target.UpdateCurrentTarget()
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
  -- build ui for gearBar
  local gearBarFrame = me.gearBar.BuildGearBar()
  -- build ui for changeMenu
  me.changeMenu.BuildChangeMenu(gearBarFrame)
  -- start ticker intervals
  me.ticker.StartTickerSlotCooldown()
  -- Update initial view of cooldowns after addon initialization
  me.gearBar.UpdateGearSlotCooldown()
  -- start ticker range check
  if me.configuration.IsShowKeyBindingsEnabled() then
    me.ticker.StartTickerRangeCheck()
  end
  -- update initial view of gearBar after addon initialization
  me.gearBar.UpdateGearBar()

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
