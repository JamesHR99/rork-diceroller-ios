import Foundation

/// Rogue: twin daggers and leather. Speed, bleed, and evade stacked until the
/// blows stop finding you.
enum RogueContent {
    // MARK: - Starting gear

    /// Dagger die: 3× Swift Slash, 2× Dagger Throw, 1× Evade.
    static func daggerDie(rarity: Rarity = .common, name: String = "Twin Daggers") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.swiftSlash, .swiftSlash, .swiftSlash, .daggerThrow, .daggerThrow, .evade])
    }

    /// Leather die: 3× Evade, 2× Heal, 1× Block.
    static func armorDie(rarity: Rarity = .common, name: String = "Leather Armour") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.evade, .evade, .evade, .heal, .heal, .block])
    }

    /// Opening blade three: throws and shadow — Twin Fang and Shadowstep fuel.
    static func hookedKris(rarity: Rarity = .common) -> Die {
        Die(name: "Hooked Kris", slot: .weapon, rarity: rarity,
            faces: [.swiftSlash, .swiftSlash, .daggerThrow, .daggerThrow, .evade, .evade])
    }

    /// Opening blade four: venom and shadow — the opening cut that leaves a mark.
    static func shadowShiv(rarity: Rarity = .common) -> Die {
        Die(name: "Shadow Shiv", slot: .weapon, rarity: rarity,
            faces: [.swiftSlash, .swiftSlash, .daggerThrow, .daggerThrow, .poison, .evade])
    }

    /// Opening armour three: rolls and mend — evade stacked with healing.
    static func shadowcloak(rarity: Rarity = .common) -> Die {
        Die(name: "Shadowcloak", slot: .armor, rarity: rarity,
            faces: [.evade, .evade, .evade, .evade, .heal, .focus])
    }

    /// Opening blade five: the back-up knife. Slashes and throws with a block,
    /// so an all-weapon draw still has Shadowstep and a guard in reach.
    static func backupKnife(rarity: Rarity = .common) -> Die {
        Die(name: "Silent Partner", slot: .weapon, rarity: rarity,
            faces: [.swiftSlash, .swiftSlash, .swiftSlash, .daggerThrow, .evade, .block])
    }

    /// Opening armour three: wrapped leathers — blocks beside the evades so
    /// the Rogue can actually stand still for a round.
    static func wrappedLeathers(rarity: Rarity = .common) -> Die {
        Die(name: "Wrapped Leathers", slot: .armor, rarity: rarity,
            faces: [.evade, .evade, .block, .block, .heal, .focus])
    }

    static func weapon() -> GearPiece {
        GearPiece(name: "Twin Daggers", symbol: "bolt.circle.fill", slot: .weapon,
                  dice: [daggerDie(), daggerDie(), hookedKris(), shadowShiv(), backupKnife()])
    }

    static func armor() -> GearPiece {
        GearPiece(name: "Leather Armour", symbol: "shield.lefthalf.filled", slot: .armor,
                  dice: [armorDie(), shadowcloak(), wrappedLeathers()])
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
                 damage: 22, evadePercent: 15,
                 flavor: "Step through the swing, answer from behind."),
        ComboDef(id: "rog_patchUp", name: "Patch Up", owner: "rogue", source: .armor,
                 required: [ComboIngredient(.exact(.heal), 2)], heal: 20,
                 flavor: "Needle, thread, teeth on the bandage."),
        ComboDef(id: "rog_hemorrhage", name: "Hemorrhage", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.daggerThrow)), ComboIngredient(.exact(.swiftSlash), 2)],
                 damage: 36, bleedAmount: 8, bleedTurns: 2, scalesWithBleed: true,
                 flavor: "Open it, widen it, keep it open."),

        // Signatures
        ComboDef(id: "rog_vanishing", name: "Vanishing Strike", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.evade)), ComboIngredient(.exact(.daggerThrow)),
                            ComboIngredient(.exact(.swiftSlash))],
                 damage: 44, bleedAmount: 6, bleedTurns: 3, guaranteedCrit: true,
                 flavor: "You were never standing there at all."),
        ComboDef(id: "rog_thousandCuts", name: "Thousand Cuts", owner: "rogue", source: .weapon,
                 required: [ComboIngredient(.exact(.swiftSlash), 3)], damage: 40,
                 bleedAmount: 10, bleedTurns: 3,
                 flavor: "Not one killing blow. A hundred small ones."),
    ]

    // MARK: - Offer pools

    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Notched Knives", slot: .weapon, rarity: rarity,
                     faces: [.swiftSlash, .swiftSlash, .swiftSlash, .swiftSlash, .daggerThrow, .evade]), "Flurry · Thousand Cuts"),
                (Die(name: "Padded Jerkin", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .evade, .heal, .block, .block]), "Shadowstep · Patch Up"),
            ]
        case .uncommon:
            [
                (Die(name: "Balanced Throwers", slot: .weapon, rarity: rarity,
                     faces: [.daggerThrow, .daggerThrow, .daggerThrow, .swiftSlash, .swiftSlash, .evade]), "Twin Fang · Opening Cut"),
                (Die(name: "Shadowweave Vest", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .evade, .evade, .heal, .heal]), "Shadowstep · Patch Up"),
            ]
        case .rare:
            [
                (Die(name: "Bleeding Edge", slot: .weapon, rarity: rarity,
                     faces: [.daggerThrow, .daggerThrow, .swiftSlash, .swiftSlash, .swiftSlash, .daggerThrow]), "Twin Fang · Hemorrhage"),
                (Die(name: "Nightrunner Leathers", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .evade, .evade, .evade, .heal]), "Shadowstep — the dark made dice"),
            ]
        case .signature:
            [
                (Die(name: "Whisper and Fang", slot: .weapon, rarity: rarity,
                     faces: [.evade, .daggerThrow, .swiftSlash, .evade, .daggerThrow, .swiftSlash]), "Vanishing Strike — the full sequence"),
                (Die(name: "Assassin's Wrap", slot: .armor, rarity: rarity,
                     faces: [.evade, .evade, .evade, .heal, .heal, .heal]), "Patch Up · Shadowstep"),
            ]
        }
    }

    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.swiftSlash, "Flurry · Thousand Cuts"), (.evade, "Shadowstep")]
        case .uncommon: [(.daggerThrow, "Twin Fang · Opening Cut"), (.heal, "Patch Up")]
        case .rare: [(.daggerThrow, "Twin Fang · Hemorrhage"), (.evade, "Shadowstep · Vanishing Strike")]
        case .signature: [(.swiftSlash, "Vanishing Strike · Thousand Cuts"), (.daggerThrow, "Vanishing Strike")]
        }
    }

    static let imbueName = "Assassin's Coating"
    static let imbueSymbol = "drop.fill"
}
