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

-- luacheck: globals CreateFrame MouseIsOver GetItemCooldown STANDARD_TEXT_FONT

local mod = rggm
local me = {}

mod.changeMenu = me

me.tag = "ChangeMenu"

--[[
  Local references to heavily accessed targetcastbar ui elements
]]--
local changeMenuFrame
local changeMenuSlots = {}

local lastGearSlotHovered

--[[
  Build the initial changeMenu for bagged items

  @param {table} gearBarFrame
]]--
function me.BuildChangeMenu(gearBarFrame)
  local changeSlotSize = mod.configuration.GetSlotSize()

  changeMenuFrame = CreateFrame("Frame", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CHANGE_FRAME, gearBarFrame)
  changeMenuFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_CHANGE_ROW_AMOUNT * changeSlotSize)
  changeMenuFrame:SetHeight(RGGM_CONSTANTS.GEAR_BAR_CHANGE_DEFAULT_HEIGHT)
  changeMenuFrame:SetBackdropColor(0, 0, 0, .5)
  changeMenuFrame:SetBackdropBorderColor(0, 0, 0, .8)
  changeMenuFrame:SetPoint("BOTTOMLEFT", gearBarFrame, "TOPLEFT", 5, 0)

  local row
  local col = 0

  for position = 1, RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT do
    local xPos
    local yPos

    if math.fmod(position, 2) ~= 0 then
      -- left
      row = 0

      yPos = col * changeSlotSize
      xPos = row * changeSlotSize
    else
      -- right
      row = 1

      yPos = col * changeSlotSize
      xPos = row * changeSlotSize
      col = col + 1
    end

    local changeSlot = me.CreateChangeSlot(changeMenuFrame, position, xPos, yPos)

    me.SetupEvents(changeSlot)
    changeSlot:Hide()
  end

  changeMenuFrame:Hide() -- hide menu initially
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
  local changeSlot = CreateFrame("Button", RGGM_CONSTANTS.ELEMENT_GEAR_BAR_SLOT .. position, frame)
  local changeSlotSize = mod.configuration.GetSlotSize()

  changeSlot:SetFrameLevel(frame:GetFrameLevel() + 1)
  changeSlot:SetSize(changeSlotSize, changeSlotSize)
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

  mod.uiHelper.CreateHighlightFrame(changeSlot)
  mod.uiHelper.CreateCooldownOverlay(
    changeSlot,
    RGGM_CONSTANTS.ELEMENT_GEAR_BAR_CHANGE_COOLDOWN_FRAME,
    changeSlotSize
  )

  table.insert(changeMenuSlots, changeSlot) -- store changeSlot

  return changeSlot
end

--[[
  Update the changeMenu. Note that the gearSlot can be nil in case of a manual trigger
  of UpdateChangeMenu instead of through a 'hover' event on a gearSlot. In this case the
  last used gearSlot is used.

  @param {table} gearSlot
    The gearSlot that was hovered
]]--
function me.UpdateChangeMenu(gearSlot)
  me.ResetChangeMenu()

  if gearSlot == nil then
    if lastGearSlotHovered ~= nil then
      gearSlot = lastGearSlotHovered
    else
      return
    end
  end

  local slot = mod.configuration.GetSlotForPosition(tonumber(gearSlot.position))
  local gearSlotMetaData = mod.gearManager.GetGearSlotForSlotId(slot)

  if gearSlotMetaData ~= nil then
    local items = mod.itemManager.GetItemsForInventoryType(gearSlotMetaData.type)

    for index, item in ipairs(items) do
      if index > RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT then
        mod.logger.LogInfo(me.tag, "All changeMenuSlots are in use skipping rest of items...")
        break
      end

      local changeMenuSlot = changeMenuSlots[index]
      mod.uiHelper.UpdateSlotTextureAttributes(changeMenuSlot)

      -- update metadata for slot
      changeMenuSlot.slotId = gearSlotMetaData.slotId
      changeMenuSlot.itemId = item.id
      changeMenuSlot.equipSlot = item.equipSlot

      changeMenuSlot:SetNormalTexture(item.icon)
      changeMenuSlot:Show()
    end

    me.UpdateChangeMenuSize(items)
    me.UpdateChangeMenuPosition(gearSlot)
    me.UpdateChangeMenuCooldownState()

    mod.ticker.StartTickerChangeMenu()

    lastGearSlotHovered = gearSlot

    if MouseIsOver(_G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME]) or MouseIsOver(changeMenuFrame) then
      changeMenuFrame:Show()
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
    changeMenuSlots[i].cooldownOverlay:SetCooldown(0, 0)
    changeMenuSlots[i]:Hide()
  end

  changeMenuFrame:Hide()
