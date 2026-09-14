import Foundation

/// Magician: wand and robes. Runes mean little alone but combine into spells.
enum MagicianContent {
    // MARK: - Starting gear

    /// Wand die: a spread of runes plus one Wand Zap that always does something.
    static func wandDie(rarity: Rarity = .common, name: String = "Magic Wand") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.runeFire, .runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap])
    }

    /// Robes die: 2× Heal, 2× Ward, 1× Dodge, 1× Channel.
    static func armorDie(rarity: Rarity = .common, name: String = "Robes") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.heal, .heal, .ward, .ward, .dodge, .channel])
    }

    /// Opening staff three: fire-weight — Fireball, Steam Burst and Meteor fuel.
    static func emberStaff(rarity: Rarity = .common) -> Die {
        Die(name: "Ember Staff", slot: .weapon, rarity: rarity,
            faces: [.runeFire, .runeFire, .runeFire, .runeArcane, .wandZap, .ward])
    }

    /// Opening staff four: frost-weight — Ice Blast and Chill Ward fuel.
    static func frostScepter(rarity: Rarity = .common) -> Die {
        Die(name: "Frost Scepter", slot: .weapon, rarity: rarity,
            faces: [.runeFrost, .runeFrost, .runeFrost, .runeLife, .runeArcane, .wandZap])
    }

    /// Opening armour three: warded plate — blocks behind the hexes.
    static func wardedKilt(rarity: Rarity = .common) -> Die {
        Die(name: "Warded Kilt", slot: .armor, rarity: rarity,
            faces: [.ward, .ward, .block, .block, .heal, .channel])
    }

    static func weapon() -> GearPiece {
        GearPiece(name: "Magic Wand", symbol: "wand.and.stars", slot: .weapon,
                  dice: [wandDie(), wandDie(), emberStaff(), frostScepter()])
    }

    static func armor() -> GearPiece {
        GearPiece(name: "Robes", symbol: "circle.hexagongrid.fill", slot: .armor,
                  dice: [armorDie(), wardedKilt()])
    }

    // MARK: - Combos

    static let combos: [ComboDef] = [
        // Weapon — runes into spells
        ComboDef(id: "mag_kindle", name: "Kindle", owner: "magician", source: .weapon,
                 required: [.exact(.wandZap), .anyRune], damage: 24, staminaNext: 2,
                 flavor: "A spark thrown into dry tinder."),
        ComboDef(id: "mag_fireball", name: "Fireball", owner: "magician", source: .weapon,
                 required: [.exact(.runeFire), .exact(.runeFire)], damage: 34,
                 burnAmount: 6, burnTurns: 3,
                 flavor: "Two flame runes fold into one roaring sphere."),
        ComboDef(id: "mag_iceBlast", name: "Ice Blast", owner: "magician", source: .weapon,
                 required: [.exact(.runeFrost), .exact(.runeFrost)], damage: 28, stagger: 0.45,
                 flavor: "The air cracks. Their next swing comes slow."),
        ComboDef(id: "mag_healingAura", name: "Healing Aura", owner: "magician", source: .weapon,
                 required: [.exact(.runeLife), .exact(.runeLife)], heal: 20,
                 regenAmount: 8, regenTurns: 2,
                 flavor: "Warm light settles on old wounds."),
        ComboDef(id: "mag_steamBurst", name: "Steam Burst", owner: "magician", source: .weapon,
                 required: [.exact(.runeFire), .exact(.runeFrost)], damage: 30, stagger: 0.3,
                 flavor: "Scalding fog. They cannot see you coming."),
        ComboDef(id: "mag_chillWard", name: "Chill Ward", owner: "magician", source: .weapon,
                 required: [.exact(.runeFrost), .exact(.runeLife)], heal: 12, block: 18,
                 flavor: "A rime of ice that mends as it holds."),
        ComboDef(id: "mag_lifeSiphon", name: "Life Siphon", owner: "magician", source: .weapon,
                 required: [.exact(.runeArcane), .exact(.runeLife)], damage: 26, lifesteal: true,
                 flavor: "What leaves them arrives in you."),
        ComboDef(id: "mag_amplify", name: "Amplify", owner: "magician", source: .weapon,
                 required: [.exact(.runeArcane), .anyRune], damage: 30, staminaNext: 2,
                 flavor: "The arcane rune doubles whatever follows it."),
        ComboDef(id: "mag_meteor", name: "Meteor", owner: "magician", source: .weapon,
                 required: [.exact(.runeFire), .exact(.runeFire), .exact(.runeArcane)],
                 damage: 68, burnAmount: 10, burnTurns: 3,
                 flavor: "Something enormous is falling, and it is on fire."),
        ComboDef(id: "mag_arcaneStorm", name: "Arcane Storm", owner: "magician", source: .weapon,
                 required: [.anyRune, .anyRune, .anyRune], distinct: true,
                 damage: 58, staminaNext: 2, burnAmount: 6, burnTurns: 2, stagger: 0.3,
                 flavor: "Three runes, three elements, one storm."),

        // Armour — robes
        ComboDef(id: "mag_mendingWeave", name: "Mending Weave", owner: "magician", source: .armor,
                 required: [.exact(.heal), .exact(.heal)], heal: 14,
                 regenAmount: 8, regenTurns: 3,
                 flavor: "Threads of light, sewing you back together."),
        ComboDef(id: "mag_arcaneShield", name: "Arcane Shield", owner: "magician", source: .armor,
                 required: [.exact(.ward), .exact(.ward)], block: 26,
                 flavor: "A lattice of light, humming under the blows."),
        ComboDef(id: "mag_manaWard", name: "Mana Ward", owner: "magician", source: .armor,
                 required: [.exact(.ward), .exact(.block)], block: 20, stagger: 0.25,
                 flavor: "Steel and sigil, layered."),
        ComboDef(id: "mag_blink", name: "Blink", owner: "magician", source: .armor,
                 required: [.exact(.dodge), .exact(.ward)], block: 8, dodge: 1, staminaNext: 3,
                 flavor: "A half-step sideways out of the world."),
        ComboDef(id: "mag_channelSurge", name: "Channel Surge", owner: "magician", source: .armor,
                 required: [.exact(.channel), .anyRune], damage: 26, staminaNext: 3,
                 flavor: "The rune counts twice when you channel it."),

        // Blended — robes shaping what the wand throws
        ComboDef(id: "mag_wardedFlame", name: "Warded Flame", owner: "magician", source: .armor,
                 required: [.exact(.ward), .exact(.runeFire), .exact(.runeFire)],
                 damage: 48, block: 16, burnAmount: 8, burnTurns: 3,
                 flavor: "Cast from behind glass. Let it roar."),
        ComboDef(id: "mag_glacialWard", name: "Glacial Ward", owner: "magician", source: .armor,
                 required: [.exact(.ward), .exact(.runeFrost), .exact(.runeLife)],
                 heal: 18, block: 24, stagger: 0.35,
                 flavor: "Ice on the lattice, warmth underneath it."),
        ComboDef(id: "mag_channelledBolt", name: "Channelled Bolt", owner: "magician", source: .armor,
                 required: [.exact(.channel), .exact(.runeArcane), .exact(.wandZap)],
                 damage: 52, staminaNext: 3, pierce: 0.5,
                 flavor: "Hold the current until the wand can barely keep it."),
        ComboDef(id: "mag_blinkCast", name: "Blink-Cast", owner: "magician", source: .armor,
                 required: [.exact(.dodge), .exact(.ward), .anyRune],
                 damage: 28, block: 14, dodge: 1, staminaNext: 2,
                 flavor: "Gone, shielded, and casting before you reappear."),
        ComboDef(id: "mag_tempest", name: "Channelled Tempest", owner: "magician", source: .armor,
                 required: [.exact(.channel), .anyRune, .anyRune, .anyRune], distinct: true,
                 damage: 84, staminaNext: 3, burnAmount: 10, burnTurns: 3, stagger: 0.35,
                 flavor: "Hold all three elements at once and let go."),
        ComboDef(id: "mag_mendingCircle", name: "Mending Circle", owner: "magician", source: .armor,
                 required: [.exact(.runeLife), .exact(.heal), .exact(.ward)],
                 heal: 26, block: 18, regenAmount: 8, regenTurns: 3,
                 flavor: "Draw the ring, sit inside it, breathe."),
    ]

    // MARK: - Offer pools

    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Apprentice Wand", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFrost, .runeLife, .runeArcane, .wandZap, .wandZap]), "Kindle · Arcane Storm"),
                (Die(name: "Novice Robes", slot: .armor, rarity: rarity,
                     faces: [.heal, .heal, .ward, .ward, .dodge, .channel]), "Mending Weave · Arcane Shield"),
            ]
        case .uncommon:
            [
                (Die(name: "Emberwood Wand", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFire, .runeFire, .runeArcane, .runeFrost, .wandZap]), "Fireball · Meteor"),
                (Die(name: "Warded Vestments", slot: .armor, rarity: rarity,
                     faces: [.ward, .ward, .ward, .heal, .channel, .dodge]), "Arcane Shield · Mana Ward"),
            ]
        case .rare:
            [
                (Die(name: "Frostglass Rod", slot: .weapon, rarity: rarity,
                     faces: [.runeFrost, .runeFrost, .runeFrost, .runeLife, .runeArcane, .wandZap]), "Ice Blast · Chill Ward"),
                (Die(name: "Channeler's Mantle", slot: .armor, rarity: rarity,
                     faces: [.channel, .channel, .ward, .ward, .heal, .heal]), "Channel Surge · Mending Weave"),
            ]
        case .signature:
            [
                (Die(name: "Stormcaller's Focus", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFrost, .runeLife, .runeArcane, .runeFire, .runeArcane]), "Arcane Storm · Meteor"),
                (Die(name: "Meteoric Sceptre", slot: .weapon, rarity: rarity,
                     faces: [.runeFire, .runeFire, .runeArcane, .runeArcane, .runeFire, .wandZap]), "Meteor · Amplify"),
            ]
        }
    }

    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.runeFire, "Fireball · Steam Burst"), (.ward, "Arcane Shield")]
        case .uncommon: [(.runeFrost, "Ice Blast · Chill Ward"), (.runeLife, "Healing Aura · Life Siphon")]
        case .rare: [(.runeArcane, "Meteor · Amplify · Life Siphon"), (.channel, "Channel Surge")]
        case .signature: [(.runeArcane, "Meteor · Arcane Storm"), (.runeFire, "Meteor · Fireball")]
        }
    }

    static let imbueName = "Rune-Etcher's Stylus"
    static let imbueSymbol = "hexagon.fill"
}
