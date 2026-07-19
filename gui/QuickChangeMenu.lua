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

-- luacheck: globals CreateFrame STANDARD_TEXT_FONT Settings MinimalSliderWithSteppersMixin

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
-- reference to the rules list container
local rulesList
-- reference to the from list container
local fromList
-- reference to the to list container
local toList

--[[
  Build the ui for the quickchange menu

  @param {table} parentFrame
    The addon configuration frame to attach to
]]--
function me.BuildUi(parentFrame)
  if builtMenu then return end

  me.CreateQuickChangeMenuTitle(parentFrame)
  --[[
    Create input elements
  ]]--
  local delaySlider = me.CreateDelaySlider(parentFrame)
  me.CreateAddRuleButton(delaySlider)
  me.CreateRemoveRuleButton(parentFrame)
  me.CreateInventoryTypeDropdown(parentFrame)
  --[[
    Create item lists
  ]]--
  rulesList = me.CreateRulesList(parentFrame)
  -- initial load of rule list
  me.RulesListOnUpdate(rulesList)
  fromList = me.CreateFromItemList(parentFrame)
  -- initial load of from list
  me.FromListOnUpdate(fromList)
  toList = me.CreateToItemList(parentFrame)
  -- initial load of to list
  me.ToListOnUpdate(toList)

  builtMenu = true
end

--[[
  @param {table} contentFrame
]]--
function me.CreateQuickChangeMenuTitle(contentFrame)
  local titleFontString = contentFrame:CreateFontString(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_MENU_TITLE, "OVERLAY", "GameFontNormalLarge")
  titleFontString:SetPoint("TOPLEFT", 16, -16)
  mod.uiHelper.SetColor(titleFontString, RGGM_CONSTANTS.COLOR.TITLE_GOLD)
  titleFontString:SetText(rggm.L["quick_change_title"])
end

--[[
  Create a slider for choosing a delay for a quickchange rule

  @param {table} frame

  @return {table}
    The created delay slider
]]--
function me.CreateDelaySlider(frame)
  local sliderMin = RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MIN
  local sliderMax = RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MAX

  local sliderOptions = Settings.CreateSliderOptions(
    sliderMin,
    sliderMax,
    RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_STEP
  )
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
    return value .. " " .. rggm.L["quick_change_slider_unit"]
  end)
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Max, function() return sliderMax end)
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Min, function() return sliderMin end)
  sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Top, function()
    return rggm.L["quick_change_slider_title"]
  end)

  local delaySlider = CreateFrame(
    "Frame",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_DELAY_SLIDER,
    frame,
    "MinimalSliderWithSteppersTemplate"
  )
  delaySlider:SetWidth(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_WIDTH)
  delaySlider:SetPoint("TOPLEFT", 15, -500)
  delaySlider:Init(
    sliderMin,
    sliderOptions.minValue,
    sliderOptions.maxValue,
    sliderOptions.steps,
    sliderOptions.formatters
  )

  mod.uiHelper.CreateSliderDescription(delaySlider, rggm.L["quick_change_slider_tooltip"])

  return delaySlider
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
  addRuleButton:SetPoint("RIGHT", 170, 0)
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
  local delay = delaySlider.Slider:GetValue()

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
  me.FromListOnUpdate(fromList)
  me.ToListOnUpdate(toList)
  me.RulesListOnUpdate(rulesList)
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
  removeRuleButton:SetPoint("TOPLEFT", 480, -220)
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
  me.RulesListOnUpdate(rulesList)
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
  slider.Slider:SetValue(RGGM_CONSTANTS.QUICK_CHANGE_DELAY_SLIDER_MIN)
end

--[[
  Create dropdown to choose from a list of itemTypes

  @param {table} frame
]]--
function me.CreateInventoryTypeDropdown(frame)
  local chooseCategoryDropdownMenu = mod.uiHelper.CreateSettingsDropdown(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_MENU_INVENTORY_TYPE_DROPDOWN,
    frame,
    {"TOPLEFT", 10, -285},
    120,
    me.InitializeInventoryTypeDropdownMenu
  )
  -- generate once so the button shows the current selection before the menu was ever opened
  chooseCategoryDropdownMenu:GenerateMenu()
end

