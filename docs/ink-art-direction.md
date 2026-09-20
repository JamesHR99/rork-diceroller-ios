# Ink of the Duat

Original Egyptian artwork inspired by the broad flat colours, expressive ink contours,
angular shadows and readable silhouettes in the supplied Hades references. No Hades
characters or extracted game assets are included.

## Four playable demigods

| Class | Personality | Visual signature | Movement |
| --- | --- | --- | --- |
| Archer | Charismatic, defiant sun-hunter | Exposed smiling face, wild feathered hair, ivory wrap and coral sash, falcon bow | Held aim, sharp release, slight recoil |
| Warrior | Weathered, proud protector | White mane and beard, scarred face, massive lion shoulder, cobalt and yellow | Deep anticipation, heavy sweep, held contact |
| Rogue | Playful, dangerous shadow hunter | Open jackal cowl, asymmetric white hair, turquoise cloth and twin knives | Low crouch, sudden extension, turquoise afterimages |
| Magician | Regal, composed and commanding | Eclipse crown, long white hair, hot pink and ivory, mint crystal and floating ornaments | Upright gathering pose, deliberate casting gesture |

Three new drawings per hero (ready, anticipation, release), with a shared baseline.
Guard/dodge borrow anticipation; recovery/victory borrow release; hurt and defeat use
the ready drawing with the existing motion score and state treatment. These are not
new eight-frame animation sheets. Existing clips remain the fallback if new art is absent.

The fifteen enemy designs plus Straw Effigy receive new flat-colour silhouettes.
Enemy movement is procedural: floating spirits, planted heavy beasts and coiling
serpents. Boss stages retain gameplay and timings but currently share their boss's
new illustration; separate stage drawings are a future art expansion.

## Scene and effects

Three region paintings: jade/cobalt drowned temples, coral furnace halls, violet/cyan
serpent abyss. Sharp moving river reflections and fire embers add motion. The cobalt,
yellow and coral barque replaces both travelling and battle hull art. All UI chrome,
gameplay, boons, save data and combat balance remain unchanged.

Projectile wakes and cuts use tapered ink strokes. Critical and ordinary impacts
throw ivory/coloured shards. Fighters use narrow rim highlights, sharp coloured
afterimages, a short bright hurt wash and fast contact transitions. Hero anticipation
ends at the existing engine release delay. Reduce Motion disables added fighter
travel/afterimages, scene drift and impact shards.

## Asset production

Generated with the built-in image-generation tool. Final masters are preserved in
`ios/PharaohSWager/Assets.xcassets/ink_*.imageset/atlas.png`, including alpha channels.
`InkArt.swift` exposes cached virtual crops and preserves a 380-pixel hero baseline.
The image catalogue renderer and character resolver support these virtual plates.

Final prompt direction: expressive original Egyptian demigods with distinct exposed
faces, exaggerated poses, thick hand-inked contours, large uninterrupted flat colour
planes, only two shadow tones per material; coral/ivory archer, cobalt/yellow warrior,
turquoise/black rogue, hot-pink/ivory magician. Enemy palette uses acid jade, cyan,
coral, violet and bone. No realistic grain, metallic gradients, fine ornament or
broad background glows. Sprite masters requested as transparent PNGs.

Visual checks capture the complete hero pose set, enemy roster and battle staging
in all three regions. They supplement the existing combat regression suite; physical
iPhone performance and tactile feel still need device playtesting.
