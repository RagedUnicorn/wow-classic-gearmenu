# Release

> This document explains how a new release is created for GearMenu

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

> Note: When updating the addon for a new WoW release the following properties have to be updated in `pom.xml`
> * addon.curseforge.gameVersion
> * addon.interface
> * addon.supported.patch
