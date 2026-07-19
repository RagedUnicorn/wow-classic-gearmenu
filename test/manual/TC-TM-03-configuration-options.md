# TC-TM-03 — TrinketMenu configuration options

**Area:** TrinketMenu | **Client:** Era | **Mandatory:** yes

## Preconditions

- TrinketMenu enabled; a trinket with an active cooldown available

## Steps

1. In the TrinketMenu configuration, unlock the menu and drag it to a new position; lock it again
2. Toggle the trinket cooldown display off and on
3. Change the TrinketMenu size slider

## Expected

- Unlocked: frame is movable; locked: it is not; position survives `/reload`
- Cooldowns show/hide according to the toggle without `/reload`
- The size slider resizes the trinket slots
- All settings survive `/reload`
