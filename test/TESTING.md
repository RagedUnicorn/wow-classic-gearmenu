# Release Testing

> This document describes the test procedure that must pass before a new GearMenu release is created.
> Deployment steps live in [RELEASE.md](../RELEASE.md); this document is the testing gate referenced there.

A release passes when:

* All automated gates are green
* All mandatory manual test cases in [test/manual/](manual/) pass on Classic Era
* The smoke checklist passes on TBC Anniversary and MoP Classic
* Zero Lua errors occurred during the whole run

Before starting the in-game runs, enable script errors so nothing is swallowed:

```
/console scriptErrors 1
```

## 1. Automated gates

Run locally (Docker required):

```bash
# lua linting
docker compose run --rm luacheck

# busted unit tests (test/headless/spec/)
docker compose run --rm busted
```

Additionally verify that CI is green on `master` for the latest commit:

* `lint.yaml` - luacheck
* `test.yaml` - busted

Both must pass with zero failures before any in-game testing starts.

## 2. In-game test matrix

The dev checkout in `Interface/AddOns/GearMenu` is what gets tested - no packaged build required.

| Client                    | Interface | Coverage                                              |
|---------------------------|-----------|-------------------------------------------------------|
| Classic Era               | 11508     | Full manual catalog ([test/manual/](manual/))         |
| TBC Anniversary           | 20506     | Smoke checklist (below)                               |
| MoP Classic               | 50504     | Smoke checklist (below)                               |
| Season of Discovery (Era) | 11508     | `TC-SOD-*` cases - conditional, see note below        |

The `TC-SOD-*` cases are **conditional**: run them only if a Season of Discovery character
is available or if SoD-related code (`code/Season.lua`, `code/Engrave.lua`,
`gui/EngraveFrame.lua`) was touched since the last release.

## 3. Smoke checklist (TBC Anniversary / MoP Classic)

A short pass to confirm the addon behaves on the non-primary clients:

- [ ] Addon loads without errors on login
- [ ] Gearbar renders with configured slots
- [ ] Hovering a gearslot opens the ChangeMenu and lists eligible bag items
- [ ] Clicking an item in the ChangeMenu swaps it
- [ ] A swap attempted during combat is queued and fires after leaving combat
- [ ] `/rggm opt` opens the options panel; all tabs open without errors
- [ ] Switching the theme (Custom ↔ Classic) works, bar renders correctly after reload
- [ ] `/reload` produces no Lua errors

## 4. Manual test case catalog (Classic Era)

One file per test case under [test/manual/](manual/). Case IDs follow `TC-<AREA>-<NN>`.

### SavedVariables lifecycle (mandatory every release)

| ID                                                           | Case                                           |
|--------------------------------------------------------------|------------------------------------------------|
| [TC-SV-01](manual/TC-SV-01-fresh-install.md)                 | Fresh install seeds defaults                   |
| [TC-SV-02](manual/TC-SV-02-upgrade-from-previous-release.md) | Upgrade from previous release migrates cleanly |

### GearBar management

| ID                                                    | Case                                  |
|-------------------------------------------------------|---------------------------------------|
| [TC-GB-01](manual/TC-GB-01-create-gearbar.md)         | Create a new gearbar                  |
| [TC-GB-02](manual/TC-GB-02-delete-gearbar.md)         | Delete a gearbar                      |
| [TC-GB-03](manual/TC-GB-03-add-remove-gearslot.md)    | Add and remove gearslots              |
| [TC-GB-04](manual/TC-GB-04-reposition-lock-unlock.md) | Reposition, lock and unlock a gearbar |
| [TC-GB-05](manual/TC-GB-05-gearslot-size.md)          | GearSlot size slider                  |
| [TC-GB-06](manual/TC-GB-06-changemenu-size.md)        | ChangeMenu size slider                |
| [TC-GB-07](manual/TC-GB-07-orientation.md)            | Orientation and ChangeMenu direction  |
| [TC-GB-08](manual/TC-GB-08-cooldown-visibility.md)    | Cooldown show/hide per bar            |
| [TC-GB-09](manual/TC-GB-09-keybinding-visibility.md)  | Keybinding show/hide per bar          |

### ChangeMenu & swapping

| ID                                               | Case                           |
|--------------------------------------------------|--------------------------------|
| [TC-CM-01](manual/TC-CM-01-hover-lists-items.md) | Hover lists eligible bag items |
| [TC-CM-02](manual/TC-CM-02-quality-filter.md)    | Item quality filter            |
| [TC-CM-03](manual/TC-CM-03-click-swap.md)        | Click swaps item out of combat |
| [TC-CM-04](manual/TC-CM-04-fastpress.md)         | FastPress (keydown vs keyup)   |

### CombatQueue

| ID                                                 | Case                                        |
|----------------------------------------------------|---------------------------------------------|
| [TC-CQ-01](manual/TC-CQ-01-queue-during-combat.md) | Queue during combat, fire on leaving combat |
| [TC-CQ-02](manual/TC-CQ-02-queue-during-cast.md)   | Queue during cast, fire when cast ends      |
| [TC-CQ-03](manual/TC-CQ-03-cancel-queued-swap.md)  | Cancel queued swap via right-click          |
| [TC-CQ-04](manual/TC-CQ-04-loss-of-control.md)     | Queue during loss of control                |
| [TC-CQ-05](manual/TC-CQ-05-death-and-release.md)   | Queue survives death, fires when alive      |

