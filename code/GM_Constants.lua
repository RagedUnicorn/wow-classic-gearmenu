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

-- luacheck: globals INVSLOT_HEAD

RGGM_CONSTANTS = {
  ADDON_NAME = "GearMenu",
  --[[
    Unit ids
  ]]--
  UNIT_ID_PLAYER = "player",
  UNIT_ID_TARGET = "target",
  MODIFIER_KEYS = { "LCTRL", "RCTRL", "LALT", "RALT", "LSHIFT", "RSHIFT" },
  MODIFIER_KEY_MAPPING = {
    ["LCTRL"] = "CTRL",
    ["RCTRL"] = "CTRL",
    ["LALT"] = "ALT",
    ["RALT"] = "ALT",
    ["LSHIFT"] = "SHIFT",
    ["RSHIFT"] = "SHIFT"
  },
  ITEMQUALITY = {
    poor = 0,
    common = 1,
    uncommon = 2,
    rare = 3,
    epic = 4,
    legendary = 5
  },
  INVSLOT_NONE = 99,
  --[[
    Highlight Frame Status colors
  ]]--
  HIGHLIGHT = {
    ["highlight"] = {1, 0.99, .47, 1},
    ["hover"] = {0.27, 0.4, 1, 1},
    ["remove"] = {1, 0.02, 0.22, 1}
  },
  --[[
    Update Intervals for tickers
  ]]--
  CHANGE_MENU_UPDATE_INTERVAL = 0.05,
  SLOT_COOLDOWN_UPDATE_INTERVAL = 0.1,
  COMBAT_QUEUE_UPDATE_INTERVAL = 0.1,
  RANGE_CHECK_UPDATE_INTERVAL = 0.1,
  --[[
    Addon configuration
  ]]--
  ELEMENT_ADDON_PANEL = "GM_AddonPanel",
  ELEMENT_TOOLTIP = "GameTooltip", -- default blizzard frames tooltip
  --[[
    GearBar
  ]]--
  ELEMENT_GEAR_BAR_BASE_FRAME_NAME = "GM_GearBarFrame_",
  ELEMENT_GEAR_BAR_SLOT = "$parentSlot_",
  ELEMENT_GEAR_BAR_COMBAT_QUEUE_SLOT = "$parent_CombatQueueSlot",
  ELEMENT_GEAR_BAR_SLOT_ICON_TEXTURE_NAME = "$parent_Icon",
  ELEMENT_GEAR_BAR_SLOT_COOLDOWN_FRAME = "$parent_Cooldown",
  GEAR_BAR_COMBAT_QUEUE_SLOT_SIZE_MODIFIER = .55,
  GEAR_BAR_SLOT_BORDER_MODIFIER = 0.075,
  GEAR_BAR_WIDTH_MARGIN = 10,
  GEAR_BAR_DEFAULT_SLOT_SIZE = 40,
  GEAR_BAR_SLOT_X = 0,
  GEAR_BAR_SLOT_Y = 0,
  --[[
    ChangeMenu
  ]]--
  ELEMENT_GEAR_BAR_CHANGE_FRAME = "GM_ChangeMenu",
  ELEMENT_GEAR_BAR_CHANGE_SLOT = "$parentSlot_",
  ELEMENT_GEAR_BAR_CHANGE_COOLDOWN_FRAME = "$parent_Cooldown",
  GEAR_BAR_CHANGE_DEFAULT_HEIGHT = 50,
  GEAR_BAR_CHANGE_ROW_AMOUNT = 2,
  GEAR_BAR_CHANGE_COOLDOWN_TEXT_MODIFIER = 0.375,
  GEAR_BAR_CHANGE_KEYBIND_TEXT_MODIFIER = .27,
  -- Amount of created slots. Rule: GEAR_BAR_CHANGE_SLOT_AMOUNT_ITEMS + 1 = GEAR_BAR_CHANGE_SLOT_AMOUNT
  GEAR_BAR_CHANGE_SLOT_AMOUNT = 41,
  -- Maximum amount of supported items
  GEAR_BAR_CHANGE_SLOT_AMOUNT_ITEMS = 40,
  --[[
    GearBar Configuration Menus
  ]]--
  ELEMENT_GEAR_BAR_CONFIG_GENERAL_OPTIONS_FRAME = "GM_GearBarConfigGeneralOptionsFrame",
  ELEMENT_GEAR_BAR_CONFIG_QUICK_CHANGE_FRAME = "GM_GearBarConfigQuickChangeFrame",
  ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_CONFIG_FRAME = "GM_GearBarConfigGearBarConfigFrame",
  ELEMENT_GEAR_BAR_CONFIG_GEAR_BAR_SUB_CONFIG_FRAME = "GM_GearBarConfigGearBarSubConfigFrame_",
  --[[
    Addon Configuration General Elements
  ]]--
  CHECK_OPTION_SIZE = 32,
  BUTTON_DEFAULT_PADDING = 20,
  BUTTON_DEFAULT_HEIGHT = 25,
  INTERFACE_PANEL_CONTENT_FRAME_WIDTH = 580,
  INTERFACE_PANEL_CONTENT_FRAME_HEIGHT = 552,
  --[[
    About Menu
  ]]--
  ELEMENT_ABOUT_LOGO = "GM_AboutLogo",
  ELEMENT_ABOUT_AUTHOR_FONT_STRING = "GM_AboutAuthor",
  ELEMENT_ABOUT_EMAIL_FONT_STRING = "GM_AboutEmail",
  ELEMENT_ABOUT_VERSION_FONT_STRING = "GM_AboutVersion",
  ELEMENT_ABOUT_ISSUES_FONT_STRING = "GM_AboutIssues",
  --[[
    General Menu
  ]]--
  ELEMENT_GENERAL_MENU = "GM_GeneralMenu",
  ELEMENT_GENERAL_MENU_TITLE = "$parentTitle",
  ELEMENT_GENERAL_OPT = "GM_Opt",
  ELEMENT_GENERAL_OPT_ENABLE_TOOLTIPS = "GM_OptEnableTooltips",
  ELEMENT_GENERAL_OPT_ENABLE_SIMPLE_TOOLTIPS = "GM_OptEnableSimpleTooltips",
  ELEMENT_GENERAL_OPT_ENABLE_DRAG_AND_DROP = "GM_OptEnableDragAndDrop",
  ELEMENT_GENERAL_OPT_ENABLE_FASTPRESS = "GM_OptEnableFastPress",
  ELEMENT_GENERAL_OPT_ENABLE_UNEQUIP_SLOT = "GM_OptEnableUnequipSlot",
  ELEMENT_GENERAL_OPT_FILTER_ITEM_QUALITY = "GM_OptFilterItemQuality",
  ELEMENT_GENERAL_LABEL_FILTER_ITEM_QUALITY = "GM_LabelFilterItemQuality",
  --[[
    QuickChange
  ]]--
  ELEMENT_QUICK_CHANGE_MENU = "GM_QuickChangeMenu",
  ELEMENT_QUICK_CHANGE_MENU_TITLE = "$parentTitle",
  ELEMENT_QUICK_CHANGE_MENU_INVENTORY_TYPE_DROPDOWN = "GM_QuickChangeMenuChooseCategory",
  QUICK_CHANGE_BUTTON_MARGIN = 15,
  --[[
    QuickChange Shared
  ]]--
  ELEMENT_QUICK_CHANGE_CONTENT_FRAME_ROW = "$parentRow",
  ELEMENT_QUICK_CHANGE_CONTENT_FRAME_HIGHLIGHT = "$parentHighlight",
  QUICK_CHANGE_MAX_ROWS = 5,
  QUICK_CHANGE_ROW_HEIGHT = 25,
  CATEGORY_DROPDOWN_DEFAULT_VALUE = INVSLOT_HEAD,
  --[[
    QuickChange Rule Frame
  ]]--
  ELEMENT_QUICK_CHANGE_RULES_SCROLL_FRAME = "$parentRulesScrollFrame",
  ELEMENT_QUICK_CHANGE_RULES_ROW = "$parentRow",
  ELEMENT_QUICK_CHANGE_RULES_ROW_HIGHLIGHT = "$parentHighlight",
  QUICK_CHANGE_RULES_CONTENT_FRAME_WIDTH = 560,
  --[[
    QuickChange Change From Frame
  ]]--
  ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME = "$parentFromScrollFrame",
  QUICK_CHANGE_FROM_CONTENT_FRAME_WIDTH = 280,
  QUICK_CHANGE_SIDE_FROM = "from",
  --[[
    QuickChange Change To Frame
  ]]--
  ELEMENT_QUICK_CHANGE_TO_SCROLL_FRAME = "$parentToScrollFrame",
  QUICK_CHANGE_TO_CONTENT_FRAME_WIDTH = 280,
  QUICK_CHANGE_SIDE_TO = "to",
  --[[
    QuickChange Delay Slider
  ]]--
  ELEMENT_QUICK_CHANGE_DELAY_SLIDER = "$parentDelaySlider",
  QUICK_CHANGE_DELAY_SLIDER_WIDTH = 450,
  QUICK_CHANGE_DELAY_SLIDER_HEIGHT = 20,
  -- delay between 0 and 120 seconds
  QUICK_CHANGE_DELAY_SLIDER_MIN = 0,
  QUICK_CHANGE_DELAY_SLIDER_MAX = 120,
  QUICK_CHANGE_DELAY_SLIDER_STEP = 1, -- 1 second per step
  --[[
    QuickChange Buttons
  ]]--
  ELEMENT_QUICK_CHANGE_ADD_RULE_BUTTON = "GM_QuickChangeAddRule",
  ELEMENT_QUICK_CHANGE_REMOVE_RULE_BUTTON = "GM_QuickChangeRemoveRule",
  --[[
    GearBar configuration menu
  ]]--
  ELEMENT_GEAR_BAR_CONFIGURATION_MENU = "GM_GearBarConfigurationMenu",
  ELEMENT_GEAR_BAR_CONFIGURATION_MENU_TITLE = "$parentTitle",
  ELEMENT_GEAR_BAR_CONFIGURATION_CREATE_BUTTON = "$parentCreateButton",
  ELEMENT_GEAR_BAR_LIST = "$parentGearBarList",
  ELEMENT_GEAR_BAR_ROW_FRAME = "GM_GearBarListRowFrame_",
  ELEMENT_GEAR_BAR_NAME_TEXT = "GM_GearBarNameText",
  ELEMENT_GEAR_BAR_REMOVE_BUTTON = "GM_GearBarRemoveButton",
  GEAR_BAR_LIST_WIDTH = 520,
  GEAR_BAR_LIST_MAX_ROWS = 6,
  GEAR_BAR_LIST_ROW_HEIGHT = 50,
  GEAR_BAR_LIST_NAME_TEXT_WIDTH = 300,
  GEAR_BAR_DEFAULT_NAME = "Default_GearBar",
  GEAR_BAR_NAME_MAX_LENGTH = 20,
  --[[
    GearBar Configuration Sub Menu
  ]]--
  ELEMENT_GEAR_BAR_CONFIGURATION_SUB_MENU = "GM_GearBarConfigurationSubMenu",
  ELEMENT_GEAR_BAR_CONFIGURATION_SUB_MENU_TITLE = "$parentTitle",
  ELEMENT_GEAR_BAR_CONFIGURATION_ADD_SLOT_BUTTON = "$parentAddSlotButton",
  ELEMENT_GEAR_BAR_CONFIGURATION_REMOVE_SLOT_BUTTON = "$parentRemoveSlotButton",
  ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_SCROLL_FRAME = "$parentScrollFrame",
  ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_ROW_FRAME = "GM_GearBarSlotConfigurationRowFrame_",
  ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_GEAR_SLOT_DROPDOWN = "GM_GearBarSlotConfigurationGearSlotDropdown_",
  ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_KEY_BINDING_BUTTON = "$parentKeyBindingButton_",
  ELEMENT_GEAR_BAR_CONFIGURATION_SLOTS_KEY_BINDING_TEXT = "$parentKeyBindingText",
  ELEMENT_GEAR_BAR_CONFIGURATION_OPT_TOOLTIP = "GM_GearBarConfigurationOptTooltip",
  ELEMENT_GEAR_BAR_CONFIGURATION_OPT_LOCK_GEAR_BAR = "GM_GearBarConfigurationOptTooltipLockGearBar",
  ELEMENT_GEAR_BAR_CONFIGURATION_OPT_SHOW_KEY_BINDINGS = "GM_GearBarConfigurationOptTooltipShowKeyBindings",
  ELEMENT_GEAR_BAR_CONFIGURATION_OPT_SHOW_COOLDOWNS = "GM_GearBarConfigurationOptTooltipShowCooldowns",
  ELEMENT_GEAR_BAR_CONFIGURATION_SIZE_SLIDER = "GM_GearBarSizeSlider",
  GEAR_BAR_CONFIGURATION_SLOTS_KEY_BINDING_TEXT_WIDTH = 150,
  GEAR_BAR_CONFIGURATION_SIZE_SLIDER_WIDTH = 450,
  GEAR_BAR_CONFIGURATION_SIZE_SLIDER_HEIGHT = 20,
  GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MIN = 24,
  GEAR_BAR_CONFIGURATION_SIZE_SLIDER_MAX = 64,
  GEAR_BAR_CONFIGURATION_SIZE_SLIDER_STEP = 1,
  GEAR_BAR_CONFIGURATION_SLOTS_LIST_WIDTH = 550,
  GEAR_BAR_CONFIGURATION_SLOTS_LIST_ROW_HEIGHT = 50,
  GEAR_BAR_CONFIGURATION_SLOTS_LIST_MAX_ROWS = 6,
  GEAR_BAR_DEFAULT_POSITION = {"CENTER", 0, 0},
  GEAR_BAR_CONFIGURATION_GEAR_SLOT_ICON_SIZE = 32,
  GEAR_BAR_GEAR_SLOT_DEFAULT_VALUE = INVSLOT_HEAD,
  --[[
    Integer - Can be the values 1 or 2. This value indicates whether the currently active key bindings
    set is account or character specific. One of following constants should be used when examining the return value:
      ACCOUNT_BINDINGS (1)
      CHARACTER_BINDINGS (2)
  ]]--
  GEAR_BAR_STORE_CHARACTER_BINDINGS  = 2,
}
