# The Twelve Hours of the Duat — Mechanics Reference

Every number here is read from the shipping code, with the file that owns it.
Use this as the tuning sheet: change a number here, change it in the named file.

---

## 1. The run at a glance

**Files:** `Models/Voyage.swift`, `Models/Gate.swift`, `ViewModels/GameManager.swift`

| Thing | Value |
|---|---|
| Hours in a night | 12 |
| Stages per hour | 4 |
| Total stages | 48 |
| Gates | 3 (hours 1–4 Reeds, 5–8 Fire, 9–12 Coils) |
| Bosses | Hours 4, 8, 12 |
| Starting gold | 40 |
| Dice carried at start | 6 (3 weapon + 3 armour) |
| Dice cap | 10 (`Loadout.maxDice`) |

### The rhythm of an hour

Each hour is four stages and always the same shape (`Voyage.generate()`):

| Stage | Content | Choice? |
|---|---|---|
| 0 | Forced **Guardian** fight | No — one node |
| 1 | 2–3 mixed nodes | Yes |
| 2 | 2 **prep** nodes (mooring / shrine / ferryman / battle) | Yes |
| 3 | Forced **Herald** — or the **Serpent-Lord** at hours 4/8/12 | No — one node |

So per hour you get **two real route decisions**, wrapped in two forced fights.
Over the run that is 12 forced openers, 12 forced closers, 24 chosen stages.

Mid-hour node weights (`Voyage.rolledKind`): battle 50% + 12% fallback = **62%**,
omen 10%, shrine 10%, ferryman 10%, mooring 8%. Heralds never spawn mid-hour.

### Routing

- `startRun` casts off straight into stage 0 — the chart opens only after that fight.
- `availableNodes` = the connections of the last cleared node. Taking one branch closes the others permanently.
- Each column guarantees every node has at least one inbound channel, so nothing is unreachable.
- `progress` = clearedNodes / 48, and it drives **rarity odds, gold, heal amounts and event payouts**. It is the single most important scaling dial in the game.

---

## 2. The dice

**Files:** `Models/Die.swift`, `Models/DieFace.swift`, `Models/FaceKind.swift`

- Every die has exactly **6 faces**. A face is a `FaceKind` plus `imbueTiers` and `bonusCrit`.
- Rolling: `faces.randomElement()` — flat 1-in-6, no weighting.
- Crit is decided **the instant the die lands**, not when it resolves:
  `chance = min(0.75, face.baseCrit + face.bonusCrit + critBonus)` — Horus patron dice with
  the *Wind-Reader* upgrade roll +8% more.
- `DieFace.critCap = 0.75` — a single face can never be a guaranteed crit.
- Every die may carry **one patron god** (`Die.patron`) — the faces never change, the god
  simply answers what the die plays (see §7).

### Base crit by face

| Faces | Base crit |
|---|---|
| Arrow III, Overhead, Dagger Throw | 8% |
| Arrow II, Swift Slash, Arcane Rune, Bomb | 6% |
| Everything else | 5% |

### Starting dice by class

| Class | Weapon die (×3) | Armour die (×3) |
|---|---|---|
| Archer | 2 Arrow I, 2 Arrow II, 1 Arrow III, 1 Bow Smack | 2 Evade, 2 Block, Heal, Focus |
| Warrior | 3 Overhead, 2 Side Swing, 1 Block | 4 Block, Heal, Focus |
| Rogue | 3 Swift Slash, 2 Dagger Throw, 1 Evade | 3 Evade, 2 Heal, Block |
| Magician | 2 Fire, Frost, Life, Arcane, Wand Zap | 2 Heal, Block, 2 Evade, Channel |

---

## 3. The turn loop

**File:** `ViewModels/BattleEngine.swift`

```
ROLL (once)  →  place faces into the plan  →  COMMIT
     →  plan resolves step by step  →  enemy statuses tick  →  enemy acts
     →  new turn
```

### Rolling

- `rollAll()` fires **once per turn** (`hasRolled` gate). There is no reroll.
- **The row is shuffled fresh on every roll** (`shuffleRow()`): carried reels stay pinned at
  the front, every other reel is `.shuffled()` into a new order. Reel index drives lock
  timing and drum speed, so the whole rhythm of a roll differs turn to turn.
- **Every loadout die rolls every turn.** A freeze no longer benches its die — the held
  face rides along as a separate carried reel (see Freezing below).
- Reels lock left to right. **Every drum runs flat out at the same speed and stays there** —
  only the reel whose stop is coming up brakes. Waiting reels never drag:
  - First lock: **0.85s**
  - Gap before reel *i*: `min(0.46 + 0.10i, 1.0)` seconds
  - Scaled ×0.72 above 7 dice, ×0.84 above 5 dice
  - Drum face-change interval: flat **0.032s** for every reel (`drumStepBase`, `drumStep(slotID:)`
    ignores reel index)
  - Brake windows are identical for every reel and short: long haul from **0.38s** out, final
    crawl from **0.16s** out, tension ring at **0.3s** out
- Each lock: tray kick (crit 0.85 / last 0.62 / normal 0.36) plus a heavy haptic — crits fire a
  double heavy 55ms apart. The face drops from higher (`-0.34×height`), larger (1.72×, crit
  1.9×), blurred and tilted on X, then slams flat.

