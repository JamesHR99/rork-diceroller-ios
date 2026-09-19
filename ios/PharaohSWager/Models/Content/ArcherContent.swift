import Foundation

/// Archer: longbow and light armour. Arrow tiers stack into heavy volleys,
/// with a real shield and a rolling evade behind the draw.
///
/// The collection is deliberately uniform: all five bow dice are the same
/// bow and all three armour dice the same leathers, so a draw's shape is a
/// question of how many weapon dice came up rather than which named die did.
/// The riser smack lives on the armour, which is what puts Point-Blank behind
/// a mixed hand instead of handing it to any bow face.
enum ArcherContent {
    // MARK: - Starting gear

    /// Bow die: 2× Arrow I, 2× Arrow II, 1× Arrow III, 1× Focus.
    static func bowDie(rarity: Rarity = .common, name: String = "Longbow") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.arrow1, .arrow1, .arrow2, .arrow2, .arrow3, .focus])
    }

    /// Light armour die: 2× Bow Smack, 2× Block, 1× Evade, 1× Heal.
    static func armorDie(rarity: Rarity = .common, name: String = "Light Armour") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.arrow1, .bowSmack, .block, .block, .evade, .heal])
    }

    static func weapon() -> GearPiece {
        GearPiece(name: "Longbow", symbol: "arrowshape.up.circle.fill", slot: .weapon,
                  dice: (0..<GameData.ownedWeaponDice).map { _ in bowDie() })
    }

    static func armor() -> GearPiece {
        GearPiece(name: "Light Armour", symbol: "shield.lefthalf.filled", slot: .armor,
                  dice: (0..<GameData.ownedArmourDice).map { _ in armorDie() })
    }

    // MARK: - Combos

    static let combos: [ComboDef] = [
        // Weapon — the draw
        ComboDef(id: "arc_twinShot", name: "Twin Shot", owner: "archer", source: .weapon,
                 required: [ComboIngredient(.anyArrow, 2)], damage: 22,
                 flavor: "Two shafts nocked as one."),
        ComboDef(id: "arc_piercingBolt", name: "Piercing Bolt", owner: "archer", source: .weapon,
                 required: [ComboIngredient(.exact(.arrow2)), ComboIngredient(.exact(.arrow3))],
                 damage: 38, pierce: 0.6,
                 flavor: "Straight through the shield and out the back."),
        ComboDef(id: "arc_pointBlank", name: "Point-Blank", owner: "archer", source: .weapon,
                 required: [ComboIngredient(.exact(.bowSmack)), ComboIngredient(.anyArrow)],
                 damage: 26, weaken: 0.2,
                 flavor: "Riser to the jaw, then the arrow."),

        // Armour — light armour
        ComboDef(id: "arc_quickGuard", name: "Quick Guard", owner: "archer", source: .armor,
                 required: [ComboIngredient(.exact(.block)), ComboIngredient(.exact(.evade))],
                 shield: 14, dodgeCharges: 1,
                 flavor: "Bracer up, then gone."),
        ComboDef(id: "arc_fieldDressing", name: "Field Dressing", owner: "archer", source: .armor,
                 required: [ComboIngredient(.exact(.heal), 2)], heal: 22,
                 flavor: "Boiled cloth and a steady hand."),
        ComboDef(id: "arc_steadyAim", name: "Steady Aim", owner: "archer", source: .armor,
                 required: [ComboIngredient(.exact(.focus)), ComboIngredient(.anyArrow)],
                 damage: 24, pierce: 0.3,
                 flavor: "The world narrows to one point."),

        // Signatures
        ComboDef(id: "arc_perfectShot", name: "Perfect Shot", owner: "archer", source: .weapon,
                 required: [ComboIngredient(.exact(.arrow1)), ComboIngredient(.exact(.arrow2)),
                            ComboIngredient(.exact(.arrow3))],
                 damage: 34, pierce: 0.4, guaranteedCrit: true,
                 flavor: "Three draws, one breath, one perfect release."),
        ComboDef(id: "arc_stormOfShafts", name: "Storm of Shafts", owner: "archer", source: .weapon,
                 required: [ComboIngredient(.anyArrow, 4)], damage: 56, weaken: 0.4,
                 flavor: "Four in the air and the riser across the jaw."),

        // MARK: Four- and five-die mixed draws
        //
        // The long recipes buy their power with time on the clock rather than
        // a discount. Two of them are staged: the bracer goes up first and the
        // release comes later in the round, so the guard is standing before
        // the answer arrives.

        ComboDef(id: "arc_coveringVolley", name: "Covering Volley", owner: "archer", source: .armor,
                 required: [ComboIngredient(.exact(.block)), ComboIngredient(.exact(.evade)),
                            ComboIngredient(.anyArrow, 2)],
                 damage: 42, shield: 18, dodgeCharges: 1, staged: true,
                 flavor: "Bracer up, feet set, and only then the shafts."),
        ComboDef(id: "arc_falconsReversal", name: "Falcon's Reversal", owner: "archer", source: .weapon,
                 required: [ComboIngredient(.exact(.bowSmack)), ComboIngredient(.exact(.evade)),
                            ComboIngredient(.anyArrow, 2)],
                 damage: 50, dodgeCharges: 1, weaken: 0.3, markPercent: 25,
                 flavor: "Give them the riser, take the angle, mark the throat."),
        ComboDef(id: "arc_sunwardBarrage", name: "Sunward Barrage", owner: "archer", source: .weapon,
                 required: [ComboIngredient(.exact(.focus)), ComboIngredient(.anyArrow, 4)],
                 damage: 82, pierce: 0.45, markPercent: 25,
                 flavor: "Four shafts into the sun, and the sun does the rest."),
        ComboDef(id: "arc_heronsPassage", name: "Heron's Passage", owner: "archer", source: .armor,
                 required: [ComboIngredient(.exact(.block)), ComboIngredient(.exact(.evade)),
                            ComboIngredient(.exact(.heal)), ComboIngredient(.anyArrow, 2)],
                 damage: 58, heal: 20, shield: 22, dodgeCharges: 1, staged: true,
                 flavor: "Wade slow, stand still, and strike once the water settles."),
    ]

    // MARK: - Offer pools

    /// Dice this class can be offered, by tier.
    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Hunting Bow", slot: .weapon, rarity: rarity,
                     faces: [.arrow1, .arrow1, .arrow1, .arrow2, .bowSmack, .focus]), "Twin Shot · Point-Blank"),
                (Die(name: "Scout's Vest", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .block, .heal, .heal, .focus]), "Quick Guard · Field Dressing"),
            ]
        case .uncommon:
            [
                (Die(name: "Yew Longbow", slot: .weapon, rarity: rarity,
                     faces: [.arrow1, .arrow2, .arrow2, .arrow2, .arrow3, .focus]), "Twin Shot · Perfect Shot"),
                (Die(name: "Ranger's Coat", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .block, .heal, .heal, .focus]), "Quick Guard · Field Dressing"),
            ]
        case .rare:
            [
                (Die(name: "Keen Recurve", slot: .weapon, rarity: rarity,
                     faces: [.arrow2, .arrow2, .arrow3, .arrow3, .arrow1, .focus]), "Piercing Bolt · Perfect Shot"),
                (Die(name: "Windstep Leathers", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .evade, .block, .focus, .heal]), "Quick Guard · Storm of Shafts"),
            ]
        case .signature:
            [
                (Die(name: "Greenwood Truestrike", slot: .weapon, rarity: rarity,
                     faces: [.arrow1, .arrow2, .arrow3, .arrow3, .arrow2, .arrow1]), "Perfect Shot — every face is a draw"),
                (Die(name: "Heartwood Quiver", slot: .weapon, rarity: rarity,
                     faces: [.arrow3, .arrow3, .arrow3, .arrow2, .focus, .bowSmack]), "Storm of Shafts · Piercing Bolt"),
            ]
        }
    }

    /// Face reforges this class can be offered, by tier.
    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.arrow1, "Twin Shot · Perfect Shot"), (.block, "Quick Guard")]
        case .uncommon: [(.arrow2, "Twin Shot · Piercing Bolt"), (.evade, "Quick Guard")]
        case .rare: [(.arrow3, "Piercing Bolt · Perfect Shot"), (.focus, "Steady Aim")]
        case .signature: [(.arrow3, "Perfect Shot · Piercing Bolt"), (.arrow2, "Perfect Shot")]
        }
    }

    static let imbueName = "Fletcher's Whetstone"
    static let imbueSymbol = "arrowshape.up.fill"
}


