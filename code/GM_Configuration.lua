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

-- luacheck: globals INVSLOT_HEAD INVSLOT_NECK INVSLOT_SHOULDER INVSLOT_CHEST INVSLOT_WAIST INVSLOT_LEGS INVSLOT_FEET
-- luacheck: globals INVSLOT_WRIST INVSLOT_HAND INVSLOT_FINGER1 INVSLOT_FINGER2 INVSLOT_TRINKET1 INVSLOT_TRINKET2
-- luacheck: globals INVSLOT_BACK INVSLOT_MAINHAND INVSLOT_OFFHAND INVSLOT_RANGED INVSLOT_AMMO GetAddOnMetadata ReloadUI
-- luacheck: globals GetBindingKey SetBinding SetBindingClick GetCurrentBindingSet AttemptToSaveBindings

local mod = rggm
local me = {}
mod.configuration = me

me.tag = "Configuration"

GearMenuConfiguration = {
  ["addonVersion"] = nil,
  --[[
    Whether the first time initialization was already done
  ]]--
  ["firstTimeInitializationDone"] = false,
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
  ["enableFastPress"] = false,
  --[[
    Whether an empty slot that enables unequipping items is displayed or not
  ]]--
  ["enableUnequipSlot"] = true,
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
    Stores all relevant metadata for the users gearBars. It does only store data that should be persisted. This
    does not include references to ui elements

    {
      ["id"] = {number},
        A unique identifier for the gearBar. This identifier can be directly matched to the GearBar
        UI-Element once it is created
      ["displayName"] = {string},
        A user friendly display name for the user to recognize
      ["position"] = {table},
        A position object that can be unpacked into SetPoint
        e.g. {"LEFT", 150, 0}
      [slots] = {},

    }
  ]]--
  ["gearBars"] = nil,
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
  ["quickChangeRules"] = {}
}

--[[
  Set default values if property is nil. This might happen after an addon upgrade
]]--
function me.SetupConfiguration()
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

  if GearMenuConfiguration.enableFastPress == nil then
    mod.logger.LogInfo(me.tag, "enableFastPress has unexpected nil value")
    GearMenuConfiguration.enableFastPress = false
  end

  if GearMenuConfiguration.enableUnequipSlot == nil then
    mod.logger.LogInfo(me.tag, "enableUnequipSlot has unexpected nil value")
    GearMenuConfiguration.enableUnequipSlot = false
  end

  if GearMenuConfiguration.filterItemQuality == nil then
    mod.logger.LogInfo(me.tag, "filterItemQuality has unexpected nil value")
    GearMenuConfiguration.filterItemQuality = 0
  end

  if GearMenuConfiguration.gearBars == nil then
    mod.logger.LogInfo(me.tag, "gearBars has unexpected nil value")
    GearMenuConfiguration.gearBars = {}
  end

  if GearMenuConfiguration.quickChangeRules == nil then
    mod.logger.LogInfo(me.tag, "quickChangeRules has unexpected nil value")
    GearMenuConfiguration.quickChangeRules = {}
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

  if #GearMenuConfiguration.gearBars == 0 and not GearMenuConfiguration.firstTimeInitializationDone then
    me.FirstTimeInitialization()
  end
end

--[[
  Run through all migration paths. Each migration path needs to decide by itself whether it
  should run or not.
]]--
function me.MigrationPath()
  me.UpgradeToV1_3_0()
  me.UpgradeToV1_4_0()
  me.UpgradeToV2_0_0()
end

--[[
  First time initialization. Create a basic default gearBar
]]--
function me.FirstTimeInitialization()
  mod.logger.LogInfo(me.tag, "First initialization detected. Creating default gearBar")

  local gearBar = mod.gearBarManager.AddGearBar(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_NAME, false)
  mod.gearBarManager.AddGearSlot(gearBar.id)
  mod.gearBarManager.UpdateGearSlot(gearBar.id, 1, mod.gearManager.GetGearSlotForSlotId(INVSLOT_TRINKET1))

  mod.gearBarManager.AddGearSlot(gearBar.id)
  mod.gearBarManager.UpdateGearSlot(gearBar.id, 2, mod.gearManager.GetGearSlotForSlotId(INVSLOT_TRINKET2))

  mod.gearBarManager.AddGearSlot(gearBar.id)
  mod.gearBarManager.UpdateGearSlot(gearBar.id, 3, mod.gearManager.GetGearSlotForSlotId(INVSLOT_HEAD))

  GearMenuConfiguration.firstTimeInitializationDone = true
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
  Should be run by versions: All < v1.4.0
  Description: Renamed enableFastpress to enableFastPress
]]--
function me.UpgradeToV1_4_0()
  local versions = {"v1.3.0", "v1.2.0", "v1.1.0", "v1.0.1", "v1.0.0"}
  local shouldRunUpgradePath = false

  for _, version in pairs(versions) do
    if GearMenuConfiguration.addonVersion == version then
      shouldRunUpgradePath = true
      break
    end
  end

  if not shouldRunUpgradePath then return end

  mod.logger.LogDebug(me.tag, "Running upgrade path from " .. GearMenuConfiguration.addonVersion .. " to v1.4.0")

  GearMenuConfiguration.enableFastPress = GearMenuConfiguration.enableFastpress
  GearMenuConfiguration.enableFastpress = nil

  mod.logger.LogDebug(me.tag, "Finished upgrade path from " .. GearMenuConfiguration.addonVersion .. " to v1.4.0")
