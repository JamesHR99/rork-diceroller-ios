# Battle loop rework

Every class draws six different dice from its eight-die collection each round. The player has no stamina bar. Each result can be played once, individually or as one ingredient of a combo.

## Planning and resolution

1. Inspect the enemies' announced moves and individual hits.
2. Roll six dice. One selective reroll is available each round; effects can raise the allowance to two. Dice already in the plan must be returned before rerolling. Unselected results become **Kept** for this round, preserving their critical result.
3. Arrange actions and explicitly Combine or Separate recipes. Focus precedes the attack it boosts. Separate Block and Evade prepare before attacks; each consumes its die without spending an exchange.
4. Commit. Player and enemy actions alternate, player first. Each combo is one action. Once one side runs out, the other finishes its announced actions. Singles never create additional enemy moves. Dead enemies lose their pending actions.
5. Settle statuses and round effects, then draw six fresh dice. Unused results and dodges expire. Guard expires except for Warriors, who retain up to eight.

| Choice | Result |
| --- | --- |
| Block | Eight guard across incoming hits; critical results increase the numeric amount |
| Evade | One guaranteed dodge of one selected announced hit, or the next incoming hit by default |
| Focus / Channel / Energize | +50% damage to the next attack or combo in the plan, one Focus per action; does not multiply god damage bonuses |
| Mixed combo | Its native defence activates before its own attack in the same exchange |
| Delay | Moves a foe's next pending action behind the next player action, up to twice per foe per round |

A Focus after all attacks has no target; the plan explains that it must move earlier. Two dodges cannot reserve the same hit: selecting an already reserved hit returns the other die to next-hit behaviour. A targeted dodge expires unused if its target is killed before that hit.

## Catalogue and progression

The existing combo and boon IDs are preserved. God powers rewarding frozen dice now reward results kept through a reroll. Stamina rewards become guard, attack bonuses, or extra rerolls. All dodge effects use whole charges instead of percentages. Focused-attack powers and attack-after-support powers have explicit triggers. Reactive guard and dodge effects activate on the relevant incoming hit, once; offensive status riders are applied after the action that creates them.

Siege Draw and Echoing Staff reserve an unused reroll while armed. Disarming or removing the relevant action releases that reservation. Assassin's Commitment consumes one available dodge before its attack; it cannot spend the dodge created by that same combo. Returning Knife banks six damage for next round's first attack. Relentless Advance adds six to next round's first weapon combo after landing one this round.

Singles retain 85% of their printed damage. Perfect Shot and Vanishing Strike have reduced base damage while retaining their guaranteed critical hit; Read the Room grants two dodges. Enemy health tuning rises from 1.12 to 1.35 to accompany the six-die opening hand. These are initial balance values, not a claim of completed device playtesting.

Existing version-2 run saves migrate to version 3 without dropping the character, equipment, powers, map, or progress. As before, saved battles restart at the encounter boundary. The revised briefing is shown once under its new tutorial version.

## Verification

The shared Xcode scheme includes the unit-test target. The iOS workflow builds the app and runs the existing dice/layout checks plus the battle regression suite on an available iPhone simulator. The new tests cover all four classes' draw rules, reroll identity and budget, Focus with Twin Shot and a separate Block, finite action queues, assigned single-hit dodges, reaction timing, fresh rounds, Chisel reservation, guard expiry, and catalogue constraints.

Device acceptance checks: play all four classes through an ordinary fight and a boss; inspect compact portrait and landscape layouts; verify VoiceOver labels and Reduce Motion; exercise mixed combos, healing, targeted dodges against multiple enemies, and mid-round deaths; resume an existing saved run. Balance should be assessed over full runs, especially Magician recovery chains and Rogue damage-over-time builds.
