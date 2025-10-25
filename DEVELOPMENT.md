# Development

#### Invtypes

A list of invtypes that are relevant to the addon

INVTYPE_HEAD
INVTYPE_NECK
INVTYPE_SHOULDER
INVTYPE_CHEST
INVTYPE_ROBE
INVTYPE_WAIST
INVTYPE_LEGS
INVTYPE_FEET
INVTYPE_WRIST
INVTYPE_HAND
INVTYPE_FINGER
INVTYPE_TRINKET
INVTYPE_CLOAK
INVTYPE_WEAPON
INVTYPE_SHIELD
INVTYPE_2HWEAPON
INVTYPE_WEAPONMAINHAND
INVTYPE_WEAPONOFFHAND
INVTYPE_HOLDABLE
INVTYPE_RANGED
INVTYPE_THROWN
INVTYPE_RANGEDRIGHT
INVTYPE_RELIC
INVTYPE_AMMO


#### SlotTypes

A list of slotTypes that are relevant to the addon

* INVSLOT_HEAD
* INVSLOT_NECK
* INVSLOT_SHOULDER
* INVSLOT_CHEST
* INVSLOT_WAIST
* INVSLOT_LEGS
* INVSLOT_FEET
* INVSLOT_WRIST
* INVSLOT_HAND
* INVSLOT_FINGER1
* INVSLOT_FINGER2
* INVSLOT_TRINKET1
* INVSLOT_TRINKET2
* INVSLOT_BACK
* INVSLOT_MAINHAND
* INVSLOT_OFFHAND
* INVSLOT_RANGED
* INVSLOT_AMMO

## Development Tools

### Docker Compose Services

The project includes Docker Compose services for development and validation tasks. Each service is containerized and requires no local setup beyond Docker.

**Available Services:**

```bash
# Code Quality
docker compose run --rm luacheck                    # Run lua linting
docker compose run --rm luacheck-report             # Generate lua lint report
```

**Output Files:**
Services with "-report" suffix generate output files in the `./target/` directory:
- `./target/luacheck-junit.xml` - Luacheck results in JUnit format

### Running Luacheck

The project uses [Luacheck](https://github.com/lunarmodules/luacheck), a static analyzer and linter for Lua, to ensure code quality and catch common issues.

**To run Luacheck:**

```bash
docker compose run --rm luacheck
```

This will:
- Mount the project directory as read-only
- Run Luacheck on all Lua files
- Output any warnings or errors found

**To generate a report:**
```bash
docker compose run --rm luacheck-report
```

This generates a JUnit XML report in `./target/luacheck-junit.xml`.

**Configuration:**
- `.luacheckrc` - Contains Luacheck configuration, including:
  - Global variables specific to WoW addons
  - Lua 5.1 standard for compatibility
  - Excluded directories (e.g., `target/`, `tools/`)

### Testing and Code Quality

Before committing changes:

1. Run Luacheck to ensure code quality: `docker compose run --rm luacheck`
2. Test the addon in-game with `/reload` to ensure functionality works correctly
3. Verify the addon loads without errors

## Dependency Management

This repository uses [Renovate](https://renovatebot.com/) for automated dependency updates. Renovate monitors and updates:

- Maven dependencies (plugins and libraries)
- GitHub Actions versions
- World of Warcraft interface versions and related properties
  - `addon.interface` - WoW interface version
  - `addon.supported.patch` - WoW patch version
  - `addon.curseforge.gameVersion` - CurseForge game version ID

The configuration can be found in `renovate.json`. Renovate runs on a weekly schedule and creates pull requests for available updates.
