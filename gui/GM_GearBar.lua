--[[
  MIT License

  Copyright (c) 2020 Michael Wiesendanger

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
-- luacheck: globals InCombatLockdown STANDARD_TEXT_FONT IsItemInRange

local mod = rggm
local me = {}

mod.gearBar = me

me.tag = "GearBar"

--[[
  Storage for gearBar ui elements
]]--
local gearBarUiStorage = {}

--[[
  Retrieve a gearBar object from the storage by its id

  @param {number} gearBarId
    An id of a gearBar

  @return {table | nil}
    table - A table containing all relevant ui elements for that gearBar
    nil - If no gearBar with the passed id could be found
]]--
function me.GetGearBar(gearBarId)
  if gearBarUiStorage[gearBarId] == nil then
    mod.logger.LogError(me.tag, "Unable to find a GearBar with id: " .. gearBarId)
    return nil
  end

  return gearBarUiStorage[gearBarId]
end

--[[
  Store a gearBar object

  @param {number} gearBarId
    An id of a gearBar
  @param {table} gearBarReference
    A ui reference to a gearBar
]]--
function me.AddGearBar(gearBarId, gearBarReference)
  gearBarUiStorage[gearBarId] = {
    ["gearBarReference"] = gearBarReference,
    ["gearSlotReferences"] = {}
  }
end

--[[
  Not possible to destroy frames. In this case the frame is hidden and the reference
  nullified.

  @param {number} gearBarId
    An id of a gearBar
]]--
function me.RemoveGearBar(gearBarId)
  local gearBar = me.GetGearBar(gearBarId)
  gearBar.gearBarReference:Hide()
  gearBarUiStorage[gearBarId] = nil
end

--[[
  Store a gearSlot object to a gearBar object

  @param {number} gearBarId
    An id of a gearBar
  @param {table} gearSlotReference
    A ui reference to a gearSlot
]]--
function me.AddGearSlot(gearBarId, gearSlotReference)
  if gearBarUiStorage[gearBarId] == nil then
    mod.logger.LogError(me.tag, "Unable to find a GearBar with id: " .. gearBarId)
    return
  end

  table.insert(gearBarUiStorage[gearBarId].gearSlotReferences, gearSlotReference)
end

--[[
  Local references to heavily accessed ui elements
]]--
local gearSlots = {}

function me.BuildGearBars()
  local gearBars = mod.gearBarManager.GetGearBars()

  for _, gearBar in pairs(gearBars) do
    me.BuildGearBar(gearBar)
  end
end

--[[
  Build a gearBar based on the passed metadata

  @param {table} gearBar

  @return {table}
    The created gearBarFrame
]]--
function me.BuildGearBar(gearBar)
  local gearBarFrame = CreateFrame(
    "Frame",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_BASE_FRAME_NAME .. gearBar.id,
    UIParent
  )
  gearBarFrame.id = gearBar.id

  local gearBarSlotSize = mod.configuration.GetSlotSize()

  -- TODO magic value
  gearBarFrame:SetWidth(
    gearBarSlotSize + RGGM_CONSTANTS.GEAR_BAR_WIDTH_MARGIN
  )
  gearBarFrame:SetHeight(gearBarSlotSize + RGGM_CONSTANTS.GEAR_BAR_HEIGHT_MARGIN)

  gearBarFrame:SetPoint("CENTER", 0, 0)
  gearBarFrame:SetMovable(true)
  -- prevent dragging the frame outside the actual 3d-window
  gearBarFrame:SetClampedToScreen(true)

  gearBarFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })

  mod.logger.LogError(me.tag, "Building gearBar")
  me.SetupDragFrame(gearBarFrame)
  mod.gearBar.AddGearBar(gearBar.id, gearBarFrame)

  --[[
    Create all configured slots for the gearBar
  ]]--
  for i = 1, #gearBar.slots do
    me.BuilGearSlot(gearBarFrame, i)
  end

  return gearBarFrame
end

