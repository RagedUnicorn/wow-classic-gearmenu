# TC-PR-01 — Save current configuration as profile

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A recognizable configuration (specific gearbars, a QuickChange rule, a non-default theme
  or filter setting)

## Steps

1. Open `/rggm opt` → Profiles
2. Use "Save current as..." with a new profile name
3. Save a second time with the **same** name after changing one setting

## Expected

- The profile appears in the profile list
- Saving under an existing name overwrites that profile (no duplicate entry)
- The profile captures the full setup: gearbars (slots, sizes, orientation, lock state,
  position), QuickChange rules, TrinketMenu settings, theme and general options
- Profiles persist across `/reload` (stored per character in
  `GearMenuConfiguration.profiles`)
