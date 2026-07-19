# TC-GB-06 — ChangeMenu size slider

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar exists; at least one bag item is eligible for one of its slots

## Steps

1. In the bar's configuration, change the ChangeMenu size slider
2. Hover a gearslot of that bar to open the ChangeMenu
3. Compare against a second bar with an unchanged ChangeMenu size

## Expected

- The ChangeMenu slots of the configured bar render at the new size, independent of the
  GearSlot size
- Other bars keep their own ChangeMenu size
- The size survives `/reload`
