# TC-CM-03 — Click swaps item out of combat

**Area:** ChangeMenu | **Client:** Era | **Mandatory:** yes

## Preconditions

- Out of combat, not casting; a gearbar slot with at least one alternative item in the bags

## Steps

1. Hover the gearslot to open the ChangeMenu
2. Left-click an alternative item

## Expected

- The item is equipped immediately (no queueing)
- The gearslot icon updates to the newly equipped item
- The previously equipped item is now listed in the ChangeMenu
- No Lua errors
