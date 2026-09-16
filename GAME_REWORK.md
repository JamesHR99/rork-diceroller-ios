# DiceRoller — complete gameplay rework recap

Consolidated design • 16 September 2026

This is the latest proposed design, incorporating the eight-die collection, six active slots, separately displayed rarity and level, and interleaved agility timeline. It supersedes conflicting earlier proposals: six owned dice, all-Common opening rewards, duplicate-based rarity promotion, and a separate enemy phase are no longer the direction.

This is a design specification, not an implementation report. The god catalogue is proposed content. The combo inventory records the existing recipes and clearly separates them from proposed timing changes. Values, probabilities, level caps and timing numbers are initial playtest parameters, not validated balance. No game code has been changed.

## 1. The intended experience and complete loop

Build a character whose equipment offers a recognisable set of moves and whose gods reward chosen combat styles. Adapt to the dice you draw and roll. Decide whether to act quickly, establish protection, combine several faces into a powerful slower action, or preserve ingredients for the next round.

1. At round start, show each enemy's committed intent and its scheduled execution time.
2. Keep previously frozen dice; randomly draw enough other dice to fill six slots and roll the newly drawn dice.
3. Receive the round's stamina allowance and any earned temporary stamina.
4. Build, order and target your actions. Inspect the combined player/enemy timeline and mark unused dice to freeze.
5. Commit the plan. Reserve its stamina and faces; resolve player and enemy actions together in timeline order.
6. Settle scheduled verdicts, statuses, retaliation and end-of-round rewards. Clear expiring effects and begin the next round if combat continues.
7. After victory, take the route's growth reward: a god power, a level upgrade, an eligible milestone or an equipment modification.

The score presentation should attribute useful output to the native combo, gods and preparation. Do not count an animation hit, an echo or each status tick as a new combo. Do not reward repeatedly holding the same die or stalling without combat progress. A numerical score formula has not been specified in this design.

## 2. Dice, freezing, stamina and equipment

### The eight-die collection

- Own five weapon dice and three armour dice. Six can be active at once.
- Draw distinct physical dice without replacement for each round. Weapon/armour describes the die's source; its rolled face determines the available ingredient.
- Return all non-held dice to the available eight-die collection for the next draw. This is a fresh draw each round, not a persistent discard-pile cycle.
- With no held dice, draw six from eight. With one held die, draw five from the remaining seven. With two held, draw four from the remaining six.
- Six active dice necessarily contain three to five weapon dice and one to three armour dice. An armour die does not guarantee that it rolls Block.
- Show the two undrawn dice and the face distributions of all owned dice. Randomness should be understandable.
- Remove relic items, relic dice and relic reward/shop paths. Keep the normal collection at eight; equipment improvements replace or modify dice/faces rather than silently growing the bag.

### Freezing

- Freeze up to two unused dice when committing. It costs no stamina in the initial proposal.
- A held die retains its face and critical state and occupies one of the next round's six slots. It cannot also be drawn again.
- Played faces cannot be held. An explicitly printed Chisel return effect is the only exception, and must reserve the actual source die and a freeze slot.
- Holding can continue across rounds. A “new freeze” reward only qualifies when a freshly rolled face is first held, not when the same face is held again.
- A “frozen action” uses a die actually held from an earlier round. Marking a die for next round does not make a current action frozen.
- Holding does not prepay stamina or reduce preparation time unless a power explicitly says so.
- Anubis's Preserved Moment can temporarily raise the holding allowance to three, still inside six active slots. Three held dice mean drawing three from the other five.

### Stamina

- Base allowance: round 1 = 3, round 2 = 4, round 3 onward = 5. Reset this curve at each encounter.
- Refresh to that allowance each round, then add bonuses earned for that round, up to six total stamina. Unspent stamina and temporary excess expire.
- Each used face costs one stamina: solo 1, pair 2, triple 3, four-face combo 4.
- Remove generic large-combo discounts and automatic stamina banking. Only named boons or Chisels can change costs or generate stamina.
- Native Focus costs one stamina, primes +8 direct damage on the next Attack, and banks +1 stamina for next round. Resolve it before the attack it should strengthen. Identical primes retain the strongest value; they do not stack.
- Resolve the Magician's existing Channel face deliberately: for the first prototype, use it as the class's equivalent of Focus, with the same support rules, rather than an undocumented second stamina system.
- Pay/reserve planned stamina at commitment. Kills or cancelled actions do not refund it mid-resolution. This keeps affordability and Last Measure deterministic.

### Ptah's Chisels