> An earlier pass had drum speed and brake windows grow with reel index, so the whole row got
> visibly lazier left to right and a full loadout took 13s+. Now the row keeps its speed and
> only the next die winds down.

### Stamina

| Class | Max stamina |
|---|---|
| Archer / Warrior / Magician | 4 |
| Rogue | 5 |

- Placing a face costs **1 stamina**. Reordering only costs the plan-cost difference.
- Taking a face back refunds exactly what the plan spent on it — pulling a die out of a
  fusion also takes back that fusion's discount.
- The bar is **derived, not decremented**: `stamina = turnStamina - planStaminaCost`, where
  `turnStamina` is the budget the turn opened with. Laying dice out never mutates the
  budget, so placing and taking back are exact mirrors *by construction* — they cannot
  drift apart. Only `resolveTurn` draws the committed plan's cost out of `turnStamina`
  for good.
- Affordability is checked by pricing the whole prospective order
  (`planCost(for:) <= turnStamina`), never by charging a per-die delta.
- Turn start: `turnStamina = min(maxStamina, min(turnStamina, maxStamina) + 2) + nextTurnStamina`
  (`GameData.staminaRecoveryPerTurn` = 2).

The bar **never refills**. Unspent stamina carries over and each turn recovers **+2**,
capped at the class maximum — so an all-in turn opens the next one on 2 (base 3).
Carrying can never exceed the cap on its own; hoarding for turns buys nothing.

**Chain marks are live.** Each tray die wears the **letters** of every recipe the combo panel
lists that it could still feed, coloured to match the list — committing dice elsewhere makes
the letters fall in real time. Recipes are named in the panel, never hidden: pick one to
fuse it, tap it again to dissolve it back into solo faces.

**Chains barely refuel you.** `GameData.comboStaminaBank` is **0 for a pair and +1 for a
chain of 3 or more**, and that is the *only* refund a combo pays: recipes' printed
`staminaNext` values are **ignored by the engine** (kept in the content files as legacy
data, filtered out of every effect line). The bar is meant to hold you near your base.

**Overcharging past the cap is earned, not automatic.** `nextTurnStamina` — Focus,
Energize/Channel, god blessings, and that single chain point — lands
*above* the maximum and expires if left unspent. Building a turn around Focus is the
intended way to afford a big chain.

> Two reworks ago the bar refilled completely every turn, which made spending everything
> free. The pass after that made combos the main faucet (+1/+2/+3 plus printed refunds),
> which let long chains self-sustain and made the bar irrelevant. Now chains pay a token
> +1 from 3 faces up and abilities are the only real overcharge.

### Combo cost discount

A fused combo step costs less than its faces played apart (`GameData.comboStaminaCost`):

| Faces in the fusion | Stamina cost |
|---|---|
| 1 (solo) | 1 |
| 2 | 2 (full price) |
| 3 | 2 |
| 4 | 3 |
| 5 | 4 |

The rebate lands the moment the fusion forms in the plan — a 3-point bar can afford a
3-face fusion on the spot — and is reversed if the fusion is broken. This discount, not a
refund, is what makes long chains affordable: a landed combo banks only
`comboStaminaBank(faces:)` (0 for a pair, +1 from 3 faces up) for the next turn.

### The draw

You carry far more dice than you roll. The weapon starts with **four** dice and the armour
with **three** — seven from the first fight — and the relic chosen after the practice bout
adds **three** more, **ten in all** (`Loadout.maxDice` = 10). Against that, only
`GameData.diceDrawCount` (**6**) dice hit the table each turn.

- Every turn draws a **fresh six at random** from the whole loadout
  (`BattleEngine.draw(count:from:excluding:)`), in `init` and again in `startPlayerTurn` —
  so the same collection produces a different hand every turn.
- **No mix guarantee**: a draw can come up all weapon and leave nothing defensive. Freezes
  are the intended answer.
- **Dice behind held faces sit out the draw** — the `excluding:` set is the carried dice —
  so a held face never arrives beside a fresh roll of its own die. The hold is the only
  way to guarantee a specific face comes back.
- The codex marks which dice the current draw put on the table (`drawnDieIDs`, passed to
  `InfoSheetView` from the battle screen).
- Opening kits are composed so every die feeds real combos — e.g. the Archer carries
  Longbow ×2 + Recurve Cadence + Heron's Shaft, plus Light Armour ×2 + Padded Cuirass;
  each class follows the same main-die ×2 + two character dice pattern.

### Freezing

- Freezing is **free**. The allowance is **1 hold per turn in the Gate of Reeds** and
  **2 from the Fire Gate onward (hour 5+)** — `GameData.freezesPerTurn(hour:)`. The
  second hold is announced in the status line when the Fire gate title card plays.
- A held face keeps exactly as it landed (crit and all) — **and the die it came from still
  rolls next turn.** A freeze *adds* a face rather than benching a die, so the turn after a
  freeze you have one more face than dice.
- Mechanically the held face becomes its own `DieSlot` with `isCarried = true`, pinned to
  the front of the row and excluded from `rollableDice`. `pendingCarry` ferries it across
  the enemy turn; `startPlayerTurn` rebuilds `slots` as `carried + this turn's draw`.
