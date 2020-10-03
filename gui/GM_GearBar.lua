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

--[[
  The gearBar (GM_Gearbar) module is responsible for building and showing gearBars to the user.
  A gearBar can have n amount of slots where the user can define different gearSlot types and keybinds to activate them.

  A gearBar is always bound to a gearBarConfiguration that was created in the ui configuration of the addon.
  This configuration tells the gearBar exactly how many slots it should have and how those are configured.
  The module responsible for holding and changing this information is the gearBarManager (GM_GearBarManager).
  The gearBar module however should never change values in the gearBarManager. Its sole purpose is to read
  all of the present configurations and display them exactly as described to the user.
]]--

local mod = rggm
local me = {}

mod.gearBar = me

me.tag = "GearBar"

--[[
  ELEMENTS
]]--

--[[
  Initial setup of all configured gearBars. Used during addon startup
]]--
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

  gearBarFrame:SetWidth(
      RGGM_CONSTANTS.GEAR_BAR_SLOT_AMOUNT * gearBarSlotSize
    )
  gearBarFrame:SetHeight(gearBarSlotSize)

  gearBarFrame:SetPoint("CENTER", 0, 0)
  gearBarFrame:SetMovable(true)
  -- prevent dragging the frame outside the actual 3d-window
  gearBarFrame:SetClampedToScreen(true)

  -- TODO buggy background path
  gearBarFrame:SetBackdrop({
    bgFile = "Interface\\AddOns\\GearMenu\\assets\\ui_slot_background"
  })

  mod.gearBarStorage.AddGearBar(gearBar.id, gearBarFrame)

  --[[
    Create all configured slots for the gearBar
  ]]--
  for i = 1, #gearBar.slots do
    local gearSlot = me.BuilGearSlot(gearBarFrame, gearBar, i)
    mod.gearBarStorage.AddGearSlot(gearBar.id, gearSlot)
  end

  return gearBarFrame
end

