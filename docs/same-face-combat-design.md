# DiceRoller: Same-Face Combat Rework
## Complete proposed rules and content catalogue
Design version 1.0 • 19 September 2026

**Status:** proposed replacement design, grounded in the current `JamesHR99/rork-diceroller-ios` source. This document does not change game code. All numerical values are initial prototype values, not validated balance.

**The rule:** combine one to six separate physical dice showing exactly the same face. Arrow I combines with Arrow I; Arrow II with Arrow II. Different die names, equipment origins, materials and critical states do not prevent a match. A one-die action is the first tier, although “combo” in boon text means two or more dice.

The objective is to make constructing an action immediate to understand, while keeping choices about rerolls, splitting groups, targets, defence, statuses, build composition and commitment.

## 1. What this replaces

Current Swift source takes precedence over older design notes when describing the starting point. The current source uses six active dice, one single-die reroll with a maximum of two, guaranteed Dodge charges, an alternating action queue, same-round kept results, and some mixed recipes. The older GAME_REWORK.md describes stamina, agility and cross-round freezing; those are not the foundation of this proposal.

| System | Proposed rule |
|---|---|
| Collection | Eight physical dice: five weapon, three armour; draw six without replacement each round. |
| Matching | Exact effective face identity, group size 1–6. No mixed recipes or “any arrow” grouping. |
| Action budget | Each drawn die can be used once. No separate player stamina cost. |
| Rerolls | Two selective reroll passes each round; a pass rerolls any nonempty chosen subset. Bonuses raise the allowance to at most three. |
| Kept results | A die retained through an actual reroll is Prepared for this round. No cross-round freezing. |
| Timing | Alternating player and enemy events. Attack groups of 4–6 require a wind-up event before their release. |
| Defence | Shield and guaranteed, assigned Dodge charges; no random evade percentage. |
| Criticals | Rolled once with each face. Deterministic contribution to the action; no second combo-critical lottery. |
| Gods | Character-equipped boons; no patron-per-die requirement, no mixed-ingredient conditions. |
| Ptah | Two class-specific Chisels maximum; actual face conversions, targeting or resource trade-offs. |
| Growth | Reforge face distributions, improve crit, choose boons and level them; do not inflate the number of owned dice. |

The change from one single-die reroll to two selective passes is deliberate. Without better matching control, five- and six-of-a-kind would mostly be catalogue entries players never experience. Two passes provide the familiar decision “keep this useful pair, or chase a larger group?”

## 2. The complete round

1. Reveal all enemy actions and individual strikes for the round. Draw six of the eight owned dice, then roll all six.
2. Gain two reroll passes plus earned bonuses, maximum three. Opening roll costs no pass.
3. Select any subset to reroll. Each confirmed nonempty subset costs one pass, regardless of its size. Unselected dice retain face and critical state and become Prepared.
4. Form exact-face groups. Choose their sizes, targets and order. A group of four may be one four, two pairs, a triple plus solo, or four solos.
5. Assign guaranteed Dodges to visible strikes. Set optional Chisel costs and secondary targets. View the complete event queue and projected consequences.
6. Commit. Lock all dice identities, groups, targets and reserved costs. Resolve the queue. A face is never reused.
7. Settle statuses and expiring effects. Return all eight physical dice to the collection for the next fresh draw. Unused results and reroll passes disappear.

A Prepared die is not locked or frozen. It can be rerolled later; doing so removes Prepared from that new result until another real reroll retains it. Rerolling all six creates no Prepared dice. Merely opening the reroll selector or converting a face does not make it Prepared. There is no automatic freeze effect during preroll.

Canceling or editing a plan before commitment is free. Refund a Chisel reservation when unarmed, but never refund an already executed reroll. Empty rerolls are illegal. Undoing a random result is illegal. Save the roll and reward RNG state so reloading cannot reroll either.

## 3. Dice, equipment and reaching six-of-a-kind

### Starting distributions

Every row below is one physical six-sided die. Repeat the row five times for weapon and three times for armour. Individual sides are equally likely. This is a proposed redistribution, not a description of the current loadout.

| Class | Weapon die: six sides | Armour die: six sides |
|---|---|---|
| Archer | Arrow I, Arrow I, Arrow II, Arrow II, Arrow III, Focus | Arrow I, Bow Smack, Block, Block, Evade, Heal |
| Warrior | Overhead, Overhead, Overhead, Side Swing, Side Swing, Block | Overhead, Block, Block, Heal, Focus, Focus |
| Rogue | Swift Slash, Swift Slash, Dagger Throw, Dagger Throw, Evade, Poison | Swift Slash, Evade, Evade, Heal, Focus, Block |
| Magician | Fire, Fire, Frost, Arcane, Wand Zap, Channel | Fire, Frost, Life, Life, Arcane, Channel |

Giving armour one primary attack face lets every starting class potentially roll six of its principal face. The loss of a defensive side is a real price. Magician retains its rune-only identity: Frost supplies early defence, Life healing, Channel protection and setup.

Six Arrow II, Arrow III, Bow Smack, Side Swing, Dagger Throw, Poison, Wand Zap or shared support faces may require reforging. The codex must say which tiers are currently reachable; it must never imply that five weapon dice can produce six weapon-only results.

### Reforging and specialization

- A reforge changes one side on one selected physical die into a chosen face from that class's legal palette.
- Either equipment family may receive any legal class face. Weapon/armour remains the item's origin, not a matching restriction.
- Archer palette: four Archer faces plus Block, Evade, Heal, Focus.
- Warrior palette: Overhead, Side Swing, Block, Heal, Focus. No native Evade.
- Rogue palette: Swift Slash, Dagger Throw, Poison, Block, Evade, Heal, Focus.
- Magician palette: Fire, Frost, Life, Arcane, Wand Zap, Channel. No shared Block/Evade/Heal/Focus sides.
- Limit any one face to three sides of each die. Never create deterministic six-identical-side dice.
- Replacing a whole die preserves eight owned dice. Show lost face access and crit investments before accepting.
- Reforges preserve the edited side's crit upgrade. Imbues belong to that side, not to a face name globally.
- Equipment rarity governs offer quality and the crit upgrade budget, not an additional hidden damage multiplier.
- Add an equipment preview: “Arrow II appears on 5/8 dice; largest possible natural group: 5.” Count physical dice containing a face, not total copies of its sides.
- Chisel-assisted reachability is a separate badge. A conversion still consumes a real sixth die.

Suggested die specializations: Archer Penetrator (three Arrow II sides); Warrior Sweeper (three Side Swing); Rogue Venomer (three Poison); Magician Ember Wand (three Fire). Armour versions trade defence for the same specialization. Higher rarity should improve a useful distribution or crit investment, not simply erase all defensive choices.

### How often should large groups appear?

For six active dice each with probability p of the desired face, two selective reroll passes devoted entirely to that face give per-die success q = 1 − (1 − p)^3. All six match with probability q^6.

| Desired face probability on each drawn die | Six match after up to two passes |
|---|---:|
| 1/6 | Approximately 0.56% |
| 2/6 | Approximately 12.1% |
| 3/6 | Approximately 44.9% |

These are idealized fixed-hand calculations, not measured run frequencies. Actual hands mix distributions, and keeping defence or spending a pass on a Chisel lowers the opportunity. Sixes should be uncommon in an opening build and deliberate in a specialized late build. Reachability is necessary but does not guarantee frequency.

## 4. Group size, action order and commitment

| Dice | Role in the game | Player events | Typical decision |
|---:|---|---:|---|
| 1 | Reliable basic move | 1 | Set up, finish a weak foe, defend immediately. |
| 2 | Efficient technique | 1 | Reliable daily combat, especially with pair boons. |
| 3 | Signature | 1 | Strong payoff while leaving three dice for another action. |
| 4 | Heavy technique | 2 for Attacks; 1 otherwise | Commit damage while retaining two dice for protection. |
| 5 | Finisher | 2 for Attacks; 1 otherwise | Reserve one defensive or setup die. |
| 6 | Apex | 2 for Attacks; 1 otherwise | Entire hand committed; no separate defence from dice. |

For a 4–6 die Attack, insert **Wind-up** followed by **Release** into the player queue. Interleave the enemy queue between those events in the normal way. Wind-up causes no damage, healing, shield, critical event, status or boon activation. The group counts as one action when its Release resolves. Pure support or defensive groups resolve in one event; they already sacrifice the entire offensive hand at six.

