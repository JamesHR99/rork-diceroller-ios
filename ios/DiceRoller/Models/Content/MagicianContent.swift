import Foundation

/// Magician: wand and robes. Runes mean little alone but fold into spells,
/// with evade stacked where a wall would be.
enum MagicianContent {
    // MARK: - Starting gear

    /// Wand die: a spread of runes plus one Wand Zap that always does something.
    static func wandDie(rarity: Rarity = .common, name: String = "Magic Wand") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.runeFire, .runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap])
    }

    /// Robes die: 2× Heal, 1× Block, 2× Evade, 1× Channel.
    static func armorDie(rarity: Rarity = .common, name: String = "Robes") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.heal, .heal, .block, .evade, .evade, .channel])
    }

    /// Opening staff three: fire-weight — Fireball and Meteor fuel.
    static func emberStaff(rarity: Rarity = .common) -> Die {
        Die(name: "Ember Staff", slot: .weapon, rarity: rarity,
            faces: [.runeFire, .runeFire, .runeFire, .runeArcane, .wandZap, .block])
    }

    /// Opening staff four: frost-weight — Ice Blast and Chill Ward fuel.
    static func frostScepter(rarity: Rarity = .common) -> Die {
        Die(name: "Frost Scepter", slot: .weapon, rarity: rarity,
            faces: [.runeFrost, .runeFrost, .runeFrost, .runeLife, .runeArcane, .wandZap])
    }

    /// Opening armour three: warded plate — Blink fuel behind the hexes.
    static func wardedKilt(rarity: Rarity = .common) -> Die {
        Die(name: "Warded Kilt", slot: .armor, rarity: rarity,
            faces: [.block, .block, .block, .evade, .heal, .channel])
    }

    /// Opening staff five: the varied focus — one of every rune, so Arcane
    /// Storm and Kindle stay reachable from a single die.
    static func runeFocus(rarity: Rarity = .common) -> Die {
        Die(name: "Scribe's Focus", slot: .weapon, rarity: rarity,
            faces: [.runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap, .channel])
    }

    /// Opening armour three: hexed linen — wards and a mend behind the runes.
    static func hexedLinen(rarity: Rarity = .common) -> Die {
        Die(name: "Hexed Linen", slot: .armor, rarity: rarity,
            faces: [.block, .block, .evade, .evade, .heal, .channel])
    }

    static func weapon() -> GearPiece {
        GearPiece(name: "Magic Wand", symbol: "wand.and.stars", slot: .weapon,
                  dice: [wandDie(), wandDie(), emberStaff(), frostScepter(), runeFocus()])
    }

    static func armor() -> GearPiece {
        GearPiece(name: "Robes", symbol: "circle.hexagongrid.fill", slot: .armor,
                  dice: [armorDie(), wardedKilt(), hexedLinen()])
    }

    // MARK: - Combos

    static let combos: [ComboDef] = [
        // Weapon — runes into spells
        ComboDef(id: "mag_fireball", name: "Fireball", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFire), 2)], damage: 26,
                 burnAmount: 4, burnTurns: 2,
                 flavor: "Two flame runes fold into one roaring sphere."),
        ComboDef(id: "mag_iceBlast", name: "Ice Blast", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFrost), 2)], damage: 22, stagger: 0.45,
                 flavor: "The air cracks. Their next swing comes slow."),
        ComboDef(id: "mag_chillWard", name: "Chill Ward", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFrost)), ComboIngredient(.exact(.runeLife))],
                 heal: 10, shield: 14,
                 flavor: "A rime of ice that mends as it holds."),
        ComboDef(id: "mag_lifeSiphon", name: "Life Siphon", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeArcane)), ComboIngredient(.exact(.runeLife))],
                 damage: 20, lifesteal: true,
                 flavor: "What leaves them arrives in you."),
        ComboDef(id: "mag_kindle", name: "Kindle", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.wandZap)), ComboIngredient(.anyRune)],
                 damage: 20,
                 flavor: "A spark thrown into dry tinder."),
        ComboDef(id: "mag_blink", name: "Blink", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.evade)), ComboIngredient(.exact(.block))],
                 shield: 10, evadePercent: 15,
                 flavor: "A half-step sideways out of the world."),

        // Signatures
        ComboDef(id: "mag_meteor", name: "Meteor", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFire), 2), ComboIngredient(.exact(.runeArcane))],
                 damage: 50, burnAmount: 6, burnTurns: 3,
                 flavor: "Something enormous is falling, and it is on fire."),
        ComboDef(id: "mag_arcaneStorm", name: "Arcane Storm", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.anyRune, 3)], distinct: true,
                 damage: 44, burnAmount: 4, burnTurns: 2, stagger: 0.3,
                 flavor: "Three runes, three elements, one storm."),
    ]

    // MARK: - Offer pools

    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Apprentice Wand", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap, .wandZap]), "Kindle · Arcane Storm"),
                (Die(name: "Novice Robes", slot: .armor, rarity: rarity,
                     faces: [.heal, .heal, .block, .evade, .evade, .channel]), "Blink · Chill Ward"),
            ]
        case .uncommon:
            [
                (Die(name: "Emberwood Wand", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFire, .runeFire, .runeArcane, .runeFrost, .wandZap]), "Fireball · Meteor"),
                (Die(name: "Warded Vestments", slot: .armor, rarity: rarity,
                     faces: [.block, .block, .block, .heal, .channel, .evade]), "Blink · Chill Ward"),
            ]
        case .rare:
            [
                (Die(name: "Frostglass Rod", slot: .weapon, rarity: rarity,
                     faces: [.runeFrost, .runeFrost, .runeFrost, .runeLife, .runeArcane, .wandZap]), "Ice Blast · Chill Ward"),
                (Die(name: "Channeler's Mantle", slot: .armor, rarity: rarity,
                     faces: [.channel, .channel, .block, .block, .heal, .heal]), "Kindle · Blink"),
            ]
        case .signature:
            [
                (Die(name: "Stormcaller's Focus", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFrost, .runeLife, .runeArcane, .runeFire, .runeArcane]), "Arcane Storm · Meteor"),
                (Die(name: "Meteoric Sceptre", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFire, .runeArcane, .runeArcane, .runeFire, .wandZap]), "Meteor · Fireball"),
            ]
        }
    }

    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.runeFire, "Fireball · Meteor"), (.block, "Blink")]
        case .uncommon: [(.runeFrost, "Ice Blast · Chill Ward"), (.runeLife, "Life Siphon")]
        case .rare: [(.runeArcane, "Meteor · Arcane Storm · Life Siphon"), (.channel, "Kindle")]
        case .signature: [(.runeArcane, "Meteor · Arcane Storm"), (.runeFire, "Meteor · Fireball")]
        }
    }

    static let imbueName = "Rune-Etcher's Stylus"
    static let imbueSymbol = "hexagon.fill"
}
