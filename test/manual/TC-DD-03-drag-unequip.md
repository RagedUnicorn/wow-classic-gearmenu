# TC-DD-03 — Unequip by dragging into bag

**Area:** DragDrop | **Client:** Era | **Mandatory:** yes

## Preconditions

- An item equipped in a configured gearslot; free bag space; out of combat

## Steps

1. Drag the item off the gearslot
2. Drop it into an open bag

## Expected

- The item is unequipped and lands in the bag
- The gearslot shows its empty-slot texture
- Hovering the now-empty slot still opens the ChangeMenu with eligible items
- No Lua errors
