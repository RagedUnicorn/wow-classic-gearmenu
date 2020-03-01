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

-- luacheck: globals INVSLOT_HEAD INVSLOT_NECK INVSLOT_SHOULDER INVSLOT_CHEST INVSLOT_WAIST INVSLOT_LEGS INVSLOT_FEET
-- luacheck: globals INVSLOT_WRIST INVSLOT_HAND INVSLOT_FINGER1 INVSLOT_FINGER2 INVSLOT_TRINKET1 INVSLOT_TRINKET2
-- luacheck: globals INVSLOT_BACK INVSLOT_MAINHAND INVSLOT_OFFHAND INVSLOT_RANGED INVSLOT_AMMO GetAddOnMetadata

local mod = rggm
local me = {}
mod.configuration = me

me.tag = "Configuration"

GearMenuConfiguration = {
  ["addonVersion"] = nil,
  --[[
    Whether the gearBar is locked from moving or not
  ]]--
  ["lockGearBar"] = false,
  --[[
    Whether to show keybindings on the itemslots
  ]]--
  ["showKeyBindings"] = true,
  --[[
    Whether to show cooldowns on the itemslots
  ]]--
  ["showCooldowns"] = true,
  --[[
    Whether to enable tooltips
  ]]--
  ["enableTooltips"] = true,
  --[[
    Whether simple tooltips (single line) are enabled or not
  ]]--
  ["enableSimpleTooltips"] = false,
  --[[
    Whether to disable drag and drop between and onto GearMenu itemslots
  ]]--
  ["enableDragAndDrop"] = true,
  --[[
    Whether fastpress is enabled or not. If fastpress is activated actions will be
    triggered as soon as a key is pressed down instead of waiting for the keyup event
  ]]--
  ["enableFastpress"] = false,
  --[[
    Itemquality to filter items by their quality. Everything that is below the settings value
    will not be considered a valid item to display when building the changemenu.
    By default all items are allowed

    0 Poor (gray)
    1 Common (white)
    2 Uncommon (green)
    3 Rare (blue)
    4 Epic (purple)
    5 Legendary (orange)
  ]]--
  ["filterItemQuality"] = 2,
  --[[
    Base size for a slot such as the changeMenu and gearBar
  ]]--
  ["slotSize"] = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE,
  --[[
    Initial default slot mapping
  ]]--
  ["slots"] = {
    [1] = INVSLOT_HEAD,
    [2] = RGGM_CONSTANTS.INVSLOT_NONE,
    [3] = RGGM_CONSTANTS.INVSLOT_NONE,
    [4] = INVSLOT_CHEST,
    [5] = INVSLOT_WAIST,
    [6] = RGGM_CONSTANTS.INVSLOT_NONE,
    [7] = INVSLOT_FEET,
    [8] = RGGM_CONSTANTS.INVSLOT_NONE,
    [9] = RGGM_CONSTANTS.INVSLOT_NONE,
    [10] = RGGM_CONSTANTS.INVSLOT_NONE,
    [11] = RGGM_CONSTANTS.INVSLOT_NONE,
    [12] = INVSLOT_TRINKET1,
    [13] = INVSLOT_TRINKET2,
    [14] = RGGM_CONSTANTS.INVSLOT_NONE,
    [15] = INVSLOT_MAINHAND,
    [16] = INVSLOT_OFFHAND,
    [17] = RGGM_CONSTANTS.INVSLOT_NONE
  },
  --[[
    example
    {
      ["changeFromName"] = {string},
      ["changeFromItemId"] = {number},
      ["changeFromItemIcon"] = {string},
      ["changeFromItemQuality"] = {number},
      ["changeToName"] = {string},
      ["changeToItemId"] = {number},
      ["changeToItemIcon"] = {string},
      ["changeToItemQuality"] = {number},
      ["equipSlot"] = {{number}, {number}},
      ["spellId"] = {number},
      ["delay"] = {number} -- delay in seconds
    }
  ]]--
  ["quickChangeRules"] = {},
  --[[
    Framepositions for user draggable Frames
    frames = {
      -- should match the actual frame name
      ["GM_Frame"] = {
      point: "CENTER",
        posX: 0,
        posY: 0
      }
      ...
    }
  ]]--
  ["frames"] = {}
}

