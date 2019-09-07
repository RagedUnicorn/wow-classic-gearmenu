--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

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

-- luacheck: globals BINDING_HEADER_GEARMENU INVSLOT_HEAD

--[[
  Misc Variables
]]--
BINDING_HEADER_GEARMENU = "GearMenu"

_G["BINDING_NAME_CLICK GM_GearBarSlot_1:LeftButton"] = "Slot 1"
_G["BINDING_NAME_CLICK GM_GearBarSlot_2:LeftButton"] = "Slot 2"
_G["BINDING_NAME_CLICK GM_GearBarSlot_3:LeftButton"] = "Slot 3"
_G["BINDING_NAME_CLICK GM_GearBarSlot_4:LeftButton"] = "Slot 4"
_G["BINDING_NAME_CLICK GM_GearBarSlot_5:LeftButton"] = "Slot 5"
_G["BINDING_NAME_CLICK GM_GearBarSlot_6:LeftButton"] = "Slot 6"
_G["BINDING_NAME_CLICK GM_GearBarSlot_7:LeftButton"] = "Slot 7"
_G["BINDING_NAME_CLICK GM_GearBarSlot_8:LeftButton"] = "Slot 8"
_G["BINDING_NAME_CLICK GM_GearBarSlot_9:LeftButton"] = "Slot 9"
_G["BINDING_NAME_CLICK GM_GearBarSlot_10:LeftButton"] = "Slot 10"
_G["BINDING_NAME_CLICK GM_GearBarSlot_11:LeftButton"] = "Slot 11"
_G["BINDING_NAME_CLICK GM_GearBarSlot_12:LeftButton"] = "Slot 12"
_G["BINDING_NAME_CLICK GM_GearBarSlot_13:LeftButton"] = "Slot 13"
_G["BINDING_NAME_CLICK GM_GearBarSlot_14:LeftButton"] = "Slot 14"
_G["BINDING_NAME_CLICK GM_GearBarSlot_15:LeftButton"] = "Slot 15"
_G["BINDING_NAME_CLICK GM_GearBarSlot_16:LeftButton"] = "Slot 16"
_G["BINDING_NAME_CLICK GM_GearBarSlot_17:LeftButton"] = "Slot 17"

