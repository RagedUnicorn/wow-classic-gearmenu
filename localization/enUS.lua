
-- luacheck: globals GetAddOnMetadata

rggm = rggm or {}
rggm.L = {}

rggm.L["addon_name"] = "GearMenu"

-- console
rggm.L["help"] = "|cFFFFC300(%s)|r: Use |cFFFFC300/rggm|r or |cFFFFC300/gearmenu|r for a list of options"
rggm.L["opt"] = "|cFFFFC300opt|r - display Optionsmenu"
rggm.L["reload"] = "|cFFFFC300reload|r - reload UI"
rggm.L["info_title"] = "|cFF00FFB0GearMenu:|r"
rggm.L["invalid_argument"] = "Invalid argument passed"

-- about
rggm.L["author"] = "Author: Michael Wiesendanger"
rggm.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
rggm.L["version"] = "Version: " .. GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")
rggm.L["issues"] = "Issues: https://github.com/RagedUnicorn/wow-classic-gearmenu/issues"

-- general
rggm.L["general_category_name"] = "General"
rggm.L["general_title"] = "General Configuration"
rggm.L["window_lock_gear_bar"] = "Lock GearBar"
rggm.L["window_lock_gear_bar_tooltip"] = "Prevents GearBar frame from being moved"
rggm.L["show_keybindings"] = "Show Key Bindings"
rggm.L["show_keybindings_tooltip"] = "Display the key bindings over the equipped items"
rggm.L["show_cooldowns"] = "Show Cooldowns"
rggm.L["show_cooldowns_tooltip"] = "Display a cooldown for all itemslots"
rggm.L["enable_tooltips"] = "Enable Tooltips"
rggm.L["enable_tooltips_tooltip"] = "Whether to show a tooltip when hovering an item or not"
rggm.L["enable_simple_tooltips"] = "Display simple Tooltips"
rggm.L["enable_simple_tooltips_tooltip"] = "Show only the title of the item that is currently hovered "
  .. "instead of the full tooltip"
rggm.L["enable_drag_and_drop"] = "Enable Drag and Drop"
rggm.L["enable_drag_and_drop_tooltip"] = "Enable Drag and Drop for items"
rggm.L["filter_item_quality"] = "Filter Item Quality:"
rggm.L["item_quality_poor"] = "|cff9d9d9d"..ITEM_QUALITY0_DESC.."|r"
rggm.L["item_quality_common"] = "|cffffffff"..ITEM_QUALITY1_DESC.."|r"
rggm.L["item_quality_uncommon"] = "|cff1eff00"..ITEM_QUALITY2_DESC.."|r"
rggm.L["item_quality_rare"] = "|cff0070dd"..ITEM_QUALITY3_DESC.."|r"
rggm.L["item_quality_epic"] = "|cffa335ee"..ITEM_QUALITY4_DESC.."|r"
rggm.L["item_quality_legendary"] = "|cffff8000"..ITEM_QUALITY5_DESC.."|r"

-- gearslots
rggm.L["gearslot_category_name"] = "Gearslots"
for i = 1, 17, 1 do 
	rggm.L["titleslot_"..i] = "Slot "..i..":"
end

-- quickchange
rggm.L["quick_change_category_name"] = "Quickchange"
rggm.L["quick_change_slider_title"] = "Delay in seconds"
rggm.L["quick_change_slider_tooltip"] = "Set a delay for when the Quickchange rule should actually take place. "
  .. "For items that give a buff the delay should usually be set to the duration of the buff"
rggm.L["quick_change_slider_unit"] = "seconds"
rggm.L["quick_change_add_rule"] = "Add"
rggm.L["quick_change_remove_rule"] = "Remove"
rggm.L["quick_change_invalid_rule"] = "The item from and the item to switch to cannot be the same"
rggm.L["quick_change_unable_to_remove_rule"] = "Unable to remove rule - Please select a rule you want to remove first"
rggm.L["quick_change_unable_to_add_rule_from"] = "Unable to add new rule - missing a 'From' item"
rggm.L["quick_change_unable_to_add_rule_to"] = "Unable to add new rule - missing a 'To' item"
rggm.L["quick_change_unable_to_add_rule_duplicate"] = "Unable to add new rule - A rule for this item already exists"

-- missing
rggm.L["EquipItem: "] = "EquipItem: "
rggm.L[" in slot: "] = " in slot: "
rggm.L["Was unable to switch because the item to switch to could not be found"] = "Was unable to switch because the item to switch to could not be found"
rggm.L["Filtered duplicate item - "] = "Filtered duplicate item - "
rggm.L[" - from item list"] = " - from item list"
rggm.L["Skipped item: "] = "Skipped item: "
rggm.L[" because it has no onUse effect"] = " because it has no onUse effect"
rggm.L["Ignoring item because its quality is lower than setting "] = "Ignoring item because its quality is lower than setting "

-- slot translations
rggm.L["slot_name_head"] = "Head"
rggm.L["slot_name_neck"] = "Neck"
rggm.L["slot_name_shoulders"] = "Shoulders"
rggm.L["slot_name_chest"] = "Chest"
rggm.L["slot_name_waist"] = "Waist"
rggm.L["slot_name_legs"] = "Legs"
rggm.L["slot_name_feet"] = "Feet"
rggm.L["slot_name_wrist"] = "Wrist"
rggm.L["slot_name_hands"] = "Hands"
rggm.L["slot_name_upper_finger"] = "Upper Finger"
rggm.L["slot_name_lower_finger"] = "Lower Finger"
rggm.L["slot_name_finger"] = "Finger"
rggm.L["slot_name_upper_trinket"] = "Upper Trinket"
rggm.L["slot_name_lower_trinket"] = "Lower Trinket"
rggm.L["slot_name_trinket"] = "Trinket"
rggm.L["slot_name_back"] = "Cloak"
rggm.L["slot_name_main_hand"] = "MainHand"
rggm.L["slot_name_off_hand"] = "OffHand"
rggm.L["slot_name_ranged"] = "Ranged"
