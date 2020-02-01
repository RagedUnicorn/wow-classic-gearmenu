--[[
  MIT License

  Copyright (c) 2020 Michael Wiesendanger

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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT UIDropDownMenu_Initialize UIDropDownMenu_AddButton
-- luacheck: globals UIDropDownMenu_GetSelectedID UIDropDownMenu_SetSelectedValue FauxScrollFrame_Update
-- luacheck: globals FauxScrollFrame_GetOffset UIDropDownMenu_GetSelectedValue

local mod = rggm
local me = {}
mod.quickChangeMenu = me

me.tag = "QuickChangeMenu"

--[[
  Local references to ui elements
]]--
local fromRows = {}
local toRows = {}
local rulesRows = {}

--[[
  Tracks the current selected 'from' and 'to' item ids

  ["from"] = itemId,
    {number} - The itemId to switch from (left side of a quickchange rule)
  ["to"] = itemId,
    {number} - {number} - The itemId to switch to (right side of a quickchange rule)
  ["delay"] = 2
    {number} - The delay until the rule takes place after detecting it. Can be 0 for an
    immediate switch
]]--
local selectedRule = {
  ["from"] = nil,
  ["to"] = nil
}

--[[
  Tracks the currently selected quickchange rule

  ["from"] = itemId,
    {number} - The itemId to switch from (left side of a quickchange rule)
  ["to"] = itemId,
    {number} - {number} - The itemId to switch to (right side of a quickchange rule)
]]--
local quickchangeRule = {
  ["from"] = nil,
  ["to"] = nil
}

-- track whether the menu was already built
local builtMenu = false

function me.BuildUi(frame)
  if builtMenu then return end

  --[[
    Create input elements
  ]]--
  me.CreateDelaySlider(frame)
  me.CreateAddRuleButton()
  me.CreateRemoveRuleButton(frame)
  me.CreateInventoryTypeDropdown(frame)
  --[[
    Create item lists
  ]]--
  local rulesScrollFrame = me.CreateRulesList(frame)
  -- initial load of rule list
  me.RulesScrollFrameOnUpdate(rulesScrollFrame)
  local fromScrollFrame = me.CreateFromItemList(frame)
  -- initial load of from list
  me.FromFauxScrollFrameOnUpdate(fromScrollFrame)
  local toScrollFrame = me.CreateToItemList(frame)
  -- initial load of to list
  me.ToFauxScrollFrameOnUpdate(toScrollFrame)

  builtMenu = true
end

--[[
  Create a slider for choosing a delay for a quickchange rule

  @param {table} frame
]]--
function me.CreateDelaySlider(frame)
  local delaySlider = CreateFrame(
    "Slider",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_DELAY_SLIDER,
    frame,
    "OptionsSliderTemplate"
  )
  delaySlider:SetWidth(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_WIDTH)
  delaySlider:SetHeight(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_HEIGHT)
  delaySlider:SetOrientation('HORIZONTAL')
  delaySlider:SetPoint("TOPLEFT", 10, -440)
  delaySlider:SetMinMaxValues(
    RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MIN,
    RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MAX
  )
  delaySlider:SetValueStep(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_STEP)
  delaySlider:SetObeyStepOnDrag(true)
  delaySlider:SetValue(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MIN)

  -- Update slider texts
  _G[delaySlider:GetName() .. "Low"]:SetText(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MIN)
  _G[delaySlider:GetName() .. "High"]:SetText(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MAX)
  _G[delaySlider:GetName() .. "Text"]:SetText(rggm.L["quick_change_slider_title"])
  delaySlider.tooltipText = rggm.L["quick_change_slider_tooltip"]

  local valueFontString = delaySlider:CreateFontString(nil, "OVERLAY")
  valueFontString:SetFont(STANDARD_TEXT_FONT, 12)
  valueFontString:SetPoint("BOTTOM", 0, -15)
  valueFontString:SetText(delaySlider:GetValue() .. " " .. rggm.L["quick_change_slider_unit"])

  delaySlider.valueFontString = valueFontString
  delaySlider:SetScript("OnValueChanged", me.DelaySliderOnValueChange)
end

--[[
  OnValueChanged callback for delay slider

  @param {table} self
  @param {number} value
]]--
function me.DelaySliderOnValueChange(self, value)
  self.valueFontString:SetText(value .. " " .. rggm.L["quick_change_slider_unit"])
end

--[[
  Create a button for add new quickchange rules
]]--
function me.CreateAddRuleButton()
  local addRuleButton = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_ADD_RULE_BUTTON,
    _G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_DELAY_SLIDER],
    "UIPanelButtonTemplate"
  )
  addRuleButton:SetPoint("RIGHT", 120, 0)
  addRuleButton:SetText(rggm.L["quick_change_add_rule"])

  local buttonSize = addRuleButton:GetTextWidth() + RGGM_CONSTANTS.QUICK_CHANGE_BUTTON_MARGIN

  if buttonSize < 100 then
    buttonSize = 100
  end

  addRuleButton:SetWidth(buttonSize)
  addRuleButton:SetScript("OnClick", me.AddRuleOnClick)
