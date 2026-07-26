# TC-PR-07 — Default profile is seeded and immutable

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A character that has never seen the default profile (fresh install per TC-SV-01) for step 1,
  otherwise any character

## Steps

1. Log in and open `/rggm opt` → Profiles without saving anything
2. Select "Default" and try "Rename", then "Delete"
3. Change a setting (e.g. add a gearBar and set the item quality filter to Epic), then click
   "Save current as..." and enter `Default`
4. Select "Default" and click "Apply", confirm the popup
5. Save a profile under a different name and rename it to `Default`
6. Export the "Default" profile, then import it under the name `Default`
7. `/reload` and re-check the list

## Expected

- "Default" is present in the list on the very first login, without the user creating it
- While "Default" is selected the Rename and Delete buttons are greyed out; clicking them
  anyway (or reaching them by any other route) prints a user-visible error and changes nothing
- Saving under the name `Default` is refused with a "cannot be overwritten" error; the stored
  Default profile keeps the shipped values (no gearBars, no quickChange rules, item quality
  filter Uncommon, custom theme, trinketMenu enabled)
- Applying "Default" resets the live configuration to those shipped values and reloads the UI —
  the character is back to the fresh-install state with no gearBars
- Renaming another profile to `Default` is refused with a user-visible error and leaves both
  profiles untouched
- Importing under the name `Default` is refused with a user-visible error
- After `/reload` the list still holds "Default" plus any user profiles; other profiles can
  still be saved, applied, renamed and deleted as usual
- No Lua errors
