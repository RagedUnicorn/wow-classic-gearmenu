--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

--[[
  Opt-in registry of WoW-global stubs.

  This is deliberately NOT a full Blizzard API mock. A spec requires this module and pulls only the
  stubs it needs, installs them onto the global table for the duration of the test, then restores
  the previous values so nothing leaks across specs. The Bootstrap helper prepends test/headless to
  package.path so this resolves as `require("WowStubs")`.

  Usage:
    local wowStubs = require("WowStubs")

    local restore
    before_each(function()
      restore = wowStubs.install({
        InCombatLockdown = wowStubs.stubs.InCombatLockdown(false),
        C_LossOfControl  = wowStubs.stubs.C_LossOfControl({}),
      })
    end)
    after_each(function() restore() end)

  `install` also accepts any ad-hoc stub the registry does not provide, e.g.
    wowStubs.install({ SomeApi = function() return 42 end })
]]--

local unpack = table.unpack or unpack -- luacheck: ignore

local M = {}

--[[
  Install a table of name -> value stubs onto the global table.

  @param {table} stubs
    map of global name to stub value (function, table, ...)

  @return {function}
    a restore function that puts the previous global values back (including nil for globals that
    did not previously exist). Call it from after_each.
]]--
function M.install(stubs)
  local previous = {}
  local names = {}

  for name, value in pairs(stubs) do
    previous[name] = _G[name]
    names[#names + 1] = name
    _G[name] = value
  end

  return function()
    for _, name in ipairs(names) do
      _G[name] = previous[name]
    end
  end
end

--[[
  Ready-made stub builders for the WoW globals the near-term pilot specs touch. Each returns a fresh
  stub configured by its arguments; add more here as new specs need them.
]]--
M.stubs = {}

--[[
  InCombatLockdown() -> boolean (CombatQueue.ProcessQueue)

  @param {boolean} inCombat
  @return {function}
]]--
function M.stubs.InCombatLockdown(inCombat)
  return function()
    return inCombat and true or false
  end
end

--[[
  C_LossOfControl namespace (CombatQueue.UpdateEquipChangeBlockStatus). `events` is the list of
  active loss-of-control data entries to report.

  @param {table} events
  @return {table}
]]--
function M.stubs.C_LossOfControl(events)
  events = events or {}

  return {
    GetActiveLossOfControlDataCount = function()
      return #events
    end,
    GetActiveLossOfControlData = function(index)
      return events[index]
    end
  }
end

--[[
  C_AddOns namespace (Logger.PrintLogMessage, Configuration.SetAddonVersion). `metadata` maps the
  requested key (e.g. "Title", "Version") to the value to return.

  @param {table} metadata
  @return {table}
]]--
function M.stubs.C_AddOns(metadata)
  metadata = metadata or {}

  return {
    GetAddOnMetadata = function(_, key)
      return metadata[key]
    end
  }
end

--[[
  C_Item namespace - the namespaced GetItemInfo / GetItemInfoInstant used across the item modules.
  `results` maps an itemId/itemLink to a list of return values for GetItemInfo; `instantResults`
  does the same for the cache-free GetItemInfoInstant (whose 4th return is the equip slot).

  @param {table} results
  @param {table} instantResults
  @return {table}
]]--
function M.stubs.C_Item(results, instantResults)
  results = results or {}
  instantResults = instantResults or {}

  return {
    GetItemInfo = function(item)
      local values = results[item] or {}
      return unpack(values)
    end,
    GetItemInfoInstant = function(item)
      local values = instantResults[item] or {}
      return unpack(values)
    end
  }
end

--[[
  UIErrorsFrame (Logger.PrintUserError) - captures messages added to it.

  @return {table}
]]--
function M.stubs.UIErrorsFrame()
  local frame = { messages = {} }

  function frame:AddMessage(message, ...)
    self.messages[#self.messages + 1] = { message = message, ... }
  end

  return frame
end

--[[
  GetLocale() -> string (localization files branch on this at load time).

  @param {string} locale
  @return {function}
]]--
function M.stubs.GetLocale(locale)
  return function()
    return locale or "enUS"
  end
end

return M
