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

--[[
  The themeCoordinator is a bridge that routes certain calls to the specific theme implementation.
]]--

local mod = rggm
local me = {}

mod.themeCoordinator = me

me.tag = "ThemeCoordinator"

local themeReference

--[[
  Update the current theme reference for ease of access
]]--
function me.UpdateTheme()
  if mod.configuration.GetUiTheme() == RGGM_CONSTANTS.UI_THEME_CLASSIC then
    themeReference = mod.themeClassic
  elseif mod.configuration.GetUiTheme() == RGGM_CONSTANTS.UI_THEME_CUSTOM then
    themeReference = mod.themeCustom
  else
    mod.logger.LogError(me.tag, "Invalid uiTheme found")
  end
end

--[[
  Fallthrough for CreateGearSlot

  @param {table} gearBarFrame
    The gearBarFrame where the gearSlot gets attached to
  @param {table} gearBar
  @param {number} position
    Position on the gearBar

  @return {table}
    The created gearSlot
]]--
function me.CreateGearSlot(gearBarFrame, gearBar, position)
  if type(themeReference.CreateGearSlot) == "function" then
    return themeReference.CreateGearSlot(gearBarFrame, gearBar, position)
  else
    mod.logger.LogInfo(me.tag, "No implementation for CreateGearSlot in theme doing nothing...")
  end
end

--[[
  Fallthrough for CreateTrinketSlot

  @param {table} changeMenuFrame
    The changeMenuFrame where the changeSlot gets attached to
  @param {number} position

  @return {table}
    The created changeSlot
]]--
function me.CreateChangeSlot(changeMenuFrame, position)
  if type(themeReference.CreateChangeSlot) == "function" then
    return themeReference.CreateChangeSlot(changeMenuFrame, position)
  else
    mod.logger.LogInfo(me.tag, "No implementation for CreateChangeSlot in theme doing nothing...")
  end
end

--[[
  Fallthrough for CreateTrinketSlot

  @param {table} trinketMenuFrame
    The trinketMenuFrame where the trinketSlot gets attached to
  @param {number} position
    Position in the trinketMenu

  @return {table}
    The created trinketSlot
]]--
function me.CreateTrinketSlot(trinketMenuFrame, position)
  if type(themeReference.CreateTrinketSlot) == "function" then
    return themeReference.CreateTrinketSlot(trinketMenuFrame, position)
  else
    mod.logger.LogInfo(me.tag, "No implementation for CreateTrinketSlot in theme doing nothing...")
  end
end

--[[
  Slot prepare texture

  @param {table} slot
  @param {number} slotSize
]]--
function me.UpdateSlotTextureAttributes(slot, slotSize)
  if type(themeReference.UpdateSlotTextureAttributes) == "function" then
    themeReference.UpdateSlotTextureAttributes(slot, slotSize)
  else
    mod.logger.LogInfo(me.tag, "No implementation for UpdateSlotTextureAttributes in theme doing nothing...")
  end
end

--[[
  Callback for a gearBarSlot OnClick

  @param {table} self
  @param {string} button
]]--
function me.GearSlotOnClick(self, button)
  if type(themeReference.GearSlotOnClick) == "function" then
    themeReference.GearSlotOnClick(self, button)
  else
    mod.logger.LogInfo(me.tag, "No implementation for GearSlotOnClick in theme doing nothing...")
  end
end

--[[
  Callback for a gearSlot OnEnter

  @param {table} self
]]--
function me.GearSlotOnEnter(self)
  if type(themeReference.GearSlotOnEnter) == "function" then
    themeReference.GearSlotOnEnter(self)
  else
    mod.logger.LogInfo(me.tag, "No implementation for GearSlotOnEnter in theme doing nothing...")
  end
end

--[[
  Callback for a gearSlot OnLeave

  @param {table} self
]]--
function me.GearSlotOnLeave(self)
  if type(themeReference.GearSlotOnLeave) == "function" then
    themeReference.GearSlotOnLeave(self)
  else
    mod.logger.LogInfo(me.tag, "No implementation for GearSlotOnLeave in theme doing nothing...")
  end
end

--[[
  Callback for a changeSlot OnClick

  @param {table} self
  @param {string} button
]]--
function me.ChangeSlotOnClick(self, button)
  if type(themeReference.ChangeSlotOnClick) == "function" then
    themeReference.ChangeSlotOnClick(self, button)
  else
    mod.logger.LogInfo(me.tag, "No implementation for ChangeSlotOnClick in theme doing nothing...")
  end
end

--[[
  Callback for a changeSlot OnEnter

  @param {table} self
]]--
function me.ChangeSlotOnEnter(self)
  if type(themeReference.ChangeSlotOnEnter) == "function" then
    themeReference.ChangeSlotOnEnter(self)
  else
    mod.logger.LogInfo(me.tag, "No implementation for ChangeSlotOnEnter in theme doing nothing...")
  end
end

--[[
  Callback for a changeSlot OnLeave

  @param {table} self
]]--
function me.ChangeSlotOnLeave(self)
  if type(themeReference.ChangeSlotOnLeave) == "function" then
    themeReference.ChangeSlotOnLeave(self)
  else
    mod.logger.LogInfo(me.tag, "No implementation for ChangeSlotOnLeave in theme doing nothing...")
  end
end

--[[
  Callback for changeMenuSlotReset

  @param {table} changeMenuSlot
]]--
function me.ChangeMenuSlotReset(changeMenuSlot)
  if type(themeReference.ChangeMenuSlotReset) == "function" then
    themeReference.ChangeMenuSlotReset(changeMenuSlot)
  else
    mod.logger.LogInfo(me.tag, "No implementation for ChangeMenuSlotReset in theme doing nothing...")
  end
end

--[[
  Callback for a trinketMenuSlot OnClick

  @param {table} self
  @param {string} button
]]--
function me.TrinketMenuSlotOnClick(self, button)
  if type(themeReference.TrinketMenuSlotOnClick) == "function" then
    themeReference.TrinketMenuSlotOnClick(self, button)
  else
    mod.logger.LogInfo(me.tag, "No implementation for TrinketMenuSlotOnClick in theme doing nothing...")
  end
end

--[[
  Callback for a trinketMenuSlot OnEnter

  @param {table} self
]]--
function me.TrinketMenuSlotOnEnter(self)
  if type(themeReference.TrinketMenuSlotOnEnter) == "function" then
    themeReference.TrinketMenuSlotOnEnter(self)
  else
    mod.logger.LogInfo(me.tag, "No implementation for TrinketMenuSlotOnEnter in theme doing nothing...")
  end
end

--[[
  Callback for a trinketMenuSlot OnLeave

  @param {table} self
]]--
function me.TrinketMenuSlotOnLeave(self)
  if type(themeReference.TrinketMenuSlotOnLeave) == "function" then
    themeReference.TrinketMenuSlotOnLeave(self)
  else
    mod.logger.LogInfo(me.tag, "No implementation for TrinketMenuSlotOnLeave in theme doing nothing...")
  end
end

--[[
  Callback for trinketMenuSlotReset

  @param {table} trinketMenuSlot
]]--
function me.TrinketMenuSlotReset(trinketMenuSlot)
  if type(themeReference.TrinketMenuSlotReset) == "function" then
    themeReference.TrinketMenuSlotReset(trinketMenuSlot)
  else
    mod.logger.LogInfo(me.tag, "No implementation for TrinketMenuSlotReset in theme doing nothing...")
  end
end
