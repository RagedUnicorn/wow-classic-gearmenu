--[[
  MIT License

  Copyright (c) 2025 Michael Wiesendanger

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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT FauxScrollFrame_Update FauxScrollFrame_GetOffset

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
  Holds the value of the selected slotId from the dropdown
]]--
local currentSelectedSlotId = RGGM_CONSTANTS.CATEGORY_DROPDOWN_DEFAULT_VALUE
--[[
  Holds items that match the currentSelectedSlotId and caches them
]]--
local fromCachedQuickChangeItems
local toCachedQuickChangeItems
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

  ["from"] = {
    ["enchantId"] = {number},
      The enchantId to switch from (left side of a quickchange rule)
    ["itemId"] = {number}
      The itemId to switch from (left side of a quickchange rule)
  },
  ["to"] = {
    ["enchantId"] = {number},
      The enchantId to switch to (right side of a quickchange rule)
    ["itemId"] = {number}
      The itemId to switch to (right side of a quickchange rule)
  }
]]--
local quickchangeRule = {
  ["from"] = nil,
  ["to"] = nil
}
-- track whether the menu was already built
local builtMenu = false
-- reference to rules scrollFrame
local rulesScrollFrame
-- reference to from scrollFrame
local fromScrollFrame
-- reference to to scrollFrame
local toScrollFrame

--[[
  Build the ui for the quickchange menu

  @param {table} parentFrame
    The addon configuration frame to attach to
]]--
function me.BuildUi(parentFrame)
  if builtMenu then return end

  local quickChangeContentFrame = me.CreateQuickChangeContentFrame(parentFrame)
  me.CreateQuickChangeMenuTitle(quickChangeContentFrame)
  --[[
    Create input elements
  ]]--
  local delaySlider = me.CreateDelaySlider(quickChangeContentFrame)
  me.CreateAddRuleButton(delaySlider)
  me.CreateRemoveRuleButton(quickChangeContentFrame)
  me.CreateInventoryTypeDropdown(quickChangeContentFrame)
  --[[
    Create item lists
  ]]--
  rulesScrollFrame = me.CreateRulesList(quickChangeContentFrame)
  -- initial load of rule list
  me.RulesScrollFrameOnUpdate(rulesScrollFrame)
  fromScrollFrame = me.CreateFromItemList(quickChangeContentFrame)
  -- initial load of from list
  me.FromFauxScrollFrameOnUpdate(fromScrollFrame)
  toScrollFrame = me.CreateToItemList(quickChangeContentFrame)
  -- initial load of to list
  me.ToFauxScrollFrameOnUpdate(toScrollFrame)

  builtMenu = true
end

--[[
  @param {table} parentFrame

  @return {table}
   The created quickchange content frame
]]--
function me.CreateQuickChangeContentFrame(parentFrame)
  local quickChangeContentFrame = CreateFrame(
    "Frame", RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_MENU, parentFrame)
  quickChangeContentFrame:SetWidth(RGGM_CONSTANTS.INTERFACE_PANEL_CONTENT_FRAME_WIDTH)
  quickChangeContentFrame:SetHeight(RGGM_CONSTANTS.INTERFACE_PANEL_CONTENT_FRAME_HEIGHT)
  quickChangeContentFrame:SetPoint("TOPLEFT", parentFrame, 5, -7)

  return quickChangeContentFrame
end

--[[
  @param {table} contentFrame
]]--
function me.CreateQuickChangeMenuTitle(contentFrame)
  local titleFontString = contentFrame:CreateFontString(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_MENU_TITLE, "OVERLAY")
  titleFontString:SetFont(STANDARD_TEXT_FONT, 20)
  titleFontString:SetPoint("TOP", 0, -20)
  titleFontString:SetSize(contentFrame:GetWidth(), 20)
  titleFontString:SetText(rggm.L["quick_change_title"])
end

