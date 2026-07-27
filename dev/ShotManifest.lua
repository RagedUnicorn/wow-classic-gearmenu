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

-- THIS FILE IS AUTO-GENERATED. ALL CHANGES ARE OVERWRITTEN
-- Source: wow-media-capture/reference/media/gearmenu.json
-- Regenerate: scripts/gen-shot-table.ps1 -Addon gearmenu

-- shows/name are human-facing copy carried over from the manifest verbatim - reflowing
-- them is not the generator's call, so the 120-column limit does not apply here
-- luacheck: max line length 400

RGGM_SHOTS = {
  {
    name = "gm_switch_items",
    shot = "switch_items",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 250,
    shows = "Hovering a gearSlot opens the changeMenu and clicking an item equips it"
  },
  {
    name = "gm_combat_queue",
    shot = "combat_queue",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 250,
    shows = "Clicking an item in combat parks it in the combatQueue (small icon on the slot), swap fires on leaving combat"
  },
  {
    name = "gm_combat_queue_cancel",
    shot = "combat_queue_cancel",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 250,
    shows = "Right-clicking a gearSlot clears that slot's queued swap"
  },
  {
    name = "gm_combat_queue_cast",
    shot = "combat_queue_cast",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    includeFrames = { "GM_ChangeMenu", "PlayerCastingBarFrame", "CastingBarFrame" },
    hideChrome = true,
    padding = 250,
    shows = "Switching while casting queues the swap; it fires when the cast completes - and immediately if the cast is cancelled"
  },
  {
    name = "gm_quick_change_add_rule",
    shot = "quick_change_add_rule",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openCategory:quickChange" },
    hideFrames = { "GM_TrinketMenuFrame", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 100,
    shows = "QuickChange panel: picking a used-item and a switch-to item and adding a delayed rule"
  },
  {
    name = "gm_keybinding",
    shot = "keybinding",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openGearBarConfig" },
    includeFrames = { "GM_GearBarFrame_1" },
    hideFrames = { "GM_TrinketMenuFrame", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 250,
    shows = "Binding a key to a gearSlot in the per-bar slot configuration and using it in the world"
  },
  {
    name = "gm_drag_and_drop_slots",
    shot = "drag_and_drop_slots",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    hideChrome = true,
    padding = 400,
    shows = "Dragging an item from one gearSlot to another swaps the two slots"
  },
  {
    name = "gm_drag_and_drop_equip",
    shot = "drag_and_drop_equip",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    includeFrames = { "ContainerFrameCombinedBags", "ContainerFrame1", "ContainerFrame2", "ContainerFrame3", "ContainerFrame4", "ContainerFrame5" },
    hideChrome = true,
    padding = 150,
    shows = "Dragging an item out of a bag onto a gearSlot equips it"
  },
  {
    name = "gm_drag_and_drop_unequip",
    shot = "drag_and_drop_unequip",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    includeFrames = { "ContainerFrameCombinedBags", "ContainerFrame1", "ContainerFrame2", "ContainerFrame3", "ContainerFrame4", "ContainerFrame5" },
    hideChrome = true,
    padding = 150,
    shows = "Dragging an item off a gearSlot into a bag unequips it"
  },
  {
    name = "gm_combined_equip",
    shot = "combined_equip",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 250,
    shows = "Right-click on a changeMenu item of a combined slot equips into the opposite slot (trinket pair)"
  },
  {
    name = "gm_unequip",
    shot = "unequip",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 250,
    shows = "The empty changeMenu slot unequips the hovered gearSlot"
  },
  {
    name = "gm_trinketmenu_demo",
    shot = "trinketmenu_demo",
    frame = "GM_TrinketMenuFrame",
    kind = "gif",
    setup = {},
    includeFrames = { "GM_GearBarFrame_1" },
    hideChrome = true,
    padding = 150,
    shows = "TrinketMenu with all trinkets and cooldowns in view; left/right click equips upper/lower slot"
  },
  {
    name = "gm_rune_support",
    shot = "rune_support",
    frame = "GM_GearBarFrame_1",
    kind = "gif",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 250,
    shows = "Season of Discovery rune icons overlaid on changeMenu items"
  },
  {
    name = "gm_create_gearbar",
    shot = "create_gearbar",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openCategory:gearBar" },
    hideFrames = { "GM_TrinketMenuFrame", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 200,
    shows = "Creating a second gearBar from the GearBar configuration panel"
  },
  {
    name = "gm_configure_gearslots",
    shot = "configure_gearslots",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openGearBarConfig" },
    includeFrames = { "GM_GearBarFrame_1" },
    hideFrames = { "GM_TrinketMenuFrame", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 150,
    shows = "Per-bar slot configuration: adding gearSlots to a bar via the slot list"
  },
  {
    name = "gm_options_cooldowns",
    shot = "options_cooldowns",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openGearBarConfig" },
    includeFrames = { "GM_GearBarFrame_1" },
    hideFrames = { "GM_TrinketMenuFrame", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 250,
    shows = "Per-bar cooldown visibility toggle and the bar reacting"
  },
  {
    name = "gm_options_keybindings",
    shot = "options_keybindings",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openGearBarConfig" },
    includeFrames = { "GM_GearBarFrame_1" },
    hideFrames = { "GM_TrinketMenuFrame", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 250,
    shows = "Per-bar keybinding visibility toggle and the bar reacting"
  },
  {
    name = "gm_options_lock_window",
    shot = "options_lock_window",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openGearBarConfig" },
    includeFrames = { "GM_GearBarFrame_1" },
    hideFrames = { "GM_TrinketMenuFrame", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 250,
    shows = "Per-bar lock toggle and dragging the unlocked bar"
  },
  {
    name = "gm_options_slot_sizes",
    shot = "options_slot_sizes",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openGearBarConfig" },
    includeFrames = { "GM_GearBarFrame_1", "GM_ChangeMenu" },
    hideFrames = { "GM_TrinketMenuFrame", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 250,
    shows = "Per-bar size sliders: gearSlot size resizing the live bar, then changeMenu size resizing the hover menu"
  },
  {
    name = "gm_orientation_support",
    shot = "orientation_support",
    frame = "GM_GearBarFrame_1",
    setup = {},
    includeFrames = { "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 120,
    shows = "A horizontal and a vertical gearBar side by side in the world"
  },
  {
    name = "gm_vertical_and_horizontal_gearbar",
    shot = "vertical_and_horizontal_gearbar",
    frame = "GM_GearBarFrame_1",
    setup = {},
    includeFrames = { "GM_GearBarFrame_2", "GM_ChangeMenu" },
    hideChrome = true,
    padding = 150,
    shows = "ChangeMenu opening sideways from a vertical bar and up/down from a horizontal bar"
  },
  {
    name = "gm_options_filter_item_quality",
    shot = "options_filter_item_quality",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openCategory:general" },
    includeFrames = { "GM_GearBarFrame_1", "GM_ChangeMenu" },
    hideFrames = { "GM_TrinketMenuFrame", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 250,
    shows = "Options panel quality filter changing which items the changeMenu offers"
  },
  {
    name = "gm_theme_custom",
    shot = "theme_custom",
    frame = "GM_GearBarFrame_1",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 60,
    shows = "GearBar and changeMenu rendered in the Custom theme"
  },
  {
    name = "gm_theme_classic",
    shot = "theme_classic",
    frame = "GM_GearBarFrame_1",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 60,
    shows = "GearBar and changeMenu rendered in the Classic theme"
  },
  {
    name = "gm_trinketmenu_configuration",
    shot = "trinketmenu_configuration",
    frame = "SettingsPanel",
    kind = "gif",
    setup = { "openCategory:trinketMenu" },
    includeFrames = { "GM_TrinketMenuFrame" },
    hideFrames = { "GM_GearBarFrame_1", "GM_GearBarFrame_2" },
    hideChrome = true,
    padding = 150,
    shows = "TrinketMenu panel: enable, lock, cooldowns, column count and size options with the menu reacting"
  },
  {
    name = "gm_profile_configuration",
    shot = "profile_panel",
    frame = "SettingsPanel",
    setup = { "openCategory:profile" },
    hideFrames = { "GM_GearBarFrame_1", "GM_GearBarFrame_2", "GM_TrinketMenuFrame" },
    hideChrome = true,
    padding = 0,
    shows = "Profiles panel with the named-profile list (immutable Default entry), management buttons and the export/import string box"
  },
  {
    name = "gm_switch_items_still",
    shot = "switch_items_still",
    frame = "GM_GearBarFrame_1",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 200,
    shows = "Static bar-plus-changeMenu scene used as the store gallery Item Switching tile"
  },
  {
    name = "gm_combat_queue_still",
    shot = "combat_queue_still",
    frame = "GM_GearBarFrame_1",
    setup = {},
    includeFrames = { "GM_ChangeMenu" },
    hideChrome = true,
    padding = 200,
    shows = "Static combat scene with a queued swap badge, the store gallery CombatQueue tile"
  },
  {
    name = "gm_trinket_menu_still",
    shot = "trinket_menu_still",
    frame = "GM_TrinketMenuFrame",
    setup = {},
    hideChrome = true,
    padding = 200,
    shows = "Static TrinketMenu scene, the store gallery TrinketMenu tile"
  },
  {
    name = "gm_configuration_still",
    shot = "configuration_still",
    frame = "SettingsPanel",
    setup = { "openGearBarConfig" },
    hideFrames = { "GM_GearBarFrame_1", "GM_GearBarFrame_2", "GM_TrinketMenuFrame" },
    hideChrome = true,
    padding = 0,
    shows = "Static per-bar configuration panel, the store gallery Configuration tile"
  }
}
