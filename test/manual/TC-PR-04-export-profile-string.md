# TC-PR-04 — Export produces profile string

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- Two profiles: the active one and an inactive one (TC-PR-01)

## Steps

1. Change a setting while the active profile is active (do not reload)
2. Open `/rggm opt` → Profiles, select the active row and click "Export"
3. Inspect the *Profile String* field
4. Select the inactive profile and click "Export"
5. Click somewhere outside the list so nothing is selected and look at the Export button

## Expected

- A copy-pasteable `GearMenu1:` string appears in the field (base64-encoded payload with
  Adler-32 checksum from `code/Encoder.lua`), selected for copying
- The export of the active row already includes the change made in step 1 (the profile
  is saved before it is exported)
- The export of the inactive profile reflects its stored settings, not the live ones
- The full string can be selected and copied (Ctrl+C) — no truncation in the edit box
- Exporting a different profile replaces the field content accordingly
- With nothing selected Export is greyed
- No Lua errors