--[[
  Create a slider for choosing a delay for a quickchange rule

  @param {table} frame

  @return {table}
    The created delay slider
]]--
function me.CreateDelaySlider(frame)
  local delaySlider = CreateFrame(
    "Slider",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_DELAY_SLIDER,
    frame,
    "UISliderTemplateWithLabels"
  )
  delaySlider:SetWidth(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_WIDTH)
  delaySlider:SetHeight(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_HEIGHT)
  delaySlider:SetOrientation('HORIZONTAL')
  delaySlider:SetPoint("TOPLEFT", 15, -450)
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

  return delaySlider
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

  @param {table} parentFrame
]]--
function me.CreateAddRuleButton(parentFrame)
  local addRuleButton = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_ADD_RULE_BUTTON,
    parentFrame,
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

  @param {table} self
]]--
function me.AddRuleOnClick(self)
  local delaySlider = self:GetParent()
  local delay = delaySlider:GetValue()

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

  mod.quickChange.AddQuickChangeRule(selectedRule, delay)
  me.ResetSelectedItems()
  me.ResetDelaySlider(delaySlider)
  -- update items in 'from', 'to' and the rules list
  me.FromFauxScrollFrameOnUpdate(fromScrollFrame)
  me.ToFauxScrollFrameOnUpdate(toScrollFrame)
  me.RulesScrollFrameOnUpdate(rulesScrollFrame)
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

  mod.quickChange.RemoveQuickChangeRule(quickchangeRule)
  me.ResetSelectedRule()
  me.RulesScrollFrameOnUpdate(rulesScrollFrame)
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
Reset the delay slider to its initial value

@param {table} slider
]]--
function me.ResetDelaySlider(slider)
  slider:SetValue(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MIN)
end

--[[
  Create dropdown to choose from a list of itemTypes

  @param {table} frame
]]--
function me.CreateInventoryTypeDropdown(frame)
  local chooseCategoryDropdownMenu = mod.libUiDropDownMenu.CreateUiDropDownMenu(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_MENU_INVENTORY_TYPE_DROPDOWN,
    frame
  )

  chooseCategoryDropdownMenu:SetPoint("TOPLEFT", 0, -250)

  mod.libUiDropDownMenu.UiDropDownMenu_SetWidth(chooseCategoryDropdownMenu, 100)
  mod.libUiDropDownMenu.UiDropDownMenu_Initialize(chooseCategoryDropdownMenu, me.InitializeInventoryTypeDropdownMenu)
end

--[[
  Initialize dropdownmenu for inventory types

  @param {table} self
]]--
function me.InitializeInventoryTypeDropdownMenu(self)
  local gearSlots = mod.gearManager.GetGearSlots()
  local registeredInventoryTypes = {}

  for _, gearSlot in pairs(gearSlots) do
    --[[
      Prevent duplicate entries of inventoryTypes by using the textureId. Slots such
      as upper and lower trinket have the same texture and are thus only added once
    ]]--
    if registeredInventoryTypes[gearSlot.inventoryTypeId] == nil then
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

      mod.libUiDropDownMenu.UiDropDownMenu_AddButton(button)
      registeredInventoryTypes[gearSlot.inventoryTypeId] = true
    end
  end

  if mod.libUiDropDownMenu.UiDropDownMenu_GetSelectedValue(self) == nil then
    mod.libUiDropDownMenu.UiDropDownMenu_SetSelectedValue(self, RGGM_CONSTANTS.CATEGORY_DROPDOWN_DEFAULT_VALUE)
  end
end

--[[
  Callback for optionsmenu dropdowns

  @param {table} self
]]
function me.InventoryTypeDropDownMenuCallback(self)
  mod.libUiDropDownMenu.UiDropDownMenu_SetSelectedValue(self:GetParent().dropdown, self.value)

  me.ResetSelectedItems()

  -- update items in both 'from' and 'to' list
  me.FromFauxScrollFrameOnUpdate(fromScrollFrame, self.value)
  me.ToFauxScrollFrameOnUpdate(toScrollFrame, self.value)
  currentSelectedSlotId = self.value -- update currently selected slot after both scrollframes where updated
end