RGGM_CONSTANTS = {
  ADDON_NAME = "GearMenu",
  --[[
    Unit ids
  ]]--
  UNIT_ID_PLAYER = "player",
  ITEMQUALITY = {
    poor = 0,
    common = 1,
    uncommon = 2,
    rare = 3,
    epic = 4,
    legendary = 5
  },
  INVSLOT_NONE = 0,
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
  --[[
    Addon configuration
  ]]--
  ELEMENT_ADDON_PANEL = "GM_AddonPanel",
  ELEMENT_TOOLTIP = "GameTooltip", -- default blizzard frames tooltip
  --[[
    GearBar
  ]]--
  ELEMENT_GEAR_BAR_FRAME = "GM_GearBar",
  ELEMENT_GEAR_BAR_WIDTH = 680,
  ELEMENT_GEAR_BAR_WIDTH_MARGIN = 20,
  ELEMENT_GEAR_BAR_HEIGHT = 50,
  ELEMENT_GEAR_BAR_SLOT = "$parentSlot_",
  ELEMENT_GEAR_BAR_COMBAT_QUEUE_SLOT = "$parent_CombatQueueSlot",
  ELEMENT_GEAR_BAR_COMBAT_QUEUE_SLOT_SIZE = 22,
  ELEMENT_GEAR_BAR_SLOT_SIZE = 40,
  ELEMENT_GEAR_BAR_SLOT_X = 5,
  ELEMENT_GEAR_BAR_SLOT_Y = 0,
  ELEMENT_GEAR_BAR_SLOT_ICON_TEXTURE_NAME = "$parent_Icon",
  ELEMENT_GEAR_BAR_SLOT_COOLDOWN_FRAME = "$parent_Cooldown",
  ELEMENT_GEAR_BAR_SLOT_COOLDOWN_SIZE = 32,
  ELEMENT_GEAR_BAR_SLOT_AMOUNT = 17,
  --[[
    ChangeMenu
  ]]--
  ELEMENT_GEAR_BAR_CHANGE_FRAME = "GM_ChangeMenu",
  ELEMENT_GEAR_BAR_CHANGE_SLOT = "$parentSlot_",
  ELEMENT_GEAR_BAR_CHANGE_SLOT_SIZE = 40,
  ELEMENT_GEAR_BAR_CHANGE_WIDTH = 100,
  ELEMENT_GEAR_BAR_CHANGE_HEIGHT = 50,
  ELEMENT_GEAR_BAR_CHANGE_COOLDOWN_FRAME = "$parent_Cooldown",
  ELEMENT_GEAR_BAR_CHANGE_COOLDOWN_SIZE = 32,
  ELEMENT_GEAR_BAR_CHANGE_SLOT_AMOUNT = 10,
  --[[
    About
  ]]--
  ELEMENT_ABOUT_LOGO = "GM_AboutLogo",
  ELEMENT_ABOUT_AUTHOR_FONT_STRING = "GM_AboutAuthor",
  ELEMENT_ABOUT_EMAIL_FONT_STRING = "GM_AboutEmail",
  ELEMENT_ABOUT_VERSION_FONT_STRING = "GM_AboutVersion",
  ELEMENT_ABOUT_ISSUES_FONT_STRING = "GM_AboutIssues",
  --[[
    General
  ]]--
  ELEMENT_GENERAL_SUB_OPTION_FRAME = "GM_GeneralMenuOptionsFrame",
  ELEMENT_GENERAL_CHECK_OPTION_SIZE = 32,
  ELEMENT_GENERAL_OPT = "GM_Opt",
  ELEMENT_GENERAL_FRAME = "GM_GeneralFrame",
  ELEMENT_GENERAL_TITLE = "GM_GeneralTitle",
  ELEMENT_GENERAL_OPT_WINDOW_LOCK_GEAR_BAR = "GM_OptWindowLockGearBar",
  ELEMENT_GENERAL_OPT_SHOW_KEY_BINDINGS = "GM_OptShowKeyBindings",
  ELEMENT_GENERAL_OPT_SHOW_COOLDOWNS = "GM_OptShowCooldowns",
  ELEMENT_GENERAL_OPT_ENABLE_TOOLTIPS = "GM_OptEnableTooltips",
  ELEMENT_GENERAL_OPT_ENABLE_SIMPLE_TOOLTIPS = "GM_OptEnableSimpleTooltips",
  ELEMENT_GENERAL_OPT_ENABLE_DRAG_AND_DROP = "GM_OptEnableDragAndDrop",
  ELEMENT_GENERAL_OPT_FILTER_ITEM_QUALITY = "GM_OptFilterItemQuality",
  ELEMENT_GENERAL_LABEL_FILTER_ITEM_QUALITY = "GM_LabelFilterItemQuality",
  --[[
    GearSlots
  ]]--
  ELEMENT_GEAR_SLOTS_SUB_OPTION_FRAME = "GM_GearSlotsMenuOptionFrame",
  ELEMENT_GEAR_SLOT_OPT_SLOT_LABEL = "GM_GearSlotOptSlotLabel_",
  ELEMENT_GEAR_SLOT_OPT_SLOT = "GM_GearSlotOptSlot_",
  --[[
    QuickChange
  ]]--
  ELEMENT_QUICK_CHANGE_SUB_OPTION_FRAME = "GM_QuickChangeMenuOptionFrame",
  ELEMENT_QUICK_CHANGE_CHOOSE_INVENTORY_TYPE = "GM_QuickChangeChooseCategory",
  --[[
    QuickChange rule frame
  ]]--
  ELEMENT_QUICK_CHANGE_RULES_SCROLL_FRAME = "GM_QuickChangeRulesScrollFrame",
  ELEMENT_QUICK_CHANGE_RULES_SCROLL_FRAME_SLIDER = "GM_QuickChangeRulesScrollFrameSlider",
  ELEMENT_QUICK_CHANGE_RULES_CONTENT_FRAME = "GM_QuickChangeRulesContentFrame",
  ELEMENT_QUICK_CHANGE_RULES_CONTENT_FRAME_HEIGHT = 100,
  ELEMENT_QUICK_CHANGE_RULES_CONTENT_FRAME_WIDTH = 560,
  ELEMENT_QUICK_CHANGE_RULES_FRAME = "GM_QuickChangeRulesFrame_",
  ELEMENT_QUICK_CHANGE_RULES_ROW = "$parentRow",
  ELEMENT_QUICK_CHANGE_RULES_ROW_HIGHLIGHT = "$parentHighlight",
  ELEMENT_QUICK_CHANGE_RULES_FRAME_HEIGHT = 20,
  --[[
    QuickChange change from frame
  ]]--
  ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME = "GM_QuickChangeFromScrollFrame",
  ELEMENT_QUICK_CHANGE_FROM_SCROLL_FRAME_SLIDER = "GM_QuickChangeFromScrollFrameSlider",
  ELEMENT_QUICK_CHANGE_FROM_CONTENT_FRAME = "GM_QuickChangeFromContentFrame",
  ELEMENT_QUICK_CHANGE_FROM_CONTENT_FRAME_WIDTH = 280,

  --[[
    QuickChange change to frame
  ]]--
  ELEMENT_QUICK_CHANGE_TO_SCROLL_FRAME = "GM_QuickChangeToScrollFrame",
  ELEMENT_QUICK_CHANGE_TO_SCROLL_FRAME_SLIDER = "GM_QuickChangeToScrollFrameSlider",
  ELEMENT_QUICK_CHANGE_TO_CONTENT_FRAME = "GM_QuickChangeToContentFrame",
  ELEMENT_QUICK_CHANGE_TO_CONTENT_FRAME_WIDTH = 280,


  ELEMENT_QUICK_CHANGE_CONTENT_FRAME_ROW = "$parentRow",
  ELEMENT_QUICK_CHANGE_CONTENT_FRAME_HIGHLIGHT = "$parentHighlight",
  ELEMENT_QUICK_CHANGE_SCROLL_FRAME_SLIDER_STEP_SIZE = 10,
  ELEMENT_QUICK_CHANGE_MAX_ROWS = 5,
  ELEMENT_QUICK_CHANGE_ROW_HEIGHT = 25,
  CATEGORY_DROPDOWN_DEFAULT_VALUE = INVSLOT_HEAD,

  ELEMENT_QUICK_CHANGE_DELAY_SLIDER = "GM_QuickChangeDelaySlider",
  ELEMENT_QUICK_CHANGE_DELAY_SLIDER_WIDTH = 450,
  ELEMENT_QUICK_CHANGE_DELAY_SLIDER_HEIGHT = 20,
  -- delay between 0 and 120 seconds
  QUICK_CHANGE_DELAY_SLIDER_MIN = 0,
  QUICK_CHANGE_DELAY_SLIDER_MAX = 120,
  QUICK_CHANGE_DELAY_SLIDER_STEP = 1, -- 1 second per step

  QUICK_CHANGE_SIDE_FROM = "from",
  QUICK_CHANGE_SIDE_TO = "to",

  ELEMENT_QUICK_CHANGE_ADD_RULE_BUTTON = "GM_QuickChangeAddRule",
  ELEMENT_QUICK_CHANGE_REMOVE_RULE_BUTTON = "GM_QuickChangeRemoveRule",

  --[[
    Configuration values for scrollframe slider
    0 is all the way up
    100 is all the way down
  ]]--
  QUICK_CHANGE_CONFIG_SLIDER_MIN_VALUE = 0,
  QUICK_CHANGE_CONFIG_SLIDER_MAX_VALUE = 100,
}
