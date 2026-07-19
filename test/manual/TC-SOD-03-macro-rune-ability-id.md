# TC-SOD-03 — Macro with runeAbilityId

**Area:** Season of Discovery | **Client:** Era (SoD) | **Mandatory:** conditional

> Run only if a Season of Discovery character is available or SoD-related code was touched.

## Preconditions

- SoD character; an engraved bag item with known itemId and runeAbilityId
- Ideally two copies of the same item with different runes (the disambiguation case the
  parameter exists for)

## Steps

1. Run `/run GM_AddToCombatQueue(<itemId>, 0, <runeAbilityId>, <slotId>)` out of combat
2. If two same-itemId items with different runes exist, repeat targeting each rune

## Expected

- The item is equipped; with duplicates present, the copy carrying the requested rune is
  chosen
- `runeAbilityId = 0` still works when rune disambiguation is not needed (documented
  behavior)
- No Lua errors
