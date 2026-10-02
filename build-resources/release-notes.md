# New Features
* Profiles now follow the live active profile model: the profile you are on is marked "(active)" in gold and every change you make belongs to it - it is saved automatically when you switch profiles, at logout and reload, on export and at every login, so there is no Save / Update step to remember
* Create new Profile copies the current settings into a new profile and makes it active; Load switches to the selected profile and reloads the UI, the profile you leave keeping your settings as they are; deleting the active profile falls back to Default
* Add a Reset to defaults button that restores the factory settings into the active profile - the shipped options and the starter GearBar, exactly like a fresh install

# Breaking Changes
* The Default profile is now your editable home profile instead of a frozen copy of the factory settings: it is never deleted or renamed, but loading it brings back what you last had in it. Use Reset to defaults to get the factory settings back
* The Save current as... and Apply buttons are gone; Create new Profile and Load replace them. On the first login after the update the profile you had applied and not edited since becomes the active one, otherwise Default takes over your current settings - nothing is lost either way

# Bug Fixes
* Choosing the empty entry of a change menu no longer equips the item held on the cursor into the slot, and it now tells you why an item could not be unequipped - in combat, while dead, casting or under a loss of control effect, while a spell asks for a target, or when the item is locked - instead of silently doing nothing. Choosing the empty entry also cancels a swap still queued for that slot
* Importing a profile string now checks the GearBar slots it carries: a string with a slot at an invalid position, a slot that is not a slot or a key binding that is not a key is refused as invalid instead of raising Lua errors or binding keys to GearSlots that do not exist
* The update notice now only accepts a version broadcast over the guild, raid, party or instance channel that is a plain version number - a whispered version or one carrying extra text is ignored, and only the clean version number is shown and remembered, so another player can no longer put their own text into your chat or silence genuine update notices
* Chinese (zhCN): the "Add Gearslot" button and the maximum-slots message now speak of gear slots instead of GearBars, and the TrinketMenu settings are translated
* Fix a Lua error when the GearSlot size is changed for a GearBar that no longer exists
* Fix a Lua error when "Add Gearslot" is clicked on the configuration page of a GearBar that was deleted in the meantime
* Fix a Lua error when your bags change while the change menu of a GearBar you just deleted is still open - the change menu now closes instead
* A swap listener registered with GM_RegisterSwapListener that unregisters itself while handling an event no longer causes the next listener to be skipped and a "Swap listener failed" error to be logged
* QuickChange rules now also fire for channelled spells and for casts that finish while a channel is active - before, those casts were silently ignored
* The key binding on a GearSlot turns red for an out-of-range target right after a login or /reload - before, a target selected before the reload was only picked up once you changed target
* The version check no longer repeats its guild message on every group change - the guild hears it once per login, the group on every change - and a group change right after another one is announced a few seconds later instead of being skipped, so a player who joins right away still learns about a newer version
* The combat queue no longer restarts its update loop in the middle of a fight after a resurrection, a loss of control ending or an item being queued - queued items are still equipped as soon as the fight is over