end

--[[
  OnClick callback for add rule button
]]--
function me.AddRuleOnClick()
  local delay = _G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_DELAY_SLIDER]:GetValue()

  if delay == nil then
    -- internal user
    mod.logger.LogError(me.tag, "Unable to read delay from delay slider")
    return
  end

  if selectedRule.from == nil then
    -- user error
    mod.logger.PrintUserError(rggm.L["quick_change_unable_to_add_rule_from"])
    return
  end

  if selectedRule.to == nil then
    -- user error
    mod.logger.PrintUserError(rggm.L["quick_change_unable_to_add_rule_to"])
    return
  end

  mod.quickChange.AddQuickChangeRule(selectedRule.from, selectedRule.to, delay)
  me.ResetSelectedItems()
  -- update items in 'from', 'to' and the rules list
  me.FromFauxScrollFrameOnUpdate(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME])
  me.ToFauxScrollFrameOnUpdate(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME])
  me.RulesScrollFrameOnUpdate(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_SCROLL_FRAME])
end

--[[
  Create a button for adding new quickchange rules

  @param {table} frame
]]--
function me.CreateRemoveRuleButton(frame)
  local removeRuleButton = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_REMOVE_RULE_BUTTON,
    frame,
    "UIPanelButtonTemplate"
  )
  removeRuleButton:SetPoint("TOPLEFT", 480, -200)
  removeRuleButton:SetText(rggm.L["quick_change_remove_rule"])

  local buttonSize = removeRuleButton:GetTextWidth() + RGGM_CONSTANTS.QUICK_CHANGE_BUTTON_MARGIN

  if buttonSize < 100 then
    buttonSize = 100
  end

  removeRuleButton:SetWidth(buttonSize)
  removeRuleButton:SetScript("OnClick", me.RemoveRuleOnClick)
end

--[[
  OnClick callback for remove rule button
]]--
function me.RemoveRuleOnClick()
  if quickchangeRule.from == nil or quickchangeRule.to == nil then
    mod.logger.PrintUserError(rggm.L["quick_change_unable_to_remove_rule"])
    return
  end

  mod.quickChange.RemoveQuickChangeRule(quickchangeRule.from, quickchangeRule.to)
  me.ResetSelectedRule()
  me.RulesScrollFrameOnUpdate(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_SCROLL_FRAME])
end

--[[
  Reset the currently selected items
]]--
function me.ResetSelectedItems()
  selectedRule.from = nil
  selectedRule.to = nil
end

--[[
  Reset the currently selected rule
]]--
function me.ResetSelectedRule()
  quickchangeRule.from = nil
  quickchangeRule.to = nil
end

--[[
  Create dropdown to choose from a list of itemTypes

  @param {table} frame
]]--
function me.CreateInventoryTypeDropdown(frame)
  local chooseCategoryDropdownMenu = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_CHOOSE_INVENTORY_TYPE,
    frame,
    "UIDropDownMenuTemplate"
  )
  chooseCategoryDropdownMenu:SetPoint("TOPLEFT", 5, -250)

  UIDropDownMenu_Initialize(chooseCategoryDropdownMenu, me.InitializeInventoryTypeDropdownMenu)
end

--[[
  Initialize dropdownmenu for inventory types

  @param {table} self
]]--
function me.InitializeInventoryTypeDropdownMenu()
  local gearSlots = mod.gearManager.GetGearSlots()
  local registeredInventoryTypes = {}

  for _, gearSlot in pairs(gearSlots) do
    --[[
      Prevent duplicate entries of inventoryTypes by using the textureId. Slots such
      as upper and lower trinket have the same texture and are thus only added once
    ]]--
    if registeredInventoryTypes[gearSlot.textureId] == nil then
      local button

      if gearSlot.simplifiedName ~= nil then
        button = mod.uiHelper.CreateDropdownButton(
          rggm.L[gearSlot.simplifiedName],
          gearSlot.slotId,
          me.InventoryTypeDropDownMenuCallback
        )
      else
        button = mod.uiHelper.CreateDropdownButton(
          rggm.L[gearSlot.name],
          gearSlot.slotId,
          me.InventoryTypeDropDownMenuCallback
        )
      end

      UIDropDownMenu_AddButton(button)
      registeredInventoryTypes[gearSlot.textureId] = true
    end
  end

  if (UIDropDownMenu_GetSelectedValue(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_CHOOSE_INVENTORY_TYPE]) == nil) then
    UIDropDownMenu_SetSelectedValue(
      _G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_CHOOSE_INVENTORY_TYPE],
      RGGM_CONSTANTS.CATEGORY_DROPDOWN_DEFAULT_VALUE
    )
  end
