# TC-SV-01 — Fresh install seeds defaults

**Area:** SavedVariables | **Client:** Era | **Mandatory:** yes

## Preconditions

- Client fully logged out
- Backup of the character's current `WTF/.../SavedVariables/GearMenu.lua` taken (to restore after the test)

## Steps

1. Delete `GearMenu.lua` (and `GearMenu.lua.bak`) from the character's `SavedVariables` folder
2. Log in with the character
3. Observe the screen and chat for errors
4. Open `/rggm opt` and walk through every tab

## Expected

- No Lua errors on login
- A default gearbar is created containing three slots: upper trinket, lower trinket, head
  (`FirstTimeInitialization` in `code/Configuration.lua`)
- All option tabs open and show default values (e.g. item quality filter at green/uncommon)
- After logout, `GearMenuConfiguration` in the SavedVariables file contains all fields from
  `CONFIGURATION_DEFAULTS` and `firstTimeInitializationDone = true`