- Keep Chisels as equipment modifications outside the seven god slots; initially allow two per run.
- Chisels change how native attacks or defence work: targeting, distribution of damage, ingredient substitution, a particular action's preparation time or an explicit cost exception.
- Split attacks and echoes remain one primary action for god counters. They do not copy the full divine payload.
- Ingredient substitution counts a die once. Show the effective matching face and the contribution role before commitment.
- A returned die occupies its source slot and a permitted hold slot; it cannot create a seventh active die or an extra copy.
-found very rarely instead of god boons (guranteed one in the first 4 hours and one in the second - can't be bought in a store, when found give a choice of one of 3 augmentations similar to the god boon selection)

## 3. Agility and the shared action timeline

Stamina determines how much you can do. Agility and each action's preparation time determine when it happens. These are separate systems.

| Class | Starting agility | Intended timing identity |
|---|---:|---|
| Rogue | 3 | Fast defence, quick attacks and sequential opportunities |
| Archer | 2 | Flexible pairs and deliberate precision shots |
| Warrior | 1 | Early simple protection, slower heavy attacks and retaliation |
| Magician | 1 | Quick emergency wards and slower powerful spells |

Action duration = max(1, preparation time − actor agility − eligible Haste).

| Default action | Preparation time before agility |
|---|---:|
| Solo Block or Evade | 3 |
| Quick solo attack | 4 |
| Ordinary solo attack, Heal or Focus/Channel | 5 |
| Typical two-face combo | 6 |
| Typical three-face combo | 9 |
| Typical four-face combo | 12 |

These are defaults. Each recipe and enemy ability can have an authored override. A stronger attack need not be fast merely because it uses fewer ingredients.

- Each actor's queued actions execute sequentially. The second player's action begins after the first finishes, not at round start.
- Each enemy initially receives its authored intent, not extra moves for having high agility. Boss follow-ups must be explicitly authored and revealed.
- All actors share one clock. At equal beats, player actions resolve before enemies; enemy ties use stable visible order.
- The timeline is planning information, not a real-time input test. A player can inspect and reorder their plan before committing.
- Ordinary hits do not cancel your pending action. Death cancels an actor's remaining events; explicit interruption is a separate mechanic and is not universally granted.
- If an enemy target dies before a planned attack, retain the action's scheduled time and use the first living target in a visible preselected fallback order. If none survives, combat finishes. Never grant a surprise timing reset on retargeting.
- Actions resolve their native and divine outputs at their execution beat. An attack with shield does not supply that shield during its wind-up unless explicitly authored as multiple timed events.
- Newly gained shield cannot absorb an earlier hit. Newly gained evade applies only to subsequent hits. Do not label chance-based dodging as guaranteed protection.
- Phase transitions do not invent unannounced immediate boss attacks. Reveal the changed intent schedule in the next planning window.
-sometimes the enemy can suprise the player when you eneter an encounter giving it a agility boost for the first turn.

### Worked timing comparison

Rogue agility is 3. The enemy strike resolves at beat 3. You have three stamina and Block plus three Swift Slashes available.

| Plan | Timeline | Resulting trade-off |
|---|---|---|
| Solo Block, then Flurry | Block at beat 1; enemy at beat 3; Flurry at beat 4 | Protection arrives before the hit, followed by a smaller attack. |
| Thousand Cuts | Enemy at beat 3; combo at beat 6 | Greater wound payoff, but its preparation leaves you exposed. |

Both plans cost three stamina. The unplayed dice can be held if slots permit. The example uses Flurry's default preparation of 6 and Thousand Cuts' 9.

### Haste and delay

- Haste shortens one eligible action's preparation. Total extra Haste is capped at two beats per action beyond the class-agility adjustment; minimum duration remains one.
- Haste does not create stamina or another action. Rarity and levels do not scale its frequency or fixed beat reduction.
- Next-action Haste must be earned before that action starts. If already resolved events or random outcomes change eligibility, update only future events, preserving progress; nothing resolves retroactively.
- Delay moves an enemy's still-pending action later. Initially cap combined player-inflicted delay at two beats per enemy per round; never delay a completed event or repeatedly freeze an enemy out of combat.
- Stagger remains damage reduction. Delay is a separate printed clause, not an automatic addition to every stagger effect.
- Speed remains deterministic once the roll and plan are known. Random evasion or an on-dodge boon can make subsequent outcomes conditional; preview that uncertainty honestly.

### Concrete timing additions proposed in this recap

These integrate the earlier agility examples into named powers; they are new tuning proposals, not previously implemented abilities:

- Quick Guard, Blink, Riposte and Chill Ward: preparation 4, emphasising early protection. Native shield/evade still arrives only when they resolve.
- Shadowstep: preparation 5; after resolving, grant the next action this round one beat of Haste. One such grant per round; unused Haste expires at round end.
- Ice Blast: retain its current stagger baseline and add one beat of delay to the target's pending action, once per round. Reassess its damage/stagger budget together with this addition.
- Earthshaker: same optional one-beat pending-action delay, once per round; do not assume the original damage is already balanced with it.
- Horus's Falcon's Eye: its qualifying first frozen Attack receives two beats of Haste.
- Bastet's Dancing Blades: the separately primed next Attack receives one beat of Haste.
- Bes's The Stout Door: the first Guard action each round receives one beat of Haste.
- Riposte's old reflection behaviour becomes a stance lasting until round end: the next enemy hit that shield absorbs at least partially triggers retaliation for 50% of the absorbed amount, rounded down. Consume the stance once; secondary retaliation does not trigger Attack boons. Its damage budget needs validation.

## 4. Gods, slots, rarity, levels and the opening reward

### Equipped powers

- Three Attack slots, two Defence slots, two Utility slots; no additional god-count limit.
- Multiple powers from one god or several gods can modify the same qualifying action.
- Every regular boon is a complete power. No entry attunement or basic Burn unlock is required.
- A new power uses a free matching slot or replaces a selected power. Show lost investment and affected duo prerequisites.
- At most two equipped duo boons and one Legendary evolution acquired per run initially. Both remain inside the ordinary slot budget.

### Rarity and level are separate

- Generate and display a new scalable boon's Common, Rare or Epic rarity before the player chooses. It starts at Level 1.
- A repeat offer for an equipped boon is explicitly a level upgrade. It keeps its current rarity, occupies the same slot, and does not create a second copy.
- Repeat offers do not reroll rarity and cannot promote it. A hypothetical rarity-promotion reward would be a separate future mechanic, not part of this version.
- Initially cap scalable levels at 3. Hide capped duplicate offers. The cap is a prototype parameter, not an established requirement for the final game.
- Levels do not transfer to a different named replacement boon.
- Only the card's designated numeric parameter scales. Fixed clauses, Haste, trigger counts, stamina and freeze slots do not silently grow.
- Twelve fixed Utility powers remain marked Fixed Utility, with no meaningless rarity or level upgrade. Duos also have fixed effects. Legendary evolutions preserve source rarity and level.

| New scalable boon offer | Common | Rare | Epic |
|---|---:|---:|---:|
| Early / opening | 75% | 23% | 2% |
| Middle | 45% | 40% | 15% |
| Late | 20% | 45% | 35% |

Use the three regions as the initial stage boundaries. These odds apply to eligible new scalable powers, not fixed Utility, duplicates or milestone cards.

| Solar Flare rarity | Level 1 | Level 2 | Level 3 |
|---|---:|---:|---:|
| Common | +6 damage | +8 damage | +10 damage |
| Rare | +9 damage | +11 damage | +13 damage |
| Epic | +12 damage | +14 damage | +16 damage |

Solar Flare's 4 Burn and first-large-combo condition stay fixed. Common Level 3 can outperform a new Rare Level 1; the rarer version retains its higher ceiling.

The complete Common Level 1/2/3 values are printed in the catalogue below. Appendix A supplies a full initial rarity matrix for all 48 scalable regular powers, so the rarity model is concrete. Values still require tuning against mechanic caps.

### Opening and later god meetings

- After the Straw Effigy, replace the relic selection with one uniformly random god: Ra, Sobek, Anubis, Bes, Horus or Bastet.
- That god offers three distinct, usable regular powers. Guarantee an immediately useful Attack option, and prefer a Defence and Utility alternative where eligible.
- Roll eligible new boon rarities using the early-run odds and display them before selection. The first meeting is not restricted to Common.
- Choose one; equip it directly on the character. The opening god does not lock later allegiance.
- Persist the selected god and offers so reopening the reward does not reroll them.
- Later meetings aim to mix a new power, an eligible owned-power upgrade and a flexible alternative or unlocked milestone, all respecting the visiting god and legal slots. Do not force a no-op duplicate to fill an offer template.

## 5. Effect definitions, stacking and round boundaries

The catalogue uses “round” consistently: one planning window and its entire interleaved timeline plus settlement. Every “first/second/third Attack” counter refers to completed primary player actions in that round, not die count or animation hits.

### Action roles

- Attack: a primary action with native direct damage. An attack combo is a damaging recipe; large means at least three ingredients.
- Guard: an action whose native result grants shield. It can also be an Attack, as with Warlord's Answer. Can you enable a shield bar above the enemy health in the same way the enemy gets a shield bar.
- Evade: an action whose native result grants evade chance. Consuming an Evade ingredient without such an output does not automatically qualify.
- Support: an action with native healing or a Focus/Channel preparation effect. Roles can overlap.
- Ingredient conditions remain separate. The Stout Door's per-Block bonus requires actual Block ingredients; Chill Ward can be Guard while supplying zero Block ingredients.
- A mixed Guard/Attack cannot satisfy “a separate Guard, then Attack” within itself. It can arm a benefit for a subsequent action.
- Frozen means using at least one held-from-prior-round die, regardless of how many held ingredients are included.

### Stacking

- Separate named boons coexist within the slots. Each owns its own activation counter.
- Explicit per-ingredient clauses count qualifying ingredients once. A fixed status application remains one payload per qualifying action.
- Apply native critical scaling, add flat damage, sum additive damage percentages, apply that percentage total once, then round down. Pierce adds up to 100%.
- Test “already burning,” “already bleeding,” missing HP and shield conditions before the action changes them.
- Batch new Burn and Judgement additions from one action before their cap. Bleed takes the highest applied potency.
- Secondary damage, retaliation, echoes and status ticks do not generate new Attack actions, recursive boon triggers or stamina.
- Primes from different named powers can coexist. Reapplying the same prime retains the strongest instead of stacking copies. Unless a card states a shorter duration, primes expire at the end of the following round.
- Split/splash native damage does not duplicate divine status payloads. Select a primary blessing target before commitment.

### Critical faces

Roll critical state with the face and preserve it when held. Proposed native solo multiplier is 1.5; native combo damage/healing/shield gain +15% per critical ingredient, capped at +60%. Do not make another random combo-critical roll after commitment. Status potency, god riders and stamina do not automatically crit.

Perfect Shot and Vanishing Strike currently guarantee a separate ×2 combo critical. Their replacement deterministic precision bonuses/native values remain a required balancing decision; the current inventory below does not silently remove that value.

### Status and defence rules

| Effect | Proposed rule |
|---|---|
| Burn | Add potency to cap 12. Tick at round end, then decay by 1. Early ticks do not decay it. |
| Bleed | Strongest potency wins, cap 10. Refresh to two round-end ticks. Early ticks do not reduce duration. |
| Poison | Shared recipes currently use it. Interim consolidation rule: strongest potency, cap 10, three round-end ticks; no new god required. This rule is a new proposal to make retained Poison recipes usable. |
| Judgement | Add to cap 30 per foe. First application in round R schedules a verdict for the end of R+1; additions do not postpone it. Final Verdict can advance it to this round's end. |
| Shield | Add to cap 30, persists within the encounter, clears between encounters. Must exist before a hit. |
| Evade | Add percentage points to cap 60%; rolls independently against each eligible incoming hit. Clear at round end, after settlement. |
| Damage reduction | Sum applicable reductions to cap 50%; apply before shield. A next-hit token is spent on the first non-evaded damaging hit. |
| Divine healing | Cap repeatable boon healing at 8 actual HP restored per round. Native healing and native lifesteal are separate. Overheal is zero. |
| Lifesteal | Heal from actual enemy HP removed by the eligible native attack, not its uncapped overkill value. |

All native and divine Burn/Bleed applications use the same proposed status rules. The current recipe durations below are historical baselines, not a second simultaneous status system. Converting a long-duration native effect to the shared rules requires retuning its potency or other benefits.

### Settlement order

After all scheduled actions resolve: due Judgement verdicts (with their attached duo modifiers), end-of-round duo damage, then ordinary Burn/Bleed/Poison ticks for surviving actors in visible order. Check death after each event. Apply survival effects such as Nine Lives at the lethal event, not after settlement ends.

Then resolve Unbroken House retaliation and Unscathed's reward, then check end-of-round resource conditions such as Hearth Breath and Last Measure. Finally clear evade, unused round-only Haste and expiring armed reactions. Earlier qualifying stamina banks remain scheduled for next round, subject to its cap. If combat ends, no next-round benefits leak into the next encounter unless a power explicitly says so.

Unscathed requires at least one incoming hit attempt and zero HP lost across the entire round, including status damage; its check occurs after the status ticks. Blood Reserve checks current HP at the next round start. Opening shield effects occur before the first timeline begins.

Retaliations armed by Guard/Evade actions expire at round end if unused. Multiple armed named reactions can respond to the same later hit or dodge. An attack's on-kill native benefits resolve before clearing the encounter, but no new enemy action occurs after all enemies die.

## 6. Reading the complete god catalogue

There are 60 regular powers (10 per god), 15 duos and six Legendary evolutions. A/B/C values below are Common Level 1/2/3. Only the marked value scales; fixed text remains fixed. New timing additions are marked explicitly. These are target content, not a claim that 81 cards should be implemented before testing the core loop.

## 7. Ra — fire, commitment and rising power

Ra rewards building heat, choosing a finishing moment and committing prepared dice. His pool supports large combos, separate attacks and frozen strikes without an entry-level Burn purchase.

| ID | Slot | Boon | Complete effect | Main function |
|---|---|---|---|---|
| RA-A1 | Attack | **Solar Flare** | Your first large attack combo each round gains **6 / 8 / 10** direct damage and adds 4 Burn to its primary surviving target. | Large combos |
| RA-A2 | Attack | **Scorching Sequence** | Your first Attack each round adds **3 / 4 / 5** Burn. If your second Attack that round targets the same living foe, it pays one early Burn tick after its status applications. | Multiple moves; order |
| RA-A3 | Attack | **Sun's Judgement** | Your first frozen Attack each round gains **8 / 10 / 12** direct damage and adds 3 Burn. | Freezes; prepared attacks |
| RA-A4 | Attack | **Noon Spear** | If you began the round with at least 5 stamina, your first Attack gains **30 / 40 / 50** percentage points of pierce and adds 4 Burn. | Rising stamina; Focus |
| RA-A5 | Attack | **Sun's Edge** | Every Attack adds 1 Burn per Attack ingredient. Against an already-burning target, it also gains **15 / 20 / 25%** direct damage. | Ingredient scaling; setup |
| RA-D1 | Defence | **Solar Guard** | Your first Guard action each round grants **4 / 5 / 6** extra shield and arms retaliation: the first incoming hit shield absorbs that round adds 4 Burn to its attacker. | Block; retaliation |
| RA-D2 | Defence | **Cinder Step** | Your first Evade action each round grants +10 percentage points of evade chance and arms your first successful dodge that round to add **3 / 4 / 5** Burn to its attacker. | Evade; reactive fire |
| RA-D3 | Defence | **Sunset Shelter** | Your first frozen Guard action each round grants **6 / 8 / 10** extra shield and arms the first hit shield absorbs that round to add 2 Burn to every living foe. | Frozen defence; reactive area fire |
| RA-U1 | Utility | **Dawn Breath** | Start each encounter with +1 temporary stamina: the opening budget becomes 4. Fixed; it does not alter later base allowances. | Early tempo |
| RA-U2 | Utility | **Banked Embers** | At commitment, newly freeze at least one Attack face to bank +1 stamina for next round. Once per round; re-freezing a carried face does not qualify. Fixed. | Freezes; next-turn stamina |

Possible directions: Solar Flare + Sun's Judgement prepares a large frozen finisher; Scorching Sequence + Sun's Edge rewards two attacks in order. Noon Spear makes an early Focus matter and remains active once the normal ramp reaches five.

## 8. Sobek — wounds, pressure and survival

Sobek establishes wounds, exploits damaged enemies and rewards taking measured risks. Bleed refreshes rather than adding, so repeated small hits and one potent application have different jobs.

| ID | Slot | Boon | Complete effect | Main function |
|---|---|---|---|---|
| SO-A1 | Attack | **Twin Fangs** | Your first two-face attack combo each round gains **4 / 6 / 8** direct damage and applies Bleed 4. | Small combos |
| SO-A2 | Attack | **Blood Scent** | Your first Attack each round applies Bleed 3. All your Attacks against already-bleeding targets gain **20 / 25 / 30%** direct damage. | Setup; multiple moves |
| SO-A3 | Attack | **Death Grip** | Your first frozen Attack each round gains **6 / 8 / 10** direct damage and applies Bleed 5. | Frozen attacks |
| SO-A4 | Attack | **Feeding Frenzy** | Your second Attack each round applies Bleed 3. If that action's native damage dealt positive HP damage, also heal **3 / 4 / 5**. | Multiple moves; sustain |
| SO-A5 | Attack | **Jaws of the Nile** | Your first large attack combo each round applies Bleed **4 / 5 / 6**, then pays one early Bleed tick and heals for HP actually lost to that tick, up to 4. | Large combos; sustain |
| SO-D1 | Defence | **Crocodile Armour** | Your first Guard action each round grants **4 / 5 / 6** extra shield and arms the first hit shield absorbs that round to apply Bleed 3 to its attacker. | Block; reactive wounds |
| SO-D2 | Defence | **River Slip** | Your first Evade action each round grants +10 percentage points of evade chance and arms your first successful dodge that round to heal **3 / 4 / 5**. | Evade; recovery |
| SO-D3 | Defence | **Blood Shelter** | Your first frozen Guard action each round grants **5 / 7 / 9** extra shield and heals 3. | Frozen defence; recovery |
| SO-U1 | Utility | **Blood Reserve** | At round start, after the previous round has fully settled, gain +1 temporary stamina if HP is at or below half maximum. Subject to the total budget cap of 6. Fixed. | Risk; stamina |
| SO-U2 | Utility | **Patient Hunter** | The first action using a frozen face each encounter heals 3 and banks +1 stamina for the following round. Any action role qualifies. Fixed. | Freezes; delayed stamina |

Possible directions: Twin Fangs + Blood Scent supports a wound-setting solo followed by a pair; Death Grip + Jaws rewards saving a potent combo. Healing remains bounded, and low-HP stamina is a risk/reward tool rather than a reason enemies should stop applying pressure.

## 9. Anubis — sequences, preservation and timed verdicts

Anubis makes players think about when damage will arrive. Every regular offensive boon below establishes its own Judgement or supplies a complete attack benefit; there is no prerequisite god attunement.

| ID | Slot | Boon | Complete effect | Main function |
|---|---|---|---|---|
| AN-A1 | Attack | **Scales of War** | Your first attack combo containing a Block ingredient each round adds **8 / 10 / 12** Judgement and grants 4 shield. | Mixed attack/guard combo |
| AN-A2 | Attack | **Second Reading** | Every Attack adds **2 / 3 / 4** Judgement per Attack ingredient. Once per round, an Attack against an already-judged foe adds 4 further Judgement. | Ingredient scaling; sequence |
| AN-A3 | Attack | **Sealed Fate** | Your first frozen Attack each round gains **6 / 8 / 10** direct damage and adds 6 Judgement. | Frozen attacks |
| AN-A4 | Attack | **Final Sentence** | Your first large attack combo each round gains 20 percentage points of pierce and adds **10 / 12 / 14** Judgement. | Large combo; delayed payoff |
| AN-A5 | Attack | **Borrowed Time** | Your first Attack against a target already below half HP each round gains **8 / 10 / 12** direct damage and adds 4 Judgement if it survives. | Finishing; target choice |
| AN-D1 | Defence | **Tomb Ward** | Your first Guard action each round grants **3 / 4 / 5** extra shield and arms the first hit shield absorbs that round to add 6 Judgement to its attacker. | Block; retaliation |
| AN-D2 | Defence | **Passing Shadow** | Your first Evade action each round grants +10 percentage points of evade chance and arms your first successful dodge that round to add **6 / 8 / 10** Judgement to its attacker. | Evade; delayed retaliation |
| AN-D3 | Defence | **Burial Cloth** | Your first frozen Guard action each round grants **6 / 8 / 10** extra shield and removes one player damage-over-time status, chosen in planning. | Frozen defence; cleanse |
| AN-U1 | Utility | **Last Measure** | Finish the round with exactly zero stamina to bank +1 for next round. Once per round; checks actual paid costs, including Chisel and boon adjustments. Fixed. | Full commitment; stamina |
| AN-U2 | Utility | **Preserved Moment** | Once per encounter, choose to freeze up to three faces at commitment instead of two. Still six active slots from eight owned dice. On the following commitment the normal two-face limit returns, unless this boon was not yet used. Fixed. | One large preparation turn |

Possible directions: Second Reading supports sequential applications while Final Sentence concentrates a large ledger. A frozen mixed attack/guard recipe can qualify for several named boons together. It is still one action and cannot generate its own “already judged” condition.

## 10. Bes — protection that lets you keep fighting

Bes supports an offensive shield build as well as dedicated defence. His Attack boons earn their slot by letting attacks protect the player; Defence and Utility provide different routes to a stable turn.

| ID | Slot | Boon | Complete effect | Main function |
|---|---|---|---|---|
| BE-A1 | Attack | **Sheltering Blow** | Every Attack grants **2 / 3 / 4** shield per Attack ingredient, up to 8 shield per action. If you had at least 8 shield before the action, it also gains +15% direct damage. | Shield offence; ingredient scaling |
| BE-A2 | Attack | **Counter-Swing** | Once per round, your next Attack after a separate Guard action gains **8 / 10 / 12** direct damage and grants 4 shield. The armed bonus expires after the next round. | Guard → Attack sequence |
| BE-A3 | Attack | **Guardian's Hand** | Your first frozen Attack each round gains **6 / 8 / 10** direct damage and grants 6 shield. | Frozen attack; protection |
| BE-A4 | Attack | **Stalwart Advance** | Your first two-face attack combo each round gains **4 / 6 / 8** direct damage and grants 6 shield. | Small combo; protection |
| BE-A5 | Attack | **Unbroken Rhythm** | Your second Attack each round gains **6 / 8 / 10** direct damage and grants 4 shield. | Multiple moves |
| BE-D1 | Defence | **The Stout Door** | Every Guard action gains **3 / 4 / 5** extra shield per Block ingredient. This applies once as a pooled shield gain, subject to the shield cap. **Timing addition:** the first Guard action each round has 1 beat of Haste, even if it has no Block ingredient. | Single and combined blocks |
| BE-D2 | Defence | **Rebuild the Wall** | Start each encounter with **6 / 8 / 10** shield. The first time shield breaks in that encounter, regain 8 shield after the hit finishes; it cannot undo HP damage from that hit. | Opening safety; recovery |
| BE-D3 | Defence | **Steady Footing** | Your first Evade action each round gains +10 percentage points of evade chance and grants **4 / 5 / 6** shield. | Reliable and uncertain defence together |
| BE-U1 | Utility | **Hearth Breath** | End the round with at least 8 shield to bank +1 stamina for next round. Once per round. Fixed. | Defensive preparation; stamina |
| BE-U2 | Utility | **Safe Keeping** | At commitment, newly freeze at least one Block, Evade or Support face to schedule 4 shield at the start of your next round. Once per round; re-freezing does not qualify. Fixed. | Defensive freezes |

Possible directions: Counter-Swing rewards splitting Guard and Attack; Sheltering Blow rewards maintaining shield; a defence-heavy plan can prepare stamina through Hearth Breath. Slot caps and the 30-shield cap prevent stockpiling every protective benefit without tradeoffs.

## 11. Horus — precision, timing and prepared power

Horus is the strongest fit for deliberate holds and piercing a specific target. His bonuses are conditional percentages or preparation rewards, not another damage-over-time status.

| ID | Slot | Boon | Complete effect | Main function |
|---|---|---|---|---|
| HO-A1 | Attack | **Falcon's Eye** | Your first frozen Attack each round gains **25 / 30 / 35%** direct damage and 20 percentage points of pierce. **Timing addition:** this qualifying action has 2 beats of Haste. | Frozen attacks |
| HO-A2 | Attack | **Keen Edge** | Your first Attack each round gains **20 / 30 / 40** percentage points of pierce. If it contains a critical ingredient, it also gains 6 direct damage. | Crit selection; armour |
| HO-A3 | Attack | **Patient Aim** | Your first large attack combo each round gains **20 / 25 / 30%** direct damage and 40 percentage points of pierce. | Large combo |
| HO-A4 | Attack | **Watchful Strike** | Once per round, your next Attack after a separate Guard or Support action gains **20 / 25 / 30%** direct damage and 30 percentage points of pierce. Prime expires after the next round. | Action order; Focus |
| HO-A5 | Attack | **High Flight** | If you began the round with at least 5 stamina, your first Attack gains **20 / 25 / 30%** direct damage and 20 percentage points of pierce. | Stamina ramp; early overcharge |
| HO-D1 | Defence | **Watchful Guard** | Your first frozen Guard action each round gains **6 / 8 / 10** extra shield and reduces the next non-evaded hit by 20%. Reduction expires next round. | Frozen defence |
| HO-D2 | Defence | **Feather Step** | Your first Evade action each round grants **10 / 15 / 20** extra percentage points of evade chance. If it uses a frozen face, gain 5 further percentage points, still capped at 60%. | Frozen evasion |
| HO-D3 | Defence | **High Perch** | Your first Guard action each round grants **4 / 5 / 6** extra shield. If a different face carried from a prior turn is still unused when the Guard action starts, gain 4 further shield. | Preserve or spend a frozen face |
| HO-U1 | Utility | **Thermal** | Your first action using a frozen face each round banks +1 stamina for next round. Fixed. | Spend freezes to sustain tempo |
| HO-U2 | Utility | **Perfect Timing** | Once per encounter, you may reduce the cost of a combo using a frozen face by 1, to a minimum of 1. Toggle it in planning before commitment. Fixed. | Freeze; immediate efficiency |

Possible directions: Watchful Strike makes a Support action before a combo worthwhile; Patient Aim and Falcon's Eye favour a large held strike. Those percentage bonuses add. Perfect Timing spends its once-per-encounter use only when the discounted action executes, not when it is previewed.

## 12. Bastet — short techniques, evasion and movement

Bastet encourages several useful actions and agile pairs. She can also support a frozen finisher, but she does not need to imitate the large-combo gods to remain strong.

| ID | Slot | Boon | Complete effect | Main function |
|---|---|---|---|---|
| BA-A1 | Attack | **Pounce** | Your first two-face attack combo each round gains **6 / 8 / 10** direct damage and grants +10 percentage points of evade chance. | Small combo |
| BA-A2 | Attack | **Quick Claws** | Your first two solo Attacks each round gain **3 / 4 / 5** direct damage each. If the second targets the same living foe as the first, it gains 2 additional direct damage. | Solo sequence; focus fire |
| BA-A3 | Attack | **Silent Approach** | Your first frozen Attack each round gains **6 / 8 / 10** direct damage and grants +15 percentage points of evade chance. | Frozen offence |
| BA-A4 | Attack | **Dancing Blades** | Once per round, your next Attack after a separate Evade action gains **8 / 10 / 12** direct damage and 40 percentage points of pierce. Prime expires after the next round. **Timing addition:** the primed Attack also has 1 beat of Haste. | Evade → Attack sequence |
| BA-A5 | Attack | **Ninefold Flurry** | Your third Attack action each round gains **10 / 12 / 14** direct damage and grants +10 percentage points of evade chance. Ingredients inside one combo do not count as separate attacks. | Multiple moves; stamina |
| BA-D1 | Defence | **Hunting Step** | Your first Evade action each round grants **10 / 15 / 20** extra percentage points of evade chance. If it is a two-face combo, gain 5 further percentage points, capped at 60%. | Evasive pairs |
| BA-D2 | Defence | **Light Landing** | Your first Evade action each round grants +10 percentage points of evade chance and arms your first successful dodge that round to grant **4 / 5 / 6** shield. | Dodge; protection |
| BA-D3 | Defence | **Unscathed** | Start the encounter with **4 / 6 / 8** shield. At round-end settlement, if at least one incoming hit was attempted and you lost no HP anywhere in that round, gain 4 shield. | Avoid all health damage |
| BA-U1 | Utility | **Light Feet** | Your first successful dodge each round banks +1 stamina for the next round. Fixed. | Evade; stamina |
| BA-U2 | Utility | **Slip Through** | Once per encounter, you may play one solo face carried from a previous turn for 0 stamina. Toggle it in planning. This is an explicit exception to the usual minimum action cost. Fixed. | Freeze; an extra move |

Possible directions: Pounce supports two-face techniques, Quick Claws supports solos, and Ninefold Flurry creates a reason to sequence three attacks when the budget allows. Slip Through never copies a face and never returns itself; it consumes the actual carried face and its once-per-encounter use.

## 13. All fifteen duo boons

Duos are later rewards with real prerequisites. The regular catalogue remains usable without them. A duo needs its listed source powers equipped, and those powers must remain equipped while the duo is active. The duo itself never satisfies its own prerequisite and does not establish a source for another duo.

If replacing a source would deactivate a duo, preview that consequence before confirmation. Never offer a duo as selectable when there is no legal way to equip it while retaining its prerequisites. Check replacement choices, not just the current collection.

### Source groups used in the table

| Source label | Eligible equipped regular boons |
|---|---|
| Ra Burn | RA-A1 to RA-A5, or RA-D1 to RA-D3 |
| Sobek Bleed | SO-A1 to SO-A5, or SO-D1 |
| Sobek Healing | SO-A4, SO-A5, SO-D2, SO-D3 or SO-U2 |
| Anubis Judgement | AN-A1 to AN-A5, AN-D1 or AN-D2 |
| Bes Shield | BE-A1 to BE-A5, BE-D1 to BE-D3, or BE-U2 |
| Horus Frozen | HO-A1, HO-D1, HO-D2, HO-D3, HO-U1 or HO-U2 |
| Horus Pierce | HO-A1 to HO-A5 |
| Bastet Evade | BA-A1, BA-A3, BA-A5, BA-D1 or BA-D2 |

A legendary counts as the source boon it evolves. Native faces supply the necessary actions, but do not substitute for a named god source in duo prerequisites. For example, owning only Blood Reserve does not unlock a Bleed-based Sobek duo.

All duo values below are fixed and do not level. Each has its own use counter.

| ID | Gods / name | Slot | Complete effect | Equipped prerequisites |
|---|---|---|---|---|
| DU-01 | Ra + Sobek — **Boiling Nile** | Attack | At end of the round, the living foe with both Burn and Bleed and the greatest Burn takes extra direct HP damage equal to its Burn, capped at 6. Once per round; does not consume or decay either status. Ties use visible enemy order. | Ra Burn + Sobek Bleed |
| DU-02 | Ra + Anubis — **Funeral Pyre** | Attack | The first scheduled Judgement verdict against a burning foe each round deals extra HP damage equal to twice that foe's current Burn, capped at 12. | Ra Burn + Anubis Judgement |
| DU-03 | Ra + Bes — **Forge Song** | Defence | The first incoming hit shield absorbs each round adds 4 Burn to the attacker. | Ra Burn + Bes Shield |
| DU-04 | Ra + Horus — **Sunstrike** | Attack | Your first frozen Attack each round gains 6 direct damage. If its target was already burning, pay one early Burn tick after status applications, capped at 6 HP damage. | Ra Burn + Horus Frozen |
| DU-05 | Ra + Bastet — **Dancing Flame** | Defence | Your first successful dodge each round adds 4 Burn to the attacker and grants 2 shield. | Ra Burn + Bastet Evade |
| DU-06 | Sobek + Anubis — **The Crossing** | Utility | Your first scheduled Judgement verdict against a bleeding foe each round heals 3 and banks +1 stamina for the next round. Check Bleed immediately before the verdict, even if the verdict kills. | Sobek Bleed + Anubis Judgement |
| DU-07 | Sobek + Bes — **Crocodile Hide** | Defence | Your first positive healing event each round grants 5 shield. Eligible healing comes from native actions, consumables or regular/legendary boons, never another duo. Overheal does not qualify. | Sobek Healing + Bes Shield |
| DU-08 | Sobek + Horus — **Reed and Sky** | Attack | Your first frozen Attack against an already-bleeding foe each round gains +25% direct damage and 20 percentage points of pierce. | Sobek Bleed + Horus Frozen |
| DU-09 | Sobek + Bastet — **Death Roll** | Defence | Your first successful dodge against a bleeding attacker each round pays one early Bleed tick against it and heals 2. | Sobek Bleed + Bastet Evade |
| DU-10 | Anubis + Bes — **Guardian of the Tomb** | Defence | The first incoming hit shield absorbs each round adds 6 Judgement to the attacker. | Anubis Judgement + Bes Shield |
| DU-11 | Anubis + Horus — **The Weighing Eye** | Attack | Your first frozen Attack each round adds 8 Judgement. If a verdict was already pending on that foe before the action, gain 4 shield as well. | Anubis Judgement + Horus Frozen |
| DU-12 | Anubis + Bastet — **Borrowed Life** | Defence | Your first successful dodge each round adds 6 Judgement to the attacker and heals 2. | Anubis Judgement + Bastet Evade |
| DU-13 | Bes + Horus — **Watchful Guardian** | Defence | Your first action using a frozen face each round grants 6 shield. If that action is Guard, it also reduces the next non-evaded hit by 25%, expiring at the next round. | Bes Shield + Horus Frozen |
| DU-14 | Bes + Bastet — **Warm Doorstep** | Defence | Your first successful dodge each round grants 6 shield. The first time shield breaks that round, gain +10 percentage points of evade chance for the rest of that round, capped at 60%. | Bes Shield + Bastet Evade |
| DU-15 | Horus + Bastet — **Silent Descent** | Attack | Your first successful dodge each round primes the next Attack for +20% direct damage and 100% pierce. It expires after the next round and does not stack with itself. | Horus Pierce + Bastet Evade |

Slot example: Forge Song and Dancing Flame can coexist in the two Defence slots if Ra's Burn, Bes's Shield and Bastet's Evade are provided by equipped Attack boons. They cannot fit alongside two separate Defence source boons. The acquisition screen must show that difference explicitly.

## 14. Six legendary evolutions

These are the highest-tier version of a named regular boon, replacing it in its existing slot. They are not a free eighth power. Limit the run to one legendary evolution.

Unlock an evolution offer by equipping the named source boon plus at least one other regular boon of the same god. Both must be equipped when choosing the evolution. This is a one-time acquisition requirement: the evolved card remains complete if the other regular boon is later replaced. Duos do not count as the second regular boon.

The source's rarity and level carry over. Where values are listed below, they replace that part of the source instead of adding another copy. Unmentioned source clauses remain. If the player later replaces the legendary, it leaves the build; its once-per-run acquisition is not reset.

| ID | God / legendary | Evolves | Full replacement behaviour |
|---|---|---|---|
| LG-RA | Ra — **Crown of Noon** | RA-A1 Solar Flare, Attack slot | Your first large attack combo each round gains **10 / 12 / 14** direct damage. If its primary target survives the native hit, consume that target's pre-action Burn for twice that potency as direct HP damage, capped at 20; then, if it still survives, add 6 Burn. Other boons' new Burn is applied afterward as usual. |
| LG-SO | Sobek — **Lord of the Bloodied Nile** | SO-A5 Jaws of the Nile, Attack slot | Your first large attack combo each round applies Bleed **6 / 7 / 8**, pays one early Bleed tick, and heals for HP actually lost to that tick up to 6. If the target was already below half HP before the action, the native attack also gains +20% direct damage. |
| LG-AN | Anubis — **Final Verdict** | AN-A4 Final Sentence, Attack slot | Your first large attack combo each round gains 20 percentage points of pierce, adds **14 / 16 / 18** Judgement and advances that target's entire pending ledger to the end of the current round. Further additions this turn join it. It still resolves only once for that target at the scheduled phase. |
| LG-BE | Bes — **Unbroken House** | BE-A1 Sheltering Blow, Attack slot | Retain Sheltering Blow at its current level. At round-end settlement, retaliate for half the shield absorbed during that round, rounded down and capped at 15 direct HP damage, against the living enemy whose hits consumed most shield. If no shield-damaging attacker survives, no retaliation occurs. |
| LG-HO | Horus — **Eye of the Falcon** | HO-A1 Falcon's Eye, Attack slot | Your first frozen Attack each round gains **35 / 40 / 45%** direct damage and ignores all block and armour. It is still a single once-per-round activation, even with several frozen ingredients. |
| LG-BA | Bastet — **Nine Lives Unbound** | BA-D1 Hunting Step, Defence slot | Retain Hunting Step at its current level. Once per encounter, a lethal hit or damage-over-time event leaves you at 1 HP instead. Set evade chance to its normal 60% cap through the end of the current round; later hits or damage-over-time can still kill you. |

These rewards are intentionally strong but not proven equal. A once-per-encounter death rescue must be assessed by survival and win rate, not only by damage contribution. Three other god rewards plus a legendary should not be treated as a substitute for enemy and encounter tuning.


## 15. All current class combos — inventory, not final rebalance

These are **current recipe base values**, not rebalanced proposals and not final damage previews. Critical ingredients, combo critical hits, class effects, gods, Chisels and enemy defences can change the result. Burn/Bleed notation below means damage per tick × duration as authored in the current recipe; the proposed status model uses different rules.

“Any Strike” means any face matched by the code's attack-face predicate. It is an additional ingredient: Executioner needs three separate faces. “Any Swing” means Overhead or Side Swing. Stagger reduces the target's upcoming strike damage; it is not a percentage chance to skip a turn. Evade values are percentage points added to evade chance.

### Archer — precision, piercing and preparing exact arrows

| Combo | Required faces | Current base effect | Why it is useful |
|---|---|---|---|
| Twin Shot | Any Arrow ×2 | 22 damage | Flexible conversion of two arrows; leaves other dice for another action. |
| Piercing Bolt | Arrow II + Arrow III | 38 damage; 60% pierce | Strong pair against protected targets. |
| Point-Blank | Bow Smack + any Arrow | 26 damage; 20% stagger | Deals damage while weakening the target's incoming strike. |
| Quick Guard | Block + Evade | 14 shield; +15 points evade | Combines reliable absorption with a chance to avoid hits. |
| Field Dressing | Heal ×2 | Heal 22 | Dedicated recovery when missing enough HP to use it. |
| Steady Aim | Focus + any Arrow | 24 damage; 30% pierce | Converts Focus into immediate penetrating damage. |
| Perfect Shot | Arrow I + Arrow II + Arrow III | 58 damage; 40% pierce; guaranteed combo crit | Exact-recipe burst; gives holding a missing arrow a clear purpose. |
| Storm of Shafts | Any Arrow ×4 | 56 damage; 40% stagger | Flexible four-arrow commitment that also reduces retaliation. |

Current Perfect Shot's guaranteed ×2 combo crit makes its 58 base become 116 before other modifiers, even with no critical ingredients. Storm of Shafts is single-target unless a separate modifier changes targeting. Steady Aim does not automatically inherit the solo Focus face's effects.

Design direction: Horus rewards holding the correct arrow; Ra rewards committing the completed large combo; Bastet makes pairs a competing route. Perfect Shot and Storm need a clearer balance between precision burst and suppression.

Source: [ArcherContent.swift](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Content/ArcherContent.swift).

### Warrior — pressure, protection and finishing wounded enemies

| Combo | Required faces | Current base effect | Why it is useful |
|---|---|---|---|
| Crushing Blow | Overhead ×2 | 30 damage | Straightforward pair for immediate pressure. |
| Wide Sweep | Side Swing ×2 | 24 damage; 25% stagger | Trades some burst for reduced retaliation. |
| Earthshaker | Overhead ×3 | 46 damage; 40% stagger | Larger offensive commitment that also blunts an incoming strike. |
| Riposte | Block ×2 | 20 shield; 50% reflection on fully shield-absorbed hits | Rewards meeting the incoming hit with enough shield. |
| Second Wind | Heal + Block | Heal 12; 10 shield | Repairs current damage while preparing for the next hit. |
| Executioner | Any Swing ×2 + another Any Strike | 44 damage plus floor(enemy missing HP ÷ 5) | A finisher that improves after earlier damage. |
| Warlord's Answer | Any Swing ×3 + Block | 58 damage; 14 shield; 35% stagger | Heavy attack with simultaneous protection. |
| Blood Tide | Any Swing ×4 | 68 damage; lifesteal | Offensive recovery when the target lets the attack deal damage. |

Wide Sweep is not inherently an area attack. Riposte currently reflects only when shield completely absorbs the hit, not on every partly blocked hit. Blood Tide heals from the engine's reported dealt damage; see the overkill correction below.

Design direction: Bes strengthens protection, Sobek supports wound pressure and recovery, and Ra rewards heavy commitment. Make Executioner's wounded-target payoff distinct from Earthshaker's suppression and Blood Tide's recovery.

Source: [WarriorContent.swift](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Content/WarriorContent.swift).

### Rogue — applying wounds, exploiting them and retaining flexibility

| Combo | Required faces | Current base effect | Why it is useful |
|---|---|---|---|
| Flurry | Swift Slash ×2 | 22 damage | Simple pair that can leave room for another move. |
| Opening Cut | Swift Slash + Dagger Throw | 22 damage; Bleed 6 ×2 | Establishes Bleed for later pressure and conditional effects. |
| Twin Fang | Dagger Throw ×2 | 26 damage; Bleed 8 ×3 | Strong longer-duration wound application. |
| Shadowstep | Evade + Any Strike | 22 damage; +15 points evade | Attack while improving the chance to avoid retaliation. |
| Patch Up | Heal ×2 | Heal 20 | Direct recovery when survival matters more than attacking. |
| Hemorrhage | Dagger Throw + Swift Slash ×2 | 36 damage plus twice the target's pre-action stored Bleed potency; Bleed 8 ×2 | Cashes in an established wound for immediate damage. |
| Vanishing Strike | Evade + Dagger Throw + Swift Slash | 44 damage; Bleed 6 ×3; guaranteed combo crit | A mixed-face burst recipe worth preparing. |
| Thousand Cuts | Swift Slash ×3 | 40 damage; Bleed 10 ×3 | Converts several slashes into a strong sustained wound. |

Vanishing Strike's guaranteed ×2 crit makes its 44 base become 88 before other modifiers. It does **not** currently grant evasion despite consuming an Evade face. Thousand Cuts is one combo action, not multiple independent Attack triggers. Current critical combos also scale status potency and extend duration, so the table's base Bleed is not the guaranteed-crit final value.

Design direction: Sobek helps establish wound pressure, Bastet rewards pairs and agile sequences, and Anubis provides delayed finishing power. Show the value of Bleed that is already present before Hemorrhage resolves; its own new Bleed does not supply the damage bonus for that same action.

Source: [RogueContent.swift](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Content/RogueContent.swift).

### Magician — choosing damage, suppression or recovery from runes

| Combo | Required faces | Current base effect | Why it is useful |
|---|---|---|---|
| Fireball | Fire Rune ×2 | 26 damage; Burn 4 ×2 | Pair-based immediate damage and continuing pressure. |
| Ice Blast | Frost Rune ×2 | 22 damage; 45% stagger | Strong reduction of the target's upcoming strike. |
| Chill Ward | Frost Rune + Life Rune | Heal 10; 14 shield | Converts runes into both recovery and protection. |
| Life Siphon | Arcane Rune + Life Rune | 20 damage; lifesteal | Simultaneously damages the enemy and recovers HP. |
| Kindle | Wand Zap + any Rune | 20 damage | Flexible fallback when more specific rune pairs are unavailable. |
| Blink | Evade + Block | 10 shield; +15 points evade | Mixed defence while reserving runes for other actions. |
| Meteor | Fire Rune ×2 + Arcane Rune | 50 damage; Burn 6 ×3 | A focused large-combo damage and Burn payoff. |
| Arcane Storm | Three distinct Rune types | 44 damage; Burn 4 ×2; 30% stagger | Rewards varied runes with both pressure and suppression. |

Rune types are Fire, Frost, Life and Arcane. Kindle has no native Burn. Arcane Storm is single-target by default. Including a Life Rune does not automatically add its solo healing effect to a recipe that does not list healing.

Design direction: Ra amplifies offensive commitment, Bes supports warding, and Horus rewards preserving the rune needed for Meteor or Arcane Storm. The player should understand why matching runes and collecting varied runes lead to different outcomes.

Source: [MagicianContent.swift](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Content/MagicianContent.swift).

## 16. All six shared combos and relic removal

| Combo | Required faces | Current base effect | Place in the revised game |
|---|---|---|---|
| Detonate | Bomb ×2 | 36 damage; Burn 5 ×2 | Remove from the active recipe list unless two Bomb-capable dice remain available. |
| Venom Coat | Poison ×2 | Poison 8 ×3 | Requires two simultaneous Poison faces; one Poison-capable die is insufficient. |
| Steadied Strike | Heal + Any Strike | 16 damage; heal 14 | Remains a useful shared attack/recovery recipe using ordinary kit faces. |
| Breach and Strike | Bomb + Any Strike | 28 damage; 50% pierce | Needs a retained, deliberate Bomb face source. |
| Envenomed Edge | Poison + Any Strike | 18 damage; Poison 6 ×3 | Can remain available to Rogue: its starter Shadow Shiv has a Poison face. |
| Blinding Blast | Evade + Bomb | 26 damage; +20 points evade | Needs a retained, deliberate Bomb face source. |

Removing relics does not automatically invalidate all six shared recipes. Check actual face sources. In the initial eight-die prototype, retain reachable recipes and hide inaccessible ones. If Bombs or broader Poison access return later, introduce them through a deliberate kit modification rather than another random extra-dice system. One held die still occupies one of six active positions; it cannot provide two simultaneous ingredients by holding yesterday's face and rolling an additional copy today.

Source: [SharedContent.swift](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Content/SharedContent.swift).


## 17. Proposed preparation values for every recipe

This table is the proposed timing layer applied to the current inventory. Costs below are the revised costs, not the old coded combo discounts. Damage/status values above remain current baselines until retuned.

| Class | Combo | Stamina | Preparation before agility | Timing purpose / proposed change |
|---|---|---:|---:|---|
| Archer | Twin Shot | 2 | 6 | Flexible pair |
| Archer | Piercing Bolt | 2 | 6 | Penetrating pair |
| Archer | Point-Blank | 2 | 5 | Earlier pressure and stagger |
| Archer | Quick Guard | 2 | 4 | Early shield and evasion |
| Archer | Field Dressing | 2 | 6 | Recovery competes with incoming damage |
| Archer | Steady Aim | 2 | 6 | Deliberate penetrating shot |
| Archer | Perfect Shot | 3 | 9 | Prepared precision; guaranteed-crit replacement still to tune |
| Archer | Storm of Shafts | 4 | 12 | Heavy suppression; targeting must be clear |
| Warrior | Crushing Blow | 2 | 6 | Reliable pair |
| Warrior | Wide Sweep | 2 | 6 | Damage reduction if it lands before the hit |
| Warrior | Earthshaker | 3 | 9 | Proposed +1 pending-action delay, once per round |
| Warrior | Riposte | 2 | 4 | Shield plus a single round-limited counter stance |
| Warrior | Second Wind | 2 | 5 | Earlier recovery/protection |
| Warrior | Executioner | 3 | 9 | Wounded-target finisher |
| Warrior | Warlord's Answer | 4 | 12 | Shield arrives with the heavy attack, not at wind-up |
| Warrior | Blood Tide | 4 | 12 | Large offensive recovery commitment |
| Rogue | Flurry | 2 | 6 | Reference quick pair: three beats after agility |
| Rogue | Opening Cut | 2 | 6 | Establish a wound before another action |
| Rogue | Twin Fang | 2 | 6 | Sustained-pressure pair |
| Rogue | Shadowstep | 2 | 5 | +1 next-action Haste once per round |
| Rogue | Patch Up | 2 | 6 | Recovery |
| Rogue | Hemorrhage | 3 | 9 | Exploit a pre-existing wound |
| Rogue | Vanishing Strike | 3 | 9 | Precision burst; does not gain unprinted evasion |
| Rogue | Thousand Cuts | 3 | 9 | Strong wound, slower than a protective opening |
| Magician | Fireball | 2 | 6 | Offensive pair |
| Magician | Ice Blast | 2 | 6 | Proposed +1 pending-action delay, once per round |
| Magician | Chill Ward | 2 | 4 | Quick emergency ward |
| Magician | Life Siphon | 2 | 6 | Damage-based recovery |
| Magician | Kindle | 2 | 5 | Faster fallback spell; no automatic native Burn |
| Magician | Blink | 2 | 4 | Early shield and evasion |
| Magician | Meteor | 3 | 9 | Slow heavy spell |
| Magician | Arcane Storm | 3 | 9 | Varied-rune pressure and suppression |
| Shared | Detonate | 2 | 6 | Requires two Bomb sources |
| Shared | Venom Coat | 2 | 6 | Requires two Poison sources |
| Shared | Steadied Strike | 2 | 6 | Attack plus recovery |
| Shared | Breach and Strike | 2 | 6 | Piercing pair |
| Shared | Envenomed Edge | 2 | 6 | Poison setup |
| Shared | Blinding Blast | 2 | 5 | Earlier offence/evasion |

Big combos should win on a clear specialty, not simultaneously on damage, healing, shield, speed, efficiency and god triggers. Compare plans using the same dice, stamina and enemy intent. Two pairs can distribute targets and land at different times; a large combo concentrates its output at one later time. Do not force every build toward the same answer.

## 18. Enemy agility and ability redesign

Each enemy needs base agility; each ability needs preparation time. These values are independent of animation duration. High agility does not grant extra actions. Multi-hit intents are one action unless separate follow-up beats are explicitly authored and revealed.

Suggested agility values and move roles below are new prototype parameters. Per-move preparation and damage must be authored together; the table is not a claim that every existing move has already been numerically rebalanced.

| Enemy | Agility | Proposed timing identity |
|---|---:|---|
| Straw Effigy | 0 | Harmless practice; no damaging action |
| Reed Lurker | 2 | Quick Snap from the Reeds; slower Thrashing Coils |
| Marsh Shade | 2 | Quick Cold Grasp; slower Keening and Feed on Breath |
| Sand Crawler | 2 | Quick Pincer; readable preparation for Skittering Swarm |
| Silt Colossus | 0 | Slow Silt Slam; deliberate protection |
| Ember Wraith | 2 | Quick Scorch; slower Conflagrate |
| Flamekeeper | 1 | Slow Open the Furnace; relatively quick Brazier Shove |
| Ash Jackal | 3 | Fast Rend; visibly prepared Cinder Pounce |
| Bronze Effigy | 0 | Relatively quick Stamp; slow Furnace Burst |
| Devourer Spawn | 1 | Heavy Maul; longer Gorge recovery |
| Shadow of the Uncreated | 3 | Quick Fade from the Light; slower Wail of the Void |
| Hour-Eater | 1 | Explicit, bounded manipulation of pending action timing |
| Boneplate Devourer | 0 | Heavy Maul; quicker, weaker Gnaw |
| Sekhen | 1 | Faster Reed Lash; slower Haul the Barque |
| Nehebkau | 1 | Moderate Constrict; longer Molten Coil preparation |
| Apep | 2 | Phase-specific rhythms; clear quick pressure and heavy commitments |

Fast strikes need smaller damage/status budgets. Slow characters must have viable answers through quick basic defence, opening/persistent shield or appropriately tuned HP—not require every player to acquire Haste. Packs need encounter-level timing budgets so several fast attackers do not produce unavoidable lethal openings.

Hour-Eater delays may move a future player action but never erase spent stamina or create an unrevealed action. Boss transitions reveal changed schedules before the next commitment. Future charged attacks spanning rounds would require their own explicit design; they are not assumed here.

Current enemy source: [EnemyContent.swift](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Content/EnemyContent.swift). Current engine source: [BattleEngine.swift](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/ViewModels/BattleEngine.swift). Enemy names and current combo baselines come from the repository inspected during this conversation; all agility values here are proposals.

## 19. Interface and implementation changes

- Replace die ownership by gods with character-level boon cards grouped as Attack, Defence and Utility.
- Show six active slots, held markers and the two undrawn dice. Offer inspection of the entire eight-die collection.
- Show stamina now, actual plan cost, next-round bonuses and overflow against the six-stamina cap.
- Let the player select a smaller recipe or dissolve an automatically suggested large combo. Never force the largest recipe when timing makes smaller actions desirable.
- Show a combined timeline with action names, targets, preparation, god contributions and enemy intents. Reordering must immediately update the preview.
- Warn when a planned shield/heal arrives after a dangerous hit; show evasion and conditional reactions as probabilities or branches rather than guarantees.
- Preview Haste, bounded delays, protection expiry and fallback targets. Do not hide a timing change behind an animation.
- Display new-boon rarity before selection. Display duplicates as before/after level upgrades that keep rarity.
- Persist generated reward offers. Remove all remaining relic grants and repair recipes/rewards that depended on them.
- Expand each current starter kit from its source-defined four weapon/two armour dice to the proposed five weapon/three armour collection. Choose the added die's faces deliberately for recipe reachability; exact new face distributions remain to be authored.
- Replace the separate player/enemy resolution loops with a scheduler that resolves one shared timeline and one round-settlement pass.
- Migrate old phase-based boons, counters and status durations to the explicit round rules above.
- Keep the preview and actual resolution on the same calculation rules, including shield consumption, missing-HP bonuses, eligibility and timing changes.
- Retune combo critical signatures, native statuses, lifesteal, large-combo damage and enemy move damage together. Do not treat the old numbers as balanced merely because they compile.

## 20. What is settled versus still to tune

The design direction is eight owned dice/six active slots; meaningful holds; stamina ramp; character-owned overlapping gods; shown-before-selection rarity; repeat selections increasing level only; and interleaved agility-based combat.

Numerical tuning remains open: extra starter-die faces, per-enemy move preparation/damage, replacement critical-signature values, rarity/level curves and caps, status conversions, exact score formula, and whether every large combo has a worthwhile but sufficiently narrow payoff. The proposed matrices make these testable without claiming the balancing work is finished.

Start validation with all four class identities but a small god/encounter slice. Check: a slow class can defend a reasonable opening; a fast class cannot cancel every enemy for free; two small moves sometimes outperform a large one on survival/targeting; large prepared combos still feel rewarding; all displayed boon and timing contributions match resolution.
