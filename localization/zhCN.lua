
-- luacheck: globals GetAddOnMetadata

if (GetLocale() == "zhCN") then
	rggm = rggm or {}
	rggm.L = {}
	
	rggm.L["addon_name"] = "GearMenu"

	-- console
	rggm.L["help"] = "|cFFFFC300(%s)|r: 使用 |cFFFFC300/rggm|r or |cFFFFC300/gearmenu|r 获取可用设置"
	rggm.L["opt"] = "|cFFFFC300opt|r - 开启选项界面"
	rggm.L["reload"] = "|cFFFFC300reload|r - 重载界面"
	rggm.L["info_title"] = "|cFF00FFB0GearMenu:|r"
	rggm.L["invalid_argument"] = "无效的参数"

	-- about
	rggm.L["author"] = "作者: Michael Wiesendanger"
	rggm.L["email"] = "邮件: michael.wiesendanger@gmail.com"
	rggm.L["version"] = "版本: " .. GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")
	rggm.L["issues"] = "问题反馈: https://github.com/RagedUnicorn/wow-classic-gearmenu/issues"

	-- general
	rggm.L["general_category_name"] = "通用"
	rggm.L["general_title"] = "通用设置"
	rggm.L["window_lock_gear_bar"] = "锁定装备栏"
	rggm.L["window_lock_gear_bar_tooltip"] = "阻止装备栏框架被移动。"
	rggm.L["show_keybindings"] = "显示按键绑定"
	rggm.L["show_keybindings_tooltip"] = "在装备上显示按键绑定。"
	rggm.L["show_cooldowns"] = "显示 冷却时间"
	rggm.L["show_cooldowns_tooltip"] = "在所有物品槽中显示冷却时间。"
	rggm.L["enable_tooltips"] = "显示鼠标提示"
	rggm.L["enable_tooltips_tooltip"] = "当鼠标悬停在物品上显示详细提示。"
	rggm.L["enable_simple_tooltips"] = "显示简略提示信息"
	rggm.L["enable_simple_tooltips_tooltip"] = "只会显示当前鼠标悬停项目的标题，通常是物品的名称，"
	  .. "而不显示完整的提示。"
	rggm.L["enable_drag_and_drop"] = "启用拖拽"
	rggm.L["enable_drag_and_drop_tooltip"] = "为物品启用拖拽。"
	rggm.L["filter_item_quality"] = "根据物品品质筛选："
	rggm.L["item_quality_poor"] = "|cff9d9d9d"..ITEM_QUALITY0_DESC.."|r"
	rggm.L["item_quality_common"] = "|cffffffff"..ITEM_QUALITY1_DESC.."|r"
	rggm.L["item_quality_uncommon"] = "|cff1eff00"..ITEM_QUALITY2_DESC.."|r"
	rggm.L["item_quality_rare"] = "|cff0070dd"..ITEM_QUALITY3_DESC.."|r"
	rggm.L["item_quality_epic"] = "|cffa335ee"..ITEM_QUALITY4_DESC.."|r"
	rggm.L["item_quality_legendary"] = "|cffff8000"..ITEM_QUALITY5_DESC.."|r"

	-- gearslots
	rggm.L["gearslot_category_name"] = "装备槽"
	for i = 1, 17, 1 do 
		rggm.L["titleslot_"..i] = "第"..i.."格："
	end

	-- quickchange
	rggm.L["quick_change_category_name"] = "快速换装"
	rggm.L["quick_change_slider_title"] = "延迟（秒）"
	rggm.L["quick_change_slider_tooltip"] = "为快速换装的规则设置一定的延迟。"
	  .. "对于提供buff的物品，延迟通常是该buff的持续时间。"
	rggm.L["quick_change_slider_unit"] = SECONDS
	rggm.L["quick_change_add_rule"] = ADD
	rggm.L["quick_change_remove_rule"] = REMOVE
	rggm.L["quick_change_invalid_rule"] = "切换中的物品不能和需要切换的物品相同"
	rggm.L["quick_change_unable_to_remove_rule"] = "不能移除规则-首先请选择一个你要移除的规则"
	rggm.L["quick_change_unable_to_add_rule_from"] = "不能添加新的规则 - 缺少需要切换的物品"
	rggm.L["quick_change_unable_to_add_rule_to"] = "不能添加新的规则 - 缺少需要替换的物品"
	rggm.L["quick_change_unable_to_add_rule_duplicate"] = "不能添加新的规则 - 此物品的规则已经存在"

	-- slot translations
	rggm.L["slot_name_head"] = HEADSLOT
	rggm.L["slot_name_neck"] = NECKSLOT
	rggm.L["slot_name_shoulders"] = SHOULDERSLOT
	rggm.L["slot_name_chest"] = CHESTSLOT
	rggm.L["slot_name_waist"] = WAISTSLOT
	rggm.L["slot_name_legs"] = LEGSSLOT
	rggm.L["slot_name_feet"] = FEETSLOT
	rggm.L["slot_name_wrist"] = WRISTSLOT
	rggm.L["slot_name_hands"] = HANDSSLOT
	rggm.L["slot_name_upper_finger"] = FINGER0SLOT_UNIQUE
	rggm.L["slot_name_lower_finger"] = FINGER1SLOT_UNIQUE
	rggm.L["slot_name_finger"] = FINGER1SLOT
	rggm.L["slot_name_upper_trinket"] = TRINKET0SLOT_UNIQUE
	rggm.L["slot_name_lower_trinket"] = TRINKET1SLOT_UNIQUE
	rggm.L["slot_name_trinket"] = TRINKET1SLOT
	rggm.L["slot_name_back"] = BACKSLOT
	rggm.L["slot_name_main_hand"] = MAINHANDSLOT
	rggm.L["slot_name_off_hand"] = SECONDARYHANDSLOT
	rggm.L["slot_name_ranged"] = RANGEDSLOT
end