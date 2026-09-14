import Foundation

/// Archer: longbow and light armour. Arrow tiers chain into the Perfect Shot.
enum ArcherContent {
    // MARK: - Starting gear

    /// Bow die: 2× Arrow I, 2× Arrow II, 1× Arrow III, 1× Bow Smack.
    static func bowDie(rarity: Rarity = .common, name: String = "Longbow") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.arrow1, .arrow1, .arrow2, .arrow2, .arrow3, .bowSmack])
    }

    /// Light armour die: 2× Dodge, 1× Roll, 1× Block, 1× Heal, 1× Focus.
    static func armorDie(rarity: Rarity = .common, name: String = "Light Armour") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.dodge, .dodge, .roll, .block, .heal, .focus])
    }

    /// Opening bow three: mid-weight draws and smacks — Twin Shot and
    /// Point-Blank fuel, with a Focus to aim by.
    static func cadenceBow(rarity: Rarity = .common) -> Die {
        Die(name: "Recurve Cadence", slot: .weapon, rarity: rarity,
            faces: [.arrow1, .arrow2, .arrow2, .bowSmack, .bowSmack, .focus])
    }

    /// Opening bow four: heavy shafts — Piercing Bolt and Perfect Shot fuel.
    static func heronBow(rarity: Rarity = .common) -> Die {
        Die(name: "Heron's Shaft", slot: .weapon, rarity: rarity,
            faces: [.arrow1, .arrow3, .arrow3, .bowSmack, .dodge, .focus])
    }

    /// Opening armour three: padded plate — Field Dressing fuel behind blocks.
    static func paddedCuirass(rarity: Rarity = .common) -> Die {
        Die(name: "Padded Cuirass", slot: .armor, rarity: rarity,
            faces: [.block, .block, .heal, .heal, .roll, .focus])
    }

    static func weapon() -> GearPiece {
        GearPiece(name: "Longbow", symbol: "arrowshape.up.circle.fill", slot: .weapon,
                  dice: [bowDie(), bowDie(), cadenceBow(), heronBow()])
    }

    static func armor() -> GearPiece {
        GearPiece(name: "Light Armour", symbol: "shield.lefthalf.filled", slot: .armor,
                  dice: [armorDie(), paddedCuirass()])
    }

    // MARK: - Combos

    static let combos: [ComboDef] = [
        // Weapon — the draw
        ComboDef(id: "arc_drawnShot", name: "Drawn Shot", owner: "archer", source: .weapon,
                 required: [.exact(.arrow1), .exact(.arrow2)], damage: 30,
                 flavor: "String to the cheek, loosed clean."),
        ComboDef(id: "arc_twinShot", name: "Twin Shot", owner: "archer", source: .weapon,
                 required: [.anyArrow, .anyArrow], sameKind: true, damage: 26, staminaNext: 2,
                 flavor: "Two shafts nocked as one."),
        ComboDef(id: "arc_piercingBolt", name: "Piercing Bolt", owner: "archer", source: .weapon,
                 required: [.exact(.arrow2), .exact(.arrow3)], damage: 44, pierce: 0.6,
                 flavor: "Straight through the shield and out the back."),
        ComboDef(id: "arc_suppressing", name: "Suppressing Fire", owner: "archer", source: .weapon,
                 required: [.exact(.arrow1), .exact(.arrow1), .exact(.arrow1)], damage: 32, stagger: 0.35,
                 flavor: "Keep their head down, keep them slow."),
        ComboDef(id: "arc_pointBlank", name: "Point-Blank", owner: "archer", source: .weapon,
                 required: [.exact(.bowSmack), .anyArrow], damage: 34, stagger: 0.2,
                 flavor: "Riser to the jaw, then the arrow."),
        ComboDef(id: "arc_perfectShot", name: "Perfect Shot", owner: "archer", source: .weapon,
                 required: [.exact(.arrow1), .exact(.arrow2), .exact(.arrow3)], damage: 80,
                 staminaNext: 2, pierce: 0.4, guaranteedCrit: true,
                 flavor: "Three draws, one breath, one perfect release."),

        // Armour — light armour
        ComboDef(id: "arc_sidestep", name: "Sidestep", owner: "archer", source: .armor,
                 required: [.exact(.dodge), .exact(.dodge)], dodge: 2, staminaNext: 2,
                 flavor: "Never where the blade expects you."),
        ComboDef(id: "arc_rollAndDraw", name: "Roll and Draw", owner: "archer", source: .armor,
                 required: [.exact(.roll), .anyArrow], damage: 28, dodge: 1,
                 flavor: "Tumble clear, rise firing."),
        ComboDef(id: "arc_fieldDressing", name: "Field Dressing", owner: "archer", source: .armor,
                 required: [.exact(.heal), .exact(.heal)], heal: 26,
                 flavor: "Boiled cloth and a steady hand."),
        ComboDef(id: "arc_quickGuard", name: "Quick Guard", owner: "archer", source: .armor,
                 required: [.exact(.block), .exact(.dodge)], block: 12, dodge: 1,
                 flavor: "Bracer up, then gone."),
        ComboDef(id: "arc_steadyAim", name: "Steady Aim", owner: "archer", source: .armor,
                 required: [.exact(.focus), .anyArrow], damage: 30, staminaNext: 2, pierce: 0.3,
                 flavor: "The world narrows to one point."),

        // Blended — light armour opening into the draw
        ComboDef(id: "arc_windRead", name: "Wind Read", owner: "archer", source: .armor,
                 required: [.exact(.focus), .exact(.arrow2), .exact(.arrow3)],
                 damage: 46, staminaNext: 2, pierce: 0.5,
                 flavor: "Read the air, hold the breath, let the heavy shaft go."),
        ComboDef(id: "arc_rollingVolley", name: "Rolling Volley", owner: "archer", source: .armor,
                 required: [.exact(.roll), .anyArrow, .anyArrow],
                 damage: 40, dodge: 1, staminaNext: 2,
                 flavor: "Tumble clear and empty the quiver from your knees."),
        ComboDef(id: "arc_coveringStep", name: "Covering Step", owner: "archer", source: .armor,
                 required: [.exact(.block), .exact(.dodge), .anyArrow],
                 damage: 30, block: 14, dodge: 1,
                 flavor: "Bracer, sidestep, shot — in that order, always."),
        ComboDef(id: "arc_fieldSurgery", name: "Field Surgery", owner: "archer", source: .armor,
                 required: [.exact(.heal), .exact(.heal), .exact(.focus)],
                 heal: 24, staminaNext: 2, regenAmount: 6, regenTurns: 2,
                 flavor: "Stitch it, breathe, pick the next target."),
        ComboDef(id: "arc_hunterCycle", name: "Hunter's Cycle", owner: "archer", source: .armor,
                 required: [.exact(.dodge), .exact(.arrow1), .exact(.arrow2), .exact(.arrow3)],
                 damage: 76, staminaNext: 2, pierce: 0.5,
                 flavor: "Out of reach, then three draws that climb into the dark."),
        ComboDef(id: "arc_stormOfShafts", name: "Storm of Shafts", owner: "archer", source: .weapon,
                 required: [.anyArrow, .anyArrow, .anyArrow, .exact(.bowSmack)],
                 damage: 70, stagger: 0.4,
                 flavor: "Three in the air and the riser across the jaw."),
    ]

    // MARK: - Offer pools

    /// Dice this class can be offered, by tier.
    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Hunting Bow", slot: .weapon, rarity: rarity,
                     faces: [.arrow1, .arrow1, .arrow1, .arrow2, .bowSmack, .focus]), "Drawn Shot · Suppressing Fire"),
                (Die(name: "Scout's Vest", slot: .armor, rarity: rarity,
                     faces: [.dodge, .dodge, .block, .heal, .roll, .focus]), "Sidestep · Quick Guard"),
            ]
        case .uncommon:
            [
                (Die(name: "Yew Longbow", slot: .weapon, rarity: rarity,
                     faces: [.arrow1, .arrow2, .arrow2, .arrow2, .arrow3, .focus]), "Twin Shot · Drawn Shot"),
                (Die(name: "Ranger's Coat", slot: .armor, rarity: rarity,
                     faces: [.dodge, .roll, .roll, .heal, .heal, .focus]), "Roll and Draw · Field Dressing"),
            ]
        case .rare:
            [
                (Die(name: "Keen Recurve", slot: .weapon, rarity: rarity,
                     faces: [.arrow2, .arrow2, .arrow3, .arrow3, .arrow1, .focus]), "Piercing Bolt · Twin Shot"),
                (Die(name: "Windstep Leathers", slot: .armor, rarity: rarity,
                     faces: [.roll, .roll, .dodge, .dodge, .focus, .heal]), "Roll and Draw · Sidestep"),
            ]
        case .signature:
            [
                (Die(name: "Greenwood Truestrike", slot: .weapon, rarity: rarity,
                     faces: [.arrow1, .arrow2, .arrow3, .arrow3, .arrow2, .arrow1]), "Perfect Shot — every face is a draw"),
                (Die(name: "Heartwood Quiver", slot: .weapon, rarity: rarity,
                     faces: [.arrow3, .arrow3, .arrow3, .arrow2, .focus, .bowSmack]), "Piercing Bolt · Twin Shot III"),
            ]
        }
    }

    /// Face reforges this class can be offered, by tier.
    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.arrow1, "Drawn Shot · Suppressing Fire"), (.block, "Quick Guard")]
        case .uncommon: [(.arrow2, "Drawn Shot · Piercing Bolt"), (.roll, "Roll and Draw")]
        case .rare: [(.arrow3, "Piercing Bolt · Perfect Shot"), (.focus, "Steady Aim")]
        case .signature: [(.arrow3, "Perfect Shot · Piercing Bolt"), (.arrow2, "Perfect Shot")]
        }
    }

    static let imbueName = "Fletcher's Whetstone"
    static let imbueSymbol = "arrowshape.up.fill"
}
