# Scenery and enemy sprites

Seventeen separate static scenery layers and one static Straw Effigy pose are supplied. The manifest gives native image dimensions and suggested display crops. No new scene code is installed.

## Composition

Place ruins behind the river, reflection highlights on the river, the solar barque above them, and reeds at the foreground edges. Place the sun disc above the barque with the separate halo behind it. The halo has an open center; make the cropped disc approximately half the halo's displayed width to cover that opening. Match the three disc states to a common displayed diameter before switching or crossfading. Their decorative rims differ, so they are visual treatments rather than identical geometry for morphing.

Place the flame over the brazier's bowl, keeping the flame base aligned with the coals. Reeds pivot near their bundled stem base. Mask the coil's lower ends with the river surface when moving it vertically. The mist and ripple layers are individual patches, not certified seamless tiles.

## Runtime motion using static artwork

The game can animate transforms and opacity: slight vertical barque movement, a slow halo fade, small reed rotations about their base, mist drifting, star twinkling and repeated ember particles. These possibilities do not make the supplied PNGs timed animation sheets. True frame animation still needs a separate pass.

The bright, weakened and nearly extinguished sun discs have independent native bounds. Keep their displayed center and diameter stable. The same applies to palette variants of river reflections.

## Straw Effigy

`duat_enemy_strawEffigy` is a full-body static pose facing left. The manifest includes a suggested ground anchor; check its alignment against the existing enemy layout. Name mapping in the game's enemy resolver is still required. No attack, hurt or defeat animation is implied.

## Checks still needed in the game

Check layer order, scale, ground anchors and small-size visibility on device. All source PNG bytes are preserved. No iOS build or device render was performed for this assets-only package.
