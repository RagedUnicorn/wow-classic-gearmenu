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
  Spec for the out of combat behaviour of the gearBar configuration menu in
  gui/GearBarConfigurationMenu.lua: the gearBar limit, the settings category every gearBar gets,
  the name popup and the gearBar list that keeps one row per configured gearBar.

  The combat guards of creating and deleting a gearBar are covered by
  GearBarConfigurationMenuCombatGuardSpec. Here the collaborators are recorder stubs and
  CreateFrame hands out fake widgets that keep their text, shown state, scripts and height.
]]--

local wowStubs = require("WowStubs")

describe("GearBarConfigurationMenu", function()
  local menu
  local previous
  local restore
  local popupDialogs
  local gearBars
  local calls

  --[[
    A fake widget: keeps text, height, scripts and shown state and accepts any other call

    @return {table}
  ]]--
  local function fakeWidget()
    local widget = { shown = true, scripts = {} }
    local methods = {
      Show = function(self) self.shown = true end,
      Hide = function(self) self.shown = false end,
      SetText = function(self, text) self.text = text end,
      GetText = function(self) return self.text end,
      SetHeight = function(self, height) self.height = height end,
      SetScript = function(self, scriptName, handler) self.scripts[scriptName] = handler end,
      CreateFontString = function() return fakeWidget() end,
      GetFontString = function() return fakeWidget() end,
      GetStringWidth = function() return 0 end
    }

    return setmetatable(widget, {
      __index = function(_, method)
        return methods[method] or function() end
      end
    })
  end

  --[[
    @param {number} amount

    @return {table}
      gearBars with ids 1..amount
  ]]--
  local function configuredGearBars(amount)
    local configured = {}

    for id = 1, amount do
      configured[id] = { id = id, displayName = "Bar " .. id }
    end

    return configured
  end

  local function newListContainer()
    return { rows = {}, content = fakeWidget() }
  end

  before_each(function()
    gearBars = {}
    popupDialogs = {}
    calls = { categories = {}, visualUpdates = {}, userErrors = 0 }

    previous = {
      gearBarConfigurationMenu = rggm.gearBarConfigurationMenu,
      gearBarConfigurationSubMenu = rggm.gearBarConfigurationSubMenu,
      gearBarManager = rggm.gearBarManager,
      gearBar = rggm.gearBar,
      addonConfiguration = rggm.addonConfiguration,
      logger = rggm.logger,
      L = rggm.L
    }

    rggm.L = {}
    rggm.gearBarManager = {
      GetGearBars = function() return gearBars end,
      AddGearBar = function(name)
        local gearBar = { id = #gearBars + 1, displayName = name }

        gearBars[#gearBars + 1] = gearBar

        return gearBar
      end
    }
    rggm.gearBar = {
      BuildGearBar = function() end,
      UpdateGearBarVisual = function(gearBar)
        calls.visualUpdates[#calls.visualUpdates + 1] = gearBar.id
      end
    }
    rggm.addonConfiguration = {
      GetGearBarSubCategory = function() return "gearBarSubCategory" end,
      BuildCategory = function(frameName, parent, name, callback)
        local entry = {
          frameName = frameName, parent = parent, name = name, callback = callback,
          category = {}, menu = {}
        }

        calls.categories[#calls.categories + 1] = entry

        return entry.category, entry.menu
      end
    }
    rggm.gearBarConfigurationSubMenu = {
      GearBarConfigurationCategoryContainerOnCallback = function() end
    }
    rggm.logger = {
      LogDebug = function() end,
      PrintUserError = function() calls.userErrors = calls.userErrors + 1 end
    }

    restore = wowStubs.install({
      InCombatLockdown = wowStubs.stubs.InCombatLockdown(false),
      StaticPopupDialogs = popupDialogs,
      StaticPopup_Show = function() end,
      CreateFrame = function() return fakeWidget() end
    })

    dofile("gui/GearBarConfigurationMenu.lua")
    menu = rggm.gearBarConfigurationMenu
  end)

  after_each(function()
    restore()

    for name, module in pairs(previous) do
      rggm[name] = module
    end
  end)

  describe("CreateNewGearBar", function()
    it("adds a settings category for the new gearBar and draws it", function()
      menu.CreateNewGearBar("Tanking")

      local entry = calls.categories[1]

      assert.are.equal(1, #calls.categories)
      assert.are.equal(RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_SUB_CONFIG_FRAME .. 1, entry.frameName)
      assert.are.equal("gearBarSubCategory", entry.parent)
      assert.are.equal("Tanking", entry.name)
      assert.are.equal(
        rggm.gearBarConfigurationSubMenu.GearBarConfigurationCategoryContainerOnCallback, entry.callback)
      assert.are.equal(1, entry.category.gearBarId)
      assert.are.equal(1, entry.menu.gearBarId)
      assert.are.same({ 1 }, calls.visualUpdates)
    end)

    it("refuses a gearBar beyond the maximum and tells the user", function()
      gearBars = configuredGearBars(RGGM_CONSTANTS.MAX_GEAR_BARS)

      menu.CreateNewGearBar("One too many")

      assert.are.equal(RGGM_CONSTANTS.MAX_GEAR_BARS, #gearBars)
      assert.are.equal(0, #calls.categories)
      assert.are.equal(1, calls.userErrors)
    end)

    it("still allows the last gearBar below the maximum", function()
      gearBars = configuredGearBars(RGGM_CONSTANTS.MAX_GEAR_BARS - 1)

      menu.CreateNewGearBar("Last one")

      assert.are.equal(RGGM_CONSTANTS.MAX_GEAR_BARS, #gearBars)
      assert.are.equal(0, calls.userErrors)
    end)
  end)

  describe("LoadConfiguredGearBars", function()
    it("adds a settings category tagged with the gearBar id for every configured gearBar", function()
      gearBars = configuredGearBars(3)

      menu.LoadConfiguredGearBars()

      assert.are.equal(3, #calls.categories)

      for index, entry in ipairs(calls.categories) do
        assert.are.equal("Bar " .. index, entry.name)
        assert.are.equal(index, entry.category.gearBarId)
        assert.are.equal(index, entry.menu.gearBarId)
      end
    end)
  end)

  describe("name popup", function()
    local function editBoxWithText(text)
      local button1 = fakeWidget()
      local editBox = fakeWidget()

      button1.enabled = true
      button1.Enable = function(self) self.enabled = true end
      button1.Disable = function(self) self.enabled = false end
      editBox.text = text
      editBox.GetParent = function() return { GetButton1 = function() return button1 end } end

      return editBox, button1
    end

    it("enables the accept button only while a name is entered", function()
      local dialog = popupDialogs["RGGM_CHOOSE_GEAR_BAR_NAME"]
      local editBox, button1 = editBoxWithText("")

      dialog.EditBoxOnTextChanged(editBox)
      assert.is_false(button1.enabled)

      editBox.text = "Tanking"
      dialog.EditBoxOnTextChanged(editBox)
      assert.is_true(button1.enabled)
    end)

    it("clears the name and disables the accept button when shown", function()
      local editBox, button1 = editBoxWithText("previous name")

      popupDialogs["RGGM_CHOOSE_GEAR_BAR_NAME"].OnShow({
        GetEditBox = function() return editBox end,
        GetButton1 = function() return button1 end
      })

      assert.are.equal("", editBox.text)
      assert.is_false(button1.enabled)
    end)

    it("limits the name to the gearBar name length", function()
      assert.are.equal(RGGM_CONSTANTS.GEAR_BAR_NAME_MAX_LENGTH, popupDialogs["RGGM_CHOOSE_GEAR_BAR_NAME"].maxLetters)
    end)

    it("creates a gearBar with the entered name and refreshes the list on accept", function()
      local refreshed = 0
      local editBox = editBoxWithText("Healing")

      menu.GearBarListOnUpdate = function() refreshed = refreshed + 1 end

      popupDialogs["RGGM_CHOOSE_GEAR_BAR_NAME"].OnAccept({ GetEditBox = function() return editBox end })

      assert.are.equal("Healing", gearBars[1].displayName)
      assert.are.equal(1, refreshed)
    end)
  end)

  describe("GearBarListOnUpdate", function()
    it("shows one row per gearBar with its name and the id its remove button deletes", function()
      local listContainer = newListContainer()

      gearBars = configuredGearBars(2)
      menu.GearBarListOnUpdate(listContainer)

      assert.are.equal(2, #listContainer.rows)

      for index, row in ipairs(listContainer.rows) do
        assert.is_true(row.shown)
        assert.are.equal("Bar " .. index, row.gearBarName.text)
        assert.are.equal(index, row.removeGearBarButton.id)
      end

      assert.are.equal(2 * RGGM_CONSTANTS.GEAR_BAR_LIST_ROW_HEIGHT, listContainer.content.height)
    end)

    it("reuses the rows and hides the surplus when gearBars were removed", function()
      local listContainer = newListContainer()

      gearBars = configuredGearBars(3)
      menu.GearBarListOnUpdate(listContainer)

      local firstRow = listContainer.rows[1]

      gearBars = { { id = 3, displayName = "Bar 3" } }
      menu.GearBarListOnUpdate(listContainer)

      assert.are.equal(3, #listContainer.rows)
      assert.are.equal(firstRow, listContainer.rows[1])
      assert.are.equal("Bar 3", firstRow.gearBarName.text)
      assert.are.equal(3, firstRow.removeGearBarButton.id)
      assert.is_false(listContainer.rows[2].shown)
      assert.is_false(listContainer.rows[3].shown)
    end)

    it("keeps the list content at least one pixel high without gearBars", function()
      local listContainer = newListContainer()

      menu.GearBarListOnUpdate(listContainer)

      assert.are.equal(0, #listContainer.rows)
      assert.are.equal(1, listContainer.content.height)
    end)
  end)
end)
