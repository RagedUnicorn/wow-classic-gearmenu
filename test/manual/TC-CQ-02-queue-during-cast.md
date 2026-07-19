# TC-CQ-02 — Queue during cast, fire when cast ends

**Area:** CombatQueue | **Client:** Era | **Mandatory:** yes

## Preconditions

- Out of combat; a castable spell with a cast time (mount cast works well)
- A gearbar slot with an alternative item in the bags

## Steps

1. Start casting (e.g. summon the mount)
2. While the cast bar is running, click an alternative item in the ChangeMenu
3. Let the cast finish
4. Repeat steps 1–2, but this time cancel the cast (move or press Escape)

## Expected

- During the cast the swap is queued (queued-item overlay on the slot), not executed
- When the cast completes, the swap fires (`UNIT_SPELLCAST_SUCCEEDED`)
- When the cast is cancelled, the swap also fires (`UNIT_SPELLCAST_INTERRUPTED`)
- The overlay clears in both variants
