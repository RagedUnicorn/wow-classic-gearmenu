# TC-QC-04 — Remove a rule

**Area:** QuickChange | **Client:** Era | **Mandatory:** yes

## Preconditions

- At least one QuickChange rule exists

## Steps

1. Open `/rggm opt` → QuickChange
2. Select the rule and remove it
3. Use the former "from" item

## Expected

- The rule disappears from the list and does not return after `/reload`
- Using the item no longer triggers any switch
- No Lua errors