Build the global enemy queue from revealed enemy actions in stable enemy order, one first action per foe, then second actions, and so on. Alternate one player event and one enemy event, starting with the player unless an explicitly previewed encounter ambush gives enemies the opening event. Exhausted queues simply stop contributing. Grouping never deletes enemy actions.

**Example, four Overheads, two Blocks; enemy has E1 and E2:**

- Four Overheads first: Wind-up → E1 → Release → E2 → Block pair.
- Block pair first: Block pair → E1 → Wind-up → E2 → Release.
- Two Overhead pairs: Pair → E1 → Pair → E2 → Block pair.

The heavy move earns better output but exposes the hero during preparation. The Block-first plan gains safety; the pair plan attacks sooner. If E1 is lethal without protection, a large damage number does not make the first plan sensible.

Damage never spontaneously interrupts wind-up. Death cancels pending events. Retarget a dead target to the next living foe in the player's visible fallback order, without moving the event earlier. Do not refund committed dice or Chisel costs.

Delay moves one pending enemy event to immediately after the next player event. If no later player event exists it has no effect. Limit to one successful delay per enemy per round; bosses follow the same rule unless a visible boss trait explicitly modifies it. Delay cannot repeatedly move the same event or grant another player action.

## 5. Shared effect rules and calculation order

### Definitions

**Attack:** native direct damage OR hostile native status application, including Poison. This makes Poison a useful offensive build with god support; a flat damage boon can give it a direct hit.

**Guard:** native shield. **Evade:** native Dodge charges. **Support:** native healing, Regen or Focus. Roles can overlap. Boon-granted shield or Dodge does not create a new role and cannot trigger another role's boons. A move with two native roles can trigger both sets once each. A Guard/Attack cannot satisfy “after a separate Guard” using itself.

**Small:** 1–2 dice. **Signature:** 3. **Heavy:** 4–6. **Combo:** 2–6. **Prepared action:** at least one ingredient retained through a real reroll this round. Unless stated otherwise, “first” and all action counters reset each round. Count resolved actions, never animation hits, dice, wind-up or echoes.

### Status and defence glossary

| Effect | Proposed exact rule |
|---|---|
| Damage D | Native direct damage before crit and bonuses. Single target unless splash is printed. |
| Shield S | Absorbs direct damage before HP. Cap 100. Clears at round end; Warrior carries at most 8 into the next round. Clears between encounters. |
| Dodge Q | One charge avoids one assigned incoming strike and its on-hit effects. Cap 6. Assigned strike must occur after the Dodge action resolves. Expires round end. |
| Unassigned Dodge | Automatically avoids the next eligible strike. If its assigned strike is canceled, becomes unassigned for the rest of this round. |
| Marked M | One token per target: next primary player Attack with positive direct damage gets +M% direct damage against that target, then consumes it. Strongest token wins; default expiry end of following round. |
| Weaken W | Next non-dodged damaging enemy action deals W% less direct damage, across all strikes in that action. Strongest wins, cap 50%. Expires end of following round if unused. |
| Burn B | Adds potency, cap 12. Deals B direct HP damage at round end, then halves, rounding down. |
| Bleed L | Strongest potency wins, cap 10. Lasts two round-end ticks; application refreshes duration. |
| Poison P | Adds potency, cap 8. At round end deals P direct HP damage, then grows by 1 to the cap while positive. Persists until cleanse or combat end. |
| Judgement J | Adds to cap 30. A primary Attack group of at least 3 releases the target's ledger after this action's additions, once per action. Deal the stored amount as direct HP damage, then clear it. No escalating multiplier or timed verdict. |
| Pierce X | X% of direct damage bypasses both Shield and Armour. Rest meets Shield, then Armour, then HP. Armour is a non-regenerating encounter pool. Cap 100%. |
| Regen R | Heal R at this and next round-end; strongest wins and refreshes duration. |
| Focus F | The next separate primary Attack gains +F% direct damage. Strongest Focus wins. Expires at end of next round; consumes on that Attack even if it only applies a status. |
| Cleanse C1 / Call | Remove one / all of the hero's Burn, Bleed, Poison, Marked, Weaken and Judgement. Select C1 priority during planning. |
| Early tick | Deal current status potency immediately without decay, growth or duration loss. It is secondary damage. |
| Retaliation | Printed damage when a qualifying enemy hit occurs. Secondary; no Attack counters or god recursion. |

DoT damage ignores shield and armour and cannot be Dodged. Only explicit cleansing or death prevention can answer it. Bosses can receive these statuses; no undocumented immunity. Player status rules mirror enemies. Player Judgement from a trial is a separate enemy-authored timed sentence with its own visible expiry.

An enemy Dodge avoids its specified next direct-damage packet; it does not cancel the entire multi-packet action. Marked and Focus are consumed when an eligible Attack attempts its positive direct-damage packet, including one avoided by an enemy Dodge; do not promise a retained prime on a miss. Hostile status riders of a completely Dodged primary packet do not land, while status-only Poison is not a direct strike and cannot be Dodged. A multi-hit animation is normally one mechanical damage packet. Twin Bowstring explicitly creates two packets. Apply Marked once to the combined budget directed at its marked primary target, rather than letting one tiny arrow consume it. Splash and echoes do not consume Marked. New Marked is applied after the action's old Marked is consumed, so it benefits a later action.

### Criticals

Each side has a base 10% critical chance. Imbues add +5 / +8 / +12 / +15 percentage points according to offer material; final per-side critical chance caps at 40%. This replaces the old face-dependent critical chance and combo lottery.

For group size n with k critical dice:

**Native multiplier = 1 + 0.5 × k/n.**

Apply it to native direct damage, native shield and immediate native healing. Also apply it to the Poison amount on Poison-face actions and the Focus percentage on Focus-face actions; caps still apply. Channel's shield benefits; its Focus percentage does not. Dodge counts, statuses on damaging attacks, Marked, Weaken, Pierce, Regen, timings and god/Chisel additions do not crit.

- Solo critical: ×1.5.
- Pair with one critical: ×1.25.
- Triple with one critical: ×1.1667.
- Six dice with three criticals: ×1.25.
- All six critical: ×1.5, not ×2 and not another random roll.

The proportion rule keeps a critical die useful without making one lucky ingredient double a six-die finisher. An action containing at least one critical ingredient qualifies for “critical ingredient” boons, even if its native Dodge has no scalable quantity. Such faces show “critical ingredient” rather than promising an extra Dodge.

Every reroll rerolls both the selected face and its critical state. Kept dice retain both. Conversion preserves the original die's critical state and cannot reroll it.

### Ordered action resolution

1. Capture pre-action target statuses, HP and player shield. Determine eligible boons and prepared/critical/size/sequence conditions.
2. Validate and pay optional Chisel costs. A cost that cannot be paid disables that Chisel's effect; the native action still resolves. Show conditional payments in preview.
3. Scale native numeric outputs for criticals. Add flat damage from eligible gods and Chisels.
4. Sum eligible additive damage percentages, including Focus, existing Marked, Chisels and boons; cap positive bonus at +200% separately for each target packet. Multiply once. Marked applies only to damage directed at its marked primary target; a conditional percentage is evaluated for that packet's own target. Global Focus and action-wide bonuses may scale native splash. Round each final packet down, not each intermediate modifier.
5. Split packets or assign splash from the native damage budget as specified by a Chisel. Divine flat damage and status riders go only to the primary packet/target.
6. Resolve direct damage with Pierce and defences. Apply native shield/healing/Dodges. Consume old Marked and Focus as appropriate.
7. Apply native and divine statuses to surviving targets; batch additive statuses before caps and strongest-wins effects before choosing their potency.
8. Execute explicit early ticks, then release Judgement for a qualifying group. Crown of Noon is an explicit ordering override: consume only the snapshotted old Burn before batching new Burn applications in step 7. Apply healing/retaliation primes and update primary action counters once.
9. Check defeat after every harmful packet. Finish combat immediately when all foes die; no healing or farming actions after the victory.

Flat additions receive percentage bonuses but do not crit. Shield granted by a boon arrives at this action's resolution, never during wind-up. Same-name primes refresh to the stronger value rather than accumulating. Different named effects coexist within their caps.

Round end: delayed echoes are not processed here; first resolve any explicitly pre-tick boon such as Boiling Nile, then resolve Burn, Bleed, Poison on each living actor in stable visible order, checking death after each tick; then Regen, then end-round boons; expire Dodges and short effects; apply shield carry. A dead actor cannot be healed by later settlement.

## 6. Reading the move catalogue

All values below are the **complete native result for that tier**, not bonuses added to lower tiers. No old solo penalty or length multiplier is applied. Higher tiers retain only clauses explicitly printed in their row.

