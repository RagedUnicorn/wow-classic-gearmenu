# TC-PR-06 — Corrupted import string rejected

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A valid exported profile string to mutate

## Steps

1. Paste the valid string into the *Profile String* field, but change a few characters in
   the middle (breaks the Adler-32 checksum)
2. Click "Import"
3. Repeat with clearly invalid input: an empty string, random text (`hello world`), and a
   string from another addon if available

## Expected

- Every invalid string is **rejected with a user-visible error message**
- No profile is created; the existing profile list and the live configuration are untouched
- No Lua errors — rejection is a handled failure (checksum/parse validation in
  `code/Encoder.lua` / `code/Serializer.lua`), never a crash
