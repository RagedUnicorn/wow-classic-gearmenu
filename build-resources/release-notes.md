# New Features
* Add per-GearBar orientation support to lay out GearSlots horizontally or vertically
* Add a configurable ChangeMenu open direction (up/down for horizontal, left/right for vertical GearBars)
* Add a drag handle to move a GearBar while it is unlocked

# Bug Fixes
* Fix ChangeMenu width to match the visible columns instead of the total item count

# Refactoring and Improvements
* Add a headless unit test suite based on the Busted framework covering the CombatQueue, GearBarManager, configuration migration, ItemManager matchers and macro slot validity
* Add localization parity tests to ensure key and format placeholder consistency across all locales
* Add lint and test status badges to the README
* Upgrade the CI toolchain to Java 21
