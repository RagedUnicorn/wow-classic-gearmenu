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

-- luacheck: globals StaticPopupDialogs StaticPopup_Show

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

-- TODO also need to track the validity of a keybinding
-- while it only has modifiers only it is not valid

local mod = rggm
local me = {}
mod.keyBind = me

me.tag = "KeyBind"

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
  Popup dialog for choosing a profile name
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
    mod.logger.LogError(me.tag, recordedKeyBinding)

    local gearSlot = currentGearBarConfiguration.slots[currentGearSlotPosition]

    if gearSlot ~= nil then
      gearSlot.keyBinding = recordedKeyBinding
      mod.gearBarManager.UpdateGearSlot(currentGearBarConfiguration.id, currentGearSlotPosition, gearSlot)
      mod.gearBar.UpdateGearBars()
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
  Show Keybinding dialog to record and save keyBinding to the passed gearSlot

  @param {table} gearBarConfiguration
  @param {number} gearSlotPosition
]]--
function me.SetKeyBindingForGearSlot(gearBarConfiguration, gearSlotPosition)
  currentGearBarConfiguration = gearBarConfiguration
  currentGearSlotPosition = gearSlotPosition
  StaticPopup_Show("RGPVPW_SET_KEYBIND")
end

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
        me.UpdateDialogText(self)

        return
      end
    end
  end

  recordedKeyBinding = recordedKeyBinding .. key

  me.LockKeyBinding(self)
  prohibitModifier = true

  me.UpdateDialogText(self)

  mod.logger.LogInfo(me.tag, "Keybinding recorded: " .. recordedKeyBinding)
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
  Reset keyBinding recording
]]--
function me.ResetKeyBindingRecording()
  recordedKeyBinding = ""
  prohibitModifier = false
  lockKeyBinding = false
  lastRecordedKey = ""
end

--[[
  Update the dialogs text

  @param {table} dialog
]]--
function me.UpdateDialogText(dialog)
  dialog.text:SetText(rggm.L["gear_bar_configuration_key_binding_dialog"] .. " " .. recordedKeyBinding)
end
