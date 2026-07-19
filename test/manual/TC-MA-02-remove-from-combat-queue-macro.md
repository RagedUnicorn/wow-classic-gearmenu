# TC-MA-02 — GM_RemoveFromCombatQueue macro

**Area:** Macro API | **Client:** Era | **Mandatory:** yes

## Preconditions

- A queued swap on a known slot (queue one in combat, e.g. slot 14 via TC-MA-01)
- `GM_RemoveFromCombatQueue` is part of the public API contract — this case guards it

## Steps

1. While the swap is queued and the player still in combat, run:
   `/run GM_RemoveFromCombatQueue(14)`
2. Leave combat

## Expected

- The queue for slot 14 is cleared; the queued-item overlay disappears
- After leaving combat no swap fires
- Calling it for a slot with no queued swap is a no-op without errors
