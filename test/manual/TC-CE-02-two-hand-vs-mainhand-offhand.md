# TC-CE-02 — 2H ↔ MH/OH weapon combinations

**Area:** CombinedEquip | **Client:** Era | **Mandatory:** yes

## Preconditions

- A character able to use a two-hand weapon and a one-hand weapon + off-hand (shield or
  held-in-off-hand); all three items available; gearbar with mainhand and off-hand slots;
  out of combat; free bag space

## Steps

1. Equip the one-hand weapon and the off-hand
2. Via the mainhand gearslot's ChangeMenu, equip the two-hand weapon
3. Via the ChangeMenu, switch back to the one-hand weapon, then equip the off-hand again

## Expected

- Equipping the 2H unequips both the one-hand and the off-hand (they land in the bags),
  no items are lost
- Switching back to 1H works; the off-hand can then be equipped in the off-hand slot
- Gearslot icons track every change correctly
- No Lua errors at any step
