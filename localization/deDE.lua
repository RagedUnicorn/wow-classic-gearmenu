
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
  rggm.L["enable_tooltips"] = "Aktiviere KurzInfo"
  rggm.L["enable_tooltips_tooltip"] = "Aktiviere Kurzinfo für markierte Items"
  rggm.L["enable_simple_tooltips"] = "Zeige simple Kurzinfo"
  rggm.L["enable_simple_tooltips_tooltip"] = "Zeige nur den Titel des markierten Items anstatt die ganze Kurzinfo"
  rggm.L["enable_drag_and_drop"] = "Aktiviere Drag and Drop"
  rggm.L["enable_drag_and_drop_tooltip"] = "Aktiviere Drag and Drop für Items"
  rggm.L["enable_fast_press"] = "Aktiviere Schnellklick"
  rggm.L["enable_fast_press_tooltip"] = "Aktiviert Aktionen beim drücken eines Knopfs anstatt beim loslassen des Knopfs"
  rggm.L["enable_unequip_slot"] = "Aktiviere Ausrüstung ausziehen Slot"
  rggm.L["enable_unequip_slot_tooltip"] = "Aktiviert einen leeren Slot im ChangeMenu."
    .. " Dies erlaubt es einfacher items auszuziehen"
  rggm.L["filter_item_quality"] = "Filtere Gegenstandsqualität:"
  rggm.L["item_quality_poor"] = "Arm (Grau)"
  rggm.L["item_quality_common"] = "Gewöhnlich (Weiss)"
  rggm.L["item_quality_uncommon"] = "Ungewöhnlich (Grün)"
  rggm.L["item_quality_rare"] = "Selten (Blau)"
  rggm.L["item_quality_epic"] = "Episch (Violet)"
  rggm.L["item_quality_legendary"] = "Legendär (Orange)"
  rggm.L["choose_theme"] = "Wähle Theme:"
  rggm.L["theme_classic"] = "Klassisch"
  rggm.L["theme_custom"] = "Angepasst"
  rggm.L["theme_change_confirmation"] = "Dies wird dein Interface neu laden. Willst du fortfahren?"
  rggm.L["theme_change_confirmation_yes"] = "Ja"
  rggm.L["theme_change_confirmation_no"] = "Nein"

  -- quickchange
  rggm.L["quick_change_category_name"] = "Schnellwechsel"
  rggm.L["quick_change_title"] = "Schnellwechsel"
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

  -- trinketMenu
  rggm.L["trinket_menu_category_name"] = "TrinketMenu"
  rggm.L["trinket_menu_title"] = "Trinket Menu Einstellungen"
  rggm.L["enable_trinket_menu"] = "Aktiviere TrinketMenu"
  rggm.L["enable_trinket_menu_tooltip"] = "Aktiviere oder deaktiviere die Anzeige des TrinketMenus"
  rggm.L["window_lock_trinket_menu"] = "Sperre TrinketMenu"
  rggm.L["window_lock_trinket_menu_tooltip"] = "Verhindert das verschieben des TrinketMenus"
  rggm.L["shoow_cooldowns_trinket_menu"] = "Zeige Abklingzeiten"
  rggm.L["shoow_cooldowns_trinket_menu_tooltip"] = "Aktiviere die Anzeige der Abklingzeiten"
  rggm.L["trinket_menu_column_amount_slider_title"] = "Spalten"
  rggm.L["trinket_menu_column_amount_slider_tooltip"] =
    "Anzahl Spalten die benutzt werden für die anzeige des TrinketMenus"
  rggm.L["trinket_menu_slot_size_slider_title"] = "Schmuckstückslot Grösse"
  rggm.L["trinket_menu_slot_size_slider_tooltip"] = "Konfiguriere die Grösse der Schmuckstückslots"

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

  -- gearbar
  rggm.L["gear_bar_configuration_category_name"] = "GearBar"
  rggm.L["gear_bar_configuration_panel_text"] = "GearBar Konfiguration"
  rggm.L["gear_bar_configuration_add_gearbar"] = "Erstelle neue GearBar"
  rggm.L["gear_bar_choose_name"] = "Wähle einen Namen für die neue GearBar"
  rggm.L["gear_bar_choose_name_accept_button"] = "Akzeptieren"
  rggm.L["gear_bar_choose_name_cancel_button"] = "Abbrechen"
  rggm.L["gear_bar_remove_button"] = "Entferne GearBar"
  rggm.L["gear_bar_confirm_delete"] = "Willst du diese GearBar wirklich löschen?"
  rggm.L["gear_bar_confirm_delete_yes_button"] = "Ja"
  rggm.L["gear_bar_confirm_delete_no_button"] = "Nein"
  rggm.L["gear_bar_max_amount_of_gear_bars_reached"] =
    "Du hast das maximum von " .. RGGM_CONSTANTS.MAX_GEAR_BARS .. " GearBars erreicht"

  -- gearbar options
  rggm.L["window_lock_gear_bar"] = "Sperre Ausrüstungsbalken"
  rggm.L["window_lock_gear_bar_tooltip"] = "Verhindert das bewegen des Ausrüstungsbalken"
  rggm.L["show_keybindings"] = "Zeige Tastaturkürzel an"
  rggm.L["show_keybindings_tooltip"] = "Zeige Tastaturkürzel auf den ausgerüsteten Items an"
  rggm.L["show_cooldowns"] = "Zeige Abklingzeiten an"
  rggm.L["show_cooldowns_tooltip"] = "Zeige Abklingzeiten für alle Slots an"
  rggm.L["gear_slot_size_slider_title"] = "Ausrüstungsslot Grösse"
  rggm.L["gear_slot_size_slider_tooltip"] = "Verändere die Grösse der Ausrüstungsslots"
  rggm.L["change_slot_size_slider_title"] = "Wechselslots Grösse"
  rggm.L["change_slot_size_slider_tooltip"] = "Verändere die Grösse der Wechselslots"
  rggm.L["gear_bar_max_amount_of_gear_slots_reached"] =
    "Du hast das maximum von " .. RGGM_CONSTANTS.MAX_GEAR_BAR_SLOTS .. " GearBar Slots erreicht"
  -- add/remove slots
  rggm.L["gear_bar_configuration_add_gearslot"] = "Erstelle Gearslot"
  rggm.L["gear_bar_configuration_remove_gearslot"] = "-"
  rggm.L["gear_bar_configuration_delete_gearbar"] = "Lösche GearBar"
  -- gearbar scrollmenu
  rggm.L["gear_bar_configuration_key_binding_button"] = "Erstelle/Entferne Kürzel"
  rggm.L["gear_bar_configuration_key_binding_not_set"] = "Kein Kürzel gesetzt"
  rggm.L["gear_bar_configuration_key_binding_dialog"] = "Setze Tastenkürzel zu: "
  rggm.L["gear_bar_configuration_key_binding_dialog_initial"] = "(drücke das Tastenkürzel das du verwenden willst "
    .. "oder lasse es leer um das Tastenkürzel zurückzusetzen)"
  rggm.L["gear_bar_configuration_key_binding_dialog_accept"] = "Akzeptieren"
  rggm.L["gear_bar_configuration_key_binding_dialog_cancel"] = "Abbrechen"
  rggm.L["gear_bar_configuration_key_binding_override_dialog"] = "Tastenkürzel wird bereits benutzt. "
    .. "Willst du es überschreiben?"
  rggm.L["gear_bar_configuration_key_binding_dialog_override_yes"] = "Ja"
  rggm.L["gear_bar_configuration_key_binding_dialog_override_no"] = "Nein"
  rggm.L["gear_bar_configuration_key_binding_user_error"] = "Setzen des neuen Tastenkürzels ist fehlgeschlagen"

  -- macro bridge user errors
  rggm.L["unable_to_find_equipslot"] = "Konnte keinen passenden slot für itemdId %s finden"
  rggm.L["unable_to_find_item"] = "Konnte keine Iteminformationen für itemId %s finden"
end
