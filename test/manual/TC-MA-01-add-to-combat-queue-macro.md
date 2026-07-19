# TC-MA-01 — GM_AddToCombatQueue macro

**Area:** Macro API | **Client:** Era | **Mandatory:** yes

## Preconditions

- A trinket in the bags whose itemId is known (e.g. via wowhead)
- `GM_AddToCombatQueue` is part of the public API contract — this case guards it

## Steps

1. Create a macro: `/run GM_AddToCombatQueue(<itemId>, 0, 0, 14)`
   (14 = lower trinket slot; enchantId/runeAbilityId 0)
2. Out of combat: run the macro
3. Enter combat and run the macro with a different eligible item

## Expected

- Out of combat: the item is equipped into the lower trinket slot immediately
- In combat: the swap is queued (queued-item overlay on the matching gearslot if the slot is
  on a bar) and fires after leaving combat
- No Lua errors; invalid itemIds fail gracefully with a logged/user error, not a crash
