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

--[[
  The Profiles settings page - the family feature every sibling addon carries, laid
  out like theirs: the title, a "Saved Profiles" list with the action buttons beside
  it, and the "Profile String (Export / Import)" box with its two buttons. A profile
  is the whole GearMenu setup (see code/Profile.lua), and one of them is the active
  profile the live setup belongs to: its row reads "<name> (active)" in gold, every
  edit made in the settings is its own, and a switch mirrors it before the other
  profile is loaded, so nothing is lost between profiles. The page creates a new
  profile from the current settings (it becomes the active one), loads a selected one
  (which reloads the UI), renames and deletes (deleting the active profile falls back
  to Default), resets the active profile to the factory settings, and exports /
  imports profiles as GearMenu1: strings. Default is the editable home profile every
  character starts on - it cannot be renamed or deleted, and "Reset to defaults" is
  how the factory settings come back.

  Every path that applies a snapshot to the live configuration (Load, Reset to
  defaults, deleting the active profile) is wrapped in the key-binding dance: the
  outgoing GearBars' WoW key bindings are cleared before, the incoming ones applied
  after, and the UI reloads so every GearBar rebuilds from the applied state.
]]--

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT StaticPopupDialogs StaticPopup_Show ReloadUI
-- luacheck: globals ACCEPT CANCEL YES NO

local mod = rggm
local me = {}
mod.profileMenu = me

me.tag = "ProfileMenu"

--[[
  Currently selected profile name in the list, or nil when nothing is selected
]]--
me.selectedProfile = nil

-- track whether the menu was already built
local builtMenu = false

--[[
  Scroll child holding the profile rows and the reusable row button pool
]]--
local profileListContent
local rowPool

--[[
  The multiline edit box used for export/import strings
]]--
local profileEditBox

--[[
  The action buttons that act on the selection and are greyed out while they could
  not act (see UpdateActionButtonState)
]]--
local loadButton
local renameButton
local deleteButton
local exportButton

--[[
  The row label colours: the active profile stands out in the title gold, every other
  row keeps the body colour of the family list - set by hand, so a row that stops being
  the active one turns back.
]]--
local ACTIVE_ROW_COLOR = RGGM_CONSTANTS.COLOR.TITLE_GOLD
local ROW_COLOR = RGGM_CONSTANTS.COLOR.BODY

--[[
  The action button column: right of the list, one button per 32px starting at the
  list's top edge, so the fifth button ends above the list's bottom edge
]]--
local ACTION_BUTTON_LEFT = 320
local ACTION_BUTTON_TOP = -64
local ACTION_BUTTON_SPACING = 32

-- forward declarations
local SetupStaticPopups
local CreateActionButton
local CreateProfileRow
local RefreshList
local UpdateActionButtonState
local PrintDefaultProfileError
local Trim
local IsNameTooLong
local HandleCreate
local HandleLoad
local HandleReset
local HandleDelete
local HandleRename
local HandleExport
local HandleImport
local FinishImport

--[[
  Build the ui for the profile menu. Built once (guarded); the list is
  refreshed on every show so external changes are reflected.

  @param {table} parentFrame
    The addon configuration frame to attach to
]]--
function me.BuildUi(parentFrame)
  if not builtMenu then
    SetupStaticPopups()

    local titleFontString = parentFrame:CreateFontString(
      RGGM_CONSTANTS.ELEMENT_PROFILE_TITLE, "OVERLAY", "GameFontNormalLarge")
    titleFontString:SetPoint("TOPLEFT", 16, -16)
    mod.uiHelper.SetColor(titleFontString, RGGM_CONSTANTS.COLOR.TITLE_GOLD)
    titleFontString:SetText(rggm.L["profile_title"])

    local listLabel = parentFrame:CreateFontString(nil, "OVERLAY")
    listLabel:SetFont(STANDARD_TEXT_FONT, 13)
    listLabel:SetPoint("TOPLEFT", 20, -46)
    listLabel:SetText(rggm.L["profile_list_label"])

    me.BuildProfileList(parentFrame)
    me.BuildActionButtons(parentFrame)

    local stringLabel = parentFrame:CreateFontString(nil, "OVERLAY")
    stringLabel:SetFont(STANDARD_TEXT_FONT, 13)
    stringLabel:SetPoint("TOPLEFT", 20, -246)
    stringLabel:SetText(rggm.L["profile_string_label"])

    me.BuildStringBox(parentFrame)

    builtMenu = true
  end

  RefreshList()
