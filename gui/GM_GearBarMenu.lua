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

-- luacheck: globals CreateFrame UIParent InCombatLockdown STANDARD_TEXT_FONT C_Timer

local mod = rggm
local me = {}

mod.gearBarMenu = me

me.tag = "GearBarMenu"

-- track whether the menu was already built
local builtMenu = false


--[[
  @param {table} frame
]]--
function me.BuildUi(frame)
  if builtMenu then return end

  me.CreateNewGearBarButton(frame)
end

--[[
  Create a button to create new gearBars

  @param {table} gearBarFrame

  @return {table}
    The created button
]]--
function me.CreateNewGearBarButton(gearBarFrame)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_MENU_BUTTON_ADD_GEAR_BAR,
    gearBarFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_DEFAULT_HEIGHT)
  button:SetText(rggm.L["gear_bar_configuration_add_gearbar"])
  button:SetPoint("TOPLEFT", 10, 10)
  button:SetScript('OnClick', me.CreateNewGearBar)

  local buttonFontString = button:GetFontString()

  button:SetWidth(
    buttonFontString:GetStringWidth() + RGGM_CONSTANTS.BUTTON_DEFAULT_PADDING
  )

  return button
end

--[[
  Create a button to a gearSlots to a gearBar

  @param {table} gearBarFrame

  @return {table}
    The created button
]]--
function me.CreateAddGearSlotButton(gearBarFrame)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_MENU_BUTTON_ADD_SLOT,
    gearBarFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_ADD_GEAR_SLOT_HEIGHT)
  button:SetWidth(RGGM_CONSTANTS.BUTTON_ADD_GEAR_SLOT_WIDTH)
  button:SetText(rggm.L["gear_bar_configuration_add_gearslot"])
  button:SetPoint("RIGHT", -25, 0)
  button:SetScript('OnClick', function()
    mod.gearBarManager.AddNewGearSlot(gearBarFrame.id)
    me.UpdateGearBar(gearBarFrame.id)
  end)

  return button
end

--[[
  Create a button to remove gearSlots from a gearBar

  @param {table} gearBarFrame

  @return {table}
    The created button
]]--
function me.CreateRemoveGearSlotButton(gearBarFrame)
  local button = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_MENU_BUTTON_REMOVE_SLOT,
    gearBarFrame,
    "UIPanelButtonTemplate"
  )

  button:SetHeight(RGGM_CONSTANTS.BUTTON_REMOVE_GEAR_SLOT_HEIGHT)
  button:SetWidth(RGGM_CONSTANTS.BUTTON_REMOVE_GEAR_SLOT_WIDTH)
  button:SetText(rggm.L["gear_bar_configuration_remove_gearslot"])
  button:SetPoint("RIGHT", -2, 0)
  button:SetScript('OnClick', function()
    mod.gearBarManager.RemoveGearSlot(gearBarFrame.id)
    me.UpdateGearBar(gearBarFrame.id)
  end)

  return button
end

--[[
  Creating a new gearBar includes storing this info in the mod.configuration module
]]--
function me.CreateNewGearBar()
  local gearBar = mod.gearBarManager.GetNewGearBar()
  gearBar.displayName = "TODO some displayName"
  gearBar.position = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_POSITION
  -- make new gearBar known to the configuration module
  mod.gearBarManager.AddNewGearBar(gearBar)

  -- create an initial GearSlot (every GearBar needs to have at least one GearSlot)
  mod.gearBarManager.AddNewGearSlot(gearBar.id)

  me.BuildGearBar(gearBar)
end

--[[
  Build a gearBar based on the passed metadaa

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
    2 * gearBarSlotSize + RGGM_CONSTANTS.GEAR_BAR_WIDTH_MARGIN
  )
  gearBarFrame:SetHeight(gearBarSlotSize + RGGM_CONSTANTS.GEAR_BAR_HEIGHT_MARGIN)

  gearBarFrame:SetPoint("CENTER", 0, 0)
  gearBarFrame:SetMovable(true)
  -- prevent dragging the frame outside the actual 3d-window
  gearBarFrame:SetClampedToScreen(true)

  gearBarFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })

  me.SetupDragFrame(gearBarFrame)
  mod.gearBar.AddGearBar(gearBar.id, gearBarFrame)

  --[[
    Create all configured slots for the gearBar
  ]]--
  for i = 1, #gearBar.slots do
    me.BuilGearSlot(gearBarFrame, i)
  end

  me.BuildConfigurationButtons(gearBarFrame)

  return gearBarFrame
end

--[[
  Build configuration buttons for adding and removing gearSlots

  @param {table} gearBarFrame
]]--
function me.BuildConfigurationButtons(gearBarFrame)
  -- TODO should only be shown in edit-mode
  me.CreateAddGearSlotButton(gearBarFrame)
  me.CreateRemoveGearSlotButton(gearBarFrame)
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
  Update gearBar ui such as its size, slots that should be displayed.

  @param {number} gearBarId
]]--
function me.UpdateGearBar(gearBarId)
  me.UpdateGearSlots(gearBarId)
  me.UpdateGearBarSize(gearBarId)

  -- TODO temporary placement
  me.TempUpdateGearBars()
end

--[[
  Update all GearBars
]]--
function me.TempUpdateGearBars()
  local gearBars = mod.gearBarManager.GetGearBars()

  for _, gearBar in pairs(gearBars) do
    me.TempUpdateGearBar(gearBar)
  end
end

--[[
  Update a single gearBar

  @param {table} gearBar
]]--
function me.TempUpdateGearBar(gearBar)
  if InCombatLockdown() then
    -- temporary fix for in combat configuration of slots
    mod.logger.LogError(me.tag, "Unable to update slots in combat. Please /reload after your are out of combat")
    return
  end

  local gearBarSlotSize = mod.configuration.GetSlotSize()

  for index, gearSlotMetaData in pairs(gearBar.slots) do
    mod.logger.LogError(me.tag, "Gearslot index: " .. index)

    local uiGearBar = mod.gearBar.GetGearBar(gearBar.id)
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
