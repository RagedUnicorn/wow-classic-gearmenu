# New Features
* Add gear profiles to save, apply, rename and delete named snapshots of the addon configuration in a new Profiles settings category
* Add profile export and import via a portable checksummed profile string to share setups between characters
* Add chat notifications explaining why a gear swap failed (item not found, item locked, cursor busy, spell targeting, no bag space)
* Add a Fallback to Base Item option that equips a plain copy of an item when the exact enchanted or engraved copy cannot be found
* Add a public swap listener API (GM_RegisterSwapListener / GM_UnregisterSwapListener) notifying third-party addons and WeakAuras about queued, unqueued and completed swaps
* Queue gear swaps while affected by loss of control effects and execute them once control is regained
* Add an update notification when a newer GearMenu version is detected in your party, raid or guild

# Bug Fixes
* Fix GearSlot click handling on the modern UI engine
* Fix Season of Discovery rune ability reference in the GearBar
* Fix ChangeMenu behavior when the underlying GearBar is deleted
* Fix the settings panel not refreshing after deleting a GearBar
* Fix range check ticker cleanup when deleting a GearBar

# Refactoring and Improvements
* Improve swap performance with an item location cache and debounced bag updates
* Introduce a central event bus for addon-internal event dispatch
* Reduce UI frame churn with a shared frame pool and grid layout helpers across the ChangeMenu, TrinketMenu and profile list
* Unify all scrollable lists on a shared scroll container and polish settings panel layout and styling
* Restructure configuration defaults with automatic backfill of new settings for existing characters
* Rebuild the slash command handling on a command registry with generated /rggm help output
* Improve argument validation of the public macro API GM_AddToCombatQueue / GM_RemoveFromCombatQueue
* Block GearBar configuration changes during combat with clear user feedback
* Show the GearMenu icon in the addon list
* Greatly extend the headless test suite (command parsing, combat queue, version comm, encoder and serializer, event bus, click handling, item location cache, swap failures, key bindings, macros, profiles and UI pooling)
* Update supported game versions to Classic Era 1.15.9 (Interface 11509) and TBC Anniversary 2.5.6 (Interface 20506)
