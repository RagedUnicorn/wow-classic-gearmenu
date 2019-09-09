
-- luacheck: globals GetAddOnMetadata

if (GetLocale() == "zhTW") then
	rggm = rggm or {}
	rggm.L = {}

	rggm.L["addon_name"] = "GearMenu"

	-- console
	rggm.L["help"] = "|cFFFFC300(%s)|r：使用 |cFFFFC300/rggm|r 或 |cFFFFC300/gearmenu|r列出指令選項"
	rggm.L["opt"] = "|cFFFFC300opt|r - 顯示選項"
	rggm.L["reload"] = "|cFFFFC300reload|r - 重載介面"
	rggm.L["info_title"] = "|cFF00FFB0GearMenu:|r"
	rggm.L["invalid_argument"] = "無效參數"

	-- about
	rggm.L["author"] = "作者：Michael Wiesendanger"
	rggm.L["email"] = "電子信箱：michael.wiesendanger@gmail.com"
	rggm.L["version"] = "版本：" .. GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")
	rggm.L["issues"] = "提問：https://github.com/RagedUnicorn/wow-classic-gearmenu/issues"

	-- general
	rggm.L["general_category_name"] = "一般"
	rggm.L["general_title"] = "一般選項"
	rggm.L["window_lock_gear_bar"] = "鎖定裝備列"
	rggm.L["window_lock_gear_bar_tooltip"] = "防止裝備列被拖動。"
	rggm.L["show_keybindings"] = "顯示按鍵綁定"
	rggm.L["show_keybindings_tooltip"] = "在裝備列上顯示綁定的快捷鍵。"
	rggm.L["show_cooldowns"] = "顯示冷卻時間"
	rggm.L["show_cooldowns_tooltip"] = "在所有裝備槽上顯示換裝冷卻時間。"
	rggm.L["enable_tooltips"] = "啟用滑鼠提示"
	rggm.L["enable_tooltips_tooltip"] = "滑鼠指向裝備條上的物品時，顯示詳細的滑鼠提示。"
	rggm.L["enable_simple_tooltips"] = "顯示簡易提示"
	rggm.L["enable_simple_tooltips_tooltip"] = "滑鼠指向裝備條上的物品時，只顯示物品標題或名字。"

	rggm.L["enable_drag_and_drop"] = "啟用拖動"
	rggm.L["enable_drag_and_drop_tooltip"] = "可以直接拖動物品，將之加入或移出裝備條。"
	rggm.L["filter_item_quality"] = "過濾物品品質："
	rggm.L["item_quality_poor"] = "|cff9d9d9d"..ITEM_QUALITY0_DESC.."|r"
	rggm.L["item_quality_common"] = "|cffffffff"..ITEM_QUALITY1_DESC.."|r"
	rggm.L["item_quality_uncommon"] = "|cff1eff00"..ITEM_QUALITY2_DESC.."|r"
	rggm.L["item_quality_rare"] = "|cff0070dd"..ITEM_QUALITY3_DESC.."|r"
	rggm.L["item_quality_epic"] = "|cffa335ee"..ITEM_QUALITY4_DESC.."|r"
	rggm.L["item_quality_legendary"] = "|cffff8000"..ITEM_QUALITY5_DESC.."|r"

	-- gearslots
	rggm.L["gearslot_category_name"] = "裝備格子"
	for i = 1, 17, 1 do 
		rggm.L["titleslot_"..i] = "第"..i.."格："
	end
	
	-- quickchange
	rggm.L["quick_change_category_name"] = "快速換裝"
	rggm.L["quick_change_slider_title"] = "推遲秒數"
	rggm.L["quick_change_slider_tooltip"] = "設定快速換裝的延時規則。"
	  .. "對於給予特效的物品來說，推持的秒數通常設為特效的持續時間。"
	rggm.L["quick_change_slider_unit"] = SECONDS
	rggm.L["quick_change_add_rule"] = ADD
	rggm.L["quick_change_remove_rule"] = REMOVE
	rggm.L["quick_change_invalid_rule"] = "不能切換同一物品，要脫下和要穿上的裝備必需是不同的。"
	rggm.L["quick_change_unable_to_remove_rule"] = "無法移除規則 - 請先選定你要移除的規則"
	rggm.L["quick_change_unable_to_add_rule_from"] = "無法添加規則 - 缺少「來源」物品，你要指定一個要脫下的裝備"
	rggm.L["quick_change_unable_to_add_rule_to"] = "無法添加規則 - 缺少「目標」物品，你要指定一個要穿上的裝備"
	rggm.L["quick_change_unable_to_add_rule_duplicate"] = "無法添加新規則 - 這個物品的換裝規則已經存在"

	-- missing
	rggm.L["EquipItem: "] = "裝備物品："
	rggm.L[" in slot: "] = " 至欄位："
	rggm.L["Was unable to switch because the item to switch to could not be found"] = "無法切換，因為找不到要切換的裝備。"
	rggm.L["Filtered duplicate item - "] = "過濾重覆項目 - "
	rggm.L[" - from item list"] = " - 自物品清單中"
	rggm.L["Skipped item: "] = "跳過物品："
	rggm.L[" because it has no onUse effect"] = "，因為他沒有使用特效。"
	rggm.L["Ignoring item because its quality is lower than setting "] = "忽略這個物品，因為它的品質太差，預設"
	
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