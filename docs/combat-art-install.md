# Combat art expansion: manual asset installation

This code update extends PR #10 on `codex/ink-of-the-duat` in
`JamesHR99/rork-diceroller-ios`. The five new PNG atlases are delivered separately
as `DiceRoller-Combat-Art-Expansion.zip`; they are NOT included in the code commit.

## Install

1. Check out or download the latest `codex/ink-of-the-duat` branch (PR #10).
2. Extract `DiceRoller-Combat-Art-Expansion.zip`.
3. Copy its five `.imageset` folders from `ios/PharaohSWager/Assets.xcassets/`
   into the IDENTICAL path in your repository. Merge folders; do not replace or
   delete the existing `Assets.xcassets` directory.
4. Each new imageset contains `atlas.png` and `Contents.json`. Keep both files,
   filenames, and folder names unchanged. Do not import the entire atlas as
   separate loose files or rename it in Xcode.
5. Commit these five folders to `codex/ink-of-the-duat` and push. PR #10 updates
   automatically. Do not upload the ZIP itself as the runtime asset.
6. Open `ios/PharaohSWager.xcodeproj`, run the PharaohSWager scheme, and rerun
   the unit tests and simulator visual checks. Review before merging.

Expected folders:

- `ink_hero_actions.imageset`: 24 poses, four columns × six rows.
- `ink_hero_specials.imageset`: 12 finisher/victory/defeat poses, four × three.
- `ink_enemy_guards.imageset`: 15 guard poses, five × three.
- `ink_enemy_hurt.imageset`: 15 damage reactions, five × three.
- `ink_apep_phases.imageset`: 12 head/coils/maw poses, three × four.

The existing backgrounds, barque, enemy idle/attack art, and training dummy
remain in PR #10. This ZIP contains only this expansion, not the whole game.

## Behaviour

- Nine distinct illustrated hero poses, with follow-through sharing strike.
- Dedicated enemy guards and hurt reactions; evasions reuse guard art with
  motion and defeat reuses hurt. Training dummy retains its existing drawing.
- Three distinct Apep phase bodies, each with idle/attack/guard/hurt art.
- Recipe-aware motion for sweeps, overheads, bow attacks, knives, and spells;
  granted guard/evade can lead into offensive combinations.
- Four-plus-die attacks use finisher drawings. Projectile silhouettes add
  embellishments at three and five dice, with a maximum six-face schedule.
- Shared projectile/contact timing and bounded effect geometry.
- Reduce Motion suppresses fighter travel/afterimages and extra effect rotation.

These are illustrated key poses plus procedural animation, not fully drawn
frame-by-frame in-betweens for every possible recipe. Damage, boons, dice costs,
and reroll rules are unchanged; presentation timing can differ.

## Validation and fallback

Local checks verified 78 separate sprite slots, alpha channels, shared canvas
heights, and patch whitespace. Native Xcode/iOS compilation is not available in
the authoring environment; consult the PR checks and test on an iPhone.
Asset-specific tests explicitly skip until the five atlases are installed;
this must not be mistaken for validation of the new art. Existing art remains
the fallback in the code-only PR. Malformed atlases fail safely to older art.

The ZIP includes SHA256SUMS.txt to verify file integrity. Master PNGs were
generated with the built-in image generator using the supplied four-hero and
enemy identity references: saturated Egyptian flat-colour cel shading, sharp
ink contours, class-coloured costumes, isolated transparent silhouettes,
right-facing heroes and left-facing enemies, dedicated expressive action poses.
