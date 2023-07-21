--[[
  MIT License

  Copyright (c) 2023 Michael Wiesendanger

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

-- luacheck: globals CreateFrame UIParent INVSLOT_TRINKET1 INVSLOT_TRINKET2 CooldownFrame_Set CooldownFrame_Clear
-- luacheck: globals C_Container

local mod = rggm
local me = {}
mod.trinketMenu = me

me.tag = "TrinketMenu"

--[[
  Local references to heavily accessed targetcastbar ui elements
]]--
local trinketMenuFrame
local trinketMenuSlots = {}

function me.BuildTrinketMenu()
  if trinketMenuFrame ~= nil then return end -- ui already built

  trinketMenuFrame = CreateFrame(
    "Frame",
    RGGM_CONSTANTS.ELEMENT_TRINKET_MENU_FRAME_NAME,
    UIParent,
    "BackdropTemplate"
  )

  local framePosition = mod.configuration.GetUserPlacedFramePosition(trinketMenuFrame:GetName())

  if framePosition ~= nil then
    trinketMenuFrame:SetPoint(
      framePosition.point,
      framePosition.relativeTo,
      framePosition.relativePoint,
      framePosition.posX,
      framePosition.posY
    )
  else
    trinketMenuFrame:SetPoint(unpack(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_POSITION))
  end

  trinketMenuFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })

  trinketMenuFrame:SetMovable(true)
  -- prevent dragging the frame outside the actual 3d-window
  trinketMenuFrame:SetClampedToScreen(true)

  me.SetupDragFrame(trinketMenuFrame)
  me.CreateTrinketMenuSlots()
  me.UpdateTrinketMenuLockedState()
  me.UpdateTrinketMenuResize()
end

--[[
  Create ui elements for the trinketMenuSlots
]]--
function me.CreateTrinketMenuSlots()
  for position = 1, RGGM_CONSTANTS.TRINKET_MENU_DEFAULT_SLOT_AMOUNT do
    local trinketSlot = mod.themeCoordinator.CreateTrinketSlot(trinketMenuFrame, position)
    table.insert(trinketMenuSlots, trinketSlot) -- store trinketSlot
    trinketSlot:Hide()
  end
end

--[[
  UPDATE
]]--

