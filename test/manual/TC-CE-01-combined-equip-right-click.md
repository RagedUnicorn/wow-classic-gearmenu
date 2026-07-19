# TC-CE-01 — Right-click equips into opposite slot

**Area:** CombinedEquip | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar with both trinket slots (or both ring slots); a spare trinket/ring in the bags;
  out of combat

## Steps

1. Hover the **upper** trinket gearslot to open the ChangeMenu
2. Right-click an item in the ChangeMenu
3. Verify where the item was equipped
4. Repeat with a left-click on another item

## Expected

- Right-click equips the chosen item into the **opposite** (lower) trinket slot —
  combined equipping is enabled for trinket and ring slots
- Left-click equips into the hovered (upper) slot itself
- On slots without combined equipping (e.g. head), right-click behaves like left-click and
  equips into the hovered slot
