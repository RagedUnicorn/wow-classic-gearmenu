# TC-EV-01 — Swap listener notifications

**Area:** Public API | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar slot with an alternative item; ability to enter combat
- `GM_RegisterSwapListener` / `GM_UnregisterSwapListener` are part of the public API
  contract — this case guards them

## Steps

1. Register a listener:
   ```
   /run GM_TestListener = function(e, s, i) print("GM event", e, "slot", s, "item", i) end; GM_RegisterSwapListener(GM_TestListener)
   ```
2. Perform an immediate swap out of combat
3. Enter combat, queue a swap, then leave combat so it executes
4. Queue another swap and cancel it via right-click
5. Unregister: `/run GM_UnregisterSwapListener(GM_TestListener)` and do one more swap

## Expected

- Immediate swap: only `completed` prints
- Queued swap that executes: `queued` on queueing, then `unqueued` directly before
  `completed` when it fires
- Cancelled swap: `queued` then `unqueued` only
- Arguments are `(eventName, slotId, itemId)` as documented
- After unregistering, no further prints; swaps still work normally
