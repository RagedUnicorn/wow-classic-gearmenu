
-- luacheck: globals GetLocale GetAddOnMetadata

if (GetLocale() == "deDE") then
  rggm = rggm or {}
  rggm.L = {}

  rggm.L["addon_name"] = "GearMenu"

  -- console
  rggm.L["help"] = "|cFFFFC300(%s)|r: Benutze |cFFFFC300/rggm|r oder |cFFFFC300/gearmenu|r "
    .. "für eine Liste der verfügbaren Optionen"
  rggm.L["opt"] = "|cFFFFC300opt|r - zeige Optionsmenu an"
  rggm.L["reload"] = "|cFFFFC300reload|r - UI neu laden"
  rggm.L["info_title"] = "|cFF00FFB0GearMenu:|r"
  rggm.L["invalid_argument"] = "Ungültiges Argument übergeben"

  -- about tab
  rggm.L["author"] = "Autor: Michael Wiesendanger"
  rggm.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
  rggm.L["version"] = "Version: " .. GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")
  rggm.L["issues"] = "Probleme: https://github.com/RagedUnicorn/wow-classic-gearmenu/issues"

  -- general
  rggm.L["general_category_name"] = "Allgemein"
  rggm.L["general_title"] = "Allgemeine Konfiguration"
  rggm.L["window_lock_gear_bar"] = "Sperre Ausrüstungsbalken"
  rggm.L["window_lock_gear_bar_tooltip"] = "Verhindert das bewegen des Ausrüstungsbalken"
  rggm.L["show_keybindings"] = "Zeige Tastaturkürzel an"
  rggm.L["show_keybindings_tooltip"] = "Zeige Tastaturkürzel auf den ausgerüsteten Items an"
  rggm.L["show_cooldowns"] = "Zeige Abklingzeiten an"
  rggm.L["show_cooldowns_tooltip"] = "Zeige Abklingzeiten für alle Slots an"
  rggm.L["enable_tooltips"] = "Aktiviere KurzInfo"
  rggm.L["enable_tooltips_tooltip"] = "Aktiviere Kurzinfo für markierte Items"
  rggm.L["enable_simple_tooltips"] = "Zeige simple Kurzinfo"
  rggm.L["enable_simple_tooltips_tooltip"] = "Zeige nur den Titel des markierten Items anstatt die ganze Kurzinfo"
  rggm.L["enable_drag_and_drop"] = "Aktiviere Drag and Drop"
  rggm.L["enable_drag_and_drop_tooltip"] = "Aktiviere Drag and Drop für Items"
  rggm.L["filter_item_quality"] = "Filtere Gegenstandsqualität:"
  rggm.L["item_quality_poor"] = "|cff9d9d9d"..ITEM_QUALITY0_DESC.."|r"
  rggm.L["item_quality_common"] = "|cffffffff"..ITEM_QUALITY1_DESC.."|r"
  rggm.L["item_quality_uncommon"] = "|cff1eff00"..ITEM_QUALITY2_DESC.."|r"
  rggm.L["item_quality_rare"] = "|cff0070dd"..ITEM_QUALITY3_DESC.."|r"
  rggm.L["item_quality_epic"] = "|cffa335ee"..ITEM_QUALITY4_DESC.."|r"
  rggm.L["item_quality_legendary"] = "|cffff8000"..ITEM_QUALITY5_DESC.."|r"

  -- gearslots
  rggm.L["gearslot_category_name"] = "Ausrüstungsslots"
  for i = 1, 17, 1 do 
	rggm.L["titleslot_"..i] = "Slot "..i..":"
  end

  -- quickchange
  rggm.L["quick_change_category_name"] = "Schnellwechsel"
  rggm.L["quick_change_slider_title"] = "Verzögerung in Sekunde"
  rggm.L["quick_change_slider_tooltip"] = "Setzt eine Verzögerung wann eine Quickchange Regel "
    .. "angewendet werden sollte. Für Gegenstände welche einen Stärkungszauber auslösen sollte "
    .. "diese Verzögerung normalerweise der Dauer des Stärkungszaubers entsprechen."
  rggm.L["quick_change_slider_unit"] = "Sekunden"
  rggm.L["quick_change_add_rule"] = "Hinzufügen"
  rggm.L["quick_change_remove_rule"] = "Entfernen"
  rggm.L["quick_change_invalid_rule"] = "Der Gegenstand von dem gewechselt und der Gegenstand zu "
    .. "dem gewechselt werden soll, können nicht der gleiche Gegenstand sein"
  rggm.L["quick_change_unable_to_remove_rule"] = "Konnte Regel nicht entfernen - Bitte selektiere "
    .. "zuerst eine Regel welche entfernt werden soll"
  rggm.L["quick_change_unable_to_add_rule_from"] = "Konnte neue Regel nicht hinzufügen "
    .. "- Kein 'Von' Gegenstand ausgewählt"
  rggm.L["quick_change_unable_to_add_rule_to"] = "Konnte neue Regel nicht hinzufügen - Kein 'Zu' Gegenstand ausgewählt"
  rggm.L["quick_change_unable_to_add_rule_duplicate"] = "Konnte neue Regel nicht hinzufügen "
    .. "- Eine Regel für diesen Gegenstand existiert bereits"

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
  rggm.L["slot_name_head"] = "Kopf"
  rggm.L["slot_name_neck"] = "Hals"
  rggm.L["slot_name_shoulders"] = "Schultern"
  rggm.L["slot_name_chest"] = "Brust"
  rggm.L["slot_name_waist"] = "Taille"
  rggm.L["slot_name_legs"] = "Beine"
  rggm.L["slot_name_feet"] = "Füße"
  rggm.L["slot_name_wrist"] = "Handgelenke"
  rggm.L["slot_name_hands"] = "Hände"
  rggm.L["slot_name_upper_finger"] = "Oberer Finger"
  rggm.L["slot_name_lower_finger"] = "Unterer Finger"
  rggm.L["slot_name_finger"] = "Finger"
  rggm.L["slot_name_upper_trinket"] = "Oberer Schmuck"
  rggm.L["slot_name_lower_trinket"] = "Unterer Schmuck"
  rggm.L["slot_name_trinket"] = "Schmuck"
  rggm.L["slot_name_back"] = "Rücken"
  rggm.L["slot_name_main_hand"] = "Waffenhand"
  rggm.L["slot_name_off_hand"] = "Schildhand"
  rggm.L["slot_name_ranged"] = "Distanz"
end
