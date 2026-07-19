# TC-GB-07 — Orientation and ChangeMenu direction

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar with at least three slots exists

## Steps

1. In the bar's configuration, switch the orientation from horizontal to vertical
2. Hover a gearslot and note the direction the ChangeMenu opens
3. Change the ChangeMenu direction option (left/right for vertical bars)
4. Switch the orientation back to horizontal
5. Check the ChangeMenu direction options offered (up/down for horizontal bars)

## Expected

- Slots re-lay out vertically/horizontally immediately
- Horizontal bars offer up/down ChangeMenu directions, vertical bars left/right; the menu
  opens in the chosen direction and does not overlap neighboring slots
- When the stored direction is invalid for the new orientation it resets to that
  orientation's default (up for horizontal, right for vertical)
- Orientation and direction survive `/reload`
