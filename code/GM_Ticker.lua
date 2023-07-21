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

-- luacheck: globals C_Timer

local mod = rggm
local me = {}
mod.ticker = me

me.tag = "Ticker"

local combatQueueTicker
local rangeCheckTicker
local changeMenuTicker

local tickerRangeCheckSubscribers = {}

--[[
  Start the repeating update ticker for changeMenu
]]--
function me.StartTickerChangeMenu()
  if changeMenuTicker == nil or changeMenuTicker:IsCancelled() then
    changeMenuTicker = C_Timer.NewTicker(
      RGGM_CONSTANTS.CHANGE_MENU_UPDATE_INTERVAL, mod.gearBarChangeMenu.ChangeMenuOnUpdate)
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
  Start the repeating update ticker for combatQueue
]]--
function me.StartTickerCombatQueue()
  if combatQueueTicker == nil or combatQueueTicker:IsCancelled() then
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
local function StartTickerRangeCheck()
  if rangeCheckTicker == nil or rangeCheckTicker:IsCancelled() then
    rangeCheckTicker = C_Timer.NewTicker(
      RGGM_CONSTANTS.RANGE_CHECK_UPDATE_INTERVAL, mod.gearBar.UpdateSpellRange)
      mod.logger.LogInfo(me.tag, "Started 'StartTickerRangeCheck'")
  end
end

--[[
  Stop the repeating update ticker for rangeCheck
]]--
local function StopTickerRangeCheck()
  if rangeCheckTicker then
    rangeCheckTicker:Cancel()
    mod.logger.LogInfo(me.tag, "Stopped 'StopTickerRangeCheck'")
  end
end

--[[
  @param {number} gearBarId
]]--
function me.RegisterForTickerRangeCheck(gearBarId)
  for i = 1, #tickerRangeCheckSubscribers do
    if tickerRangeCheckSubscribers[i] == gearBarId then
      mod.logger.LogDebug(me.tag, "GearBar with id: " .. gearBarId .. " is already registered for range check")
      return
    end
  end

  table.insert(tickerRangeCheckSubscribers, gearBarId)

  if #tickerRangeCheckSubscribers == 1 then
    StartTickerRangeCheck()
  end
end

--[[
  @param {number} gearBarId
]]--
function me.UnregisterForTickerRangeCheck(gearBarId)
  for i = 1, #tickerRangeCheckSubscribers do
    if tickerRangeCheckSubscribers[i] == gearBarId then
      table.remove(tickerRangeCheckSubscribers, gearBarId)
      break
    end
  end

  if #tickerRangeCheckSubscribers == 0 then
    StopTickerRangeCheck()
  end
end