--[[
  Update the trinketMenu Ui
]]--
function me.UpdateTrinketMenu()
  local items = mod.itemManager.GetItemsForInventoryType({RGGM_CONSTANTS.TRINKET_MENU_INV_TYPE})

  me.UpdateTrinketMenuSlots(items)
  me.UpdateTrinketMenuSlotCooldowns()
  me.UpdateTrinketMenuSize(#items)
end

--[[
  A resize of the trinketMenu can be triggered by either changing the size of the slots
  or the column amount that is used.
  Additionaly a resize should be invoked after the initial load
]]--
function me.UpdateTrinketMenuResize()
  local items = mod.itemManager.GetItemsForInventoryType({RGGM_CONSTANTS.TRINKET_MENU_INV_TYPE})

  me.UpdateTrinketMenuSize(#items)
  me.UpdateTrinketMenuSlotSize()
end

--[[
  Update the trinketMenus frame size

  @param {number} itemCount
]]--
function me.UpdateTrinketMenuSize(itemCount)
  local trinketMenuSlotSize = mod.configuration.GetTrinketMenuSlotSize()
  local trinketMenuColumnAmount = mod.configuration.GetTrinketMenuColumnAmount()
  local rows = itemCount / trinketMenuColumnAmount

  trinketMenuFrame:SetHeight(math.ceil(rows) * trinketMenuSlotSize)
  trinketMenuFrame:SetWidth(
    trinketMenuSlotSize * trinketMenuColumnAmount
    + RGGM_CONSTANTS.TRINKET_MENU_WIDTH_MARGIN
  )
end

--[[
  Update the size of a trinketSlot after the player changed the setting
]]--
function me.UpdateTrinketMenuSlotSize()
  local trinketMenuSlotSize = mod.configuration.GetTrinketMenuSlotSize()

  for index = 1, RGGM_CONSTANTS.TRINKET_MENU_DEFAULT_SLOT_AMOUNT, mod.configuration.GetTrinketMenuColumnAmount() do
    local row = math.floor(index / mod.configuration.GetTrinketMenuColumnAmount())

    --[[
      special case for single row config
    ]]--
    if mod.configuration.GetTrinketMenuColumnAmount() == 1 then
      row = row -1
    end

    for column = 1, mod.configuration.GetTrinketMenuColumnAmount() do
      if index + column - 1 > RGGM_CONSTANTS.TRINKET_MENU_DEFAULT_SLOT_AMOUNT then break end

      local trinketMenuSlot = trinketMenuSlots[index + column -1]

      trinketMenuSlot:SetSize(
        trinketMenuSlotSize,
        trinketMenuSlotSize
      )

      local yPos = row * trinketMenuSlotSize
      local xPos = (column - 1) * trinketMenuSlotSize

      trinketMenuSlot:ClearAllPoints()
      trinketMenuSlot:SetPoint(
        "BOTTOMLEFT",
        trinketMenuFrame,
        "BOTTOMLEFT",
        xPos,
        yPos
      )

      mod.themeCoordinator.UpdateSlotTextureAttributes(trinketMenuSlot, trinketMenuSlotSize)
    end
  end
end

--[[
  Update the trinketSlots Ui
  - Update the trinketSlot when an itemchange happened. E.g. the player switched to another trinket.
    Trinkets that are worn are no longer displayed in the trinketMenu list

  @param {table} items
]]--
function me.UpdateTrinketMenuSlots(items)
  local trinketMenuSlotSize = mod.configuration.GetTrinketMenuSlotSize()

  for index = 1, RGGM_CONSTANTS.TRINKET_MENU_DEFAULT_SLOT_AMOUNT do
    if items[index] ~= nil then
      me.UpdateTrinketMenuSlot(trinketMenuSlots[index], items[index], trinketMenuSlotSize)
    else
      me.ResetTrinketMenuSlot(trinketMenuSlots[index])
    end
  end
end

--[[
  Visually update a trinketSlot

  @param {table} trinketMenuSlot
  @param {table} item
  @param {number} trinketMenuSlotSize
]]--
function me.UpdateTrinketMenuSlot(trinketMenuSlot, item, trinketMenuSlotSize)
  mod.themeCoordinator.UpdateSlotTextureAttributes(trinketMenuSlot, trinketMenuSlotSize)

  trinketMenuSlot.itemId = item.id
  trinketMenuSlot.equipSlot = item.equipSlot
  trinketMenuSlot.itemTexture:SetTexture(item.icon)
  trinketMenuSlot:Show()
end

--[[
  Updates the cooldown representations of all items in the trinketMenu
]]--
function me.UpdateTrinketMenuSlotCooldowns()
  for _, trinketMenuSlot in pairs(trinketMenuSlots) do
    if trinketMenuSlot.itemId ~= nil then
      if mod.configuration.IsShowCooldownsEnabled() then
        local startTime, duration = C_Container.GetItemCooldown(trinketMenuSlot.itemId)
        CooldownFrame_Set(trinketMenuSlot.cooldownOverlay, startTime, duration, true)
      else
        CooldownFrame_Clear(trinketMenuSlot.cooldownOverlay)
      end
    else
      CooldownFrame_Clear(trinketMenuSlot.cooldownOverlay)
    end
  end
end

--[[
  Reset a slot to its empty/invisible state

  @param {table} trinketMenuSlot
]]--
function me.ResetTrinketMenuSlot(trinketMenuSlot)
  trinketMenuSlot:Hide()
  mod.themeCoordinator.TrinketMenuSlotReset(trinketMenuSlot)
end

--[[
  Update the visual representation of the trinketMenu whether the menu is locked or unlocked
]]--
function me.UpdateTrinketMenuLockedState()
  if mod.configuration.IsTrinketMenuFrameLocked() then
    trinketMenuFrame:SetBackdrop(nil)
  else
    trinketMenuFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
    })
  end
