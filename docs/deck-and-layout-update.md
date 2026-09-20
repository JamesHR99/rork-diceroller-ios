# Deck and landscape layout fixes

The opening title is now **Pharaoh's Wager**, with a larger two-line gold wordmark.
Continue Voyage appears only on the main menu. Hero selection is a fixed new-run
screen with a visible Cast Off button; replacing a save still asks for confirmation.

The battle scene uses a close midship deck extending past both screen edges.
Install `Pharaohs-Wager-Deck-Update.zip` by merging its `ink_battle_deck.imageset`
folder into `ios/PharaohSWager/Assets.xcassets/` on `codex/deck-and-screen-layout`.
This small add-on does not replace the previously installed art packs. Until it
is installed, the old hull is enlarged and cropped to its center.

God rewards now have a fixed header with the god's domain, greeting, progression
and run status; all choices share the screen width. Accept/skip remain pinned
below the cards. Compact reward cards show full descriptions without horizontal
or vertical scrolling, using measured text sizing. Shop cards retain their
existing scrolling layout. Check smallest supported landscape devices and large
accessibility sizes before release.

The new deck PNG was generated with the built-in image tool. Its alpha is
preserved; the runtime fits it to the combat floor without modifying source pixels.
