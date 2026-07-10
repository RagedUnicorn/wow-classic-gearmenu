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

-- luacheck: globals SLASH_GEARMENU1 SLASH_GEARMENU2 SlashCmdList ReloadUI

local mod = rggm
local me = {}
mod.cmd = me

me.tag = "Cmd"

--[[
  Registry mapping a sub-command name (or alias) to its entry:

  {
    ["handler"] = function(args),
      handler invoked with the remaining arguments (command name removed)
    ["helpTextKey"] = string or nil
      localization key printed by the generated help output
  }

  Aliases share the entry of their primary command. Only primary commands are tracked in
  commandOrder, so the help output lists each command once, in registration order.
]]--
local commandRegistry = {}
local commandOrder = {}

-- forward declarations
local HandleSlashCommand
local ParseArguments
local ShowInfoMessage

--[[
  Setup slash command handler
]]--
function me.SetupSlashCmdList()
  SLASH_GEARMENU1 = "/rggm"
  SLASH_GEARMENU2 = "/gearmenu"

  SlashCmdList["GEARMENU"] = HandleSlashCommand
end

--[[
  Register a sub-command. The help output is generated from the registry, so a registered
  command with a helpTextKey automatically shows up in `/rggm help`.

  @param {string} command
    The sub-command name
  @param {function} handler
    Invoked with the remaining arguments as a table when the sub-command is dispatched
  @param {string} helpTextKey
    Optional localization key (rggm.L) for the command's help line
  @param {table} aliases
    Optional list of alternative names dispatching to the same handler
]]--
function me.RegisterCommand(command, handler, helpTextKey, aliases)
  if type(command) ~= "string" or type(handler) ~= "function" then
    mod.logger.LogError(me.tag, "Invalid command registration - missing command or handler")

    return
  end

  if commandRegistry[command] == nil then
    table.insert(commandOrder, command)
  end

  commandRegistry[command] = {
    ["handler"] = handler,
    ["helpTextKey"] = helpTextKey
  }

  if aliases ~= nil then
    for _, alias in ipairs(aliases) do
      commandRegistry[alias] = commandRegistry[command]
    end
  end

  mod.logger.LogDebug(me.tag, "Registered command: " .. command)
end

--[[
  Handle slash command input

  @param {string} msg
    The raw command arguments
]]--
HandleSlashCommand = function(msg)
  local args = ParseArguments(msg)

  if #args == 0 or args[1] == "help" then
    ShowInfoMessage()

    return
  end

  local entry = commandRegistry[args[1]]

  if entry ~= nil then
    table.remove(args, 1) -- drop the command name; handlers receive the remaining arguments
    entry.handler(args)
  else
    mod.logger.PrintUserError(rggm.L["invalid_argument"])
  end
end

--[[
  Parse command arguments from a string

  @param {string} msg
    The raw command string

  @return {table}
    Array of whitespace-separated arguments
]]--
ParseArguments = function(msg)
  local args = {}

  mod.logger.LogDebug(me.tag, "/rggm passed argument: " .. msg)

  -- parse arguments by whitespace
  for arg in string.gmatch(msg, "%S+") do
    table.insert(args, arg)
  end

  return args
end

--[[
  Print cmd options for addon - generated from the command registry
]]--
ShowInfoMessage = function()
  print(rggm.L["info_title"])

  for _, command in ipairs(commandOrder) do
    local helpTextKey = commandRegistry[command].helpTextKey

    if helpTextKey ~= nil then
      print(rggm.L[helpTextKey])
    end
  end
end

-- built-in commands
me.RegisterCommand("reload", function()
  ReloadUI()
end, "reload", { "rl" })

me.RegisterCommand("opt", function()
  mod.addonConfiguration.OpenMainCategory()
end, "opt")
