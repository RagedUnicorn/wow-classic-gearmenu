--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

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

-- luacheck: globals CreateFrame UIParent GetBindingText GetBindingKey GetInventoryItemID GetItemCooldown
-- luacheck: globals GetInventoryItemLink GetItemInfo GetContainerItemInfo C_Timer MouseIsOver
-- luacheck: globals CursorCanGoInSlot EquipCursorItem ClearCursor IsInventoryItemLocked PickupInventoryItem
-- luacheck: globals InCombatLockdown

local mod = rggm
local me = {}

mod.gearBar = me

me.tag = "GearBar"

--[[
  Local references to heavily accessed ui elements
]]--
local gearSlots = {}

--[[
  Build the initial gearBar for equiped items

  @return {table}
    The created gearBarFrame
]]--
function me.BuildGearBar()
  local gearBarFrame = CreateFrame("Frame", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME, UIParent)
  gearBarFrame:SetWidth(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_WIDTH + RGGM_CONSTANTS.ELEMENT_GEAR_BAR_WIDTH_MARGIN
  )
  gearBarFrame:SetHeight(RGGM_CONSTANTS.ELEMENT_GEAR_BAR_HEIGHT)

  if not mod.configuration.IsGearBarLocked() then
    gearBarFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
    })
  end

  gearBarFrame:SetPoint("CENTER", 0, 0)
  gearBarFrame:SetMovable(true)
  gearBarFrame:SetClampedToScreen(true)

  mod.uiHelper.LoadFramePosition(gearBarFrame, RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME)
  me.SetupDragFrame(gearBarFrame)

  -- create all gearSlots
  for i = 1, RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_AMOUNT do
    me.CreateGearSlot(gearBarFrame, i)
  end

  return gearBarFrame
end

--[[
  Create a single gearSlot. Note that a gearSlot inherits from the SecureActionButtonTemplate to enable the usage
  of clicking items.

  @param {table} gearBarFrame
    The gearBarFrame where the gearSlot gets attached to
  @param {number} position
    Position on the gearBar

  @return {table}
    The created gearSlot
]]--
function me.CreateGearSlot(gearBarFrame, position)
  local gearSlot = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT .. position,
    gearBarFrame,
    "SecureActionButtonTemplate"
  )

  gearSlot:SetFrameLevel(gearBarFrame:GetFrameLevel() + 1)
  gearSlot:SetSize(RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_SIZE, RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_SIZE)
  gearSlot:SetPoint(
    "LEFT",
    gearBarFrame,
    "LEFT",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_X + (position - 1) * RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_SIZE,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_Y
  )

  local backdrop = {
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    edgeFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background",
    tile = false,
    tileSize = 32,
    edgeSize = 20,
    insets = {
      left = 12,
      right = 12,
      top = 12,
      bottom = 12
    }
  }

  local slot = mod.configuration.GetSlotForPosition(position)
  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)

  if gearSlotMetaData ~= nil then
    gearSlot:SetAttribute("type1", "item")
    gearSlot:SetAttribute("item", gearSlotMetaData.slotId)
  end

  gearSlot:SetBackdrop(backdrop)
  gearSlot:SetBackdropColor(0.15, 0.15, 0.15, 1)
  gearSlot:SetBackdropBorderColor(0, 0, 0, 1)

  gearSlot.combatQueueSlot = me.CreateCombatQueueSlot(gearSlot)
  gearSlot.keyBindingText = me.CreateKeyBindingText(gearSlot, position)
  gearSlot.position = position

  mod.uiHelper.CreateHighlightFrame(gearSlot)
  mod.uiHelper.PrepareSlotTexture(gearSlot)
  mod.uiHelper.CreateCooldownOverlay(
    gearSlot,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_COOLDOWN_FRAME,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_COOLDOWN_SIZE
  )

  me.SetupEvents(gearSlot)
  -- store gearSlot
  table.insert(gearSlots, gearSlot)
  -- initially hide slots
  gearSlot:Show()

  return gearSlot
end

