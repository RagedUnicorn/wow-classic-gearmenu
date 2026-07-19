# TC-CM-04 — FastPress (keydown vs keyup)

**Area:** ChangeMenu | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar slot with an equipped usable item (e.g. trinket with on-use effect)

## Steps

1. In `/rggm opt` general settings, disable FastPress
2. Press and hold the mouse button on the gearslot, then release — note when the item fires
3. Enable FastPress
4. Repeat the press-and-hold

## Expected

- FastPress disabled: the action triggers on key/button release (keyup)
- FastPress enabled: the action triggers immediately on key/button press (keydown)
- The setting survives `/reload`
