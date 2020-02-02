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

-- luacheck: globals GetAddOnMetadata UIErrorsFrame

local mod = rggm
local me = {}

mod.logger = me

me.tag = "Logger"

--[[
  LogLevels {number}

  debug - 4
  info - 3
  warn - 2
  error - 1
  event - 0
]]--
me.debug = 4
me.info = 3
me.warn = 2
me.error = 1
me.event = 0

me.logLevel = RGGM_ENVIRONMENT.LOG_LEVEL

--[[
  LogEvents {boolean}

  Whether to log events or not
]]--
me.logEvent = RGGM_ENVIRONMENT.LOG_EVENT

--[[
  LogLevel colors
]]--
me.colors = {}
me.colors.error = "|cfff00000"  -- red
me.colors.warn = "|cffffce01"   -- yellow
me.colors.info = "|cff18f3ff"   -- blue
me.colors.debug = "|cff7413d9"  -- magenta
me.colors.event = "|cff1cdb4f"  -- green

local userMessageTag = "User"

--[[
  Writes string message to the default chat frame

  @param {string} levelColor
  @param {string} tag
  @param {string} message
]]--
local PrintLogMessage = function(levelColor, tag, message)
  if tag == nil then
    tag = "Unknown"
  end

  if not mod.filter.ShouldFilterTag(tag) then
    print(levelColor .. GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Title") .. ":" .. tag .. " - " .. message)
  end
end

--[[
  @param {string} tag
  @param {string} message
]]--
function me.LogDebug(tag, message)
  if me.logLevel == me.debug then

    PrintLogMessage(me.colors.debug, tag, message)
  end
end

--[[
  @param {string} tag
  @param {string} message
]]--
function me.LogInfo(tag, message)
  if me.logLevel >= me.info then
    PrintLogMessage(me.colors.info, tag, message)
  end
end

--[[
  @param {string} tag
  @param {string} message
]]--
function me.LogWarn(tag, message)
  if me.logLevel >= me.warn then
    PrintLogMessage(me.colors.warn, tag, message)
  end
end

--[[
  @param {string} tag
  @param {string} message
]]--
function me.LogError(tag, message)
  if me.logLevel >= me.error then
    PrintLogMessage(me.colors.error, tag, message)
  end
end

--[[
  @param {string} tag
  @param {string} message
]]--
function me.LogEvent(tag, message)
  if me.logEvent then
    PrintLogMessage(me.colors.event, tag, message)
  end
end

--[[
  Display a message in the standard error frame

  @param {string} msg
]]--
function me.PrintUserError(msg)
  UIErrorsFrame:AddMessage(msg, 1.0, 0.0, 0.0, 53, 5)
end

function me.PrintUserChatError(message)
  PrintLogMessage(me.colors.error, userMessageTag, message)
end