--[[
  Menu generator for the inventory type dropdown - fills the root description with a radio
  entry per distinct inventory type

  @param {table} _
    The dropdown the menu is generated for (unused)
  @param {table} rootDescription
]]--
function me.InitializeInventoryTypeDropdownMenu(_, rootDescription)
  local gearSlots = mod.gearManager.GetGearSlots()
  local registeredInventoryTypes = {}

  for _, gearSlot in pairs(gearSlots) do
    --[[
      Prevent duplicate entries of inventoryTypes by using the textureId. Slots such
      as upper and lower trinket have the same texture and are thus only added once
    ]]--
    if registeredInventoryTypes[gearSlot.inventoryTypeId] == nil then
      local slotName = gearSlot.simplifiedName or gearSlot.name

      rootDescription:CreateRadio(
        rggm.L[slotName],
        me.IsInventoryTypeSelected,
        me.OnInventoryTypeSelect,
        gearSlot.slotId
      )
      registeredInventoryTypes[gearSlot.inventoryTypeId] = true
    end
  end
end

--[[
  Whether the passed slotId is the currently selected inventory type

  @param {number} slotId

  @return {boolean}
]]--
function me.IsInventoryTypeSelected(slotId)
  return currentSelectedSlotId == slotId
end

--[[
  Callback for when an inventory type is selected

  @param {number} slotId
    The slotId of the selected inventory type
]]--
function me.OnInventoryTypeSelect(slotId)
  me.ResetSelectedItems()

  -- update items in both 'from' and 'to' list
  me.FromListOnUpdate(fromList, slotId)
  me.ToListOnUpdate(toList, slotId)
  currentSelectedSlotId = slotId -- update currently selected slot after both scrollframes where updated
end

--[[
  Create a scrollable frame for displaying configured quickchange rules

  @param {table} frame

  @return {table}
    The created rulesList container
]]--
function me.CreateRulesList(frame)
  return mod.uiHelper.CreateScrollList(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_SCROLL_FRAME,
    frame,
    {"TOPLEFT", 10, -50},
    RGGM_CONSTANTS.QUICK_CHANGE_RULES_CONTENT_FRAME_WIDTH,
    RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS
  )
end

--[[
  @param {table} contentFrame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateRuleRowFrame(contentFrame, position)
  local rowOffset = (position - 1) * RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * -1
  local row = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_RULES_ROW .. position,
    contentFrame,
    "BackdropTemplate"
  )
  row:SetHeight(RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, rowOffset)
  row:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, rowOffset)
  me.ApplyRowBackdrop(row, position)

  local fromItemIcon = mod.uiHelper.CreateItemIconHolder(
    row,
    { "LEFT", 5, 0 },
    RGGM_CONSTANTS.QUICK_CHANGE_ICON_SIZE
  )
  row.fromItemIcon = fromItemIcon

  local fromItemName = row:CreateFontString(nil, "OVERLAY")
  fromItemName:SetFont(STANDARD_TEXT_FONT, 14)
  mod.uiHelper.SetColor(fromItemName, RGGM_CONSTANTS.COLOR.BODY)
  fromItemName:SetPoint("LEFT", fromItemIcon.iconHolder, "RIGHT", 5, 0)
  fromItemName:SetWidth(200)
  fromItemName:SetJustifyH("LEFT")
  row.fromItemName = fromItemName

  local toItemIcon = mod.uiHelper.CreateItemIconHolder(
    row,
    { "LEFT", fromItemName, "RIGHT", 5, 0 },
    RGGM_CONSTANTS.QUICK_CHANGE_ICON_SIZE
  )
  row.toItemIcon = toItemIcon

  local toItemName = row:CreateFontString(nil, "OVERLAY")
  toItemName:SetFont(STANDARD_TEXT_FONT, 14)
  mod.uiHelper.SetColor(toItemName, RGGM_CONSTANTS.COLOR.BODY)
  toItemName:SetPoint("LEFT", toItemIcon.iconHolder, "RIGHT", 5, 0)
  toItemName:SetWidth(200)
  toItemName:SetJustifyH("LEFT")
  row.toItemName = toItemName

  local delay = row:CreateFontString(nil, "OVERLAY")
  delay:SetFont(STANDARD_TEXT_FONT, 14)
  mod.uiHelper.SetColor(delay, RGGM_CONSTANTS.COLOR.BODY)
  delay:SetPoint("RIGHT", 0, 0)
  delay:SetWidth(50)
  row.delay = delay

  local selectedTexture = row:CreateTexture(nil, "BACKGROUND")
  selectedTexture:SetAllPoints()
  selectedTexture:SetColorTexture(1, 0.82, 0, 0.25)
  selectedTexture:Hide()
  row.selectedTexture = selectedTexture

  local hoverTexture = row:CreateTexture(nil, "HIGHLIGHT")
  hoverTexture:SetAllPoints()
  hoverTexture:SetColorTexture(1, 1, 1, 0.15)

  me.SetupRowEvents(row)

  return row
end

