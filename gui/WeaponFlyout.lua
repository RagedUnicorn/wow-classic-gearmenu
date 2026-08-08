--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

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

-- luacheck: globals CreateFrame InCombatLockdown GetInventoryItemID C_Item MouseIsOver
-- luacheck: globals SecureHandlerWrapScript INVSLOT_MAINHAND INVSLOT_OFFHAND INVSLOT_RANGED

--[[
  PROTOTYPE - immediate weapon swapping during combat.

  The regular changeMenu equips through insecure addon code (see code/ItemManager.lua).
  Those functions are protected in combat, which is why every swap started while the player
  is in combat ends up parked in the combatQueue. The game itself however does allow the
  weapon slots to be changed mid fight - the restriction is on the API, not on the rules.

  The one legal in-combat path is a secure button whose action was prepared before combat
  and that the player physically clicks. This module implements exactly that for the slots
  the game permits (main hand, off hand and, where it exists, ranged):

    * every gearSlot owns a flyout frame holding a pool of SecureActionButtons
    * out of combat the flyout is (re)built - each button gets type = "macro" and a
      macrotext of "/equipslot <slotId> <itemName>"
    * hovering the gearSlot opens the flyout from a secure snippet, so it can open in
      combat as well - showing a protected frame is only allowed from the restricted
      environment
    * clicking a button runs the prepared macro on the player's own hardware event and
      the weapon is equipped right away - no combatQueue involved

  What the prototype deliberately does not do:

    * an addon can still only control WHAT is equipped, never WHEN. There is no way to
      swap on a proc or on low health - the click has to come from the player
    * the macro addresses the item by name, so it cannot distinguish two copies of the
      same item with different enchants or runes the way the combatQueue path can
    * the flyout content is frozen for the duration of a fight. Items looted (or the
      quality filter changed) during combat only show up after leaving combat
]]--

local mod = rggm
local me = {}

mod.weaponFlyout = me

me.tag = "WeaponFlyout"

--[[
  Label under which a gearSlot publishes its own flyout to the restricted environment.
  Secure snippets have no access to the addon namespace - a frame is only addressable
  in there once it was explicitly handed over with SetFrameRef
]]--
local FLYOUT_FRAME_REF = "weaponFlyout"

--[[
  Attribute mirroring whether the flyout currently holds at least one usable macro button.
  Written out of combat by UpdateFlyout, read from the restricted environment (which
  cannot inspect children) and by me.IsFlyoutActive
]]--
local ATTRIBUTE_HAS_ITEMS = "hasItems"

--[[
  Opening the flyout. The snippets below are wrapped around the gearSlot's own OnEnter /
  OnLeave scripts (see me.SetupGearSlot) and run inside the restricted environment, which may
  show and hide protected frames even during combat lockdown - that is what makes the flyout
  reachable in combat at all. An empty flyout must never open
]]--
local SHOW_FLYOUT_SNIPPET = string.format([[
  local flyout = self:GetFrameRef("%s")

  if flyout and flyout:GetAttribute("%s") then
    flyout:Show()
  end
]], FLYOUT_FRAME_REF, ATTRIBUTE_HAS_ITEMS)

--[[
  Leaving the gearSlot towards its own flyout must not close it. The flyout is anchored
  flush against the gearSlot, so by the time OnLeave fires the mouse already sits on top
  of it and the geometric IsUnderMouse test keeps it open
]]--
local HIDE_FLYOUT_SNIPPET = string.format([[
  local flyout = self:GetFrameRef("%s")

  if flyout and not flyout:IsUnderMouse(true) then
    flyout:Hide()
  end
]], FLYOUT_FRAME_REF)

--[[
  Counterpart on the flyout itself. Moving onto one of its macro buttons fires OnLeave on
  the flyout as well, hence the recursive IsUnderMouse test
]]--
local HIDE_SELF_SNIPPET = [[
  if not self:IsUnderMouse(true) then
    self:Hide()
  end
]]

--[[
  Close the flyout once one of its buttons was used, matching what the changeMenu does after
  an item was picked. Wrapped as the post body of the button's OnClick so it runs after the
  secure action - and, being a snippet, it can close the flyout during combat as well.
  Reaches the flyout through GetParent instead of a frame reference: a flyout button is
  always a direct child of its flyout
]]--
local HIDE_ON_CLICK_SNIPPET = [[
  self:GetParent():Hide()
]]