--[[
  @param {table} gearSlot

  @return {table}
    The created combatQueueSlot
]]--
function me.CreateCombatQueueSlot(gearSlot)
  local combatQueueSlot = CreateFrame("Frame", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_COMBAT_QUEUE_SLOT, gearSlot)
  combatQueueSlot:SetSize(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_COMBAT_QUEUE_SLOT_SIZE,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_COMBAT_QUEUE_SLOT_SIZE
  )
  combatQueueSlot:SetPoint("TOPRIGHT", gearSlot)

  local iconHolderTexture = combatQueueSlot:CreateTexture(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_ICON_TEXTURE_NAME,
    "LOW",
    nil
  )
  iconHolderTexture:SetPoint("TOPLEFT", combatQueueSlot, "TOPLEFT")
  iconHolderTexture:SetPoint("BOTTOMRIGHT", combatQueueSlot, "BOTTOMRIGHT")
  iconHolderTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

  combatQueueSlot.icon = iconHolderTexture

  return combatQueueSlot
end

--[[
  @param {table} gearSlot
  @param {number} position

  @return {table}
    The created keybindingFontString
]]--
function me.CreateKeyBindingText(gearSlot, position)
  local keybindingFontString = gearSlot:CreateFontString(nil, "OVERLAY")
  keybindingFontString:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
  keybindingFontString:SetTextColor(1, .82, 0, 1)
  keybindingFontString:SetPoint("TOP", 0, 1)
  keybindingFontString:SetSize(gearSlot:GetWidth(), 20)
  keybindingFontString:SetText(
    GetBindingText(GetBindingKey("CLICK GM_GearBarSlot_" .. position .. ":LeftButton"), "KEY_", 1)
  )

  if mod.configuration.IsShowKeyBindingsEnabled() then
    keybindingFontString:Show()
  else
    keybindingFontString:Hide()
  end

  return keybindingFontString
end

--[[
  Update keybindings whenever the event UPDATE_BINDINGS is fired
]]--
function me.UpdateKeyBindings()
  for index, gearSlot in pairs(gearSlots) do
    local keyBindingText = GetBindingText(GetBindingKey("CLICK GM_GearBarSlot_" .. index .. ":LeftButton"), "KEY_", 1)

    if keyBindingText ~= nil then
      gearSlot.keyBindingText:SetText(keyBindingText)
    end
  end
end

--[[
  Update the gearBar after one of the slots was hidden or shown again
]]--
function me.UpdateGearBar()
  if InCombatLockdown() then
    -- temporary fix for in combat configuration of slots
    mod.logger.LogError(me.tag, "Unable to update slots in combat. Please /reload after your are out of combat")
    return
  end

  local slotCount = 0

  for index, gearSlot in pairs(gearSlots) do
    local slot = mod.configuration.GetSlotForPosition(index)
    local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)

    if gearSlotMetaData ~= nil then
      -- slot is active
      gearSlot:SetAttribute("type1", "item")
      gearSlot:SetAttribute("item", gearSlotMetaData.slotId)
      me.UpdateTexture(gearSlot, gearSlotMetaData)
      slotCount = slotCount + 1
      gearSlot:Show()
    else
      -- slot is inactive
      gearSlot:Hide()
    end
  end

  local gearBarWidth = slotCount * RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_SIZE
    + RGGM_CONSTANTS.ELEMENT_GEAR_BAR_WIDTH_MARGIN
  _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME]:SetWidth(gearBarWidth)

  me.UpdateSlotPosition()
end

--[[
  Update the gearBar after one of PLAYER_EQUIPMENT_CHANGED, BAG_UPDATE events
]]--
function me.UpdateGearBarTextures()
  for index, gearSlot in pairs(gearSlots) do
    local slot = mod.configuration.GetSlotForPosition(index)
    local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)

    if gearSlotMetaData ~= nil then
      me.UpdateTexture(gearSlot, gearSlotMetaData)
    end
  end
end

--[[
  Update the slotPositions based on the slots that are inactive
]]--
function me.UpdateSlotPosition()
  local position = 1

  for index, gearSlot in pairs(gearSlots) do
    local slotId = mod.configuration.GetSlotForPosition(index)

    if slotId == 0 then
      -- slot is inactive
      position = position -1
    end

    if position < 0 then
      position = 0
    end

    gearSlot:SetPoint(
      "LEFT",
      _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME],
      "LEFT",
      RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_X + (position - 1) * RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_SIZE,
      RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_Y
    )

    position = position + 1
  end
end

