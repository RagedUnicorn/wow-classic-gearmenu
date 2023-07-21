# Feature

* Fix: #70 - Adding support for enchantIds to the Addon
  * GearMenu supports itemEnchantIds in QuickChangeRules, ChangeMenu, GearBars and TrinketMenu. This means that items with the same id but different enchant ids will no longer be treated as the same item. Instead, GearMenu also compares the enchant id when looking for items.
  * Note: All existing QuickChangeRules will have no itemEnchantId set. It is best to recreate the rule if those items have an enchant that is relevant otherwise old rules should still work. Items in the QuickChange can now be hovered to get a detailed tooltip with the enchant id.
