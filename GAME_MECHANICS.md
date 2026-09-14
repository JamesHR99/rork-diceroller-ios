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
  `chance = min(0.75, face.baseCrit + face.bonusCrit + critBonus + blessedCrit)`
- `DieFace.critCap = 0.75` — a single face can never be a guaranteed crit.

### Base crit by face

| Faces | Base crit |
|---|---|
| Arrow III, Overhead, Dagger Throw | 8% |
| Arrow II, Swift Slash, Arcane Rune, Bomb | 6% |
| Everything else | 5% |

### Starting dice by class

| Class | Weapon die (×3) | Armour die (×3) |
|---|---|---|
| Archer | 2 Arrow I, 2 Arrow II, 1 Arrow III, 1 Bow Smack | 2 Dodge, Roll, Block, Heal, Focus |
| Warrior | 3 Overhead, 2 Side Swing, 1 Parry | 3 Block, Brace, Heal, Taunt |
| Rogue | 3 Swift Slash, 2 Dagger Throw, 1 Dodge | 3 Dodge, 2 Heal, 1 Block |
| Magician | 2 Fire, Frost, Life, Arcane, Wand Zap | 2 Heal, 2 Ward, Dodge, Channel |

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
| Archer / Warrior / Magician | 3 |
| Rogue | 4 |

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

**Chain tallies are live.** The number carved on each tray die counts the chains that die can *still* feed from where the plan stands: the search pool is everything left in the tray plus the run of not-yet-fused chips at the tail of the plan, so committing dice to a line makes the other tallies fall in real time. A face already welded into a finished chain drops out of the count entirely, and the header badge counts the same way. Chains are still never named mid-fight — and nothing is highlighted, only tallied.

**Chains barely refuel you.** `GameData.comboStaminaBank` is **0 for a pair and +1 for a
chain of 3 or more**, and that is the *only* refund a combo pays: recipes' printed
`staminaNext` values are **ignored by the engine** (kept in the content files as legacy
data, filtered out of every effect line). The bar is meant to hold you near your base.

**Overcharging past the cap is earned, not automatic.** `nextTurnStamina` — Focus,
Energize/Channel, gift riders, duos, plus that single chain point — lands
*above* the maximum and expires if left unspent: at the next turn start the bar is clamped
back down to `maxStamina` before the +2 applies. Building a turn around Focus is the
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
- **Frozen fuel:** a carried face adds **+10%** to the crit roll of any combo it joins
  (`GameData.frozenFuelCritBonus`); guaranteed-crit recipes are unaffected.
- You cannot freeze a die that is already in the plan; playing a frozen die thaws it and
  refunds the freeze.
- Freezing is the *only* dice manipulation in the game — no rerolls, no mulligans.

---

## 4. Attacks — how damage is actually built

### Single faces (`applyFace`)

**A face played alone is chip damage.** `FaceKind.soloValue` cuts the printed `baseValue`
to `GameData.soloAttackScale` (0.4) for attacks and `soloGuardScale` (0.9) for
guards/heals/venom, floored at 1. A lone guard face is a real play; lone attacks stay chip. Divine faces are exempt — a god's favour is scarce and
earned, and lands at full value alone.

`value = soloValue × (isCrit ? 1.5 : 1)`, rounded **up**.

The table below lists **printed `baseValue`** — what a face is worth *inside a combo's
maths and the codex*. Solo, an Arrow III is 8, not 19.

| Face | Base | Solo behaviour |
|---|---|---|
| Arrow I / II / III | 7 / 12 / 19 | damage |
| Bow Smack | 6 | damage |
| Overhead / Side Swing | 12 / 9 | damage |
| Swift Slash / Dagger Throw | 7 / 11 | damage |
| Wand Zap | 8 | damage |
| Fire / Frost / Life / Arcane rune | 4 / 3 / 5 / 4 | damage (Frost also staggers 20%) |
| Bomb | 15 | damage + burn 4×2 (crit 6×2) |
| Parry / Brace / Taunt / Ward / Block | 8 / 10 / 6 / 9 / 7 | block (Brace carries over) |
| Heal / Elixir / Life Rune | 8 / 12 / 5 | heal |
| Dodge / Smoke | — | evade next hit |
| Roll | 4 | evade **and** 4 block |
| Poison | 3 | poison 3×2 |
| Energize / Channel | — | +1 stamina next turn (+2 on crit) |
| Focus | — | +1 stamina next turn **and +5 to the next attack in the plan** |

