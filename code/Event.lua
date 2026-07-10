--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

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

mod.event = me

me.tag = "Event"

--[[
  Central event bus. Core registers its handlers here keyed by event name, then
  hands the bus the main frame so it can subscribe to those events. The frame's
  OnEvent script delegates straight to Dispatch, which logs the event once,
  applies the readiness gate, and invokes the matching handler.

  This keeps the event surface declared in one place (Core) while removing the
  flat if/elseif dispatch chain and the per-branch initialization flag.
]]--

-- main frame reference, set in Setup
local frame
-- registered handlers keyed by event name: eventName -> { fn = handler, gated = boolean, unit = string|nil }
local handlers = {}
-- gated handlers are suppressed until initialization completes and SetReady is called
local isReady = false

--[[
  Register a handler for one or more events.

  @param {string|table} events
    a single event name or an array of event names sharing the handler
  @param {function} handler
    invoked with the event varargs when the event fires
  @param {table} opts
    optional; opts.gated = true skips the handler until SetReady is called
    optional; opts.unit = "<unitId>" subscribes via RegisterUnitEvent so the
      client only delivers the event for that unit - use for high-frequency
      UNIT_* events to avoid handler invocations for irrelevant units
]]--
function me.Register(events, handler, opts)
  local gated = opts and opts.gated or false
  local unit = opts and opts.unit or nil

  if type(events) == "table" then
    for _, eventName in ipairs(events) do
      handlers[eventName] = { fn = handler, gated = gated, unit = unit }
    end
  else
    handlers[events] = { fn = handler, gated = gated, unit = unit }
  end
end

--[[
  Wire the bus to the main frame and subscribe to every registered event.
  Call this from Core.OnLoad after all handlers are registered.

  @param {table} mainFrame
]]--
function me.Setup(mainFrame)
  frame = mainFrame

  for eventName, entry in pairs(handlers) do
    if entry.unit then
      frame:RegisterUnitEvent(eventName, entry.unit)
    else
      frame:RegisterEvent(eventName)
    end
  end
end

--[[
  Mark initialization complete so gated handlers begin firing. Replaces the
  per-Core initializationDone flag.
]]--
function me.SetReady()
  isReady = true
end

--[[
  Dispatch an event to its registered handler. Invoked from the frame's OnEvent
  script. Unknown events are ignored; gated handlers are suppressed until ready.

  @param {string} eventName
  @param {vararg} ...
]]--
function me.Dispatch(eventName, ...)
  local entry = handlers[eventName]

  if not entry then return end

  if entry.gated and not isReady then
    mod.logger.LogDebug(me.tag, "Ignoring " .. eventName .. " - addon not yet initialized")

    return
  end

  mod.logger.LogEvent(me.tag, eventName)
  entry.fn(...)
end