- Because a carried reel is a distinct slot, freeze state is keyed by **slot id**
  (`frozenSlotIDs`, `toggleFreeze(slotID:)`), not die id — one die can have both a carried
  reel and its own fresh roll on the table at once.
- A carried face can itself be frozen again, holding it a further turn.
- **Holds feed the gods now:** the old universal +10% crit bonus for a held face is gone.
  Ra's *Solar Wind* and Horus's *Falcon's Eye* pay out when an action carries a held face
  of theirs; Horus's *Thermal* hands back 1 stamina for the first held Horus face each turn.
- You cannot freeze a die that is already in the plan; playing a frozen die thaws it and
  refunds the freeze.
- Freezing is the *only* dice manipulation in the game — no rerolls, no mulligans.

---

## 4. Attacks — how damage is actually built

### Single faces (`applyFace`)

**A face played alone is workable, never the best answer.** `FaceKind.soloValue` cuts the
printed `baseValue` to `GameData.soloAttackScale` (**0.65**) for attacks and
`soloGuardScale` (0.9) for guards/heals/venom, floored at 1. A lone guard face is a real
play; lone attacks are two thirds of themselves — playable, but the chain still wins.

`value = soloValue × (isCrit ? 1.5 : 1)`, rounded **up**.

| Face | Base | Solo behaviour |
|---|---|---|
| Arrow I / II / III | 7 / 12 / 19 | damage |
| Bow Smack | 6 | damage |
| Overhead / Side Swing | 12 / 9 | damage |
| Swift Slash / Dagger Throw | 7 / 11 | damage |
| Wand Zap | 8 | damage |
| Fire / Frost / Life / Arcane rune | 4 / 3 / 6 / 4 | damage (Frost also staggers 20%) |
| Bomb | 15 | damage + burn 4×2 (crit 6×2) |
| **Block** | 8 | +8 shield — **persists until broken** |
| **Evade** | — | **+15% evade chance this turn** (crit +20%) |
| Heal / Life Rune | 10 / 6 | heal |
| Poison | 3 | poison 3×2 |
| Energize / Channel | — | +1 stamina next turn (+2 on crit) |
| Focus | — | +1 stamina next turn **and +5 to the next attack in the plan** |

The old defensive families collapsed into single meanings: Parry/Brace/Taunt/Ward → **Block**,
Dodge/Roll/Smoke → **Evade**, Heal/Elixir → **Heal**. A face means the same thing on a
weapon, armour, item or relic.

### Combos (`buildPlan` → `applyCombo`)

- Recipes ask for **ingredients and quantities, never a tap order** — any arrangement of the
  right faces fuses into one step (`ComboDef.match(from:)`, bounded backtracking over
  ingredient lines).
- Matching is **greedy**, testing recipes sorted by face count desc → specificity desc →
  damage desc. `forcedCombos` (player-locked from the panel) are tested first;
  `dissolvedCombos` are skipped, so tapping a recipe in the panel re-plans the turn by hand.
- Stamina cost of a combo is discounted — 3 faces cost 2, 4 cost 3, 5 cost 4 (see §3).

**Recipes print their own value — chains no longer multiply by length.** What lifts a step
is its critical dice: each crit face feeding a combo adds `GameData.critComboWeight` (+15%)
to the whole output. `GameData.comboOutputScale` is the single source of truth:
`(1 + critDice × 0.15) × (crit ? 2.0 : 1)`.

**Combo crit** is rolled once for the whole step (`GameData.comboCritChance`):

| Crit dice fed in | Chance whole combo crits |
|---|---|
| 1 | 35% |
| 2 | 70% |
| 3+ | 85% |
| all dice crit | 100% |
| `guaranteedCrit` recipe | 100% |

A critical combo is **×2.0**; a critical single face is only ×1.5 of an already-reduced
solo value. That gap is what makes chaining the strongest way to kill anything.

### Headline recipes per class

Each class carries six everyday recipes plus two signatures; six item recipes are shared.

| Class | Everyday | Signatures |
|---|---|---|
| Archer | Twin Shot (any arrow ×2, 22), Piercing Bolt (II+III, 38, pierce 60%), Point-Blank (smack + arrow, 26, stagger 20%), Quick Guard (block + evade, 14 shield, +15% evade), Field Dressing (heal ×2, 22), Steady Aim (focus + arrow, 24, pierce 30%) | **Perfect Shot** (I+II+III, 58, pierce 40%, always crits), **Storm of Shafts** (any arrow ×4, 56, stagger 40%) |
| Warrior | Crushing Blow (overhead ×2, 30), Wide Sweep (side ×2, 24, stagger 25%), Earthshaker (overhead ×3, 46, stagger 40%), Riposte (block ×2, 20 shield, reflect 50%), Second Wind (heal + block, 12 heal + 10 shield), Executioner (any swing ×2 + any strike, 44, +missing HP ÷ 5) | **Warlord's Answer** (any swing ×3 + block, 58, 14 shield, stagger 35%), **Blood Tide** (any swing ×4, 68, lifesteal) |
| Rogue | Flurry (slash ×2, 22), Opening Cut (slash + throw, 22, bleed 6×2), Twin Fang (throw ×2, 26, bleed 8×3), Shadowstep (evade + strike, 22, +15% evade), Patch Up (heal ×2, 20), Hemorrhage (throw + slash ×2, 36, bleed 8×2, +2/bleed stack) | **Vanishing Strike** (evade + throw + slash, 44, bleed 6×3, always crits), **Thousand Cuts** (slash ×3, 40, bleed 10×3) |
| Magician | Fireball (fire ×2, 26, burn 4×2), Ice Blast (frost ×2, 22, stagger 45%), Chill Ward (frost + life, 10 heal + 14 shield), Life Siphon (arcane + life, 20, lifesteal), Kindle (zap + any rune, 20), Blink (evade + block, 10 shield, +15% evade) | **Meteor** (fire ×2 + arcane, 50, burn 6×3), **Arcane Storm** (3 different runes, 44, burn 4×2, stagger 30%) |

