# TC-CM-02 — Item quality filter

**Area:** ChangeMenu | **Client:** Era | **Mandatory:** yes

## Preconditions

- Bag contains items for one gearslot in at least two different quality tiers
  (e.g. a white/gray and a green item for the same slot)

## Steps

1. In `/rggm opt` general settings, note the current "Filter Item Quality" value
   (default: uncommon/green)
2. Hover the gearslot and check which items are listed
3. Lower the filter to common/poor
4. Hover the gearslot again
5. Restore the filter to its previous value

## Expected

- With the default filter, items below uncommon are not listed in the ChangeMenu
- After lowering the filter, the lower-quality items appear
- The change takes effect without `/reload` and survives `/reload`
