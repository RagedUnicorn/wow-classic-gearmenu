# Features

* Add support for scaling gearmenu slots. There is a new option to change the size of the gearslots. Related items will automatically adapt to the chosen size
* Add support for adding items to the combat queue while the player is casting. Gearmenu now detects when the player is casting while he tries to change an item and puts that item in the combatqueue until the cast is finished or the player aborts the cast
* Add support for 'Fastpress' in the addon configuration. This feature allows to activate items on keypress down instead of keypress up
* Increase the maximum of supported items in the changemenu to 20

# Bugfixes

* #20 Fixed a bug where items such as wands, crossbows and throw weapons wouldn't show up as possible items to switch to
* #27 #32 Fixed a bug where certain items clashed with items that had a partial id match with other items
