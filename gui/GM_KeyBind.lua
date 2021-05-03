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

-- luacheck: globals StaticPopupDialogs StaticPopup_Show SetBindingClick STANDARD_TEXT_FONT
-- luacheck: globals GetBindingAction SetBinding GetCurrentBindingSet AttemptToSaveBindings
-- luacheck: globals StaticPopup_Hide

--[[
  The keyBind (GM_KeyBind) is responsible for recording and setting keyBindings to gearSlots
  on the gearBar.

  Note that a keyBind belongs to exactly one button even if a user decides to use the same gearSlot
  on multiple gearBars

  KeyBinding rules:
  - A keyBinding can consist of multiple keys
  - Keys need to be combined with "-"
  - Keybindings differentiate between normale keys and modifiers
    Modifiers:
    - A keyBinding can have the following modifiers RGGM_CONSTANTS.MODIFIER_KEYS
    - A keyBinding can have multiple modifiers but not the same one multiple times
      CTRL-CTRL-T (invalid)
      CTRL-SHIFT-T (valid)
      `lastRecordedKey` takes care of that
    - Modifiers need to be mapped to their actual value in a keyBinding text RGGM_CONSTANTS.MODIFIER_KEY_MAPPING
    Normal Keys:
    - Once a normal key was added to a keyBinding text it cannot be followed by
      a modifier `prohibitModifier` takes care of that

  Examples:
    T (valid)
    CTRL-T (valid)
    CTRL-SHIFT-T (valid)

    CTRL (invalid)
    CTRL-CTRL (invalid)
    CTRL-CTRL-T (invalid)
    T-CTRL (invalid)
]]--

local mod = rggm
local me = {}
mod.keyBind = me

me.tag = "KeyBind"

--[[
  Whether the keyBinding is considered a valid one or not. Accept button to save
  the keyBinding is only enabled after the keyBinding is considered valid.
]]--
local isKeyBindingValid = false
--[[
  The keyBinding that was recorded so far
]]--
local recordedKeyBinding = ""
--[[
  Track if modifiers are prohibited in the current recording. Keybinds can start with
  a modifier but once something different than a modifier is recorded they are no longer
  allowed in the sequence.

  E.g

  T-CTRL (invalid)
  CTRL-T (valid)
]]--
local prohibitModifier = false
--[[
  Locks the keyBinding from any further changes
]]--
local lockKeyBinding = false
--[[
  Stores the last key that was recorded and added to the keyBindingText. Helps prevent
  adding multiple modifiers of the same name.

  E.g. CTRL-CTRL-T (invalid)
]]--
local lastRecordedKey = ""
--[[
  The gearBar configuration of the gearBar that is being configured
]]--
local currentGearBarConfiguration
--[[
  The gearSlot position that invoked the setting of a keyBinding
]]--
local currentGearSlotPosition

--[[
  Popup dialog for setting a new keybind
]]--
StaticPopupDialogs["RGPVPW_SET_KEYBIND"] = {
  text = rggm.L["gear_bar_configuration_key_binding_dialog"]
    .. rggm.L["gear_bar_configuration_key_binding_dialog_initial"],
  button1 = rggm.L["gear_bar_configuration_key_binding_dialog_accept"],
  button2 = rggm.L["gear_bar_configuration_key_binding_dialog_cancel"],
  OnShow = function(self)
    me.ResetKeyBindingRecording()
    self:SetScript("OnKeyDown", me.KeyBindingOnKeyDown)
  end,
  OnAccept = function()
    local gearSlot = currentGearBarConfiguration.slots[currentGearSlotPosition]

    if gearSlot ~= nil then
      me.SetKeyBinding(currentGearBarConfiguration.id, currentGearSlotPosition, recordedKeyBinding)
    else
      mod.logger.LogError(
        me.tag,
        "Failed to update keyBinding for gearBar with id: " .. currentGearBarConfiguration.id
        .. " at position: " .. currentGearSlotPosition
      )
    end
  end,
  OnCancel = function()
    me.ResetKeyBindingRecording()
  end,
  timeout = 0,
  whileDead = true,
  preferredIndex = 3
}

--[[
  Popup dialog for confirming the overriding of another keybind
]]--
StaticPopupDialogs["RGPVPW_SET_KEYBIND_OVERRIDE"] = {
  text = rggm.L["gear_bar_configuration_key_binding_override_dialog"],
  button1 = rggm.L["gear_bar_configuration_key_binding_dialog_override_yes"],
  button2 = rggm.L["gear_bar_configuration_key_binding_dialog_override_no"],
  OnShow = function()
    StaticPopup_Hide("RGPVPW_SET_KEYBIND")
  end,
  OnAccept = function()
    me.SetKeyBindingToGearSlot(currentGearBarConfiguration.id, recordedKeyBinding, currentGearSlotPosition)
    StaticPopup_Hide("RGPVPW_SET_KEYBIND")
  end,
  OnCancel = function()
    StaticPopup_Hide("RGPVPW_SET_KEYBIND")
  end,
  timeout = 0,
  whileDead = true,
  preferredIndex = 4
}