--[[
  Update the cooldown of items on gearBar after a BAG_UPDATE_COOLDOWN event or a manual
  invoke after a configuration change (show/hide) cooldowns
]]--
function me.UpdateGearSlotCooldown()
  for index, gearSlot in pairs(gearSlots) do
    local slot = mod.configuration.GetSlotForPosition(index)
    local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)

    if gearSlotMetaData ~= nil then
      local itemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlotMetaData.slotId)

      if itemId ~= nil then
        if mod.configuration.IsShowCooldownsEnabled() then
          local startTime, duration = GetItemCooldown(itemId)
          gearSlot.cooldownOverlay:SetCooldown(startTime, duration)
        else
          gearSlot.cooldownOverlay:Hide()
        end
      end
    end
  end
end

--[[
  Update the button texture style and add icon for the currently worn item. If no item is worn
  the default icon is displayed

  @param {table} gearSlot
  @param {table} slotMetaData
]]--
function me.UpdateTexture(gearSlot, slotMetaData)
  local itemLink = GetInventoryItemLink(RGGM_CONSTANTS.UNIT_ID_PLAYER, slotMetaData.slotId)

  if itemLink then
    local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemLink)
    -- If an actual item was found in the inventoryslot said icon is used
    gearSlot:SetNormalTexture(itemIcon or slotMetaData.textureId)
  else
    -- If no item can be found in the inventoryslot use the default icon
    gearSlot:SetNormalTexture(slotMetaData.textureId)
    gearSlot.cooldownOverlay:Hide() -- hide cooldown if there is no actual item
  end
end

--[[
  Update the visual representation of the combatQueue on the gearBar

  @param {table} slotId
]]--
function me.UpdateCombatQueue(slotId)
  local position = mod.configuration.GetSlotForSlotId(slotId)
  local combatQueue = mod.combatQueue.GetCombatQueueStore()
  local itemId = combatQueue[slotId]
  local icon

  for i = 1, table.getn(gearSlots) do
    if gearSlots[i].position == position then
      icon = gearSlots[i].combatQueueSlot.icon
    end
  end

  if itemId then
    local bagNumber, bagPos = mod.itemManager.FindItemInBag(itemId)
    if bagNumber then
      icon:SetTexture(GetContainerItemInfo(bagNumber, bagPos))
      icon:Show()
    end
  else
    icon:Hide()
  end
end

--[[
  @param {table} frame
    The frame to attach the drag handlers to
]]--
function me.SetupDragFrame(frame)
  frame:SetScript("OnMouseDown", me.StartDragFrame)
  frame:SetScript("OnMouseUp", me.StopDragFrame)
end

--[[
  Frame callback to start moving the passed (self) frame

  @param {table} self
]]--
function me.StartDragFrame(self)
  if mod.configuration.IsGearBarLocked() then return end

  self:StartMoving()
end

--[[
  Frame callback to stop moving the passed (self) frame

  @param {table} self
]]--
function me.StopDragFrame(self)
  if mod.configuration.IsGearBarLocked() then return end

  self:StopMovingOrSizing()

  local point, relativeTo, relativePoint, posX, posY = self:GetPoint()

  mod.configuration.SaveUserPlacedFramePosition(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME,
    point,
    relativeTo,
    relativePoint,
    posX,
    posY
  )
end

--[[
  Setup event for a changeSlot

  @param {table} gearSlot
]]--
function me.SetupEvents(gearSlot)
  --[[
    Note: SecureActionButtons ignore right clicks by default - reenable right clicks
  ]]--
  if mod.configuration.IsFastpressEnabled() then
    gearSlot:RegisterForClicks("LeftButtonDown", "RightButtonDown")
  else
    gearSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  end
  gearSlot:RegisterForDrag("LeftButton")
  --[[
    Replacement for OnCLick. Do not overwrite click event for protected button
  ]]--
  gearSlot:SetScript("PreClick", function(self, button, down)
    me.GearSlotOnClick(self, button, down)
  end)

  gearSlot:SetScript("OnEnter", function(self)
    me.GearSlotOnEnter(self)
  end)

  gearSlot:SetScript("OnLeave", function(self)
    me.GearSlotOnLeave(self)
  end)

  gearSlot:SetScript("OnReceiveDrag", function(self)
    me.GearSlotOnReceiveDrag(self)
  end)

  gearSlot:SetScript("OnDragStart", function(self)
    me.GearSlotOnDragStart(self)
  end)