D = damage, S = shield, H = immediate healing, Q = Dodge charges; B/L/P/J = Burn/Bleed/Poison/Judgement; M/W/X/F = Marked/Weaken/Pierce/Focus percentage. “Splash N” deals N native direct damage to one selected secondary foe; it is not per enemy. “All” means all living foes or all removable self-statuses as stated. Values before modifiers.

All classes have six tiers for every face in their legal palette. Shared Block/Heal/Focus tables are reused, while each class's native face access remains distinct. This catalogue contains 19 unique face ladders × 6 tiers = **114 defined actions**. Reusing shared ladders gives Archer 48 accessible class-tier entries, Warrior 30, Rogue 42 and Magician 36; higher tiers may require reforging.

## 7. Archer: precision and target selection

Arrow I establishes Marked; Arrow II punches through protection; Arrow III spends more build investment for a heavy single-target hit. Bow Smack is an emergency defensive attack. Names communicate progression without requiring the player to learn another recipe.

### Arrow I

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Quick Shot | D8. |
| 2 | Twin Shot | D18; M20. |
| 3 | Hunter's Volley | D30; M25. |
| 4 | Storm of Shafts | D44; M25; splash 10. |
| 5 | Rain of Arrows | D60; M30; splash 16. |
| 6 | Skyfall Volley | D78; M35; splash 24. |

### Arrow II

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Piercing Shot | D10; X20. |
| 2 | Piercing Bolt | D22; X30. |
| 3 | Armourbreaker | D36; X40. |
| 4 | Siege Bolt | D52; X50; W20. |
| 5 | King's Bane | D70; X60; W25. |
| 6 | Horizon Splitter | D90; X75; W30. |

### Arrow III

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Heavy Shot | D12. |
| 2 | Deadeye | D27; X15. |
| 3 | Perfect Shot | D45; X25. |
| 4 | Execution Shot | D64; X30; +15% damage if target was Marked. |
| 5 | Royal Execution | D85; X40; +20% damage if target was Marked. |
| 6 | The Last Arrow | D108; X50; +25% damage if target was Marked. |

Perfect Shot has authored damage and Pierce; the old guaranteed ×2 critical is removed. Arrow III specialization sacrifices common Arrow I/II matching and defensive sides.

### Bow Smack

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Bow Smack | D5; W15. |
| 2 | Point-Blank | D12; S6; W20. |
| 3 | Break Contact | D21; S10; W25. |
| 4 | Turning Strike | D32; S14; W30. |
| 5 | Bowguard Assault | D45; S18; W35. |
| 6 | Unbroken Bow | D60; S24; W40; Q1. |

Even a six-die Bow Smack gains protection only on Release. It is not a replacement for an early Block against a lethal opening.

## 8. Warrior: heavy blows and a standing defence

Native passive: carry up to 8 remaining Shield into the following round. Remove any separate hidden momentum multiplier; the move ladder and boons supply offensive scaling.

### Overhead

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Overhead | D12. |
| 2 | Crushing Blow | D27. |
| 3 | Earthshaker | D44; W20. |
| 4 | Warlord's Answer | D62; S10; W25. |
| 5 | Thronebreaker | D83; S14; W30. |
| 6 | Judgement of Steel | D106; S18; W35; X30. |

### Side Swing

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Side Swing | D9. |
| 2 | Wide Sweep | D20; splash 6. |
| 3 | Cleaving Arc | D33; splash 11. |
| 4 | Whirlwind Crush | D48; splash 18; W20 on primary. |
| 5 | Blood Tide | D65; splash 26; heal 20% of native HP damage dealt, maximum 10. |
| 6 | Last Stand | D84; splash 36; heal 20% of native HP damage dealt, maximum 14; W25 on primary. |

Native lifesteal counts actual HP damage from main and native splash, excluding overkill, shield, armour, divine riders and Chisel splash. It cannot heal from a dead target beyond its remaining HP.

## 9. Rogue: wounds, venom and deliberate Dodges

The Rogue keeps its lower HP and access to Evade on both equipment families. It does not receive a new speed stat.

### Swift Slash

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Swift Slash | D7. |
| 2 | Flurry | D16; L3. |
| 3 | Thousand Cuts | D27; L5. |
| 4 | Veiled Assault | D40; L6; Q1. |
| 5 | Nightfall Ambush | D55; L8; Q1; M20. |
| 6 | Vanishing Strike | D72; L10; Q2; M25. |

### Dagger Throw

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Dagger Throw | D9; L2. |
| 2 | Twin Fang | D20; L4. |
| 3 | Hemorrhage | D33; L6; +15% damage against a target already Bleeding. |
| 4 | Red Horizon | D48; L7; +20% damage against a target already Bleeding. |
| 5 | Death's Reach | D65; L8; one early Bleed tick after application. |
| 6 | The Final Fang | D84; L10; one early Bleed tick after application; X30. |

### Poison

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Venom | P2. |
| 2 | Coated Edge | P3; W15. |
| 3 | Creeping Death | P4; W20. |
| 4 | Withering Touch | P5; W25; S10. |
| 5 | Serpent's Dance | P6; W30; S16; Q1. |
| 6 | Death by Inches | P8; W35; S22; Q1; one early Poison tick after application. |

Poison is an Attack for grouping and gods. Its 4–6 tiers wind up even without direct damage. Its native critical applies to P and any native shield, not to flat divine damage. The cap can make crit potency redundant at six; previews show the capped result. Large Poison groups buy immediate suppression, protection and an early tick rather than claiming their long-term DoT is six times a solo's.

## 10. Magician: six readable spell families

The Magician uses only Fire, Frost, Life, Arcane, Wand Zap and Channel. Removing mixed rune recipes must not remove access to survival: a lone Frost provides shield, a lone Life heals, and Channel gives a small ward.

### Fire Rune

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Ember | D7; B1. |
| 2 | Fireball | D17; B3. |
| 3 | Meteor | D30; B4. |
| 4 | Inferno | D45; B6; splash 10. |
| 5 | Phoenix Fire | D62; B8; splash 16; H8. |
| 6 | Sunfall | D81; B10; splash 24; H12. |

Burn goes to the primary target only. Fire splash does not silently burn other enemies.

### Frost Rune

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Frost Ward | D4; S5; W10. |
| 2 | Ice Blast | D10; S10; W20. |
| 3 | Glacier | D18; S16; W30; delay one pending action. |
| 4 | Glacial Passage | D28; S23; W35; delay one pending action. |
| 5 | Winter Bastion | D40; S31; W40; delay one pending action. |
| 6 | Stillness of the Duat | D54; S40; W50; delay one pending action. |

Frost 4–6 still winds up. Glacier's delay can help a following player action; with no player event left, it cannot delete the enemy's turn.

### Life Rune

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Mend | H7. |
| 2 | Mending Bloom | H15; R2. |
| 3 | Sanctuary | H24; S8; R3. |
| 4 | Wellspring | H34; S14; R4. |
| 5 | Phoenix Rite | H45; S20; R5; C1. |
| 6 | Garden of Eternity | H57; S28; R6; Call. |

Life is Support, plus Guard from tier 3. It is not an Attack. Its six-die version costs the complete hand but resolves without wind-up.

### Arcane Rune

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Arcane Dart | D9; X20. |
| 2 | Arcane Barrage | D21; X30. |
| 3 | Arcane Storm | D35; X40; M20. |
| 4 | Astral Lance | D51; X50; M25. |
| 5 | Astral Reversal | D69; X60; M30; S10. |
| 6 | The Final Word | D89; X75; M35; S16. |

### Wand Zap

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Spark | D8. |
| 2 | Chain Spark | D18; splash 5. |
| 3 | Stormcall | D30; splash 10; W15 on primary. |
| 4 | Thunderchain | D44; splash 16; W20 on primary. |
| 5 | Tempest | D60; splash 23; W25 on primary. |
| 6 | Sky Unbound | D78; splash 31; W30 on primary. |

### Channel

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Channel | S4; F25. |
| 2 | Deep Channel | S9; F40. |
| 3 | Runic Ward | S15; F55. |
| 4 | Prism Ward | S22; F70; Q1. |
| 5 | Solar Aegis | S30; F85; Q1; C1. |
| 6 | Astral Covenant | S40; F100; Q2; C1. |

All Channel tiers are Guard and Support. Tiers 4–6 also qualify as Evade. Focus persists into the next round, allowing a six-Channel hand to prepare a later attack. No extra reroll is generated natively.

## 11. Shared defence and preparation ladders

