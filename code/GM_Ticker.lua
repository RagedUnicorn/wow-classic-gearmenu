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

-- luacheck: globals C_Timer

local mod = rggm
local me = {}
mod.ticker = me

me.tag = "Ticker"

local changeMenuTicker
local slotCooldownTicker
local combatQueueTicker
local rangeCheckTicker

--[[
  Start the repeating update ticker for changeMenu
]]--
function me.StartTickerChangeMenu()
  if changeMenuTicker == nil or changeMenuTicker._cancelled then
    changeMenuTicker = C_Timer.NewTicker(
      RGGM_CONSTANTS.CHANGE_MENU_UPDATE_INTERVAL, mod.changeMenu.ChangeMenuOnUpdate)
      mod.logger.LogInfo(me.tag, "Started 'ChangeMenuTicker'")
  end
end

--[[
  Stop the repeating update ticker for changeMenu
]]--
function me.StopTickerChangeMenu()
  if changeMenuTicker then
    changeMenuTicker:Cancel()
    mod.logger.LogInfo(me.tag, "Stopped 'ChangeMenuTicker'")
  end
end

--[[
  Start the repeating update ticker for slotCooldowns
]]--
function me.StartTickerSlotCooldown()
  if slotCooldownTicker == nil or slotCooldownTicker._cancelled then
    slotCooldownTicker = C_Timer.NewTicker(
      RGGM_CONSTANTS.SLOT_COOLDOWN_UPDATE_INTERVAL, mod.uiHelper.UpdateSlotCooldown)
      mod.logger.LogInfo(me.tag, "Started 'SlotCooldownTicker'")
  end
end

--[[
  Stop the repeating update ticker for slotCooldowns
]]--
function me.StopTickerSlotCooldown()
  if slotCooldownTicker then
    slotCooldownTicker:Cancel()
    mod.logger.LogInfo(me.tag, "Stopped 'SlotCooldownTicker'")
  end
end

--[[
  Start the repeating update ticker for combatQueue
]]--
function me.StartTickerCombatQueue()
  if combatQueueTicker == nil or combatQueueTicker._cancelled then
    combatQueueTicker = C_Timer.NewTicker(
      RGGM_CONSTANTS.COMBAT_QUEUE_UPDATE_INTERVAL, mod.combatQueue.ProcessQueue)
      mod.logger.LogInfo(me.tag, "Started 'CombatQueueTicker'")
  end
end

--[[
  Stop the repeating update ticker for combatQueue
]]--
function me.StopTickerCombatQueue()
  if combatQueueTicker then
    combatQueueTicker:Cancel()
    mod.logger.LogInfo(me.tag, "Stopped 'CombatQueueTicker'")
  end
end

--[[
  Start the repeating update ticker for rangeCheck
]]--
function me.StartTickerRangeCheck()
  if rangeCheckTicker == nil or rangeCheckTicker._cancelled then
    rangeCheckTicker = C_Timer.NewTicker(
      RGGM_CONSTANTS.RANGE_CHECK_UPDATE_INTERVAL, mod.gearBar.UpdateSpellRange)
      mod.logger.LogInfo(me.tag, "Started 'StartTickerRangeCheck'")
  end
end

--[[
  Stop the repeating update ticker for rangeCheck
]]--
function me.StopTickerRangeCheck()
  if rangeCheckTicker then
    rangeCheckTicker:Cancel()
    mod.logger.LogInfo(me.tag, "Stopped 'StopTickerRangeCheck'")
  end
end
