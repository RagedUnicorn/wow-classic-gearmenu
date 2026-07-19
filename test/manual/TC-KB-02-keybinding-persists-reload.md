# TC-KB-02 — Keybinding persists across /reload

**Area:** Keybinding | **Client:** Era | **Mandatory:** yes

## Preconditions

- A keybinding set on a gearslot (TC-KB-01)

## Steps

1. `/reload`
2. Check the gearslot label
3. Press the bound key
4. Log out to character select and back in; check again

## Expected

- The keybinding label is still shown after `/reload` and after a full relog
- The key still triggers the slot
- No duplicate or orphaned bindings appear (keybinding reconciliation runs cleanly)
