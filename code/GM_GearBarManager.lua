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

--[[
  Note this module modifies directly gearBars that are stored in GearMenuConfiguration
]]--

local mod = rggm
local me = {}

mod.gearBarManager = me

me.tag = "GearBarManager"

--[[
  Create a new entry for the passed GearBar in the gearbar storage and also create
  the initial default gearSlot

  @param {string} gearBarName
    The gearBarName that should be used for display

  @return {table}
    The created gearBar
]]--
function me.AddGearBar(gearBarName)
  local gearBar = {
    ["id"] = 100000 + math.floor(math.random() * 100000),
    ["displayName"] = gearBarName,
    ["isLocked"] = false,
    ["showKeyBindings"] = true,
    ["showCooldowns"] = true,
    ["slots"] = {},
    ["slotSize"] = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE,
    ["position"] = { -- default position
      ["point"] = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_POSITION[1],
      ["posX"] = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_POSITION[2],
      ["posY"] = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_POSITION[3],
    }
  }

  table.insert(GearMenuConfiguration.gearBars, gearBar)
  mod.logger.LogInfo(me.tag, "Created new GearBar with id: " .. gearBar.id)

  me.AddGearSlot(gearBar.id)

  return gearBar
end

--[[
  Remove a gearBar from the gearbar storage. E.g. when it was deleted by the player

  @param {number} gearBarId
    An id of a gearBar
]]--
function me.RemoveGearBar(gearBarId)
  for index, gearBar in pairs(GearMenuConfiguration.gearBars) do
    if gearBar.id == gearBarId then
      table.remove(GearMenuConfiguration.gearBars, index)
      mod.logger.LogInfo(me.tag, "Removed GearBar with id: " .. gearBarId)

      return -- abort
    end
  end

  mod.logger.LogError(
    me.tag, "Failed to remove GearBar from storage. Was unable to find GearBar with id: " .. gearBarId
  )
end

--[[
  Retrieve a gearBar by its id

  @param {number} gearBarId
    An id of a gearBar

  @return {table | nil}
    table - if the gearBar was found
    nil - if no matching gearBar could be found
]]--
function me.GetGearBar(gearBarId)
  for _, gearBar in pairs(GearMenuConfiguration.gearBars) do
    if gearBar.id == gearBarId then
      return gearBar
    end
  end

  mod.logger.LogError(me.tag, "Could not find GearBar with id: " .. gearBarId)

  return nil
end

--[[
  @return {table}
    Return a clone of all gearBars
]]--
function me.GetGearBars()
  return mod.common.Clone(GearMenuConfiguration.gearBars)
end

--[[
  Update the position of a specific gearBar

  @param {number} gearBarId
  @param {string} point
  @param {string} relativeTo
  @param {string} relativePoint
  @param {number} posX
  @param {number} posY
]]--
function me.UpdateGearBarPosition(gearBarId, point, relativeTo, relativePoint, posX, posY)
  local gearBar = me.GetGearBar(gearBarId)
  gearBar.position.point = point
  gearBar.position.relativeTo = relativeTo
  gearBar.position.relativePoint = relativePoint
  gearBar.position.posX = posX
  gearBar.position.posY = posY
end

