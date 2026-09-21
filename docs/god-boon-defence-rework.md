# God boons and defensive actions

This update adapts the existing 60 regular powers, 15 duos and six legendaries.
Stable boon IDs, saved rarity/levels and slot capacities are preserved.
The live catalogue in Models/Content/GodCatalog.swift is authoritative for card text.

## Defensive rules

- Block generates Guard. Ordinary unspent Guard on both sides expires after the full alternating round. Plate remains persistent.
- Bes's Hearth Breath or Unbroken House retains up to 8 existing Guard, not 8 per boon.
- Evade is assigned to an individual future hit. Each charge reduces that hit by 50%, upgraded to at most 75%. Multiple charges never stack on one hit.
- Weaken, a defensive ward and Evade multiply in that order, before Guard. Fractional damage rounds up once; positive hits cannot become zero from partial reduction alone.
- Reactions to Evade pay after remaining damage lands, only if the hero survives. Reaction healing cannot undo death and reaction Guard cannot absorb that same hit.
- Native healing restores missing HP and is not limited by the divine healing budget. Divine healing shares an 8 HP per-round cap. Overhealing does not trigger healing rewards.

## Build identities

| God | Build |
| --- | --- |
| Ra | Burn pressure, sustained attacks and large detonations |
| Sobek | Bleed, healing through aggression, and recovery empowering the next attack |
| Anubis | Store Judgement, defend and choose a release |
| Bes | Retain Guard and counter damage actually absorbed |
| Horus | Paid rerolls, Prepared results, Focus and Pierce |
| Bastet | Partial evasion, small attacks, Marked and counterattacks |

Counter-Swing, Dancing Blades and Patient Hunter bank one reward each for the next separate Attack, expiring at the end of the following round. A new reward from the same boon replaces its unspent prior reward rather than stacking.

## Rerolls

Encounters start at zero, two unused dice earn one reroll, storage holds two rerolls, and stored half-charges reset between encounters.
All catalogue boons and duos share one bonus half-charge per round, separate from unused-dice charging. Full storage discards excess; bonuses cannot create overflow.
Banked Embers requires a completed large attack and an unused die. Thermal requires a Prepared action after a paid reroll. Light Feet requires damage prevented. The Crossing requires a Judgement release on a Bleeding enemy.

## Targeting and migration

Blood Shelter asks for a foe when healing in a multi-enemy fight. Last Measure has its own targeting prompt; if its chosen foe is no longer alive and Judged at settlement, it uses the first eligible foe in visible order.
Old save files resolve their existing boon IDs through the new catalogue; no duplicate boon copies or extra slots are introduced.

## Verification

BattleLoopTests covers reduction/cap arithmetic, Guard expiry and retention, the shared charge budget, catalogue IDs and scaling, partial-hit damage and healing, next-Attack reactions and paid-reroll interactions. The existing iOS workflow builds and runs the complete regression suite.
