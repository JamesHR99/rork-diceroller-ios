import Foundation

/// Magician: wand and robes. The Magician owns no shield face, no evade face
/// and no bandage — every point of guard, evasion and healing has to be
/// *spelled* out of runes. That is the whole class: the dice are six neutral
/// syllables and the power is entirely in what you fold them into.
///
/// The collection is uniform: all five wand dice carry one of every rune plus
/// a zap and a channel, and all three robes carry the life-heavy spread, so a
/// draw's shape is a question of how many weapon dice came up rather than
/// which named die did.
enum MagicianContent {
    // MARK: - Starting gear

    /// Wand die: one of every rune, a Wand Zap and a Channel.
    static func wandDie(rarity: Rarity = .common, name: String = "Magic Wand") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap, .channel])
    }

    /// Robes die: 2× Life Rune, 1× Channel, 1× Arcane, 1× Frost, 1× Fire.
    static func armorDie(rarity: Rarity = .common, name: String = "Robes") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.runeLife, .runeLife, .channel, .runeArcane, .runeFrost, .runeFire])
    }

    static func weapon() -> GearPiece {
        GearPiece(name: "Magic Wand", symbol: "wand.and.stars", slot: .weapon,
                  dice: (0..<GameData.ownedWeaponDice).map { _ in wandDie() })
    }

    static func armor() -> GearPiece {
        GearPiece(name: "Robes", symbol: "circle.hexagongrid.fill", slot: .armor,
                  dice: (0..<GameData.ownedArmourDice).map { _ in armorDie() })
    }

    // MARK: - Combos
    //
    // Every pairing of the six faces spells something. Matching runes give the
    // pure elemental effect; mixed runes give the hybrids — wards, mends,
    // evasion and stamina. Nothing here is reachable from a single face, which
    // is what makes the Magician a caster rather than a dice-roller.

    static let combos: [ComboDef] = [

        // MARK: Matched runes — the pure elements

        ComboDef(id: "mag_fireball", name: "Fireball", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFire), 2)], damage: 26,
                 burnAmount: 4, burnTurns: 2,
                 flavor: "Two flame runes fold into one roaring sphere."),
        ComboDef(id: "mag_iceBlast", name: "Ice Blast", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFrost), 2)], damage: 22, stagger: 0.45,
                 flavor: "The air cracks. Their next swing comes slow."),
        ComboDef(id: "mag_arcaneBarrage", name: "Arcane Barrage", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeArcane), 2)], damage: 28, pierce: 0.4,
                 flavor: "Raw structure, thrown. Armour is only a suggestion."),
        ComboDef(id: "mag_chainSpark", name: "Chain Spark", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.wandZap), 2)], damage: 24, stagger: 0.2,
                 flavor: "It jumps twice before it decides where to stop."),
        ComboDef(id: "mag_mendingBloom", name: "Mending Bloom", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeLife), 2)], heal: 22,
                 regenAmount: 4, regenTurns: 2,
                 flavor: "Green light in the shape of a closing wound."),
        ComboDef(id: "mag_deepChannel", name: "Deep Channel", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.channel), 2)], shield: 10, staminaNext: 2,
                 flavor: "Hands still, breath long, the whole night listening."),

        // MARK: Fire hybrids

        ComboDef(id: "mag_scaldingMist", name: "Scalding Mist", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFire)), ComboIngredient(.exact(.runeFrost))],
                 damage: 20, evadePercent: 25,
                 flavor: "Fire into ice makes steam, and steam makes you hard to find."),
        ComboDef(id: "mag_emberPoultice", name: "Ember Poultice", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeFire)), ComboIngredient(.exact(.runeLife))],
                 heal: 16, shield: 8,
                 flavor: "Cauterise, bind, carry on."),
        ComboDef(id: "mag_cinderWard", name: "Cinder Ward", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeFire)), ComboIngredient(.exact(.runeArcane))],
                 shield: 18, reflect: 0.4,
                 flavor: "A shell of hanging coals. Touch it and it answers."),
        ComboDef(id: "mag_ignition", name: "Ignition", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFire)), ComboIngredient(.exact(.wandZap))],
                 damage: 26, burnAmount: 5, burnTurns: 2,
                 flavor: "A spark thrown into dry tinder."),
        ComboDef(id: "mag_stokeTheFlame", name: "Stoke the Flame", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFire)), ComboIngredient(.exact(.channel))],
                 damage: 18, staminaNext: 1, burnAmount: 4, burnTurns: 2,
                 flavor: "Feed it slowly and it feeds you back."),

        // MARK: Frost hybrids

        ComboDef(id: "mag_rimePlate", name: "Rime Plate", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeFrost)), ComboIngredient(.exact(.runeArcane))],
                 shield: 20, stagger: 0.2,
                 flavor: "Ice grown along the lines of a diagram."),
        ComboDef(id: "mag_chillWard", name: "Chill Ward", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeFrost)), ComboIngredient(.exact(.runeLife))],
                 heal: 10, shield: 14,
                 flavor: "A rime of ice that mends as it holds."),
        ComboDef(id: "mag_staticChill", name: "Static Chill", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFrost)), ComboIngredient(.exact(.wandZap))],
                 damage: 22, stagger: 0.35,
                 flavor: "Cold enough to slow the arm, sharp enough to find it."),
        ComboDef(id: "mag_frostgather", name: "Frostgather", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeFrost)), ComboIngredient(.exact(.channel))],
                 shield: 14, staminaNext: 1,
                 flavor: "Draw the heat out of the air and keep it."),

        // MARK: Life and arcane hybrids

        ComboDef(id: "mag_lifeSiphon", name: "Life Siphon", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeArcane)), ComboIngredient(.exact(.runeLife))],
                 damage: 20, lifesteal: true,
                 flavor: "What leaves them arrives in you."),
        ComboDef(id: "mag_quickening", name: "Quickening", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeLife)), ComboIngredient(.exact(.wandZap))],
                 heal: 14, staminaNext: 1,
                 flavor: "A jolt through the heart to remind it of the job."),
        ComboDef(id: "mag_wellspring", name: "Wellspring", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeLife)), ComboIngredient(.exact(.channel))],
                 heal: 18, regenAmount: 3, regenTurns: 2,
                 flavor: "Open the ground and let it come up slowly."),
        ComboDef(id: "mag_arcLash", name: "Arc Lash", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeArcane)), ComboIngredient(.exact(.wandZap))],
                 damage: 26, pierce: 0.3,
                 flavor: "A whip of bare structure, cracked at something's guard."),
        ComboDef(id: "mag_blink", name: "Blink", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeArcane)), ComboIngredient(.exact(.channel))],
                 shield: 10, evadePercent: 30,
                 flavor: "A half-step sideways out of the world."),
        ComboDef(id: "mag_capacitor", name: "Capacitor", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.wandZap)), ComboIngredient(.exact(.channel))],
                 damage: 16, staminaNext: 2,
                 flavor: "Hold the charge until the wand complains, then let go."),

        // MARK: Three-rune spells

        ComboDef(id: "mag_meteor", name: "Meteor", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFire), 2), ComboIngredient(.exact(.runeArcane))],
                 damage: 50, burnAmount: 6, burnTurns: 3,
                 flavor: "Something enormous is falling, and it is on fire."),
        ComboDef(id: "mag_glacier", name: "Glacier", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFrost), 2), ComboIngredient(.exact(.runeArcane))],
                 damage: 46, stagger: 0.5,
                 flavor: "A wall of ice arrives, and keeps arriving."),
        ComboDef(id: "mag_phoenixRite", name: "Phoenix Rite", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFire), 2), ComboIngredient(.exact(.runeLife))],
                 damage: 30, heal: 20, burnAmount: 5, burnTurns: 2,
                 flavor: "Burn it off them and put it back into you."),
        ComboDef(id: "mag_stormcall", name: "Stormcall", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFrost)), ComboIngredient(.exact(.runeArcane)),
                            ComboIngredient(.exact(.wandZap))],
                 damage: 48, pierce: 0.3, stagger: 0.4,
                 flavor: "The whole sky, briefly, is your idea."),
        ComboDef(id: "mag_sanctuary", name: "Sanctuary", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeLife), 2), ComboIngredient(.exact(.runeArcane))],
                 heal: 28, shield: 22,
                 flavor: "A room with no door, for exactly one turn."),
        ComboDef(id: "mag_prismWard", name: "Prism Ward", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeFire)), ComboIngredient(.exact(.runeFrost)),
                            ComboIngredient(.exact(.runeLife))],
                 heal: 14, shield: 24, evadePercent: 20,
                 flavor: "Three elements bent into one shell of light."),
        ComboDef(id: "mag_runicBulwark", name: "Runic Bulwark", owner: "magician", source: .armor,
                 required: [ComboIngredient(.exact(.runeArcane), 2), ComboIngredient(.exact(.channel))],
                 shield: 30, reflect: 0.5,
                 flavor: "Write the wall, then stand behind the writing."),
        ComboDef(id: "mag_arcaneStorm", name: "Arcane Storm", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.anyRune, 3)], distinct: true,
                 damage: 44, burnAmount: 4, burnTurns: 2, stagger: 0.3,
                 flavor: "Three runes, three elements, one storm."),

        // MARK: The full word

        ComboDef(id: "mag_fourfoldWord", name: "The Fourfold Word", owner: "magician", source: .weapon,
                 required: [ComboIngredient(.exact(.runeFire)), ComboIngredient(.exact(.runeFrost)),
                            ComboIngredient(.exact(.runeLife)), ComboIngredient(.exact(.runeArcane))],
                 damage: 64, heal: 18, shield: 18, burnAmount: 5, burnTurns: 3,
                 flavor: "Every rune the wand knows, spoken at once."),
    ]

    // MARK: - Offer pools

    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Apprentice Wand", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap, .wandZap]), "Chain Spark · Arcane Storm"),
                (Die(name: "Novice Robes", slot: .armor, rarity: rarity,
                     faces: [.runeLife, .runeLife, .runeLife, .channel, .runeArcane, .runeFrost]), "Mending Bloom · Sanctuary"),
            ]
        case .uncommon:
            [
                (Die(name: "Emberwood Wand", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFire, .runeFire, .runeArcane, .runeFrost, .wandZap]), "Fireball · Meteor"),
                (Die(name: "Warded Vestments", slot: .armor, rarity: rarity,
                     faces: [.runeArcane, .runeArcane, .channel, .channel, .runeLife, .runeFrost]), "Runic Bulwark · Blink"),
            ]
        case .rare:
            [
                (Die(name: "Frostglass Rod", slot: .weapon, rarity: rarity,
                     faces: [.runeFrost, .runeFrost, .runeFrost, .runeArcane, .wandZap, .runeLife]), "Glacier · Stormcall"),
                (Die(name: "Channeler's Mantle", slot: .armor, rarity: rarity,
                     faces: [.channel, .channel, .runeArcane, .runeArcane, .runeLife, .runeLife]), "Runic Bulwark · Deep Channel"),
            ]
        case .signature:
            [
                (Die(name: "Stormcaller's Focus", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap, .runeArcane]), "The Fourfold Word · Stormcall"),
                (Die(name: "Meteoric Sceptre", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFire, .runeArcane, .runeArcane, .runeFire, .wandZap]), "Meteor · Fireball"),
            ]
        }
    }

    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.runeFire, "Fireball · Meteor"), (.runeLife, "Mending Bloom · Chill Ward")]
        case .uncommon: [(.runeFrost, "Ice Blast · Rime Plate"), (.runeLife, "Sanctuary · Wellspring")]
        case .rare: [(.runeArcane, "Meteor · Runic Bulwark · Blink"), (.channel, "Deep Channel · Blink")]
        case .signature: [(.runeArcane, "The Fourfold Word · Stormcall"), (.runeFire, "Meteor · Phoenix Rite")]
        }
    }

    static let imbueName = "Rune-Etcher's Stylus"
    static let imbueSymbol = "hexagon.fill"
}