--[[
  TODO describe that this is a ui function only
  TODO this function cannot be called while in combatlockdown
  Create a single gearSlot. Note that a gearSlot inherits from the SecureActionButtonTemplate to enable the usage
  of clicking items.

  @param {table} gearBarFrame
    The gearBarFrame where the gearSlot gets attached to
  @param {number} position
    Position on the gearBar

  @return {table}
    The created gearSlot
]]--
function me.BuilGearSlot(gearBarFrame, position)
  local gearSlot = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT .. position,
    gearBarFrame,
    "SecureActionButtonTemplate"
  )

  local gearBarSlotSize = mod.configuration.GetSlotSize()

  gearSlot:SetFrameLevel(gearBarFrame:GetFrameLevel() + 1)
  gearSlot:SetSize(gearBarSlotSize, gearBarSlotSize)
  gearSlot:SetPoint(
    "LEFT",
    gearBarFrame,
    "LEFT",
    RGGM_CONSTANTS.GEAR_BAR_SLOT_X + (position - 1) * gearBarSlotSize,
    RGGM_CONSTANTS.GEAR_BAR_SLOT_Y
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

  local gearBar = mod.gearBarManager.GetGearBar(gearBarFrame.id)
  local gearSlotMetaData = gearBar.slots[position]

  if gearSlotMetaData ~= nil then
    gearSlot:SetAttribute("type1", "item")
    gearSlot:SetAttribute("item", gearSlotMetaData.slotId)
  end

  gearSlot:SetBackdrop(backdrop)
  gearSlot:SetBackdropColor(0.15, 0.15, 0.15, 1)
  gearSlot:SetBackdropBorderColor(0, 0, 0, 1)

  gearSlot.combatQueueSlot = mod.gearBar.CreateCombatQueueSlot(gearSlot)
  gearSlot.keyBindingText = mod.gearBar.CreateKeyBindingText(gearSlot, position)
  gearSlot.position = position

  mod.uiHelper.CreateHighlightFrame(gearSlot)
  mod.uiHelper.UpdateSlotTextureAttributes(gearSlot)
  mod.uiHelper.CreateCooldownOverlay(
    gearSlot,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_COOLDOWN_FRAME,
    gearBarSlotSize
  )

  me.SetupEvents(gearSlot)

  mod.gearBar.AddGearSlot(gearBarFrame.id, gearSlot)

  return gearSlot
end

--[[
  @param {table} gearSlot

  @return {table}
    The created combatQueueSlot
]]--
function me.CreateCombatQueueSlot(gearSlot)
  local combatQueueSlot = CreateFrame("Frame", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_COMBAT_QUEUE_SLOT, gearSlot)
  local combatQeueuSlotSize = mod.configuration.GetSlotSize()
    * RGGM_CONSTANTS.GEAR_BAR_COMBAT_QUEUE_SLOT_SIZE_MODIFIER

  combatQueueSlot:SetSize(
    combatQeueuSlotSize,
    combatQeueuSlotSize
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
  keybindingFontString:SetTextColor(1, 1, 1, 1)
  keybindingFontString:SetPoint("TOP", 0, 1)
  keybindingFontString:SetSize(gearSlot:GetWidth(), 20)
  me.SetKeyBindingFont(keybindingFontString)
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
  @param {string} keybindingFontString
]]--
function me.SetKeyBindingFont(keybindingFontString)
  keybindingFontString:SetFont(
    STANDARD_TEXT_FONT,
    mod.configuration.GetSlotSize() * RGGM_CONSTANTS.GEAR_BAR_CHANGE_KEYBIND_TEXT_MODIFIER,
    "THICKOUTLINE"
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

  gearSlot:SetScript("OnEnter", me.GearSlotOnEnter)
  gearSlot:SetScript("OnLeave", me.GearSlotOnLeave)

  gearSlot:SetScript("OnReceiveDrag", function(self)
    -- me.GearSlotOnReceiveDrag(self) -- TODO drag and drop support
  end)

  gearSlot:SetScript("OnDragStart", function(self)
    -- me.GearSlotOnDragStart(self) -- TODO drag and drop support
  end)
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
    mod.combatQueue.RemoveFromQueue(self:GetAttribute("item"))
  else
    return -- ignore other buttons
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
  mod.changeMenu.DuplicateUpdateChangeMenu(self, self:GetParent().id)
  mod.tooltip.BuildTooltipForWornItem(self:GetAttribute("item"))
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
  Update all GearBars
]]--
function me.UpdateGearBars()
  local gearBars = mod.gearBarManager.GetGearBars()

  for _, gearBar in pairs(gearBars) do
    me.UpdateGearBar(gearBar)
  end
end

--[[
  Update a single gearBar

  @param {table} gearBar
]]--
function me.UpdateGearBar(gearBar)
  if InCombatLockdown() then
    -- temporary fix for in combat configuration of slots TODO
    mod.logger.LogError(me.tag, "Unable to update slots in combat. Please /reload after your are out of combat")
    return
  end

  local gearBarSlotSize = mod.configuration.GetSlotSize()
  local uiGearBar = mod.gearBar.GetGearBar(gearBar.id)

  for index, gearSlotMetaData in pairs(gearBar.slots) do
    mod.logger.LogDebug(me.tag, "Updating gearBar with id: " .. gearBar.id)

    -- TODO GetGearBar can return nil
    local gearBarReference = me.GetGearBar(gearBar.id).gearBarReference
    --[[
      TODO need to check if this is a good way for implenting the creation of a new slot
      We essentialy tell the gearBar to update after we added a new slot
      The slot does not exist the update process recognizes this and creates the slot

      OR

      Would it be better to make sure the slot is already created when we add the button to the gearBarmanager
    ]]--
    if uiGearBar.gearSlotReferences[index] == nil then
      mod.logger.LogInfo(me.tag, "GearSlot does not yet exist. Creating a new one")
      me.BuilGearSlot(gearBarReference, index)
    end

    local uiGearSlot = uiGearBar.gearSlotReferences[index]

    uiGearSlot:SetAttribute("type1", "item")
    uiGearSlot:SetAttribute("item", gearSlotMetaData.slotId)
    mod.gearBar.UpdateTexture(uiGearSlot, gearSlotMetaData)
    mod.uiHelper.UpdateSlotTextureAttributes(uiGearSlot)

    -- update slotsize to match configuration
    uiGearSlot:SetSize(gearBarSlotSize, gearBarSlotSize)
    uiGearSlot.cooldownOverlay:SetSize(gearBarSlotSize, gearBarSlotSize)
    uiGearSlot.cooldownOverlay:GetRegions()
      :SetFont(
        STANDARD_TEXT_FONT,
        mod.configuration.GetSlotSize() * RGGM_CONSTANTS.GEAR_BAR_CHANGE_COOLDOWN_TEXT_MODIFIER
      )

    mod.gearBar.SetKeyBindingFont(uiGearSlot.keyBindingText)

    uiGearSlot:Show() -- finally make the slot visible
  end

  -- remove leftover gearSlots that are obsolete and should no longer be displayed
  -- TODO what happens with hidden buttons that have keybinds to them?
  for index, gearSlotReference in pairs(uiGearBar.gearSlotReferences) do
    if index > #gearBar.slots then
      mod.logger.LogDebug(me.tag, "GearBar(" .. gearBar.id .. ") - Index: " .. index .. " should be hidden")
      gearSlotReference:Hide() -- hide leftover slot
      -- TODO is it good enough to just hide the slot
    end
  end