--[[
  Create a scrollable frame for displaying configured quickchange rules

  @param {table} frame

  @return {table}
    The created rulesScrollFrame
]]--
function me.CreateRulesList(frame)
  local scrollFrame = CreateFrame(
    "ScrollFrame",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_SCROLL_FRAME,
    frame,
    "FauxScrollFrameTemplate, BackdropTemplate"
  )
  scrollFrame:SetWidth(RGGM_CONSTANTS.QUICK_CHANGE_RULES_CONTENT_FRAME_WIDTH)
  scrollFrame:SetHeight(
    RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS
  )
  scrollFrame:SetPoint("TOPLEFT", 10, -50)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })

  scrollFrame:SetScript("OnVerticalScroll", me.RuleListOnVerticalScroll)

  for i = 1, RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS do
    table.insert(rulesRows, me.CreateRuleRowFrame(scrollFrame, i))
  end

  return scrollFrame
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

  local fromContainerFrame = mod.uiHelper.CreateMouseOverEventContainer(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_MOUSEOVER_CONTAINER_LEFT,
    row,
    { "LEFT", 0, 0 }
  )

  local fromItemIcon = fromContainerFrame:CreateTexture(nil, "ARTWORK")
  fromItemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  fromItemIcon:SetAllPoints()
  row.fromItemIcon = fromItemIcon

  local fromItemName = row:CreateFontString(nil, "OVERLAY")
  fromItemName:SetFont(STANDARD_TEXT_FONT, 14)
  fromItemName:SetPoint("LEFT", row.fromItemIcon, 0, 0)
  fromItemName:SetWidth(250)
  row.fromItemName = fromItemName

  local toContainerFrame = mod.uiHelper.CreateMouseOverEventContainer(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_MOUSEOVER_CONTAINER_RIGHT,
    row,
    { "RIGHT", row.fromItemName, 50, 0 }
  )

  local toItemIcon = toContainerFrame:CreateTexture(nil, "ARTWORK")
  toItemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  toItemIcon:SetAllPoints()
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
  me.SetupContainerEvents(fromContainerFrame)
  me.SetupContainerEvents(toContainerFrame)

  return row
end

--[[
  Check if a rule is matching

  @param {table} rule
  @param {table} row
]]--
function me.IsRuleMatching(rule, row)
  if not rule.to or not rule.from then
    return false
  end

  local to = rule.to
  local from = rule.from

  return (to.itemId == row.toItemId)
    and (from.itemId == row.fromItemId)
    and (to.enchantId == row.toItemEnchantId)
    and (from.enchantId == row.fromItemEnchantId)
    and (to.runeAbilityId == row.toRuneAbilityId)
    and (from.runeAbilityId == row.fromRuneAbilityId)
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

    if value <= #quickChangeRules then
      local ruleData = quickChangeRules[value]
      local row = rulesRows[index]

      row.fromItemIcon:SetTexture(ruleData.changeFromItemIcon)
      row.fromItemName:SetText(ruleData.changeFromName)
      row.fromItemId = ruleData.changeFromItemId
      row.fromItemEnchantId = ruleData.changeFromItemEnchantId
      row.fromRuneAbilityId = ruleData.changeFromRuneAbilityId
      row.fromRuneName = ruleData.changeFromRuneName
      row.toItemIcon:SetTexture(ruleData.changeToItemIcon)
      row.toItemName:SetText(ruleData.changeToName)
      row.toItemId = ruleData.changeToItemId
      row.toItemEnchantId = ruleData.changeToItemEnchantId
      row.toRuneAbilityId = ruleData.changeToRuneAbilityId
      row.toRuneName = ruleData.changeToRuneName
      row.delay:SetText(ruleData.delay)

      if me.IsRuleMatching(ruleData, row) then
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
  local scrollFrame = me.CreateFauxScrollFrame(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME,
    frame,
    RGGM_CONSTANTS.QUICK_CHANGE_FROM_CONTENT_FRAME_WIDTH,
    me.FromFauxScrollFrameOnUpdate,
    fromRows
  )

  scrollFrame:ClearAllPoints()
  scrollFrame:SetPoint("TOPLEFT", frame, 5, -300)

  return scrollFrame
end