end

--[[
  Updates the changeMenuFrame size depending on how many changeslots are displayed at the time

  @param {table} items
]]--
function me.UpdateChangeMenuSize(items)
  local rows

  if table.getn(items) > RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT then
    rows = RGGM_CONSTANTS.GEAR_BAR_CHANGE_SLOT_AMOUNT / RGGM_CONSTANTS.GEAR_BAR_CHANGE_ROW_AMOUNT
  else
    rows = table.getn(items) / RGGM_CONSTANTS.GEAR_BAR_CHANGE_ROW_AMOUNT
  end

  -- special case for if only one row needs to be displayed
  if rows < 1 then rows = 1 end

  changeMenuFrame:SetHeight(math.ceil(rows) * mod.configuration.GetSlotSize())
  changeMenuFrame:SetWidth(RGGM_CONSTANTS.GEAR_BAR_CHANGE_ROW_AMOUNT * mod.configuration.GetSlotSize())
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
]]--
function me.UpdateChangeMenuCooldownState()
  for _, changeMenuSlot in pairs(changeMenuSlots) do
    if changeMenuSlot.itemId ~= nil then
      if mod.configuration.IsShowCooldownsEnabled() then
        local startTime, duration = GetItemCooldown(changeMenuSlot.itemId)
        changeMenuSlot.cooldownOverlay:SetCooldown(startTime, duration)
      else
        changeMenuSlot.cooldownOverlay:Hide()
      end
    end
  end
end

--[[
 Update the size of all changeMenuSlots after the gearSlot size was changed
]]--
function me.UpdateChangeMenuSlotSize()
  local changeSlotSize = mod.configuration.GetSlotSize()
  local row
  local col = 0

  for index, changeMenuSlot in pairs(changeMenuSlots) do
    local xPos
    local yPos

    if math.fmod(index, 2) ~= 0 then
      -- left
      row = 0

      yPos = col * changeSlotSize
      xPos = row * changeSlotSize
    else
      -- right
      row = 1

      yPos = col * changeSlotSize
      xPos = row * changeSlotSize
      col = col + 1
    end

    changeMenuSlot:SetPoint(
      "BOTTOMLEFT",
      changeMenuFrame,
      "BOTTOMLEFT",
      xPos,
      yPos
    )

    changeMenuSlot:SetSize(changeSlotSize, changeSlotSize)
    changeMenuSlot.cooldownOverlay:SetSize(changeSlotSize, changeSlotSize)
    changeMenuSlot.cooldownOverlay:GetRegions()
      :SetFont(
        STANDARD_TEXT_FONT,
        mod.configuration.GetSlotSize() * RGGM_CONSTANTS.GEAR_BAR_CHANGE_COOLDOWN_TEXT_MODIFIER
      )
  end
end

--[[
  Setup event for a changeSlot

  @param {table} changeSlot
]]--
function me.SetupEvents(changeSlot)
  -- register button to receive leftclick
  changeSlot:RegisterForClicks("LeftButtonUp")

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
  if button == "LeftButton" then
    mod.itemManager.EquipItemById(self.itemId, self.slotId)
    me.CloseChangeMenu()
  end
end

--[[
  GUI callback for updating the changeMenu - invoked regularly by a timer

  Close changeMenu frame after when mouse is not over either the main gearBarFrame or the
  changeMenuFrame.
]]--
function me.ChangeMenuOnUpdate()
  if not MouseIsOver(_G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME]) and not MouseIsOver(changeMenuFrame) then
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

--[[
  Hide cooldowns for bagged items
]]--
function me.HideCooldowns()
  for _, changeMenuSlot in pairs(changeMenuSlots) do
    changeMenuSlot.cooldownOverlay:Hide()
  end
end

--[[
  Show cooldowns for bagged items
]]--
function me.ShowCooldowns()
  for _, changeMenuSlot in pairs(changeMenuSlots) do
    changeMenuSlot.cooldownOverlay:Show()
  end
end