--[[
  Set default values if property is nil. This might happen after an addon upgrade
]]--
function me.SetupConfiguration()
  if GearMenuConfiguration.lockGearBar == nil then
    mod.logger.LogInfo(me.tag, "lockGearBar has unexpected nil value")
    GearMenuConfiguration.lockGearBar = true
  end

  if GearMenuConfiguration.showKeyBindings == nil then
    mod.logger.LogInfo(me.tag, "showKeyBindings has unexpected nil value")
    GearMenuConfiguration.showKeyBindings = true
  end

  if GearMenuConfiguration.showCooldowns == nil then
    mod.logger.LogInfo(me.tag, "showCooldowns has unexpected nil value")
    GearMenuConfiguration.showCooldowns = false
  end

  if GearMenuConfiguration.enableTooltips == nil then
    mod.logger.LogInfo(me.tag, "enableTooltips has unexpected nil value")
    GearMenuConfiguration.enableTooltips = true
  end

  if GearMenuConfiguration.enableSimpleTooltips == nil then
    mod.logger.LogInfo(me.tag, "enableSimpleTooltips has unexpected nil value")
    GearMenuConfiguration.enableSimpleTooltips = false
  end

  if GearMenuConfiguration.enableDragAndDrop == nil then
    mod.logger.LogInfo(me.tag, "enableDragAndDrop has unexpected nil value")
    GearMenuConfiguration.enableDragAndDrop = true
  end

  if GearMenuConfiguration.enableFastpress == nil then
    mod.logger.LogInfo(me.tag, "enableFastpress has unexpected nil value")
    GearMenuConfiguration.enableFastpress = false
  end

  if GearMenuConfiguration.filterItemQuality == nil then
    mod.logger.LogInfo(me.tag, "filterItemQuality has unexpected nil value")
    GearMenuConfiguration.filterItemQuality = 0
  end

  if GearMenuConfiguration.slotSize == nil then
    mod.logger.LogInfo(me.tag, "slotSize has unexpected nil value")
    GearMenuConfiguration.slotSize = RGGM_CONSTANTS.GEAR_BAR_DEFAULT_SLOT_SIZE
  end

  if GearMenuConfiguration.slots == nil then
    mod.logger.LogInfo(me.tag, "slots has unexpected nil value")

    GearMenuConfiguration.slots = {
      [1] = INVSLOT_HEAD,
      [2] = RGGM_CONSTANTS.INVSLOT_NONE,
      [3] = RGGM_CONSTANTS.INVSLOT_NONE,
      [4] = INVSLOT_CHEST,
      [5] = INVSLOT_WAIST,
      [6] = RGGM_CONSTANTS.INVSLOT_NONE,
      [7] = INVSLOT_FEET,
      [8] = RGGM_CONSTANTS.INVSLOT_NONE,
      [9] = RGGM_CONSTANTS.INVSLOT_NONE,
      [10] = RGGM_CONSTANTS.INVSLOT_NONE,
      [11] = RGGM_CONSTANTS.INVSLOT_NONE,
      [12] = INVSLOT_TRINKET1,
      [13] = INVSLOT_TRINKET2,
      [14] = RGGM_CONSTANTS.INVSLOT_NONE,
      [15] = INVSLOT_MAINHAND,
      [16] = INVSLOT_OFFHAND,
      [17] = RGGM_CONSTANTS.INVSLOT_NONE
    }
  end

  if GearMenuConfiguration.quickChangeRules == nil then
    mod.logger.LogInfo(me.tag, "quickChangeRules has unexpected nil value")
    GearMenuConfiguration.quickChangeRules = {}
  end

  if GearMenuConfiguration.frames == nil then
    mod.logger.LogInfo(me.tag, "frames has unexpected nil value")
    GearMenuConfiguration.frames = {}
  end

  --[[
    Set saved variables with addon version. This can be used later to determine whether
    a migration path applies to the current saved variables or not
  ]]--
  me.SetAddonVersion()
end

--[[
  Set addon version on addon options. Before setting a new version make sure
  to run through migration paths.
]]--
function me.SetAddonVersion()
  -- if no version set so far make sure to set the current one
  if GearMenuConfiguration.addonVersion == nil then
    GearMenuConfiguration.addonVersion = GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")
  end

  me.MigrationPath()
  -- migration done update addon version to current
  GearMenuConfiguration.addonVersion = GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")
end

--[[
  Run through all migration paths. Each migration path needs to decide by itself whether it
  should run or not.
]]--
function me.MigrationPath()
  me.UpgradeToV1_3_0()
end

