# Update

* Adding support for Season of Discovery runes. GearMenu will now display runes in its UI elements. This can be configured in the General Configuration.

**Note:** This is a breaking change for existing Macros that equip items.

The function changed to support the runeAbilityId

`/run GM_AddToCombatQueue(itemId, enchantId, runeAbilityId, slotId)`

If you had a previous macro that you want to adapt, and you don't care about a specific rune you can just pass '0' as a value

```
# old
/run GM_AddToCombatQueue(itemId, enchantId, slotId)
/run GM_AddToCombatQueue(179350, 0, 13)

# new
/run GM_AddToCombatQueue(itemId, enchantId, runeAbilityId, slotId)
/run GM_AddToCombatQueue(179350, 0, 0, 13)
```

# Fixes

* Fixed an issue where the TrinketMenu UI was being accessed before it was initialized. Fixes #102
* Add better safety checks when retrieving the cooldown of an item. Fixes #103
* Prevent GearMenu from forgetting its Keybinds visually.

# Fix 2.4.1

* Fix #105 - limit access to runeslot for Season of Discovery only
