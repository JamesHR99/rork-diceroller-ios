# Hero animation sheet contract

All new animation studies for `rogue`, `warrior`, and `magician` use the same contract as the archer studies, with transparency made mandatory.

- Canvas: 1536 × 1024 PNG.
- Grid: 4 columns × 2 rows.
- Cell: 384 × 512 pixels.
- Order: left-to-right, then top-to-bottom.
- Background: genuine RGBA transparency. Empty pixels must have alpha `0`; never bake a checkerboard, matte, floor, gradient, or backdrop into the sheet.
- Anchoring: keep the feet on a shared baseline and the character at a stable full-body scale in every cell.
- Effects: retain soft magic, sparks, and motion trails with semitransparent alpha.
- Framing: do not crop the character, weapon, shield, staff, cloth, or effects.

Before accepting a new sheet, verify its dimensions and alpha channel:

```sh
identify -format '%wx%h %[channels] opaque=%[opaque]\n' path/to/sheet.png
```

Expected: `1536x1024 srgba opaque=false`.

