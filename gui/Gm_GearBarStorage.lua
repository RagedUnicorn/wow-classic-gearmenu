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

-- luacheck: globals STANDARD_TEXT_FONT CreateFrame FauxScrollFrame_Update FauxScrollFrame_GetOffset
-- luacheck: globals UIDropDownMenu_Initialize UIDropDownMenu_AddButton UIDropDownMenu_SetSelectedValue

--[[
  The gearBarMenu (GM_GearBarConfigurationMenu) module has some similarities to the gearBar (GM_GearBar) module.
  It is also heavily interacting with gearBarManager (GM_GearBarManager) module but unlike the gearBar module
  its purpose is to change and create values in the gearBarManager. It is used to give the user a UI to create, delete
  and modify new gearBars and slots.
]]--

--[[
  Module for easier storage and retrieving of gearBar elements that are directly shown to the user
  in the form of a gearBar. Not to be used for the configuration of a gearBar
]]--

local mod = rggm
local me = {}

mod.gearBarStorage = me

me.tag = "GearBarStorage"

--[[
  Storage for gearBar ui elements
]]--
local gearBarUiStorage = {}

--[[
  Retrieve all stored gearBars

  @return {table}
]]--
function me.GetGearBars()
  return gearBarUiStorage
end

--[[
  Retrieve a gearBar object from the storage by its id

  @param {number} gearBarId
    An id of a gearBar

  @return {table | nil}
    table - A table containing all relevant ui elements for that gearBar
    nil - If no gearBar with the passed id could be found
]]--
function me.GetGearBar(gearBarId)
  if gearBarUiStorage[gearBarId] == nil then
    mod.logger.LogError(me.tag, "Unable to find a GearBar with id: " .. gearBarId)
    return nil
  end

  return gearBarUiStorage[gearBarId]
end

--[[
  Store a gearBar object

  @param {number} gearBarId
    An id of a gearBar
  @param {table} gearBarReference
    A ui reference to a gearBar
]]--
function me.AddGearBar(gearBarId, gearBarReference)
  gearBarUiStorage[gearBarId] = {
    ["gearBarReference"] = gearBarReference,
    ["gearSlotReferences"] = {}
  }
end

--[[
  Not possible to destroy frames. In this case the frame is hidden and the reference
  nullified.

  @param {number} gearBarId
    An id of a gearBar
]]--
function me.RemoveGearBar(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)
  gearBar.gearBarReference:Hide()
  gearBarUiStorage[gearBarId] = nil
end

--[[
  Store a gearSlot object to a gearBar object

  @param {number} gearBarId
    An id of a gearBar
  @param {table} gearSlotReference
    A ui reference to a gearSlot
]]--
function me.AddGearSlot(gearBarId, gearSlotReference)
  if gearBarUiStorage[gearBarId] == nil then
    mod.logger.LogError(me.tag, "Unable to find a GearBar with id: " .. gearBarId)
    return
  end

  table.insert(gearBarUiStorage[gearBarId].gearSlotReferences, gearSlotReference)
  mod.logger.LogDebug(me.tag, "Added new slot to gearBar with id: " .. gearBarId)
end
