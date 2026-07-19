# TC-QC-01 — Add a QuickChange rule

**Area:** QuickChange | **Client:** Era | **Mandatory:** yes

## Preconditions

- An item with a usable (on-use) effect equipped or in the bags (the "from" item)
- A second item for the same slot (the "to" item)

## Steps

1. Open `/rggm opt` → QuickChange
2. Select the "from" item and the "to" item, delay 0
3. Add the rule

## Expected

- The rule appears in the rules list showing both items and the delay
- Only items with a usable effect are offered as "from" items
- The rule is persisted (present after `/reload`, stored in
  `GearMenuConfiguration.quickChangeRules`)
