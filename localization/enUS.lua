
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
rggm.L["enable_tooltips"] = "Enable Tooltips"
rggm.L["enable_tooltips_tooltip"] = "Whether to show a tooltip when hovering an item or not"
rggm.L["enable_simple_tooltips"] = "Display simple Tooltips"
rggm.L["enable_simple_tooltips_tooltip"] = "Show only the title of the item that is currently hovered "
  .. "instead of the full tooltip"
rggm.L["enable_fast_press"] = "Enable FastPress"
rggm.L["enable_fast_press_tooltip"] = "Enables actions to be triggered on a keypress down instead on keypress up"
rggm.L["enable_drag_and_drop"] = "Enable Drag and Drop"
rggm.L["enable_drag_and_drop_tooltip"] = "Enable Drag and Drop for items"
rggm.L["enable_unequip_slot"] = "Enable Unequip Slot"
rggm.L["enable_unequip_slot_tooltip"] = "Enables an empty slot to be added to the changeMenu."
  .. " This allows for easier unequipping of items"
rggm.L["filter_item_quality"] = "Filter Item Quality:"
rggm.L["item_quality_poor"] = "Poor (Grey)"
rggm.L["item_quality_common"] = "Common (White)"
rggm.L["item_quality_uncommon"] = "Uncommon (Green)"
rggm.L["item_quality_rare"] = "Rare (Blue)"
rggm.L["item_quality_epic"] = "Epic (Purple)"
rggm.L["item_quality_legendary"] = "Legendary (Orange)"
rggm.L["choose_theme"] = "Choose Theme:"
rggm.L["theme_classic"] = "Classic"
rggm.L["theme_custom"] = "Custom"
rggm.L["theme_change_confirmation"] = "This will reload your Interface. Do you want to proceed?"
rggm.L["theme_change_confirmation_yes"] = "Yes"
rggm.L["theme_change_confirmation_no"] = "No"

-- trinketMenu
rggm.L["trinket_menu_category_name"] = "TrinketMenu"
rggm.L["trinket_menu_title"] = "Trinket Menu Configuration"
rggm.L["enable_trinket_menu"] = "Enable TrinketMenu"
rggm.L["enable_trinket_menu_tooltip"] = "Whether to enable and show TrinketMenu or not"
rggm.L["window_lock_trinket_menu"] = "Lock TrinketMenu"
rggm.L["window_lock_trinket_menu_tooltip"] = "Prevents TrinketMenu frame from being moved"
rggm.L["shoow_cooldowns_trinket_menu"] = "Show Cooldowns"
rggm.L["shoow_cooldowns_trinket_menu_tooltip"] = "Display a cooldown for all itemslots"
rggm.L["trinket_menu_column_amount_slider_title"] = "Columns"
rggm.L["trinket_menu_column_amount_slider_tooltip"] = "The amount of columns to use in the TrinketMenu"
rggm.L["trinket_menu_slot_size_slider_title"] = "Slot Size"
rggm.L["trinket_menu_slot_size_slider_tooltip"] = "The size of a slot in the TrinketMenu"

-- quickchange
rggm.L["quick_change_category_name"] = "QuickChange"
rggm.L["quick_change_title"] = "QuickChange"
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
rggm.L["slot_name_ammo"] = "Ammo"

-- gearbar
rggm.L["gear_bar_configuration_category_name"] = "GearBar"
rggm.L["gear_bar_configuration_panel_text"] = "GearBar Configuration"
rggm.L["gear_bar_configuration_add_gearbar"] = "Create new GearBar"
rggm.L["gear_bar_choose_name"] = "Choose a name for the new GearBar"
rggm.L["gear_bar_choose_name_accept_button"] = "Accept"
rggm.L["gear_bar_choose_name_cancel_button"] = "Cancel"
rggm.L["gear_bar_remove_button"] = "Remove GearBar"
rggm.L["gear_bar_confirm_delete"] = "Do you really want to delete this GearBar?"
rggm.L["gear_bar_confirm_delete_yes_button"] = "Yes"
rggm.L["gear_bar_confirm_delete_no_button"] = "No"
rggm.L["gear_bar_max_amount_of_gear_bars_reached"] =
  "You reached the maximum amount of " .. RGGM_CONSTANTS.MAX_GEAR_BARS .. " GearBars"

-- gearbar options
rggm.L["window_lock_gear_bar"] = "Lock GearBar"
rggm.L["window_lock_gear_bar_tooltip"] = "Prevents GearBar frame from being moved"
rggm.L["show_keybindings"] = "Show Key Bindings"
rggm.L["show_keybindings_tooltip"] = "Display the key bindings over the equipped items"
rggm.L["show_cooldowns"] = "Show Cooldowns"
rggm.L["show_cooldowns_tooltip"] = "Display a cooldown for all itemslots"
rggm.L["gear_slot_size_slider_title"] = "Gearslot size"
rggm.L["gear_slot_size_slider_tooltip"] = "Modify the size of the Gearslots"
rggm.L["change_slot_size_slider_title"] = "Changeslot size"
rggm.L["change_slot_size_slider_tooltip"] = "Modify the size of the Changeslots"
rggm.L["gear_bar_max_amount_of_gear_slots_reached"] =
  "You reached the maximum amount of " .. RGGM_CONSTANTS.MAX_GEAR_BAR_SLOTS .. " GearBar Slots"

-- add/remove slots
rggm.L["gear_bar_configuration_add_gearslot"] = "Add Gearslot"
rggm.L["gear_bar_configuration_remove_gearslot"] = "-"
rggm.L["gear_bar_configuration_delete_gearbar"] = "Delete GearBar"
-- gearbar scrollmenu
rggm.L["gear_bar_configuration_key_binding_button"] = "Set/Unset Keybinding"
rggm.L["gear_bar_configuration_key_binding_not_set"] = "No Keybind Set"
rggm.L["gear_bar_configuration_key_binding_dialog"] = "Set Keybinding to: "
rggm.L["gear_bar_configuration_key_binding_dialog_initial"] = "(press keybind you want to use or leave empty to unbind)"
rggm.L["gear_bar_configuration_key_binding_dialog_accept"] = "Accept"
rggm.L["gear_bar_configuration_key_binding_dialog_cancel"] = "Cancel"
rggm.L["gear_bar_configuration_key_binding_override_dialog"] = "Keybind already in use. Do you want to override?"
rggm.L["gear_bar_configuration_key_binding_dialog_override_yes"] = "Yes"
rggm.L["gear_bar_configuration_key_binding_dialog_override_no"] = "No"
rggm.L["gear_bar_configuration_key_binding_user_error"] = "Failed to set new Keybinding"

-- macro bridge user errors
rggm.L["unable_to_find_equipslot"] = "Unable to find a matching slot for itemId %s"
rggm.L["unable_to_find_item"] = "Unable to find any itemInfo for itemId %s"
