# TC-CMD-01 — /rggm command surface

**Area:** Slash commands | **Client:** Era | **Mandatory:** yes

## Preconditions

- Addon loaded

## Steps

1. Type `/rggm`
2. Type `/rggm help`
3. Type `/rggm opt`
4. Type `/rggm foo`
5. Type `/rggm rl` (expect a UI reload)
6. Type `/gearmenu opt` (alias)
7. Type `/rggm reload` (expect a UI reload)

## Expected

- Bare `/rggm` and `/rggm help` print the info/help text listing the available commands
- `/rggm opt` opens the GearMenu options panel
- An unknown argument (`foo`) prints the invalid-argument user error
- `/rggm rl` and `/rggm reload` both reload the UI
- `/gearmenu` works identically to `/rggm`
