import Foundation

/// Rogue: twin daggers and leather. Speed, bleed, venom, and evade stacked
/// until the blows stop finding you.
///
/// The collection is uniform: all five dagger dice are the same pair of blades
/// and all three armour dice the same leathers, so a draw's shape is a question
/// of how many weapon dice came up rather than which named die did. Venom now
/// rides the blades themselves, and every guard, focus and mend lives on the
/// leathers.
enum RogueContent {
    // MARK: - Starting gear

    /// Dagger die: 2× Swift Slash, 2× Dagger Throw, 1× Evade, 1× Poison.
    static func daggerDie(rarity: Rarity = .common, name: String = "Twin Daggers") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.swiftSlash, .swiftSlash, .swiftSlash, .swiftSlash, .evade, .focus])
    }

    /// Leather die: 2× Evade, 2× Heal, 1× Focus, 1× Block.
    static func armorDie(rarity: Rarity = .common, name: String = "Leather Armour") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.swiftSlash, .evade, .evade, .heal, .focus, .block])
    }

    static func weapon() -> GearPiece {
        GearPiece(name: "Twin Daggers", symbol: "bolt.circle.fill", slot: .weapon,
                  dice: (0..<GameData.ownedWeaponDice).map { _ in daggerDie() })
    }

    static func armor() -> GearPiece {
        GearPiece(name: "Leather Armour", symbol: "shield.lefthalf.filled", slot: .armor,
                  dice: (0..<GameData.ownedArmourDice).map { _ in armorDie() })
    }

    // MARK: - Combos

    static let combos: [ComboDef] = [
        // Weapon — speed and shadow
        ComboDef(id: "rog_flurry", name: "Flurry", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.swiftSlash), 2)], damage: 22,
                 flavor: "A blur of steel, gone before the eye follows."),
        ComboDef(id: "rog_openingCut", name: "Opening Cut", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.swiftSlash)), ComboIngredient(.exact(.daggerThrow))],
                 damage: 22, bleedAmount: 6, bleedTurns: 2,
                 flavor: "Open the seam, then put a blade in it."),
        ComboDef(id: "rog_twinFang", name: "Twin Fang", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.daggerThrow), 2)], damage: 26,
                 bleedAmount: 8, bleedTurns: 3,
                 flavor: "Two blades leave the hand, two wounds weep."),
        ComboDef(id: "rog_shadowstep", name: "Shadowstep", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.evade)), ComboIngredient(.anyStrike)],
                 damage: 22, dodgeCharges: 1,
                 flavor: "Step through the swing, answer from behind."),
        ComboDef(id: "rog_hemorrhage", name: "Hemorrhage", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.daggerThrow)), ComboIngredient(.exact(.swiftSlash), 2)],
                 damage: 36, bleedAmount: 8, bleedTurns: 2, scalesWithBleed: true,
                 flavor: "Open it, widen it, keep it open."),

        // Venom — the coating rides the blades now, so the poison line is the
        // Rogue's own rather than something borrowed out of a satchel.
        ComboDef(id: "rog_coatedEdge", name: "Coated Edge", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.poison)), ComboIngredient(.exact(.swiftSlash))],
                 damage: 18, poisonAmount: 6, poisonTurns: 3,
                 flavor: "Draw it through the vial, then through them."),
        ComboDef(id: "rog_creepingDeath", name: "Creeping Death", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.poison)), ComboIngredient(.exact(.daggerThrow))],
                 damage: 22, poisonAmount: 8, poisonTurns: 3,
                 flavor: "It leaves the hand slow and arrives slower."),
        ComboDef(id: "rog_witheringTouch", name: "Withering Touch", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.poison), 2)],
                 damage: 14, poisonAmount: 12, poisonTurns: 3,
                 flavor: "Both blades wet. Nobody walks that off."),

        // Armour — the leathers
        ComboDef(id: "rog_patchUp", name: "Patch Up", owner: "rogue", source: .armor,
                 required: [ComboIngredient(.exact(.heal), 2)], heal: 20,
                 flavor: "Needle, thread, teeth on the bandage."),
        ComboDef(id: "rog_smokeAndSteel", name: "Smoke and Steel", owner: "rogue", source: .armor,
                 required: [ComboIngredient(.exact(.evade)), ComboIngredient(.exact(.block))],
                 shield: 14, dodgeCharges: 1,
                 flavor: "Bracer up, and be somewhere else."),
        ComboDef(id: "rog_readTheRoom", name: "Read the Room", owner: "rogue", source: .armor,
                 required: [ComboIngredient(.exact(.focus)), ComboIngredient(.exact(.evade))],
                 dodgeCharges: 2,
                 flavor: "Watch the feet. The blade always tells the feet first."),

        // Signatures
        ComboDef(id: "rog_vanishing", name: "Vanishing Strike", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.evade)), ComboIngredient(.exact(.daggerThrow)),
                            ComboIngredient(.exact(.swiftSlash))],
                 damage: 32, bleedAmount: 6, bleedTurns: 3, guaranteedCrit: true,
                 flavor: "You were never standing there at all."),
        ComboDef(id: "rog_thousandCuts", name: "Thousand Cuts", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.swiftSlash), 3)], damage: 40,
                 bleedAmount: 10, bleedTurns: 3,
                 flavor: "Not one killing blow. A hundred small ones."),
        ComboDef(id: "rog_deathByInches", name: "Death by Inches", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.poison)), ComboIngredient(.exact(.daggerThrow)),
                            ComboIngredient(.exact(.swiftSlash))],
                 damage: 38, bleedAmount: 6, bleedTurns: 3, poisonAmount: 10, poisonTurns: 3,
                 flavor: "Venom, a thrown blade, and a cut to let it in."),

        // MARK: Four- and five-die mixed work
        //
        // The Rogue trades raw damage for statuses and cover: the long recipes
        // pay less on the swing and far more on what is left behind.

        ComboDef(id: "rog_veiledAssault", name: "Veiled Assault", owner: "rogue", source: .armor,
                 required: [ComboIngredient(.exact(.evade)), ComboIngredient(.exact(.block)),
                            ComboIngredient(.anyStrike, 2)],
                 damage: 40, shield: 14, dodgeCharges: 1, bleedAmount: 7,
                 flavor: "Be gone before the answer, and bleeding them when you return."),
        ComboDef(id: "rog_fangAndFeint", name: "Fang and Feint", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.poison)), ComboIngredient(.exact(.evade)),
                            ComboIngredient(.anyStrike, 2)],
                 damage: 38, dodgeCharges: 1, poisonAmount: 5, markPercent: 25,
                 flavor: "Show them the left hand. The right one is already wet."),
        ComboDef(id: "rog_nightfallAmbush", name: "Nightfall Ambush", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.evade)), ComboIngredient(.exact(.poison)),
                            ComboIngredient(.exact(.daggerThrow)), ComboIngredient(.exact(.swiftSlash), 2)],
                 damage: 66, dodgeCharges: 1, bleedAmount: 9, poisonAmount: 6, markPercent: 25,
                 flavor: "Everything at once, out of a doorway, and then nothing at all."),
        ComboDef(id: "rog_serpentsDance", name: "Serpent's Dance", owner: "rogue", source: .armor,
                 required: [ComboIngredient(.exact(.evade), 2), ComboIngredient(.exact(.poison)),
                            ComboIngredient(.anyStrike, 2)],
                 damage: 44, shield: 16, dodgeCharges: 2, poisonAmount: 8, staged: true,
                 flavor: "Coil, let it strike air, and let the venom do the arithmetic."),
    ]

    // MARK: - Offer pools

    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Notched Knives", slot: .weapon, rarity: rarity,
                     faces: [.swiftSlash, .swiftSlash, .swiftSlash, .daggerThrow, .poison, .evade]), "Flurry · Thousand Cuts"),
                (Die(name: "Padded Jerkin", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .heal, .heal, .block, .block]), "Smoke and Steel · Patch Up"),
            ]
        case .uncommon:
            [
                (Die(name: "Balanced Throwers", slot: .weapon, rarity: rarity,
                     faces: [.daggerThrow, .daggerThrow, .daggerThrow, .swiftSlash, .poison, .evade]), "Twin Fang · Creeping Death"),
                (Die(name: "Shadowweave Vest", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .evade, .heal, .heal, .focus]), "Read the Room · Patch Up"),
            ]
        case .rare:
            [
                (Die(name: "Bleeding Edge", slot: .weapon, rarity: rarity,
                     faces: [.daggerThrow, .daggerThrow, .swiftSlash, .swiftSlash, .swiftSlash, .poison]), "Twin Fang · Hemorrhage"),
                (Die(name: "Venomer's Kit", slot: .weapon, rarity: rarity,
                     faces: [.poison, .poison, .poison, .daggerThrow, .swiftSlash, .evade]), "Withering Touch · Death by Inches"),
            ]
        case .signature:
            [
                (Die(name: "Whisper and Fang", slot: .weapon, rarity: rarity,
                     faces: [.evade, .daggerThrow, .swiftSlash, .poison, .daggerThrow, .swiftSlash]), "Vanishing Strike — the full sequence"),
                (Die(name: "Assassin's Wrap", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .evade, .heal, .heal, .focus]), "Patch Up · Read the Room"),
            ]
        }
    }

    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.swiftSlash, "Flurry · Thousand Cuts"), (.evade, "Shadowstep")]
        case .uncommon: [(.daggerThrow, "Twin Fang · Opening Cut"), (.poison, "Coated Edge")]
        case .rare: [(.poison, "Withering Touch · Creeping Death"), (.evade, "Shadowstep · Vanishing Strike")]
        case .signature: [(.swiftSlash, "Vanishing Strike · Thousand Cuts"), (.daggerThrow, "Death by Inches")]
        }
    }

    static let imbueName = "Assassin's Coating"
    static let imbueSymbol = "drop.fill"
}


