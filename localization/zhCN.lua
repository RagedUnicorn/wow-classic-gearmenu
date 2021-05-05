
-- luacheck: globals GetLocale GetAddOnMetadata

if (GetLocale() == "zhCN") then
  rggm = rggm or {}
  rggm.L = {}

  rggm.L["addon_name"] = "GearMenu"

-- console
  rggm.L["help"] = "|cFFFFC300(%s)|r: 输入 |cFFFFC300/rggm|r 或 |cFFFFC300/gearmenu|r 打开选项列表"
  rggm.L["opt"] = "|cFFFFC300opt|r - 显示设置菜单"
  rggm.L["reload"] = "|cFFFFC300reload|r - 重置UI"
  rggm.L["info_title"] = "|cFF00FFB0GearMenu:|r"
  rggm.L["invalid_argument"] = "参数无效"

-- about
  rggm.L["author"] = "Author: Michael Wiesendanger"
  rggm.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
  rggm.L["version"] = "Version: " .. GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")
  rggm.L["issues"] = "Issues: https://github.com/RagedUnicorn/wow-classic-gearmenu/issues"

-- general
  rggm.L["general_category_name"] = "一般"
  rggm.L["general_title"] = "一般配置"
  rggm.L["enable_tooltips"] = "鼠标提示"
  rggm.L["enable_tooltips_tooltip"] = "悬停物品时是否显示工具提示"
  rggm.L["enable_simple_tooltips"] = "简单鼠标提示"
  rggm.L["enable_simple_tooltips_tooltip"] = "仅显示当前悬停项的标题 而不是完整的工具提示"
  rggm.L["enable_fast_press"] = "启动快速按键"
  rggm.L["enable_fast_press_tooltip"] = "允许在按键下压时触发操作而不是在按键抬起时触发操作"
  rggm.L["enable_drag_and_drop"] = "启用可拖动"
  rggm.L["enable_drag_and_drop_tooltip"] = "启用可拖动物品"
  rggm.L["enable_unequip_slot"] = "启用取消装备插槽"
  rggm.L["enable_unequip_slot_tooltip"] = "允许将一个空插槽添加到changeMenu。这样可以更轻松地取消装备"
  rggm.L["filter_item_quality"] = "过滤物品品质:"
  rggm.L["item_quality_poor"] = "灰色"
  rggm.L["item_quality_common"] = "白色"
  rggm.L["item_quality_uncommon"] = "绿色"
  rggm.L["item_quality_rare"] = "蓝色"
  rggm.L["item_quality_epic"] = "紫色"
  rggm.L["item_quality_legendary"] = "橙色"

-- quickchange
  rggm.L["quick_change_category_name"] = "快速更换"
  rggm.L["quick_change_title"] = "快速更换"
  rggm.L["quick_change_slider_title"] = "延迟(秒)"
  rggm.L["quick_change_slider_tooltip"] = "为快速更换规则实际发生的时间设置延迟。 "
  .. "对于提供buff的物品，延迟通常应设置为buff的持续时间"
  rggm.L["quick_change_slider_unit"] = "秒"
  rggm.L["quick_change_add_rule"] = "添加"
  rggm.L["quick_change_remove_rule"] = "移除"
  rggm.L["quick_change_invalid_rule"] = "不能在相同物品间切换"
  rggm.L["quick_change_unable_to_remove_rule"] = "无法删除规则-请先选择要删除的规则"
  rggm.L["quick_change_unable_to_add_rule_from"] = "无法添加新规则-缺少“From”项"
  rggm.L["quick_change_unable_to_add_rule_to"] = "无法添加新规则-缺少'To'项"
  rggm.L["quick_change_unable_to_add_rule_duplicate"] = "无法添加新规则-此物品的规则已存在"

-- slot translations
  rggm.L["slot_name_head"] = "头"
  rggm.L["slot_name_neck"] = "项链"
  rggm.L["slot_name_shoulders"] = "肩膀"
  rggm.L["slot_name_chest"] = "胸"
  rggm.L["slot_name_waist"] = "腰"
  rggm.L["slot_name_legs"] = "腿"
  rggm.L["slot_name_feet"] = "脚"
  rggm.L["slot_name_wrist"] = "腕"
  rggm.L["slot_name_hands"] = "手"
  rggm.L["slot_name_upper_finger"] = "手指1"
  rggm.L["slot_name_lower_finger"] = "手指2"
  rggm.L["slot_name_finger"] = "手指"
  rggm.L["slot_name_upper_trinket"] = "饰品1"
  rggm.L["slot_name_lower_trinket"] = "饰品2"
  rggm.L["slot_name_trinket"] = "饰品"
  rggm.L["slot_name_back"] = "披风"
  rggm.L["slot_name_main_hand"] = "主手"
  rggm.L["slot_name_off_hand"] = "副手"
  rggm.L["slot_name_ranged"] = "远程"

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

  -- gearbar options
  rggm.L["window_lock_gear_bar"] = "锁定装备条"
  rggm.L["window_lock_gear_bar_tooltip"] = "防止装备条移动"
  rggm.L["show_keybindings"] = "显示快捷键"
  rggm.L["show_keybindings_tooltip"] = "显示装备物品上的按键绑定"
  rggm.L["show_cooldowns"] = "显示冷却计时"
  rggm.L["show_cooldowns_tooltip"] = "所有装备槽上显示冷却计时"
  rggm.L["gear_slot_size_slider_title"] = "Gearslot size"
  rggm.L["gear_slot_size_slider_tooltip"] = "Modify the size of the Gearslots"
  rggm.L["change_slot_size_slider_title"] = "Changeslot size"
  rggm.L["change_slot_size_slider_tooltip"] = "Modify the size of the Changeslots"

  -- add/remove slots
  rggm.L["gear_bar_configuration_add_gearslot"] = "Add Gearslot"
  rggm.L["gear_bar_configuration_remove_gearslot"] = "-"
  rggm.L["gear_bar_configuration_delete_gearbar"] = "Delete GearBar"
  -- gearbar scrollmenu
  rggm.L["gear_bar_configuration_key_binding_button"] = "Set/Unset Keybinding"
  rggm.L["gear_bar_configuration_key_binding_not_set"] = "No Keybind Set"
  rggm.L["gear_bar_configuration_key_binding_dialog"] = "Set Keybinding to: "
  rggm.L["gear_bar_configuration_key_binding_dialog_initial"] = "(press keybind you want to use or leave "
    .. "empty to unbind)"
  rggm.L["gear_bar_configuration_key_binding_dialog_accept"] = "Accept"
  rggm.L["gear_bar_configuration_key_binding_dialog_cancel"] = "Cancel"
  rggm.L["gear_bar_configuration_key_binding_override_dialog"] = "Keybind already in use. Do you want to override?"
  rggm.L["gear_bar_configuration_key_binding_dialog_override_yes"] = "Yes"
  rggm.L["gear_bar_configuration_key_binding_dialog_override_no"] = "No"
  rggm.L["gear_bar_configuration_key_binding_user_error"] = "Failed to set new Keybinding"

  -- macro bridge user errors
  rggm.L["unable_to_find_equipslot"] = "无法为物品Id找到匹配的槽位 %s"
  rggm.L["unable_to_find_item"] = "无法为物品Id找到指定的物品信息 %s"
end
