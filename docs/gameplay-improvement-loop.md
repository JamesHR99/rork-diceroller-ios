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

## Ranked questions for the next iterations

1. Does a bag above 14–16 dice still feel like a build, or does mandatory-looking drafting dilute it into noise?
2. Do Reeds enemies create distinct defensive decisions, or are their telegraphs different names for the same answer?
3. Does the first herald arrive soon enough to create a memorable difficulty peak?
4. Are god paths and Chisels encountered early enough for a run to develop an identity before its midpoint?
5. Beyond persistent chain discovery and records, what unlock gives a finished or failed run a specific reason to start another?