--[[
  The inventory slots the game allows to change during combat. Every other slot is refused
  by the server no matter how the swap is triggered, so only these get a secure flyout -
  for all others the combatQueue remains the only option
]]--
local combatSwapSlots = {
  [INVSLOT_MAINHAND] = true,
  [INVSLOT_OFFHAND] = true,
  [INVSLOT_RANGED] = true
}

--[[
  Whether an update was requested while the flyouts could not be touched. Rebuilding calls
  SetAttribute/SetPoint on protected frames and is therefore impossible during combat
  lockdown - the request is replayed once the player leaves combat
]]--
local pendingUpdate = false

-- forward declarations
local AnchorFlyout
local AnchorFlyoutSlot
local BuildMacroText
local CollectItems
local LayoutFlyoutSlot
local UpdateFlyout

--[[
  @param {number} slotId

  @return {boolean}
    true - if the game allows the slot to be changed during combat
    false - for every other slot
]]--
function me.IsCombatSwapSlot(slotId)
  return combatSwapSlots[slotId] == true
end

--[[
  Whether the passed gearSlot currently has a flyout worth showing. Mirrors the condition
  the secure snippet evaluates, so the insecure hover path (which suppresses the regular
  changeMenu for flyout slots) can never disagree with what actually opens

  @param {table} gearSlot

  @return {boolean}
]]--
function me.IsFlyoutActive(gearSlot)
  if gearSlot == nil or gearSlot.weaponFlyout == nil then return false end

  return gearSlot.weaponFlyout:GetAttribute(ATTRIBUTE_HAS_ITEMS) == true
end

--[[
  ELEMENTS
]]--

--[[
  Attach a flyout to a freshly created gearSlot and wire up the secure hover handling.
  Whether the flyout ever opens is decided later by UpdateFlyout based on the configured
  slotId.

  Called at the very end of mod.gearBar.SetupEvents on purpose: the secure wrappers
  installed below have to go on top of the gearSlot's own OnEnter/OnLeave handlers, which
  SetupEvents assigns. Wiring this up any earlier risks the wrappers being replaced by those
  later SetScript calls.

  Because of SetAttribute this CANNOT run in combat; the me.CreateGearSlot dispatcher
  already guards against that.

  @param {table} gearSlot
    The gearSlot the flyout is attached to

  @return {table}
    The created flyout frame
]]--
function me.SetupGearSlot(gearSlot)
  local flyout = CreateFrame(
    "Frame",
    RGGM_CONSTANTS.ELEMENT_WEAPON_FLYOUT_FRAME,
    gearSlot,
    "SecureHandlerBaseTemplate, BackdropTemplate"
  )

  flyout:SetSize(
    RGGM_CONSTANTS.GEAR_BAR_CHANGE_DEFAULT_SLOT_SIZE,
    RGGM_CONSTANTS.GEAR_BAR_CHANGE_DEFAULT_SLOT_SIZE
  )
  -- the flyout overlaps neighbouring gearSlots and has to render on top of them
  flyout:SetFrameStrata("DIALOG")
  flyout:EnableMouse(true)
  flyout:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground"
  })
  flyout:SetBackdropColor(0, 0, 0, .5)
  flyout:SetAttribute(ATTRIBUTE_HAS_ITEMS, false)
  --[[
    Insecure counterpart of the closing snippet. Out of combat the flyout is an ordinary
    frame, so closing it does not need the restricted environment at all - which keeps the
    menu behaving even where the snippet does not
  ]]--
  flyout:SetScript("OnLeave", function(self)
    me.HideFlyoutIfUnhovered(self)
  end)
  flyout:Hide()

  flyout.slotPool = mod.uiHelper.CreateFramePool(function(position)
    return mod.themeCoordinator.CreateWeaponFlyoutSlot(flyout, position)
  end)

  --[[
    Published before the wrapping below so a client that refuses the secure wiring still
    leaves a usable out-of-combat flyout behind (and a Lua error naming the exact line)
    instead of a half-built gearSlot
  ]]--
  gearSlot.weaponFlyout = flyout
  gearSlot:SetFrameRef(FLYOUT_FRAME_REF, flyout)

  --[[
    Wrap the hover scripts explicitly instead of going through the _onenter / _onleave
    attributes of SecureHandlerEnterLeaveTemplate. Those wrappers are installed when the
    frame is created - before the gearSlot has any OnEnter/OnLeave handler of its own -
    while wrapping here happens after mod.gearBar.SetupEvents assigned them. A wrapper
    placed on top of the final handlers holds no matter how the client implements wrapping
  ]]--
  SecureHandlerWrapScript(gearSlot, "OnEnter", gearSlot, SHOW_FLYOUT_SNIPPET)
  SecureHandlerWrapScript(gearSlot, "OnLeave", gearSlot, HIDE_FLYOUT_SNIPPET)
  SecureHandlerWrapScript(flyout, "OnLeave", flyout, HIDE_SELF_SNIPPET)

  return flyout
