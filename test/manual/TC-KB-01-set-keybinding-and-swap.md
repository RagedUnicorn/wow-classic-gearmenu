# TC-KB-01 — Set keybinding, label shows, key swaps

**Area:** Keybinding | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar with a slot holding a usable item; keybinding display enabled on the bar

## Steps

1. Open the bar's gearslot configuration in `/rggm opt`
2. Set a keybinding for the slot (bindings are set inside GearMenu's configuration, not the
   Blizzard keybinding UI)
3. Close the options and check the slot
4. Press the bound key

## Expected

- The keybinding label appears on the gearslot
- Pressing the key triggers the slot exactly like clicking it (uses the item / opens swap
  behavior; respects the FastPress setting)
- Rebinding a key already used elsewhere is handled gracefully (old binding replaced, no error)