--[[
  TODO this function cannot be called while in combatlockdown
  Create a single gearSlot. Note that a gearSlot inherits from the SecureActionButtonTemplate to enable the usage
  of clicking items.

  @param {table} gearBarFrame
    The gearBarFrame where the gearSlot gets attached to
  @param {table} gearBar
  @param {number} position
    Position on the gearBar

  @return {table}
    The created gearSlot
]]--
function me.BuilGearSlot(gearBarFrame, gearBar, position)
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

  local gearSlotMetaData = gearBar.slots[position]

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
  mod.uiHelper.UpdateSlotTextureAttributes(gearSlot)
  mod.uiHelper.CreateCooldownOverlay(
    gearSlot,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT_COOLDOWN_FRAME,
    gearBarSlotSize
  )

  me.SetupEvents(gearSlot)
  me.SetupDragFrame(gearSlot)

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
  UPDATE
]]--

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
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)

  for index, gearSlotMetaData in pairs(gearBar.slots) do
    mod.logger.LogDebug(me.tag, "Updating gearBar with id: " .. gearBar.id)

    if uiGearBar.gearSlotReferences[index] == nil then
      mod.logger.LogInfo(me.tag, "GearSlot does not yet exist. Creating a new one")
      local gearSlot = me.BuilGearSlot(uiGearBar.gearBarReference, gearBar, index)
      mod.gearBarStorage.AddGearSlot(gearBar.id, gearSlot)
    end

    local uiGearSlot = uiGearBar.gearSlotReferences[index]

    uiGearSlot:SetAttribute("type1", "item")
    uiGearSlot:SetAttribute("item", gearSlotMetaData.slotId)
    me.UpdateTexture(uiGearSlot, gearSlotMetaData)
    mod.uiHelper.UpdateSlotTextureAttributes(uiGearSlot)

    -- update slotsize to match configuration
    uiGearSlot:SetSize(gearBarSlotSize, gearBarSlotSize)
    uiGearSlot.cooldownOverlay:SetSize(gearBarSlotSize, gearBarSlotSize)
    uiGearSlot.cooldownOverlay:GetRegions()
      :SetFont(
        STANDARD_TEXT_FONT,
        mod.configuration.GetSlotSize() * RGGM_CONSTANTS.GEAR_BAR_CHANGE_COOLDOWN_TEXT_MODIFIER
      )

    me.SetKeyBindingFont(uiGearSlot.keyBindingText)

    uiGearSlot:Show() -- finally make the slot visible
  end

  -- remove leftover gearSlots that are obsolete and should no longer be displayed
  -- TODO what happens with hidden buttons that have keybinds to them?
  -- Should probably remove the keybind before deleting
  for index, gearSlotReference in pairs(uiGearBar.gearSlotReferences) do
    if index > #gearBar.slots then
      mod.logger.LogDebug(me.tag, "GearBar(" .. gearBar.id .. ") - Index: " .. index .. " should be hidden")
      gearSlotReference:Hide() -- hide leftover slot
      -- TODO is it good enough to just hide the slot
    end
  end


  -- update baseFrame size
  uiGearBar.gearBarReference:SetWidth(gearBarSlotSize * #uiGearBar.gearSlotReferences)
end

--[[
  Update gearSlots in cases such as a new gearSlots was added or one was removed

  @param {number} gearBarId
]]--
function me.UpdateGearSlots(gearBarId)
  local gearBarUi = mod.gearBar.GetGearBar(gearBarId)
  local gearBar = mod.gearBarManager.GetGearBar(gearBarId)

  for i = 1, #gearBar.slots do
    if gearBarUi.gearSlotReferences[i] ~= nil then
      mod.logger.LogDebug(me.tag, "Found already present slot")
    else
      mod.logger.LogDebug(me.tag, "Not slout found. Creating a new one")
      local gearSlot = me.BuilGearSlot(gearBarUi.gearBarReference, gearBar, i)
      mod.gearBarStorage.AddGearSlot(gearBar.id, gearSlot)
    end
  end

  me.CleanupOrphanedGearSlots(gearBar, gearBarUi)
end

--[[
  Search for orphan gearSlots that should be removed. Note it is not possible to delete
  a frame. It can only be hidden but will of course not be recreated once the user reloads the ui

  @param {table} gearBar
    The configuration of a gearBar
  @param {table} gearBarUi
    The visual representation of a gearBar
]]--
function me.CleanupOrphanedGearSlots(gearBar, gearBarUi)
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
      me.UpdateTexture(uiGearSlot, gearSlot)
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
  Update gearBar in cases such as a new gearSlot was added or one was removed. Should
  always be called after me.UpdateGearSlots otherwise the size calculation will be off.

  @param {number} gearBarId
]]--
function me.UpdateGearBarSize(gearBarId)
  local gearBarUi = mod.gearBar.GetGearBar(gearBarId)
  local slotAmount = #gearBarUi.gearSlotReferences + 1 -- TODO explain

  mod.logger.LogError(me.tag, string.format("Updating GearBar for %s slots", slotAmount))

  local gearBarSlotSize = mod.configuration.GetSlotSize()

  gearBarUi.gearBarReference:SetWidth(slotAmount * gearBarSlotSize)
end

--[[
  EVENTS
]]--

--[[
  Setup events for gearBar frame

  @param {table} frame
    The frame to attach the drag handlers to
]]--
function me.SetupDragFrame(frame)
  frame:SetScript("OnMouseDown", me.StartDragFrame)
  frame:SetScript("OnMouseUp", me.StopDragFrame)
end

--[[
  Frame callback to start moving the parent (gearBar) of the passed self (gearSlot) frame

  @param {table} self
]]--
function me.StartDragFrame(self)
  -- if mod.configuration.IsGearBarLocked() then return end TODO

  self:GetParent():StartMoving()
end

--[[
  Frame callback to stop moving the parent (gearBar) of the passed self (gearSlot) frame

  @param {table} self
]]--
function me.StopDragFrame(self)
  -- if mod.configuration.IsGearBarLocked() then return end TODO
  local gearBarFrame = self:GetParent()
  gearBarFrame:StopMovingOrSizing()

  -- local point, relativeTo, relativePoint, posX, posY = gearBarFrame:GetPoint()

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
  mod.gearBarChangeMenu.UpdateChangeMenu(self, self:GetParent().id)
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