end

--[[
  Build the bordered, scrollable list of saved profiles.

  @param {table} frame
]]--
function me.BuildProfileList(frame)
  local listContainer = mod.uiHelper.CreateScrollList(
    RGGM_CONSTANTS.ELEMENT_PROFILE_LIST_SCROLL_FRAME,
    frame,
    {"TOPLEFT", 20, ACTION_BUTTON_TOP},
    RGGM_CONSTANTS.ELEMENT_PROFILE_LIST_WIDTH,
    RGGM_CONSTANTS.ELEMENT_PROFILE_LIST_HEIGHT
  )

  profileListContent = listContainer.content

  rowPool = mod.uiHelper.CreateFramePool(CreateProfileRow)
end

--[[
  Build the five action buttons beside the list: Create new Profile, Load, Rename,
  Delete and Reset to defaults. Load, Delete and Reset confirm; Load, Rename and
  Delete act on the selected profile and are greyed while they could not act (see
  UpdateActionButtonState), Reset acts on the active profile.

  @param {table} frame
]]--
function me.BuildActionButtons(frame)
  CreateActionButton(
    frame,
    RGGM_CONSTANTS.ELEMENT_PROFILE_CREATE_BUTTON,
    RGGM_CONSTANTS.ELEMENT_PROFILE_BUTTON_WIDTH,
    {"TOPLEFT", ACTION_BUTTON_LEFT, ACTION_BUTTON_TOP},
    rggm.L["profile_create_button"],
    function()
      StaticPopup_Show("RGGM_PROFILE_CREATE")
    end
  )

  loadButton = CreateActionButton(
    frame,
    RGGM_CONSTANTS.ELEMENT_PROFILE_LOAD_BUTTON,
    RGGM_CONSTANTS.ELEMENT_PROFILE_BUTTON_WIDTH,
    {"TOPLEFT", ACTION_BUTTON_LEFT, ACTION_BUTTON_TOP - ACTION_BUTTON_SPACING},
    rggm.L["profile_load_button"],
    function()
      if not me.selectedProfile then
        mod.logger.PrintUserError(rggm.L["profile_error_no_selection"])
        return
      end

      local activeName = mod.profile.GetActiveProfileName()

      -- the active profile is loaded already (the button is greyed for it)
      if me.selectedProfile == activeName then
        return
      end

      StaticPopup_Show("RGGM_PROFILE_LOAD", me.selectedProfile, activeName, me.selectedProfile)
    end
  )

  renameButton = CreateActionButton(
    frame,
    RGGM_CONSTANTS.ELEMENT_PROFILE_RENAME_BUTTON,
    RGGM_CONSTANTS.ELEMENT_PROFILE_BUTTON_WIDTH,
    {"TOPLEFT", ACTION_BUTTON_LEFT, ACTION_BUTTON_TOP - 2 * ACTION_BUTTON_SPACING},
    rggm.L["profile_rename_button"],
    function()
      if not me.selectedProfile then
        mod.logger.PrintUserError(rggm.L["profile_error_no_selection"])
        return
      end

      if mod.profile.IsDefaultProfile(me.selectedProfile) then
        PrintDefaultProfileError("profile_error_default_cannot_be_renamed")
        return
      end

      StaticPopup_Show("RGGM_PROFILE_RENAME", nil, nil, me.selectedProfile)
    end
  )

  deleteButton = CreateActionButton(
    frame,
    RGGM_CONSTANTS.ELEMENT_PROFILE_DELETE_BUTTON,
    RGGM_CONSTANTS.ELEMENT_PROFILE_BUTTON_WIDTH,
    {"TOPLEFT", ACTION_BUTTON_LEFT, ACTION_BUTTON_TOP - 3 * ACTION_BUTTON_SPACING},
    rggm.L["profile_delete_button"],
    function()
      if not me.selectedProfile then
        mod.logger.PrintUserError(rggm.L["profile_error_no_selection"])
        return
      end

      if mod.profile.IsDefaultProfile(me.selectedProfile) then
        PrintDefaultProfileError("profile_error_default_cannot_be_deleted")
        return
      end

      -- deleting the active profile says what follows: Default takes over and the UI reloads
      if me.selectedProfile == mod.profile.GetActiveProfileName() then
        StaticPopup_Show(
          "RGGM_PROFILE_DELETE_ACTIVE",
          me.selectedProfile,
          RGGM_CONSTANTS.DEFAULT_PROFILE_NAME,
          me.selectedProfile
        )
        return
      end

      StaticPopup_Show("RGGM_PROFILE_DELETE", me.selectedProfile, nil, me.selectedProfile)
    end
  )

  CreateActionButton(
    frame,
    RGGM_CONSTANTS.ELEMENT_PROFILE_RESET_BUTTON,
    RGGM_CONSTANTS.ELEMENT_PROFILE_BUTTON_WIDTH,
    {"TOPLEFT", ACTION_BUTTON_LEFT, ACTION_BUTTON_TOP - 4 * ACTION_BUTTON_SPACING},
    rggm.L["profile_reset_button"],
    function()
      StaticPopup_Show("RGGM_PROFILE_RESET", mod.profile.GetActiveProfileName())
    end
  )

  UpdateActionButtonState()
