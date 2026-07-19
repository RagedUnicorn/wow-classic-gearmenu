# TC-CQ-01 — Queue during combat, fire on leaving combat

**Area:** CombatQueue | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar slot (e.g. trinket) with an alternative item in the bags
- A low-level mob or a way to safely enter combat

## Steps

1. Enter combat
2. Hover the gearslot and click an alternative item
3. Observe the gearslot
4. Leave combat (kill the mob or run out of range until combat drops)

## Expected

- During combat the item is not equipped; a small queued-item icon is shown on the gearslot
- Immediately after leaving combat the swap executes automatically (ticker on
  `PLAYER_REGEN_ENABLED`)
- The queued-item overlay clears and the slot shows the new item
- Works for weapons too (weapons cannot be swapped by addons during combat and are always queued)
