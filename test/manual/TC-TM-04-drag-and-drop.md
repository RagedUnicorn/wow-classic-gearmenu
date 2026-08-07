# TC-TM-04 — Drag and drop out of and into the TrinketMenu

**Area:** TrinketMenu | **Client:** Era | **Mandatory:** yes

## Preconditions

- TrinketMenu enabled; at least two unequipped trinkets in the bags; free bag space; out of combat
- Drag & Drop enabled in the general options

## Steps

1. Drag a trinket out of the TrinketMenu and drop it on a character trinket slot
2. Drag another trinket out of the TrinketMenu and drop it on a gearslot configured for trinkets
3. Drag an equipped trinket off the character sheet and drop it onto the TrinketMenu
4. Drag a non-trinket (e.g. a ring) from the bags and drop it onto the TrinketMenu
5. Disable Drag & Drop in the general options and repeat steps 1 and 3
6. Enter combat, then repeat steps 1 and 3

## Expected

- Step 1/2: the trinket is picked up onto the cursor and equips on drop; the TrinketMenu list
  no longer shows it
- Step 3: the trinket is unequipped into the first free bag slot and reappears in the TrinketMenu
- Step 4: the ring stays on the cursor, nothing is placed into the bags
- Step 5: neither direction reacts — dragging does not pick anything up and dropping does nothing
- Step 6: no protected-frame or taint error; a drop on a gearslot is queued via the combat queue,
  and a refused bag placement clears the cursor and prints the localized "no free space" error
- With full bags, step 3 prints the localized "no free space" message and leaves the trinket equipped
- Both the Classic and the Custom theme behave identically
- No Lua errors