These moves are available only where the class's legal face palette permits them. Reusing the table avoids four separate definitions of what Block means.

### Block — Archer, Warrior and Rogue

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Block | S8. |
| 2 | Brace | S18. |
| 3 | Bulwark | S30; arm one retaliation for 50% of shield absorbed by the next hit, maximum 8 damage. |
| 4 | Iron Wall | S43; same retaliation, maximum 12. |
| 5 | Fortress | S57; same retaliation, maximum 16. |
| 6 | Unbroken Gate | S72; same retaliation, maximum 20; C1. |

Retaliation is direct damage against the attacker, meets its defences, expires this round, and does not qualify Block as Attack. Higher shield is useful against packs; it is not permanent invulnerability.

### Evade — Archer and Rogue

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Sidestep | Q1. |
| 2 | Disengage | Q2; S3. |
| 3 | Shadowstep | Q3; S6; M20 on one chosen foe. |
| 4 | Ghostwalk | Q4; S10; M25 on one chosen foe. |
| 5 | Phantom Dance | Q5; S15; M30 on one chosen foe; C1. |
| 6 | Beyond Reach | Q6; S21; M35 on one chosen foe; Call. |

Evade's offensive mark does not make it an Attack. Unneeded Dodge charges expire. Six Evades are a specialist recovery/setup hand, not six guaranteed rounds of safety.

### Heal — Archer, Warrior and Rogue

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Field Dressing | H8. |
| 2 | Patch Up | H17. |
| 3 | Second Wind | H27; C1. |
| 4 | Rally | H38; S6; C1. |
| 5 | Renewed Vigor | H50; S12; Call. |
| 6 | Refuse the Grave | H63; S20; Call. |

Healing cannot revive the hero. At full HP, its healing portion is zero; cleanse and shield may still have value.

### Focus — Archer, Warrior and Rogue

| Dice | Move | Complete effect |
|---:|---|---|
| 1 | Focus | F50. |
| 2 | Steady Aim | F65. |
| 3 | Perfect Preparation | F80; S4. |
| 4 | Battle Trance | F95; S8. |
| 5 | Unshakable Intent | F110; S12. |
| 6 | Moment of Destiny | F125; S16; C1. |

Focus is a separate Support action, never an extra ingredient in an attack group. A six-Focus hand prepares next round. A critical pure Focus action scales F by the contribution rule, subject to the global +200% damage-bonus cap when spent; its shield scales normally too. Channel and Focus primes share one strongest-wins slot.

**Legacy Energize:** remove from new rewards and convert old saved sides to Focus, or Channel for Magician. It is an alias migration, not a twentieth ladder. “Any arrow,” “any strike,” distinct-rune and mixed Block/Attack recipes are retired.


## 12. Gods: build structure, rarity and offers

Keep six gods and the current catalogue's names where they still fit. Each god has ten regular boons: five Attack, three Defence, two Utility. This supplies **60 regular boons**, plus **15 duos** and **six legendary evolutions** below.

Equip three Attack, two Defence and two Utility boons. A boon is attached to the hero, applies to all qualifying class faces, and works without patron dice or a separate basic blessing. Different gods may coexist. Maximum two duos and one acquired legendary evolution per run, all within these seven slots.

- New scalable boons arrive at Common, Rare or Epic, Level 1.
- The three bold values in a row are Common Levels 1/2/3.
- Rare: multiply only the designated bold value by 1.25 and round up. Epic: multiply it by 1.50 and round up.
- Percentage values are percentage points, not multiplicative factors. Only the bold number scales; caps still apply.
- Fixed Utility boons and duos have no rarity or levels.
- A duplicate increases the existing boon's level up to 3, retaining rarity and its slot.
- Replacing a boon does not transfer its level.
- Show new boon rarity before selection. Opening region odds: 75% Common, 23% Rare, 2% Epic; middle: 45/40/15; final: 20/45/35.
- Example: Solar Flare Common L1/L2/L3 = 6/8/10 extra damage; Rare = 8/10/13; Epic = 9/12/15.
- Avoid upgrades whose entire practical effect is permanently capped in the current build.

**First meeting:** after the Straw Effigy, visit one uniformly random god and choose one of three usable offers. Guarantee one immediately useful Attack option. No relic replacement, no allegiance lock.

**Later offers:** three distinct usable choices, mixing new powers, eligible level upgrades and unlocked milestones. A full slot can offer a replacement with its losses visible. The player's palette and current equipment determine usability: do not offer the Warrior an Evade-only power, or a four-die condition when no current ladder can reach four, unless the offer explicitly includes the equipment change required.

All six gods must support more than “make the biggest group.” Ra emphasizes heavy commitment; Sobek wound setup; Anubis building then releasing Judgement; Bes protection and follow-through; Horus critical precision and preparation; Bastet solos and pairs.

### Ra — commitment, Burn and repeated pressure

| ID / slot | Boon | Complete reworked effect |
|---|---|---|
| RA-A1 / Attack | Solar Flare | First 4–6 die Attack each round: +**6/8/10** damage and B4 on primary. |
| RA-A2 / Attack | Scorching Sequence | First Attack: B**3/4/5**. Second Attack adds B2 if it targets that same living foe. |
| RA-A3 / Attack | Sun's Wrath | First Prepared Attack: +**6/8/10** damage and B2. |
| RA-A4 / Attack | Noon Spear | First Focus-enhanced Attack: +**20/25/30** percentage points Pierce and B3. |
| RA-A5 / Attack | Sun's Edge | All Attacks against an already Burning primary target gain +**10/15/20**% damage. Each Attack adds B1 per ingredient, maximum 3 per action. |
| RA-D1 / Defence | Solar Guard | First Guard action: +S**4/6/8**. Arm the next hit absorbed by shield this round to apply B3 to its attacker. |
| RA-D2 / Defence | Cinder Step | First Evade action arms the next successful Dodge this round to apply B**3/4/5** to its attacker. |
| RA-D3 / Defence | Sunset Shelter | First Guard of 3+ dice: +S**6/8/10**; arm the next shield-absorbed hit this round to apply B2 to all living foes. |
| RA-U1 / Utility | Dawn Breath | Start each encounter with S8. Fixed. |
| RA-U2 / Utility | Banked Embers | Resolve a 4–6 die Attack to gain one extra reroll pass next round, once per round; total pass cap 3. Fixed. |

### Sobek — Bleed, Poison and survival through pressure

| ID / slot | Boon | Complete reworked effect |
|---|---|---|
| SO-A1 / Attack | Twin Fangs | First two-die Attack: +**4/6/8** damage and L3. |
| SO-A2 / Attack | Blood Scent | First Attack applies L3. All Attacks against an already Bleeding primary target gain +**10/15/20**% damage. |
| SO-A3 / Attack | Death Grip | First Prepared Attack: +**5/7/9** damage and P2. |
| SO-A4 / Attack | Feeding Frenzy | Second Attack applies L3; if its native direct damage removes any HP, heal **3/4/5**. |
| SO-A5 / Attack | Jaws of the Nile | First 3+ die Attack applies L**4/5/6**. If the target was already Bleeding, pay one early Bleed tick after application. |
| SO-D1 / Defence | Crocodile Armour | First Guard: +S**4/6/8**; arm the next shield-absorbed hit this round to apply L3 to its attacker. |
| SO-D2 / Defence | River Slip | First Evade arms the next successful Dodge this round to heal **3/4/5**. |
| SO-D3 / Defence | Blood Shelter | First Prepared Guard: +S**5/7/9**, and H3. |
| SO-U1 / Utility | Blood Reserve | Start a round at half HP or less to gain S6. Fixed. |
| SO-U2 / Utility | Patient Hunter | First Prepared action each encounter heals 4 and grants S6. Fixed. |

Native and divine early ticks of the same status from one action merge into one tick, using that status's final potency. Jaws plus The Final Fang does not pay two Bleed ticks. That is a consistent anti-duplication rule, not a hidden exception.

### Anubis — build Judgement, choose its release

