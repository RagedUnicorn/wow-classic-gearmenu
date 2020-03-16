# Features
* Update for new interface version 1.13.4 (11304)
* Add support for zhCN locale
* Add support for ammoslot(0)
	* This requires a migration during the update to v1.3.0 and is done automatically
* Implement support for macrobridge
	* Add support for adding items into the combatqueue directly from within a macro
	* Add support for clearing the combatqueue for a specific slotId directly from within a macro

# Bugfixes
* Fix #42 Adapt changemenusize after resizing gearslots
* Check for both bagNumber and bagPos when searching an item
* Fix handling of drag and drop while in combatlockdown
	* Fix dragging item onto a slot while in combat. The item is now properly put into the combatQueue
	* Fix dragging items between slots e.g. trinket1 onto trinket2. The item that is dragged is now properly put into the combatQueue of the targetslot
	* Use a more general approach with GetItemInfo for retrieving an items
* Fix #54 Rework detection whether the player is dead or not
* Prevent attempting to change gear while the player is dead

# Development
* Add project setup for automated twitch releases
* Replace hardcoded includeBaseDirectory for assembly-development
