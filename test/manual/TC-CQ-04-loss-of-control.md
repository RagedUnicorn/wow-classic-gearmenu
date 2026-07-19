# TC-CQ-04 — Queue during loss of control

**Area:** CombatQueue | **Client:** Era | **Mandatory:** yes

## Preconditions

- A repeatable loss-of-control effect on the player. Out-of-combat options: another player's
  sap/fear in a duel, or a mob with a stun/fear. (Any effect that triggers
  `LOSS_OF_CONTROL_ADDED` works.)

## Steps

1. Get affected by the loss-of-control effect
2. While under the effect (and otherwise out of combat), click an alternative item in the ChangeMenu
3. Wait for the effect to expire

## Expected

- While under loss of control the swap is queued, not executed
- Once the effect ends (`LOSS_OF_CONTROL_UPDATE` clears the block flag), the queued swap
  fires as soon as no other block (combat/cast) applies
- The queued-item overlay clears
