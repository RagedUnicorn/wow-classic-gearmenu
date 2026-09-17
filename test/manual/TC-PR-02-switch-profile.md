# TC-PR-02 — Switch profiles without losing edits

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- TC-PR-01: `Raid setup` is the active profile, `Default` exists

## Steps

1. With `Raid setup` active, move a gearbar, change its slot size and toggle a general
   option (e.g. *Enable FastPress*); leave the key binding of TC-PR-01 in place
2. Open Profiles, select `Default`, click "Load", read the confirm, answer Yes and wait
   for the reload
3. Add a gearbar with one slot and bind a key to it; toggle a different option
4. Open Profiles, select `Raid setup`, click "Load", answer Yes and wait for the reload
5. Press the key bound in step 1, then the key bound in step 3
6. Select the active row and look at the Load button; then click somewhere outside the
   list so nothing is selected

## Expected

- The Load confirm names both profiles: `Load profile "Default"? Your current settings
  stay saved in "Raid setup", then the UI reloads.`
- After step 2 the configuration is Default's own (its gearbars, positions, options), the
  list reads "Default (active)"
- After step 4 the gearbar is where step 1 moved it, with the changed slot size and the
  toggled option (the edits made while `Raid setup` was active were kept without any
  Update / Save step); the gearbar and option of step 3 are gone (they belong to `Default`)
  and the list reads "Raid setup (active)"
- Step 5: the key of step 1 swaps its slot; the key of step 3 does nothing (the outgoing
  profile's bindings were cleared, the incoming profile's bindings applied)
- Load is greyed while the active row is selected and clicking it does nothing; with
  nothing selected Load, Rename, Delete and Export are greyed and clicking Load prints
  "No profile selected"
- No Lua errors during either switch or after the reloads
