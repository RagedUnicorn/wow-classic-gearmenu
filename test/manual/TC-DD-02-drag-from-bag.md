# TC-DD-02 — Drag from bag onto gearslot

**Area:** DragDrop | **Client:** Era | **Mandatory:** yes

## Preconditions

- A bag item compatible with a configured gearslot; out of combat

## Steps

1. Open the bags and pick up the item with a drag
2. Drop it onto the matching gearslot on the gearbar

## Expected

- The item is equipped into that slot; the previously equipped item goes to the bags
- Dropping an item on an **incompatible** slot does not equip it (item stays on cursor /
  returns to bag, no error)
- No Lua errors