Runes are deliberately terrible alone (3–5 printed, 1–2 after the solo cut) — that is the
Magician's whole design tension, now generalised to every class.

### Combos (`buildPlan` → `applyCombo`)

- Faces must sit **adjacent and in exact order** in the play bar.
- Matching is **greedy left-to-right**, testing recipes sorted by: length desc → specificity desc → devotion desc → blocksAll → damage desc. A 3-face ultimate always beats the 2-face combo hiding inside it.
- Stamina cost of a combo is discounted — 3 faces cost 2, 4 cost 3, 5 cost 4 (see §3).

**Chain length multiplies everything the combo does** (`GameData.comboLengthScale`) —
damage, heal, block, bleed, poison, burn and regen all ride the same curve, so long
defensive chains scale as hard as offensive ones:

| Faces in the chain | Output multiplier |
|---|---|
| 2 | ×1.0 (as printed) |
| 3 | ×1.4 |
| 4 | ×1.8 |
| 5+ | ×2.2 |

**Critical dice add weight inside the chain**, not just odds: each crit face feeding a
combo adds `GameData.critComboWeight` (+15%) to the chain's whole output. A crit is never
wasted in a combo. `GameData.comboOutputScale(faces:critDice:crit:)` is the single source
of truth: `(lengthScale + critDice × 0.15) × (crit ? 2.0 : 1)`.

**Combo crit** is rolled once for the whole step (`GameData.comboCritChance`):

| Crit dice fed in | Chance whole combo crits |
|---|---|
| 1 | 35% |
| 2 | 70% |
| 3+ | 85% |
| all dice crit | 100% |
| `guaranteedCrit` recipe | 100% |

Any die carried over from a freeze adds **+10%** to the roll (capped at 100%).

A critical combo is **×2.0** on top of the length-and-crit-weight scale; a critical single
face is only ×1.5 of an already-reduced solo value. That gap is what makes chaining the
only real way to kill anything.

### Headline recipes per class

**Archer** — tiered draw
| Combo | Recipe | Effect |
|---|---|---|
| Drawn Shot | Arrow I → II | 30 |
| Piercing Bolt | Arrow II → III | 44, ignores 60% block |
| Twin Shot | 2 same arrows | 26, +2 stamina |
| Suppressing Fire | Arrow I ×3 | 32, stagger 35% |
| **Perfect Shot** | Arrow I → II → III | **80, always crits**, pierce 40% |
| Steady Aim | Focus → any arrow | 30, pierce 30% |

**Warrior** — momentum and walls
| Combo | Recipe | Effect |
|---|---|---|
| Crushing Blow | Overhead ×2 | 38 |
| Cleaving Follow-Through | Overhead → Side | 34, **+12 to next turn's first swing** |
| Rising Guillotine | Side → Overhead | 36, pierce 50% |
| Earthshaker | Overhead ×3 | 62, stagger 40% |
| Executioner | Over → Over → Side | 52 + (missing enemy HP ÷ 5) |
| **Whirlwind Crush** | Over → Side → Over | **72**, +3 stamina, stagger 30% |
| Riposte | Parry ×2 | blocks everything, **reflects 100%** |
| Fortress | Block ×3 | blocks everything, reflects 50% |

**Rogue** — bleed and vanishing
| Combo | Recipe | Effect |
|---|---|---|
| Flurry | Slash ×2 | 22, +2 stamina |
| Opening Cut | Slash → Throw | 28, bleed 6×2, **marks +25%** |
| Cutthroat | Throw → Slash | 26 **+2 per enemy bleed stack** |
| Twin Fang | Throw ×2 | 34, bleed 10×3 |
| Thousand Cuts | Slash ×3 | 42, bleed 8×3 |
| **Vanishing Strike** | Dodge → Throw → Slash | **60, always crits**, blocks everything |
| Untouchable | Dodge ×3 | blocks everything, +3 stamina |

