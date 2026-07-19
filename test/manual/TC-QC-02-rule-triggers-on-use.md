# TC-QC-02 — Rule triggers on item use

**Area:** QuickChange | **Client:** Era | **Mandatory:** yes

## Preconditions

- A QuickChange rule with delay 0 exists (TC-QC-01); the "from" item is equipped and its
  effect is off cooldown; out of combat

## Steps

1. Use the "from" item (click it on the gearbar or use its slot binding)
2. Observe the gearslot

## Expected

- Immediately after use, the "to" item is equipped in the slot
- If the same use happens **in combat**, the switch goes to the combat queue instead and
  fires after leaving combat (normal switching rules apply)
- No Lua errors
