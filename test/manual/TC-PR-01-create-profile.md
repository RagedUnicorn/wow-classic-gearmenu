# TC-PR-01 — Create a profile from the current settings

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A recognizable configuration (specific gearbars with a key binding on one slot, a
  QuickChange rule, a non-default theme or filter setting)

## Steps

1. Open `/rggm opt` → Profiles and look at the list
2. Click "Create new Profile", enter `Raid setup`, Accept
3. Click "Create new Profile" again and enter `Raid setup`; then `Default`; then a blank
   name; then try to type a name longer than 30 characters
4. `/reload` and reopen the page

## Expected

- Before step 2 the list reads "Default (active)" in gold; with nothing selected Load,
  Rename, Delete and Export are greyed while Create new Profile, Reset to defaults and
  Import are not
- After step 2 the list reads "Default" and "Raid setup (active)" (gold, selected), the
  chat says `Created profile "Raid setup" - it is now active`, and no UI reload happened -
  the gearbars, the key binding and the rule are exactly as before
- The taken name, `Default` and the blank name are each refused with a chat error and
  nothing is created; the prompt stops accepting input at 30 characters
- After `/reload` the list still shows "Raid setup (active)"; the SavedVariables hold both
  profiles under `GearMenuConfiguration.profiles` with the same settings (the mirror ran
  at the reload) and `GearMenuConfiguration.activeProfile` reads `Raid setup`
- The profile captures the full setup: gearbars (slots, sizes, orientation, lock state,
  key binding labels, position), QuickChange rules, TrinketMenu settings, theme and
  general options
- No Lua errors