**Items (every class)** — Detonate (bomb ×2, 36 + burn 5×2), Venom Coat (poison ×2, poison 8×3),
Steadied Strike (heal + strike, 16 + 14 heal), Breach and Strike (bomb + strike, 28, pierce 50%),
Envenomed Edge (poison + strike, 18, poison 6×3), Blinding Blast (evade + bomb, 26, +20% evade).

### Damage bonuses stacked on top

1. **Warrior momentum** — `attacksSoFar × 5`, counted per attack already resolved *this turn*. Applies to attack steps only.
2. **Momentum carry** — momentum recipes bank damage into next turn's first swing.
3. **Focus** — a Focus face banks +5 onto the next attack step in the plan.
4. **Scaling flags** — `scalesWithBleed` (+2/stack), `scalesWithWounds` (+missing HP ÷5), `scalesWithBurn` (+3/stack).
5. **God primes** — flat (`primeDamage`) and percentage (`primePercent`) bonuses banked onto the next damaging action; **percentages add, nothing compounds**, and unspent primes expire after your next player turn.

### How damage lands on the enemy (`damageEnemy`)

```
raw × mark  →  pierce ignores (block × pierce)  →  remaining block absorbs
    →  pierce ignores (armourMax × pierce)  →  remaining armour absorbs
    →  the rest hits HP
```

- All damage is routed to each attack's **assigned foe** (`allocations`: plan-step ID → foe ID). Solo fights skip targeting entirely; in packs, committing opens the allocation step where every attack (each combo as one unit, each solo face alone) is pointed at a foe. If your target died mid-turn, the attack slides to the nearest living foe.
- `mark` is a one-shot multiplier and is **consumed by the next hit** (reset to 1.0), per foe.
- Mark does **not** apply to bleed/poison/burn ticks or judgement detonations.
- **Armour** sits between block and HP: direct hits chip it first, and pierce ignores a fraction of it exactly as it does block. Statuses never touch it. Armour never regenerates.
- Enemy block from last turn is still standing during your turn, and is wiped for every living foe at the start of the enemy turn.

---

## 5. Statuses

**All statuses use `max()`, not addition — reapplying the same status does not stack, it refreshes.**

| Status | On | Ticks |
|---|---|---|
| Bleed | enemy or player | start of enemy turn (enemy), start of your turn (player) |
| Poison | enemy only | start of enemy turn |
| Burn | enemy only | start of enemy turn |
| Regen | player | start of your turn |

- A critical combo adds **+1 turn** to bleed/poison/burn duration.
- **Statuses seep under armour** — they tick health directly and never touch the plate.
- Player bleed is only applied **if the enemy actually landed a hit** (`landedAnyHit`), and it overwrites rather than refreshing.
- Ra's burn caps at **12 stacks**; Sobek's bleed refreshes rather than stacking.
- **Anubis's judgement** is stored per foe (`EnemyState.judgementAmount/pending`) and
  detonates against health at the end of your next player turn (`detonateJudgements`).
- In packs, **every foe carries its own statuses** — each attack carries its statuses and god triggers to whichever foe it was assigned to, not to a global aim.

---

## 6. The enemy turn

**Order of operations (`enemyTurn`):**

1. **Every living foe's** block resets to **0**.
2. Bleed → poison → burn tick **per foe**, in that order, each decrementing its own counter. A death here ends the fight immediately (victory needs every foe dead).
3. **Each living foe then acts, one after another**, in the order they rose: its telegraphed `intent` move executes — block first, then heal, then attacks.
4. Damage is computed once per foe, then **split across the number of attack faces in the move** (remainder goes on the first hit).
5. **Evade clears** after every foe has acted, and Bes's *Unbroken House* retaliates for
   half of what your shield absorbed (up to 20) at whoever hit you hardest.

**Total attack damage per foe** = `move.damage + heat`, where `heat = heatPerTurn × (turnNumber − 1)`, per foe.
Only two enemies have heat: **Nehebkau (4/turn)** and **Apep (2/turn)**. Stagger then multiplies by `(1 − stagger)` and is consumed, per foe.

**Per-hit defence order:**

```
Evade roll?         → Double.random < evadeChance — hit avoided, first-evade rewards fire
Player shield?      → absorbs up to its value (persists across turns)
Otherwise           → HP loss (Nine Lives Unbound can catch a lethal hit)
```

Evade chance stacks to a **60% ceiling** (`GameData.evadeCeiling`) and clears after the
enemy turn. The old full-block ("blocks everything") and agility rolls are gone.

