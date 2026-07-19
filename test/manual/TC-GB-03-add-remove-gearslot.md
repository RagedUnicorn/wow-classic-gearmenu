# TC-GB-03 — Add and remove gearslots

**Area:** GearBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- A gearbar exists

## Steps

1. Open the gearbar's configuration sub-menu in `/rggm opt`
2. Add a new gearslot and assign it a slot type (e.g. FeetSlot)
3. Verify the slot renders on the bar showing the currently equipped item
4. Change the slot type to a different slot (e.g. HandsSlot)
5. Remove the gearslot again

## Expected

- Adding a slot immediately extends the bar; the slot shows the equipped item of its slot type
- Changing the slot type updates the displayed item/texture
- Removing the slot shrinks the bar; remaining slots keep their configuration
- All changes survive `/reload`
