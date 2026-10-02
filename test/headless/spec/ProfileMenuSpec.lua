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
  Spec for the Profiles settings page in gui/ProfileMenu.lua: the profile list, the greyed-out
  state of the action buttons, and the flows behind the buttons and StaticPopups - create, load,
  rename, delete, reset, export and import - with their validation, the Default-profile guard and
  the key-binding dance around every path that applies a snapshot: the bindings of the live
  gearBars are cleared before and the incoming ones applied after.

  code/Profile.lua is replaced by an in-memory fake (ProfileSpec covers the real store), so the
  spec pins what the menu asks of it and in which order. The page is built against recording
  widget stubs; the buttons are found by their frame names and clicked through their OnClick
  script, the popups are driven through the StaticPopupDialogs entries the page registers.
  gui/ProfileMenu.lua is re-dofile'd per test because it guards the build with file-local state.
]]--

local wowStubs = require("WowStubs")

local DEFAULT = "Default"

describe("ProfileMenu", function()
  local frames
  local callLog
  local userErrors
  local userMessages
  local shownPopups
  -- the StaticPopupDialogs table the page registers its popups in
  local popupDialogs
  local profiles
  local state
  local previous
  local restore

  local function noop() end

  --[[
    A recording widget: keeps its scripts, text, enabled and shown state, and accepts the layout
    calls the page makes without recording them

    @param {string} name

    @return {table}
  ]]--
  local function Widget(name)
    local widget = { name = name, scripts = {}, text = "", enabled = true, shown = true }

    for _, method in ipairs({
      "SetHeight", "SetWidth", "SetSize", "SetPoint", "SetAllPoints", "SetColorTexture", "SetJustifyH",
      "SetFont", "SetFontObject", "ClearFocus"
    }) do
      widget[method] = noop
    end

    function widget:SetScript(scriptName, handler) self.scripts[scriptName] = handler end
    function widget:SetText(text) self.text = text end
    function widget:GetText() return self.text end
    function widget:SetEnabled(enabled) self.enabled = enabled end
    function widget:Show() self.shown = true end
    function widget:Hide() self.shown = false end
    function widget:IsShown() return self.shown end
    function widget:HighlightText() self.highlighted = true end
    function widget:SetFocus() self.focused = true end
    function widget:SetMaxLetters(maxLetters) self.maxLetters = maxLetters end
    widget.CreateTexture = function() return Widget() end
    widget.CreateFontString = function() return Widget() end

    return widget
  end

  local function CreateFrame(_, name, _, template)
    local frame = Widget(name)

    if template == "InputScrollFrameTemplate" then
      frame.EditBox = Widget()
    end

    frames.created = frames.created + 1

    if name then frames[name] = frame end

    return frame
  end

  local function log(entry)
    callLog[#callLog + 1] = entry
  end

  local function sortedNames()
    local names = {}

    for name in pairs(profiles) do names[#names + 1] = name end

    table.sort(names)

    return names
  end

  --[[
    In-memory stand-in for code/Profile.lua. The mutating calls are logged so the spec can
    assert the order the menu runs them in.
  ]]--
  local function FakeProfile()
    return {
      ListProfiles = sortedNames,
      ProfileExists = function(name) return profiles[name] ~= nil end,
      IsDefaultProfile = function(name) return name == DEFAULT end,
      IsNameTooLong = function(name) return #name > RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH end,
      GetActiveProfileName = function() return state.active end,
      GetProfile = function(name) return profiles[name] end,
      CreateProfile = function(name)
        log("profile.CreateProfile " .. name)
        profiles[name] = {}
        state.active = name
      end,
      SwitchProfile = function(name)
        log("profile.SwitchProfile " .. name)

        if state.switchSucceeds then state.active = name end

        return state.switchSucceeds
      end,
      ResetActiveProfile = function() log("profile.ResetActiveProfile") end,
      DeleteProfile = function(name)
        log("profile.DeleteProfile " .. name)

        if name == DEFAULT or not profiles[name] then return false end

        profiles[name] = nil

        if state.active == name then
          state.active = DEFAULT
          return true, true
        end

        return true, false
      end,
      RenameProfile = function(oldName, newName)
        log("profile.RenameProfile " .. oldName .. " " .. newName)
        profiles[newName] = profiles[oldName]
        profiles[oldName] = nil

        if state.active == oldName then state.active = newName end

        return true
      end,
      SaveActiveProfile = function() log("profile.SaveActiveProfile") end,
      ExportString = function(_, name)
        log("profile.ExportString " .. name)
        return "GearMenu1:" .. name
      end,
      ImportString = function(text)
        state.importedText = text
        return state.importEnvelope, state.importErrorKey
      end,
      SaveProfile = function(name, payload)
        log("profile.SaveProfile " .. name)
        profiles[name] = payload
      end
    }
  end

  local function FakeUiHelper()
    return {
      CalculateGridPosition = function(index, _, size) return 0, (index - 1) * size end,
      SetColor = function(fontString, color) fontString.color = color end,
      ApplyBorderBackdrop = noop,
      CreateScrollList = function() return { content = Widget("content") } end,
      CreateFramePool = function(factory)
        local pool = { frames = {} }

        function pool.Acquire(index)
          pool.frames[index] = pool.frames[index] or factory(index)
          return pool.frames[index]
        end

        function pool.ReleaseFrom(index)
          for position = index, #pool.frames do pool.frames[position]:Hide() end
        end

        function pool.ForEach(callback)
          for _, frame in ipairs(pool.frames) do callback(frame) end
        end

        frames.rowPool = pool

        return pool
      end
    }
  end

  local function build()
    rggm.profileMenu.BuildUi(Widget("panel"))
  end

  local function click(buttonName)
    frames[buttonName].scripts.OnClick(frames[buttonName])
  end

  --[[
    Show a registered StaticPopup the way the client does: a popup frame with the given data
    and an EditBox whose parent is the popup, then run its OnShow

    @param {string} popupName
    @param {any} data

    @return {table} popup
    @return {table} dialog
  ]]--
  local function openPopup(popupName, data)
    local dialog = popupDialogs[popupName]
    local popup = Widget(popupName)

    popup.data = data
    popup.EditBox = Widget()
    popup.EditBox.GetParent = function() return popup end

    if dialog.OnShow then dialog.OnShow(popup) end

    return popup, dialog
  end

  --[[
    Type a name into a naming popup and press Accept

    @param {string} popupName
    @param {any} data
    @param {string} text
  ]]--
  local function acceptWithName(popupName, data, text)
    local popup, dialog = openPopup(popupName, data)

    popup.EditBox:SetText(text)
    dialog.OnAccept(popup)
  end

  local function confirm(popupName, data)
    local popup, dialog = openPopup(popupName, data)

    dialog.OnAccept(popup)
  end

  local function rows()
    local visible = {}

    for _, row in ipairs(frames.rowPool.frames) do
      if row:IsShown() then visible[#visible + 1] = row end
    end

    return visible
  end

  local function rowFor(name)
    for _, row in ipairs(rows()) do
      if row.profileName == name then return row end
    end
  end

  local function editBox()
    return frames[RGGM_CONSTANTS.ELEMENT_PROFILE_STRING_SCROLL_FRAME].EditBox
  end

  local function button(constantName)
    return frames[RGGM_CONSTANTS[constantName]]
  end

  before_each(function()
    frames = { created = 0 }
    callLog = {}
    userErrors = {}
    userMessages = {}
    shownPopups = {}
    popupDialogs = {}
    profiles = { [DEFAULT] = {}, Healing = {}, Tanking = {} }
    state = { active = DEFAULT, switchSucceeds = true }

    previous = {
      profileMenu = rggm.profileMenu,
      profile = rggm.profile,
      keyBind = rggm.keyBind,
      gearBarManager = rggm.gearBarManager,
      logger = rggm.logger,
      uiHelper = rggm.uiHelper,
      L = rggm.L
    }

    rggm.profile = FakeProfile()
    rggm.uiHelper = FakeUiHelper()
    -- the live gearBars ClearGearBarKeyBindings has to receive
    local liveGearBars = { { id = 1, slots = {} } }

    rggm.gearBarManager = { GetGearBars = function() return liveGearBars end }
    rggm.keyBind = {
      ClearGearBarKeyBindings = function(gearBars)
        assert.are.equal(liveGearBars, gearBars)
        log("keyBind.ClearGearBarKeyBindings")
      end,
      ApplyGearBarKeyBindings = function() log("keyBind.ApplyGearBarKeyBindings") end
    }
    rggm.logger = {
      PrintUserError = function(message) userErrors[#userErrors + 1] = message end,
      PrintUserMessage = function(message) userMessages[#userMessages + 1] = message end
    }
    -- every key reads "<key>:%s" so a message names both its key and its argument
    rggm.L = setmetatable({}, { __index = function(_, key) return key .. ":%s" end })

    restore = wowStubs.install({
      CreateFrame = CreateFrame,
      STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF",
      StaticPopupDialogs = popupDialogs,
      StaticPopup_Show = function(popupName, textArg1, textArg2, data)
        shownPopups[#shownPopups + 1] = {
          name = popupName, textArg1 = textArg1, textArg2 = textArg2, data = data
        }
      end,
      -- the client's Lua 5.1 global the page unpacks its SetPoint anchors with
      unpack = unpack or rawget(table, "unpack"),
      ReloadUI = function() log("ReloadUI") end
    })

    dofile("gui/ProfileMenu.lua")
  end)

  after_each(function()
    restore()

    for name, module in pairs(previous) do
      rggm[name] = module
    end
  end)

  describe("profile list", function()
    it("lists every profile and marks the active one", function()
      state.active = "Healing"
      build()

      local visible = rows()

      assert.are.equal(3, #visible)
      assert.are.same({ DEFAULT, "Healing", "Tanking" },
        { visible[1].profileName, visible[2].profileName, visible[3].profileName })
      assert.are.equal("profile_active_suffix:Healing", rowFor("Healing").label.text)
      assert.are.equal(RGGM_CONSTANTS.COLOR.TITLE_GOLD, rowFor("Healing").label.color)
      assert.are.equal("Tanking", rowFor("Tanking").label.text)
      assert.are.equal(RGGM_CONSTANTS.COLOR.BODY, rowFor("Tanking").label.color)
    end)

    it("selects a profile when its row is clicked and highlights only that row", function()
      build()

      local row = rowFor("Tanking")
      row.scripts.OnClick(row)

      assert.are.equal("Tanking", rggm.profileMenu.selectedProfile)
      assert.is_true(rowFor("Tanking").selectedTexture:IsShown())
      assert.is_false(rowFor("Healing").selectedTexture:IsShown())
      assert.is_false(rowFor(DEFAULT).selectedTexture:IsShown())
    end)

    it("builds the page once and refreshes the list on every show", function()
      build()

      local created = frames.created
      profiles.Pvp = {}

      build()

      assert.are.equal(4, #rows())
      assert.are.equal(created + 1, frames.created) -- only the new row
    end)

    it("drops a selection whose profile no longer exists", function()
      build()
      rggm.profileMenu.SelectProfile("Tanking")
      profiles.Tanking = nil

      build()

      assert.is_nil(rggm.profileMenu.selectedProfile)
      assert.are.equal(2, #rows())
    end)
  end)

  describe("action button state", function()
    local function enabledState()
      return {
        load = button("ELEMENT_PROFILE_LOAD_BUTTON").enabled,
        rename = button("ELEMENT_PROFILE_RENAME_BUTTON").enabled,
        delete = button("ELEMENT_PROFILE_DELETE_BUTTON").enabled,
        export = button("ELEMENT_PROFILE_EXPORT_BUTTON").enabled
      }
    end

    it("greys out every selection button while nothing is selected", function()
      build()

      assert.are.same({ load = false, rename = false, delete = false, export = false }, enabledState())
    end)

    it("only allows exporting the active Default profile", function()
      build()
      rggm.profileMenu.SelectProfile(DEFAULT)

      assert.are.same({ load = false, rename = false, delete = false, export = true }, enabledState())
    end)

    it("enables every selection button for another profile", function()
      build()
      rggm.profileMenu.SelectProfile("Tanking")

      assert.are.same({ load = true, rename = true, delete = true, export = true }, enabledState())
    end)
  end)

  describe("create", function()
    before_each(build)

    it("opens the name prompt with an empty edit box", function()
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_CREATE_BUTTON)

      assert.are.equal("RGGM_PROFILE_CREATE", shownPopups[1].name)
      assert.are.equal("", openPopup("RGGM_PROFILE_CREATE").EditBox:GetText())
      assert.are.equal(RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH, popupDialogs["RGGM_PROFILE_CREATE"].maxLetters)
    end)

    it("creates the trimmed name, selects it and lists it as active", function()
      acceptWithName("RGGM_PROFILE_CREATE", nil, "  Raid  ")

      assert.are.same({ "profile.CreateProfile Raid" }, callLog)
      assert.are.equal("Raid", rggm.profileMenu.selectedProfile)
      assert.are.equal("profile_active_suffix:Raid", rowFor("Raid").label.text)
      assert.are.same({ "profile_create_success:Raid" }, userMessages)
    end)

    it("creates the name when Enter is pressed and closes the prompt", function()
      local popup, dialog = openPopup("RGGM_PROFILE_CREATE")

      popup.EditBox:SetText("Raid")
      dialog.EditBoxOnEnterPressed(popup.EditBox)

      assert.are.same({ "profile.CreateProfile Raid" }, callLog)
      assert.is_false(popup:IsShown())
    end)

    for _, case in ipairs({
      { label = "an empty name", name = "   ", error = "profile_error_name_empty:%s" },
      {
        label = "the reserved Default name",
        name = DEFAULT,
        error = "profile_error_default_cannot_be_overwritten:Default"
      },
      { label = "a name another profile carries", name = "Tanking", error = "profile_error_name_exists:%s" },
      {
        label = "an overlong name",
        name = string.rep("x", RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH + 1),
        error = "profile_error_name_too_long:" .. RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH
      }
    }) do
      it("refuses " .. case.label, function()
        acceptWithName("RGGM_PROFILE_CREATE", nil, case.name)

        assert.are.same({}, callLog)
        assert.are.same({ case.error }, userErrors)
      end)
    end
  end)

  describe("load", function()
    before_each(build)

    it("asks to select a profile first", function()
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_LOAD_BUTTON)

      assert.are.same({}, shownPopups)
      assert.are.same({ "profile_error_no_selection:%s" }, userErrors)
    end)

    it("does nothing for the active profile", function()
      rggm.profileMenu.SelectProfile(DEFAULT)
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_LOAD_BUTTON)

      assert.are.same({}, shownPopups)
      assert.are.same({}, userErrors)
    end)

    it("confirms loading the selected profile over the active one", function()
      rggm.profileMenu.SelectProfile("Tanking")
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_LOAD_BUTTON)

      assert.are.same(
        { name = "RGGM_PROFILE_LOAD", textArg1 = "Tanking", textArg2 = DEFAULT, data = "Tanking" },
        shownPopups[1]
      )
    end)

    it("clears the key bindings, switches, applies the new bindings and reloads", function()
      confirm("RGGM_PROFILE_LOAD", "Tanking")

      assert.are.same({
        "keyBind.ClearGearBarKeyBindings",
        "profile.SwitchProfile Tanking",
        "keyBind.ApplyGearBarKeyBindings",
        "ReloadUI"
      }, callLog)
    end)

    it("puts the bindings back without a reload when the switch fails", function()
      state.switchSucceeds = false

      confirm("RGGM_PROFILE_LOAD", "Tanking")

      assert.are.same({
        "keyBind.ClearGearBarKeyBindings",
        "profile.SwitchProfile Tanking",
        "keyBind.ApplyGearBarKeyBindings"
      }, callLog)
    end)

    it("refuses a profile deleted while the confirmation was open", function()
      profiles.Tanking = nil

      confirm("RGGM_PROFILE_LOAD", "Tanking")

      assert.are.same({}, callLog)
      assert.are.same({ "profile_error_no_selection:%s" }, userErrors)
    end)
  end)

  describe("reset to defaults", function()
    before_each(build)

    it("confirms resetting the active profile", function()
      state.active = "Healing"

      click(RGGM_CONSTANTS.ELEMENT_PROFILE_RESET_BUTTON)

      assert.are.equal("RGGM_PROFILE_RESET", shownPopups[1].name)
      assert.are.equal("Healing", shownPopups[1].textArg1)
    end)

    it("resets inside the key-binding dance and reloads", function()
      confirm("RGGM_PROFILE_RESET")

      assert.are.same({
        "keyBind.ClearGearBarKeyBindings",
        "profile.ResetActiveProfile",
        "keyBind.ApplyGearBarKeyBindings",
        "ReloadUI"
      }, callLog)
    end)
  end)

  describe("delete", function()
    before_each(build)

    it("refuses the Default profile before asking", function()
      rggm.profileMenu.SelectProfile(DEFAULT)
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_DELETE_BUTTON)

      assert.are.same({}, shownPopups)
      assert.are.same({ "profile_error_default_cannot_be_deleted:Default" }, userErrors)
    end)

    it("confirms deleting an inactive profile", function()
      rggm.profileMenu.SelectProfile("Tanking")
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_DELETE_BUTTON)

      assert.are.same({ name = "RGGM_PROFILE_DELETE", textArg1 = "Tanking", data = "Tanking" }, shownPopups[1])
    end)

    it("says Default takes over when the active profile is deleted", function()
      state.active = "Tanking"
      rggm.profileMenu.SelectProfile("Tanking")
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_DELETE_BUTTON)

      assert.are.same(
        { name = "RGGM_PROFILE_DELETE_ACTIVE", textArg1 = "Tanking", textArg2 = DEFAULT, data = "Tanking" },
        shownPopups[1]
      )
    end)

    it("deletes an inactive profile without touching the key bindings", function()
      rggm.profileMenu.SelectProfile("Tanking")

      confirm("RGGM_PROFILE_DELETE", "Tanking")

      assert.are.same({ "profile.DeleteProfile Tanking" }, callLog)
      assert.is_nil(rggm.profileMenu.selectedProfile)
      assert.is_nil(rowFor("Tanking"))
      assert.are.same({ "profile_delete_success:Tanking" }, userMessages)
    end)

    it("falls back to Default inside the key-binding dance when the active profile is deleted", function()
      state.active = "Tanking"

      confirm("RGGM_PROFILE_DELETE_ACTIVE", "Tanking")

      assert.are.same({
        "keyBind.ClearGearBarKeyBindings",
        "profile.DeleteProfile Tanking",
        "keyBind.ApplyGearBarKeyBindings",
        "ReloadUI"
      }, callLog)
    end)
  end)

  describe("rename", function()
    before_each(build)

    it("refuses the Default profile before asking", function()
      rggm.profileMenu.SelectProfile(DEFAULT)
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_RENAME_BUTTON)

      assert.are.same({}, shownPopups)
      assert.are.same({ "profile_error_default_cannot_be_renamed:Default" }, userErrors)
    end)

    it("prefills the prompt with the current name", function()
      rggm.profileMenu.SelectProfile("Tanking")
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_RENAME_BUTTON)

      assert.are.equal("Tanking", shownPopups[1].data)

      local popup = openPopup("RGGM_PROFILE_RENAME", "Tanking")

      assert.are.equal("Tanking", popup.EditBox:GetText())
      assert.is_true(popup.EditBox.highlighted)
    end)

    it("renames, selects the new name and lists it", function()
      acceptWithName("RGGM_PROFILE_RENAME", "Tanking", " Protection ")

      assert.are.same({ "profile.RenameProfile Tanking Protection" }, callLog)
      assert.are.equal("Protection", rggm.profileMenu.selectedProfile)
      assert.is_not_nil(rowFor("Protection"))
      assert.is_nil(rowFor("Tanking"))
      assert.are.same({ "profile_rename_success:Protection" }, userMessages)
    end)

    it("treats accepting the unchanged name as a no-op (GMF-0037)", function()
      state.active = "Tanking"

      local popup, dialog = openPopup("RGGM_PROFILE_RENAME", "Tanking")
      dialog.EditBoxOnEnterPressed(popup.EditBox)

      assert.are.same({}, callLog)
      assert.is_not_nil(profiles.Tanking)
      assert.are.same({}, userMessages)
      assert.are.same({}, userErrors)
      assert.is_false(popup:IsShown())
    end)

    for _, case in ipairs({
      { label = "an empty name", name = " ", error = "profile_error_name_empty:%s" },
      { label = "the Default name", name = DEFAULT, error = "profile_error_default_cannot_be_overwritten:Default" },
      { label = "a name another profile carries", name = "Healing", error = "profile_error_name_exists:%s" },
      {
        label = "an overlong name",
        name = string.rep("x", RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH + 1),
        error = "profile_error_name_too_long:" .. RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH
      }
    }) do
      it("refuses " .. case.label, function()
        acceptWithName("RGGM_PROFILE_RENAME", "Tanking", case.name)

        assert.are.same({}, callLog)
        assert.are.same({ case.error }, userErrors)
      end)
    end
  end)

  describe("export", function()
    before_each(build)

    it("asks to select a profile first", function()
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_EXPORT_BUTTON)

      assert.are.same({}, callLog)
      assert.are.same({ "profile_error_no_selection:%s" }, userErrors)
    end)

    it("mirrors the live setup first and puts the selected string into the box", function()
      rggm.profileMenu.SelectProfile(DEFAULT)
      click(RGGM_CONSTANTS.ELEMENT_PROFILE_EXPORT_BUTTON)

      assert.are.same({ "profile.SaveActiveProfile", "profile.ExportString Default" }, callLog)
      assert.are.equal("GearMenu1:Default", editBox():GetText())
      assert.is_true(editBox().highlighted)
      assert.is_true(editBox().focused)
    end)
  end)

  describe("import", function()
    local envelope

    before_each(function()
      build()
      envelope = { name = "Shared", payload = { imported = true } }
    end)

    it("caps the string box at the profile string limit (GMF-0023)", function()
      assert.are.equal(RGGM_CONSTANTS.PROFILE_STRING_MAX_LENGTH, editBox().maxLetters)
      assert.is_true(RGGM_CONSTANTS.PROFILE_STRING_MAX_LENGTH > 0)
    end)

    it("reports why a string was rejected and asks for no name", function()
      state.importErrorKey = "profile_error_invalid"
      editBox():SetText("garbage")

      click(RGGM_CONSTANTS.ELEMENT_PROFILE_IMPORT_BUTTON)

      assert.are.equal("garbage", state.importedText)
      assert.are.same({}, shownPopups)
      assert.are.same({ "profile_error_invalid:%s" }, userErrors)
    end)

    it("asks for a name for a valid string, prefilled with the exported name", function()
      state.importEnvelope = envelope

      click(RGGM_CONSTANTS.ELEMENT_PROFILE_IMPORT_BUTTON)

      assert.are.equal("RGGM_PROFILE_IMPORT", shownPopups[1].name)
      assert.are.equal(envelope, shownPopups[1].data)
      assert.are.equal("Shared", openPopup("RGGM_PROFILE_IMPORT", envelope).EditBox:GetText())
    end)

    it("prefills an empty name when the string carries none (GMF-0022)", function()
      assert.are.equal("", openPopup("RGGM_PROFILE_IMPORT", { payload = {} }).EditBox:GetText())
    end)

    it("stores the payload under the given name without switching to it", function()
      editBox():SetText("GearMenu1:...")

      acceptWithName("RGGM_PROFILE_IMPORT", envelope, " Shared ")

      assert.are.same({ "profile.SaveProfile Shared" }, callLog)
      assert.are.equal(envelope.payload, profiles.Shared)
      assert.are.equal(DEFAULT, state.active)
      assert.are.equal("Shared", rggm.profileMenu.selectedProfile)
      assert.are.equal("", editBox():GetText())
      assert.are.same({ "profile_import_success:Shared" }, userMessages)
    end)

    for _, case in ipairs({
      { label = "an empty name", name = "", error = "profile_error_name_empty:%s" },
      { label = "the Default name", name = DEFAULT, error = "profile_error_default_cannot_be_overwritten:Default" },
      { label = "a name another profile carries", name = "Tanking", error = "profile_error_name_exists:%s" },
      {
        label = "an overlong name",
        name = string.rep("x", RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH + 1),
        error = "profile_error_name_too_long:" .. RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH
      }
    }) do
      it("refuses " .. case.label, function()
        acceptWithName("RGGM_PROFILE_IMPORT", envelope, case.name)

        assert.are.same({}, callLog)
        assert.are.same({ case.error }, userErrors)
      end)
    end
  end)
end)
