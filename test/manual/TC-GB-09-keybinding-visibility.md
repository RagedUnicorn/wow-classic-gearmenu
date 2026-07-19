# TC-GB-09 — Keybinding show/hide per bar

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar with at least one keybound gearslot (see TC-KB-01)

## Steps

1. In the bar's configuration, disable keybinding display
2. Observe the slot
3. Re-enable keybinding display

## Expected

- Disabled: the keybinding text disappears from the slot; the binding itself keeps working
- Enabled: the keybinding text is shown on the slot again
- The setting is per-bar and survives `/reload`
