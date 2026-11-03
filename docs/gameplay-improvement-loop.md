# Gameplay improvement loop

This loop optimises for voluntary, satisfying playtime: clearer decisions, stronger build expression, varied encounters, and a compelling reason to try another run. It does not use forced waiting, punishment for leaving, opaque odds, or other manipulative retention patterns.

## The loop

1. **Play a fresh run on a phone-sized landscape simulator.** Continue at least through one reward and one route encounter; periodically continue to a herald, gate boss, and full-run ending.
2. **Record friction and delight at the moment they happen.** Separate clarity defects from balance defects and content gaps.
3. **Score the session.** Use the measures below and compare them with the previous build.
4. **Choose one high-confidence hypothesis.** Prefer a small change with a visible player outcome over a broad speculative rework.
5. **Implement with a regression.** Rules receive deterministic tests; layouts are checked at 660×320 and a current iPhone landscape size.
6. **Replay the affected loop.** Keep the change only when it improves the intended moment without weakening another one.
7. **Promote the next question.** Move from onboarding to early build, gate pacing, enemy variety, late-run progression, and replay motivation in that order.

## Session scorecard

| Signal | What to record | Healthy direction |
|---|---|---|
| Time to first meaningful choice | Launch to first plan decision | Down |
| Time to first payoff | Launch to first satisfying combo, upgrade, or discovery | Down |
| Decision density | Meaningful choices per five minutes | Up, without overload |
| Dead time | Time watching without a useful read or input | Down |
| Build expression | How often the chosen bag/upgrades change the best decision | Up |
| Encounter distinction | Enemies that demand a different answer | Up |
| Fairness | Damage and consequences that were legible beforehand | Up |
| Run momentum | Rewards that create a clear next goal | Up |
| Replay pull | New class, chain, route, god, or strategy worth trying | Up |

Also note the round count, health lost, rerolls used, skipped rewards, bag size, discovered chains, and whether a death felt earned.

## Iteration 1 — first-run friction and early build clarity

Live path: Archer class selection → opening briefing → Straw Effigy → die draft → Omen → permanent crit etching.

### What worked

- Matching faces visibly grew into a named, stronger action.
- The complete queued turn and announced enemy sequence were readable before commitment.
- Drafting a Yew Longbow and immediately etching its Arrow III face made the run feel personal after two encounters.
- The Omen offered a genuine risk, build, or economy choice rather than a cosmetic branch.

### Friction found

- Seven briefing pages delayed the first roll and repeated class/story information already shown elsewhere.
- The briefing still instructed players to drag dice and use a minus control, contradicting the current tap-to-remove interaction.
- The important interactive dice row initially began below the fold on a phone-sized landscape screen.
- A die reward did not show that the bag would grow while the hand remained six, hiding the consistency cost of taking every reward.

### Changes kept

- Four decision-focused briefing pages: build a turn, spend Resolve/reroll, read intent, shape the next draw.
- Two-column interactive lesson so the plan and all six demo faces are visible without scrolling.
- Explicit tap-to-remove and left-to-right resolution copy.
- Reward header previews `BAG 10 → 11 · DRAW 6 EACH TURN`, with a focused-bag reminder before selection and swap messaging at the cap.
- Regression coverage keeps the briefing at four pages and rejects the obsolete interaction copy.

## Iteration 2 — hold, redraw, and interleave

Live loops: three practice rounds using one-, two-, and three-action plans; reward Skip; then a Silt Colossus round with Focus, a two-die Piercing Bolt, two full hand refreshes, and a Heavy Shot placed before the announced guard.

### What worked

- Locking a finished action and rerolling every unused die made each pull produce a new decision instead of asking which single weak die to replace.
- Two pulls were enough to build in stages without making the best hand feel guaranteed.
- Automatic player/enemy alternation created a useful schedule immediately; manual Earlier/Later controls were only needed for a deliberate tactic.
- Moving Focus and Piercing Bolt ahead of Wide Sweep, then placing Heavy Shot between Wide Sweep and the enemy guard, made enemy intent affect the exact plan rather than only the amount of Block to take.
- Numbered badges on both the dice and shared timeline kept three player actions plus three enemy moves readable without scrolling.

### Friction found