--[[
  Apply the striped list row backdrop shared by all quickchange lists

  @param {table} row
  @param {number} position
]]--
function me.ApplyRowBackdrop(row, position)
  row:SetBackdrop({
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  })

  if math.fmod(position, 2) == 0 then
    row:SetBackdropColor(0.37, 0.37, 0.37, .3)
  else
    row:SetBackdropColor(.25, .25, .25, .9)
  end
end

--[[
  Whether the passed row shows the currently selected quickchange rule

  @param {table} rule
    The currently selected quickchange rule ({from, to} with itemId/enchantId/runeAbilityId)
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
  Update the quickchange rules list. Rows are created lazily - one per rule - and
  surplus rows are hidden.

  @param {table} listContainer
]]--
function me.RulesListOnUpdate(listContainer)
  local quickChangeRules = mod.configuration.GetQuickChangeRules()

  for index = 1, math.max(#quickChangeRules, #rulesRows) do
    if index <= #quickChangeRules and rulesRows[index] == nil then
      rulesRows[index] = me.CreateRuleRowFrame(listContainer.content, index)
    end

    local row = rulesRows[index]

    if index <= #quickChangeRules then
      local ruleData = quickChangeRules[index]

      row.fromItemIcon:SetTexture(ruleData.changeFromItemIcon)
      row.fromItemIcon.iconHolder.itemId = ruleData.changeFromItemId
      row.fromItemName:SetText(ruleData.changeFromName)
      row.fromItemId = ruleData.changeFromItemId
      row.fromItemEnchantId = ruleData.changeFromItemEnchantId
      row.fromRuneAbilityId = ruleData.changeFromRuneAbilityId
      row.fromRuneName = ruleData.changeFromRuneName
      row.toItemIcon:SetTexture(ruleData.changeToItemIcon)
      row.toItemIcon.iconHolder.itemId = ruleData.changeToItemId
      row.toItemName:SetText(ruleData.changeToName)
      row.toItemId = ruleData.changeToItemId
      row.toItemEnchantId = ruleData.changeToItemEnchantId
      row.toRuneAbilityId = ruleData.changeToRuneAbilityId
      row.toRuneName = ruleData.changeToRuneName
      row.delay:SetText(ruleData.delay)

      if me.IsRuleMatching(quickchangeRule, row) then
        me.ShowHighLight(row)
      else
        me.HideHighlight(row)
      end

      row:Show()
    else
      row:Hide()
    end
  end

  listContainer.content:SetHeight(
    math.max(#quickChangeRules, RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS) * RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT
  )
end

--[[
  @param {table} frame

  @return {table}
    The created fromList container
]]--
function me.CreateFromItemList(frame)
  return mod.uiHelper.CreateScrollList(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME,
    frame,
    {"TOPLEFT", 5, -320},
    RGGM_CONSTANTS.QUICK_CHANGE_FROM_CONTENT_FRAME_WIDTH,
    RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS
  )
end

--[[
  Update the item to switch from list. Gathers all items for the currently selected
  inventory type and displays them. This only includes items that have an on use effect.
  Rows are created lazily - one per item - and surplus rows are hidden.

  @param {table} listContainer
  @param {number} slotId
    Optional slotId
]]--
function me.FromListOnUpdate(listContainer, slotId)
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

  for i = 1, math.max(#fromCachedQuickChangeItems, #fromRows) do
    if i <= #fromCachedQuickChangeItems and fromRows[i] == nil then
      fromRows[i] = me.CreateRowFrames(listContainer.content, i)
    end

    local row = fromRows[i]

    if i <= #fromCachedQuickChangeItems then
      row.icon:SetTexture(fromCachedQuickChangeItems[i].texture)
      row.icon.iconHolder.itemId = fromCachedQuickChangeItems[i].id
      row.name:SetText(fromCachedQuickChangeItems[i].name)
      row.itemId = fromCachedQuickChangeItems[i].id
      row.enchantId = fromCachedQuickChangeItems[i].enchantId or nil
      row.runeAbilityId = fromCachedQuickChangeItems[i].runeAbilityId or nil
      row.runeName = fromCachedQuickChangeItems[i].runeName or nil
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
      row:Hide()
    end
  end

  listContainer.content:SetHeight(
    math.max(#fromCachedQuickChangeItems, RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS)
    * RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT
  )
end

--[[
  @param {table} frame

  @return {table}
    The created toList container
]]--
function me.CreateToItemList(frame)
  return mod.uiHelper.CreateScrollList(
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_TO_SCROLL_FRAME,
    frame,
    {"TOPLEFT", 310, -320},
    RGGM_CONSTANTS.QUICK_CHANGE_TO_CONTENT_FRAME_WIDTH,
    RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS
  )
end

--[[
  Update the item to switch to list. Gathers all items for the currently selected
  inventory type and displays them. Rows are created lazily - one per item - and
  surplus rows are hidden.

  @param {table} listContainer
  @param {number} slotId
    Optional slotId
]]--
function me.ToListOnUpdate(listContainer, slotId)
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

  for i = 1, math.max(#toCachedQuickChangeItems, #toRows) do
    if i <= #toCachedQuickChangeItems and toRows[i] == nil then
      toRows[i] = me.CreateRowFrames(listContainer.content, i)
    end

    local row = toRows[i]

    if i <= #toCachedQuickChangeItems then
      row.icon:SetTexture(toCachedQuickChangeItems[i].texture)
      row.icon.iconHolder.itemId = toCachedQuickChangeItems[i].id
      row.name:SetText(toCachedQuickChangeItems[i].name)
      row.itemId = toCachedQuickChangeItems[i].id
      row.enchantId = toCachedQuickChangeItems[i].enchantId or nil
      row.runeAbilityId = toCachedQuickChangeItems[i].runeAbilityId or nil
      row.runeName = toCachedQuickChangeItems[i].runeName or nil
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
      row:Hide()
    end
  end

  listContainer.content:SetHeight(
    math.max(#toCachedQuickChangeItems, RGGM_CONSTANTS.QUICK_CHANGE_MAX_ROWS)
    * RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT
  )
end

--[[
  @param {table} contentFrame
  @param {number} position

  @return {table}
    The created row
]]--
function me.CreateRowFrames(contentFrame, position)
  local rowOffset = (position - 1) * RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT * -1
  local row = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_QUICK_CHANGE_CONTENT_FRAME_ROW .. position,
    contentFrame,
    "BackdropTemplate"
  )
  row:SetHeight(RGGM_CONSTANTS.QUICK_CHANGE_ROW_HEIGHT)
  row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, rowOffset)
  row:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, rowOffset)
  me.ApplyRowBackdrop(row, position)

  local itemIcon = mod.uiHelper.CreateItemIconHolder(
    row,
    { "LEFT", 5, 0 },
    RGGM_CONSTANTS.QUICK_CHANGE_ICON_SIZE
  )
  row.icon = itemIcon

  local itemNameFontString = row:CreateFontString(nil, "OVERLAY")
  itemNameFontString:SetFont(STANDARD_TEXT_FONT, 14)
  mod.uiHelper.SetColor(itemNameFontString, RGGM_CONSTANTS.COLOR.BODY)
  itemNameFontString:SetPoint("LEFT", itemIcon.iconHolder, "RIGHT", 5, 0)
  itemNameFontString:SetWidth(
    contentFrame:GetWidth() - RGGM_CONSTANTS.QUICK_CHANGE_ICON_SIZE - 20
  )
  itemNameFontString:SetJustifyH("LEFT")
  row.name = itemNameFontString

  local selectedTexture = row:CreateTexture(nil, "BACKGROUND")
  selectedTexture:SetAllPoints()
  selectedTexture:SetColorTexture(1, 0.82, 0, 0.25)
  selectedTexture:Hide()
  row.selectedTexture = selectedTexture

  local hoverTexture = row:CreateTexture(nil, "HIGHLIGHT")
  hoverTexture:SetAllPoints()
  hoverTexture:SetColorTexture(1, 1, 1, 0.15)

  me.SetupRowEvents(row)

  return row
end

--[[
  Setup script handlers for a row. Hovering is handled by the row's HIGHLIGHT layer
  texture - only the click selection needs a handler.

  @param {table} row
]]--
function me.SetupRowEvents(row)
  row:SetScript("OnClick", function(self)
    if self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_FROM then
      selectedRule.from = {
        ["itemId"] = self.itemId,
        ["enchantId"] = self.enchantId or nil,
        ["runeAbilityId"] = self.runeAbilityId or nil,
        ["runeName"] = self.runeName or nil
      }

      me.FromListOnUpdate(fromList)
    elseif self.side == RGGM_CONSTANTS.QUICK_CHANGE_SIDE_TO then
      selectedRule.to = {
        ["itemId"] = self.itemId,
        ["enchantId"] = self.enchantId or nil,
        ["runeAbilityId"] = self.runeAbilityId or nil,
        ["runeName"] = self.runeName or nil
      }
      me.ToListOnUpdate(toList)
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

      me.RulesListOnUpdate(rulesList)
    end
  end)
end

--[[
  Show the selection highlight of a row

  @param {table} row
]]--
function me.ShowHighLight(row)
  row.selectedTexture:Show()
end

--[[
  Hide the selection highlight of a row

  @param {table} row
]]--
function me.HideHighlight(row)
  row.selectedTexture:Hide()
end
