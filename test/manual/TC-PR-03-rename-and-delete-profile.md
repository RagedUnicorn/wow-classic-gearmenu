# TC-PR-03 — Rename and delete a profile

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- At least one saved profile

## Steps

1. Open `/rggm opt` → Profiles
2. Rename the profile to a new name
3. Delete the renamed profile

## Expected

- Rename: the list shows the new name; the profile's content is unchanged (spot-check by
  applying it or re-exporting)
- Delete: the profile disappears from the list and does not return after `/reload`
- Deleting a profile does **not** change the live configuration
- No Lua errors
