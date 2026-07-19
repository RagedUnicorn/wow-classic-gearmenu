# TC-PR-02 — Apply profile restores configuration

**Area:** Profiles | **Client:** Era | **Mandatory:** yes

## Preconditions

- A saved profile (TC-PR-01)

## Steps

1. Change several settings away from the profile's state (move a bar, change slot size,
   toggle an option)
2. Open `/rggm opt` → Profiles, select the profile and click "Apply"
3. Wait for the UI reload

## Expected

- Applying triggers a UI reload
- After the reload, the configuration matches the profile exactly: bar positions, slots,
  sizes, orientation, lock state, QuickChange rules, TrinketMenu settings, theme, general
  options
- No Lua errors during apply or after the reload