end

--[[
  UPDATE
]]--

--[[
  Rebuild every flyout of every gearBar. Deferred to the next combat exit while the player
  is in combat - a flyout is a protected frame and cannot be re-laid-out during lockdown
]]--
function me.UpdateAllFlyouts()
  if InCombatLockdown() then
    pendingUpdate = true

    return
  end

  pendingUpdate = false

  for _, gearBar in pairs(mod.gearBarManager.GetGearBars()) do
    me.UpdateGearBarFlyouts(gearBar)
  end
end

--[[
  Rebuild all flyouts of a single gearBar

  @param {table} gearBar
]]--
function me.UpdateGearBarFlyouts(gearBar)
  if InCombatLockdown() then
    pendingUpdate = true

    return
  end

  for position = 1, #gearBar.slots do
    UpdateFlyout(gearBar, position)
  end
end

--[[
  Replay a deferred rebuild once the player left combat. Invoked from the
  PLAYER_REGEN_ENABLED handler in code/Core.lua
]]--
function me.OnLeaveCombat()
  if not pendingUpdate then return end

  me.UpdateAllFlyouts()
end

--[[
  Update the useOnKeyDown attribute of all flyout buttons of a gearSlot to match the
  fastpress configuration. Counterpart of mod.gearBar.UpdateClickHandler, which drives it

  @param {table} gearSlot
]]--
function me.UpdateClickHandler(gearSlot)
  if gearSlot.weaponFlyout == nil then return end

  gearSlot.weaponFlyout.slotPool.ForEach(function(flyoutSlot)
    flyoutSlot:SetAttribute("useOnKeyDown", mod.configuration.IsFastPressEnabled())
  end)
end