end

--[[
  Build the multiline export/import string box and its Export/Import buttons.

  @param {table} frame
]]--
function me.BuildStringBox(frame)
  local stringContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  stringContainer:SetSize(RGGM_CONSTANTS.ELEMENT_PROFILE_STRING_WIDTH, RGGM_CONSTANTS.ELEMENT_PROFILE_STRING_HEIGHT)
  stringContainer:SetPoint("TOPLEFT", 20, -264)
  mod.uiHelper.ApplyBorderBackdrop(stringContainer)

  local scrollContainer = CreateFrame(
    "ScrollFrame",
    RGGM_CONSTANTS.ELEMENT_PROFILE_STRING_SCROLL_FRAME,
    stringContainer,
    "InputScrollFrameTemplate"
  )
  scrollContainer:SetPoint("TOPLEFT", 6, -6)
  scrollContainer:SetPoint("BOTTOMRIGHT", -6, 6)

  --[[ the template draws its own input-border art outside its rect which does not line
       up with the profile list's backdrop - hide it, the container draws the border ]]--
  local artKeys = {
    "TopLeftTex", "TopRightTex", "BottomLeftTex", "BottomRightTex",
    "TopTex", "BottomTex", "LeftTex", "RightTex", "MiddleTex"
  }

  for _, artKey in ipairs(artKeys) do
    if scrollContainer[artKey] then
      scrollContainer[artKey]:Hide()
    end
  end

  if scrollContainer.CharCount then
    scrollContainer.CharCount:Hide()
  end

  profileEditBox = scrollContainer.EditBox
  profileEditBox:SetMaxLetters(0)
  profileEditBox:SetFontObject("ChatFontNormal")
  profileEditBox:SetWidth(RGGM_CONSTANTS.ELEMENT_PROFILE_STRING_WIDTH - 30)
  profileEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)

  exportButton = CreateActionButton(
    frame,
    RGGM_CONSTANTS.ELEMENT_PROFILE_EXPORT_BUTTON,
    110,
    {"TOPLEFT", 20, -366},
    rggm.L["profile_export_button"],
    HandleExport
  )

  CreateActionButton(
    frame,
    RGGM_CONSTANTS.ELEMENT_PROFILE_IMPORT_BUTTON,
    110,
    {"TOPLEFT", 140, -366},
    rggm.L["profile_import_button"],
    HandleImport
  )

  UpdateActionButtonState()
end

--[[
  Select a profile by name and update the row highlights.

  @param {string} name
]]--
function me.SelectProfile(name)
  me.selectedProfile = name

  if not rowPool then return end

  rowPool.ForEach(function(row)
    if row:IsShown() and row.profileName == name then
      row.selectedTexture:Show()
    else
      row.selectedTexture:Hide()
    end
  end)

  UpdateActionButtonState()
end

--[[
  Grey out the buttons that act on the selection while they could not act: Load,
  Rename, Delete and Export with nothing selected, Load also on the active profile
  (it is loaded already), Rename and Delete also on the Default profile. Create new
  Profile, Reset to defaults and Import never depend on the selection. The click
  handlers guard the same conditions - this only makes the refusal visible before
  the click.
]]--
UpdateActionButtonState = function()
  if not loadButton or not renameButton or not deleteButton or not exportButton then return end

  local selected = me.selectedProfile ~= nil and mod.profile.ProfileExists(me.selectedProfile)
  local editable = selected and not mod.profile.IsDefaultProfile(me.selectedProfile)
  local loadable = selected and me.selectedProfile ~= mod.profile.GetActiveProfileName()

  loadButton:SetEnabled(loadable)
  renameButton:SetEnabled(editable)
  deleteButton:SetEnabled(editable)
  exportButton:SetEnabled(selected)
end

--[[
  Print one of the profile_error_default_* messages. The reserved profile name is not
  translated - it is a saved-variable key that also travels inside export strings - so every
  locale spells it out verbatim instead of naming it in its own words.

  @param {string} errorKey
]]--
PrintDefaultProfileError = function(errorKey)
  mod.logger.PrintUserError(string.format(rggm.L[errorKey], RGGM_CONSTANTS.DEFAULT_PROFILE_NAME))
end

--[[
  Create a row button at the given index in the list. Used as the createFrame
  factory of the row pool.

  @param {number} index
  @return {table}
]]--
CreateProfileRow = function(index)
  local rowHeight = RGGM_CONSTANTS.ELEMENT_PROFILE_LIST_ROW_HEIGHT
  local _, yPos = mod.uiHelper.CalculateGridPosition(index, 1, rowHeight)

  local row = CreateFrame("Button", RGGM_CONSTANTS.ELEMENT_PROFILE_LIST_ROW .. index, profileListContent)
  row:SetHeight(rowHeight)
  row:SetPoint("TOPLEFT", profileListContent, "TOPLEFT", 0, -yPos)
  row:SetPoint("TOPRIGHT", profileListContent, "TOPRIGHT", 0, -yPos)

  local selectedTexture = row:CreateTexture(nil, "BACKGROUND")
  selectedTexture:SetAllPoints()
  selectedTexture:SetColorTexture(1, 0.82, 0, 0.25)
  selectedTexture:Hide()
  row.selectedTexture = selectedTexture

  local highlightTexture = row:CreateTexture(nil, "HIGHLIGHT")
  highlightTexture:SetAllPoints()
  highlightTexture:SetColorTexture(1, 1, 1, 0.15)

  local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint("LEFT", 4, 0)
  label:SetJustifyH("LEFT")
  row.label = label

  row:SetScript("OnClick", function(self)
    me.SelectProfile(self.profileName)
  end)

  return row
end

--[[
  Rebuild the visible profile rows from the saved profile list. The active profile's
  row reads "<name> (active)" in gold; the selection is the translucent row texture,
  so a row can be active, selected or both.
]]--
RefreshList = function()
  if not profileListContent then return end

  local names = mod.profile.ListProfiles()
  local activeName = mod.profile.GetActiveProfileName()

  -- drop a selection that no longer exists
  if me.selectedProfile and not mod.profile.ProfileExists(me.selectedProfile) then
    me.selectedProfile = nil
  end

  local rowHeight = RGGM_CONSTANTS.ELEMENT_PROFILE_LIST_ROW_HEIGHT
  profileListContent:SetHeight(math.max(#names * rowHeight, 1))

  for index, name in ipairs(names) do
    local row = rowPool.Acquire(index)

    row.profileName = name

    if name == activeName then
      row.label:SetText(string.format(rggm.L["profile_active_suffix"], name))
      mod.uiHelper.SetColor(row.label, ACTIVE_ROW_COLOR)
    else
      row.label:SetText(name)
      mod.uiHelper.SetColor(row.label, ROW_COLOR)
    end

    if name == me.selectedProfile then
      row.selectedTexture:Show()
    else
      row.selectedTexture:Hide()
    end

    row:Show()
  end

  rowPool.ReleaseFrom(#names + 1)

  UpdateActionButtonState()
end

--[[
  Helper to create a UIPanelButton.

  @param {table} parent
  @param {string} name
  @param {number} width
  @param {table} point
    a table that can be unpacked into SetPoint
  @param {string} text
  @param {function} onClick
  @return {table}
]]--
CreateActionButton = function(parent, name, width, point, text, onClick)
  local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
  button:SetSize(width, RGGM_CONSTANTS.ELEMENT_PROFILE_BUTTON_HEIGHT)
  button:SetPoint(unpack(point))
  button:SetText(text)
  button:SetScript("OnClick", onClick)

  return button
end

--[[
  Trim leading/trailing whitespace from a string.

  @param {string} value
  @return {string}
]]--
Trim = function(value)
  return (string.match(value, "^%s*(.-)%s*$"))
end

--[[
  Refuse an overlong profile name. The name prompts already cap their edit box, so this
  only catches a name that did not come from typing - an imported envelope carrying a
  name from an addon version with a laxer limit.

  @param {string} name
  @return {boolean}
    true - if the name was refused and an error was printed
    false - otherwise
]]--
IsNameTooLong = function(name)
  if not mod.profile.IsNameTooLong(name) then
    return false
  end

  mod.logger.PrintUserError(
    string.format(rggm.L["profile_error_name_too_long"], RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH))

  return true
end

--[[
  Create a new named profile from the current settings and make it the active one.
  A name another profile carries is refused, and so is the reserved Default name.

  @param {string} name
]]--
HandleCreate = function(name)
  name = Trim(name)

  if name == "" then
    mod.logger.PrintUserError(rggm.L["profile_error_name_empty"])
    return
  end

  if IsNameTooLong(name) then return end

  if mod.profile.IsDefaultProfile(name) then
    PrintDefaultProfileError("profile_error_default_cannot_be_overwritten")
    return
  end

  if mod.profile.ProfileExists(name) then
    mod.logger.PrintUserError(rggm.L["profile_error_name_exists"])
    return
  end

  mod.profile.CreateProfile(name)
  me.selectedProfile = name
  RefreshList()
  mod.logger.PrintUserMessage(string.format(rggm.L["profile_create_success"], name))
end

--[[
  Switch to a stored profile and reload the UI: the profile that was active keeps the
  settings as they are now, the loaded one takes over. The outgoing GearBars' key
  bindings are cleared before the switch and the incoming ones applied after, so the
  bindings follow the profile across the reload. The active profile itself has
  nothing to load.

  @param {string} name
]]--
HandleLoad = function(name)
  if not mod.profile.ProfileExists(name) then
    mod.logger.PrintUserError(rggm.L["profile_error_no_selection"])
    return
  end

  if name == mod.profile.GetActiveProfileName() then
    return
  end

  mod.keyBind.ClearGearBarKeyBindings(mod.gearBarManager.GetGearBars())

  if not mod.profile.SwitchProfile(name) then
    -- nothing was applied; put the bindings of the still-live GearBars back
    mod.keyBind.ApplyGearBarKeyBindings()
    return
  end

  mod.keyBind.ApplyGearBarKeyBindings()
  ReloadUI()
end

--[[
  Reset the active profile to the factory settings (the starter GearBar included) and
  reload the UI, with the key-binding dance around it like a load.
]]--
HandleReset = function()
  mod.keyBind.ClearGearBarKeyBindings(mod.gearBarManager.GetGearBars())
  mod.profile.ResetActiveProfile()
  mod.keyBind.ApplyGearBarKeyBindings()
  ReloadUI()
end

--[[
  Delete a stored profile. Deleting the active profile falls back to Default, which
  takes over the live setup - that path runs the key-binding dance and reloads the
  UI like a load does.

  @param {string} name
]]--
HandleDelete = function(name)
  if mod.profile.IsDefaultProfile(name) then
    PrintDefaultProfileError("profile_error_default_cannot_be_deleted")
    return
  end

  local isActive = name == mod.profile.GetActiveProfileName()

  if isActive then
    mod.keyBind.ClearGearBarKeyBindings(mod.gearBarManager.GetGearBars())
  end

  local deleted, fellBack = mod.profile.DeleteProfile(name)

  if not deleted then
    PrintDefaultProfileError("profile_error_default_cannot_be_deleted")
    return
  end

  if me.selectedProfile == name then
    me.selectedProfile = nil
  end

  mod.logger.PrintUserMessage(string.format(rggm.L["profile_delete_success"], name))

  if fellBack then
    mod.keyBind.ApplyGearBarKeyBindings()
    ReloadUI()
    return
  end

  RefreshList()
end

--[[
  Rename a stored profile. Neither the Default profile itself nor its name as the
  target are allowed, and a name another profile carries is refused.

  @param {string} oldName
  @param {string} newName
]]--
HandleRename = function(oldName, newName)
  newName = Trim(newName)

  if newName == "" then
    mod.logger.PrintUserError(rggm.L["profile_error_name_empty"])
    return
  end

  if IsNameTooLong(newName) then return end

  if mod.profile.IsDefaultProfile(oldName) then
    PrintDefaultProfileError("profile_error_default_cannot_be_renamed")
    return
  end

  if mod.profile.IsDefaultProfile(newName) then
    PrintDefaultProfileError("profile_error_default_cannot_be_overwritten")
    return
  end

  if newName ~= oldName and mod.profile.ProfileExists(newName) then
    mod.logger.PrintUserError(rggm.L["profile_error_name_exists"])
    return
  end

  mod.profile.RenameProfile(oldName, newName)
  me.selectedProfile = newName
  RefreshList()
  mod.logger.PrintUserMessage(string.format(rggm.L["profile_rename_success"], newName))
end

--[[
  Export the selected profile into the string box and select it for copying. The live
  setup is mirrored into the active profile first, so the active row always exports
  the settings as they are now.
]]--
HandleExport = function()
  local name = me.selectedProfile

  if not name or not mod.profile.ProfileExists(name) then
    mod.logger.PrintUserError(rggm.L["profile_error_no_selection"])
    return
  end

  mod.profile.SaveActiveProfile()
  profileEditBox:SetText(mod.profile.ExportString(mod.profile.GetProfile(name), name))
  profileEditBox:HighlightText()
  profileEditBox:SetFocus()
end

--[[
  Decode and validate the string box content, then prompt for a name to store
  it under.
]]--
HandleImport = function()
  local envelope, errorKey = mod.profile.ImportString(profileEditBox:GetText())

  if not envelope then
    mod.logger.PrintUserError(rggm.L[errorKey])
    return
  end

  StaticPopup_Show("RGGM_PROFILE_IMPORT", nil, nil, envelope)
end

--[[
  Store an imported, already-validated envelope under a user-given name. The import
  is stored without switching to it.

  @param {string} name
  @param {table} envelope
]]--
FinishImport = function(name, envelope)
  name = Trim(name)

  if name == "" then
    mod.logger.PrintUserError(rggm.L["profile_error_name_empty"])
    return
  end

  if IsNameTooLong(name) then return end

  if mod.profile.IsDefaultProfile(name) then
    PrintDefaultProfileError("profile_error_default_cannot_be_overwritten")
    return
  end

  if mod.profile.ProfileExists(name) then
    mod.logger.PrintUserError(rggm.L["profile_error_name_exists"])
    return
  end

  mod.profile.SaveProfile(name, envelope.payload)
  me.selectedProfile = name
  profileEditBox:SetText("")
  RefreshList()
  mod.logger.PrintUserMessage(string.format(rggm.L["profile_import_success"], name))
end

--[[
  Register the StaticPopup dialogs used for naming and destructive confirmation. The
  name prompts answer Accept / Cancel, every confirm answers Yes / No.
]]--
SetupStaticPopups = function()
  StaticPopupDialogs["RGGM_PROFILE_CREATE"] = {
    text = rggm.L["profile_name_prompt"],
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH,
    OnShow = function(self)
      self.EditBox:SetText("")
      self.EditBox:SetFocus()
    end,
    OnAccept = function(self)
      HandleCreate(self.EditBox:GetText())
    end,
    EditBoxOnEnterPressed = function(self)
      HandleCreate(self:GetText())
      self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
  }

  StaticPopupDialogs["RGGM_PROFILE_RENAME"] = {
    text = rggm.L["profile_rename_prompt"],
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH,
    OnShow = function(self)
      self.EditBox:SetText(self.data or "")
      self.EditBox:SetFocus()
      self.EditBox:HighlightText()
    end,
    OnAccept = function(self)
      HandleRename(self.data, self.EditBox:GetText())
    end,
    EditBoxOnEnterPressed = function(self)
      local parent = self:GetParent()
      HandleRename(parent.data, self:GetText())
      parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
  }

  StaticPopupDialogs["RGGM_PROFILE_IMPORT"] = {
    text = rggm.L["profile_import_name_prompt"],
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = RGGM_CONSTANTS.PROFILE_NAME_MAX_LENGTH,
    OnShow = function(self)
      self.EditBox:SetText((self.data and self.data.name) or "")
      self.EditBox:SetFocus()
      self.EditBox:HighlightText()
    end,
    OnAccept = function(self)
      FinishImport(self.EditBox:GetText(), self.data)
    end,
    EditBoxOnEnterPressed = function(self)
      local parent = self:GetParent()
      FinishImport(self:GetText(), parent.data)
      parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
  }

  --[[
    A Yes / No question, the family rule for every confirm popup

    @param {string} textKey
    @param {function} commit
      invoked with the popup's data
    @return {table}
  ]]--
  local function ConfirmPopup(textKey, commit)
    return {
      text = rggm.L[textKey],
      button1 = YES,
      button2 = NO,
      OnAccept = function(self)
        commit(self.data)
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3
    }
  end

  StaticPopupDialogs["RGGM_PROFILE_LOAD"] = ConfirmPopup("profile_load_confirm", HandleLoad)
  StaticPopupDialogs["RGGM_PROFILE_DELETE"] = ConfirmPopup("profile_delete_confirm", HandleDelete)
  -- deleting the active profile says what follows: Default takes over and the UI reloads
  StaticPopupDialogs["RGGM_PROFILE_DELETE_ACTIVE"] = ConfirmPopup("profile_delete_active_confirm", HandleDelete)
  StaticPopupDialogs["RGGM_PROFILE_RESET"] = ConfirmPopup("profile_reset_confirm", HandleReset)
end
