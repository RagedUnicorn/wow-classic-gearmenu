# TC-PR-05 — Import round-trip

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- An exported profile string (TC-PR-04), ideally from a profile with multiple gearbars and
  QuickChange rules

## Steps

1. Delete the source profile (or switch to a second character — profiles are stored per
   character, and cross-character transfer is the point of export/import)
2. Paste the exported string into the *Profile String* field
3. Click "Import"
4. Apply the imported profile (TC-PR-02)

## Expected

- The profile is created from the string and appears in the list
- After applying, the configuration matches the originally exported setup exactly
- Importing the same string twice does not corrupt the list (second import is a separate
  entry or a handled name conflict — no silent overwrite without feedback)
- No Lua errors