end

--[[
  Callback for optionsmenu dropdowns

  @param {table} self
]]
function me.InventoryTypeDropDownMenuCallback(self)
  UIDropDownMenu_SetSelectedValue(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_CHOOSE_INVENTORY_TYPE], self.value)

  me.ResetSelectedItems()

  -- update items in both 'from' and 'to' list
  me.FromFauxScrollFrameOnUpdate(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME])
  me.ToFauxScrollFrameOnUpdate(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME])
end

--[[
  Create a scrollable frame for displaying configured quickchange rules

  @param {table} frame

  @return {table}
    The created rulesScrollFrame
]]--
function me.CreateRulesList(frame)
  local rulesScrollFrame = CreateFrame(
    "ScrollFrame",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_SCROLL_FRAME,
    frame,
    "FauxScrollFrameTemplate"
  )
  rulesScrollFrame:SetWidth(RGGM_CONSTANTS.QUICK_CHANGE_RULES_CONTENT_FRAME_WIDTH)
  rulesScrollFrame:SetHeight(
    RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS
  )
  rulesScrollFrame:SetPoint("TOPLEFT", 10, -50)
  rulesScrollFrame:EnableMouseWheel(true)
  rulesScrollFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })

  rulesScrollFrame:SetScript("OnVerticalScroll", me.RuleListOnVerticalScroll)

  for i = 1, RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS do
    table.insert(rulesRows, me.CreateRuleRowFrame(rulesScrollFrame, i))
  end

  return rulesScrollFrame
end

--[[
  OnVerticalScroll callback for scrollable rule list

  @param {table} self
  @param {number} offset
]]--
function me.RuleListOnVerticalScroll(self, offset)
  self.ScrollBar:SetValue(offset)
  self.offset = math.floor(offset / RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT + 0.5)
  me.RulesScrollFrameOnUpdate(self)
end

