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

-- luacheck: globals C_AddOns UnitChannelInfo C_Timer

rggm = rggm or {}
local me = rggm

me.tag = "Core"

-- Forward declarations
local OnPlayerEnteringWorld
local OnBagUpdate
local OnItemLockChanged
local OnPlayerEquipmentChanged
local OnUnitInventoryChanged
local OnBagUpdateCooldown
local OnUpdateBindings
local OnLossOfControl
local OnUnitSpellCastSucceeded
local OnUnitSpellCastStop
local OnPlayerAliveOrLeftCombat
local OnPlayerRegenDisabled
local OnPlayerTargetChanged
local Initialize
local ShowWelcomeMessage

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
  Run the bootstrap sequence on initial login or ui reload, then mark the event
  bus ready so gated handlers begin firing.

  @param {boolean} isInitialLogin
  @param {boolean} isReloadingUi
]]--
OnPlayerEnteringWorld = function(isInitialLogin, isReloadingUi)
  if isInitialLogin or isReloadingUi then
    Initialize()
    me.event.SetReady()
  end

  me.comm.BroadcastVersion()
end

--[[
  Invalidate the item location cache and request a debounced bag update when a bags
  inventory changes.
]]--
OnBagUpdate = function()
  me.itemLocationCache.Invalidate()
  me.itemManager.RequestBagUpdate()
end

--[[
  Invalidate the item location cache when an item is locked or unlocked. The event fires
  while items are picked up and placed, i.e. whenever bag contents are about to change.
]]--
OnItemLockChanged = function()
  me.itemLocationCache.Invalidate()
end

--[[
  Update the gearBar visuals when the player equips or unequips an item.
]]--
OnPlayerEquipmentChanged = function()
  me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarVisual)
end

--[[
  Update the gearBar visuals when the player's inventory changes.

  @param {string} unit
]]--
OnUnitInventoryChanged = function(unit)
  if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER then
    me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarVisual)
  end
end

--[[
  Update gearSlot and trinketMenu cooldowns when a cooldown update call is sent to a bag.
]]--
OnBagUpdateCooldown = function()
  me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarGearSlotCooldowns)

  if me.configuration.IsTrinketMenuEnabled() then
    me.trinketMenu.UpdateTrinketMenuSlotCooldowns()
  end
end

--[[
  Update the displayed keybindings when the keybindings are changed.
]]--
OnUpdateBindings = function()
  --[[
    On starting up the addon often times GetBindingAction will not return the correct keybinding set but rather an
    empty string. To prevent this a slight delay is required.
  ]]--
  C_Timer.After(RGGM_CONSTANTS.KEYBIND_UPDATE_DELAY, me.keyBind.OnUpdateKeyBindings)
end

--[[
  Update the equip change block status when a loss of control is added, updated or removed.
]]--
OnLossOfControl = function()
  me.combatQueue.UpdateEquipChangeBlockStatus()
end

--[[
  Process quickChange rules and the combat queue after a successful spellcast of the
  player. Channelled spells are skipped - the queue is processed once the channel stops.

  @param {vararg} ...
]]--
OnUnitSpellCastSucceeded = function(...)
  local unit = ...

  if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER then
    local channelledSpell = UnitChannelInfo(RGGM_CONSTANTS.UNIT_ID_PLAYER)

    if not channelledSpell then
      me.quickChange.OnUnitSpellCastSucceeded(...)
      me.combatQueue.ProcessQueue()
    end
  end
end

--[[
  Process the combat queue when the player's spellcast is interrupted or the
  player stops channeling.

  @param {string} unit
]]--
OnUnitSpellCastStop = function(unit)
  if unit == RGGM_CONSTANTS.UNIT_ID_PLAYER then
    me.combatQueue.ProcessQueue()
  end
end

--[[
  Player is alive again or left combat - work through all combat queues.
]]--
OnPlayerAliveOrLeftCombat = function()
  if not me.common.IsPlayerReallyDead() then
    me.ticker.StartTickerCombatQueue()
  end
end

--[[
  Stop the combat queue ticker when the player enters combat status.
]]--
OnPlayerRegenDisabled = function()
  me.ticker.StopTickerCombatQueue()
end

--[[
  Update the tracked target when the player's target changes.
]]--
OnPlayerTargetChanged = function()
  me.target.UpdateCurrentTarget()
end

