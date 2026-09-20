# Techniques and personality expansion

## Install

Download `DiceRoller-Techniques-and-Personality.zip` supplied with the code PR.
Extract it and copy its 12 `.imageset` folders into
`ios/PharaohSWager/Assets.xcassets/`. Merge folders; do not replace the entire
asset catalog. Keep each `Contents.json` beside its `atlas.png`. Commit these
folders to `codex/ink-of-the-duat`, the same branch as PR #10, then run the iOS tests.
The ZIP includes the previous five combat atlases; no separate earlier download
is needed. Existing base character art remains in the repository.

## New drawings: 112 poses across seven transparent atlases

| Sheet | Drawings | Purpose |
| --- | ---: | --- |
| ink_hero_techniques | 20 | Three attack variants, light parry and heavy guard per class |
| ink_hero_personality | 12 | Three acting poses per class |
| ink_enemy_melee | 16 | Primary anatomy/weapon attack per enemy, plus dummy |
| ink_enemy_alternate | 16 | Alternate move pose per enemy, plus dummy |
| ink_enemy_evade | 16 | Withdrawal/heavy defensive brace per enemy, plus dummy |
| ink_enemy_personality_a | 16 | Personality gesture |
| ink_enemy_personality_b | 16 | Personality settle |

The combined pack contains 190 poses across 12 sheets including the earlier 78.
Enemy sheet order is reedLurker, marshShade, sandCrawler, sekhen, emberWraith,
flamekeeper, ashJackal, nehebkau, devourerSpawn, uncreatedShadow, hourEater,
apep, siltColossus, bronzeEffigy, boneplateDevourer, trainingDummy.

## Runtime behavior

- Archer: standing release, kneeling heavy shot, bow bash.
- Warrior: overhead cut, sweep, guard-combo shoulder bash.
- Rogue: crosscut, thrown blade, venom thrust.
- Magician: fire, frost and arcane casting.
- Hero guards choose light parry below three dice and planted guard at three or more.
- Enemy move IDs select primary versus alternate attack; evade and heavy block use defensive art.
- Personality: archer beckons, warrior boasts, rogue plays with a knife,
  magician adjusts her crown; enemies have individual creature gestures.
- Idle acting is staggered during player planning, cancels on combat actions,
  and is disabled with Reduce Motion. Existing timing, smears, recoil, effects
  and combo escalation animate the new drawings.

These are drawn key poses combined with procedural motion, not fully hand-drawn
in-between animation. Mixed recipes select their first offensive face; they do
not switch drawing for every projectile. Apep's later coils/maw phases retain
their existing dedicated body art rather than reverting to the new head sheet.
Dummy attack drawings are spare assets and do not add attacks to its AI.
No damage rules, enemy AI moves, or new gameplay abilities are introduced.

## Verification

Transparent-body extraction checks cover all 112 new slots. Mapping tests run
without the optional atlases. Image-resolution tests skip when the pack is not
installed, and must be rerun in Xcode after installation. Missing optional art
falls back to existing character poses. Review animation timing and framing on
device before release.
