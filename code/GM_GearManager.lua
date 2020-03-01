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

-- luacheck: globals INVSLOT_HEAD INVSLOT_NECK INVSLOT_SHOULDER INVSLOT_CHEST INVSLOT_WAIST INVSLOT_LEGS INVSLOT_FEET
-- luacheck: globals INVSLOT_WRIST INVSLOT_HAND INVSLOT_FINGER1 INVSLOT_FINGER2 INVSLOT_TRINKET1 INVSLOT_TRINKET2
-- luacheck: globals INVSLOT_BACK INVSLOT_MAINHAND INVSLOT_OFFHAND INVSLOT_RANGED INVSLOT_AMMO UnitClass

local mod = rggm
local me = {}

mod.gearManager = me

me.tag = "GearManager"

--[[
  Gearslots metadata

  {
    ["name"] = "",
      {string} - The name of the slot. Used for translation
    ["simplifiedName"] = "",
      {string} - Simplified name if the slot. Makes no difference between similar slots
      such as upper and lower trinket and upper and lower finger. Used for translation
    ["type"] = {"", ""},
      {table} - A table of all inventory types that fit this slot
    ["textureId"] = 1,
      {number} - Texture id of the slot. Similar slots have the same texture
    ["slotId"] = 1,
      {number} - The slots id
  }
]]--
local gearSlots = {
  {
    ["name"] = "slot_name_head",
    ["type"] = {"INVTYPE_HEAD"},
    ["textureId"] = 136516,
    ["slotId"] = INVSLOT_HEAD
  }, {
    ["name"] = "slot_name_neck",
    ["type"] = {"INVTYPE_NECK"},
    ["textureId"] = 136519,
    ["slotId"] = INVSLOT_NECK
  }, {
    ["name"] = "slot_name_shoulders",
    ["type"] = {"INVTYPE_SHOULDER"},
    ["textureId"] = 136526,
    ["slotId"] = INVSLOT_SHOULDER
  }, {
    ["name"] = "slot_name_chest",
    ["type"] = {"INVTYPE_CHEST", "INVTYPE_ROBE"},
    ["textureId"] = 136512,
    ["slotId"] = INVSLOT_CHEST
  }, {
    ["name"] = "slot_name_waist",
    ["type"] = {"INVTYPE_WAIST"},
    ["textureId"] = 136529,
    ["slotId"] = INVSLOT_WAIST
  }, {
    ["name"] = "slot_name_legs",
    ["type"] = {"INVTYPE_LEGS"},
    ["textureId"] = 136517,
    ["slotId"] = INVSLOT_LEGS
  }, {
    ["name"] = "slot_name_feet",
    ["type"] = {"INVTYPE_FEET"},
    ["textureId"] = 136513,
    ["slotId"] = INVSLOT_FEET
  }, {
    ["name"] = "slot_name_wrist",
    ["type"] = {"INVTYPE_WRIST"},
    ["textureId"] = 136530,
    ["slotId"] = INVSLOT_WRIST
  }, {
    ["name"] = "slot_name_hands",
    ["type"] = {"INVTYPE_HAND"},
    ["textureId"] = 136515,
    ["slotId"] = INVSLOT_HAND
  }, {
    ["name"] = "slot_name_upper_finger",
    ["simplifiedName"] = "slot_name_finger",
    ["type"] = {"INVTYPE_FINGER"},
    ["textureId"] = 136514,
    ["slotId"] = INVSLOT_FINGER1
  }, {
    ["name"] = "slot_name_lower_finger",
    ["simplifiedName"] = "slot_name_finger",
    ["type"] = {"INVTYPE_FINGER"},
    ["textureId"] = 136514,
    ["slotId"] = INVSLOT_FINGER2
  }, {
    ["name"] = "slot_name_upper_trinket",
    ["simplifiedName"] = "slot_name_trinket",
    ["type"] = {"INVTYPE_TRINKET"},
    ["textureId"] = 136528,
    ["slotId"] = INVSLOT_TRINKET1
  }, {
    ["name"] = "slot_name_lower_trinket",
    ["simplifiedName"] = "slot_name_trinket",
    ["type"] = {"INVTYPE_TRINKET"},
    ["textureId"] = 136528,
    ["slotId"] = INVSLOT_TRINKET2
  }, {
    ["name"] = "slot_name_back",
    ["type"] = {"INVTYPE_CLOAK"},
    ["textureId"] = 136512,
    ["slotId"] = INVSLOT_BACK
  }, {
    ["name"] = "slot_name_main_hand",
    ["type"] = {"INVTYPE_WEAPONMAINHAND", "INVTYPE_2HWEAPON", "INVTYPE_WEAPON"},
    ["textureId"] = 136518,
    ["slotId"] = INVSLOT_MAINHAND
  }, {
    ["name"] = "slot_name_off_hand",
    ["type"] = (function()
      local _, class = UnitClass(RGGM_CONSTANTS.UNIT_ID_PLAYER)

      if class == "ROGUE" then
        --[[
          e.g. possible itemids
          INVTYPE_HOLDABLE - 4984

          INVTYPE_WEAPONOFFHAND - 19866

          INVTYPE_WEAPON - 19166
        ]]--
        return {"INVTYPE_HOLDABLE", "INVTYPE_WEAPONOFFHAND", "INVTYPE_WEAPON"}
        --[[
          e.g. possible itemids
          INVTYPE_HOLDABLE - 4984
        ]]--
      elseif class == "MAGE" or class == "WARLOCK" or class == "PRIEST" or class == "DRUID" then
        return {"INVTYPE_HOLDABLE"}
        --[[
          e.g. possible itemids
          INVTYPE_HOLDABLE - 4984

          INVTYPE_WEAPONOFFHAND - 19866

          INVTYPE_WEAPON - 19166
        ]]--
      elseif  class == "HUNTER" then
        return {"INVTYPE_WEAPONOFFHAND", "INVTYPE_WEAPON", "INVTYPE_HOLDABLE"}
        --[[
          e.g. possible itemids
          INVTYPE_HOLDABLE - 4984

          INVTYPE_SHIELD - 19862
        ]]--
      elseif class == "PALADIN" or class == "SHAMAN" then
        return {"INVTYPE_HOLDABLE", "INVTYPE_SHIELD"}
        --[[
          e.g. possible itemids
          INVTYPE_HOLDABLE - 4984

          INVTYPE_SHIELD - 19862

          INVTYPE_WEAPON - 19166

          INVTYPE_WEAPONOFFHAND - 19866
        ]]--
      elseif class == "WARRIOR" then
        return {"INVTYPE_HOLDABLE", "INVTYPE_SHIELD", "INVTYPE_WEAPON", "INVTYPE_WEAPONOFFHAND"}
      else
        return {}
      end
    end)(),
    ["textureId"] = 136524,
    ["slotId"] = INVSLOT_OFFHAND
  }, {
    ["name"] = "slot_name_ranged",
    ["type"] = {"INVTYPE_RANGED", "INVTYPE_THROWN", "INVTYPE_RANGEDRIGHT"},
    ["textureId"] = 136520,
    ["slotId"] = INVSLOT_RANGED
  }, {
    ["name"] = "slot_name_ammo",
    ["type"] = {"INVTYPE_AMMO"},
    ["textureId"] = 136520,
    ["slotId"] = INVSLOT_AMMO
  }
}

--[[
  @return {table}
]]--
function me.GetGearSlots()
  return gearSlots
end

--[[
  @param {number} slotId
    A slotId on the gearBar

  @return {table | nil}
    table - if a gearSlot could be found
    nil - if no gearSlot could be found
]]--
function me.GetGearSlotForSlotId(slotId)
  for _, slot in pairs(gearSlots) do
    if slot.slotId == slotId then
      return slot
    end
  end

  return nil
end

--[[
  Searches and returns all slots found that match a certain type such as
  INVTYPE_CLOAK etc.

  @param {string} type

   @return {table}
    A table with all found gearSlots. Can be empty.
]]--
function me.GetGearSlotsForType(type)
  local foundGearSlots = {}

  for _, slot in pairs(gearSlots) do
    for _, value in pairs(slot.type) do
      if value == type then
        table.insert(foundGearSlots, slot)
      end
    end
  end

  return foundGearSlots
end
