# TC-SV-02 — Upgrade from previous release migrates cleanly

**Area:** SavedVariables | **Client:** Era | **Mandatory:** yes

## Preconditions

- Client fully logged out
- A `GearMenu.lua` SavedVariables file produced by the **previous release** is available
  (ideally with multiple gearbars, QuickChange rules and at least one profile in it)

## Steps

1. Place the previous release's `GearMenu.lua` into the character's `SavedVariables` folder
2. Log in with the character
3. Observe the screen and chat for errors
4. Verify gearbars render exactly as configured in the old file (slots, sizes, positions, lock state)
5. Open `/rggm opt` and check QuickChange rules and profiles are still present
6. Log out and inspect the SavedVariables file

## Expected

- No Lua errors on login; `MigrationPath()` / defaults backfill runs silently
- All user data (gearbars, QuickChange rules, profiles, frame positions) survives unchanged
- Newly introduced configuration fields are present with their default values
- `addonVersion` in the file is bumped to the new release version
