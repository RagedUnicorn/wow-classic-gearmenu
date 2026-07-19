# TC-QC-03 — Delayed rule respects delay

**Area:** QuickChange | **Client:** Era | **Mandatory:** yes

## Preconditions

- Same setup as TC-QC-02, but the rule is configured with a delay (e.g. 10 seconds —
  in practice you would match the duration of the item's buff)

## Steps

1. Use the "from" item
2. Watch the gearslot and count the delay

## Expected

- The switch does **not** happen immediately
- After the configured delay elapses, the "to" item is equipped (queued instead if the
  player is in combat at that moment)
- No Lua errors
