# TC-PR-03 — Rename and delete a profile, the active one too

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- TC-PR-02: `Raid setup` is active with its own gearbars and key binding, `Default` holds
  a different setup

## Steps

1. Open `/rggm opt` → Profiles, select `Raid setup` (the active row) and rename it to
   `Raid`
2. Rename it again and try to type a name longer than 30 characters; then try the name
   `Default`
3. Click "Create new Profile", enter `Temp` (it becomes active); select `Raid`, Load,
   Yes, wait for the reload; then select `Temp`, click "Delete", answer Yes
4. Select `Raid` (the active row), click "Delete", read the confirm, answer Yes and wait
   for the reload
5. Reopen the Profiles page and press the key that was bound in `Raid`

## Expected

- The rename prompt stops accepting input at 30 characters; `Default` as the new name is
  refused with `"Default" is a reserved profile name`
- Rename: the list shows "Raid (active)" - the active marker followed the rename - and
  the profile's content is unchanged (spot-check by re-exporting); `/reload` keeps `Raid`
  as the active profile
- Deleting the inactive `Temp` in step 3 asks the plain `Delete profile "Temp"?` question,
  removes it without a reload, drops the selection and leaves `Raid` active and the live
  configuration untouched
- The confirm in step 4 says `Raid` is the active profile and that `Default` takes over
  the settings before the UI reloads
- After the reload the list reads "Default (active)" and `Raid` is gone; the gearbars and
  options are `Default`'s own; the key bound in `Raid` does nothing any more, the keys
  bound in `Default` work
- Neither profile returns after `/reload`
- No Lua errors
