# TC-PR-07 — Default profile is editable, Reset to defaults restores the factory settings

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A character that has never seen the Default profile (fresh install per TC-SV-01) for
  step 1, otherwise any character

## Steps

1. Log in and open `/rggm opt` → Profiles without creating anything
2. Select "Default" and try "Rename", then "Delete"
3. With `Default` active, add a gearbar with a bound key, set the item quality filter to
   Epic and add a QuickChange rule; `/reload` and check the SavedVariables
4. Click "Create new Profile" and enter `Default`; then create `Scratch` (it becomes
   active) and change one more option
5. With nothing selected click "Reset to defaults", read the confirm, answer Yes and wait
   for the reload
6. Select `Default`, Load, Yes, wait for the reload
7. Export the "Default" profile, then import it under the name `Default`; then rename
   `Scratch` to `Default`

## Expected

- "Default (active)" is present in gold on the very first login, without the user
  creating it
- While "Default" is selected the Rename and Delete buttons are greyed out; clicking them
  anyway (or reaching them by any other route) prints a user-visible error and changes
  nothing
- Default is editable: after step 3 the stored `GearMenuConfiguration.profiles.Default`
  holds the gearbar, the Epic filter and the rule (the mirror ran at the reload) - it was
  not re-seeded with the shipped values
- Creating under the name `Default` is refused with `"Default" is a reserved profile name`
- "Reset to defaults" is never greyed; the confirm names `Scratch` and says every option
  goes back to its default and the gearbars and QuickChange rules are replaced by the
  starter gearbar
- After the reload of step 5 the character is in the fresh-install state: a single
  "Default GearBar" with upper trinket, lower trinket and head, no QuickChange rules, the
  item quality filter at Uncommon, the custom theme, TrinketMenu enabled; the key bound in
  step 3 does nothing; the list still reads "Scratch (active)"
- `Default` was not touched by the reset: after step 6 the gearbar, the Epic filter and
  the rule of step 3 are back
- Importing under the name `Default` and renaming onto `Default` are each refused with the
  reserved-name error and leave every profile untouched
- After `/reload` the list still holds "Default" plus the user profiles; other profiles
  can still be created, loaded, renamed and deleted as usual
- No Lua errors
