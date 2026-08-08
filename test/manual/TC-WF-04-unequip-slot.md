# TC-WF-04 — Unequip slot in the weapon flyout

**Area:** WeaponFlyout (prototype) | **Client:** Era | **Mandatory:** yes

## Preconditions

- `Weapon Quick Swap` and `Enable Unequip Slot` both enabled in `/rggm opt` → Options
- A gearbar with an off hand slot, an off hand item worn and a free bag slot

## Steps

1. Out of combat, hover the off hand slot
2. Click the empty slot at the end of the flyout
3. Hover the off hand slot again
4. Re-equip an off hand, enter combat, hover the slot and click the empty slot
5. Disable `Enable Unequip Slot`, leave combat and hover the slot again

## Expected

- Step 1: an empty slot showing the slot's placeholder icon closes out the flyout, taking the
  next free grid position after the last weapon — the same placement the change menu uses
- Step 2: the off hand is moved into the bags and the flyout closes
- Step 3: the empty slot is gone (nothing is worn in that slot any more)
- Step 4: **nothing is unequipped**; a chat message states that unequipping is not possible
  during combat, and no `ADDON_ACTION_BLOCKED` error appears
- Step 5: the empty slot is gone — the option is shared with the change menu

## Notes

- The in-combat limit is not an oversight. Every other flyout button carries an `/equipslot`
  macro, but no slash command takes an item off, and the functions that do are protected —
  so this one button falls back to the same insecure path the change menu uses
- With full bags the swap is refused with the regular no-bag-space message