end

--[[
  EVENTS
]]--

--[[
  Setup events for trinketMenu frame

  @param {table} trinketMenu
    The trinketMenu to attach the drag handlers to
]]--
function me.SetupDragFrame(trinketMenu)
  trinketMenu:SetScript("OnMouseDown", me.StartDragFrame)
  trinketMenu:SetScript("OnMouseUp", me.StopDragFrame)
end

--[[
  Frame callback to start moving the trinketMenu frame

  @param {table} self
]]--
function me.StartDragFrame(self)
  if mod.configuration.IsTrinketMenuFrameLocked(self:GetName()) then return end

  self:StartMoving()
end

--[[
  Frame callback to stop moving the trinketMenu frame

  @param {table} self
]]--
function me.StopDragFrame(self)
  if mod.configuration.IsTrinketMenuFrameLocked(self:GetName()) then return end

  self:StopMovingOrSizing()

  local point, relativeTo, relativePoint, posX, posY = self:GetPoint()
  mod.configuration.SaveUserPlacedFramePosition(self:GetName(), point, relativeTo, relativePoint, posX, posY)
end

--[[
  Setup events for a trinketSlot

  @param {table} trinketSlot
]]--
function me.SetupEvents(trinketSlot)
  -- register button to receive leftclick
  trinketSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  trinketSlot:SetScript("OnEnter", function(self)
    me.TrinketMenuSlotOnEnter(self)
  end)

  trinketSlot:SetScript("OnLeave", function(self)
    me.TrinketMenuSlotOnLeave(self)
  end)

  trinketSlot:SetScript("OnClick", function(self, button)
    me.TrinketMenuSlotOnClick(self, button)
  end)
end

--[[
  Callback for a trinketMenuSlot OnEnter

  @param {table} self
]]--
function me.TrinketMenuSlotOnEnter(self)
  mod.tooltip.UpdateTooltipForItem(self)
  mod.themeCoordinator.TrinketMenuSlotOnEnter(self)
end

--[[
  Callback for a trinketMenuSlot OnLeave

  @param {table} self
]]--
function me.TrinketMenuSlotOnLeave(self)
  mod.tooltip.TooltipClear()
  mod.themeCoordinator.TrinketMenuSlotOnLeave(self)
end

--[[
  Callback for a trinketMenuSlot OnClick

  @param {table} self
  @param {string} button
]]--
function me.TrinketMenuSlotOnClick(self, button)
  --[[
    Leftclick - equip item into first INVSLOT_TRINKET1 slot
    Rightclick - equip item into second INVSLOT_TRINKET2 slot
  ]]--
  local item = {}
  item.itemId = self.itemId
  item.enchantId = nil -- trinkets can't be enchanted

  if button == "RightButton" then
    item.slotId = INVSLOT_TRINKET2
    mod.itemManager.EquipItemByItemAndEnchantId(item)
  else
    item.slotId = INVSLOT_TRINKET1
    mod.itemManager.EquipItemByItemAndEnchantId(item)
  end

  mod.themeCoordinator.TrinketMenuSlotOnClick(self, button)
end

--[[
  CONFIGURATION
]]--

--[[
  Enable the trinketMenu
]]--
function me.EnableTrinketMenu()
  --[[
    Build menu if not already done
  ]]--
  if trinketMenuFrame == nil then
    me.BuildTrinketMenu()
  end

  me.UpdateTrinketMenu()
  trinketMenuFrame:Show()
end

--[[
  Disable the trinketMenu
]]--
function me.DisableTrinketMenu()
  trinketMenuFrame:Hide()
end
