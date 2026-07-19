# TC-PR-04 — Export produces profile string

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A saved profile

## Steps

1. Open `/rggm opt` → Profiles
2. Select the profile and click "Export"
3. Inspect the *Profile String* field

## Expected

- A copy-pasteable string appears in the field (base64-encoded payload with Adler-32
  checksum from `code/Encoder.lua`)
- The full string can be selected and copied (Ctrl+C) — no truncation in the edit box
- Exporting a different profile replaces the field content accordingly
- No Lua errors