**Intent** is picked by weighted random at the start of your turn, from whichever stage is active, **per living foe** — so what you see telegraphed is what will happen, one capsule per foe above the arena.

### Packs

- Regular battle nodes roll `GameData.packChance` (**25%**) for a pack; within a pack, `packTrioChance` (**15%**) makes it a trio, otherwise a pair. Members are distinct creatures drawn from the same gate's roster.
- **The first fight of a run is the Straw Effigy** (`EnemyContent.trainingDummy`): a harmless
  rehearsal foe on the practice bank — no damage, no armour, no scaling, 56 HP so every class
  lands chains against something real. Its spoils are **three random relics to choose from**
  (`RelicContent`, one equips into the item slot with its three dice), and **no god attends**
  that first water's edge — no god attends. The gods start meeting you from
  the second fight onward.
- Each member arrives as `EnemyDef.packMember()`: **HP ×0.55**, **gold ×0.7** — so a trio is
  much less than double a solo fight.
- One pack member can additionally rise **armoured** (`eliteArmourChance`, 12% — same roll for solo fights).
- Every living foe telegraphs its own intent; on their turn they act one after another. There is no persistent aim — attacks are allocated per turn at commit time (see §4), and a fallen target's attack redirects to the nearest living foe mid-resolution.
- Serpent-lords and heralds never pack.

### The bestiary

| Gate | Guardians (HP) | Heavies (HP, armour) | Serpent-Lord |
|---|---|---|---|
| Reeds (1–4) | Reed Lurker 54, Marsh Shade 68, Sand Crawler 82 | Silt Colossus 128, armour 26 | **Sekhen** 168 |
| Fire (5–8) | Ember Wraith 106, Flamekeeper 132, Ash Jackal 148 | Bronze Effigy 160, armour 34 | **Nehebkau** 262, heat 4 |
| Coils (9–12) | Devourer Spawn 172, Shadow of the Uncreated 190, Hour-Eater 208 | Boneplate Devourer 200, armour 42 | **Apep** 420, heat 2, 3 stages |

All HP below is the raw table; `GameData.enemyHealthTune` (**×1.12**) is applied in
`EnemyDef.init` to hold fight length against the stronger solo attacks.

Mid-hour and prep fights draw from the current gate's roster (guardians **and** heavies), so hour 1 and hour 3 can throw the same creature.

**Heralds** (`EnemyDef.herald()`) are a gate creature with: HP ×1.45, damage ×1.3, block ×1.3, gold ×1.8.

**Armoured elites** (`EnemyDef.armoured()`) can replace any regular foe (12% of fights): name prefixed "Armoured", **HP ×1.3**, **gold ×1.6**, and an armour plate of `max(16, maxHP ÷ 5)`.

**Apep's stages** trigger on HP fraction: ≤1.0 The Head That Bites, ≤0.66 The Coils That Crush, ≤0.33 The Maw. Each stage swaps the entire move pool and announces itself with a screen shake.

---

## 7. The gods

**Files:** `Models/Deity.swift`, `Models/GodKit.swift`, `Models/PairingContent` (in GodKit.swift)

Six gods: **Ra, Sobek, Anubis, Bes, Horus, Bastet**.

### Patron dice, not face gifts

**A god claims a whole die** (`Die.patron`) and never touches its faces. The claim means
their **blessing answers every face that die plays**, read by what the face is:

- Attack faces → the **attack** answer. **Block** faces → the **block** answer.
  **Evade** faces → the **evade** answer. Everything else → the **support** answer.
- Each answer fires **once per role per action** (`resolveBlessings`), chains included —
  a long chain does not multiply a god's patience.
- A claim is laid through a **patron offer** (shrines, occasional post-battle favour, the
  Standing Idol omen). Replacing a patron only happens through explicit replace cards.

The old seventy-two named face gifts, their three-step deepening, the devotion ladder and
the eighteen devotion combos are **gone** — gods speak through blessings, upgrades and
capstones now.

### The six blessings (per answer, once per role per action)

| God | Attack | Block | Evade | Support |
|---|---|---|---|---|
| Ra | burn 2 | +4 shield | burn 2 on attacker | prime 3 burn |
| Sobek | bleed 4 | +4 shield | heal 3 | prime 5 heal |
| Anubis | 6 judgement | +4 shield | 4 judgement | prime 6 damage |
| Bes | +3 shield | +5 shield | prime 8 damage | +4 shield |
| Horus | pierce 20% | +4 shield | prime +15% | prime +15% |
| Bastet | +4 damage | +3 shield | +8% evade (once/turn) | prime 4 damage |

Ra's burn caps at **12 stacks**; Sobek's bleed **refreshes to the stronger value** rather
than stacking; Anubis's **judgement** stores damage (cap 30 per enemy) that **detonates
against health at the end of your next turn** — additions join the pile without delaying it.

### Upgrades and capstones

- **Four upgrades per god** (`GodKit.upgrades`), each earned **once** and each needing a
  blessed die of that god. Upgrades tied to a god you no longer carry **go quiet**
  (`GameManager.activeUpgrades`) rather than disappearing.