| ID / slot | Boon | Complete reworked effect |
|---|---|---|
| AN-A1 / Attack | Scales of War | First Attack after a separate Guard this round: add J**6/8/10** and gain S4. |
| AN-A2 / Attack | Second Reading | Every Attack adds J**1/2/3** per ingredient, maximum 12 per action. |
| AN-A3 / Attack | Sealed Fate | First Prepared Attack: +**5/7/9** damage and J5. |
| AN-A4 / Attack | Final Sentence | First 3+ die Attack: +20 percentage points Pierce and J**6/8/10** before its normal release. |
| AN-A5 / Attack | Borrowed Time | First Attack against a target already below half HP: +**6/8/10** damage and J4 if it survives. |
| AN-D1 / Defence | Tomb Ward | First Guard: +S**4/6/8**; arm the next shield-absorbed hit this round to apply J5 to its attacker. |
| AN-D2 / Defence | Passing Shadow | First Evade arms the next successful Dodge this round to add J**5/7/9** to its attacker. |
| AN-D3 / Defence | Burial Cloth | First Prepared Guard: +S**5/7/9** and C1. |
| AN-U1 / Utility | Last Measure | Resolve actions using all six physical dice this round to earn one extra reroll pass next round, cap 3. Wind-up alone is insufficient. Fixed. |
| AN-U2 / Utility | Preserved Moment | Once each encounter, after rolling, select one result to become Prepared without spending a reroll. It does not change its face or crit. Fixed. |

Scales of War's old Block-inside-Attack condition is replaced by a separate Guard → Attack sequence. Judgement payoff is transparent: J18 followed by a qualifying three-die action adding J6 releases 24. A two-die action instead leaves the ledger available for later.

### Bes — safe openings, shield and counterattacks

| ID / slot | Boon | Complete reworked effect |
|---|---|---|
| BE-A1 / Attack | Sheltering Blow | Every Attack grants S**1/2/3** per ingredient, maximum S8 per action. If the hero had at least S8 before the action, gain +10% damage. |
| BE-A2 / Attack | Counter-Swing | First Attack after a separate Guard this round: +**6/8/10** damage and S4. |
| BE-A3 / Attack | Guardian's Hand | First Prepared Attack: +**5/7/9** damage and S5. |
| BE-A4 / Attack | Stalwart Advance | First two-die Attack: +**4/6/8** damage and W20 on primary. |
| BE-A5 / Attack | Unbroken Rhythm | Second Attack: +**5/7/9** damage and S4. |
| BE-D1 / Defence | The Stout Door | Every Guard action gains S**2/3/4** per ingredient, maximum S12 per action. Applies to native Frost/Channel/Life Guards as well as Block. |
| BE-D2 / Defence | Rebuild the Wall | Encounter start: S**6/8/10**. First time shield breaks this encounter, gain S8 after that hit; it cannot undo HP damage. |
| BE-D3 / Defence | Steady Footing | First Evade action: +S**4/6/8**. |
| BE-U1 / Utility | Hearth Breath | End a round with at least S8 to start the next with S6 in addition to native carry, shield cap 100. Fixed. |
| BE-U2 / Utility | Safe Keeping | First Prepared Guard each round gains S5. Fixed. |

### Horus — crit quality, Marked and deliberate setup

| ID / slot | Boon | Complete reworked effect |
|---|---|---|
| HO-A1 / Attack | Falcon's Eye | First Prepared Attack: +**15/20/25**% damage and +20 percentage points Pierce. |
| HO-A2 / Attack | Keen Edge | First Attack containing a critical ingredient: +**5/7/9** damage and +20 percentage points Pierce. |
| HO-A3 / Attack | Patient Aim | First 4–6 die Attack: +**15/20/25**% damage and +30 percentage points Pierce. |
| HO-A4 / Attack | Watchful Strike | First Attack after a separate Guard or Support this round: +**10/15/20**% damage; apply M25 after damage. |
| HO-A5 / Attack | High Flight | First Focus-enhanced Attack: +**15/20/25**% damage and +20 percentage points Pierce. |
| HO-D1 / Defence | Watchful Guard | First Prepared Guard: +S**5/7/9** and arm 20% reduction on the next non-dodged enemy damage action, expiring this round. |
| HO-D2 / Defence | Feather Step | First Evade: +S**3/5/7**; if Prepared, gain another S3. |
| HO-D3 / Defence | High Perch | First Guard: +S**4/6/8**. If it contains a critical ingredient, mark one chosen foe M20. |
| HO-U1 / Utility | Thermal | First Prepared action each round primes +15% damage for the next separate Attack; expires at end of next round. Fixed. |
| HO-U2 / Utility | Perfect Timing | Once per encounter, turn one rolled result critical before commitment. Uses the same deterministic contribution rule and does not reroll the face. Fixed. |

Thermal never buffs the action that earns it. Distinguish its separate named prime from native Focus; both may contribute additively.

### Bastet — solos, pairs and evasive sequences

| ID / slot | Boon | Complete reworked effect |
|---|---|---|
| BA-A1 / Attack | Pounce | First two-die Attack: +**4/6/8** damage and Q1. |
| BA-A2 / Attack | Quick Claws | First two solo Attacks each gain +**3/4/5** damage. |
| BA-A3 / Attack | Silent Approach | First Prepared Attack: +**5/7/9** damage; apply M20 after damage. |
| BA-A4 / Attack | Dancing Blades | First Attack after a separate Evade this round: +**6/8/10** damage and +30 percentage points Pierce. |
| BA-A5 / Attack | Ninefold Flurry | Third Attack action this round: +**8/10/12** damage and Q1. One six-die group counts as one action. |
| BA-D1 / Defence | Hunting Step | First Evade: +S**3/5/7**. If it uses exactly two dice, gain another S3. |
| BA-D2 / Defence | Light Landing | First Evade arms the next successful Dodge this round to grant S**4/6/8**. |
| BA-D3 / Defence | Unscathed | Encounter start: S**4/6/8**. If at least one enemy strike was attempted and the hero lost no HP from any source that round, begin the next with S4. |
| BA-U1 / Utility | Light Feet | First successful Dodge each round earns one extra reroll pass next round, total cap 3. Fixed. |
| BA-U2 / Utility | Slip Through | First solo Attack each round gains +4 damage. Combos do not consume the benefit. Fixed. |

Bastet's Attack-granted Dodges protect only against later strikes. They do not qualify an Attack as Evade for her own sequence powers.

### Trigger limits across all gods

- Each named first/second/third trigger has its own counter; duplicate copies of a boon cannot be equipped.
- “First qualifying” means the first action satisfying all printed conditions, not a wasted activation on an ineligible first action.
- Boon healing, including duos and legendaries, is capped at 8 actual HP restored per round. Native healing and native lifesteal are separate.
- Reroll bonuses from all sources pool into the maximum of three passes next round; excess expires rather than banking.
- A boon can arm only its printed one-shot reaction per round. Reactions expire round end unless explicitly stated otherwise.
- Bonuses apply once per primary action. Six ingredients are not six god triggers.
- Different gods can add status simultaneously; caps apply after batching.
- Status ticks, splash, retaliation, echo, a returned knife and a Judgement verdict cannot trigger Attack, critical, sequence, or reroll rewards.

## 13. All fifteen duo boons

These are optional later build links, not required to make a regular boon function. Each duo occupies the listed ordinary slot, has fixed values and triggers at most once per round unless its row says otherwise.

Unlock only while two relevant regular source boons, one from each listed god, remain equipped. An evolution counts as its source. A duo never supplies a prerequisite. Hide a duo if equipping it would require removing its own prerequisite.

Source tags: **Ra Burn** = RA-A1–A5 or D1–D3; **Sobek Bleed** = SO-A1/A2/A4/A5/D1; **Sobek Healing** = SO-A4/D2/D3/U2; **Anubis Judgement** = AN-A1–A5/D1/D2; **Bes Shield** = any Bes regular; **Horus Prepared** = HO-A1/D1/D2/U1; **Horus Precision** = HO-A1/A2/A3/A5/U2; **Bastet Dodge** = BA-A1/A5/D1/D2/U1. HO-A4 also counts as Precision; HO-U2 does not count as a Prepared source. These tags describe actual enabling effects, not just ownership of a god's name.

