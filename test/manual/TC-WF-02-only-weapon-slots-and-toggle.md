# TC-WF-02 — Only weapon slots get a flyout, toggle takes effect live

**Area:** WeaponFlyout (prototype) | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar with a main hand, an off hand and at least one non-weapon slot (e.g. trinket)
- Alternative items in the bags for all three slots

## Steps

1. Enable `Weapon Quick Swap` in `/rggm opt` → Options
2. Hover the trinket slot
3. Hover the main hand slot, then the off hand slot
4. Disable `Weapon Quick Swap` again
5. Hover the main hand slot

## Expected

- Step 2: the regular change menu opens, unchanged in look and behaviour
- Step 3: the flyout opens instead of the change menu — never both at once
- Step 4: the toggle takes effect without a `/reload`
- Step 5: the main hand slot is back to the regular change menu
- A weapon slot with no alternative weapon in the bags shows no flyout at all and keeps
  the regular change menu behaviour

## Notes

- On Era/TBC the ranged slot also qualifies. On MoP Classic the ranged slot no longer holds
  weapons, so it simply never has anything to offer
