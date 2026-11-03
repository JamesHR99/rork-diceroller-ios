# Battle UI and turn order

The battle screen distinguishes the **round** from each action on a shared, editable timeline.

- Tap dice in the order you want to play them. Adjacent matching dice build a combo; a different face appends another action without replacing the plan. Tapping a queued die removes it and rebuilds the affected combos.
- Player actions and enemy intent share one numbered timeline. Dice carry the beat their action belongs to; select a blue action and move it Earlier or Later before pressing Go.
- One or two dice cost one Resolve, three or four cost two, and five or six cost three. A large combo is one uninterrupted action, not alternating player/enemy exchanges.
- **Go** is the only play control. It commits the complete visible schedule, even with unused Resolve. Merely selecting a full budget never starts combat. Over-budget plans cannot commit; remove dice to bring the cost down. An empty plan passes.
- A numbered, row-major grid shows every player action and every living enemy move in actual execution order, without scrolling. Short landscape screens add columns to keep the full round visible. Tap an enemy for detail; select a blue player chip to move it.
- Announced enemy damage is before player Guard, Evade and reactive powers. Multi-hit moves display their hit count. Defeated enemies leave the queue; a delayed opening move returns next round.
- Guard sits beside the player's name in a fixed-height header, preventing health/name movement as protection changes. Guard values expire according to the existing combat rules.

The resolver consumes the same interleaved schedule the preview displays. A separate action may land before, between or after enemy moves; an individual combo remains uninterrupted.

## Planning and performance

- The hand is a central overlay, not a permanent shelf. Six large reels use their own full-width row; smaller Roll Unused and Go controls share the timeline editor, with 44-point touch targets.
- The console stays visible while you build the whole turn. After Go, it slides away once for targeting and remains away through the complete timeline, returning for the next round's hand. Backing out of targeting restores the complete plan without spending Resolve. Charge-collection flights complete before the console leaves.
- Fighters use the full stage height independently of the console. Packs retain larger artwork too. Targeting instructions and action announcements are low captions, leaving the centre clear for attacks and projectiles.
- The roll accelerates, spins and brakes into left-to-right detents, with a stronger individual landing bounce, gold rim flare and final tray kick. Existing lock audio and haptics stay synchronized to the actual results. Six reels finish in 1.92 seconds; Reduce Motion keeps its short, non-scrolling presentation (at most 0.30 seconds) and removes the tray kick.
- A dedicated health rail above the dice always shows player HP/Guard and each living enemy's HP. Go shows the plan's total Resolve cost against the available budget.

## Verification

- Full iOS unit/rendering suite: 78 tests passed (103 including parameterized runs) on the iPhone 17 Pro simulator (iOS 26.3.1).
- Added regressions for combo costs/order, stable three-enemy ordering as selection grows, final-Resolve damage, and victory before retaliation.
- Timeline regressions verify automatic alternation, manual Earlier/Later placement, late-defence consequences, locked-dice rerolls, no intermediate planning phase, over-budget rejection/removal, and multiple-target aiming/cancel restoration.
- Captured two-, four- and six-die previews at 660- and 960-point widths, plus complete nine-move consoles at 660, 752 and 1024 points.
- Added measured-fit tests for zero through nine moves on small landscape phones and tablets, bounded roll cadence tests, and full-screen planning/targeting/return captures.
- Manually checked the central hand, combo selection and combat handover on the iPhone 16e simulator in landscape.

Device playtesting is still needed for crowded boss fights, larger accessibility text, and longer runs with complex boon interactions. Target-dependent effects are intentionally described as conditional rather than guaranteed HP forecasts.
