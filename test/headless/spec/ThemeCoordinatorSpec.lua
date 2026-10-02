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
  Spec for gui/ThemeCoordinator.lua, the bridge that routes slot creation and the slot handlers to
  the configured theme (gui/ThemeClassic.lua or gui/ThemeCustom.lua). UpdateTheme picks the theme
  from the configuration; every routed call forwards its arguments to that theme and returns its
  result, and a call the theme does not implement is a logged no-op. Both themes are recording fakes.
]]--

-- Lua 5.1 keeps unpack global, the busted runtime only has table.unpack
local unpackArguments = unpack or rawget(table, "unpack")

-- the routed calls and the arguments they forward
local ROUTED_CALLS = {
  { "CreateGearSlot", { "gearBarFrame", "gearBar", 3 } },
  { "CreateChangeSlot", { "changeMenuFrame", 2 } },
  { "CreateTrinketSlot", { "trinketMenuFrame", 5 } },
  { "UpdateSlotTextureAttributes", { "slot", 40 } },
  { "GearSlotOnClick", { "self", "LeftButton" } },
  { "GearSlotOnEnter", { "self" } },
  { "GearSlotOnLeave", { "self" } },
  { "ChangeSlotOnClick", { "self", "RightButton" } },
  { "ChangeSlotOnEnter", { "self" } },
  { "ChangeSlotOnLeave", { "self" } },
  { "ChangeMenuSlotReset", { "changeMenuSlot" } },
  { "TrinketMenuSlotOnClick", { "self", "LeftButton" } },
  { "TrinketMenuSlotOnEnter", { "self" } },
  { "TrinketMenuSlotOnLeave", { "self" } },
  { "TrinketMenuSlotReset", { "trinketMenuSlot" } }
}

describe("ThemeCoordinator", function()
  local coordinator
  local uiTheme
  local calls
  local warnings
  local previous

  --[[
    A theme that records every call as { theme, function, arguments... } and returns a marker

    @param {string} themeName

    @return {table}
  ]]--
  local function FakeTheme(themeName)
    local theme = {}

    for _, routed in ipairs(ROUTED_CALLS) do
      local functionName = routed[1]

      theme[functionName] = function(...)
        calls[#calls + 1] = { themeName, functionName, ... }

        return themeName .. "." .. functionName
      end
    end

    return theme
  end

  before_each(function()
    uiTheme = RGGM_CONSTANTS.UI_THEME_CUSTOM
    calls = {}
    warnings = {}

    previous = {
      themeCoordinator = rggm.themeCoordinator,
      themeClassic = rggm.themeClassic,
      themeCustom = rggm.themeCustom,
      configuration = rggm.configuration,
      logger = rggm.logger
    }

    rggm.themeClassic = FakeTheme("classic")
    rggm.themeCustom = FakeTheme("custom")
    rggm.configuration = { GetUiTheme = function() return uiTheme end }
    rggm.logger = {
      LogInfo = function() end,
      LogWarn = function(_, message) warnings[#warnings + 1] = message end
    }

    dofile("gui/ThemeCoordinator.lua")
    coordinator = rggm.themeCoordinator
  end)

  after_each(function()
    for name, module in pairs(previous) do
      rggm[name] = module
    end
  end)

  for _, routed in ipairs(ROUTED_CALLS) do
    local functionName, arguments = routed[1], routed[2]

    it("routes " .. functionName .. " with its arguments to the custom theme", function()
      local expected = { "custom", functionName }

      for index, argument in ipairs(arguments) do
        expected[index + 2] = argument
      end

      coordinator.UpdateTheme()

      local result = coordinator[functionName](unpackArguments(arguments))

      assert.are.same({ expected }, calls)

      if functionName:find("^Create") then
        assert.are.equal("custom." .. functionName, result)
      end
    end)
  end

  it("routes to the classic theme once it is configured", function()
    uiTheme = RGGM_CONSTANTS.UI_THEME_CLASSIC
    coordinator.UpdateTheme()

    coordinator.GearSlotOnEnter("self")

    assert.are.same({ { "classic", "GearSlotOnEnter", "self" } }, calls)
  end)

  it("switches the routing when the theme is updated again", function()
    coordinator.UpdateTheme()
    uiTheme = RGGM_CONSTANTS.UI_THEME_CLASSIC
    coordinator.UpdateTheme()

    coordinator.GearSlotOnLeave("self")

    assert.are.equal("classic", calls[1][1])
  end)

  it("keeps the current theme and warns about an unknown configured theme", function()
    coordinator.UpdateTheme()
    uiTheme = 99
    coordinator.UpdateTheme()

    coordinator.GearSlotOnLeave("self")

    assert.are.same({ "Invalid uiTheme found" }, warnings)
    assert.are.equal("custom", calls[1][1])
  end)

  it("does nothing for a call the theme does not implement", function()
    rggm.themeCustom.ChangeMenuSlotReset = nil
    coordinator.UpdateTheme()

    assert.has_no.errors(function() coordinator.ChangeMenuSlotReset("changeMenuSlot") end)
    assert.are.same({}, calls)
  end)
end)