--[[
  Function is called after each keydown and records them together to a full keyBind

  @param {table} self
  @param {string} key

]]--
function me.KeyBindingOnKeyDown(self, key)
  if lockKeyBinding then
    mod.logger.LogInfo(me.tag, "KeyBinding is already locked no further changes allowed")
    return
  end

  if lastRecordedKey == key then
    mod.logger.LogDebug(me.tag, "Double key detected - ignoring")
    return
  end

  lastRecordedKey = key

  if recordedKeyBinding ~= "" then
    recordedKeyBinding = recordedKeyBinding .. "-"
  end

  if not prohibitModifier then
    for _, modifierKey in pairs(RGGM_CONSTANTS.MODIFIER_KEYS) do
      if key == modifierKey then
        recordedKeyBinding = recordedKeyBinding .. RGGM_CONSTANTS.MODIFIER_KEY_MAPPING[key]
        isKeyBindingValid = false
        me.UpdateDialogText(self)
        me.UpdateDialog(self)

        return
      end
    end
  end

  recordedKeyBinding = recordedKeyBinding .. key

  me.LockKeyBinding(self)
  prohibitModifier = true
  isKeyBindingValid = true -- at least one "normal key" was added

  me.UpdateDialogText(self)
  me.UpdateDialog(self)

  mod.logger.LogInfo(me.tag, "Keybinding recorded: " .. recordedKeyBinding)
end

--[[
  Reset keyBinding recording
]]--
function me.ResetKeyBindingRecording()
  recordedKeyBinding = ""
  prohibitModifier = false
  lockKeyBinding = false
  lastRecordedKey = ""
  isKeyBindingValid = false
end

--[[
  Lock keyBinding and stop recording any further keys

  @param {table} dialog
]]--
function me.LockKeyBinding(dialog)
  dialog:SetScript("OnKeyDown", nil)
  lockKeyBinding = true
end

--[[
  Update the dialogs text

  @param {table} dialog
]]--
function me.UpdateDialogText(dialog)
  dialog.text:SetText(rggm.L["gear_bar_configuration_key_binding_dialog"] .. " " .. recordedKeyBinding)
end

--[[
  Update dialog related button

  @param {table} dialog
]]--
function me.UpdateDialog(dialog)
  if isKeyBindingValid then
    dialog.button1:Enable() -- enable accept button
  else
    dialog.button1:Disable() -- disable accept button
  end
end

--[[
  Set keybinds

  @param {number} gearBarId
  @param {table} gearSlotPosition
  @param {string} keyBinding
    The keyBinding to set. Will reset the gearSlot if nil or empty
]]--
function me.SetKeyBinding(gearBarId, gearSlotPosition, keyBinding)
  -- unbind keybindings on gearSlot
  if keyBinding == nil or keyBinding == "" then
    me.UnsetKeyBinding(gearBarId, gearSlotPosition)

    return
  end

  local action = GetBindingAction(keyBinding)

  if action ~= "" and action ~= nil then
    --[[
      This keybind is already in use somewhere. Make sure to log this information and reset
      the keybinding.
    ]]--
    mod.logger.LogInfo(me.tag, "Keybinding is already in use: " .. action)
    StaticPopup_Show("RGPVPW_SET_KEYBIND_OVERRIDE")
  else
    mod.logger.LogDebug(me.tag, "Keybinding is not in use")
    me.SetKeyBindingToGearSlot(gearBarId, keyBinding, gearSlotPosition)
  end
end

--[[
  Unset keybinding e.g. when a gearSlot with a binding is deleted or if keyBinding
  was left empty when accepting the keyBinding

  Will be ignored when trying to unset a gearSlot that does not have a keybinding

  @param {number} gearBarId
  @param {number} gearSlotPosition

]]--
function me.UnsetKeyBinding(gearBarId, gearSlotPosition)
  local gearSlot = mod.gearBarManager.GetGearSlot(gearBarId, gearSlotPosition)

  if gearSlot.keyBinding == nil then
    mod.logger.LogInfo(me.tag, "GearSlot has no keybinding set. Nothing to reset")
    return
  end

  mod.logger.LogInfo(me.tag,
    "Keybinding - resetting gearBar{" .. gearBarId .. "}gearSlot{" .. gearSlotPosition .. "} keybind")

  mod.logger.LogDebug(me.tag, "Current keybinding before resetting: " .. gearSlot.keyBinding)
  SetBinding(gearSlot.keyBinding)
  gearSlot.keyBinding = nil

  me.UpdateGearBarConfigurationSubMenu()
  me.AttemptToSaveBindings()
