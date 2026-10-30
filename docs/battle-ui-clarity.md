# Battle UI and turn order

The battle screen now distinguishes the **round** from the active **player/enemy turn**. This describes the current Resolve-based flow; the alternating-action description in the older battle-loop document predates it.

- Select matching dice to build one action or combo. Short names remain visible on the dice, and unselected matching faces have a dashed outline.
- The preview shows the action's name, native effect, dice count, Resolve cost and whether you can act again. Tap it for damage breakdowns and conditional god/chisel effects.
- One or two dice cost one Resolve, three or four cost two, and five or six cost three. A large combo is one uninterrupted action, not alternating player/enemy exchanges.
- The complete player action resolves first. Enemies wait for End Turn, or follow automatically when the action spends the final Resolve. The button explicitly says **Play & End** in that case.
- A numbered, row-major grid shows every living enemy's announced move in actual execution order, without scrolling. Short landscape screens use up to five columns to fit nine moves. Tap a move for its full name, effects and forecast limitations.
- Announced enemy damage is before player Guard, Evade and reactive powers. Multi-hit moves display their hit count. Defeated enemies leave the queue; a delayed opening move returns next round.
- Guard sits beside the player's name in a fixed-height header, preventing health/name movement as protection changes. Guard values expire according to the existing combat rules.

The resolver and preview share the same player-first schedule. This also fixes a previous defect that discarded the selected player action when its cost exhausted Resolve, allowing enemies to act without that action landing.

## Planning and performance

- The hand is a central overlay, not a permanent shelf. Six large reels use their own full-width row; smaller Reroll and Play/End Turn controls sit underneath with 44-point touch targets.
- The console and enemy-order grid slide away during targeting, player attacks and the enemy phase. They return when the player can choose another action, keeping unspent dice and the current selection when backing out of targeting. Charge-collection flights complete before the console leaves.
- Fighters use the full stage height independently of the console. Packs retain larger artwork too. Targeting instructions and action announcements are low captions, leaving the centre clear for attacks and projectiles.
- The roll accelerates, spins and brakes into left-to-right detents, with a stronger individual landing bounce, gold rim flare and final tray kick. Existing lock audio and haptics stay synchronized to the actual results. Six reels finish in 1.92 seconds; Reduce Motion keeps its short, non-scrolling presentation (at most 0.30 seconds) and removes the tray kick.
- Resolve, player health and current Guard remain readable in the planning footer.

## Verification

- Full iOS unit/rendering suite: 72 tests passed (97 including parameterized runs) on the iPhone 17 Pro simulator (iOS 26.3).
- Added regressions for combo costs/order, stable three-enemy ordering as selection grows, final-Resolve damage, and victory before retaliation.
- Captured two-, four- and six-die previews at 660- and 960-point widths, plus complete nine-move consoles at 660, 752 and 1024 points.
- Added measured-fit tests for zero through nine moves on small landscape phones and tablets, bounded roll cadence tests, and full-screen planning/targeting/return captures.
- Manually checked the central hand, combo selection and combat handover on the iPhone 16e simulator in landscape.

Device playtesting is still needed for crowded boss fights, larger accessibility text, and longer runs with complex boon interactions. Target-dependent effects are intentionally described as conditional rather than guaranteed HP forecasts.
