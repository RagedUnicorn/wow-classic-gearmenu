# TC-UN-01 — Unequip via empty ChangeMenu slot

**Area:** Unequip | **Client:** Era | **Mandatory:** yes

## Preconditions

- The "empty slot in ChangeMenu" option enabled in `/rggm opt` general settings
- An item equipped in a configured gearslot; free bag space; out of combat

## Steps

1. Hover the gearslot to open the ChangeMenu
2. Click the empty-slot entry

## Expected

- The equipped item is unequipped and moved to the bags
- The gearslot shows its empty texture
- With the option disabled, the empty-slot entry is not shown in the ChangeMenu
- In combat, the unequip is queued like any other swap
