# TC-CQ-05 — Queue survives death, fires when alive

**Area:** CombatQueue | **Client:** Era | **Mandatory:** yes

## Preconditions

- A queued swap can be produced and the character can safely die (low-level zone)
- **Do not run on a Hardcore character**

## Steps

1. Enter combat and queue a swap (as in TC-CQ-01)
2. Die while the swap is still queued
3. Release, run back and resurrect (or accept a resurrection)

## Expected

- The queued swap is not lost on death
- After the character is alive again (`PLAYER_ALIVE` / `PLAYER_UNGHOST` start the ticker),
  the queued swap fires automatically
- No Lua errors at death, release or resurrection
