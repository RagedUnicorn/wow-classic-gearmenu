# TC-GB-04 — Reposition, lock and unlock a gearbar

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar exists and is currently locked

## Steps

1. In the bar's configuration, unlock the gearbar
2. Drag the bar to a different screen position
3. Lock the gearbar again
4. Attempt to drag the locked bar
5. `/reload`

## Expected

- Unlocked: the bar can be dragged freely
- Locked: dragging has no effect
- The new position survives `/reload` (persisted per bar in its `position` table)
- Lock state itself also survives `/reload`
