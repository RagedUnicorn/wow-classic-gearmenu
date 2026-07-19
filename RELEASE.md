# Release

> This document explains how a new release is created for GearMenu

## Pre-release testing

Complete the test procedure in [test/TESTING.md](test/TESTING.md) before creating any deployment:

* Automated gates - luacheck and busted must be green (locally and in CI)
* Full manual test case catalog ([test/manual/](test/manual/)) on Classic Era
* Smoke checklist on TBC Anniversary and MoP Classic
* `TC-SOD-*` cases if a Season of Discovery character is available or SoD code was touched

## Deployment

Push all commits before proceeding
* Make sure `build-resources/release-notes.md` are up-to-date
* Make sure Metadata https://github.com/RagedUnicorn/wow-gearmenu-meta is up-to-date
* Create a GitHub deployment
  * Invoke GitHub action
    * https://github.com/RagedUnicorn/wow-classic-gearmenu/actions/workflows/release_github.yaml
* Create a CurseForge deployment
  * Invoke CurseForge action
    * https://github.com/RagedUnicorn/wow-classic-gearmenu/actions/workflows/release_curseforge.yaml
* Create a Wago.io deployment
  * Invoke GitHub action
    * https://github.com/RagedUnicorn/wow-classic-gearmenu/actions/workflows/release_wago.yaml