| ID | Gods / duo | Slot | Complete effect | Required tags |
|---|---|---|---|---|
| DU-01 | Ra + Sobek: Boiling Nile | Attack | At round end before normal ticks, the living foe with both Burn and Bleed and the greatest Burn takes extra HP damage equal to Burn, maximum 6. Ties use visible order. | Ra Burn + Sobek Bleed |
| DU-02 | Ra + Anubis: Funeral Pyre | Attack | First released Judgement on a Burning foe deals additional HP damage equal to twice its current Burn, maximum 10. | Ra Burn + Anubis Judgement |
| DU-03 | Ra + Bes: Forge Song | Defence | First hit absorbed by shield applies B3 to its attacker. | Ra Burn + Bes Shield |
| DU-04 | Ra + Horus: Sunstrike | Attack | First Prepared Attack: +6 damage. If primary was already Burning, add B3 after damage. | Ra Burn + Horus Prepared |
| DU-05 | Ra + Bastet: Dancing Flame | Defence | First successful Dodge applies B3 to its attacker and grants S3. | Ra Burn + Bastet Dodge |
| DU-06 | Sobek + Anubis: The Crossing | Utility | First Judgement release on an already Bleeding foe heals 3 and earns one reroll pass next round, cap 3. Evaluate Bleed before the verdict even if it kills. | Sobek Bleed + Anubis Judgement |
| DU-07 | Sobek + Bes: Crocodile Hide | Defence | First positive healing event from a native action, item or regular/evolved boon grants S5. Overheal, Regen and other duos do not trigger it. | Sobek Healing + Bes Shield |
| DU-08 | Sobek + Horus: Reed and Sky | Attack | First Prepared Attack against an already Bleeding primary gains +20% damage and +20 percentage points Pierce. | Sobek Bleed + Horus Prepared |
| DU-09 | Sobek + Bastet: Death Roll | Defence | First Dodge against a Bleeding attacker pays one early Bleed tick on it and heals 2. | Sobek Bleed + Bastet Dodge |
| DU-10 | Anubis + Bes: Guardian of the Tomb | Defence | First hit absorbed by shield adds J5 to its attacker. | Anubis Judgement + Bes Shield |
| DU-11 | Anubis + Horus: The Weighing Eye | Attack | First Prepared Attack adds J6. If primary already had Judgement before this action, gain S4. | Anubis Judgement + Horus Prepared |
| DU-12 | Anubis + Bastet: Borrowed Life | Defence | First successful Dodge adds J5 to its attacker and heals 2. | Anubis Judgement + Bastet Dodge |
| DU-13 | Bes + Horus: Watchful Guardian | Defence | First Prepared action grants S6. If natively Guard, arm 20% reduction for the next non-dodged enemy damage action this round. | Bes Shield + Horus Prepared |
| DU-14 | Bes + Bastet: Warm Doorstep | Defence | First successful Dodge grants S5. If shield later breaks this round, gain Q1 after the hit, once. | Bes Shield + Bastet Dodge |
| DU-15 | Horus + Bastet: Silent Descent | Attack | First successful Dodge primes next separate Attack for +20% damage and +50 percentage points Pierce; expires end of next round. | Horus Precision + Bastet Dodge |

Multiple reductions, including Weaken and defensive tokens, combine additively but cap at 50% for a damage action. A Dodge avoids a strike before reduction; a reduction token is not consumed by a completely Dodged action. Multi-strike actions resolve their token eligibility at the first non-dodged strike and retain it across their remaining strikes.

## 14. Six legendary evolutions

Unlock after owning the source plus one other regular boon of that god. The evolution replaces its source in the same ordinary slot and retains source rarity and level. Maximum one evolution acquired per run; replacing it does not reset this allowance. This explicitly replaces the current separate legendary-slot approach.

Retain every source clause unless changed below. Scale the bold values by the same rarity rule. A legendary never duplicates its source's counters or effects.

| ID | God / evolution | Source | Reworked full change |
|---|---|---|---|
| LG-RA | Ra: Crown of Noon | Solar Flare | First 4–6 die Attack gains +**10/12/14** damage. After direct damage, consume the primary target's pre-action Burn for twice its potency as HP damage, maximum 20; then apply B6 instead of B4 if it survives. Other new Burn applications follow. |
| LG-SO | Sobek: Lord of the Bloodied Nile | Jaws of the Nile | First 3+ die Attack applies L**6/7/8** and always pays one early Bleed tick. Heal HP actually lost to this tick, maximum 6. If target was already Bleeding, native damage gains +15%. |
| LG-AN | Anubis: Final Verdict | Final Sentence | First 3+ die Attack gains +20 points Pierce and adds J**10/12/14**. Its released ledger deals 25% extra HP damage, maximum 8 extra, against any foe. Clear once; no boss-specific instant execute. |
| LG-BE | Bes: Unbroken House | Sheltering Blow | Keep source unchanged. Round end: retaliate for half the total shield absorbed this round, maximum 15 direct HP damage, against the living enemy responsible for the most absorption. No surviving attacker means no retaliation. |
| LG-HO | Horus: Eye of the Falcon | Falcon's Eye | First Prepared Attack gains +**25/30/35**% damage and 100% Pierce instead of the source's bonuses. Does not alter crit chance or add a second hit. |
| LG-BA | Bastet: Nine Lives Unbound | Hunting Step | Keep source unchanged. Once per encounter, lethal damage from a strike or status leaves the hero at 1 HP and grants Q2 after the event. Later damage and DoT can still kill. |

The source requirement is acquisition-only for the second same-god regular; the evolved card remains functional if that second regular is later replaced. Duos still check their currently equipped source tags.

## 15. Ptah's complete Chisel rework

Chisels modify equipment behaviour outside god slots. Maximum two distinct Chisels per run. Keep three choices per class at the first Workshop, then the two unowned choices at the second; do not invent a third duplicate offer.

First Workshop: guarantee by the end of hour 4, selecting an eligible reward node at run generation. Second: guarantee during hours 5–8. These are **in-game hours**, not elapsed real time. Ptah replaces that node's normal upgrade choice and cannot be bought in the shop. Persist workshop placement and chosen offers. If a route would skip the reserved node, move the guarantee to the next reachable eligible node before the window ends.

### Archer

| Chisel | Complete rule | Example / trade-off |
|---|---|---|
| Twin Bowstring | Arrow groups of 2+ split their native direct damage into two packets of 55% each, rounded down. Choose same or separate targets. Crit applies before splitting; all god flat damage and status riders go to the first packet. Native statuses also go only to primary. Native splash remains one separate splash. If the first packet is Dodged, its riders fail; the second cannot rescue or duplicate them. | Native D30 becomes 16 + 16. Split to avoid overkill, or stack into one foe; both packets meet defences. |
| Siege Draw | Once per round, reserve one unspent reroll pass to empower one Arrow group of 2+: +25% direct damage and +30 points Pierce. Must be affordable before commitment. The pass cannot also be rolled. | Keep a promising hand and spend its last pass on power; a six-die group can use it because it costs no seventh die. |
| Adjustable Nock | Once per round, convert one Arrow result up or down one tier: I↔II↔III. It must be Prepared. The displayed face actually changes before grouping; crit and physical die identity remain. No I→III jump. | Two Arrow II and one Prepared Arrow I become three Arrow II. Conversion persists only for this round. |

Twin Bowstring copies the native damage budget only; Siege Draw's additive percentage applies to each native packet, while divine additions remain primary. Marked boosts only packets directed at the marked primary foe, consuming its token once for the action.

### Warrior

| Chisel | Complete rule | Example / trade-off |
|---|---|---|
| Crescent Edge | Overhead and Side Swing groups of 2+ add one splash packet equal to 25% of critical-scaled native main damage against a chosen second foe. If the move already splashes that foe, add the amounts into one packet. No copied statuses, gods or lifesteal. | Crushing Blow D27 adds 6 to a second foe; no second foe means no splash. |
| Counterweight | Once per round, optionally spend a chosen 1–10 existing Shield at attack resolution for +2 flat damage per Shield on an Overhead or Side Swing action. If fewer shield remain, spend what remains and scale the bonus down. The move's own new shield cannot pay. | Spending 8 existing shield adds 16 damage, but leaves the hero exposed. Preview both full and minimum payment. |
| Relentless Advance | If an Overhead or Side Swing combo resolves this round, next round's first combo of either face gains +8 damage. Does not stack; expires at next round end. | A pair now supports a heavy move next round; changing swing family is allowed. |

Relentless cannot trigger itself from retaliation or splash. Counterweight's flat addition is primary-only and does not enlarge Crescent's splash budget.

### Rogue

| Chisel | Complete rule | Example / trade-off |
|---|---|---|
| Returning Knife | First Dagger Throw action each round arms one returning blade: after the next separate Attack this round, deal 8 secondary direct damage to that later action's primary target. No new die, no copied statuses, no Attack trigger. Expires round end. | Dagger pair followed by a Slash pair gains a final 8-damage blade. A six-Dagger hand leaves no later Attack to trigger it. |
| Concealed Blade | Once per round, convert one Evade result into Swift Slash before grouping. It keeps crit and Prepared state but loses all native Evade output. Actual displayed face changes; no mixed matching exception. | Two Slashes and one Evade become a Slash triple at the cost of a guaranteed Dodge. |
| Assassin's Commitment | Once per round, designate a Swift Slash or Dagger Throw action to spend one available Dodge at resolution for +30% damage and +30 points Pierce. Choose an unassigned charge or explicitly release an assigned one. A Dodge created by this same action cannot pay. | Evade → enemy strike may spend your only charge, leaving no fuel; reserve a different charge or use an Evade pair. |

