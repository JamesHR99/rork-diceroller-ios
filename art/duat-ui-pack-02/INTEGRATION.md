# Using the artwork

## Native masters and padding

The Xcode imagesets preserve the supplied PNG exports. Most UI masters are 1254 × 1254; always read each manifest entry. Hero exports include masked portrait masters and cropped original frames, documented in CHARACTER_INTEGRATION.md. Some controls occupy only a narrow band of a square master. Scaling the entire square to a short button frame would make these controls too small.

`contentRectPixels` gives a suggested top-left-origin crop in source pixels: `[x, y, width, height]`. It is measured from alpha ≥ 16 plus four pixels of padding. Use this rectangle when displaying UI pieces, or crop during your own export pipeline. Faint generated edge pixels may lie outside it. The preview uses CSS to display this rectangle; it does not modify the source PNG.

For icons, preserve aspect ratio and compare the 24/32/48/64 px samples. Optical weight varies between drawings; the supplied crop is geometric, not an optical alignment guarantee.

## Panel resizing

The large panel and small card each have `nineSliceAfterContentCropPixels` in the manifest. The caps are measured in pixels after applying `contentRectPixels`; do not apply them to the uncropped square. They keep approximately the outer quarter of the border fixed and stretch the central paper region. At scale 1, these pixel values can be used as UIImage cap insets; otherwise divide by the image scale.

Use moderate resizing. Mid-edge ornaments and texture can stretch, so large aspect-ratio changes should use the separate gold corner/divider artwork over a live paper surface. The suggested cap margins need final visual review at your target layout size; they are not Xcode slicing metadata installed by this pack.

## States and layering

Button, pip and frame variants were drawn separately. Their outlines and padding are not pixel-identical. Normalize their content bounds within a common control rectangle and check state transitions in the app. Do not treat these variants as fixed-cell animation frames.

Dice frames have transparent centers. The manifest supplies a conservative centered face window for each die frame. Keep the face sprite within that opening and render live values above it. Rolling and critical variants are static visual states, not timed roll/burst animations.

Resource fills belong inside the empty channel of `duat_ui_bar_track`. Display the cropped fill at the full channel width, then reveal the desired percentage with clipping from the leading edge. Do not squeeze a partly full bar's texture into a shorter width. The single lotus end cap may be mirrored at runtime for the other end.

Repeat a night-hour tick twelve times in code around the desired dial. Rotate/place the current-hour pointer and gate marks separately; keep the numerals live. The marker art does not impose hour counts or positions.

All assets have `frameCount: 1` and `loop: false`. No animation timing is implied. Poses, VFX loops and sprite-sheet frame alignment remain a separate production pass.