- **One capstone per run**, unlocked by two upgrades of that god (`GodKit.capstoneUnlocked`):
  Ra *Solar Flare* (detonate burn for 3/stack, once a turn), Sobek *Jaws of the Nile*
  (bite a bleed early, heal up to 8), Anubis *Final Verdict* (×2 vs low ordinary foes, ×1.5
  vs bosses), Bes *Unbroken House* (retaliate half of what your shield absorbed, up to 20),
  Horus *Eye of the Falcon* (a held-Horus chain with a crit ignores all defences), Bastet
  *Nine Lives Unbound* (once a battle, a lethal hit leaves you at 1 HP with near-certain evade).

### Fifteen pairings

**One pairing per run**, unlocked by carrying **one upgrade from each of two gods**
(`GameManager.pairingReady`), firing **at most once per turn** while both gods stay
equipped (`PairingContent.pairings`): Boiling Nile, Funeral Pyre, Forge Song, Sunstrike,
Dancing Flame, The Crossing, Crocodile Hide, Reed and Sky, Death Roll, Guardian of the
Tomb, The Weighing Eye, Borrowed Life, Watchful Guardian, Warm Doorstep, Silent Descent.

---

## 8. Economy and rewards

| Source | Payout |
|---|---|
| Winning a fight | `max(6, Σ enemy goldReward × (1 + progress × 0.8) × 0.6)` — pack members pay ×0.7, armoured elites ×1.6. No heal (`postBattleHeal` = 0) |
| Skipping a reward card | +15 gold |
| Mooring — rest | `max(20, maxHP × 0.35)` |
| Mooring — whetstone | one free reforge |

**Reward screen** is always **3 usable cards**. After a fight a god visits only **28%** of
the time (`makeGodFavourOffers`: a patron claim on an unblessed die, upgrades, a capstone
once unlocked, or a ready pairing — mundane fills top up any shortfall); the other **72%**
are the river's own (`makeMundaneSpoils`): Grave-Goods gold, Bandages and Beer healing, and
**18%** a face reforge. Serpent-lords **always** drop a relic die; heralds drop one **38%**
of the time; **packs** add to those odds (10% for pairs, 16% for trios).

**Shrines** are the reliable place to receive a god's favour: three cards from that god
(`makeGodFavourOffers`), plus the Breath of Ra **15%** of the time while the run has room.

**Ferryman** stocks 5 rolled offers (30% reforge / 28% imbue / 20% item / 22% restorative), a relic 26% of the time, plus a flask. Prices: `base × rarityMultiplier` rounded to 5, where multipliers are 1.0 / 1.6 / 2.4 / 3.6.

**Rarity odds** (`Rarity.weights`, `p` = progress 0→1) — every card rolls independently, nothing guarantees one of each:

| Material | Weight |
|---|---|
| Clay | `0.72 − 0.42p` |
| Copper | `0.22 + 0.10p` |
| Lapis | `0.05 + 0.20p` |
| Gold Leaf | `0.01 + 0.12p²` |

**Imbues** add permanent crit to one face: +6% / +10% / +15% / +22% by tier.

---

## 9. Levers for refining the flow

Ranked by how much they move the feel of a fight.

**Pacing of a single turn**
- `GameData.freezesPerTurn(hour:)` (1 in the Reeds, 2 from hour 5) — the dice-manipulation
  budget, now also the only guarantee a face returns once the pool deepens. Each freeze is a
  *net extra face* (the die still rolls, and sits out the next draw).
- `GameData.diceDrawCount` (6) — how many dice hit the table from the ten you carry.
- Class `maxStamina` in `GameData.classes` (4, Rogue 5) plus `GameData.maxStaminaGrants`
  (2) — the bar carries over and recovers +2 a turn, so this is the steady-state ceiling.
  Breath of Ra cards (spoils ~20%, shrines ~15%, Ferryman ~30% priced at the rare tier)
  raise it permanently, capped two points above the class.
- `GameData.staminaRecoveryPerTurn` (2) — how fast a spent bar comes back. Raised from 1 so all-in turns cost at most two turns of runway; at 1, combo banks were the real income.
- `GameData.comboStaminaBank` (0 for a pair, +1 from 3 faces up) — deliberately tiny. Raising it back toward +1/+2/+3 makes chains self-sustaining and the bar irrelevant; this is the dial that decides whether stamina is a real constraint.
- `GameData.comboStaminaCost` — the fusion discount, now the *main* reason a long chain is affordable at all.
- `nextTurnStamina` sources (Focus, Energize/Channel, god blessings, and the single chain point) are the only way above the cap, and only for one turn.

**God power curve**
- Blessing values in `GodKit.blessing(for:role:)` — six gods × four answers. These fire every turn; small nudges move everything.
- Upgrade strength in `GodKit.upgrades` and the six capstones — earned once each, so they are one-time power spikes rather than curves.
- Pairing trigger odds live in the once-per-turn flags (`pairingFiredThisTurn` and friends) in `BattleEngine` — raising them to per-action would double god output.

**Length of a fight**
- Enemy `maxHP` in `EnemyContent` versus your combo damage. Right now a Warrior hitting Whirlwind Crush (72, 144 on crit) can two-turn a Reed Lurker but needs ~6 clean turns on Apep.
- `heatPerTurn` — currently only on two bosses. Adding 1–2 to late guardians would punish stalling everywhere.
- Post-fight heal (0 HP — `GameData.postBattleHeal`) and `rest` heal (35%) — the attrition curve across an hour; the mundane spoil's heal and the Ferryman's flask are the mid-hour comeback.

