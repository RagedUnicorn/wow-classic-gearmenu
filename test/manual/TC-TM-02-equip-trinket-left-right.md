# TC-TM-02 — Left/right click equips upper/lower trinket

**Area:** TrinketMenu | **Client:** Era | **Mandatory:** yes

## Preconditions

- TrinketMenu enabled; at least two unequipped trinkets in the bags; out of combat

## Steps

1. Left-click a trinket in the TrinketMenu
2. Check the character's trinket slots
3. Right-click another trinket in the TrinketMenu
4. Check again

## Expected

- Left-click equips the trinket into the **upper** trinket slot
- Right-click equips the trinket into the **lower** trinket slot
- The TrinketMenu updates to reflect equipped/available trinkets
- In combat, the equip is queued via the combat queue instead
