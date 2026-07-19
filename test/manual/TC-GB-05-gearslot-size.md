# TC-GB-05 — GearSlot size slider

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- Two gearbars exist

## Steps

1. In the first bar's configuration, change the GearSlot size slider to a clearly different value
2. Observe both bars
3. `/reload` and check again

## Expected

- Only the first bar's slots resize; the second bar is unchanged (size is per-bar)
- Slot contents (item icon, cooldown, keybinding text) scale with the slot
- The size survives `/reload`
