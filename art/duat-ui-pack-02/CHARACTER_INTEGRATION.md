# Transparent character poses

Seven transparent PNG pose assets are supplied in Xcode imagesets. Four are the faithful revisions made directly from your original portraits; three are extracted original sheet poses. No character was redrawn during background removal. Earlier rejected redesigns and opaque checkerboard review images are excluded from this ZIP.

| Hero | Runtime pose | Xcode asset name | Source |
| --- | --- | --- | --- |
| Archer | guardUp | duat_hero_archer_guardUp | Original block sheet, frame 2 |
| Rogue | hurt | duat_hero_rogue_hurt | Original damage sheet, frame 3 |
| Rogue | defeat | duat_hero_rogue_defeat | Revised pose using original portrait |
| Magician | follow | duat_hero_magician_follow | Original attack sheet, frame 6 |
| Magician | dodge | duat_hero_magician_dodge | Revised pose using original portrait |
| Magician | defeat | duat_hero_magician_defeat | Revised pose using original portrait |
| Magician | victory | duat_hero_magician_victory | Revised pose using original portrait |

Frames are zero-based. Open `characters-preview.html` to see the actual exports on dark, ivory and green backgrounds.

## Transparency and preservation

The four revised portraits have real alpha from 0 to 255. Their fully opaque foreground RGB pixels are byte-for-byte unchanged from the direct-reference revisions. Background masks, narrow anti-aliasing edges and checker-contaminated blue glow received pixel-based cleanup authorized by the user. Pale fabric, gold ornaments, face details and water highlights were protected during masking. No image generation was used in this cleanup pass.

The archer's original teal background was removed using a colour key and local edge matting. His crop extends slightly left of the nominal cell to preserve the complete forward foot. The rogue hurt and magician follow assets retain their original source alpha, whose maximum is 254 (about 99.6% opacity). This is genuine transparency, not a painted checkerboard. The magician's preceding-frame attack beam and detached spill at the frame boundary were removed during isolation. All three extracted poses have 32 pixels of transparent padding on each side and were not resampled.

All seven PNGs decode as RGBA, have fully transparent outside borders, and were inspected over three contrasting backgrounds. `character-alpha-validation.json` records dimensions, hashes and alpha checks.

## Runtime use

Copy the included `ios/` and `art/` folders into the repository root. Use the asset names above in the existing pose selection code. Uploading the art alone does not change rendering code. These files provide one static image per missing pose, not newly timed animations.

Revised portraits are 1024 × 1536. Extracted frames are smaller, at their original pixel resolution plus padding; the manifest records each size and source rectangle. Normalize character body scale, then align the feet in the scene. Suggested ground anchors are included as starting points, not verified animation anchors. Do not stretch all canvases to the same width or treat the seven files as consecutive fixed-grid frames. Existing sprite-sheet timings remain separate.

## Archer filename correction

The attached `archer_attack_charge_sheet.png` depicts taking damage and recovering. The attached `archer_take_damage_sheet.png` depicts drawing and releasing the bow. Their names and animation mappings are reversed relative to the pictured actions. Correct those runtime mappings when integrating your source sheets. Original attachments were not changed or renamed.

This pack completes the seven listed hero pose gaps with static exports. New UI/VFX loops, additional enemies, NPCs and the inventory's optional illustrations remain outside this delivery. No iOS build or device playback validation was performed.