--[[
  Rebuild the flyout of a single gearSlot. Clears the flyout first so a slot that no longer
  qualifies (feature disabled, reconfigured to a non weapon slot, no items available) ends
  up in a state where the secure snippet refuses to open it.

  Callers guarantee that this does not run during combat lockdown

  @param {table} gearBar
  @param {number} position
    Position on the gearBar
]]--
UpdateFlyout = function(gearBar, position)
  local uiGearBar = mod.gearBarStorage.GetGearBar(gearBar.id)

  if uiGearBar == nil then return end

  local uiGearSlot = uiGearBar.gearSlotReferences[position]

  if uiGearSlot == nil or uiGearSlot.weaponFlyout == nil then return end

  local flyout = uiGearSlot.weaponFlyout

  flyout:Hide()
  flyout:SetAttribute(ATTRIBUTE_HAS_ITEMS, false)
  flyout.slotPool.ReleaseAll()

  if not mod.configuration.IsWeaponFlyoutEnabled() then return end

  local gearSlotMetaData = gearBar.slots[position]

  if gearSlotMetaData == nil or not me.IsCombatSwapSlot(gearSlotMetaData.slotId) then return end

  local items = CollectItems(gearSlotMetaData)

  if #items == 0 then
    mod.logger.LogDebug(me.tag, "No eligible items for the weaponFlyout of slotId "
      .. gearSlotMetaData.slotId .. " - keeping it closed")

    return
  end

  --[[
    Deliberately not scaled by the uiScale the way the changeMenu does it. The changeMenu is a
    parentless frame and has to compensate for the UIParent scale by hand - the flyout is a
    child of its gearSlot and already lives in that scale
  ]]--
  local flyoutSlotSize = mod.gearBarManager.GetChangeSlotSize(gearBar.id)
  local columnAmount = RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT
  -- the unequip slot takes the next free grid position after the last item, as in the changeMenu
  local hasUnequipSlot = mod.configuration.IsUnequipSlotEnabled()
    and mod.itemManager.HasItemEquipedInSlot(gearSlotMetaData.slotId)
  local totalSlots = hasUnequipSlot and #items + 1 or #items

  for index = 1, #items do
    local flyoutSlot = flyout.slotPool.Acquire(index)

    LayoutFlyoutSlot(flyout, flyoutSlot, index, flyoutSlotSize, gearBar.changeMenuDirection)

    flyoutSlot.isUnequipSlot = false
    flyoutSlot.itemId = items[index].id
    --[[
      Deliberately no slotId: the tooltip would resolve it to the item currently worn in that
      inventory slot instead of the bag candidate this button equips
    ]]--
    flyoutSlot.slotId = nil
    flyoutSlot.itemTexture:SetTexture(items[index].icon)
    flyoutSlot:SetAttribute("type", "macro")
    flyoutSlot:SetAttribute("macrotext", BuildMacroText(gearSlotMetaData.slotId, items[index].name))
    flyoutSlot:Show()

    mod.logger.LogDebug(me.tag, "Prepared flyout macro for slotId " .. gearSlotMetaData.slotId
      .. " - " .. items[index].name)
  end

  if hasUnequipSlot then
    local unequipSlot = flyout.slotPool.Acquire(totalSlots)

    LayoutFlyoutSlot(flyout, unequipSlot, totalSlots, flyoutSlotSize, gearBar.changeMenuDirection)

    --[[
      Not a macro button - nothing in the secure toolbox can take an item off. It carries no
      action at all and is handled insecurely in me.FlyoutSlotOnClick, which limits it to out
      of combat. Clearing type and macrotext matters because the pool reuses buttons
    ]]--
    unequipSlot.isUnequipSlot = true
    unequipSlot.itemId = nil
    unequipSlot.slotId = gearSlotMetaData.slotId
    unequipSlot.itemTexture:SetTexture(gearSlotMetaData.textureId)
    unequipSlot:SetAttribute("type", nil)
    unequipSlot:SetAttribute("macrotext", nil)
    unequipSlot:Show()
  end

  flyout:SetSize(
    math.min(totalSlots, columnAmount) * flyoutSlotSize,
    math.ceil(totalSlots / columnAmount) * flyoutSlotSize
  )
  AnchorFlyout(flyout, uiGearSlot, gearBar.changeMenuDirection)
  flyout:SetAttribute(ATTRIBUTE_HAS_ITEMS, true)

  mod.logger.LogInfo(me.tag, "Prepared weaponFlyout for slotId " .. gearSlotMetaData.slotId
    .. " with " .. totalSlots .. " entries")
end

--[[
  Size, anchor and style a single flyout button at its grid position

  @param {table} flyout
  @param {table} flyoutSlot
  @param {number} index
    1 based position within the flyout grid
  @param {number} flyoutSlotSize
  @param {number} changeMenuDirection
]]--
LayoutFlyoutSlot = function(flyout, flyoutSlot, index, flyoutSlotSize, changeMenuDirection)
  local xPos, yPos = mod.uiHelper.CalculateGridPosition(
    index,
    RGGM_CONSTANTS.GEAR_BAR_CHANGE_COLUMN_AMOUNT,
    flyoutSlotSize
  )

  flyoutSlot:SetSize(flyoutSlotSize, flyoutSlotSize)
  AnchorFlyoutSlot(flyout, flyoutSlot, xPos, yPos, changeMenuDirection)
  mod.themeCoordinator.UpdateSlotTextureAttributes(flyoutSlot, flyoutSlotSize)
end

