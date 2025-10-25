
-- luacheck: globals GetAddOnMetadata
-- Translator ZamestoTV
if (GetLocale() == "ruRU") then
  rggm = rggm or {}
  rggm.L = {}

  rggm.L["addon_name"] = "GearMenu"

  -- console
  rggm.L["help"] = "|cFFFFC300(%s)|r: используйте |cFFFFC300/rggm|r или |cFFFFC300/gearmenu|r для списка команд"
  rggm.L["opt"] = "|cFFFFC300opt|r - открыть меню настроек"
  rggm.L["reload"] = "|cFFFFC300reload|r - перезагрузить интерфейс"
  rggm.L["info_title"] = "|cFF00FFB0GearMenu:|r"
  rggm.L["invalid_argument"] = "Передан неверный аргумент"

  -- about
  rggm.L["author"] = "Автор: Michael Wiesendanger"
  rggm.L["email"] = "E-Mail: michael.wiesendanger@gmail.com"
  rggm.L["version"] = "Версия: " .. GetAddOnMetadata(RGGM_CONSTANTS.ADDON_NAME, "Version")
  rggm.L["issues"] = "Баги: https://github.com/RagedUnicorn/wow-classic-gearmenu/issues"

  -- general
  rggm.L["general_category_name"] = "Общие"
  rggm.L["general_title"] = "Общие настройки"
  rggm.L["enable_tooltips"] = "Включить подсказки"
  rggm.L["enable_tooltips_tooltip"] = "Показывать подсказку при наведении на предмет"
  rggm.L["enable_simple_tooltips"] = "Простые подсказки"
  rggm.L["enable_simple_tooltips_tooltip"] = "Показывать только название предмета"
    .. " вместо полной подсказки"
  rggm.L["enable_fast_press"] = "Включить быстрый отклик"
  rggm.L["enable_fast_press_tooltip"] = "Действие срабатывает при нажатии клавиши, а не при её отпускании"
  rggm.L["enable_drag_and_drop"] = "Включить перетаскивание"
  rggm.L["enable_drag_and_drop_tooltip"] = "Разрешить перетаскивание предметов"
  rggm.L["enable_unequip_slot"] = "Включить слот снятия"
  rggm.L["enable_unequip_slot_tooltip"] = "Добавляет пустой слот в меню смены экипировки"
    .. " для быстрого снятия предметов"
  rggm.L["enable_rune_slots"] = "Включить слоты рун"
  rggm.L["enable_rune_slots_tooltip"] = "Показывать слоты рун в панели экипировки"
  rggm.L["filter_item_quality"] = "Фильтр качества предметов:"
  rggm.L["item_quality_poor"] = "Хлам (Серый)"
  rggm.L["item_quality_common"] = "Обычное (Белое)"
  rggm.L["item_quality_uncommon"] = "Необычное (Зелёное)"
  rggm.L["item_quality_rare"] = "Редкое (Синее)"
  rggm.L["item_quality_epic"] = "Эпическое (Фиолетовое)"
  rggm.L["item_quality_legendary"] = "Легендарное (Оранжевое)"
  rggm.L["choose_theme"] = "Выберите тему:"
  rggm.L["theme_classic"] = "Классическая"
  rggm.L["theme_custom"] = "Пользовательская"
  rggm.L["theme_change_confirmation"] = "Будет перезагружен интерфейс. Продолжить?"
  rggm.L["theme_change_confirmation_yes"] = "Да"
  rggm.L["theme_change_confirmation_no"] = "Нет"

  -- trinketMenu
  rggm.L["trinket_menu_category_name"] = "Меню Аксессуаров"
  rggm.L["trinket_menu_title"] = "Настройки Меню Аксессуаров"
  rggm.L["enable_trinket_menu"] = "Включить Меню Аксессуаров"
  rggm.L["enable_trinket_menu_tooltip"] = "Показывать/скрывать Меню Аксессуаров"
  rggm.L["window_lock_trinket_menu"] = "Зафиксировать Меню Аксессуаров"
  rggm.L["window_lock_trinket_menu_tooltip"] = "Запрещает перемещение окна Меню Аксессуаров"
  rggm.L["shoow_cooldowns_trinket_menu"] = "Показывать кулдауны"
  rggm.L["shoow_cooldowns_trinket_menu_tooltip"] = "Отображать кулдаун для всех слотов"
  rggm.L["trinket_menu_column_amount_slider_title"] = "Колонки"
  rggm.L["trinket_menu_column_amount_slider_tooltip"] = "Количество колонок в Меню Аксессуаров"
  rggm.L["trinket_menu_slot_size_slider_title"] = "Размер слота"
  rggm.L["trinket_menu_slot_size_slider_tooltip"] = "Размер ячейки в Меню Аксессуаров"

  -- quickchange
  rggm.L["quick_change_category_name"] = "Быстрая смена"
  rggm.L["quick_change_title"] = "Быстрая смена"
  rggm.L["quick_change_slider_title"] = "Задержка в секундах"
  rggm.L["quick_change_slider_tooltip"] = "Установить задержку, после которой сработает правило Быстрой смены. "
    .. "Для предметов с баффом задержка обычно равна длительности баффа"
  rggm.L["quick_change_slider_unit"] = "секунд"
  rggm.L["quick_change_add_rule"] = "Добавить"
  rggm.L["quick_change_remove_rule"] = "Удалить"
  rggm.L["quick_change_invalid_rule"] = "Предмет «от» и «к» не могут быть одинаковыми"
  rggm.L["quick_change_unable_to_remove_rule"] = "Не удалось удалить правило — сначала выберите правило"
  rggm.L["quick_change_unable_to_add_rule_from"] = "Не удалось добавить правило — не выбран предмет «от»"
  rggm.L["quick_change_unable_to_add_rule_to"] = "Не удалось добавить правило — не выбран предмет «к»"
  rggm.L["quick_change_unable_to_add_rule_duplicate"] = "Не удалось добавить правило — правило для этого предмета уже существует"

  -- slot translations
  rggm.L["slot_name_head"] = "Голова"
  rggm.L["slot_name_neck"] = "Шея"
  rggm.L["slot_name_shoulders"] = "Плечи"
  rggm.L["slot_name_chest"] = "Грудь"
  rggm.L["slot_name_waist"] = "Пояс"
  rggm.L["slot_name_legs"] = "Ноги"
  rggm.L["slot_name_feet"] = "Ступни"
  rggm.L["slot_name_wrist"] = "Запястья"
  rggm.L["slot_name_hands"] = "Кисти рук"
  rggm.L["slot_name_upper_finger"] = "Верхнее кольцо"
  rggm.L["slot_name_lower_finger"] = "Нижнее кольцо"
  rggm.L["slot_name_finger"] = "Кольцо"
  rggm.L["slot_name_upper_trinket"] = "Верхний аксессуар"
  rggm.L["slot_name_lower_trinket"] = "Нижний аксессуар"
  rggm.L["slot_name_trinket"] = "Аксессуар"
  rggm.L["slot_name_back"] = "Плащ"
  rggm.L["slot_name_main_hand"] = "Правая рука"
  rggm.L["slot_name_off_hand"] = "Левая рука"
  rggm.L["slot_name_ranged"] = "Дальний бой"
  rggm.L["slot_name_ammo"] = "Боеприпасы"

  -- gearbar
  rggm.L["gear_bar_configuration_category_name"] = "Панель экипировки"
  rggm.L["gear_bar_configuration_panel_text"] = "Конфигурация панели экипировки"
  rggm.L["gear_bar_configuration_add_gearbar"] = "Создать новую панель экипировки"
  rggm.L["gear_bar_choose_name"] = "Выберите имя для новой панели экипировки"
  rggm.L["gear_bar_choose_name_accept_button"] = "Принять"
  rggm.L["gear_bar_choose_name_cancel_button"] = "Отмена"
  rggm.L["gear_bar_remove_button"] = "Удалить панель экипировки"
  rggm.L["gear_bar_confirm_delete"] = "Вы действительно хотите удалить эту панель экипировки?"
  rggm.L["gear_bar_confirm_delete_yes_button"] = "Да"
  rggm.L["gear_bar_confirm_delete_no_button"] = "Нет"
  rggm.L["gear_bar_max_amount_of_gear_bars_reached"] =
    "Достигнут максимум из " .. RGGM_CONSTANTS.MAX_GEAR_BARS .. " панелей экипировки"

  -- gearbar options
  rggm.L["window_lock_gear_bar"] = "Заблокировать панель экипировки"
  rggm.L["window_lock_gear_bar_tooltip"] = "Запрещает перемещение рамки панели экипировки"
  rggm.L["show_keybindings"] = "Показать привязки клавиш"
  rggm.L["show_keybindings_tooltip"] = "Отображать привязки клавиш над надетыми предметами"
  rggm.L["show_cooldowns"] = "Показывать кулдауны"
  rggm.L["show_cooldowns_tooltip"] = "Отображать кулдаун для всех слотов предметов"
  rggm.L["gear_slot_size_slider_title"] = "Размер слота экипировки"
  rggm.L["gear_slot_size_slider_tooltip"] = "Изменить размер слотов экипировки"
  rggm.L["change_slot_size_slider_title"] = "Размер слота смены"
  rggm.L["change_slot_size_slider_tooltip"] = "Изменить размер слотов смены"
  rggm.L["gear_bar_max_amount_of_gear_slots_reached"] =
    "Достигнут максимум из " .. RGGM_CONSTANTS.MAX_GEAR_BAR_SLOTS .. " слотов панели экипировки"

  -- add/remove slots
  rggm.L["gear_bar_configuration_add_gearslot"] = "Добавить слот экипировки"
  rggm.L["gear_bar_configuration_remove_gearslot"] = "-"
  rggm.L["gear_bar_configuration_delete_gearbar"] = "Удалить панель экипировки"
  -- gearbar scrollmenu
  rggm.L["gear_bar_configuration_key_binding_button"] = "Установить/Снять привязку клавиши"
  rggm.L["gear_bar_configuration_key_binding_not_set"] = "Привязка не установлена"
  rggm.L["gear_bar_configuration_key_binding_dialog"] = "Установить привязку на: "
  rggm.L["gear_bar_configuration_key_binding_dialog_initial"] = "(нажмите клавишу для привязки или оставьте пустым для снятия)"
  rggm.L["gear_bar_configuration_key_binding_dialog_accept"] = "Принять"
  rggm.L["gear_bar_configuration_key_binding_dialog_cancel"] = "Отмена"
  rggm.L["gear_bar_configuration_key_binding_override_dialog"] = "Привязка уже используется. Перезаписать?"
  rggm.L["gear_bar_configuration_key_binding_dialog_override_yes"] = "Да"
  rggm.L["gear_bar_configuration_key_binding_dialog_override_no"] = "Нет"
  rggm.L["gear_bar_configuration_key_binding_user_error"] = "Не удалось установить новую привязку клавиши"

  -- macro bridge user errors
  rggm.L["unable_to_find_equipslot"] = "Не удается найти подходящий слот для itemId %s"
  rggm.L["unable_to_find_item"] = "Не удается найти информацию о предмете для itemId %s"
end
