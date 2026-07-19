# TC-CQ-03 — Cancel queued swap via right-click

**Area:** CombatQueue | **Client:** Era | **Mandatory:** yes

## Preconditions

- A way to queue a swap (enter combat as in TC-CQ-01)
- The slot used must **not** have combined equipping (avoid trinket/ring slots for this case
  — on those, right-click equips into the opposite slot instead of clearing the queue)

## Steps

1. Enter combat and queue a swap on a non-trinket/ring gearslot (e.g. head)
2. While still in combat, right-click that gearslot
3. Leave combat

## Expected

- The right-click clears the combat queue for that slot; the queued-item overlay disappears
- After leaving combat no swap fires — the originally equipped item stays equipped
- No Lua errors