--[[
  Should be run by versions: All < v1.3.0
  Description: RGGM_CONSTANTS.INVSLOT_NONE was previously defined as 0 (zero) for slots
  that where inactive and did not have an active slot. 0 (zero) however is the ammo slots in wow
  because of that we change the definition to 99. All old configurations need to be adapted to reflect this.
]]--
function me.UpgradeToV1_3_0()
  local versions = {"v1.2.0", "v1.1.0", "v1.0.1", "v1.0.0"}
  local shouldRunUpgradePath = false

  for _, version in pairs(versions) do
    if GearMenuConfiguration.addonVersion == version then
      shouldRunUpgradePath = true
      break
    end
  end

  if not shouldRunUpgradePath then return end

  mod.logger.LogDebug(me.tag, "Running upgrade path from " .. GearMenuConfiguration.addonVersion .. " to v1.3.0")

  local slots = GearMenuConfiguration.slots

  for i = 0, #slots do
    if slots[i] == 0 then
      slots[i] = RGGM_CONSTANTS.INVSLOT_NONE
    end
  end

  mod.logger.LogDebug(me.tag, "Finished upgrade path from " .. GearMenuConfiguration.addonVersion .. " to v1.3.0")
end

--[[
  Enable moving of gearBar window
]]--
function me.UnlockGearBar()
  GearMenuConfiguration.lockGearBar = false
  _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME]:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
  })
end

--[[
  Disable moving of gearBar window
]]--
function me.LockGearBar()
  GearMenuConfiguration.lockGearBar = true
  _G[RGGM_CONSTANTS.ELEMENT_GEAR_BAR_FRAME]:SetBackdrop(nil)
end

--[[
  @return {boolean}
    true - if the gearBar is locked
    false - if the gearBar is not locked
]]--
function me.IsGearBarLocked()
  return GearMenuConfiguration.lockGearBar
end

--[[
  Show keybindings
]]--
function me.EnableShowKeyBindings()
  GearMenuConfiguration.showKeyBindings = true
  mod.gearBar.ShowKeyBindings()
  mod.ticker.StartTickerRangeCheck()
end

--[[
  Hide keybindings
]]--
function me.DisableShowKeyBindings()
  GearMenuConfiguration.showKeyBindings = false
  mod.gearBar.HideKeyBindings()
  mod.ticker.StopTickerRangeCheck()
end

--[[
  @return {boolean}
    true - if showing of keybindings is enabled
    false - if showing of keybindings is disabled
]]--
function me.IsShowKeyBindingsEnabled()
  return GearMenuConfiguration.showKeyBindings
end

--[[
  Show cooldowns
]]--
function me.EnableShowCooldowns()
  GearMenuConfiguration.showCooldowns = true
  mod.uiHelper.ShowCooldowns()
end

--[[
  Hide cooldowns
]]--
function me.DisableShowCooldowns()
  GearMenuConfiguration.showCooldowns = false
  mod.uiHelper.HideCooldowns()
end

--[[
  @return {boolean}
    true - if showing of cooldown is enabled
    false - if showing of cooldown is disabled
]]--
function me.IsShowCooldownsEnabled()
  return GearMenuConfiguration.showCooldowns
end

--[[
  Enable tooltips
]]--
function me.EnableTooltips()
  GearMenuConfiguration.enableTooltips = true
end

--[[
  Disable tooltips
]]--
function me.DisableTooltips()
  GearMenuConfiguration.enableTooltips = false
end

--[[
  @return {boolean}
    true - if tooltips are enable
    false - if tooltips are not enabled
]]--
function me.IsTooltipsEnabled()
  return GearMenuConfiguration.enableTooltips
end

--[[
  Enable simple tooltips
]]--
function me.EnableSimpleTooltips()
  GearMenuConfiguration.enableSimpleTooltips = true
end

--[[
  Disable simple tooltips
]]--
function me.DisableSimpleTooltips()
  GearMenuConfiguration.enableSimpleTooltips = false
end

--[[
  @return {boolean}
    true - if simple tooltips are enable
    false - if simple tooltips are not enabled
]]--
function me.IsSimpleTooltipsEnabled()
  return GearMenuConfiguration.enableSimpleTooltips
end

--[[
  Enable drag and drop on GearMenu itemslots
]]--
function me.EnableDragAndDrop()
  GearMenuConfiguration.enableDragAndDrop = true
end

--[[
  Disable drag and drop on GearMenu itemslots
]]--
function me.DisableDragAndDrop()
  GearMenuConfiguration.enableDragAndDrop = false
end