end

--[[
  Update gearSlots in cases such as a new gearSlots was added or one was removed

  @param {number} gearBarId
]]--
function me.UpdateGearSlots(gearBarId)
  local gearBarUi = mod.gearBar.GetGearBar(gearBarId)
  local gearBar = mod.gearBarManager.GetGearBar(gearBarId)

  for i = 1, #gearBar.slots do
    local gearSlot = gearBarUi.gearSlotReferences[i]

    if gearSlot ~= nil then
      mod.logger.LogWarn(me.tag, "Found a slot")
    else
      mod.logger.LogWarn(me.tag, "Slot not found. Should be created")
      me.BuilGearSlot(gearBarUi.gearBarReference, i)
    end
  end


  --[[
    TODO maybe there is a better way

    Search for orphan gearSlots that should be removed. Note it is not possible to delete
    a frame. It can only be hidden but will of course not be recreated once the user reloads the ui
  ]]--

  for i = 1, #gearBarUi.gearSlotReferences do
    if gearBar.slots[i] == nil then
      -- means the element is no longer known and should be "removed"
      gearBarUi.gearSlotReferences[i]:Hide()
      gearBarUi.gearSlotReferences[i] = nil
    end
  end
end

--[[
  Update the gearBar after one of PLAYER_EQUIPMENT_CHANGED, BAG_UPDATE events

  Textures are changed separately from UpdateGearBar because it can be done at any point
  even if in InCombatLockdown while gearSlots cannot be reconfigured or even deleted while
  in combatlockdown
]]--
function me.UpdateGearBarTextures()
  local gearBars = mod.gearBarManager.GetGearBars()

  for _, gearBar in pairs(gearBars) do
    local uiGearBar = mod.gearBar.GetGearBar(gearBar.id)

    for index, gearSlot in pairs(gearBar.slots) do
      local uiGearSlot = uiGearBar.gearSlotReferences[index]
      mod.gearBar.UpdateTexture(uiGearSlot, gearSlot)
    end
  end
end

--[[
  Update gearBar in cases such as a new gearSlot was adder or one was removed. Should
  always be called after me.UpdateGearSlots otherwise the size calculation will be off.

  @param {number} gearBarId
]]--
function me.UpdateGearBarSize(gearBarId)
  local gearBarUi = mod.gearBar.GetGearBar(gearBarId)
  local slotAmount = #gearBarUi.gearSlotReferences + 1 -- TODO explain

  mod.logger.LogError(me.tag, string.format("Updating GearBar for %s slots", slotAmount))

  local gearBarSlotSize = mod.configuration.GetSlotSize()

  gearBarUi.gearBarReference:SetWidth(
    slotAmount * gearBarSlotSize + RGGM_CONSTANTS.GEAR_BAR_WIDTH_MARGIN
  )
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
  -- if mod.configuration.IsGearBarLocked() then return end TODO

  self:StartMoving()
end

--[[
  Frame callback to stop moving the passed (self) frame

  @param {table} self
]]--
function me.StopDragFrame(self)
  -- if mod.configuration.IsGearBarLocked() then return end TODO

  self:StopMovingOrSizing()

  -- local point, relativeTo, relativePoint, posX, posY = self:GetPoint()

  --[[
  mod.configuration.SaveUserPlacedFramePosition(
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME,
    point,
    relativeTo,
    relativePoint,
    posX,
    posY
  )
  ]]--
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
      RGGM_CONSTANTS.GEAR_BAR_SLOT_X + (position - 1) * mod.configuration.GetSlotSize(),
      RGGM_CONSTANTS.GEAR_BAR_SLOT_Y
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

    if bagNumber ~= nil and bagPos ~= nil then
      icon:SetTexture(GetContainerItemInfo(bagNumber, bagPos))
      icon:Show()
    end
  else
    icon:Hide()
  end
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
  else
    return -- ignore other buttons
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