Returning Knife follows the triggering later action's resolved fallback target; if it is dead, use the visible fallback list. No living foe means no return hit. Assassin's Commitment is conditional on a charge surviving until resolution and never silently steals a promised assigned Dodge.

### Magician

| Chisel | Complete rule | Example / trade-off |
|---|---|---|
| Prismatic Focus | Once per round, convert one Arcane result into Fire, Frost or Life before grouping. Preserve crit, Prepared state and physical identity; no Arcane effect remains. | Two Fire plus Arcane become a Fire triple. You lose Arcane's Pierce/Marked opportunity. |
| Echoing Staff | Once per round, reserve one unspent reroll pass for a Fire/Frost/Life/Arcane/Wand Zap group of 2+. At the start of next round, echo 40% of this action's critical-scaled native main damage, immediate healing and shield, each rounded down. No Focus, splash, statuses, Dodges, gods or copied Chisel bonuses. | Fireball D17 echoes for 6. Life H24/S8 echoes H9/S3. The next fight never inherits an echo. |
| Alternating Current | Once per round, when two consecutive primary actions are different rune families, gain +6 flat native main damage if the second is an Attack, otherwise +S6. Eligible families: Fire/Frost/Life/Arcane/Channel; Wand Zap is not a rune. A non-rune action breaks the sequence. | Frost pair → Fire triple adds 6 damage to Fire. Two Fire pairs do not qualify. No mixed recipe is needed. |

Echo resolves at the next round's start after carry and opening grants, before rolling, then clears. It cannot occur without reaching another round. If all foes die, discard it. Retarget to the visible fallback order if its original target is dead. It does not steal the player's first action or qualify as an Attack.

### Chisel interaction contract

- Face conversions happen before matching, preview and role determination. They never create a die, change group size or grant both old and new native effects.
- A physical die can be converted at most once per round. No reversible UI toggling can generate counters or RNG.
- Two passive Chisels may coexist; each uses its printed budget and frequency.
- Reserved reroll costs are paid on commitment; a death before release does not refund them.
- Shield/Dodge costs are paid at release and remain conditional. Show lost defence and potentially lost bonus.
- Secondary damage has no critical roll and no recursive triggers.
- Effects such as Alternating Current's +6 are flat additions after critical scaling, despite modifying the native attack; they do not gain crit again.
- Do not add an “extra counted die,” universal wildcard or free seventh ingredient. Every apex consumes six actual matching results.

## 16. Worked builds and decisions

### Archer: Marked setup versus one heavy volley

Roll four Arrow I and two Arrow II. One Arrow I is critical. No boons.

**Split:** Arrow I pair containing the crit → Arrow II pair → remaining Arrow I pair. First pair deals floor(18 × 1.25) = 22 and leaves M20. Arrow II then deals floor(22 × 1.20) = 26 before Pierce/defences. Last Arrow I pair deals 18 and leaves M20. Total raw primary damage 66 across three action events, with defence and enemy turns interleaved.

**Heavy:** Four Arrow I → Arrow II pair. Arrow I group deals floor(44 × 1.125) = 49 plus critical-scaled splash floor(10 × 1.125) = 11, and leaves M25. Arrow II deals floor(22 × 1.25) = 27. Total raw primary damage 76 plus splash, but the first damage occurs only after Wind-up and an enemy event.

Both plans are credible. The heavy choice has more output; the split choice can kill an early threat before its first move.

### Warrior: protection feeds attack

Block pair → Overhead group of four, with Counter-Swing Common L1.

Block grants S18. Enemy acts. Overheads wind up; enemy acts again if it has another move. Release deals native 62 + boon 6 = 68 before defences, grants native S10 + boon S4, and W25. Counterweight, if equipped and armed, can spend only shield actually remaining before Release; never the S14 created by that Release.

### Rogue: three pairs can beat an apex build

With six Swift Slashes, Quick Claws does not help three pairs, but Pounce and Ninefold Flurry do.

Three pairs: 16 + 4 from Pounce, then 16, then 16 + 8 from Ninefold = 60 raw primary damage at Common L1, Q1 on the first and third actions, repeated L3 refreshes.

One six: D72, L10, Q2 and M25, after wind-up. It does not trigger pair or third-Attack boons. The two plans differ in timing, Bleed potency, access to Dodges and target flexibility; neither should be automatically selected by the interface.

### Magician: two families interact without mixed matching

Channel pair → Fire group of four, with Alternating Current.

Channel resolves S9 and F40. After enemy responses and Fire wind-up, Fire resolves with native D45 plus Chisel 6, then Focus: floor(51 × 1.40) = 71 main damage before defences. Splash uses native 10 × 1.40 = 14; it does not inherit the flat +6. Apply B6 to primary. Channel and Fire remain two separate homogeneous actions.

### Anubis: release is a choice

With Second Reading Common L2 and six matching attack faces, a pair adds J4 and leaves it stored. A following four adds J8 and releases J12 if the foe survives native damage. Two triples instead each add and release J6. A six adds J12 and releases it once. Boons tied to first 3+ groups can make these distributions differ further.

## 17. Encounters, enemies and the rest of the run

### Keep encounter variety relevant

| Enemy pattern | Decision it creates | Necessary communication |
|---|---|---|
| One large strike | Spend a solo Evade or enough Block; attack with the rest. | Exact strike value and Dodge assignment. |
| Several small strikes | Shield can outperform a single Dodge; pairs may remove the foe early. | Individual strike count and damage, not one misleading total. |
| Armoured guardian | Invest in Arrow II/Arcane/Pierce or statuses. | Separate Armour and Shield bars. |
| Wound cleanser | Decide whether to release Judgement or early-tick Bleed before cleanse. | Announce cleanse in the queue. |
| Shielding foe | Pierce, delayed releases and target switching matter. | Shield action's position before or after your hit. |
| Vulnerable wind-up | Use a heavy release or Focus while there is a safe window. | Reveal the next heavy strike, including follow-ups. |
| Two/three foes | Splash and flexible pair targeting compete with a six-die nuke. | One merged enemy event queue and clear target arrows. |
| Serpent-lord phase | Plan across several readable rounds rather than canceling every large group. | Transition cancels only dead-phase events; new attacks wait for the next planning window. |

Enemies need not roll the player's exact matching system. Retain authored telegraphed action sets. Their internal action budget must never depend on how many groups the player made.

Do not preserve old enemy HP multipliers blindly: removing the ×2 combo lottery and changing rerolls substantially changes damage. Tune around expected pair/triple play first. Ordinary fights should not require an apex. A suggested initial test range is 3–5 rounds for ordinary fights, 4–7 for elites and 6–10 for bosses; these are targets, not guarantees.

**Stall pressure:** for the first prototype, beginning in round 7 ordinary enemies gain +10% direct damage per later round, capped at +50%; bosses begin this pressure in round 11. Show the countdown and the bonus in intent. This is new encounter tuning and must be tested against healing/Poison loops. Do not claim it mathematically prevents every infinite defensive build; flag such builds in testing and tighten native healing or pressure if they occur.

### Trials

Retain one optional accepted Trial per run and three usable offers from its god on victory. Declining costs nothing. Remove any relic/patron prerequisite; require the tutorial completed and at least one regular boon equipped.

| God | Proposed champion modifier |
|---|---|
| Ra | First strike each round that removes HP applies B2 to the hero. |
| Sobek | First HP-damaging strike applies L2 and heals champion 4. |
| Anubis | Every second round, announce a Sentence action: hero receives J6, detonating at the end of the following round unless cleansed or champion killed. Enemy-only timer is explicit. |
| Bes | After its final action each round, champion gains S8. |
| Horus | Every third round, announced attacks have X50; Dodges remain effective. |
| Bastet | Every second round, champion has one visibly announced Dodge against the next primary direct-damage packet. A tiny solo may remove it before a larger release. |

Champions do not gain hidden HP/damage increases merely because they are in a Trial. Pairing rewards are not automatic.

### Rewards, shops, rests and river events