**Solo vs chain power**
- `GameData.soloAttackScale` (0.65) and `soloGuardScale` (0.9) — how hard a lone face is cut.
  Guards, heals and venom played alone keep almost everything; attacks keep two thirds. Lowering
  it back toward 0.4 restores the old chip-damage feel.
- Recipe damage values in the four content files — chains print their own value now. Raising a signature's printed damage is the lever a length multiplier used to be.
- Because solos were raised and length multipliers removed, **enemies carry ×1.12 health** (`GameData.enemyHealthTune`) and `GameData.enemyDamageBonus(hour:)` (2/3/4/6 by depth) with `enemyDamageScale` (1.0/1.15/1.25) calibrate pressure. If the solo scale moves, re-check both.

**How swingy it feels**
- `faceCritMultiplier` 1.5 vs `comboCritMultiplier` 2.0 — the gap is the main incentive to chain, now that length no longer multiplies.
- `GameData.critComboWeight` (0.15) — flat weight each crit die adds inside a chain, independent of whether the chain itself crits. This is what stops a crit being wasted in a combo.
- `comboCritChance` (35/70/85) — one crit die giving a 35% shot at double damage is the single biggest variance source in the game.
- `DieFace.critCap` 0.75 — imbues and Horus's Wind-Reader are the only crit faucets.

**Route shape**
- `Voyage.stagesPerHour` (4) — the 48-stage run length. Three would make the night much tighter.
- `Voyage.rolledKind` weights — 62% of mid-hour nodes are fights. Lowering that gives more breathing room between combats.
- `distinctKinds(count:)` — 2–3 nodes per branching column, i.e. how much choice a route decision actually offers.
- The forced opener/closer pattern in `generate()` — the rhythm of every hour lives in this one function.

**Packs and armour**
- `GameData.packChance` (0.25) — how often a regular battle is a pack. Incoming damage
  stacks per foe, so higher values make the night brutal fast. The opening fight is never a
  pack — it is the Straw Effigy.
- `GameData.packTrioChance` (0.15) — the pair/trio split. Trios of late-gate guardians are the hardest fights in the game.
- `GameData.packHealthScale` (0.55) — pack members' health. Raising it toward 1.0 without touching packChance is the gentlest way to make packs meaner.
- `GameData.eliteArmourChance` (0.12) — how often a foe rises armoured.
- Armour values per gate (Silt Colossus 26, Bronze Effigy 34, Boneplate Devourer 42) and the elite plate formula `max(16, maxHP ÷ 5)` — armour is a health tax on direct damage; note poison/burn builds ignore it entirely, so armour-heavy rosters shift class balance toward Magician.
- Because enemy damage is unchanged per foe, packs multiply incoming damage — if fights get too brutal, trim `packHealthScale` and `packChance` before touching enemy moves.

**Reveal drama**
- `shuffleRow()` — the row order is randomised every roll. Removing the shuffle restores the old fixed weapon-then-armour reading order.
- `firstLockDelay` 0.85s, `lockGaps` `0.46 + 0.10i` capped 1.0, flat `drumStepBase` 0.032, fixed `brakeWindows` (0.16 / 0.38 / 0.3). A 6-die roll now runs about 3.5s. `lockGaps` is the knob for overall roll length; `drumStepBase` alone controls how fast the drums whirl.
- Landing weight: `settle()` shake kicks (0.36 / 0.62 last / 0.85 crit) and the reel's drop distance, scale, tilt and blur in `DiceTrayView.settledReel`.

### Known inconsistencies

1. Statuses refresh instead of stacking (`max()`), so Twin Fang twice in a row is no better than once. Intentional, but it quietly nerfs bleed builds.
2. Player bleed **overwrites** with the new move's values rather than taking the max, so a weak hit can shorten an existing bleed.
4. `enemyMark` is consumed by the next `damageEnemy` call, which may be a small single face rather than the big hit you were setting up.

---

## 10. Chisels of Ptah

Ptah the craftsman rarely turns up in the spoils. A **Chisel of Ptah** reshapes the whole
weapon — never a single die — and the gods and their blessings are untouched. Two different
Chisels per run, maximum; both stay active and work together.

**Finding one**
- A gilded Chisel card can appear among post-battle spoils (`makeChiselOffer`). Claiming it
  opens **Ptah's Workshop** (`WorkshopView`, screen `.workshop`): the first visit lays out all
  three of the class's Chisels, a second offers the two not yet owned.
- Drop odds (`GameData`): one is **guaranteed somewhere in the first four hours**
  (`chiselFirstGuaranteeHour` = 4; from hour 3 onward the drop is certain, before that
  `chiselEarlyChance` = 0.14 per spoils screen; after the window `chiselLateChance` = 0.05).
  A second Chisel appears per-spoils at `chiselSecondChance` = 0.07 — a small share of runs.

**The twelve Chisels** (three per class; optional ones are `isOptional`)

