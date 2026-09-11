# TC-SV-02 — Upgrade from previous release migrates cleanly

**Area:** SavedVariables | **Client:** Era | **Mandatory:** yes

## Preconditions

- Client fully logged out
- The version bump for the release under test is already applied — `pom.xml` bumped and
  `mvn generate-resources -D generate.sources.overwrite=true` re-run, so `GearMenu.toc` carries
  the **new** `## Version:`. `SetAddonVersion()` stamps whatever the TOC says; without the bump
  the version expectation below can neither pass nor fail
- The previous release's schema fixture: `test/manual/fixtures/TC-SV-02-gearmenu-v2.7.0.lua`
- Backup of the test character's current `WTF/.../SavedVariables/GearMenu.lua` taken (to restore
  after the test)

## Steps

1. Copy the fixture over the character's `SavedVariables/GearMenu.lua` and delete `GearMenu.lua.bak`
2. Log in with the character
3. Observe the screen and chat for errors
4. Verify both gearbars render exactly as configured in the fixture:
   - **Default GearBar** — vertical, three slots (upper trinket, lower trinket, head), slot
     size 40, locked (not draggable), anchored `RIGHT` at -363.7 / -144.2
   - **Demo** — horizontal, four slots (head, feet, main hand, lower finger), gear slot size 47,
     change slot size 54, unlocked (draggable), anchored `LEFT` at 280.0 / 148.7
5. Open `/rggm opt` — the QuickChange page lists no rules, and the Profiles page lists exactly
   one profile named `Default`
6. Log out and inspect the SavedVariables file

## Expected

- No Lua errors on login; the defaults backfill (`ApplyConfigurationDefaults`) runs silently.
  The newest step in `MigrationPath()` is `UpgradeToV2_0_0()` and it only fires for pre-2.0.0
  versions — for a v2.7.0 file no migration step should run or log
- All v2.7.0 user data survives byte-for-byte: both `gearBars` entries (ids 130090 / 182509
  with their slots, sizes, positions, lock state, orientation and change menu direction), all
  scalar options, and the empty `quickChangeRules` / `frames` containers stay empty — no rules
  or frame positions are invented
- Fields introduced after v2.7.0 are present at their defaults:
  `enableFallbackToBaseItem = false`, `lastNotifiedVersion = ""`
- `GearMenuConfiguration.profiles` is created and holds **exactly one** entry named `Default`,
  seeded by `EnsureDefaultProfile()` as a snapshot of the shipped configuration defaults
  (re-seeded on every login so it always matches the running version) — **not** a snapshot
  of the imported v2.7.0 values. Save/Rename/Delete refuse to touch it (see TC-PR-07)
- `addonVersion` in the file is bumped to the new release version

## Notes

The v2.6.0 schema is not identical to v2.7.0 — v2.7.0 added per-gearBar `orientation` and
`changeMenuDirection` — so this fixture covers only the v2.7.0 hop. Upgrades from older
releases rely on the nil-backfill in `SetupConfiguration` plus `MigrationPath()` and are not
covered by this case.

Profiles did not exist in v2.7.0, which is why this case asserts that `profiles` is *created*
rather than *preserved*. When the next release ships, snapshot a fixture that does carry saved
profiles into `test/manual/fixtures/` alongside this one and extend the case to assert those
profiles survive unchanged.
