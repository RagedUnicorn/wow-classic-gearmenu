
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
  rggm.L["enable_fastpress"] = "Aktiviere Schnellklick"
  rggm.L["enable_fastpress_tooltip"] = "Aktiviert Aktionen beim drücken eines Knopfs anstatt beim loslassen des Knopfs"
  rggm.L["filter_item_quality"] = "Filtere Gegenstandsqualität:"
  rggm.L["item_quality_poor"] = "Arm (Grau)"
  rggm.L["item_quality_common"] = "Gewöhnlich (Weiss)"
  rggm.L["item_quality_uncommon"] = "Ungewöhnlich (Grün)"
  rggm.L["item_quality_rare"] = "Selten (Blau)"
  rggm.L["item_quality_epic"] = "Episch (Violet)"
  rggm.L["item_quality_legendary"] = "Legendär (Orange)"
  rggm.L["size_slider_title"] = "Ausrüstungsslot Grösse"
  rggm.L["size_slider_tooltip"] = "Verändere die Grösse der Ausrüstungsslots. Andere Elemente passen sich ebbenfalls "
    .. "an die Grösse des Ausrüstungsslots an"

  -- gearslots
  rggm.L["gearslot_category_name"] = "Ausrüstungsslots"
  rggm.L["titleslot_1"] = "Slot 1:"
  rggm.L["titleslot_2"] = "Slot 2:"
  rggm.L["titleslot_3"] = "Slot 3:"
  rggm.L["titleslot_4"] = "Slot 4:"
  rggm.L["titleslot_5"] = "Slot 5:"
  rggm.L["titleslot_6"] = "Slot 6:"
  rggm.L["titleslot_7"] = "Slot 7:"
  rggm.L["titleslot_8"] = "Slot 8:"
  rggm.L["titleslot_9"] = "Slot 9:"
  rggm.L["titleslot_10"] = "Slot 10:"
  rggm.L["titleslot_11"] = "Slot 11:"
  rggm.L["titleslot_12"] = "Slot 12:"
  rggm.L["titleslot_13"] = "Slot 13:"
  rggm.L["titleslot_14"] = "Slot 14:"
  rggm.L["titleslot_15"] = "Slot 15:"
  rggm.L["titleslot_16"] = "Slot 16:"
  rggm.L["titleslot_17"] = "Slot 17:"

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
  rggm.L["slot_name_ammo"] = "Munition"

  -- macro bridge user errors
  rggm.L["unable_to_find_equipslot"] = "Konnte keinen passenden slot für itemdId %s finden"
  rggm.L["unable_to_find_item"] = "Konnte keine Iteminformationen für itemId %s finden"
end
