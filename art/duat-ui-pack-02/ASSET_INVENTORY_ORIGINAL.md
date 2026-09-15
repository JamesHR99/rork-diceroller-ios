# DiceRoller — background and sprite inventory

Audit date: 15 September 2026.
Source: [JamesHR99/rork-diceroller-ios](https://github.com/JamesHR99/rork-diceroller-ios), main at `b1f37f13a1e9548f0909ed2460309bb17ca7c776`.

Assets only. No game code, commits, branches or pull requests were changed on GitHub. This checklist distinguishes existing art, custom artwork needed for a complete art pass, and optional illustrations. The current game already renders much of its UI and scenery through code; a missing custom sprite is not a broken game feature.

Generated this turn: three background PNGs (1672 × 941, RGB) and one winged-scarab PNG (2172 × 724, RGBA with genuine transparency). These are static art, not completed animated sprite sheets. Existing character files were inventoried, not comprehensively revalidated for transparency or frame alignment.

## 1. Backgrounds

The twelve hours use three regions. A separate background per hour is unnecessary.

| Background | Use | Status |
| --- | --- | --- |
| Gate of Reeds | Hours 1–4; drowned pylons, papyrus banks, dark jade river | Generated this turn |
| Gate of Fire | Hours 5–8; furnace halls, basalt pylons, ember river | Generated this turn |
| Gate of Coils | Hours 9–12; Apep’s coils, violet-black water, starless darkness | Generated this turn |
| Title / moored solar barque | Character selection and title | Optional; can reuse Gate of Reeds |
| Divine shrine / altar | Patron and boon offers | Optional dedicated backdrop |
| Ferryman’s trading skiff | Shop | Optional dedicated backdrop |
| Ptah’s workshop / basalt bench | Chisel selection | Optional dedicated backdrop |
| Quiet mooring | Rest | Optional dedicated backdrop |
| Omen / river encounter | Event choices | Optional dedicated backdrop; small vignette also works |
| Dawn / arrival of the sun | Victory screen | Optional dedicated backdrop |
| Extinguished sun / swallowed river | Defeat screen | Optional dedicated backdrop |
| Night chart surface | Route selection | Reuse existing papyrus texture; custom map illustration optional |

Existing catalogue scenery: `solar_barque_duat_river`, `papyrus_texture`, `aged_papyrus_texture`. The first combines scenery with the barque; it does not supply separately movable foreground parts.

## 2. Environment sprites and ambient animation layers

These are proposed separate art assets for replacing or enriching the current procedural scenery. They are not all mandatory additions.

| Layer | Pieces / animation |
| --- | --- |
| Solar barque | Isolated hull/deck with Egyptian prow and stern; optional bobbing loop |
| Ra’s sun disc | Solid disc plus separate halo; bright, weakened and nearly extinguished treatments |
| River reflection | Transparent looping ripple highlights, jade / ember / violet palettes |
| Papyrus reeds | Left and right clusters; subtle sway loop |
| Furnace fire | Small brazier flame loop and optional isolated brazier prop |
| Embers / sparks | Transparent particle sprites; use in environment and effects |
| River mist | Soft transparent strips for slow drifting |
| Stars | Small glints / twinkle sprites; first region only |
| Apep’s coils | Isolated surface coil segments; slow rise and submerge animation |
| Distant ruins | Pylons, broken lotus columns and bank silhouettes if layered movement is desired |

## 3. Shared UI sprite kit

Most of these are currently native shapes or system symbols. “Create” means custom art for the visual refresh. Reuse common skins and change the live text rather than painting a separate button for each label.

| Sprite group | Required variants / purpose | Status |
| --- | --- | --- |
| Winged scarab emblem | Gold / lapis / jade title ornament | Generated this turn; static transparent PNG |
| Large papyrus panel | General sheets, codex, records, summaries | Existing texture; create ornamental frame if desired |
| Small papyrus card | Offer, gear, item and relic cards | Create reusable frame |
| Cartouche label frame | God / hero names and compact headings | Create |
| Primary action button | Normal, pressed, disabled, highlighted | Create; shared by Cast Off, Roll, Fight, End Turn, Claim and Continue |
| Secondary / compact button | Normal, pressed, disabled, selected | Create; navigation, Freeze, class picker |
| Tabs / selector outline | Unselected and selected | Create |
| Class card frame | Archer, warrior, rogue and magician accents | Create; reuse portraits |
| Rarity frames / badges | Clay, Copper, Lapis, Gold Leaf | Create four material treatments |
| Dice tray / reel surround | Empty, ready, rolling, selected, held/frozen, spent, critical | Create reusable base and state overlays |
| Turn-plan strip | Face slots, chain connectors, stamina cost badge, next-turn / echo marker | Create |
| Enemy intent plate | Move / damage forecast frame | Create |
| Health / shield / armour bars | Track, fill and decorative end caps; player / enemy sizes | Create reusable parts |
| Stamina display | Pip full / empty and reserve / next-turn indicator | Create |
| Target marker | Selected enemy outline or ground ring | Create |
| Night dial | Twelve-hour track, current-hour highlight, cleared mark and gate boundary | Create reusable marks; numerals remain live text |
| Route node frames | Available, selected, cleared, locked/unavailable, boss | Create |
| Banner frame | Gate arrival, stage change, combo, trial, reward, victory, defeat | Create shared frame with colour / ornament variants |
| Tooltip / information panel | Small and large frame | Create reusable frame |
| Dividers and corners | Hieroglyph strip, winged divider, gold corner ornaments | Create |
| General utility icons | Back, forward, close, confirm, codex/book, records/hourglass, swap/reforge, gold/currency | Create as needed; reuse existing semantic symbols |
| Equipment slot badges | Weapon, armour, item | Create three |
| Class sigils | Bow, warrior weapon/shield, paired daggers, wand/runes | Create four |

## 4. Dice-face icons — 21

These are exact semantic faces from `FaceKind.swift`. They currently use system symbols. Keep every icon recognizable at small die size.

| Family | Icons to create |
| --- | --- |
| Archer | Arrow I; Arrow II; Arrow III; Bow Smack |
| Warrior | Overhead; Side Swing |
| Rogue | Swift Slash; Dagger Throw |
| Magician | Fire Rune; Frost Rune; Life Rune; Arcane Rune; Wand Zap; Channel |
| Shared defence / support | Block; Evade; Heal; Focus; Energize |
| Items | Bomb; Poison |

## 5. Status and navigation icons

| Group | Icons |
| --- | --- |
| Combat resources / states | Health, shield/block, bronze armour, stamina, focus/primed attack, evade, regeneration, bleed, burn, poison, judgement, frost/stagger, marked target, critical, piercing damage, champion |
| Dice interactions | Roll, held/frozen, spent, chain link, echo, reforge, imbue, swap |
| Seven route encounters | Guardian, Herald, Shrine, Ferryman, Mooring, Omen, Serpent-Lord |
| Three gate emblems | Reeds, Fire, Coils |
| Divine sigils | Ra, Sobek, Anubis, Bes, Horus, Bastet |
| Divine-trial treatment | Champion halo/seal, six deity colour/sigil variants; can reuse divine sigils |
| Upgrade controls | Ptah / workshop hammer, heal/rest, whetstone/upgrade |

Shared meanings can reuse one icon across faces, status badges and cards. Count semantic meanings, not every repeated on-screen instance.

## 6. Items, relics and Chisels

These currently use system symbols. Each named object below is a candidate for a unique inventory / reward sprite.

| Group | Count | Sprites |
| --- | --- | --- |
| Items | 7 | Healing Potion; Smoke Bomb; Poison Vial; Explosive Charge; Alchemist's Kit; Warlock's Charm; Phoenix Flask |
| Relics | 6 | Brazier of the Dawn; Vial of the Nile; Ward of Bes; Eye of Horus; The Ferryman's Toll; Canopic Heart |
| Archer Chisels | 3 | Twin Bowstring; Siege Draw; Adjustable Nock |
| Warrior Chisels | 3 | Crescent Edge; Counterweight; Relentless Advance |
| Rogue Chisels | 3 | Returning Knife; Concealed Blade; Assassin's Commitment |
| Magician Chisels | 3 | Prismatic Focus; Echoing Staff; Alternating Current |

## 7. Divine upgrades and pairings

Six god portraits already exist. Their sigils can identify ordinary offers; dedicated illustrations for every upgrade and pairing are optional, not required for the current layout.

| Deity | Four upgrade icons | Capstone icon |
| --- | --- | --- |
| Ra | Kindling; Sun's Edge; Solar Wind; Ashes to Ashes | Solar Flare |
| Sobek | Deep Water; Blood Scent; First Feast; Riptide | Jaws of the Nile |
| Anubis | Great Tally; Second Reading; Burial Gift; Weighed to the Grain | Final Verdict |
| Bes | The Stout Door; Rebuild the Wall; The Counter-Swing; House of Joy | Unbroken House |
| Horus | Falcon's Eye; The Keen Edge; Wind-Reader; Thermal | Eye of the Falcon |
| Bastet | Pounce; Light Landing; Claws Out; Unscathed | Nine Lives Unbound |

Optional pairing icons (15):

- [ ] Boiling Nile
- [ ] Funeral Pyre
- [ ] Forge Song
- [ ] Sunstrike
- [ ] Dancing Flame
- [ ] The Crossing
- [ ] Crocodile Hide
- [ ] Reed and Sky
- [ ] Death Roll
- [ ] Guardian of the Tomb
- [ ] The Weighing Eye
- [ ] Borrowed Life
- [ ] Watchful Guardian
- [ ] Warm Doorstep
- [ ] Silent Descent

## 8. Named equipment illustration appendix

The current equipment can share class / slot icons and rarity borders. Create these separate illustrations only if every named piece should have distinct art. Names below are preserved from the game even where the character artwork depicts Egyptian equivalents.

| Class | Named equipment / dice |
| --- | --- |
| Archer | Recurve Cadence; Heron's Shaft; Padded Cuirass; Longbow; Light Armour; Hunting Bow; Scout's Vest; Yew Longbow; Ranger's Coat; Keen Recurve; Windstep Leathers; Greenwood Truestrike; Heartwood Quiver |
| Warrior | Siege Axe; Boarding Maul; Bronze Aegis; Longsword; Plate Armour; Iron Broadsword; Banded Mail; Warblade; Guardian's Plate; Executioner's Edge; Bastion Harness; Cyclone Greatsword; Warlord's Bulwark |
| Rogue | Hooked Kris; Shadow Shiv; Shadowcloak; Twin Daggers; Leather Armour; Notched Knives; Padded Jerkin; Balanced Throwers; Shadowweave Vest; Bleeding Edge; Nightrunner Leathers; Whisper and Fang; Assassin's Wrap |
| Magician | Ember Staff; Frost Scepter; Warded Kilt; Magic Wand; Robes; Apprentice Wand; Novice Robes; Emberwood Wand; Warded Vestments; Frostglass Rod; Channeler's Mantle; Stormcaller's Focus; Meteoric Sceptre |

## 9. Character sprite coverage

All four heroes have portraits and multiple combat plates. Each has attack, idle, block and take-damage sheet files under `art/characters/`. Those source sheets are separate from the catalogue plates the current animation resolver selects. Do not commission duplicates without checking those sheets first.

The existing runtime uses nine pose slots per hero: idle, windup, strike, follow-through, guard, hurt, dodge, defeat, victory. A missing slot currently falls back to idle.

| Hero | Pose slot | Current catalogue coverage | Note |
| --- | --- | --- | --- |
| archer | idle | Exists: `egyptian_archer_idle` |  |
| archer | windup | Exists: `archer_bow_drawn_attack` |  |
| archer | strike | Exists: `egyptian_archer_strike` |  |
| archer | follow | Exists: `egyptian_archer_bow_down` | Often reuses another pose; dedicated follow-through optional |
| archer | guardUp | No mapped catalogue sprite; falls back to idle |  |
| archer | hurt | Exists: `egyptian_archer_hurt` |  |
| archer | dodge | Exists: `egyptian_archer_dodge` |  |
| archer | defeat | Exists: `egyptian_archer_defeat_pose` |  |
| archer | victory | Exists: `egyptian_archer_victory` |  |
| warrior | idle | Exists: `egyptian_warrior_idle` |  |
| warrior | windup | Exists: `the_same_character_2` |  |
| warrior | strike | Exists: `the_same_character` |  |
| warrior | follow | Exists: `egyptian_warrior_attack` | Often reuses another pose; dedicated follow-through optional |
| warrior | guardUp | Exists: `egyptian_warrior_guard` |  |
| warrior | hurt | Exists: `egyptian_warrior_hurt` |  |
| warrior | dodge | Exists: `egyptian_warrior_dodge` |  |
| warrior | defeat | Exists: `egyptian_warrior_defeated` |  |
| warrior | victory | Exists: `egyptian_warrior_victory` |  |
| rogue | idle | Exists: `egyptian_rogue_idle` |  |
| rogue | windup | Exists: `egyptian_rogue_crouch_knives` |  |
| rogue | strike | Exists: `egyptian_rogue_strike_pose` |  |
| rogue | follow | Exists: `egyptian_rogue_strike_pose` | Often reuses another pose; dedicated follow-through optional |
| rogue | guardUp | Exists: `egyptian_rogue_guard_pose_2` |  |
| rogue | hurt | No mapped catalogue sprite; falls back to idle |  |
| rogue | dodge | Exists: `egyptian_rogue_dodge_4` |  |
| rogue | defeat | No mapped catalogue sprite; falls back to idle |  |
| rogue | victory | Exists: `egyptian_rogue_victory_2` |  |
| magician | idle | Exists: `egyptian_priest_magician` |  |
| magician | windup | Exists: `priest_magician_staff_attack_3` |  |
| magician | strike | Exists: `egyptian_priest_staff_attack_11` |  |
| magician | follow | No mapped catalogue sprite; falls back to idle |  |
| magician | guardUp | Exists: `egyptian_priest_guard_staff_3` |  |
| magician | hurt | Exists: `egyptian_priest_hurt_2` |  |
| magician | dodge | No mapped catalogue sprite; falls back to idle |  |
| magician | defeat | No mapped catalogue sprite; falls back to idle |  |
| magician | victory | No mapped catalogue sprite; falls back to idle |  |

A resolved pose may reuse another drawing; “Exists” does not mean a complete multi-frame animation. The archer guard, rogue hurt/defeat, and magician follow-through/dodge/defeat/victory slots lack mapped catalogue sprites. Source sheets may contain useful frames for some of these.

### Enemies

| Enemy | Current art |
| --- | --- |
| Straw Effigy | No mapped character artwork |
| Reed Lurker | Base sprite exists; complete animation set still needs checking |
| Marsh Shade | Base sprite exists; complete animation set still needs checking |
| Sand Crawler | Base sprite exists; complete animation set still needs checking |
| Sekhen the Reed Serpent | Base sprite exists; complete animation set still needs checking |
| Ember Wraith | Base sprite exists; complete animation set still needs checking |
| Flamekeeper of the Fourth Hour | Base sprite exists; complete animation set still needs checking |
| Ash Jackal | Base sprite exists; complete animation set still needs checking |
| Nehebkau, the Furnace Coil | Base sprite exists; complete animation set still needs checking |
| Devourer Spawn | Base sprite exists; complete animation set still needs checking |
| Shadow of the Uncreated | Base sprite exists; complete animation set still needs checking |
| Hour-Eater | Base sprite exists; complete animation set still needs checking |
| Apep, the Uncoiled | Base sprite exists; complete animation set still needs checking |
| Silt Colossus | Reuses Sand Crawler art |
| Bronze Effigy | Reuses Flamekeeper art |
| Boneplate Devourer | Reuses Devourer Spawn art |

Reed Lurker has several extra attack/hurt/defeat plates. Marsh Shade has attack and hurt plates. Sand Crawler has an attack plate. Most other foes rely on one base illustration plus code-driven motion.

For a full enemy animation pass: idle; anticipation; strike; recovery; hurt; defeat; and guard/dodge where that foe uses them. Boss-specific attacks can be added separately. Apep has three gameplay stages (Head, Coils, Maw); distinct stage artwork would be an optional expansion. Herald, armoured, pack and divine champion variants can reuse base sprites with badges/overlays.

### Gods and supporting figures

Existing portraits: Ra, Sobek, Anubis, Bes, Horus, Bastet.

Optional new NPC sprites: Ferryman and Ptah. Story vignettes can depict other encounter figures without requiring animated NPCs.

## 10. Event vignettes — optional

Nine event illustrations could replace the current event symbols; they do not need nine full-screen backgrounds.

- [ ] A Heart on the Scales
- [ ] The Lake That Offers a Trade
- [ ] The Drowned Crew
- [ ] The Sunken Shrine
- [ ] The Embalmer's Skiff
- [ ] The Pool of Still Stars
- [ ] The Bored Gatekeeper
- [ ] The Standing Idol
- [ ] A Shed Skin

## 11. UI and effect animation sprite sheets to create

No new animated sprite sheets were generated this turn. This is the proposed animation asset list; some corresponding effects already exist in code.

| Animation | Behaviour | Art pieces |
| --- | --- | --- |
| Scarab / sun idle | Gentle repeating aura | Static emblem plus separate halo frames |
| Ready button | Slow looping light sweep | Transparent sheen strip |
| Button press / selection | Short one-shot accent | Gold edge flash / selected outline |
| Dice roll / settle | Loop while rolling, short landing flash | Motion streaks, settle burst |
| Hold / Freeze | Loop or static held state; short activation | Frost edge, crystal glints |
| Critical roll | One-shot burst | Gold rays and sparks |
| Combo connection / activation | One-shot travelling link and burst | Chain segment, solar sigil, impact rays |
| Boon / reward reveal | One-shot reveal then subtle idle | Deity halo, gold motes, card highlight |
| Gate / hour transition | One-shot sweep | Gate sigil glow, winged wipe or gold particles |
| Target selection | Subtle pulse loop | Transparent ground ring / outline |
| Shield gain / break | Short one-shots | Egyptian shield seal, fractured fragments |
| Heal / regeneration | Short one-shot or restrained loop | Ankh / lotus motes |
| Burn / poison / bleed / judgement | Status loops and impact triggers | Flame, venom, blood, scales/seal |
| Attack accents | One-shot, action-specific | Arrow trails, khopesh slash, dagger streaks, fire/frost/arcane bolts |
| Victory / defeat | One-shot | Rising sun rays / extinguishing ember treatment |

## 12. Delivery conventions

- Backgrounds: opaque landscape PNGs; keep central play area and likely crop areas visually quiet.
- Foreground sprites, icons, frames and VFX: true RGBA transparency outside the intended artwork. A panel's painted interior can remain opaque.
- Keep labels, numbers, dice values and button text out of images.
- Reuse frame skins at different sizes; deliver resizable border parts or clearly documented nine-slice margins for panels.
- Icon masters: suggested 512 × 512, with consistent padding and readable silhouettes at 24–48 pixels. These are proposed production sizes, not engine requirements.
- Animation sheets: fixed cell dimensions, constant anchor, frame order, frame count, frame duration and loop/one-shot metadata. Do not allow a subject to spill into adjacent cells.
- Suggested style: bold ink contours, angular painted lighting, antique gold, lapis, jade and dark papyrus, with the game's region and class accents.
- The four images created this turn used built-in image generation. Prompt descriptions: Gate of Reeds drowned Egyptian river; Gate of Fire basalt furnace river; Gate of Coils Apep's starless violet waters; isolated winged scarab in gold/lapis/jade. They were not installed into the game.

## Suggested production order

1. Keep the three generated region backgrounds and transparent scarab for review.
2. Create the 21 face icons, core dice states, buttons, panels and HUD frames.
3. Create the six deity sigils, seven route icons, item/relic sprites and twelve Chisel icons.
4. Produce the UI animation sheets and ambient layers.
5. Expand into optional location backgrounds, event vignettes and unique equipment illustrations.
6. Fill character/enemy pose gaps only if character animation work is included in the next asset batch.

## Source files inspected

- [Gate regions](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Gate.swift)
- [Screens and routing](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/ContentView.swift)
- [Character art mappings](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Utilities/CharacterArt.swift)
- [Dice faces](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/FaceKind.swift)
- [Enemy catalogue](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Content/EnemyContent.swift)
- [Divine upgrades and pairings](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/GodKit.swift)
- [Chisels](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Chisel.swift)
- [Items](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Content/SharedContent.swift)
- [Relics](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Content/RelicContent.swift)
- [Route nodes](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/Voyage.swift)
- [Events](https://github.com/JamesHR99/rork-diceroller-ios/blob/main/ios/DiceRoller/Models/RunEvent.swift)

