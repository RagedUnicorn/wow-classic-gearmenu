# Fixes

* Fix initial setup of GearMenu for firstTime users (no configuration present)
* Fix multiple issue with setting keyBinds
  * Keybinds are now correctly fixed if a slot is deleted and another sloth moves into its place
  * Do not lose reference to orphaned GearSlots they cannot be recreated but rather have to be reused
