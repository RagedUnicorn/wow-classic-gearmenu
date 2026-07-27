--[[
  SavedVariables fixture for TC-SV-02 - upgrade from the previous release.

  This is the v2.7.0 configuration schema: no profiles, no
  enableFallbackToBaseItem flag, no update notifier bookkeeping
  (lastNotifiedVersion). It was recorded with a real client running the
  v2.7.0 build: two gearbars - "Default GearBar" (locked, vertical, three
  slots) and "Demo" (unlocked, horizontal, four slots) - each with their
  own position, sizes and change menu direction.

  Copy this file to

    WTF/Account/<ACCOUNT>/<Realm>/<Character>/SavedVariables/GearMenu.lua

  while the client is fully closed. Comments are stripped the next time WoW
  rewrites the file - that is expected, this is a source fixture, not output.

  Do not regenerate this file against a newer build. When the next release
  ships, add a sibling fixture for that schema instead and keep this one as is.
]]--

GearMenuConfiguration = {
["enableDragAndDrop"] = true,
["trinketMenuSlotSize"] = 40,
["trinketMenuShowCooldowns"] = true,
["filterItemQuality"] = 2,
["frames"] = {
},
["enableTrinketMenu"] = true,
["lockTrinketMenuFrame"] = false,
["enableFastPress"] = false,
["enableSimpleTooltips"] = false,
["enableTooltips"] = true,
["enableUnequipSlot"] = true,
["enableRuneSlots"] = true,
["addonVersion"] = "v2.7.0",
["gearBars"] = {
{
["showKeyBindings"] = true,
["id"] = 130090,
["slots"] = {
{
["type"] = {
"INVTYPE_TRINKET",
},
["name"] = "slot_name_upper_trinket",
["inventoryTypeId"] = 11,
["simplifiedName"] = "slot_name_trinket",
["slotId"] = 13,
["textureId"] = 136528,
},
{
["type"] = {
"INVTYPE_TRINKET",
},
["name"] = "slot_name_lower_trinket",
["inventoryTypeId"] = 11,
["simplifiedName"] = "slot_name_trinket",
["slotId"] = 14,
["textureId"] = 136528,
},
{
["type"] = {
"INVTYPE_HEAD",
},
["name"] = "slot_name_head",
["inventoryTypeId"] = 1,
["slotId"] = 1,
["textureId"] = 136516,
},
},
["displayName"] = "Default GearBar",
["isLocked"] = true,
["changeMenuDirection"] = 4,
["position"] = {
["relativePoint"] = "RIGHT",
["posY"] = -144.1609497070313,
["point"] = "RIGHT",
["posX"] = -363.74365234375,
},
["orientation"] = 2,
["showCooldowns"] = true,
["changeSlotSize"] = 40,
["gearSlotSize"] = 40,
},
{
["showKeyBindings"] = true,
["id"] = 182509,
["slots"] = {
{
["type"] = {
"INVTYPE_HEAD",
},
["name"] = "slot_name_head",
["slotId"] = 1,
["textureId"] = 136516,
},
{
["type"] = {
"INVTYPE_FEET",
},
["inventoryTypeId"] = 7,
["name"] = "slot_name_feet",
["slotId"] = 8,
["textureId"] = 136513,
},
{
["type"] = {
"INVTYPE_WEAPONMAINHAND",
"INVTYPE_2HWEAPON",
"INVTYPE_WEAPON",
},
["inventoryTypeId"] = 13,
["name"] = "slot_name_main_hand",
["slotId"] = 16,
["textureId"] = 136518,
},
{
["type"] = {
"INVTYPE_FINGER",
},
["inventoryTypeId"] = 10,
["name"] = "slot_name_lower_finger",
["simplifiedName"] = "slot_name_finger",
["slotId"] = 12,
["textureId"] = 136514,
},
},
["displayName"] = "Demo",
["isLocked"] = false,
["position"] = {
["relativePoint"] = "LEFT",
["posY"] = 148.6615142822266,
["point"] = "LEFT",
["posX"] = 280.0025939941406,
},
["showCooldowns"] = true,
["orientation"] = 1,
["changeMenuDirection"] = 1,
["changeSlotSize"] = 54,
["gearSlotSize"] = 47,
},
},
["uiTheme"] = 2,
["trinketMenuColumns"] = 4,
["quickChangeRules"] = {
},
["firstTimeInitializationDone"] = true,
}