**Magician** — runes into spells
| Combo | Recipe | Effect |
|---|---|---|
| Fireball | Fire ×2 | 34, burn 6×3 |
| Ice Blast | Frost ×2 | 28, stagger 45% |
| Steam Burst | Fire → Frost | 30, stagger 30% |
| Life Siphon | Arcane → Life | 26, lifesteal |
| Amplify | Arcane → any rune | 30, +2 stamina |
| **Meteor** | Fire → Fire → Arcane | **68**, burn 10×3 |
| **Arcane Storm** | 3 *different* runes | **58**, burn 6×2, stagger 30% |
| Arcane Shield | Ward ×2 | 26 block |

**Items (every class)** — Detonate (Bomb×2, 48 + burn 8×2), Vanish (Smoke×2, blocks all), Venom Coat (Poison×2, 10×3), Great Draught (Elixir×2, heal 30), Blinding Blast, Toxic Blast, Quick Sip.

**Items blended with gear** — items no longer only combo with themselves. `.anyStrike`
wildcards let a pickup chain into whatever weapon you carry: Breach and Strike (Bomb →
strike, 38 pierce 50%), Envenomed Edge (Poison → strike), Smoke and Steel (Smoke →
strike), Steadied Draught (Elixir → Heal → strike), Demolition (Bomb → strike → strike,
58), Ambush (Smoke → strike → strike, 52 + mark), Alchemist's End (Poison → Bomb → strike
→ strike, 74), Fortified Guard (Elixir → Smoke → Energize, blocks all).

**Blended weapon × armour chains** — because every class always carries the same weapon
and armour, each class gained several 3- and 4-face recipes that open with an armour face
and pay off with the weapon: Archer's Hunter's Cycle (Dodge → Arrow I → II → III, 76),
Warrior's Warlord's Answer (Taunt → Block → Overhead → Side, 82), Rogue's Death of a
Thousand (Dodge → Slash → Throw → Slash, 72), Magician's Channelled Tempest (Channel →
3 distinct runes, 84).

### Damage bonuses stacked on top

1. **Warrior momentum** — `attacksSoFar × 5`, counted per attack already resolved *this turn*. Applies to attack steps only, and is consumed by the step that uses it.
2. **Momentum carry** — Cleaving Follow-Through banks +12 into next turn's first swing.
3. **Focus** — a Focus face banks +5 onto the next attack step in the plan.
4. **Scaling flags** — `scalesWithBleed` (+2/stack), `scalesWithWounds` (+missing HP ÷5), `scalesWithBurn` (+3/stack), `scalesWithBlock` (heal + block held).

### How damage lands on the enemy (`damageEnemy`)

```
raw × mark  →  pierce ignores (block × pierce)  →  remaining block absorbs
    →  pierce ignores (armourMax × pierce)  →  remaining armour absorbs
    →  the rest hits HP  →  Sobek blood-tithe heals you
```

- All damage is routed to the **aimed foe** (`aimedFoe`); if your target died mid-turn, the aim slides to the nearest living foe.
- `mark` is a one-shot multiplier and is **consumed by the next hit** (reset to 1.0), per foe.
- Mark does **not** apply to bleed/poison/burn ticks.
- **Armour** sits between block and HP: direct hits chip it first, and pierce ignores a fraction of it exactly as it does block. Statuses never touch it. Armour never regenerates. When the plate shatters there is an `ARMOUR BROKEN` floater, a screen kick and a heavy haptic.
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
- Devotion modifies statuses at the moment they are applied (see §7).
- In packs, **every foe carries its own statuses** — they are applied to the aimed foe only.

---

## 6. The enemy turn

**Order of operations (`enemyTurn`):**

1. **Every living foe's** block resets to **0**.
2. Bleed → poison → burn tick **per foe**, in that order, each decrementing its own counter. A death here ends the fight immediately (victory needs every foe dead).
3. **Each living foe then acts, one after another**, in the order they rose: its telegraphed `intent` move executes — block first, then heal, then attacks.
4. Damage is computed once per foe, then **split across the number of attack faces in the move** (remainder goes on the first hit).
5. Full block and reflect clear **after every foe has acted**, so a full guard covers the whole pack's incoming turn.

**Total attack damage per foe** = `move.damage + heat`, where `heat = heatPerTurn × (turnNumber − 1)`, per foe.
Only two enemies have heat: **Nehebkau (4/turn)** and **Apep (2/turn)**. Stagger then multiplies by `(1 − stagger)` and is consumed, per foe.

**Per-hit defence order:**

