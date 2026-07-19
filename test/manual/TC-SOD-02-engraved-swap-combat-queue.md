# TC-SOD-02 — Engraved item swap through combat queue

**Area:** Season of Discovery | **Client:** Era (SoD) | **Mandatory:** conditional

> Run only if a Season of Discovery character is available or SoD-related code was touched.

## Preconditions

- SoD character; two items for the same slot carrying **different** runes

## Steps

1. Out of combat, swap between the two engraved items via the ChangeMenu
2. Enter combat, queue a swap to the other engraved item, leave combat

## Expected

- Out of combat: the correct item (with its specific rune) is equipped — the rune is part
  of what identifies the item
- The queued swap picks the item with the intended rune, not just any item with the same
  itemId
- Rune display updates after each swap; no Lua errors
