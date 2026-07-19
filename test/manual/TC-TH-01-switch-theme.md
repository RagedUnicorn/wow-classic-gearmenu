# TC-TH-01 — Theme switch confirmation and reload

**Area:** Themes | **Client:** Era | **Mandatory:** yes

## Preconditions

- Addon loaded; note the currently active theme

## Steps

1. Open `/rggm opt` general settings
2. Select the other theme in the theme dropdown
3. Read the popup, then **decline** it
4. Select the other theme again and **confirm**

## Expected

- Selecting a different theme shows a confirmation popup (theme change requires a UI reload)
- Declining keeps the current theme active and the dropdown reflects the unchanged selection
- Confirming triggers `ReloadUI()`; after the reload the new theme is active
- The theme choice is persisted
