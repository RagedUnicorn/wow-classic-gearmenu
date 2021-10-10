--[[
  MIT License

  Copyright (c) 2021 Michael Wiesendanger

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

-- luacheck: globals CreateFrame MouseIsOver GetItemCooldown STANDARD_TEXT_FONT CooldownFrame_Clear
-- luacheck: globals CooldownFrame_Set UIParent

local mod = rggm
local me = {}

mod.gearBarChangeMenu = me

me.tag = "GearBarChangeMenu"

--[[
  Local references to heavily accessed targetcastbar ui elements
]]--
local changeMenuFrame
local changeMenuSlots = {}

--[[
  ELEMENTS
]]--

--[[
  Build the initial changeMenu for bagged items
]]--
function me.BuildChangeMenu()
  changeMenuFrame = CreateFrame("Frame", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CHANGE_FRAME, nil, "BackdropTemplate")
  changeMenuFrame:SetWidth(
    RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT * RGGM_CONSTANTS.GEAR_BAR_CHANGE_DEFAULT_SLOT_SIZE)
  changeMenuFrame:SetHeight(RGGM_CONSTANTS.GEAR_BAR_CHANGE_DEFAULT_HEIGHT)
  changeMenuFrame:SetPoint("CENTER")
  changeMenuFrame:SetBackdropColor(0, 0, 0, .5)
  changeMenuFrame:SetBackdropBorderColor(0, 0, 0, .8)

  me.CreateChangeSlots()

  changeMenuFrame:Hide() -- hide menu initially
end

--[[
  Create all changeslots initial representation
]]--
function me.CreateChangeSlots()
  for index = 1, RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT, RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT do
    local row = math.floor(index / RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT)

    for column = 1, RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT do
      if index + column - 1 > RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT then break end

      local yPos = row * RGGM_CONSTANTS.GEAR_BAR_CHANGE_DEFAULT_SLOT_SIZE
      local xPos = (column - 1) * RGGM_CONSTANTS.GEAR_BAR_CHANGE_DEFAULT_SLOT_SIZE

      local changeSlot = me.CreateChangeSlot(changeMenuFrame, index + column - 1, xPos, yPos)

      me.SetupEvents(changeSlot)
      changeSlot:Hide()
    end
  end
end

--[[
  Create a single changeSlot

  @param {table} frame
  @param {number} position
  @param {number} xPos
  @param {number} yPos

  @return {table}
    The created changeSlot
]]--
function me.CreateChangeSlot(frame, position, xPos, yPos)
  local changeSlot = CreateFrame(
    "Button",
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CHANGE_SLOT .. position,
    frame,
    "BackdropTemplate"
  )
  changeSlot:SetFrameLevel(frame:GetFrameLevel() + 1)
  changeSlot:SetSize(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE, RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE)
  changeSlot:ClearAllPoints()
  changeSlot:SetPoint(
    "BOTTOMLEFT",
    frame,
    "BOTTOMLEFT",
    xPos,
    yPos
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

  changeSlot:SetBackdrop(backdrop)
  changeSlot:SetBackdropColor(0.15, 0.15, 0.15, 1)
  changeSlot:SetBackdropBorderColor(0, 0, 0, 1)

  changeSlot.highlightFrame = mod.uiHelper.CreateHighlightFrame(changeSlot)
  changeSlot.cooldownOverlay = mod.uiHelper.CreateCooldownOverlay(
    changeSlot,
    RGGM_CONSTANTS.ELEMENT_SLOT_COOLDOWN_FRAME,
    RGGM_CONSTANTS.GEAR_BAR_CHANGE_DEFAULT_SLOT_SIZE
  )

  table.insert(changeMenuSlots, changeSlot) -- store changeSlot

  return changeSlot
end

--[[
  UPDATE
]]--

--[[
  Update the changeMenu. Note that the gearSlotPosition and gearBarId can be nil in case of a manual trigger
  of UpdateChangeMenu instead of through a 'hover' event on a gearSlot. In this case the
  last used gearbar and gearSlot are used.

  @param {table} gearSlotPosition
    The gearSlot position that was hovered
  @param {number} gearBarId
    The id of the hovered gearBar
]]--
function me.UpdateChangeMenu(gearSlotPosition, gearBarId)
  me.ResetChangeMenu()
  me.UpdateChangeMenuProperties(gearBarId, gearSlotPosition)

  local gearBar = mod.gearBarManager.GetGearBar(changeMenuFrame.gearBarId)
  local gearSlotMetaData = gearBar.slots[changeMenuFrame.gearSlotPosition]
  local uiGearBar = mod.gearBarStorage.GetGearBar(changeMenuFrame.gearBarId)

  if gearSlotMetaData ~= nil then
    local items = mod.itemManager.GetItemsForInventoryType(gearSlotMetaData.type)

    me.UpdateChangeSlots(gearBar.changeSlotSize, gearSlotMetaData, items)
    me.UpdateChangeMenuSize(gearBar.changeSlotSize, gearSlotMetaData, #items)
    me.UpdateChangeMenuPosition(
      uiGearBar.gearSlotReferences[changeMenuFrame.gearSlotPosition]
    )

    mod.ticker.StartTickerChangeMenu()

    if uiGearBar and MouseIsOver(uiGearBar.gearBarReference) or MouseIsOver(changeMenuFrame) then
      changeMenuFrame:Show()
    end
  end
end

--[[
  @param {number} changeSlotSize
  @param {table} gearSlotMetaData
  @param {table} item
]]--
function me.UpdateChangeSlots(changeSlotSize, gearSlotMetaData, items)
  local emptySlotPosition = {row = 0, xPos = 0, yPos = 0}

  for index = 1, #items, RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT do
    if index > RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT_ITEMS then
      mod.logger.LogInfo(me.tag, "All changeMenuSlots are in use skipping rest of items...")
      break
    end

    local row = math.floor(index/RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT)
    local lastColumn

    for column = 1, RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT do
      local actualIndex = index + column - 1
      local yPos = row * changeSlotSize
      local xPos = (column - 1) * changeSlotSize

      if actualIndex > #items or actualIndex > RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT_ITEMS then
        break
      end

      me.UpdateChangeSlot(changeMenuSlots[actualIndex], gearSlotMetaData, items[actualIndex], changeSlotSize)
      me.UpdateChangeSlotSize(changeSlotSize, changeMenuFrame, changeMenuSlots[actualIndex], xPos, yPos)

      mod.logger.LogDebug(me.tag, "Updating ChangeSlot Row{" .. row .. "} xPos{" .. xPos .. "} yPos{" .. yPos .. "}")
      lastColumn = column
    end

    if lastColumn == RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT then
      -- last spot on column was used put empty slot on new row
      emptySlotPosition.row = row + 1
      emptySlotPosition.xPos = 0
      emptySlotPosition.yPos = (row + 1) * changeSlotSize
    else
      -- place on same row as last one
      emptySlotPosition.row = row
      emptySlotPosition.xPos = lastColumn * changeSlotSize
      emptySlotPosition.yPos = row * changeSlotSize
    end
  end

  me.UpdateEmptyChangeSlot(changeSlotSize, changeMenuFrame, #items, gearSlotMetaData, emptySlotPosition)
  me.UpdateChangeMenuGearSlotCooldown()
end

--[[
  Visually update a changeslot

  @param {table} changeSlot
  @param {table} gearSlotMetaData
  @param {table} item
  @param {number} changeSlotSize
]]--
function me.UpdateChangeSlot(changeSlot, gearSlotMetaData, item, changeSlotSize)
  mod.uiHelper.UpdateSlotTextureAttributes(changeSlot, changeSlotSize)
  -- update metadata for slot
  changeSlot.slotId = gearSlotMetaData.slotId
  changeSlot.itemId = item.id
  changeSlot.equipSlot = item.equipSlot

  changeSlot:SetNormalTexture(item.icon)
  changeSlot:Show()
end

--[[
  Update the changeSlotSize to the configured one

  @param {number} changeSlotSize
  @param {table} changeMenu
  @param {table} changeSlot
  @param {number} xPos
  @param {number} yPos
]]--
function me.UpdateChangeSlotSize(changeSlotSize, changeMenu, changeSlot, xPos, yPos)
  -- update slotsize to match configuration
  changeSlot:SetSize(changeSlotSize, changeSlotSize)
  changeSlot:ClearAllPoints()
  changeSlot:SetPoint(
    "BOTTOMLEFT",
    changeMenu,
    "BOTTOMLEFT",
    xPos,
    yPos
  )

  me.UpdateCooldownOverlaySize(changeSlot, changeSlotSize)
end

--[[
  @param {table} changeSlot
  @param {number} slotSize
]]--
function me.UpdateCooldownOverlaySize(changeSlot, slotSize)
  changeSlot.cooldownOverlay:SetSize(slotSize, slotSize)
  changeSlot.cooldownOverlay:GetRegions()
    :SetFont(
      STANDARD_TEXT_FONT,
      slotSize * RGGM_CONSTANTS.GEAR_BAR_COOLDOWN_TEXT_MODIFIER
    )
end

--[[
  Visually update an empty changeslot

  @param {number} changeSlotSize
  @param {table} changeMenu
  @param {number} itemCount
  @param {table} gearSlotMetaData
  @param {table} emptySlotPosition
]]--
function me.UpdateEmptyChangeSlot(changeSlotSize, changeMenu, itemCount, gearSlotMetaData, emptySlotPosition)
  if not mod.configuration.IsUnequipSlotEnabled()
    or not mod.itemManager.HasItemEquipedInSlot(gearSlotMetaData.slotId) then return end

  local emptyChangeMenuSlot

  if itemCount > RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT_ITEMS then
    itemCount = #changeMenuSlots -- last slot is reserved for the empty slot
  else
    itemCount = itemCount + 1 -- +1 for the empty "item"
  end

  emptyChangeMenuSlot = changeMenuSlots[itemCount]

  mod.logger.LogDebug(me.tag,
    "Updating EmptyChangeSlot Row{" .. emptySlotPosition.row ..
      "} xPos{" .. emptySlotPosition.xPos ..
      "} yPos{" .. emptySlotPosition.yPos .. "}"
  )

  me.UpdateChangeSlotSize(
    changeSlotSize, changeMenu, emptyChangeMenuSlot, emptySlotPosition.xPos, emptySlotPosition.yPos)
  mod.uiHelper.UpdateSlotTextureAttributes(emptyChangeMenuSlot, changeSlotSize)

  emptyChangeMenuSlot.slotId = gearSlotMetaData.slotId
  emptyChangeMenuSlot.itemId = nil
  emptyChangeMenuSlot.equipSlot = nil

  emptyChangeMenuSlot:SetNormalTexture(gearSlotMetaData.textureId)
  emptyChangeMenuSlot:Show()
end

--[[
  Updates the changeMenuFrame size depending on how many changeslots are displayed at the time

  @param {number} changeSlotSize
  @param {table} gearSlotMetaData
  @param {number} itemCount
]]--
function me.UpdateChangeMenuSize(changeSlotSize, gearSlotMetaData, itemCount)
  local rows
  local totalItems

  if itemCount > RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT then
    rows = RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT / RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT
  else
    --[[
      If unequipSlot is enabled we increase the itemCount by 1
      If unequipSlot is enabled but the player is not wearing anything in that slot we do not
      display the unequipSlot and thus it should not be counted towards the totalItems
    ]]--
    if mod.configuration.IsUnequipSlotEnabled() and mod.itemManager.HasItemEquipedInSlot(gearSlotMetaData.slotId) then
      totalItems = itemCount + 1
    else
      totalItems = itemCount
    end

    rows = totalItems / RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT
  end

  -- special case for if only one row needs to be displayed
  if rows < 1 then rows = 1 end

  changeMenuFrame:SetHeight(math.ceil(rows) * changeSlotSize)
  changeMenuFrame:SetWidth((totalItems or itemCount) * changeSlotSize)
end

--[[
  Moves the changeMenuFrame to the currently hovered gearSlot

  @param {table} gearSlot
    The gearSlot that was hovered
]]--
function me.UpdateChangeMenuPosition(gearSlot)
  changeMenuFrame:ClearAllPoints()
  changeMenuFrame:SetPoint("BOTTOMLEFT", gearSlot, "TOPLEFT", 0, 0)
end

--[[
  Updates the cooldown representations of all items in the changeMenu

  @param {number} gearBarId
    The id of the hovered gearBar
]]--
function me.UpdateChangeMenuGearSlotCooldown()
  for _, changeMenuSlot in pairs(changeMenuSlots) do
    if changeMenuSlot.itemId ~= nil then
      if changeMenuFrame.showCooldowns then
        local startTime, duration = GetItemCooldown(changeMenuSlot.itemId)
        CooldownFrame_Set(changeMenuSlot.cooldownOverlay, startTime, duration, true)
      else
        CooldownFrame_Clear(changeMenuSlot.cooldownOverlay)
      end
    else
      CooldownFrame_Clear(changeMenuSlot.cooldownOverlay)
    end
  end
end

--[[
  Reset all changeMenuSlots into their initial state
]]--
function me.ResetChangeMenu()
  for i = 1, table.getn(changeMenuSlots) do
    changeMenuSlots[i]:SetNormalTexture(nil)
    changeMenuSlots[i].highlightFrame:Hide()
    changeMenuSlots[i]:Hide()
  end

  changeMenuFrame:Hide()
end

--[[
  Update the properties of the changeMenu

  @param {number} gearBarId
    The id of the hovered gearBar
  @param {table} gearSlotPosition
    The gearSlot position that was hovered
]]--
function me.UpdateChangeMenuProperties(gearBarId, gearSlotPosition)
  if gearSlotPosition == nil or gearBarId == nil then
    if changeMenuFrame.gearBarId ~= nil then
      gearBarId = changeMenuFrame.gearBarId
    else
      return
    end

    if changeMenuFrame.gearSlotPosition ~= nil then
      gearSlotPosition = changeMenuFrame.gearSlotPosition
    else
      return
    end
  end

  -- update changeMenuFrame's Id to the currently hovered gearBarId
  changeMenuFrame.gearBarId = gearBarId
  -- update changeMenuFrame's gearSlot position to the currently hovered gearSlot
  changeMenuFrame.gearSlotPosition = gearSlotPosition

  -- cache whether cooldowns should be shown in the changemenu or not
  if mod.gearBarManager.IsShowCooldownsEnabled(gearBarId) then
    changeMenuFrame.showCooldowns = true
  else
    changeMenuFrame.showCooldowns = false
  end
end

--[[
  EVENTS
]]--

--[[
  Setup event for a changeSlot

  @param {table} changeSlot
]]--
function me.SetupEvents(changeSlot)
  -- register button to receive leftclick
  changeSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  changeSlot:SetScript("OnEnter", function(self)
    me.ChangeSlotOnEnter(self)
  end)

  changeSlot:SetScript("OnLeave", function(self)
    me.ChangeSlotOnLeave(self)
  end)

  changeSlot:SetScript("OnClick", function(self, button)
    me.ChangeSlotOnClick(self, button)
  end)
end

--[[
  Callback for a changeSlot OnEnter

  @param {table} self
]]--
function me.ChangeSlotOnEnter(self)
  self.highlightFrame:SetBackdropBorderColor(0.27, 0.4, 1, 1)
  self.highlightFrame:Show()

  mod.tooltip.BuildTooltipForBaggedItem(self.slotId, self.itemId)
end

--[[
  Callback for a changeSlot OnLeave

  @param {table} self
]]--
function me.ChangeSlotOnLeave(self)
  self.highlightFrame:Hide()
  mod.tooltip.TooltipClear()
end

--[[
  Callback for a changeSlot OnClick

  @param {table} self
  @param {string} button
]]--
function me.ChangeSlotOnClick(self, button)
  --[[
    If right button was used to equip we need to check whether the slot is a match for combined equipping
  ]]--
  if button == "RightButton" then
    if mod.gearManager.IsEnabledCombinedEquipSlot(self.equipSlot) then
      self.slotId = mod.gearManager.GetMatchedCombinedEquipSlot(self.equipSlot, self.slotId)
    end
  end

  --[[
    Check for empty slot
  ]]--
  if self.itemId == nil and self.equipSlot == nil and self.slotId ~= nil then
    mod.itemManager.UnequipItemToBag(self)
  else
    mod.itemManager.EquipItemById(self.itemId, self.slotId, self.equipSlot)
  end

  me.CloseChangeMenu()
end

--[[
  GUI callback for updating the changeMenu - invoked regularly by a timer

  Close changeMenu frame after when mouse is not over either the main gearBarFrame or the
  changeMenuFrame.
]]--
function me.ChangeMenuOnUpdate()
  local gearBar = mod.gearBarStorage.GetGearBar(changeMenuFrame.gearBarId)

  if not MouseIsOver(gearBar.gearBarReference) and not MouseIsOver(changeMenuFrame) then
    me.CloseChangeMenu()
  end
end

--[[
  Close the changeMenu
]]--
function me.CloseChangeMenu()
  mod.ticker.StopTickerChangeMenu()
  changeMenuFrame:Hide()
end
