# Complete Duat art pack and opening menu

## Install the single combined ZIP

Download `DiceRoller-Complete-Duat-Art.zip` from the accompanying ChatGPT message.
It supersedes both earlier expansion ZIPs. Extract it, then merge its **17**
`.imageset` folders into `ios/PharaohSWager/Assets.xcassets/` on branch
`codex/ink-of-the-duat`. Keep `atlas.png` beside each `Contents.json`.
Do not replace the entire asset catalog: existing base art is still needed.
Commit/push the folders to update PR #10, run iOS tests and inspect the game
in the simulator/device before merging. SHA256SUMS verifies the packaged files.

## Contents

- Previous 12 combat sheets: 190 hero/enemy action and personality poses.
- `ink_regions`: the three supplied themed river backgrounds: teal ruins,
  ember/lava temples and violet serpent abyss.
- `ink_foregrounds`: three matching transparent foreground strips; empty centers
  keep characters readable. These frame the scene behind the interactive HUD.
- `ink_title_battle`: original painting of all four heroes battling Apep.
- `ink_projectiles`: 16 directional effects, including the nine hero projectile
  forms and enemy spectral, ember, venom, bone, void, bronze and time variants.
- `ink_impacts`: 16 hit/defence effects, including puncture, slash, heavy strike,
  fire, frost, arcane, healing, venom, spectral, bone, void, time, parry and evade.

## Code integration

The opening screen offers **Play Game**, **Best Runs**, **Settings**, and Continue
Voyage when a compatible save exists. Play Game opens the existing four-class
selection screen with a Back button. Starting over still requires confirmation.
Settings adjusts the existing persisted music/effects volumes; Best Runs uses
the existing record history. The title painting is aspect-fit to preserve all
four heroes instead of cropping them on wide devices.

Projectiles and impacts keep their existing flight/contact timing and combo
scaling. Enemy identity travels with each effect so simultaneous opponents use
the correct family. Explicit fire/frost/life/venom faces retain their elemental
readability; other shots use their creature family. All 16 enemy identities are
mapped, including the training dummy, although unused AI moves do not suddenly
gain projectiles. Warrior swings remain melee and use the heavy hit drawing.
The bronze projectile is available for compatible ranged enemy moves, not a
new warrior attack. Missing optional sheets fall back to code-drawn effects.

Impact frames expand/fade in code; these are effect key drawings, not multi-frame
hand-drawn explosion sequences. Region/foreground parallax respects Reduce Motion.
No new enemies, gameplay attacks, damage rules or saved-run schema are introduced.

## Verification

Mapping tests cover all enemy families and distinct hero projectile forms.
Optional installed-image tests check all 32 effect cells and all environment
strips. These tests skip until the images are installed. A UI test covers menu,
settings, all four hero choices and returning to the menu; the current battle
CI workflow runs unit tests only, so run UI tests separately in Xcode.

Generated PNG alpha is preserved; no background-removal or recolouring pass was
applied. Generation used the built-in image tool. Prompts are included in this
ZIP and `docs/world-art-prompts.md`.
