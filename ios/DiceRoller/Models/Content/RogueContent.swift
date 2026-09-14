import Foundation

/// Rogue: twin daggers and leather. Speed, bleed and shadow.
enum RogueContent {
    // MARK: - Starting gear

    /// Dagger die: 3× Swift Slash, 2× Dagger Throw, 1× Dodge.
    static func daggerDie(rarity: Rarity = .common, name: String = "Twin Daggers") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.swiftSlash, .swiftSlash, .swiftSlash, .daggerThrow, .daggerThrow, .dodge])
    }

    /// Leather die: 3× Dodge, 2× Heal, 1× Block.
    static func armorDie(rarity: Rarity = .common, name: String = "Leather Armour") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.dodge, .dodge, .dodge, .heal, .heal, .block])
    }

    /// Opening blade three: throws and shadow — Twin Fang and Shadowstep fuel.
    static func hookedKris(rarity: Rarity = .common) -> Die {
        Die(name: "Hooked Kris", slot: .weapon, rarity: rarity,
            faces: [.swiftSlash, .swiftSlash, .daggerThrow, .daggerThrow, .dodge, .dodge])
    }

    /// Opening blade four: venom and smoke — the opening cut that leaves a mark.
    static func shadowShiv(rarity: Rarity = .common) -> Die {
        Die(name: "Shadow Shiv", slot: .weapon, rarity: rarity,
            faces: [.swiftSlash, .swiftSlash, .daggerThrow, .daggerThrow, .poison, .smoke])
    }

    /// Opening armour three: rolls and mend — evade plus block in one face.
    static func shadowcloak(rarity: Rarity = .common) -> Die {
        Die(name: "Shadowcloak", slot: .armor, rarity: rarity,
            faces: [.dodge, .dodge, .roll, .roll, .heal, .focus])
    }

    static func weapon() -> GearPiece {
        GearPiece(name: "Twin Daggers", symbol: "bolt.circle.fill", slot: .weapon,
                  dice: [daggerDie(), daggerDie(), hookedKris(), shadowShiv()])
    }

    static func armor() -> GearPiece {
        GearPiece(name: "Leather Armour", symbol: "shield.lefthalf.filled", slot: .armor,
                  dice: [armorDie(), shadowcloak()])
    }

    // MARK: - Combos

    static let combos: [ComboDef] = [
        // Weapon — speed and shadow
        ComboDef(id: "rog_flurry", name: "Flurry", owner: "rogue", source: .weapon,
                 required: [.exact(.swiftSlash), .exact(.swiftSlash)], damage: 22, staminaNext: 2,
                 flavor: "A blur of steel, gone before the eye follows."),
        ComboDef(id: "rog_openingCut", name: "Opening Cut", owner: "rogue", source: .weapon,
                 required: [.exact(.swiftSlash), .exact(.daggerThrow)], damage: 28,
                 bleedAmount: 6, bleedTurns: 2, mark: 1.25,
                 flavor: "Open the seam, then put a blade in it."),
        ComboDef(id: "rog_cutthroat", name: "Cutthroat", owner: "rogue", source: .weapon,
                 required: [.exact(.daggerThrow), .exact(.swiftSlash)], damage: 26, scalesWithBleed: true,
                 flavor: "Follow the blood. Finish the work."),
        ComboDef(id: "rog_twinFang", name: "Twin Fang", owner: "rogue", source: .weapon,
                 required: [.exact(.daggerThrow), .exact(.daggerThrow)], damage: 34,
                 bleedAmount: 10, bleedTurns: 3,
                 flavor: "Two blades leave the hand, two wounds weep."),
        ComboDef(id: "rog_shadowstep", name: "Shadowstep", owner: "rogue", source: .weapon,
                 required: [.exact(.dodge), .anyStrike], damage: 28, dodge: 1,
                 flavor: "Step through the swing, answer from behind."),
        ComboDef(id: "rog_thousandCuts", name: "Thousand Cuts", owner: "rogue", source: .weapon,
                 required: [.exact(.swiftSlash), .exact(.swiftSlash), .exact(.swiftSlash)],
                 damage: 42, bleedAmount: 8, bleedTurns: 3,
                 flavor: "Not one killing blow. A hundred small ones."),
        ComboDef(id: "rog_vanishing", name: "Vanishing Strike", owner: "rogue", source: .weapon,
                 required: [.exact(.dodge), .exact(.daggerThrow), .exact(.swiftSlash)],
                 damage: 60, staminaNext: 2, blocksAll: true, guaranteedCrit: true,
                 flavor: "You were never standing there at all."),

        // Armour — leather
        ComboDef(id: "rog_blur", name: "Blur", owner: "rogue", source: .armor,
                 required: [.exact(.dodge), .exact(.dodge)], dodge: 2,
                 flavor: "Two swings, two empty places."),
        ComboDef(id: "rog_untouchable", name: "Untouchable", owner: "rogue", source: .armor,
                 required: [.exact(.dodge), .exact(.dodge), .exact(.dodge)],
                 staminaNext: 3, blocksAll: true,
                 flavor: "They are fighting smoke and losing."),
        ComboDef(id: "rog_patchUp", name: "Patch Up", owner: "rogue", source: .armor,
                 required: [.exact(.heal), .exact(.heal)], heal: 24, cleanseBleed: true,
                 flavor: "Needle, thread, teeth on the bandage."),
        ComboDef(id: "rog_adrenaline", name: "Adrenaline", owner: "rogue", source: .armor,
                 required: [.exact(.dodge), .exact(.heal)], heal: 12, staminaNext: 3,
                 flavor: "The blood sings. Next turn you surge."),
        ComboDef(id: "rog_deflect", name: "Deflect", owner: "rogue", source: .armor,
                 required: [.exact(.block), .exact(.swiftSlash)], damage: 18, block: 14,
                 flavor: "Turn the blade aside and cut on the way past."),

        // Blended — leather threaded between the blades
        ComboDef(id: "rog_ghostwalk", name: "Ghostwalk", owner: "rogue", source: .armor,
                 required: [.exact(.dodge), .exact(.swiftSlash), .exact(.dodge)],
                 damage: 34, dodge: 2, staminaNext: 2,
                 flavor: "In, once, and out before the body turns."),
        ComboDef(id: "rog_bloodDebt", name: "Blood Debt", owner: "rogue", source: .armor,
                 required: [.exact(.dodge), .exact(.daggerThrow), .exact(.daggerThrow)],
                 damage: 44, bleedAmount: 10, bleedTurns: 3,
                 flavor: "Two blades from the dark, and a bill that keeps coming."),
        ComboDef(id: "rog_secondSkin", name: "Second Skin", owner: "rogue", source: .armor,
                 required: [.exact(.block), .exact(.heal), .exact(.dodge)],
                 heal: 18, block: 14, dodge: 1, cleanseBleed: true,
                 flavor: "Leather, thread and a step back into the dark."),
        ComboDef(id: "rog_hemorrhage", name: "Hemorrhage", owner: "rogue", source: .weapon,
                 required: [.exact(.daggerThrow), .exact(.swiftSlash), .exact(.swiftSlash)],
                 damage: 46, bleedAmount: 8, bleedTurns: 2, scalesWithBleed: true,
                 flavor: "Open it, widen it, keep it open."),
        ComboDef(id: "rog_deathOfAThousand", name: "Death of a Thousand", owner: "rogue", source: .armor,
                 required: [.exact(.dodge), .exact(.swiftSlash), .exact(.daggerThrow), .exact(.swiftSlash)],
                 damage: 72, staminaNext: 2, bleedAmount: 12, bleedTurns: 3,
                 flavor: "They never see the one that finishes it."),
    ]

    // MARK: - Offer pools

    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Notched Knives", slot: .weapon, rarity: rarity,
                     faces: [.swiftSlash, .swiftSlash, .swiftSlash, .swiftSlash, .daggerThrow, .dodge]), "Flurry · Thousand Cuts"),
                (Die(name: "Padded Jerkin", slot: .armor, rarity: rarity,
                     faces: [.dodge, .dodge, .dodge, .heal, .block, .block]), "Blur · Deflect"),
            ]
        case .uncommon:
            [
                (Die(name: "Balanced Throwers", slot: .weapon, rarity: rarity,
                     faces: [.daggerThrow, .daggerThrow, .daggerThrow, .swiftSlash, .swiftSlash, .dodge]), "Twin Fang · Cutthroat"),
                (Die(name: "Shadowweave Vest", slot: .armor, rarity: rarity,
                     faces: [.dodge, .dodge, .dodge, .dodge, .heal, .heal]), "Untouchable · Blur"),
            ]
        case .rare:
            [
                (Die(name: "Bleeding Edge", slot: .weapon, rarity: rarity,
                     faces: [.daggerThrow, .daggerThrow, .swiftSlash, .swiftSlash, .swiftSlash, .daggerThrow]), "Twin Fang · Opening Cut"),
                (Die(name: "Nightrunner Leathers", slot: .armor, rarity: rarity,
                     faces: [.dodge, .dodge, .dodge, .dodge, .dodge, .heal]), "Untouchable · Shadowstep"),
            ]
        case .signature:
            [
                (Die(name: "Whisper and Fang", slot: .weapon, rarity: rarity,
                     faces: [.dodge, .daggerThrow, .swiftSlash, .dodge, .daggerThrow, .swiftSlash]), "Vanishing Strike — the full sequence"),
                (Die(name: "Assassin's Wrap", slot: .armor, rarity: rarity,
                     faces: [.dodge, .dodge, .dodge, .heal, .heal, .heal]), "Untouchable · Patch Up"),
            ]
        }
    }

    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.swiftSlash, "Flurry · Thousand Cuts"), (.dodge, "Blur · Shadowstep")]
        case .uncommon: [(.daggerThrow, "Twin Fang · Opening Cut"), (.heal, "Patch Up")]
        case .rare: [(.daggerThrow, "Twin Fang · Cutthroat"), (.dodge, "Untouchable · Vanishing Strike")]
        case .signature: [(.swiftSlash, "Vanishing Strike · Thousand Cuts"), (.daggerThrow, "Vanishing Strike")]
        }
    }

    static let imbueName = "Assassin's Coating"
    static let imbueSymbol = "drop.fill"
}