- `ROLL UNUSED` clipped in the compact control.
- The timeline wrapped after four entries even though a landscape phone still had enough horizontal room, shrinking the dice unnecessarily.
- Class and rules copy still described one selective reroll and a player-first handover.

### Changes kept

- Two `ROLL REST` pulls per turn. Queued dice remain locked; all other dice reroll together for one charge.
- One exact timeline for player actions and enemy intent. Separate actions default into alternating enemy gaps and can be moved Earlier or Later before Go.
- The resolver consumes the displayed schedule, so late Guard cannot prevent an earlier strike.
- Up to six timeline beats stay on one compact row; seven through twelve use two rows, with no horizontal scrolling.
- Deterministic coverage for locked-dice rerolls, default interleaving, manual placement, and the gameplay consequence of late defence.

## Ranked questions for the next iterations

1. Does a bag above 14–16 dice still feel like a build, or does mandatory-looking drafting dilute it into noise?
2. Do Reeds enemies create distinct defensive decisions, or are their telegraphs different names for the same answer?
3. Does the first herald arrive soon enough to create a memorable difficulty peak?
4. Are god paths and Chisels encountered early enough for a run to develop an identity before its midpoint?
5. Beyond persistent chain discovery and records, what unlock gives a finished or failed run a specific reason to start another?

## Iteration 3 — timeline editing and focused rewards

The next planning revision responds to player feedback: the separate selected-action editor duplicated the timeline and made both areas small. The shared timeline now carries the Resolve cost on each player action and accepts drag placement, including reordering actions in the same enemy gap. A visible budget shows planned Resolve and remaining capacity. Selected dice use the same blue as player actions and show their numbered beat.

Reviewing the execution path also found three fairness defects: Delay could repeat an already-executed enemy action, moving a Dodge could leave it assigned to a strike that had passed, and enemy Bleed forecasts could disagree with the documented two-tick, capped effect. Reordering also needs first-attack bonuses and Focus to follow the displayed sequence. These cases are covered by battle-level regressions.

The bag-dilution question remains a playtest hypothesis: a six-die opening hand is less likely to contain a particular die as the bag grows. Combat die rewards now offer an optional replacement alongside adding or skipping, showing the unchanged bag size and consequences of removing a blessing or etching. A longer run is still needed to evaluate how often replacement feels worthwhile and whether its presentation is clear at compact sizes.

The route and god audit found that shrines silently chose a random god and several older patron, Trial and Chisel paths were unreachable. This iteration makes the shrine's god a player choice, shows owned powers, and keeps each visited god's exact offers stable through Back and save/resume. Route cards explain the immediate payoff and risk; the opening now always leads to the promised practice battle. The actual reward economy still needs longer-run testing before numerical balance changes, and Trials and Chisels remain follow-up work.

## Next iteration — a herald reward that shapes the build

Chisels have class-specific effects, but the current combat and shrine reward paths never call the Chisel offer generator. A new run therefore has no ordinary way to earn them. The first herald is a natural point to introduce this kind of build-defining reward: test a choice of three unowned class Chisels after that victory, followed by the normal die draft. Skipping the Chisel should still lead to the die choice, and the screen must make the two steps clear. Keep later Chisel availability and balance as separate questions until a longer run has been played.

This needs a save-safe staged reward, not just a second screen. Persist the won node, post-fight health and gold, the current reward step, and the exact pre-rolled Chisel and die offers. Resuming or cancelling a die replacement should return to the same unfinished choice without repeating the fight, rerolling offers, paying gold twice, or granting another Chisel. Only clear the encounter after the die draft is completed or skipped. Keep old saves readable when the new snapshot is absent.

Before keeping the change, test claiming and skipping each step; saving and resuming at both steps and during die replacement; duplicate, class and capacity constraints; and the existing save format. Then play through the herald and its rewards on a compact phone layout, recording the health spent, the chosen Chisel's impact on later decisions, and whether both rewards feel worth the extra screen.

## Omen fairness follow-up

Code review found two wagers advertising fixed rewards while their actual gold payout scaled with run progress. Their displayed odds, damage, and gold now derive from the same reward data used to resolve the wager. The Standing Idol now describes its random power (and possible gold fallback or slot replacement), and its power pool excludes effects the current loadout cannot use. Deterministic tests cover wager descriptions across early, middle, and late progress. A live Omen replay and the staged herald/Trial work remain outstanding.