```
Full block active?  → absorbed entirely (and reflect fires)
Evade stack?        → consumed, hit avoided
Agility roll?       → agility% flat chance to dodge
Player block?       → absorbs up to its value
Otherwise           → HP loss
```

Agility by class: Rogue 18%, Archer 12%, Magician 8%, Warrior 5%.

**Intent** is picked by weighted random at the start of your turn, from whichever stage is active, **per living foe** — so what you see telegraphed is what will happen, one capsule per foe above the arena.

### Packs

- Regular battle nodes roll `GameData.packChance` (**25%**) for a pack; within a pack, `packTrioChance` (**15%**) makes it a trio, otherwise a pair. Members are distinct creatures drawn from the same gate's roster.
- **The first fight of a run is the Straw Effigy** (`EnemyContent.trainingDummy`): a harmless
  rehearsal foe on the practice bank — no damage, no armour, no scaling, 56 HP so every class
  lands chains against something real. Its spoils are **three random relics to choose from**
  (`RelicContent`, one equips into the item slot with its three dice), and **no god attends**
  that first water's edge — no blessing offers, no devotion. The gods start meeting you from
  the second fight onward.
- Each member arrives as `EnemyDef.packMember()`: **HP ×0.55**, **gold ×0.7** — so a trio is
  much less than double a solo fight.
- One pack member can additionally rise **armoured** (`eliteArmourChance`, 12% — same roll for solo fights).
- Every living foe telegraphs its own intent; on their turn they act one after another. Your aim (`aimedID`) sticks until you tap another foe and redirects to the nearest living foe when your target falls.
- Serpent-lords and heralds never pack.

### The bestiary

| Gate | Guardians (HP) | Heavies (HP, armour) | Serpent-Lord |
|---|---|---|---|
| Reeds (1–4) | Reed Lurker 54, Marsh Shade 68, Sand Crawler 82 | Silt Colossus 128, armour 26 | **Sekhen** 168 |
| Fire (5–8) | Ember Wraith 106, Flamekeeper 132, Ash Jackal 148 | Bronze Effigy 160, armour 34 | **Nehebkau** 262, heat 4 |
| Coils (9–12) | Devourer Spawn 172, Shadow of the Uncreated 190, Hour-Eater 208 | Boneplate Devourer 200, armour 42 | **Apep** 420, heat 2, 3 stages |

Mid-hour and prep fights draw from the current gate's roster (guardians **and** heavies), so hour 1 and hour 3 can throw the same creature.

**Heralds** (`EnemyDef.herald()`) are a gate creature with: HP ×1.45, damage ×1.3, block ×1.3, gold ×1.8.

**Armoured elites** (`EnemyDef.armoured()`) can replace any regular foe (12% of fights): name prefixed "Armoured", **HP ×1.3**, **gold ×1.6**, and an armour plate of `max(16, maxHP ÷ 5)`.

**Apep's stages** trigger on HP fraction: ≤1.0 The Head That Bites, ≤0.66 The Coils That Crush, ≤0.33 The Maw. Each stage swaps the entire move pool and announces itself with a screen shake.

---

## 7. The gods

**Files:** `Models/Deity.swift`, `Models/FaceMark.swift`, `Content/GiftContent.swift`, `Content/DuoContent.swift`, `Content/DivineContent.swift`

Six gods: **Ra, Sobek, Anubis, Bes, Horus, Bastet**.

### Gifts, not overwrites

**A god never takes a face away.** Their named **gift** is laid on top of a face you already own (`Models/FaceMark.swift`): the face keeps its kind, its numbers and every chain it fed, and the gift's `DivineFaceEffect` rides on top whenever the face plays, solo or inside a chain. A fire arrow is still an arrow.

**Seventy-two gifts** (`Content/GiftContent.swift`): each god carries **twelve** — four for attacks, four for guards, four for mends & support — and the four pull in different directions (Ra attacks: Fire Arrows / Piercing Ray / Sun-Hardened / Blinding Flare; Sobek: flood-pierce / bleed jaws / lifesteal / ambush stagger; and so on). All four read the same god, so following a god twice does not mean the same run twice.

### Deepening, and being stuck

