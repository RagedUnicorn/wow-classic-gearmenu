# Fixes

* Fix bug where GearMenu forgets keybinds
  * Previously, there was a bug in the GearMenu addon where keybinds would be forgotten during the startup process. Specifically, the GetBindingAction function would occasionally return an empty string for buttons, despite a valid keybind being set. Although the keybind would still work, GearMenu wouldn't display it anymore. To address this issue, I have implemented a slight delay before calling GetBindingAction during startup. This ensures that the keybinds are properly recognized and displayed by GearMenu.
