# TC-GB-02 — Delete a gearbar

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- At least two gearbars exist (create one via TC-GB-01 if needed)

## Steps

1. Open `/rggm opt` and go to the gearbar configuration
2. Delete the gearbar created in TC-GB-01
3. Close the options panel

## Expected

- The bar disappears from the screen and from the gearbar list
- The remaining bars are unaffected (position, slots, sizes)
- No Lua errors while deleting or after `/reload`
- The bar does not reappear after `/reload`