end

--[[
  Update clickhandler to match fastpress configuration. Only register to events that are needed
]]--
function me.UpdateClickHandler()
  for _, gearSlot in pairs(gearSlots) do
    if mod.configuration.IsFastpressEnabled() then
      gearSlot:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    else
      gearSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end
  end
end

--[[
  Callback for a gearBarSlot OnClick

  @param {table} self
  @param {string} button
]]--
function me.GearSlotOnClick(self, button)
  self.highlightFrame:Show()

  if button == "LeftButton" then
    self.highlightFrame:SetBackdropBorderColor(unpack(RGGM_CONSTANTS.HIGHLIGHT.highlight))
  elseif button == "RightButton" then
    self.highlightFrame:SetBackdropBorderColor(unpack(RGGM_CONSTANTS.HIGHLIGHT.remove))

    local slot = mod.configuration.GetSlotForPosition(self.position)
    local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)
    mod.combatQueue.RemoveFromQueue(gearSlotMetaData.slotId)
  end

  C_Timer.After(.5, function()
    if MouseIsOver(_G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME]) then
      self.highlightFrame:SetBackdropBorderColor(unpack(RGGM_CONSTANTS.HIGHLIGHT.hover))
    else
      self.highlightFrame:Hide()
    end
  end)
end

--[[
  Callback for a changeSlot OnEnter

  @param {table} self
]]--
function me.GearSlotOnEnter(self)
  self.highlightFrame:SetBackdropBorderColor(unpack(RGGM_CONSTANTS.HIGHLIGHT.hover))
  self.highlightFrame:Show()
  mod.changeMenu.UpdateChangeMenu(self)

  local slot = mod.configuration.GetSlotForPosition(self.position)
  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)

  if gearSlotMetaData ~= nil then
    mod.tooltip.BuildTooltipForWornItem(gearSlotMetaData.slotId)
  end
end

--[[
  Callback for a gearSlot OnLeave

  @param {table} self
]]--
function me.GearSlotOnLeave(self)
  self.highlightFrame:Hide()
  mod.tooltip.TooltipClear()
end

--[[
  Callback for a gearSlot OnReceiveDrag

  @param {table} self
]]--
function me.GearSlotOnReceiveDrag(self)
  if not mod.configuration.IsDragAndDropEnabled() then return end

  local slot = mod.configuration.GetSlotForPosition(self.position)
  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)
  -- abort if no item could be found
  if gearSlotMetaData == nil then return end

  if CursorCanGoInSlot(gearSlotMetaData.slotId) then
    EquipCursorItem(gearSlotMetaData.slotId)
  else
    mod.logger.LogInfo(me.tag, "Invalid item for slotId - " .. gearSlotMetaData.slotId)
    ClearCursor() -- clear cursor from item
  end
end

--[[
  Callback for a gearSlot OnDragStart

  @param {table} self
]]--
function me.GearSlotOnDragStart(self)
  if not mod.configuration.IsDragAndDropEnabled() then return end

  local slot = mod.configuration.GetSlotForPosition(self.position)
  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)
  -- abort if no item could be found
  if gearSlotMetaData == nil then return end

  if not IsInventoryItemLocked(gearSlotMetaData.slotId) then
    PickupInventoryItem(gearSlotMetaData.slotId)
  end
end

--[[
  Show keybindings for all registered items
]]--
function me.ShowKeyBindings()
  for _, gearSlot in pairs(gearSlots) do
    gearSlot.keyBindingText:Show()
  end
end

--[[
  Hide keybindings for all registered items
]]--
function me.HideKeyBindings()
  for _, gearSlot in pairs(gearSlots) do
    gearSlot.keyBindingText:Hide()
  end
end

--[[
  Hide cooldowns for worn items
]]--
function me.HideCooldowns()
  for _, gearSlot in pairs(gearSlots) do
    gearSlot.cooldownOverlay:Hide()
  end
end

--[[
  Show cooldowns for worn items
]]--
function me.ShowCooldowns()
  for _, gearSlot in pairs(gearSlots) do
    gearSlot.cooldownOverlay:Show()
  end
end