A gift **deepens three times on the same face**: **touched → deepened → named final form** (e.g. Ra's Fire Arrows ends as *Solar Flare*). Depth 1/2/3 also weights devotion. Once a face carries a gift it carries that gift. The only way out is a rare **replace offer** (12% of shrines when you carry any gift): it burns whatever the face carries and lays the new gift at **touched**, losing all prior depth.

The pick-a-face screen dims faces held by another god with their sigil. An offer card names the gift, prints its touched effect, and counts how many of your faces can take it — pick the card, then the face.

### Riders, duos and the pantheon flourish

When a chain fires, the chain's own effect lands first, then **every gifted face in the chain speaks in turn** (`resolveGiftRiders`), each announced on its own, scaled by `GameData.comboRiderScale` — deliberately gentler than the chain's own length curve (cap 1.6).

- **Two different gods in one chain** fire their named **duo** (`DuoContent.bestDuo`, weighted by face support) as a bonus rider — the *chained* (weaker) version.
- **Three or more different gods** trigger the **pantheon flourish**: every rider in the chain is multiplied by `GameData.pantheonFlourish` (1.5), with a screen-wide shake.
- A **bound face** (see below) fires its duo at **full strength every play**, solo or chained (`applyGiftRider`).

### Duo gods

**Fifteen named duos** (`Content/DuoContent.swift`), one per pair of gods. Two routes:
- **Chained** — get both gods' gifted faces into one chain and the duo fires as a taste on top.
- **Bound** — a rare **dual-god rite** (`OfferKind.rite`, 35% of shrines + the Standing Idol omen) marries the second god into a face already carrying the first. A bound face counts toward **both** gods' devotion, feeds both gods' chains, and fires the duo's *bound* (full-strength) version every single play.

### Devotion opens each god's own chains

**Devotion = the sum of gift depths** carried for that god (a final-form face counts 3), counted across every die; a rite partner counts 1.

| Devotion | Tier | Effect |
|---|---|---|
| 2 | Passive | Rung-1 chain unlocked (Ra *Kindling*, Sobek *Rising Water*, Anubis *The First Toll*, Bes *The Loud House*, Horus *The Perch*, Bastet *Whisker-Twitch*) + the small passive (Ra burns +1 turn, Sobek +3 HP per hit dealt, Anubis poison +2, Bes open with 8 block, Horus +4% crit, Bastet open with 1 evade) |
| 3 | Deeper | Rung-2 chain unlocked (*Solar Wind*, *The Drowning*, *Weighing of Hearts*, *Drums in the Dark*, *The Stooping Falcon*, *The Prowl*) + the deeper passive |
| 5 | Signature | That god's signature chain (*Procession of Ra*, *Jaws of the Nile*, *The Final Verdict*, *House of Joy*, *Eye of the Falcon*, *Nine Lives Unbound*) |

Ladder rungs are gated in `GameData.divineCombos` (`devotionRequired`) and **scale with the devotion standing behind them**: `GameData.devotionChainScale` adds +7% per devotion point past the rung, capped ×1.5 — the same Kindling at seven Ra hits harder than at two. Rungs stay unlocked only while the devotion holds; reforging a gifted face away can drop you below a rung.

Devotion passives are baked in at `BattleEngine.init` — Bes block and Bastet evades are already on the board before your first roll. Horus's crit is folded into `critBonus`, so it raises **every** face.

**Gifted faces do double duty in combos** (`FacePattern.matches(_:mark:)`, `ComboDef.matches(_:marks:)`): they still satisfy every exact and family slot they fed before, *and* they now fill divine slots — "any Ra gift" reads a Ra-gifted arrow, "a face carrying Fire Arrows" reads that exact gift, "any gifted face" reads any mark. **The Ennead** (three faces, three different gods) can be assembled entirely from gifts.

**Divine combos** come in four layers: one per god per class (e.g. Sunfire Arrow, Crocodile Grip, Solar Nova) — all rewritten to read specific *gifts* instead of the retired relic faces — cross-god fusions (Pyre Strike, Boiling Nile, **The Ennead**), the **twelve ladder rungs**, and the six devotion-gated signatures.

---

## 8. Economy and rewards

| Source | Payout |
|---|---|
| Winning a fight | `max(6, Σ enemy goldReward × (1 + progress × 0.8) × 0.6)` — pack members pay ×0.7, armoured elites ×1.6. No heal (`postBattleHeal` = 0) |
| Skipping a reward card | +15 gold |
| Mooring — rest | `max(20, maxHP × 0.35)` |
| Mooring — whetstone | one free reforge |

**Reward screen** is always **3 cards**: named-gift offers, the first always the visiting god's, later cards theirs 58% of the time and otherwise a random god's. Serpent-lords **always** drop a relic die; heralds drop one **38%** of the time; **packs** teach you the river's name a little more often (10% for pairs, 16% for trios); the relic die takes one of the three slots. Shrines lay out two gifts of their god plus either a **dual-god rite** (35%) or a third gift — and, 12% of the time when you carry gifts, a **replace offer** that burns one face's gift and lays a fresh one.

**Shrines** hold 3 gift cards, all dominated by the presiding god.

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
- Class `maxStamina` in `GameData.classes` (3, Rogue 4) plus `GameData.maxStaminaGrants`
  (2) — the bar carries over and recovers +2 a turn, so this is the steady-state ceiling.
  Breath of Ra cards (spoils ~20%, shrines ~15%, Ferryman ~30% priced at the rare tier)
  raise it permanently, capped two points above the class.
- `GameData.staminaRecoveryPerTurn` (2) — how fast a spent bar comes back. Raised from 1 so all-in turns cost at most two turns of runway; at 1, combo banks were the real income.
- `GameData.comboStaminaBank` (0 for a pair, +1 from 3 faces up) — deliberately tiny. Raising it back toward +1/+2/+3 makes chains self-sustaining and the bar irrelevant; this is the dial that decides whether stamina is a real constraint.
- `GameData.comboStaminaCost` — the fusion discount, now the *main* reason a long chain is affordable at all.
- `nextTurnStamina` sources (Focus, Energize/Channel, gift riders, duos, and the single chain point) are the only way above the cap, and only for one turn. Recipes' printed `staminaNext` is ignored by the engine.

**Gift power curve**
- `GameData.comboRiderScale` (cap 1.6) — how hard gift riders inside a chain scale with chain length and crit dice. This is the guardrail that keeps a five-chain of gifted faces strong rather than run-ending.
- `GameData.pantheonFlourish` (1.5) — the three-different-gods payoff. Raising it makes mixed pantheon builds competitive with single-god devotion.
- `GameData.devotionChainScale` (+7%/point past the rung, cap 1.5) — how much a god's own chain grows with the devotion behind it. This is the single biggest power curve in the game.
- Gift depth values in `Content/GiftContent.swift` — 72 entries × 3 depths. Depth 3 (final forms) are deliberately the strongest riders in the game.

**Length of a fight**
- Enemy `maxHP` in `EnemyContent` versus your combo damage. Right now a Warrior hitting Whirlwind Crush (72, 144 on crit) can two-turn a Reed Lurker but needs ~6 clean turns on Apep.
- `heatPerTurn` — currently only on two bosses. Adding 1–2 to late guardians would punish stalling everywhere.
- Post-fight heal (8 HP) and `rest` heal (35%) — the attrition curve across an hour.

**Solo vs chain power**
- `GameData.soloAttackScale` (0.4) and `soloGuardScale` (0.9) — how hard a lone face is cut.
  Guards, heals and venom played alone keep almost everything; attacks stay chip. Raising
  the attack scale restores the old "any face is a play" feel.
- `GameData.comboLengthScale` (1.0 / 1.4 / 1.8 / 2.2) — the whole reason to build long. Flattening it makes two-face pairs competitive again; steepening it makes 4-face chains mandatory.
- Because solos were cut and chains raised, **enemy damage is calibrated against chain output**. If the solo scales move, re-check `GameData.enemyDamageBonus(hour:)` (now 0/1/3/6 by gate depth, up from 0/1/2/4) and `enemyDamageScale` (now 1.0/1.15/1.25) — both were re-tuned upward to hold fight length against the wider draw, the second hold, and the Breath of Ra ceiling.

**How swingy it feels**
- `faceCritMultiplier` 1.5 vs `comboCritMultiplier` 2.0 — the gap is the whole incentive to chain.
- `GameData.critComboWeight` (0.15) — flat weight each crit die adds inside a chain, independent of whether the chain itself crits. This is what stops a crit being wasted in a combo.
- `comboCritChance` (35/70/85) — one crit die giving a 35% shot at double damage is the single biggest variance source in the game.
- `DieFace.critCap` 0.75 and the `blessedCrit` cap of 0.40.

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
