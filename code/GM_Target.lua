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

-- luacheck: globals UnitIsEnemy UnitGUID UnitName

local mod = rggm
local me = {}

mod.target = me

me.tag = "Target"

local currentTargetGuid = ""
local currentTargetName = ""

--[[
  Returns the players current target uid or an empty string if the player has no target.

  @return {string}
]]--
function me.GetCurrentTargetGuid()
  return currentTargetGuid
end

--[[
  Returns the players current target name or an empty string if the player has no target.

  @return {string}
]]--
function me.GetCurrentTargetName()
  return currentTargetName
end

--[[
  Get players current target (if enemy) in the form of the targets unique id and update the currentTarget.
]]--
function me.UpdateCurrentTarget()
  local targetId
  local targetName

  targetId = UnitGUID(RGGM_CONSTANTS.UNIT_ID_TARGET)
  targetName = UnitName(RGGM_CONSTANTS.UNIT_ID_TARGET)

  if targetId == nil then
    currentTargetGuid = ""
    mod.logger.LogDebug(me.tag, "Update players targetGUID: [Empty-target]")
  else
    currentTargetGuid = targetId
    mod.logger.LogDebug(me.tag, "Update players targetGUID: " .. currentTargetGuid)
  end

  if targetName == nil then
    currentTargetName = ""
    mod.logger.LogDebug(me.tag, "Update players targetName: [Empty-target]")
  else
    currentTargetName = targetName
    mod.logger.LogDebug(me.tag, "Update players targetName: " .. currentTargetName)
  end
end