--[[
  @return {boolean}
    true - if drag and drop on GearMenu itemslots is enabled
    false - if drag and drop on GearMenu itemslots is disabled
]]--
function me.IsDragAndDropEnabled()
  return GearMenuConfiguration.enableDragAndDrop
end

--[[
  Enable fastpress on GearMenu itemslots
]]--
function me.EnableFastpress()
  GearMenuConfiguration.enableFastpress = true
  mod.gearBar.UpdateClickHandler()
end

--[[
  Disable fastpress on GearMenu itemslots
]]--
function me.DisableFastpress()
  GearMenuConfiguration.enableFastpress = false
  mod.gearBar.UpdateClickHandler()
end

--[[
  @return {boolean}
    true - if fastpress on GearMenu itemslots is enabled
    false - if fastpress drop on GearMenu itemslots is disabled
]]--
function me.IsFastpressEnabled()
  return GearMenuConfiguration.enableFastpress
end

--[[
  Save itemquality to filter for when building the GearMenu menu on hover

  @param {number} itemQuality
]]--
function me.SetFilterItemQuality(itemQuality)
  assert(type(itemQuality) == "number",
    string.format("bad argument #1 to `SetFilterItemQuality` (expected number got %s)", type(itemQuality)))

  GearMenuConfiguration.filterItemQuality = itemQuality
end

--[[
  Get the itemquality to filter for when building the ChangeMenu

  @return {number}
]]--
function me.GetFilterItemQuality()
  return GearMenuConfiguration.filterItemQuality
end

--[[
  Update the gearbar slotSize

  @param {number} slotSize
]]--
function me.SetSlotSize(slotSize)
  GearMenuConfiguration.slotSize = slotSize
end

--[[
  Get the configured gearbar slotsize

  @return {number}
]]--
function me.GetSlotSize()
  return GearMenuConfiguration.slotSize
end

--[[
  Returns the slotId for a certain slot position

  @param {number} position

  @return {number}
]]--
function me.GetSlotForPosition(position)
  return GearMenuConfiguration.slots[position]
end

--[[
  @param {number} slotId

  @return {number | nil}
    number - If the position for the slotId could be found
    nil    - If the position for the slotId could not be found
]]--
function me.GetSlotForSlotId(slotId)
  for i = 1, table.getn(GearMenuConfiguration.slots) do
    if GearMenuConfiguration.slots[i] == slotId then
      return i
    end
  end

  return nil
end

--[[
  Sets a slotId for a slot position

  @param {number} position
  @param {number} slotId
]]--
function me.SetSlotForPosition(position, slotId)
  GearMenuConfiguration.slots[position] = slotId
end

--[[
  @return {table}
]]--
function me.GetQuickChangeRules()
  return GearMenuConfiguration.quickChangeRules
end

--[[
  @param {table} quickChangeRule
]]--
function me.AddQuickChangeRule(quickChangeRule)
  table.insert(GearMenuConfiguration.quickChangeRules, quickChangeRule)
end

--[[
  @param {number} position
]]--
function me.RemoveQuickChangeRule(position)
  table.remove(GearMenuConfiguration.quickChangeRules, position)
end

--[[
  Save the position of a frame in the addon variables allowing to persist its position

  @param {string} frameName
  @param {string} point
  @param {string} relativeTo
  @param {string} relativePoint
  @param {number} posX
  @param {number} posY
]]--
function me.SaveUserPlacedFramePosition(frameName, point, relativeTo, relativePoint, posX, posY)
  if GearMenuConfiguration.frames[frameName] == nil then
    GearMenuConfiguration.frames[frameName] = {}
  end

  GearMenuConfiguration.frames[frameName].posX = posX
  GearMenuConfiguration.frames[frameName].posY = posY
  GearMenuConfiguration.frames[frameName].point = point
  GearMenuConfiguration.frames[frameName].relativeTo = relativeTo
  GearMenuConfiguration.frames[frameName].relativePoint = relativePoint

  mod.logger.LogDebug(me.tag, "Saved frame position for - " .. frameName
    .. " - new pos: posX " .. posX .. " posY " .. posY .. " point " .. point)
end

--[[
  Get the position of a saved frame

  @param {string} frameName

  @return {table | nil}
    table - the returned x and y position
    nil - if no frame with the passed name could be found
]]--
function me.GetUserPlacedFramePosition(frameName)
  local frameConfig = GearMenuConfiguration.frames[frameName]

  if type(frameConfig) == "table" then
    return frameConfig
  end

  return nil
end