--[[
  Update the item to switch scrollframe on vertical scroll events. Gathers all items for
  the currently selected inventory type and displays them. This only includes items that
  have an on use effect.

  @param {table} scrollFrame
  @param {number} slotId
    Optional slotId
]]--
function me.FromFauxScrollFrameOnUpdate(scrollFrame, slotId)
  local selectedSlotId

  if slotId ~= nil then
    selectedSlotId = slotId
  else
    selectedSlotId = currentSelectedSlotId
  end

  if selectedSlotId ~= currentSelectedSlotId or fromCachedQuickChangeItems == nil then
    local gearSlot = mod.gearManager.GetGearSlotForSlotId(selectedSlotId)
    -- invalidate cache
    fromCachedQuickChangeItems = nil
    fromCachedQuickChangeItems = mod.itemManager.FindQuickChangeItems(gearSlot.type, true)
    mod.logger.LogDebug(
      me.tag, "Invalidated 'from' cached item list and updated items for new slotId: " .. selectedSlotId)
  end

  local maxValue = #fromCachedQuickChangeItems or 0

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

    if value <= #fromCachedQuickChangeItems then
      local row = fromRows[i]

      row.icon:SetTexture(fromCachedQuickChangeItems[value].texture)
      row.name:SetText(fromCachedQuickChangeItems[value].name)
      row.itemId = fromCachedQuickChangeItems[value].id
      row.enchantId = fromCachedQuickChangeItems[value].enchantId or nil
      row.runeAbilityId = fromCachedQuickChangeItems[value].runeAbilityId or nil
      row.runeName = fromCachedQuickChangeItems[value].runeName or nil
      row.side = RGGM_CONSTANTS.QUICK_CHANGE_SIDE_FROM

      local isMatchingFromRule =
        selectedRule.from ~= nil and
        selectedRule.from.itemId == row.itemId and
        selectedRule.from.enchantId == row.enchantId and
        selectedRule.from.runeAbilityId == row.runeAbilityId

      if isMatchingFromRule then
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
  local scrollFrame = me.CreateFauxScrollFrame(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_TO_SCROLL_FRAME,
    frame,
    RGGM_CONSTANTS.QUICK_CHANGE_TO_CONTENT_FRAME_WIDTH,
    me.ToFauxScrollFrameOnUpdate,
    toRows
  )

  scrollFrame:ClearAllPoints()
  scrollFrame:SetPoint("TOPLEFT", frame, 310, -300)

  return scrollFrame
end