--[[
  Collect the items a flyout offers for a gearSlot, deduplicated by name - the macro
  addresses its target by name, so two entries with the same name would produce the exact
  same button.

  The currently worn weapon is listed first on purpose. A flyout cannot be rebuilt while
  the player is in combat, so without it the weapon that was worn when the fight started
  would have no button to swap back to after the first swap

  @param {table} gearSlotMetaData

  @return {table}
    List of {id, name, icon} records, capped at RGGM_CONSTANTS.WEAPON_FLYOUT_SLOT_AMOUNT
]]--
CollectItems = function(gearSlotMetaData)
  local items = {}
  local seen = {}
  local wornItemId = GetInventoryItemID(RGGM_CONSTANTS.UNIT_ID_PLAYER, gearSlotMetaData.slotId)

  if wornItemId ~= nil then
    local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(wornItemId)

    if itemName ~= nil then
      seen[itemName] = true
      items[#items + 1] = { ["id"] = wornItemId, ["name"] = itemName, ["icon"] = itemIcon }
    end
  end

  for _, item in ipairs(mod.itemManager.GetItemsForInventoryType(gearSlotMetaData.type)) do
    if #items >= RGGM_CONSTANTS.WEAPON_FLYOUT_SLOT_AMOUNT then break end

    if item.name ~= nil and not seen[item.name] then
      seen[item.name] = true
      items[#items + 1] = item
    end
  end

  return items
end

--[[
  Build the macro a flyout button executes. /equipslot is the secure counterpart of the
  insecure equip functions - it is the only way to target a specific inventory slot from a
  macro (relevant for one handers, which would otherwise land in whichever hand the client
  picks)

  @param {number} slotId
  @param {string} itemName

  @return {string}
]]--
BuildMacroText = function(slotId, itemName)
  return string.format("/equipslot %d %s", slotId, itemName)
end

--[[
  Anchor the flyout adjacent to its gearSlot in the direction configured for the gearBar,
  mirroring mod.gearBarChangeMenu.UpdateChangeMenuPosition. The frames touch on purpose -
  a gap would let the secure OnLeave snippet close the flyout while the mouse travels
  towards it

  @param {table} flyout
  @param {table} gearSlot
  @param {number} changeMenuDirection
    One of RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_UP / _DOWN / _LEFT / _RIGHT
]]--
AnchorFlyout = function(flyout, gearSlot, changeMenuDirection)
  flyout:ClearAllPoints()

  if changeMenuDirection == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_DOWN then
    flyout:SetPoint("TOPLEFT", gearSlot, "BOTTOMLEFT", 0, 0)
  elseif changeMenuDirection == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_LEFT then
    flyout:SetPoint("BOTTOMRIGHT", gearSlot, "BOTTOMLEFT", 0, 0)
  elseif changeMenuDirection == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_RIGHT then
    flyout:SetPoint("BOTTOMLEFT", gearSlot, "BOTTOMRIGHT", 0, 0)
  else
    -- GEAR_BAR_CHANGE_MENU_DIRECTION_UP (default)
    flyout:SetPoint("BOTTOMLEFT", gearSlot, "TOPLEFT", 0, 0)
  end
end

--[[
  Place a single flyout button inside the flyout, mirroring the growth logic of
  mod.gearBarChangeMenu.UpdateChangeSlotSize - for DOWN/LEFT the flyout sits on the
  opposite side of the gearSlot, so the growth direction has to be inverted as well

  @param {table} flyout
  @param {table} flyoutSlot
  @param {number} xPos
  @param {number} yPos
  @param {number} changeMenuDirection
]]--
AnchorFlyoutSlot = function(flyout, flyoutSlot, xPos, yPos, changeMenuDirection)
  local point = "BOTTOMLEFT"
  local xOffset = xPos
  local yOffset = yPos

  if changeMenuDirection == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_DOWN then
    point = "TOPLEFT"
    yOffset = -yPos
  elseif changeMenuDirection == RGGM_CONSTANTS.GEAR_BAR_CHANGE_MENU_DIRECTION_LEFT then
    point = "BOTTOMRIGHT"
    xOffset = -xPos
  end

  flyoutSlot:ClearAllPoints()
  flyoutSlot:SetPoint(point, flyout, point, xOffset, yOffset)
end

--[[
  EVENTS
]]--

--[[
  Setup events for a flyout button. The button carries a prepared macro - the actual equip
  is performed by the secure code path behind it and must not (and cannot) be replaced by
  an OnClick handler of our own

  @param {table} flyoutSlot
]]--
function me.SetupEvents(flyoutSlot)
  --[[
    Register both click directions and let useOnKeyDown decide which one triggers the
    secure action, matching the fastpress handling of a gearSlot (see mod.gearBar.SetupEvents)
  ]]--
  flyoutSlot:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
  flyoutSlot:SetAttribute("useOnKeyDown", mod.configuration.IsFastPressEnabled())

  flyoutSlot:SetScript("OnEnter", me.FlyoutSlotOnEnter)
  flyoutSlot:SetScript("OnLeave", me.FlyoutSlotOnLeave)
  -- replacement for OnClick - the secure action of a protected button must not be overwritten
  flyoutSlot:SetScript("PreClick", me.FlyoutSlotOnClick)

  -- a flyout button is always a direct child of its flyout, which is the secure handler here
  SecureHandlerWrapScript(flyoutSlot, "OnClick", flyoutSlot:GetParent(), "", HIDE_ON_CLICK_SNIPPET)
end

--[[
  Callback for a flyout button PreClick. Only the unequip slot does any work here - every
  other button carries a prepared macro that the secure code path behind it executes.

  Fires for the down and the up phase of every click (see me.SetupEvents) and is gated to the
  phase matching the fastpress configuration so it runs exactly once per activation

  @param {table} self
  @param {string} _
    The clicked button (unused)
  @param {boolean} down
    true for the buttonDown phase, false for the buttonUp phase
]]--
function me.FlyoutSlotOnClick(self, _, down)
  if down ~= mod.configuration.IsFastPressEnabled() then return end
  if not self.isUnequipSlot then return end

  --[[
    Unequipping has no secure counterpart - no slash command removes an item, and the
    functions that do are protected. Unlike every other button of the flyout this one is
    therefore limited to out of combat
  ]]--
  if InCombatLockdown() then
    mod.logger.PrintUserChatError(rggm.L["weapon_flyout_unequip_in_combat"])

    return
  end

  mod.itemManager.UnequipItemToBag(self)
end

--[[
  Callback for a flyout button OnEnter

  @param {table} self
]]--
function me.FlyoutSlotOnEnter(self)
  mod.tooltip.UpdateTooltipForItem(self)
  mod.themeCoordinator.ChangeSlotOnEnter(self)
end

--[[
  Callback for a flyout button OnLeave

  @param {table} self
]]--
function me.FlyoutSlotOnLeave(self)
  -- a flyout button is a direct child of its flyout
  me.HideFlyoutIfUnhovered(self:GetParent())
  mod.tooltip.TooltipClear()
  mod.themeCoordinator.ChangeSlotOnLeave(self)
end

--[[
  Open a prepared flyout while the player is out of combat. Opening during combat is the
  exclusive job of the secure snippet - out of combat the flyout is an ordinary frame and
  showing it directly needs no restricted environment at all.

  Keeping both paths means the menu works out of combat regardless of what the restricted
  environment allows, and narrows a "the flyout never opens" report down to the combat case

  @param {table} gearSlot
]]--
function me.ShowFlyoutIfPrepared(gearSlot)
  if InCombatLockdown() then return end
  if not me.IsFlyoutActive(gearSlot) then return end

  gearSlot.weaponFlyout:Show()
end

--[[
  Close a flyout the mouse has left, provided it can be closed at all. During combat the
  flyout is a protected frame that only the secure _onleave snippet may hide - out of combat
  this is the path that actually runs, which keeps the hover behaviour independent of what
  the restricted environment happens to allow.

  Hovering the owning gearSlot or anything inside the flyout counts as still hovering it,
  mirroring the recursive IsUnderMouse test of the snippets

  @param {table} flyout
]]--
function me.HideFlyoutIfUnhovered(flyout)
  if flyout == nil or InCombatLockdown() then return end
  if not flyout:IsShown() then return end
  if MouseIsOver(flyout) or MouseIsOver(flyout:GetParent()) then return end

  flyout:Hide()
end