### QuickChange

| ID                                                  | Case                        |
|-----------------------------------------------------|-----------------------------|
| [TC-QC-01](manual/TC-QC-01-add-rule.md)             | Add a QuickChange rule      |
| [TC-QC-02](manual/TC-QC-02-rule-triggers-on-use.md) | Rule triggers on item use   |
| [TC-QC-03](manual/TC-QC-03-delayed-rule.md)         | Delayed rule respects delay |
| [TC-QC-04](manual/TC-QC-04-remove-rule.md)          | Remove a rule               |

### Keybindings

| ID                                                        | Case                                   |
|-----------------------------------------------------------|----------------------------------------|
| [TC-KB-01](manual/TC-KB-01-set-keybinding-and-swap.md)    | Set keybinding, label shows, key swaps |
| [TC-KB-02](manual/TC-KB-02-keybinding-persists-reload.md) | Keybinding persists across /reload     |

### Drag & drop

| ID                                                | Case                         |
|---------------------------------------------------|------------------------------|
| [TC-DD-01](manual/TC-DD-01-drag-between-slots.md) | Drag between gearslots       |
| [TC-DD-02](manual/TC-DD-02-drag-from-bag.md)      | Drag from bag onto gearslot  |
| [TC-DD-03](manual/TC-DD-03-drag-unequip.md)       | Unequip by dragging into bag |

### Combined equip & unequip

| ID                                                          | Case                                  |
|-------------------------------------------------------------|---------------------------------------|
| [TC-CE-01](manual/TC-CE-01-combined-equip-right-click.md)   | Right-click equips into opposite slot |
| [TC-CE-02](manual/TC-CE-02-two-hand-vs-mainhand-offhand.md) | 2H ↔ MH/OH weapon combinations        |
| [TC-UN-01](manual/TC-UN-01-unequip-via-empty-slot.md)       | Unequip via empty ChangeMenu slot     |

### TrinketMenu

| ID                                                      | Case                                        |
|---------------------------------------------------------|---------------------------------------------|
| [TC-TM-01](manual/TC-TM-01-enable-and-show.md)          | Enable and show TrinketMenu                 |
| [TC-TM-02](manual/TC-TM-02-equip-trinket-left-right.md) | Left/right click equips upper/lower trinket |
| [TC-TM-03](manual/TC-TM-03-configuration-options.md)    | TrinketMenu configuration options           |

### Themes

| ID                                                | Case                                  |
|---------------------------------------------------|---------------------------------------|
| [TC-TH-01](manual/TC-TH-01-switch-theme.md)       | Theme switch confirmation and reload  |
| [TC-TH-02](manual/TC-TH-02-both-themes-render.md) | Slots render correctly in both themes |

### Profiles

| ID                                                       | Case                                  |
|----------------------------------------------------------|---------------------------------------|
| [TC-PR-01](manual/TC-PR-01-save-profile.md)              | Save current configuration as profile |
| [TC-PR-02](manual/TC-PR-02-apply-profile.md)             | Apply profile restores configuration  |
| [TC-PR-03](manual/TC-PR-03-rename-and-delete-profile.md) | Rename and delete a profile           |
| [TC-PR-04](manual/TC-PR-04-export-profile-string.md)     | Export produces profile string        |
| [TC-PR-05](manual/TC-PR-05-import-round-trip.md)         | Import round-trip                     |
| [TC-PR-06](manual/TC-PR-06-corrupted-import-rejected.md) | Corrupted import string rejected      |

### Macros / public API

| ID                                                            | Case                           |
|---------------------------------------------------------------|--------------------------------|
| [TC-MA-01](manual/TC-MA-01-add-to-combat-queue-macro.md)      | GM_AddToCombatQueue macro      |
| [TC-MA-02](manual/TC-MA-02-remove-from-combat-queue-macro.md) | GM_RemoveFromCombatQueue macro |
| [TC-EV-01](manual/TC-EV-01-swap-listener-events.md)           | Swap listener notifications    |

### Slash commands

| ID                                              | Case                  |
|-------------------------------------------------|-----------------------|
| [TC-CMD-01](manual/TC-CMD-01-slash-commands.md) | /rggm command surface |

### Season of Discovery (conditional)

| ID                                                          | Case                                    |
|-------------------------------------------------------------|-----------------------------------------|
| [TC-SOD-01](manual/TC-SOD-01-rune-display.md)               | Rune display on items                   |
| [TC-SOD-02](manual/TC-SOD-02-engraved-swap-combat-queue.md) | Engraved item swap through combat queue |
| [TC-SOD-03](manual/TC-SOD-03-macro-rune-ability-id.md)      | Macro with runeAbilityId                |

## 5. Notes

* Localization is covered by the busted spec `LocalizationParitySpec` (key parity of `deDE`,
  `zhCN`, `ruRU` against `enUS`) - no manual locale pass is required.
* Keep a copy of the previous release's `GearMenu.lua` SavedVariables file around - it is the
  input for [TC-SV-02](manual/TC-SV-02-upgrade-from-previous-release.md).
* SavedVariables live at
  `WTF/Account/<ACCOUNT>/<Server>/<Character>/SavedVariables/GearMenu.lua`.
  Only touch this file while the client is fully logged out.
