# TC-WF-03 — Flyout content is frozen during combat and refreshes after

**Area:** WeaponFlyout (prototype) | **Client:** Era | **Mandatory:** no

## Preconditions

- `Weapon Quick Swap` enabled
- A gearbar with a main hand slot, one alternative weapon in the bags
- A second alternative weapon that can be looted, traded or pulled from the bank mid fight,
  or a mob that drops one

## Steps

1. Out of combat, hover the main hand slot and note the entries offered
2. Enter combat
3. Acquire another eligible weapon while in combat (loot / trade)
4. Hover the main hand slot
5. Leave combat
6. Hover the main hand slot again
7. Change the changeSlot size of the gearbar in `/rggm opt` → GearBar while in combat, then
   leave combat and hover the slot

## Expected

- Step 4: the flyout still shows exactly the entries from step 1 — the buttons carry macros
  that were prepared before combat and cannot be rebuilt during combat lockdown
- Step 6: the newly acquired weapon is now offered
- Step 7: the flyout is re-laid-out at the new slot size once combat ends, no Lua error and
  no blocked-action message while still in combat
- No `ADDON_ACTION_BLOCKED` error at any point

## Notes

- This is the central trade-off of the prototype: the addon may decide *what* is offered,
  but only outside combat. Inside combat the player's click is the only trigger and the
  offer list is fixed
