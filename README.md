# GearMenu

![](/docs/gm_ragedunicorn_love_classic.png)

> GearMenu aims to help the player switching between items in and out of combat. When the player is in combat a combatqueue will take care of switching the item as soon as possible. It also allows you to define switching rules and keybinding slots.

![](/docs/wow_badge.png)
[![](/docs/twitch_badge.png)](https://www.curseforge.com/wow/addons/gearmenu)
![](/docs/license_mit.png)

## Installation

WoW-Addons are installed directly into your WoW directory:

`[WoW-installation-directory]\Interface\AddOns`

Make sure to get the newest version of the Addon from the releases tab:

[GearMenu-Releases](https://github.com/RagedUnicorn/wow-classic-gearmenu/releases)

> Note: If the Addon is not showing up in your ingame Addonlist make sure that the Addon is named `GearMenu` in your Addons folder

## What is GearMenu?

GearMenus goal is to help the player switching between items on certain slots. Often players have items such as engineering items that have a one time use followed by a long cooldown. After using them during a fight the player wants to switch back to a more useful item. While changing items during combat is not possible (with some exceptions such as weapons) GearMenu can help with switching them as soon as possible. When a player tries to switch an item during combat it will be put into the combatqueue and switched as soon as possible. If the player leaves combat for just a split second all the items in the combatqueue will be switched. For some classes this might be even easier because they can use spells such as rogue - vanish or hunter - feign death.

**Supported slots:**

| Slotname          | Description                  |
|-------------------|------------------------------|
| HeadSlot          | Head/Helmet slot             |
| NeckSlot          | Neck slot                    |
| ShoulderSlot      | Shoulder slot                |
| ChestSlot         | Chest/Robe slot              |
| WaistSlot         | Waist/Belt slot              |
| LegsSlot          | Legs slot                    |
| FeetSlot          | Feet/Boots slot              |
| WristSlot         | Wrist/Bracers slot           |
| HandsSlot         | Hands slot                   |
| Finger0Slot       | First/Upper Ring slot        |
| Finger1Slot       | Second/Upper Ring slot       |
| Trinket0Slot      | First/Upper Trinket slot     |
| Trinket1Slot      | Second/Lower Trinket slot    |
| BackSlot          | Back/Cloak slot              |
| MainhandSlot      | Main-hand slot               |
| SecondaryHandSlot | Secondary-hand/Off-hand slot |
| RangedSlot        | Ranged slot                  |
| AmmoSlot          | Ammo slot                    |

## Features of GearMenu

### Item switch for certain slots

With GearMenu it is easy to switch between items in supported slots. This is especially useful for engineering items that you wear for a certain amount of time and then switch back to your usual gear.

![](/docs/gm_switch_items.gif)

### CombatQueue

Certain items cannot be switched while the player is in combat. Weapons will be switched immediately whether the player is in combat or not. Other items that cannot be switched in combat will be enqueued in the combatqueue and switched as soon as possible. This is especially useful in PvP when you leave combat for a short time.

![](/docs/gm_combat_queue.gif)

> Note: You can right click any slot to clear the combatqueue for that slot

![](/docs/gm_combat_queue_cancel.gif)

GearMenu also detects whether an itemswitch is possible even when out of combat. If you're switching an item while you're casting your mount or any other spell it will put the item in the combatqueue. As soon as the cast is over the item will be switched.

![](/docs/gm_combat_queue_cast.gif)

This is also the case if you cancel your cast.

![](/docs/gm_combat_queue_cast_cancel.gif)

### Quick Change

Quick change consists of rules that apply when certain items are used. The player can define rules for items that have a usable effect. An item might be immediately switched after use or only after a certain delay. Otherwise the same rules for item switching apply. This means that if the user is in combat it will be moved to the combat queue and if he is out of combat the item will be immediately switched. See the optionsmenu for defining new rules based on the item type.

> Note: If an item has a buff effect and you immediately change the item you will usually also lose its buff. In most cases it makes sense to set the delay to the duration of the buff

![](/docs/gm_quick_change_add_rule.gif)

### Keybinding

GearMenu allows to keybind to every slot with a keybinding. Instead of having a keybind for every item that you have to remember you set it directly on the slot itself.

![](/docs/gm_keybinding.gif)

### Drag and drop support

GearMenu allows to drag and drop items onto slots, remove from slots and slots can even be switched in between.

#### Drag and drop between slots

![](/docs/gm_drag_and_drop_slots.gif)

#### Drag and drop item to GearMenu

![](/docs/gm_drag_and_drop_equip.gif)

#### Unequip item by drag and drop

![](/docs/gm_drag_and_drop_unequip.gif)

### Macro Support

If you prefer having certain items in your actionslots GearMenu can still be of use. By using the macro-bridge you get all the advantages of the combatQueue in a normal macro.

#### Add Item to CombatQueue
```
/run GM_AddToCombatQueue(itemId, slotId)

# Example - Equip Hand of Justice into the lower trinket slot
/run GM_AddToCombatQueue(11815, 14)
```

> Note: It is not recommended to use this for weapons because addons cannot switch weapons during combat (GearMenu will put the item into the combatQueue). With a normal weaponswitch macro however this is still possible.

#### Clear Slot From CombatQueue
```
/run GM_RemoveFromCombatQueue(slotId)

# Example - Clear headSlot queue
/run GM_AddToCombatQueue(1)
```

##### Finding itemId

Finding the id of a certain item is easiest with websites such as [wowhead](https://classic.wowhead.com/).

```
# Example:
https://classic.wowhead.com/item=11815/hand-of-justice
```

The number after item is the itemId we search for.

##### Finding slotId

For finding the correct slotId refer to the image below. Only InventorySlotIds are valid targets for GearMenu

![](/docs/gm_interface_slots.png)

## Configurability

GearMenu is configurable. Don't need a certain slot? You can hide it.

To show the configuration screen use `/rggm opt` while ingame and `/rggm info` for an overview of options or check the standard blizzard addon options.

### Hide/Show Cooldowns

![](/docs/gm_options_cooldowns.gif)

### Hide/Show Keybindings

![](/docs/gm_options_keybindings.gif)

### Lock/Unlock Window

![](/docs/gm_options_lock_window.gif)

### Fastpress Support

Enable whether an item in a Gearslot should be used when the player pressed down(keydown) or only after the key was released(keyup).

### Filter Items by Quality

Not interested to see items with a quality level below a certain level? Filter them out and only items that meet your set level will be considered to be displayed in GearMenu.

![](/docs/gm_options_filter_item_quality.gif)

## FAQ

#### The Addon is not showing up in WoW. What can I do?

Make sure to recheck the installation part of this Readme and check that the Addon is placed inside `[WoW-installation-directory]\Interface\AddOns` and is correctly named as `GearMenu`.

#### I get a red error (Lua Error) on my screen. What is this?

This is what we call a Lua error and it usually happens because of an oversight or error by the developer (in this case me). Take a screenshot off the error and create a Github Issue with it and I will see if I can resolve it. It also helps if you can add any additional information of what you we're doing at the time and what other addons you have active. Also if you are able to reproduce the error make sure to check if it still happens if you disable all others addons.

#### GearMenu spams my chat with messages. How can I deactivate this?

Those obnoxious messages are intended for the development of this addon and means that you download a development version of the addon instead of a proper release. Releases can be downloaded from here - https://github.com/RagedUnicorn/wow-classic-gearmenu/releases

#### A certain item is not showing up when I hover a slot. Why is that?

GearMenu filters by default, items that are below common (green) quality. This can be changed in the addon configuration settings in the option "Filter Item Quality".

#### GearMenu failed to switch my item. What happened?

There are certain limitations that make it harder to switch an item even if the player is out of combat. One such example is that WoW prevents switching items while the player is casting a spell. GearMenu detects this and changes the item as soon as there is a pause between two spells or if a spell was cancelled. Just keep this in mind if you absolutely need the item switch to happen as soon as possible. Another factor can be a loss of control effect such as sap, iceblock and similar effects. In such circumstances it is not possible to switch an item. GearMenu is aware of such effects on the player and will switch the item as soon as possible.

If you still think you found an issue where GearMenu doesn't switch items as expected feel free to create an [issue](https://github.com/RagedUnicorn/wow-classic-gearmenu/issues).

#### Why can't I switch Weapons during Combat?

This is a limitation that Blizzard puts on addons. It is not currently possible to switch to an arbitrary weapon while in combat. It is however possible to create weaponswitch macros because it is already known from which weapon to what weapon the player wants to switch. While it is not ideal, to workaround this issue GearMenu puts weapons in the CombatQueue if a weaponswitch is done while the player is in combat. If he is not in combat the switch will happen immediately. This might be improved in a future release if there is a better workaround possible.

> Note: It is also possible to switch a weapon by drag an dropping the weapon in the standard Blizzard interfaces. This however is in no way connected to GearMenu

#### Why can't I create an Itemset?

This addon does not have the intention on supporting the functionality of switching between a PVE and a PVP set (or any other set). Its intention is to assist the player in switching single items fast and possibly during combat. It does not try to be the next Outfitter addon.

## Development

### Switching between Environments

Switching between development and release can be achieved with maven.

```
mvn generate-resources -Dgenerate.sources.overwrite=true -P development
```

This generates and overwrites `GM_Environment.lua` and `GearMenu.toc`. You need to specifically specify that you want to overwrite to files to prevent data loss. It is also possible to omit the profile because development is the default profile that will be used.

Switching to release can be done as such:

```
mvn generate-resources -Dgenerate.sources.overwrite=true -P release
```

In this case it is mandatory to add the release profile.

**Note:** Switching environments has the effect changing certain files to match an expected value depending on the environment. To be more specific this means that as an example test and debug files are not included when switching to release. It also means that variables such as loglevel change to match the environment.

As to not change those files all the time the repository should always stay in the development environment. Do not commit `GearMenu.toc` and `GM_Environment.lua` in their release state. Changes to those files should always be done inside `build-resources` and their respective template files marked with `.tpl`.

### Packaging the Addon

To package the addon use the `package` phase.

```
mvn package -Dgenerate.sources.overwrite=true -P development
```

This generates an addon package for development. For generating a release package the release profile can be used.

```
mvn package -Dgenerate.sources.overwrite=true -P release
```

**Note:** This packaging and switching resources can also be done one after another.

**Note:** The packaging is not fit to be used for twitch because twitch expects a specific packaging

```
# switch environment to release
mvn generate-resources -Dgenerate.sources.overwrite=true -P release
# package release
mvn package -P release
```

### Deploy GitHub Release

Before creating a new release update `addon.tag.version` in `pom.xml`. Afterwards to create a new release and deploy to GitHub the `deploy` profile has to be used.

```
# switch environment to release
mvn generate-resources -Dgenerate.sources.overwrite=true -P release
# deploy release
mvn package -P deploy-github
```

For this to work an oauth token for GitHub is required and has to be configured in your `.m2` settings file.

### Deploy Twitch Release

**Note:** Its best to create the release for GitHub first and only afterwards the twitch release. That way the tag was already created.

```
# switch environment to release
mvn generate-resources -Dgenerate.sources.overwrite=true -P release
# deploy release
mvn package -P deploy-twitch
```

## License

MIT License

Copyright (c) 2020 Michael Wiesendanger

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
