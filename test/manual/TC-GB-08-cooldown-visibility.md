# TC-GB-08 — Cooldown show/hide per bar

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- Two gearbars exist; a trinket (or other usable item) with a visible cooldown is equipped
  in a slot present on both bars

## Steps

1. Use the item to start its cooldown
2. In the first bar's configuration, disable cooldown display
3. Observe both bars
4. Re-enable cooldown display on the first bar

## Expected

- With the option disabled, the first bar shows no cooldown text/spiral for the slot while
  the second bar still does (setting is per-bar)
- Re-enabling restores the cooldown display without `/reload`
- The setting survives `/reload`