--[[
  Addon load

  @param {table} self
]]--
function me.OnLoad(self)
  -- Fired when the player logs in, /reloads the UI, or zones between map instances
  me.event.Register("PLAYER_ENTERING_WORLD", OnPlayerEnteringWorld)
  -- Fires when a bags inventory changes
  me.event.Register("BAG_UPDATE", OnBagUpdate, { gated = true })
  -- Fires when an item gets locked or unlocked while items are moved around
  me.event.Register("ITEM_LOCK_CHANGED", OnItemLockChanged, { gated = true })
  --[[
    Fires when the player equips or unequips an item
    This is already filtered for the player only and seems to work better than UNIT_INVENTORY_CHANGED
    UNIT_INVENTORY_CHANGED does not fire when equipping between items that have the same id but might
    have different enchantments or rune engravings
  ]]--
  me.event.Register("PLAYER_EQUIPMENT_CHANGED", OnPlayerEquipmentChanged, { gated = true })
  -- Fires when the player equips or unequips an item this is used as fallback during initial login of the player
  me.event.Register(
    "UNIT_INVENTORY_CHANGED",
    OnUnitInventoryChanged,
    { gated = true, unit = RGGM_CONSTANTS.UNIT_ID_PLAYER }
  )
  -- Fires when a cooldown update call is sent to a bag
  me.event.Register("BAG_UPDATE_COOLDOWN", OnBagUpdateCooldown, { gated = true })
  -- Fires when the keybindings are changed.
  me.event.Register("UPDATE_BINDINGS", OnUpdateBindings)
  -- Fires when the player is affected by some sort of control loss and when it is updated (or removed)
  me.event.Register(
    { "LOSS_OF_CONTROL_ADDED", "LOSS_OF_CONTROL_UPDATE" },
    OnLossOfControl,
    { gated = true }
  )
  -- Fires when a spell is cast successfully. Event is received even if spell is resisted.
  me.event.Register(
    "UNIT_SPELLCAST_SUCCEEDED",
    OnUnitSpellCastSucceeded,
    { gated = true, unit = RGGM_CONSTANTS.UNIT_ID_PLAYER }
  )
  -- Fires when a unit's spellcast is interrupted and when a unit stops channeling
  me.event.Register(
    { "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_STOP" },
    OnUnitSpellCastStop,
    { gated = true, unit = RGGM_CONSTANTS.UNIT_ID_PLAYER }
  )
  --[[
    Fires when the player leaves combat status, when a player resurrects after being in spirit form
    and when the player's spirit is released after death or when the player accepts a resurrection
    without releasing
  ]]--
  me.event.Register(
    { "PLAYER_REGEN_ENABLED", "PLAYER_UNGHOST", "PLAYER_ALIVE" },
    OnPlayerAliveOrLeftCombat,
    { gated = true }
  )
  -- Fires when the player enters combat status
  me.event.Register("PLAYER_REGEN_DISABLED", OnPlayerRegenDisabled, { gated = true })
  -- Register to the event that fires when the players target changes
  me.event.Register("PLAYER_TARGET_CHANGED", OnPlayerTargetChanged, { gated = true })
  -- Fires when another addon client sends a message over the addon message channel
  me.event.Register("CHAT_MSG_ADDON", me.comm.OnChatMsgAddon, { gated = true })
  -- Fires when the group or raid composition changes
  me.event.Register("GROUP_ROSTER_UPDATE", me.comm.BroadcastVersion, { gated = true })

  me.event.Setup(self)
end

--[[
  MainFrame OnEvent handler. Delegates to the event bus for dispatch.

  @param {string} event
  @param {vararg} ...
]]--
function me.OnEvent(event, ...)
  me.event.Dispatch(event, ...)
end

--[[
  Initialize addon
]]--
Initialize = function()
  me.logger.LogDebug(me.tag, "Initialize addon")
  -- update runes
  me.engrave.RefreshRunes()
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

  me.gearBar.UpdateGearBars(me.gearBar.UpdateGearBarVisual)
  me.keyBind.OnUpdateKeyBindings()
  -- register addon message prefix for the version broadcast
  me.comm.Initialize()
  ShowWelcomeMessage()
end

--[[
  Show welcome message to user
]]--
ShowWelcomeMessage = function()
  print(
    string.format("|cFF00FFB0" .. RGGM_CONSTANTS.ADDON_NAME .. rggm.L["help"],
    C_AddOns.GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version"))
  )
end
