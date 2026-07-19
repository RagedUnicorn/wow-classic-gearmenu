# TC-GB-01 — Create a new gearbar

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- Addon loaded, options panel reachable via `/rggm opt`

## Steps

1. Open `/rggm opt` and go to the gearbar configuration
2. Create a new gearbar with a distinct name
3. Close the options panel

## Expected

- The new bar appears in the gearbar list and gets its own configuration sub-menu
- The bar renders on screen with a default slot
- The bar acts independently of existing bars (moving/configuring it does not affect others)
- After `/reload` the bar is still present (persisted in `GearMenuConfiguration.gearBars`)