end

--[[
  Remove keybinding from slot if the keybinding is ours

  @param {table} gearSlot
]]--
function me.UnsetKeyBindingFromGearSlot(gearSlot)
  local action = GetBindingAction(gearSlot.keyBinding)

  if action ~= "" and action ~= nil then
    mod.logger.LogInfo(me.tag, "GearSlot has keyBinding set: " .. action)

    local match = string.match(action, RGGM_CONSTANTS.ELEMENT_GEAR_BAR_BASE_FRAME_NAME)

    if match then
      mod.logger.LogInfo(me.tag, "Action found does match GearMenus keyBinding pattern. Removing...")
      SetBinding(gearSlot.keyBinding)
      me.AttemptToSaveBindings()
    else
      mod.logger.LogDebug("Action does not match GearMenus keyBinding pattern. Ignoring keyBinding...")
    end
  end
end

--[[
  Set keyBind to a specific gearSlot
  Note: Will override keyBinds if already set

  @param {number} gearBarId
  @param {string} keyBinding
  @param {number} gearSlotPosition
]]--
function me.SetKeyBindingToGearSlot(gearBarId, keyBinding, gearSlotPosition)
  local gearSlot = mod.gearBarManager.GetGearSlot(gearBarId, gearSlotPosition)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBarId)
  local uiGearSlot = uiGearBar.gearSlotReferences[gearSlotPosition]

  mod.logger.LogInfo(me.tag, "Set new keybinding " .. keyBinding .. " to " .. uiGearSlot:GetName())

  SetBinding(keyBinding) -- reset binding

  if SetBindingClick(keyBinding, uiGearSlot:GetName()) then
    mod.logger.LogInfo(me.tag, "Successfully changed keyBind")
    gearSlot.keyBinding = keyBinding
    mod.gearBarManager.UpdateGearSlot(gearBarId, gearSlotPosition, gearSlot)

    -- update the configuration sub menu (show proper keyBinding after change)
    me.UpdateGearBarConfigurationSubMenu()
    -- save keyBindings to wow-cache
    me.AttemptToSaveBindings()
  else
    mod.logger.LogWarn(me.tag, "Failed to update keybinding: " .. keyBinding .. " to " .. uiGearSlot:GetName())
    mod.logger.PrintUserError(rggm.L["gear_bar_configuration_key_binding_user_error"])
  end
end

--[[
  Blizzard api for saving keybinds. If this is not called after a change the keyBinds are lost after
  a reload of WoW
]]--
function me.AttemptToSaveBindings()
  mod.logger.LogInfo(me.tag, "Attempting to save bindings in - " .. GetCurrentBindingSet())
  AttemptToSaveBindings(RGGM_CONSTANTS.GEAR_BAR_STORE_CHARACTER_BINDINGS)
end

--[[
  Show Keybinding dialog to record and save keyBinding to the passed gearSlot
  UI Interface entrypoint

  @param {table} gearBarConfiguration
  @param {number} gearSlotPosition
]]--
function me.SetKeyBindingForGearSlot(gearBarConfiguration, gearSlotPosition)
  currentGearBarConfiguration = gearBarConfiguration
  currentGearSlotPosition = gearSlotPosition
  StaticPopup_Show("RGPVPW_SET_KEYBIND")
end

--[[
  After changing a keybinding update the configuration submenu
]]--
function me.UpdateGearBarConfigurationSubMenu()
  mod.gearBarConfigurationSubMenu.GearBarOnUpdate()
end

--[[
  Callback for UPDATE_BINDINGS event. Iterate all keyBindings in all gearBars and check if they
  are still valid. KeyBinds could have been changed outside of gearMenu. If this case is detected we remove
  the visual representation of that keyBind from gearMenu
]]--
function me.OnUpdateKeyBindings()
  mod.logger.LogDebug(me.tag, "UPDATE_BINDINGS event. Checking gearMenus keyBinds")

  local gearBars = mod.gearBarManager.GetGearBars()
  -- iterate all keybindings of all gearBars and check if they are still bound correctly
  for i = 1, #gearBars do
    for index, gearSlot in pairs(gearBars[i].slots) do
      if gearSlot.keyBinding ~= nil then
        mod.logger.LogDebug(me.tag, "gearSlot: " .. index .. " has a keyBinding set: " .. gearSlot.keyBinding)

        local action = GetBindingAction(gearSlot.keyBinding)

        if action == nil or action == "" then
          mod.logger.LogInfo(me.tag, "Found a gearBar keyBinding that is not actually set. Resetting keyBind")
          gearSlot.keyBinding = nil -- reset keyBinding for gearSlot
          mod.gearBarManager.UpdateGearSlot(gearBars[i].id, index, gearSlot)
          mod.gearBar.UpdateGearBars() -- update visual reprensentation of all gearBars
        end
      end
    end
  end
end