- Keep gold, route choices, healing stops and existing narrative events. Rewrite their mechanical rewards to use this catalogue.
- Remove relic dice and patron-claim rewards. Boss rewards become a guaranteed usable god upgrade or equipment improvement choice, not a ninth die.
- Shops sell healing, reforges, crit imbues and replacement equipment. Do not sell Ptah visits or permanent reroll-cap increases.
- Replace stamina rewards with one explicit reward: either one bonus reroll pass for the next encounter's opening round, or a reforge. Never silently change a named reward without new text.
- Equipment quality should offer concentration versus coverage. Always show which face probabilities rise and which fall.
- No free healing after combat; rests keep their existing role. Victory cancels pending player healing and echoes.
- Event risk previews must account for the new smaller native crit ceiling; do not price an old guaranteed-critical reward as though it still doubles an action.
- Persist reward offers. Skipping provides the ordinary skip reward, not another roll at finding an apex-enabling Chisel.
- Tutorials introduce solo → pair → splitting → reroll → triple → gods. Heavy wind-up is introduced when the player can first form four; six-die moves are aspirational, not a prerequisite for learning.

### Records and scoring

Record face kind, group size, physical dice used, critical count, native versus divine output, actual HP damage, shield absorbed, successful Dodges and healing actually restored. A six-hit animation is one action. Do not reward unused shield, overheal, repeated marks or deliberate stalling. Separate best apex from general combat score. Version the leaderboard rules if scoring or balance changes; do not compare runs from different rulesets as equivalent.

## 18. Interface: make the choice visible

1. **Tray:** face, clear critical accent, Prepared badge, original physical die source. No automatic ice/freeze appearance after preroll.
2. **Matching:** highlight identical faces on selection. Joining two cards fuses them; adding a third upgrades that same card. No recipe letters or mixed-ingredient checklist.
3. **Group controls:** explicit Split and size controls. Four Arrow I can become 4, 3+1, 2+2, 2+1+1 or singles. Never silently recombine a split after target editing.
4. **Preview:** show move name, all consumed face icons, actual crit-adjusted native damage, status quantities, god additions, Chisel effect and target. Allow text to reflow as a combined card widens.
5. **Wind-up:** a linked “Preparing” event and “Release” event. Keep one action identity and one group-size label.
6. **Defence:** show expected remaining shield and assigned Dodges at each enemy strike. Distinguish conditional Chisel costs from guaranteed output.
7. **Reroll button:** “2 passes left”; selecting five dice still costs one pass. Reservations show “1 pass reserved for Siege Draw.”
8. **Codex:** every face shows tiers 1–6. Reachable tiers are normal; unavailable ones explain the required extra face-bearing dice. Names/art can reveal on first use, but effects and costs stay readable before commitment.
9. **Combat:** one strong lock-in animation on fusion; stronger release sound/animation at 3 and 6. Skip/reduced-motion modes preserve all numerical information.
10. **Enemy UI:** distinct HP, Shield and Armour; statuses show caps, expiry and pending triggers. No redundant yellow focus border around buttons that already have designed game art.

Avoid six entirely different mechanics per face. Each ladder generally develops one or two familiar effects; the gods create run variety. The player should recognize “more precise arrows” or “stronger frost protection” immediately.

## 19. Implementation and migration map

This section specifies proposed work, not changes already made.

| Current area | Required change |
|---|---|
| FaceKind.swift | Explicit legal palettes; remove Energize offers; stop deriving new action output from old solo scaling. |
| Die / loadout / class content | New starting spreads and cross-family reforge legality; enforce at most three identical sides per die. |
| ComboDef / FacePattern | Represent action as class + exact effective face + count 1–6. Retire heterogeneous recipe matching. |
| GameData | Set max group 6; retire solo damage penalty, second combo crit roll and old length/guaranteed-crit tuning. |
| BattleRules | Two selective passes, max three; preserve guaranteed strike-specific Dodges; add wind-up/release events. |
| BattleEngine planning | User-owned grouping and splitting; one-use physical dice; conversions before grouping; stable IDs across reorder. |
| BattleEngine resolution | Shared preview/runtime calculation; ordered snapshot, cost, damage, statuses, verdict and secondary events. |
| Timing | Add heavy wind-up; delay one event once per enemy; never give extra enemy actions because of player grouping. |
| GodCatalog / GodBoon | Replace all mixed triggers, materialize the 60/15/6 catalogue and slot/prerequisite rules. |
| Chisel catalog | Twelve rules above; convert before matching, reserve passes, preserve conditional costs and no-recursion. |
| GameManager / rewards | New loadouts, reforge pool, pity guarantees for two Workshops, source-eligible boons, no patron/relic rewards. |
| Views | Face ladders, group split controls, scalable action text, detailed preview, linked wind-up events. |
| Saves / records | New ruleset version; explicit migration and separate leaderboard compatibility. |

Existing runs should finish under their saved ruleset or be offered a clearly labeled restart under the new design. Do not silently translate mixed active plans into unrelated moves. Legacy Energize may translate to Focus/Channel in a new-run loadout migration; a saved mid-battle action must retain its old engine version or restart at a safe encounter boundary with user-visible notice.

Existing discovered recipe names can map to corresponding ladder moves for cosmetic history; discovery does not unlock unavailable mechanics. Old mixed-only names such as The Fourfold Word may become presentation names for a chosen same-face apex, but never retain hidden mixed requirements.

### Required verification before release

- Every legal face has exactly six tiers; all tiers have effects, roles, names and known timing.
- Two different arrow tiers never group naturally; transformed faces group only after visible conversion.
- Group sizes count distinct physical dice, not duplicate sides on one die.
- Splitting, undoing and reordering cannot duplicate faces, crits, costs or god counters.
- Six-die attacks are legal without stamina, and their wind-up does not fire boons twice.
- Side-specific crit upgrades and Prepared state survive keeping, not rerolling.
- Focus, old Marked, new Marked, early ticks and Judgement resolve in the specified order.
- Native secondary damage cannot duplicate divine payloads or trigger another Chisel recursively.
- Guaranteed Dodges answer individual strikes, never retroactively protect the wind-up.
- All 60 regulars and 15 duos have reachable eligible builds; full slots cannot make a prerequisite self-invalidating.
- Two equipped Chisels remain compatible with their shared pass/shield/Dodge budget.
- Save/reload preserves committed randomness, counters, rewards and pending echoes.
- Common pair builds, defensive builds and crit builds can win without relying on sixes.

## 20. Balance review and prototype acceptance

Track these per class and region: group-size distribution; turns spent without useful actions; rerolls used; passes reserved; damage per actual die; damage before the first enemy event; HP lost during wind-up; failed conditional Chisel payments; actual healing; status contribution; encounter length; win rate; and tier-6 frequency.

Prioritize four checks:

1. **Does the matching feel better?** A player should understand every available group without opening a recipe browser.
2. **Are pairs still worthwhile?** Compare three pairs with a six using equivalent crits and builds, including enemy timing and overkill.
3. **Can sixes really occur?** Validate each loadout's physical reachability and simulate actual draw/reroll decisions, not idealized homogeneous dice alone.
4. **Do choices remain class-specific?** Archer marks and pierces; Warrior protects and cleaves; Rogue exploits wounds and Dodges; Magician moves between spell families.

Suggested tuning order: native pair/triple baselines → enemy action pressure → heavy wind-up risk → reroll availability → four/six payoff → boon outliers → Chisel combinations → rarity scaling. Do not solve a too-strong six by making every ordinary enemy an HP sponge.

All move values, starting face distributions, wind-up thresholds, +200% damage cap, shield cap, rarity multipliers and workshop guarantees are explicit proposed parameters. The matching rule and no-double-counting contracts are the architectural commitments.

## 21. Source basis

Read from the current main branch on 19 September 2026:

- [Face kinds and native meanings](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/Models/FaceKind.swift)
- [Battle rules: six dice, rerolls, guaranteed Dodges and alternating actions](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/Models/BattleRules.swift)
- [Current content and crit constants](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/Models/GameData.swift)
- [Archer content](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/Models/Content/ArcherContent.swift)
- [Warrior content](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/Models/Content/WarriorContent.swift)
- [Rogue content](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/Models/Content/RogueContent.swift)
- [Magician content](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/Models/Content/MagicianContent.swift)
- [God catalogue](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/Models/Content/GodCatalog.swift)
- [Ptah's Chisels](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/Models/Chisel.swift)
- [Battle engine: Prepared/kept results and existing combo resolution](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/PharaohSWager/ViewModels/BattleEngine.swift)
- [Older rework document](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/GAME_REWORK.md)
- [Older mechanics reference](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/GAME_MECHANICS.md)

The repository establishes the existing systems and names. All replacement ladders, rebalanced values and rule changes in this document are new design recommendations, not claims about shipped behaviour.