end

--[[
  Should be run by versions: All < v2.0.0
  Description: Complete overhault of how gearBars are created
]]--
function me.UpgradeToV2_0_0()
  local versions = {"v1.6.0", "v1.5.0", "v1.4.0", "v1.3.0", "v1.2.0", "v1.1.0", "v1.0.1", "v1.0.0"}
  local shouldRunUpgradePath = false

  for _, version in pairs(versions) do
    if GearMenuConfiguration.addonVersion == version then
      shouldRunUpgradePath = true
      break
    end
  end

  if not shouldRunUpgradePath then return end

  mod.logger.LogDebug(me.tag, "Running upgrade path from " .. GearMenuConfiguration.addonVersion .. " to v2.0.0")

  local gearBar = mod.gearBarManager.AddGearBar(RGGM_CONSTANTS.GEAR_BAR_DEFAULT_NAME, false)

  gearBar.isLocked = GearMenuConfiguration.lockGearBar
  gearBar.showKeyBindings = GearMenuConfiguration.showKeyBindings
  gearBar.showCooldowns = GearMenuConfiguration.showCooldowns
  gearBar.gearSlotSize = GearMenuConfiguration.slotSize
  gearBar.changeSlotSize = GearMenuConfiguration.slotSize -- use gearSlot size as changeSlot size
  gearBar.position = {}
  gearBar.position.relativePoint = GearMenuConfiguration.frames.GM_GearBar.relativePoint
  gearBar.position.point = GearMenuConfiguration.frames.GM_GearBar.point
  gearBar.position.posX = GearMenuConfiguration.frames.GM_GearBar.posX
  gearBar.position.posY = GearMenuConfiguration.frames.GM_GearBar.posY
  gearBar.slots = nil -- reset slots
  gearBar.slots = {}

  local slotPosition = 1

  for i = 1, #GearMenuConfiguration.slots do
    if GearMenuConfiguration.slots[i] ~= RGGM_CONSTANTS.INVSLOT_NONE then
      local gearSlot = mod.gearManager.GetGearSlotForSlotId(GearMenuConfiguration.slots[i])
      -- check if a keybinding was set for that slot
      local key = GetBindingKey("CLICK GM_GearBarSlot_" .. i .. ":LeftButton")

      if key ~= nil then
        mod.logger.LogInfo(me.tag, "Slot with id{" .. i .. "} has keyBinding{" .. key .. "} set - attempting migration")

        SetBinding(key)
        SetBindingClick(
          key,
          RGGM_CONSTANTS.ELEMENT_GEAR_BAR_BASE_FRAME_NAME .. gearBar.id .. "Slot_" .. slotPosition
        )

        gearSlot.keyBinding = key
      end

      table.insert(gearBar.slots, gearSlot)
      slotPosition = slotPosition + 1
    end
  end

  -- unbind rest of possible keybind corpses
  for i = 1, 17 do -- there where a max amount of 17 slots possible
    local key = GetBindingKey("CLICK GM_GearBarSlot_" .. i .. ":LeftButton")

    if key ~= nil then
      SetBinding(key)
    end
  end

  AttemptToSaveBindings(GetCurrentBindingSet()) -- save bindings

  -- no longer used properties (moved to specific gearBar)
  GearMenuConfiguration.lockGearBar = nil
  GearMenuConfiguration.showKeyBindings = nil
  GearMenuConfiguration.showCooldowns = nil
  GearMenuConfiguration.slotSize = nil
  GearMenuConfiguration.frames = nil
  GearMenuConfiguration.slots = nil

  mod.logger.LogDebug(me.tag, "Finished upgrade path from " .. GearMenuConfiguration.addonVersion .. " to v2.0.0")
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
function me.EnableFastPress()
  GearMenuConfiguration.enableFastPress = true
  mod.gearBar.UpdateClickHandler()
end

--[[
  Disable fastpress on GearMenu itemslots
]]--
function me.DisableFastPress()
  GearMenuConfiguration.enableFastPress = false
  mod.gearBar.UpdateClickHandler()
end

--[[
  @return {boolean}
    true - if fastpress on GearMenu itemslots is enabled
    false - if fastpress drop on GearMenu itemslots is disabled
]]--
function me.IsFastPressEnabled()
  return GearMenuConfiguration.enableFastPress
end

--[[
  Enable enableUnequipSlot on GearMenu itemslots
]]--
function me.EnableUnequipSlot()
  GearMenuConfiguration.enableUnequipSlot = true
end

--[[
  Disable enableUnequipSlot on GearMenu itemslots
]]--
function me.DisableUnequipSlot()
  GearMenuConfiguration.enableUnequipSlot = false
end

--[[
  @return {boolean}
    true - if unequipSlot is enabled
    false - if unequipSlot is disable
]]--
function me.IsUnequipSlotEnabled()
  return GearMenuConfiguration.enableUnequipSlot
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
