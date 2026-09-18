# TC-GB-10 — Click an empty gearslot

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar with a configured gearslot whose inventory slot is empty (e.g. unequip the item via TC-UN-01 or the character frame)
- `/console scriptErrors 1` enabled; out of combat

## Steps

1. Left-click the empty gearslot
2. Right-click the empty gearslot
3. Enable FastPress in `/rggm opt` general settings and repeat steps 1-2
4. Bind a key to the gearslot (TC-KB-01) and press it

## Expected

- No Lua error is raised on any click or key press (in particular no `C_Item.IsEquippableItem` bad argument error from `SecureTemplates.lua`)
- The click is a harmless no-op; the gearslot keeps showing its empty texture
- Equipping an item into the slot again and clicking the gearslot fires the item's on-use effect as before