--[[
  @param {table} frame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateRuleRowFrame(frame, position)
  local row = CreateFrame("Button", RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_ROW .. position, frame)
  row:SetSize(frame:GetWidth() -5, RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", frame, 8, (position -1) * RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * -1)

  local fromItemIcon = row:CreateTexture(nil, "ARTWORK")
  fromItemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  fromItemIcon:SetPoint("LEFT", 0, 0)
  fromItemIcon:SetSize(
    16,
    16
  )

  row.fromItemIcon = fromItemIcon

  local fromItemName = row:CreateFontString(nil, "OVERLAY")
  fromItemName:SetFont(STANDARD_TEXT_FONT, 14)
  fromItemName:SetPoint("LEFT", row.fromItemIcon, 0, 0)
  fromItemName:SetWidth(250)

  row.fromItemName = fromItemName

  local toItemIcon = row:CreateTexture(nil, "ARTWORK")
  toItemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  toItemIcon:SetPoint("RIGHT", row.fromItemName, 50, 0)
  toItemIcon:SetSize(
    16,
    16
  )

  row.toItemIcon = toItemIcon

  local toItemName = row:CreateFontString(nil, "OVERLAY")
  toItemName:SetFont(STANDARD_TEXT_FONT, 14)
  toItemName:SetPoint("LEFT", row.toItemIcon, 0, 0)
  toItemName:SetWidth(250)

  row.toItemName = toItemName

  local delay = row:CreateFontString(nil, "OVERLAY")
  delay:SetFont(STANDARD_TEXT_FONT, 14)
  delay:SetPoint("RIGHT", 0, 0)
  delay:SetWidth(50)

  row.delay = delay

  local highlightTexture = row:CreateTexture(RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_ROW_HIGHLIGHT, "BACKGROUND")
  highlightTexture:SetSize(row:GetWidth(), row:GetHeight())
  highlightTexture:SetPoint("TOPLEFT")
  highlightTexture:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
  highlightTexture:SetBlendMode("ADD")
  highlightTexture:Hide()

  me.SetupRowEvents(row)

  return row
end

--[[
  Update the quickchange rules list

  @param {table} scrollFrame
]]--
function me.RulesScrollFrameOnUpdate(scrollFrame)
  local quickChangeRules = mod.configuration.GetQuickChangeRules()
  local maxValue = table.getn(quickChangeRules) or 0

  if maxValue <= RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS then
    maxValue = RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS + 1
  end
  -- Note: maxValue needs to be at least max_rows + 1
  FauxScrollFrame_Update(
    scrollFrame,
    maxValue,
    RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS,
    RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT
  )

  local offset = FauxScrollFrame_GetOffset(scrollFrame)
  for index = 1, RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS do
    local value = index + offset

    if value <= table.getn(quickChangeRules) then
      local row = rulesRows[index]

      row.fromItemIcon:SetTexture(quickChangeRules[value].changeFromItemIcon)
      row.fromItemName:SetText(quickChangeRules[value].changeFromName)
      row.fromItemId = quickChangeRules[value].changeFromItemId
      row.toItemIcon:SetTexture(quickChangeRules[value].changeToItemIcon)
      row.toItemName:SetText(quickChangeRules[value].changeToName)
      row.toItemId = quickChangeRules[value].changeToItemId
      row.delay:SetText(quickChangeRules[value].delay)

      if quickchangeRule.to == row.toItemId and quickchangeRule.from == row.fromItemId then
        me.ShowHighLight(row)
      else
        me.HideHighlight(row)
      end

      row:Show()
    else
      rulesRows[index]:Hide()
    end
  end
end

--[[
  @param {table} frame

  @return {table}
    The created fromScrollFrame
]]--
function me.CreateFromItemList(frame)
  local fromScrollFrame = me.CreateFauxScrollFrame(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME,
    frame,
    RGGM_CONSTANTS.QUICK_CHANGE_FROM_CONTENT_FRAME_WIDTH,
    me.FromFauxScrollFrameOnUpdate,
    fromRows
  )

  fromScrollFrame:ClearAllPoints()
  fromScrollFrame:SetPoint("TOPLEFT", frame, 5, -300)

  return fromScrollFrame
end

--[[
  Update the item to switch scrollframe on vertical scroll events. Gathers all items for
  the currently selected inventory type and displays them. This only includes items that
  have an on use effect.

  @param {table} scrollFrame
]]--
function me.FromFauxScrollFrameOnUpdate(scrollFrame)
  local selectedSlotId = UIDropDownMenu_GetSelectedValue(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_CHOOSE_INVENTORY_TYPE])
  local gearSlot = mod.gearManager.GetGearSlotForSlotId(selectedSlotId)
  local items = mod.itemManager.FindQuickChangeItems(gearSlot.type, true)
  local maxValue = table.getn(items) or 0

  if maxValue <= RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS then
    maxValue = RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS + 1
  end
  -- Note: maxValue needs to be at least max_rows + 1
  FauxScrollFrame_Update(
    scrollFrame,
    maxValue,
    RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS,
    RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT
  )

  local offset = FauxScrollFrame_GetOffset(scrollFrame)

  for i = 1, RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS do
    local value = i + offset

    if value <= table.getn(items) then
      local row = fromRows[i]

      row.icon:SetTexture(items[value].texture)
      row.name:SetText(items[value].name)
      row.itemId = items[value].id
      row.side = RGGM_CONSTANTS.QUICK_CHANGE_SIDE_FROM

      if selectedRule.from == row.itemId then
        me.ShowHighLight(row)
      else
        me.HideHighlight(row)
      end

      row:Show()
    else
      fromRows[i]:Hide()
    end
  end
end

--[[
  @param {table} frame

  @return {table}
    The created toScrollFrame
]]--
function me.CreateToItemList(frame)
  local toScrollFrame = me.CreateFauxScrollFrame(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_TO_SCROLL_FRAME,
    frame,
    RGGM_CONSTANTS.QUICK_CHANGE_TO_CONTENT_FRAME_WIDTH,
    me.ToFauxScrollFrameOnUpdate,
    toRows
  )

  toScrollFrame:ClearAllPoints()
  toScrollFrame:SetPoint("TOPLEFT", frame, 315, -300)

  return toScrollFrame
end

--[[
  Update the item to switch scrollframe on vertical scroll events. Gathers all items for
  the currently selected inventory type and displays them.

  @param {table} scrollFrame
]]--
function me.ToFauxScrollFrameOnUpdate(scrollFrame)
  local selectedSlotId = UIDropDownMenu_GetSelectedValue(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_CHOOSE_INVENTORY_TYPE])
  local gearSlot = mod.gearManager.GetGearSlotForSlotId(selectedSlotId)
  local items = mod.itemManager.FindQuickChangeItems(gearSlot.type, false)
  local maxValue = table.getn(items) or 0

  if maxValue <= RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS then
    maxValue = RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS + 1
  end
  -- Note: maxValue needs to be at least max_rows + 1
  FauxScrollFrame_Update(
    scrollFrame,
    maxValue,
    RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS,
    RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT
  )

  local offset = FauxScrollFrame_GetOffset(scrollFrame)

  for i = 1, RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS do
    local value = i + offset

    if value <= table.getn(items) then
      local row = toRows[i]

      row.icon:SetTexture(items[value].texture)
      row.name:SetText(items[value].name)
      row.itemId = items[value].id
      row.side = RGGM_CONSTANTS.QUICK_CHANGE_SIDE_TO

      if selectedRule.to == row.itemId then
        me.ShowHighLight(row)
      else
        me.HideHighlight(row)
      end

      row:Show()
    else
      toRows[i]:Hide()
    end
  end
end

--[[
  @param {string} scrollFrameName
  @param {table} frame
  @param {number} width
  @param {function} callback
    OnVerticalScroll callback function
  @param {table} storage
    Storage for the created rows

  @return {table}
    The created scrollFrame
]]--
function me.CreateFauxScrollFrame(scrollFrameName, frame, width, callback, storage)
  local scrollFrame = CreateFrame("ScrollFrame", scrollFrameName, frame, "FauxScrollFrameTemplate")
  scrollFrame:SetWidth(width)
  scrollFrame:SetHeight(RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })

  scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    self.ScrollBar:SetValue(offset)
    self.offset = math.floor(offset / RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT + 0.5)
    callback(self)
  end)

  for i = 1, RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS do
    table.insert(storage, me.CreateRowFrames(scrollFrame, i))
  end

  return scrollFrame
