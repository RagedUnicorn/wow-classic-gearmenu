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

local mod = rggm
local me = {}

mod.gearBarManager = me

me.tag = "GearBarManager"

--[[
  Stores all relevant metadata for the users gearBars. It does only store data that should be persisted. This
  does not include references to ui elements

  {
    ["id"] = {number},
      A unique identifier for the gearBar. This identifier can be directly matched to the GearBar
      UI-Element once it is created
    ["displayName"] = {string},
      A user friendly display name for the user to recognize
    ["position"] = {table},
      A position object that can be unpacked into SetPoint
      e.g. {"LEFT", 150, 0}
    [slots] = {},

  }
]]--
-- TODO this needs to be moved to the addon settings (savedvariable)
local gearBars = {}

--[[
  Creates a default object for a new GearBar

  @return {table}
    Return a default object for a new GearBar
]]--
function me.GetNewGearBar()
  local gearBar = {
    ["id"] = math.floor(math.random() * 100000),
    ["displayName"] = "",
    ["slots"] = {}
  }

  return gearBar
end

--[[
  @return {table}
    Return a clone of all gearBars
]]--
function me.GetGearBars()
  return mod.common.Clone(gearBars)
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
  for _, gearBar in pairs(gearBars) do
    if gearBar.id == gearBarId then
      return gearBar
    end
  end

  mod.logger.LogError(me.tag, "Could not find GearBar with id: " .. gearBarId)

  return nil
end

--[[
  Create a new entry for the passed GearBar in the gearbar storage.

  @param {table} gearBar
    The gearBar that should be added
]]--
function me.AddNewGearBar(gearBar)
  table.insert(gearBars, gearBar)
  mod.logger.LogInfo(me.tag, "Added new GearBar with id: " .. gearBar.id)
end

--[[
  Remove a gearBar from the gearbar storage. E.g. when it was deleted by the player

  @param {number} gearBarId
    An id of a gearBar
]]--
function me.RemoveGearBar(gearBarId)
  for index, gearBar in pairs(gearBars) do
    if gearBar.id == gearBarId then
      table.remove(gearBars, index)
      mod.logger.LogInfo(me.tag, "Removed GearBar with id: " .. gearBarId)

      return -- abort
    end
  end

  mod.logger.LogError(
    me.tag, "Failed to remove GearBar from storage. Was unable to find GearBar with id: " .. gearBarId
  )
end

--[[
  Creates a default object for a new GearSlot

  @return {table}
    Return a default object for a new GearSlot
]]--
function me.GetNewGearSlot()
  local gearSlot = {
    ["name"] = "",
      -- {string}
    ["type"] = {},
      -- list of {string}
    ["textureId"] = nil,
      -- {number}
    ["slotId"] = nil
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
      ]]--
  }

  return gearSlot
end

--[[
  Create a new gearSlot and add it to passed gearBar

  @param {number} gearBarId
    An id of a gearBar

  @return {boolean}
    true - if the operation was successful
    false - if the operation was not successful
]]--
function me.AddNewGearSlot(gearBarId)
  local gearSlot = me.GetNewGearSlot()
  local gearBar = me.GetGearBar(gearBarId)

  -- TODO hardoced for testing
  gearSlot.name = "slot_name_head"
  gearSlot.type = {"INVTYPE_HEAD"}
  gearSlot.textureId = 136516
  gearSlot.slotId = INVSLOT_HEAD

  if gearBar ~= nil then
    table.insert(gearBar.slots, gearSlot)
    mod.logger.LogError(me.tag, "added new gearslot")
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
