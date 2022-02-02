--[[
  MIT License

  Copyright (c) 2022 Michael Wiesendanger

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

-- luacheck: globals UnitIsDeadOrGhost UnitBuff CastingInfo ChannelInfo UnitIsFeignDeath UIParent

local mod = rggm
local me = {}
mod.common = me

me.tag = "Common"

--[[
  Check if a player is really dead and did not use feignDeath

  @return {boolean}
    true if the player is dead
    false if the player is not dead
]]--
function me.IsPlayerReallyDead()
  local dead = UnitIsDeadOrGhost(RGGM_CONSTANTS.UNIT_ID_PLAYER)

  if UnitIsFeignDeath(RGGM_CONSTANTS.UNIT_ID_PLAYER) then
    dead = false
  end

  return dead
end

--[[
  Checks whether the player is currently casting or channeling a spell

  @return {boolean}
    true - If the player is currently casting or channeling a spell
    false - If the player is not currently casting or channeling a spell
]]--
function me.IsPlayerCasting()
  local castName = CastingInfo(RGGM_CONSTANTS.UNIT_ID_PLAYER)
  local channelingName = ChannelInfo(RGGM_CONSTANTS.UNIT_ID_PLAYER)

  if castName ~= nil or channelingName ~= nil then
    return true
  end

  return false
end

--[[
  @param {table} obj
    the object that should be cloned
  @return {table}
    a clone of the object passed
]]--
function me.Clone(obj)
  if type(obj) ~= 'table' then return obj end

  local res = {}

  for k, v in pairs(obj) do
    res[me.Clone(k)] = me.Clone(v)
  end

  return res
end

--[[
  @return {number}
    Returns the uiScale of the UIParent frame 0..1
]]--
function me.GetUiScale()
  return UIParent:GetScale()
end
