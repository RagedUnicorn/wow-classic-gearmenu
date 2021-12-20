--[[
  MIT License

  Copyright (c) 2021 Michael Wiesendanger

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
