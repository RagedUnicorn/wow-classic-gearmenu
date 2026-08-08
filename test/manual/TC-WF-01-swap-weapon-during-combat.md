# TC-WF-01 — Weapon quick swap works during combat

**Area:** WeaponFlyout (prototype) | **Client:** Era | **Mandatory:** yes

## Preconditions

- `Weapon Quick Swap` enabled in `/rggm opt` → Options
- A gearbar with a main hand slot configured
- At least one alternative one-handed weapon in the bags, above the configured quality filter
- A low-level mob or another way to safely stay in combat

## Steps

1. Out of combat, hover the main hand gearslot and confirm the flyout opens
2. Enter combat
3. Hover the main hand gearslot again
4. Click one of the flyout entries
5. Hover the slot again and click the entry showing the weapon that was worn in step 2

## Expected

- The flyout opens on hover both out of and in combat
- The click in step 4 equips the weapon **immediately** — no queued-item overlay appears and
  nothing waits for `PLAYER_REGEN_ENABLED`
- The flyout closes on that click, in combat as well as out of it, the way the change menu
  closes after picking an item
- The weapon that was worn when the flyout was last built is offered as an entry, so step 5
  swaps straight back
- No `ADDON_ACTION_BLOCKED` error is raised at any point

## Diagnosing a flyout that does not open

Opening runs over two independent paths, which splits the failure cleanly:

- **out of combat** the flyout is shown by ordinary addon code (`ShowFlyoutIfPrepared`)
- **in combat** it can only be shown by the secure snippet wrapped around the gearSlot's
  OnEnter (`SecureHandlerWrapScript`)

So:

- opens neither out of nor in combat → the flyout was never populated. Check the debug log
  for `Prepared weaponFlyout for slotId …`; its absence means the option is off, the slot is
  not a weapon slot, or no bag weapon passed the item quality filter
- opens out of combat but not in combat → the data path is fine and the secure wiring is the
  problem

## Notes

- This is the only path in the addon that equips during combat. Every other slot still goes
  through the combat queue (see TC-CQ-01) — the game itself refuses non-weapon slots in combat
- The macro addresses the item by **name**. Two copies of the same weapon with different
  enchants or runes cannot be told apart here; use the regular change menu for that
