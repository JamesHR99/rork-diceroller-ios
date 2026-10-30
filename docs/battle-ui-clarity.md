# Battle UI and turn order

The battle screen now distinguishes the **round** from the active **player/enemy turn**. This describes the current Resolve-based flow; the alternating-action description in the older battle-loop document predates it.

- Select matching dice to build one action or combo. Short names remain visible on the dice, and unselected matching faces have a dashed outline.
- The preview shows the action's name, native effect, dice count, Resolve cost and whether you can act again. Tap it for damage breakdowns and conditional god/chisel effects.
- One or two dice cost one Resolve, three or four cost two, and five or six cost three. A large combo is one uninterrupted action, not alternating player/enemy exchanges.
- The complete player action resolves first. Enemies wait for End Turn, or follow automatically when the action spends the final Resolve. The button explicitly says **Play & End** in that case.
- A shared horizontal queue numbers every living enemy's announced moves in actual execution order. Tap a move for its effects and forecast limitations. The acting entry is highlighted and completed entries are checked off.
- Announced enemy damage is before player Guard, Evade and reactive powers. Multi-hit moves display their hit count. Defeated enemies leave the queue; a delayed opening move returns next round.
- Guard sits beside the player's name in a fixed-height header, preventing health/name movement as protection changes. Guard values expire according to the existing combat rules.

The resolver and preview share the same player-first schedule. This also fixes a previous defect that discarded the selected player action when its cost exhausted Resolve, allowing enemies to act without that action landing.

## Verification

- Full iOS unit/rendering suite: 69 tests passed on the iPhone 17 Pro simulator (iOS 26.3).
- Added regressions for combo costs/order, stable three-enemy ordering as selection grows, final-Resolve damage, and victory before retaliation.
- Captured two-, four- and six-die previews at 660- and 960-point widths.
- Manually checked combo selection, Block, Guard header stability, enemy handover and active queue highlighting on the iPhone 16e simulator in landscape.

Device playtesting is still needed for crowded boss fights, larger accessibility text, and longer runs with complex boon interactions. Target-dependent effects are intentionally described as conditional rather than guaranteed HP forecasts.