end

--[[
  @param {table} frame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateRowFrames(frame, position)
  local row = CreateFrame("Button", RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_CONTENT_FRAME_ROW .. position, frame)
  row:SetSize(frame:GetWidth(), RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", frame, 0, (position -1) * RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * -1)

  local itemIcon = row:CreateTexture(nil, "ARTWORK")
  itemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  itemIcon:SetPoint("LEFT", 5, 0)
  itemIcon:SetSize(
    16,
    16
  )

  row.icon = itemIcon

  local itemNameFontString = row:CreateFontString(nil, "OVERLAY")
  itemNameFontString:SetFont(STANDARD_TEXT_FONT, 14)
  itemNameFontString:SetPoint("LEFT", 16 + 5, 0)
  itemNameFontString:SetWidth(row:GetWidth() - 16 - 5)

  row.name = itemNameFontString

  local highlightTexture = row:CreateTexture(RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_CONTENT_FRAME_HIGHLIGHT, "BACKGROUND")
  highlightTexture:SetSize(row:GetWidth(), row:GetHeight())
  highlightTexture:SetPoint("LEFT")
  highlightTexture:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
  highlightTexture:SetBlendMode("ADD")
  highlightTexture:Hide()

  me.SetupRowEvents(row)

  return row
end

--[[
  Setup script handlers for a row

  @param {table} row
]]--
function me.SetupRowEvents(row)
  row:SetScript("OnEnter", function(self)
    me.ShowHighLight(self)
  end)

  row:SetScript("OnLeave", function(self)
    if self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_FROM and selectedRule.from ~= self.itemId then
      me.HideHighlight(self)
    elseif self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_TO and selectedRule.to ~= self.itemId then
      me.HideHighlight(self)
    end

    if self.side == nil and quickchangeRule.to ~= self.toItemId and quickchangeRule.from ~= self.fromItemId then
      me.HideHighlight(self)
    end
  end)

  row:SetScript("OnClick", function(self)
    if self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_FROM then
      selectedRule.from = self.itemId
      me.FromFauxScrollFrameOnUpdate(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME])
    elseif self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_TO then
      selectedRule.to = self.itemId
      me.ToFauxScrollFrameOnUpdate(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_TO_SCROLL_FRAME])
    else
      quickchangeRule.from = self.fromItemId
      quickchangeRule.to = self.toItemId
      me.RulesScrollFrameOnUpdate(_G[RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_SCROLL_FRAME])
    end
  end)
end

--[[
  Show the highlight of a row

  @param {table} row
]]--
function me.ShowHighLight(row)
  _G[row:GetName() .. "Highlight"]:Show()
end

--[[
  Hide the highlight of a row

  @param {table} row
]]--
function me.HideHighlight(row)
  _G[row:GetName() .. "Highlight"]:Hide()
end