--[[
  Update the item to switch scrollframe on vertical scroll events. Gathers all items for
  the currently selected inventory type and displays them.

  @param {table} scrollFrame
  @param {number} slotId
    Optional slotId
]]--
function me.ToFauxScrollFrameOnUpdate(scrollFrame, slotId)
  local selectedSlotId

  if slotId ~= nil then
    selectedSlotId = slotId
  else
    selectedSlotId = currentSelectedSlotId
  end

  if selectedSlotId ~= currentSelectedSlotId or toCachedQuickChangeItems == nil then
    local gearSlot = mod.gearManager.GetGearSlotForSlotId(selectedSlotId)
    -- invalidate cache
    toCachedQuickChangeItems = nil
    toCachedQuickChangeItems = mod.itemManager.FindQuickChangeItems(gearSlot.type, false)
    mod.logger.LogDebug(
      me.tag, "Invalidated 'to' cached item list and updated items for new slotId: " .. selectedSlotId)
  end

  local maxValue = #toCachedQuickChangeItems or 0

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

    if value <= #toCachedQuickChangeItems then
      local row = toRows[i]

      row.icon:SetTexture(toCachedQuickChangeItems[value].texture)
      row.name:SetText(toCachedQuickChangeItems[value].name)
      row.itemId = toCachedQuickChangeItems[value].id
      row.enchantId = toCachedQuickChangeItems[value].enchantId or nil
      row.runeAbilityId = toCachedQuickChangeItems[value].runeAbilityId or nil
      row.runeName = toCachedQuickChangeItems[value].runeName or nil
      row.side = RGGM_CONSTANTS.QUICK_CHANGE_SIDE_TO

      local isMatchingToRule =
        selectedRule.to ~= nil and
        selectedRule.to.itemId == row.itemId and
        selectedRule.to.enchantId == row.enchantId and
        selectedRule.to.runeAbilityId == row.runeAbilityId

      if isMatchingToRule then
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
  local scrollFrame = CreateFrame("ScrollFrame", scrollFrameName, frame, "FauxScrollFrameTemplate, BackdropTemplate")
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

  local containerFrame = mod.uiHelper.CreateMouseOverEventContainer(
    nil,
    row,
    { "LEFT", 5, 0 }
  )

  local itemIcon = containerFrame:CreateTexture(nil, "ARTWORK")
  itemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  itemIcon:SetAllPoints()
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
  me.SetupContainerEvents(containerFrame)

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
    if self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_FROM then
      if selectedRule.from == nil or selectedRule.from.itemId ~= self.itemId then
        me.HideHighlight(self)
      elseif selectedRule.from.enchantId ~= self.enchantId then
        me.HideHighlight(self)
      elseif selectedRule.from.runeAbilityId ~= self.runeAbilityId then
        me.HideHighlight(self)
      end

      return
    end

    if self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_TO then
      if selectedRule.to == nil or selectedRule.to.itemId ~= self.itemId then
        me.HideHighlight(self)
      elseif selectedRule.to.enchantId ~= self.enchantId then
        me.HideHighlight(self)
      elseif selectedRule.to.runeAbilityId ~= self.runeAbilityId then
        me.HideHighlight(self)
      end

      return
    end

    if self.side == nil then
      if quickchangeRule.from == nil or quickchangeRule.to == nil or
          quickchangeRule.from.itemId ~= self.fromItemId or quickchangeRule.to.itemId ~= self.toItemId then
        me.HideHighlight(self)
      elseif quickchangeRule.from.enchantId ~= self.fromItemEnchantId
          or quickchangeRule.to.enchantId ~= self.toItemEnchantId then
        me.HideHighlight(self)
      elseif quickchangeRule.from.runeAbilityId ~= self.fromRuneAbilityId
          or quickchangeRule.to.runeAbilityId ~= self.toRuneAbilityId then
        me.HideHighlight(self)
      end

      return
    end
  end)

  row:SetScript("OnClick", function(self)
    if self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_FROM then
      selectedRule.from = {
        ["itemId"] = self.itemId,
        ["enchantId"] = self.enchantId or nil,
        ["runeAbilityId"] = self.runeAbilityId or nil,
        ["runeName"] = self.runeName or nil
      }

      me.FromFauxScrollFrameOnUpdate(fromScrollFrame)
    elseif self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_TO then
      selectedRule.to = {
        ["itemId"] = self.itemId,
        ["enchantId"] = self.enchantId or nil,
        ["runeAbilityId"] = self.runeAbilityId or nil,
        ["runeName"] = self.runeName or nil
      }
      me.ToFauxScrollFrameOnUpdate(toScrollFrame)
    else
      quickchangeRule.from = {
        ["itemId"] = self.fromItemId,
        ["enchantId"] = self.fromItemEnchantId or nil,
        ["runeAbilityId"] = self.fromRuneAbilityId or nil,
        ["runeName"] = self.fromRuneName or nil
      }
      quickchangeRule.to = {
        ["itemId"] = self.toItemId,
        ["enchantId"] = self.toItemEnchantId or nil,
        ["runeAbilityId"] = self.toRuneAbilityId or nil,
        ["runeName"] = self.toRuneName or nil
      }

      me.RulesScrollFrameOnUpdate(rulesScrollFrame)
    end
  end)
end

--[[
  Setup script handlers for a container frame

  @param {table} containerFrame
]]--
function me.SetupContainerEvents(containerFrame)
  containerFrame:SetScript("OnEnter", function(self)
    local parentFrame = self:GetParent()
    local item

    if self:GetName() == RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_MOUSEOVER_CONTAINER_LEFT then
      item = {
        ["itemId"] = parentFrame.fromItemId,
        ["enchantId"] = parentFrame.fromItemEnchantId,
        ["runeAbilityId"] = parentFrame.fromRuneAbilityId,
        ["runeName"] = parentFrame.fromRuneName
      }
    elseif self:GetName() == RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_MOUSEOVER_CONTAINER_RIGHT then
      item = {
        ["itemId"] = parentFrame.toItemId,
        ["enchantId"] = parentFrame.toItemEnchantId,
        ["runeAbilityId"] = parentFrame.toRuneAbilityId,
        ["runeName"] = parentFrame.toRuneName
      }
    else
      item = {
        ["itemId"] = parentFrame.itemId,
        ["enchantId"] = parentFrame.enchantId,
        ["runeAbilityId"] = parentFrame.runeAbilityId,
        ["runeName"] = parentFrame.runeName
      }
    end

    mod.tooltip.UpdateTooltipForItem(item)
    me.ShowHighLight(containerFrame:GetParent())
  end)

  containerFrame:SetScript("OnLeave", function()
    mod.tooltip.TooltipClear()
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
