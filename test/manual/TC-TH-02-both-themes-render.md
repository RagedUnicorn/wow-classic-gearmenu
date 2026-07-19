# TC-TH-02 — Slots render correctly in both themes

**Area:** Themes | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar with several slots (equipped items, one empty slot, one item on cooldown,
  one keybound slot); TrinketMenu enabled

## Steps

1. With the **Custom** theme active, inspect gearbar slots, ChangeMenu, TrinketMenu:
   textures, borders, highlight on hover, cooldown spiral/text, keybinding label,
   queued-item overlay (queue a swap in combat if feasible)
2. Switch to the **Classic** theme (TC-TH-01) and repeat the inspection

## Expected

- Both themes render every element correctly: no missing/stretched textures, no overlapping
  text, hover highlight works, cooldowns and keybinding labels are positioned properly
- Slot sizes and bar layout are identical between themes (only the visual style differs)
- No Lua errors while interacting in either theme

> Any change touching slot rendering must be verified in **both** theme files
> (`gui/ThemeClassic.lua`, `gui/ThemeCustom.lua`) — this case is the runtime check for that.