--[[
  Unlock the moving of a specific gearBar

  @param {number} gearBarId
]]--
function me.UnlockGearBar(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  gearBar.isLocked = false
  mod.gearBar.UpdateGearBar(gearBar)
end

--[[
  Lock the moving of a specific gearBar

  @param {number} gearBarId
]]--
function me.LockGearBar(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  gearBar.isLocked = true
  mod.gearBar.UpdateGearBar(gearBar)
end

--[[
  @param {number} gearBarId

  @return {boolean}
    true - if the gearBar is locked
    false - if the gearBar is not locked
]]--
function me.IsGearBarLocked(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  return gearBar.isLocked
end

--[[
  Show keybindings

  @param {number} gearBarId
]]--
function me.EnableShowKeyBindings(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  gearBar.showKeyBindings = true
  mod.gearBar.UpdateGearBar(gearBar)
  mod.ticker.UnregisterForTickerRangeCheck(gearBarId)
end

--[[
  Hide keybindings

  @param {number} gearBarId
]]--
function me.DisableShowKeyBindings(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  gearBar.showKeyBindings = false
  mod.gearBar.UpdateGearBar(gearBar)
  mod.ticker.RegisterForRangeCheck(gearBarId)
end

--[[
  @param {number} gearBarId

  @return {boolean}
    true - if showing of keybindings is enabled
    false - if showing of keybindings is disabled
]]--
function me.IsShowKeyBindingsEnabled(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  return gearBar.showKeyBindings
end

--[[
  Show cooldowns

  @param {number} gearBarId
]]--
function me.EnableShowCooldowns(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  gearBar.showCooldowns = true
  mod.gearBar.UpdateGearBar(gearBar)
end

--[[
  Hide cooldowns

  @param {number} gearBarId
]]--
function me.DisableShowCooldowns(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  gearBar.showCooldowns = false
  mod.gearBar.UpdateGearBar(gearBar)
  GearMenuConfiguration.showCooldowns = false
end

--[[
  @param {number} gearBarId

  @return {boolean}
    true - if showing of cooldown is enabled
    false - if showing of cooldown is disabled
]]--
function me.IsShowCooldownsEnabled(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  return gearBar.showCooldowns
end

--[[
  Show keybindings

  @param {number} gearBarId
]]--
function me.EnableShowKeyBindings(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  gearBar.showKeyBindings = true
  mod.gearBar.UpdateGearBar(gearBar)
  -- mod.ticker.StartTickerRangeCheck() TODO
end

--[[
  Hide keybindings

  @param {number} gearBarId
]]--
function me.DisableShowKeyBindings(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  gearBar.showKeyBindings = false
  mod.gearBar.UpdateGearBar(gearBar)
  -- mod.ticker.StopTickerRangeCheck() TODO
end

--[[
  @param {number} gearBarId

  @return {boolean}
    true - if showing of keybindings is enabled
    false - if showing of keybindings is disabled
]]--
function me.IsShowKeyBindingsEnabled(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  return gearBar.showKeyBindings
end

--[[
  Create a new gearSlot and add it to passed gearBar

  @param {number} gearBarId
    An id of a gearBar

  @return {boolean}
    true - if the operation was successful
    false - if the operation was not successful
]]--
function me.AddGearSlot(gearBarId)
  local gearSlot = {
    ["name"] = "",
      -- {string}
    ["type"] = {},
      -- list of {string}
    ["textureId"] = nil,
      -- {number}
    ["slotId"] = nil,
      --[[
        {number} on of
          INVSLOT_HEAD
          INVSLOT_NECK
          INVSLOT_SHOULDER
          INVSLOT_CHEST
          INVSLOT_WAIST
          INVSLOT_LEGS
          INVSLOT_FEET
          INVSLOT_WRIST
          INVSLOT_HAND
          INVSLOT_FINGER1
          INVSLOT_FINGER2
          INVSLOT_TRINKET1
          INVSLOT_TRINKET2
          INVSLOT_BACK
          INVSLOT_MAINHAND
          INVSLOT_OFFHAND
          INVSLOT_RANGED
          INVSLOT_AMMO
      ]]--
    ["keyBinding"] = nil
      --[[
        {string}
      ]]--
  }
  local gearBar = me.GetGearBar(gearBarId)
  local defaultGearSlot = mod.gearManager.GetGearSlotForSlotId(RGGM_CONSTANTS.GEAR_BAR_GEAR_SLOT_DEFAULT_VALUE)
  gearSlot.name = defaultGearSlot.name
  gearSlot.type = defaultGearSlot.type
  gearSlot.textureId = defaultGearSlot.textureId
  gearSlot.slotId = defaultGearSlot.slotId

  if gearBar ~= nil then
    table.insert(gearBar.slots, gearSlot)
    return true
  end

  mod.logger.LogError(me.tag, "Was unable to find GearBar with id: " .. gearBarId)

  return false
end

--[[
  Remove a gearSlot from a gearBar

  @param {number} gearBarId
    An id of a gearBar
  @param {number} position

  @return {boolean}
    true - if the operation was successful
    false - if the operation was not successful
]]--
function me.RemoveGearSlot(gearBarId, position)
  local gearBar = me.GetGearBar(gearBarId)

  if gearBar ~= nil then
    table.remove(gearBar.slots, position)
    return true
  end

  mod.logger.LogError(me.tag, "Was unable to find GearBar with id: " .. gearBarId)

  return false
end

--[[
  Retrieve a gearslot from a gearBar by its gearBarId and gearslot position

  @param {number} gearBarId
  @param {number} position

  @retunr {table | nil}
    table - the gearSlot that was found
    nil - if no gearSlot was found
]]--
function me.GetGearSlot(gearBarId, position)
  local gearBar = me.GetGearBar(gearBarId)

  if gearBar == nil then
    mod.logger.LogError(me.tag, "Was unable to find GearBar with id: " .. gearBarId)
    return nil
  end

  return gearBar.slots[position]
end

--[[
  @param {number} gearBarId
    An id of a gearBar
  @param {number} position
  @param {table} updatedGearSlot
    A gearSlot table that will overwrite the configured values for the slot

  @return {boolean}
    true - if the operation was successful
    false - if the operation was not successful
]]--
function me.UpdateGearSlot(gearBarId, position, updatedGearSlot)
  local gearBar = me.GetGearBar(gearBarId)

  if gearBar ~= nil and gearBar.slots[position] ~= nil then
    gearBar.slots[position] = updatedGearSlot

    return true
  end

  mod.logger.LogError(me.tag, "Failed to update gearBarSlot position {"
    .. position .. "} for gearBar with id: " .. gearBarId)
end

--[[
  Update the gearbar slotSize in the gearBars configuration and invoke an ui
  update of the specific gearBar

  @param {number} gearBarId
    An id of a gearBar
  @param {number} slotSize
]]--
function me.SetGearSlotSize(gearBarId, slotSize)
  local gearBar = me.GetGearBar(gearBarId)
  if gearBar then
    gearBar.slotSize = slotSize
    mod.gearBar.UpdateGearBar(gearBar)
  else
    mod.logger.LogError(me.tag, "Failed to update the gearSlotSize of the gearBar with id: " .. gearBarId)
  end
end

--[[
  Get the configured gearbar slotsize

  @param {number} gearBarId
    An id of a gearBar

  @return {number}
]]--
function me.GetGearSlotSize(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)

  if gearBar then
    return gearBar.slotSize
  else
    mod.logger.LogError(me.tag, "Failed to retrieve gearSlotSize. Using default size")
    return RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE
  end
end