| Class | Chisel | Effect |
|---|---|---|
| Archer | **Twin Bowstring** | Arrow combos fire two hits at 60% each (`twinSplitFraction`); splittable targets, each hit meets block separately; god effects land once |
| Archer | **Siege Draw** *(optional)* | Overdraw an arrow combo for +1 stamina (`siegeStaminaCost`): +40% damage, pierce 0.5 |
| Archer | **Adjustable Nock** | Once a turn, one held arrow counts one tier up/down for recipe matching; keeps god, crit and true identity for blessings |
| Warrior | **Crescent Edge** | Damaging weapon combos strike a second foe for 35% (`crescentFraction`); no healing, statuses or god triggers carry |
| Warrior | **Counterweight** *(optional)* | Spend up to 10 held shield (`counterweightMaxSpend`), +2 damage per point (`counterweightDamagePerPoint`) |
| Warrior | **Relentless Advance** | Land a weapon combo → first weapon combo next turn costs 1 less stamina (`relentlessDiscount`), never below 1; skip a turn and it is gone |
| Rogue | **Returning Knife** | First dagger thrown each turn returns as a held face next turn (a carry slot; its die sits out the draw; never twice from one appearance) |
| Rogue | **Concealed Blade** | Once a turn an Evade face also counts as a Swift Slash in a weapon recipe, while still granting its evasion; its god answers the Evade role |
| Rogue | **Assassin's Commitment** *(optional)* | Burn one evade charge (15%) before a damaging combo: +40% damage, pierce 0.5; the combo's own evasion cannot pay |
| Magician | **Prismatic Focus** | Once a turn an Arcane rune stands in for Fire/Frost/Life in a spell; keeps god, crit and blessing role |
| Magician | **Echoing Staff** *(optional)* | +1 stamina before a spell: it echoes at the start of next turn for half damage/heal/shield (`echoScale`); no statuses, gods or further echoes; slides to a living foe |
| Magician | **Alternating Current** | Opposite rune-kind spell (matching vs mixed) banks 1 stamina next turn, once a turn; the first spell only sets the memory |

**Implementation map**
- Substitutions live on `RolledFace.effectiveFace` (`matchFace` is what recipes and printed
  values read; the true `face` keeps its god and crit). `buildPlan`/`refreshCandidates` use
  `chiselAssistedMatch` — one assisted recipe per grouping pass, deterministic, order-free.
- Optional Chisels arm **by combo id** from a copper Ptah badge on the recipe chip in the
  combo panel (`badgeChisel(for:)`, `toggleArmed`); the plan card wears a copper hammer and a
  chisel line while armed. `displayedDamage`, `armedDamageMultiplier`, `armedPierce`,
  `mainDamage`, `secondaryDamage`, `chiselLine` and `projectedDamage`/`planStaminaCost` all
  fold the armed state into the forecast.
- Secondary hits (Twin's second arrow, Crescent's splash, the echo) allocate through
  `secondaryAllocations` (step ID → foe ID), defaulted to the weakest living foe other than
  the main target, retappable in the allocation overlay's copper `2ND` chip.
- The Echoing Staff stores a `PendingEcho` at resolution and `firePendingEcho` lands it at
  the top of `startPlayerTurn`.

## 11. Divine Trials

Any ordinary fight can quietly be a god's **Trial**. The god appears as the fight opens,
names its champion, states the exact power lent and the boon on offer — accept or fight on
(declining costs nothing and offends nobody).

**When one can happen** (`enterBattle`)
- Only on `.battle` nodes, never the opening encounter, never before the starting relic is
  armed **and** a blessing is carried (`patrons` non-empty), never on a herald or
  serpent-lord, and never on the last quiet water before a boss (`leadsToBoss`).
- Chance per eligible fight: `GameData.trialChance` (0.12). At most **one per run**
  (`trialUsed`); accepting consumes it, declining does not.

**The six trials** (`DivineTrial.all`, engine side in `foeActs`/`startPlayerTurn`)
- **Ra, Burning Sun** — the champion's first health-damaging hit each turn sets the player
  burning 2×2 (`playerBurn*` ticks in `startPlayerTurn`). Fully blocked or evaded = nothing.
- **Sobek, Hungry River** — first health-damaging hit each turn: player bleed 2×2 and the
  champion feeds 4 health.
- **Anubis, Weighed Heart** — every 2nd enemy turn the champion passes **Sentence** instead
  of attacking: 6 judgement on the player (`playerJudgement*`), falling at the end of your
  next turn. Kill the judge and the sentence dies with it (`onEnemyDamaged`).
- **Bes, Unbroken Gate** — after acting the champion raises 8 block.
- **Horus, Watching Falcon** — every 3rd enemy turn the strike ignores half the player's
  shield (evade still avoids it outright).
- **Bastet, Vanishing Step** — every 2nd player turn the champion gains one evade charge
  that expires at the end of that turn; the first damaging attack against it misses.

**Champion and reward**
- The champion (`isTrialChampion`) is ringed in the god's colour for the whole fight and
  marked `CHAMPION` beside its badges; solo fights champion the lone foe, packs a random
  member. The lent power never changes health or damage — the encounter is ordinary.
- Winning: normal gold, plus the spoils screen becomes **a choice of three boons from the
  attending god** — a patron claim, one of their upgrades, or their capstone if the run's
  limits allow (`makeGodFavourOffers`). No pairing is handed over automatically.
- Tuning: all sizes above live in `GameData` under the trial block; the codex names all six
  trials once a run has met one (`hasMetTrial`).
