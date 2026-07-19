# TC-SOD-01 — Rune display on items

**Area:** Season of Discovery | **Client:** Era (SoD) | **Mandatory:** conditional

> Run only if a Season of Discovery character is available or SoD-related code
> (`code/Season.lua`, `code/Engrave.lua`, `gui/EngraveFrame.lua`) was touched.

## Preconditions

- SoD character with runes engraved on worn items and on at least one bag item
- Rune support enabled in `/rggm opt`

## Steps

1. Inspect gearbar slots holding engraved items
2. Hover a slot whose ChangeMenu contains an engraved bag item
3. Disable rune support in the options and re-check both

## Expected

- Active runes are displayed on worn items in the gearslots and on eligible bag items in the
  ChangeMenu
- Disabling the option removes the rune display everywhere without `/reload`
- Known Blizzard API limitation: a few items do not display runes properly — that is not a
  GearMenu regression
