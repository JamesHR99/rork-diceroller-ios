import Foundation

/// Combos unlocked by god gifts: class-specific blessings, cross-god fusions
/// every class can perform, each god's three-rung devotion ladder, and the
/// signature chains reserved for the deeply devoted. Every divine recipe is
/// built from gifted faces you already own — a Ra-gifted arrow played into
/// another arrow reaches Sunfire Arrow without giving anything up.
enum DivineContent {
    /// Every divine combo available to a class, ignoring devotion locks.
    static func combos(for classID: String) -> [ComboDef] {
        classCombos(classID) + fusions + ladder + signatures
    }

    static func classCombos(_ classID: String) -> [ComboDef] {
        switch classID {
        case "archer": archer
        case "warrior": warrior
        case "rogue": rogue
        default: magician
        }
    }

    /// One god's three-rung ladder, deepest last.
    static func ladder(for deity: Deity) -> [ComboDef] {
        ladder.filter { $0.deity == deity }
    }

    // MARK: - Archer

    static let archer: [ComboDef] = [
        ComboDef(id: "div_arc_sunfire", name: "Sunfire Arrow", owner: "archer", source: .divine,
                 deity: .ra, required: [.gift("ra_fire"), .anyArrow], damage: 36,
                 burnAmount: 8, burnTurns: 3,
                 flavor: "The shaft is alight before it leaves the string."),
        ComboDef(id: "div_arc_judgement", name: "Judgement Arrow", owner: "archer", source: .divine,
                 deity: .anubis, required: [.gift("anubis_weigh"), .anyArrow], damage: 32,
                 scalesWithWounds: true,
                 flavor: "Loosed at whatever is already failing."),
        ComboDef(id: "div_arc_eyeOfHorus", name: "Eye of Horus", owner: "archer", source: .divine,
                 deity: .horus, required: [.gift("horus_eye"), .exact(.arrow3)], damage: 48,
                 pierce: 0.6, guaranteedCrit: true,
                 flavor: "You saw the gap in the plate from four hundred paces."),
        ComboDef(id: "div_arc_catStep", name: "Cat-Step Draw", owner: "archer", source: .divine,
                 deity: .bastet, required: [.gift("bastet_grace"), .anyArrow], damage: 30,
                 dodge: 1, staminaNext: 2,
                 flavor: "Sideways, silent, and already drawn."),
        ComboDef(id: "div_arc_reedbank", name: "Reedbank Shot", owner: "archer", source: .divine,
                 deity: .sobek, required: [.gift("sobek_ambush"), .anyArrow], damage: 40, stagger: 0.3,
                 flavor: "From the water line, where nobody is looking."),
    ]

    // MARK: - Warrior

    static let warrior: [ComboDef] = [
        ComboDef(id: "div_war_sunsteel", name: "Sunsteel Cleave", owner: "warrior", source: .divine,
                 deity: .ra, required: [.gift("ra_heat"), .anySwing], damage: 38,
                 burnAmount: 7, burnTurns: 3,
                 flavor: "The blade comes down still glowing from the forge of the sky."),
        ComboDef(id: "div_war_crocGrip", name: "Crocodile Grip", owner: "warrior", source: .divine,
                 deity: .sobek, required: [.gift("sobek_jaws"), .exact(.overhead)], damage: 44,
                 bleedAmount: 10, bleedTurns: 3,
                 flavor: "Held in place for exactly as long as it takes."),
        ComboDef(id: "div_war_weighing", name: "Weighing of the Heart", owner: "warrior", source: .divine,
                 deity: .anubis, required: [.gift("anubis_weigh"), .exact(.overhead)], damage: 46,
                 scalesWithWounds: true,
                 flavor: "The feather on one pan, the sword on the other."),
        ComboDef(id: "div_war_household", name: "Household Bulwark", owner: "warrior", source: .divine,
                 deity: .bes, required: [.gift("bes_stand"), .exact(.block)], block: 28,
                 reflect: 0.4, carryBlock: true,
                 flavor: "A small ugly god stands in the doorway with you."),
        ComboDef(id: "div_war_descent", name: "Sky-Father's Descent", owner: "warrior", source: .divine,
                 deity: .horus, required: [.gift("horus_talon"), .exact(.overhead)], damage: 50,
                 pierce: 0.7,
                 flavor: "Falling steel with a falcon's aim behind it."),
    ]

    // MARK: - Rogue

    static let rogue: [ComboDef] = [
        ComboDef(id: "div_rog_scorched", name: "Scorched Blade", owner: "rogue", source: .divine,
                 deity: .ra, required: [.gift("ra_fire"), .exact(.swiftSlash)], damage: 30,
                 burnAmount: 7, burnTurns: 3,
                 flavor: "Cauterised on the way in. It still hurts."),
        ComboDef(id: "div_rog_deathRoll", name: "Death Roll", owner: "rogue", source: .divine,
                 deity: .sobek, required: [.gift("sobek_jaws"), .exact(.daggerThrow)], damage: 34,
                 bleedAmount: 13, bleedTurns: 3,
                 flavor: "Take hold and spin. The river taught you this."),
        ComboDef(id: "div_rog_embalmer", name: "Embalmer's Kiss", owner: "rogue", source: .divine,
                 deity: .anubis, required: [.gift("anubis_rot"), .exact(.swiftSlash)], damage: 26,
                 poisonAmount: 11, poisonTurns: 4,
                 flavor: "Natron on the edge. They will keep beautifully."),
        ComboDef(id: "div_rog_nineLives", name: "Nine Lives", owner: "rogue", source: .divine,
                 deity: .bastet, required: [.gift("bastet_land"), .exact(.dodge), .exact(.swiftSlash)],
                 damage: 44, dodge: 2, staminaNext: 2, blocksAll: true,
                 flavor: "Eight left. You will spend them all like this."),
        ComboDef(id: "div_rog_talon", name: "Falcon's Talon", owner: "rogue", source: .divine,
                 deity: .horus, required: [.gift("horus_dive"), .exact(.daggerThrow)], damage: 40,
                 pierce: 0.55, mark: 1.3,
                 flavor: "Thrown from above, where the falcon marked it."),
    ]

    // MARK: - Magician

    static let magician: [ComboDef] = [
        ComboDef(id: "div_mag_solarNova", name: "Solar Nova", owner: "magician", source: .divine,
                 deity: .ra, required: [.gift("ra_fire"), .exact(.runeFire)], damage: 74,
                 burnAmount: 12, burnTurns: 3,
                 flavor: "A second sun, badly behaved, very close."),
        ComboDef(id: "div_mag_nileFlood", name: "Nile Flood", owner: "magician", source: .divine,
                 deity: .sobek, required: [.gift("sobek_flood"), .exact(.runeFrost)], damage: 36,
                 heal: 10, pierce: 0.4, stagger: 0.35,
                 flavor: "Cold water over the banks and into their boots."),
        ComboDef(id: "div_mag_soulTally", name: "Soul Tally", owner: "magician", source: .divine,
                 deity: .anubis, required: [.gift("anubis_toll"), .exact(.runeArcane)], damage: 38,
                 lifesteal: true,
                 flavor: "The ledger balances in your favour."),
        ComboDef(id: "div_mag_amuletWeave", name: "Amulet Weave", owner: "magician", source: .divine,
                 deity: .bes, required: [.gift("bes_amulet"), .exact(.ward)], block: 32,
                 carryBlock: true, cleanseBleed: true,
                 flavor: "Sigil over charm over sigil, all the way down."),
        ComboDef(id: "div_mag_allSeeing", name: "All-Seeing Bolt", owner: "magician", source: .divine,
                 deity: .horus, required: [.gift("horus_dive"), .exact(.runeArcane)], damage: 38,
                 pierce: 0.3, mark: 1.5,
                 flavor: "It finds them wherever they think they are hiding."),
    ]

    // MARK: - Cross-god fusions, open to every class

    static let fusions: [ComboDef] = [
        ComboDef(id: "div_fus_pyre", name: "Pyre Strike", owner: nil, source: .divine,
                 required: [.deity(.ra), .deity(.anubis), .anyStrike], damage: 56,
                 staminaNext: 2, poisonAmount: 9, poisonTurns: 3, burnAmount: 9, burnTurns: 3,
                 flavor: "Flaming poison. Burning and rotting in the same wound."),
        ComboDef(id: "div_fus_boilingNile", name: "Boiling Nile", owner: nil, source: .divine,
                 required: [.deity(.ra), .deity(.sobek)], damage: 40,
                 burnAmount: 7, burnTurns: 2, pierce: 0.55,
                 flavor: "Scalding floodwater. It goes everywhere armour does not."),
        ComboDef(id: "div_fus_duskDawn", name: "Dusk and Dawn", owner: nil, source: .divine,
                 required: [.deity(.ra), .deity(.anubis)], damage: 34,
                 burnAmount: 6, burnTurns: 3, scalesWithWounds: true,
                 flavor: "The sun goes down. The verdict is read."),
        ComboDef(id: "div_fus_hunter", name: "Hunter's Blessing", owner: nil, source: .divine,
                 required: [.deity(.horus), .deity(.bastet)], damage: 24,
                 dodge: 1, staminaNext: 2, mark: 1.45,
                 flavor: "Seen from above, struck from the shadow."),
        ComboDef(id: "div_fus_sacredGuard", name: "Sacred Guard", owner: nil, source: .divine,
                 required: [.deity(.bes), .deity(.bastet)], block: 24, dodge: 1,
                 carryBlock: true, cleanseBleed: true,
                 flavor: "One god at the door, one already on the roof."),
        ComboDef(id: "div_fus_ennead", name: "The Ennead", owner: nil, source: .divine,
                 required: [.anyDivine, .anyDivine, .anyDivine], distinctDeities: true,
                 damage: 92, heal: 20, staminaNext: 3,
                 bleedAmount: 8, bleedTurns: 3, poisonAmount: 8, poisonTurns: 3,
                 burnAmount: 8, burnTurns: 3, pierce: 0.5,
                 flavor: "Three gods lean in at once. The air cannot hold them."),
    ]

    // MARK: - Devotion ladders (rungs at 2, 3 and 5 faces given to one god)

    /// Each god's own chains, opened rung by rung as your devotion climbs. All
    /// are played with the gifted faces themselves, and each scales with how
    /// much devotion stands behind it when it fires.
    static let ladder: [ComboDef] = [
        // Ra — two of the sun, three of the sun, the procession.
        ComboDef(id: "lad_ra_1", name: "Kindling", owner: nil, source: .divine,
                 deity: .ra, devotionRequired: Devotion.passiveTier,
                 required: [.deity(.ra), .deity(.ra)], damage: 18,
                 burnAmount: 5, burnTurns: 2,
                 flavor: "Two sparks, rubbed together. Watch the wick."),
        ComboDef(id: "lad_ra_2", name: "Solar Wind", owner: nil, source: .divine,
                 deity: .ra, devotionRequired: Devotion.deeperTier,
                 required: [.deity(.ra), .deity(.ra), .deity(.ra)], damage: 34,
                 burnAmount: 8, burnTurns: 3,
                 flavor: "The heat spreads on its own now."),
        // Sobek — drown and bleed.
        ComboDef(id: "lad_sobek_1", name: "Rising Water", owner: nil, source: .divine,
                 deity: .sobek, devotionRequired: Devotion.passiveTier,
                 required: [.deity(.sobek), .deity(.sobek)], damage: 20,
                 heal: 5, pierce: 0.3,
                 flavor: "The first step off the bank. The water is already in your boots."),
        ComboDef(id: "lad_sobek_2", name: "The Drowning", owner: nil, source: .divine,
                 deity: .sobek, devotionRequired: Devotion.deeperTier,
                 required: [.deity(.sobek), .deity(.sobek), .deity(.sobek)], damage: 36,
                 heal: 8, bleedAmount: 7, bleedTurns: 3, pierce: 0.4,
                 flavor: "Down, and down, and the current does not ask permission."),
        // Anubis — rot and judgement.
        ComboDef(id: "lad_anubis_1", name: "The First Toll", owner: nil, source: .divine,
                 deity: .anubis, devotionRequired: Devotion.passiveTier,
                 required: [.deity(.anubis), .deity(.anubis)], damage: 18,
                 poisonAmount: 5, poisonTurns: 2,
                 flavor: "A coin for the ferryman, taken from their hide."),
        ComboDef(id: "lad_anubis_2", name: "Weighing of Hearts", owner: nil, source: .divine,
                 deity: .anubis, devotionRequired: Devotion.deeperTier,
                 required: [.deity(.anubis), .deity(.anubis), .deity(.anubis)], damage: 32,
                 poisonAmount: 8, poisonTurns: 3, scalesWithWounds: true,
                 flavor: "Every wound you have given them tips the pan further."),
        // Bes — wall up and shake the room.
        ComboDef(id: "lad_bes_1", name: "The Loud House", owner: nil, source: .divine,
                 deity: .bes, devotionRequired: Devotion.passiveTier,
                 required: [.deity(.bes), .deity(.bes)], block: 20,
                 stagger: 0.15, carryBlock: true,
                 flavor: "Two small gods make one very loud wall."),
        ComboDef(id: "lad_bes_2", name: "Drums in the Dark", owner: nil, source: .divine,
                 deity: .bes, devotionRequired: Devotion.deeperTier,
                 required: [.deity(.bes), .deity(.bes), .deity(.bes)], block: 30,
                 stagger: 0.3, reflect: 0.25, carryBlock: true,
                 flavor: "The rhythm finds everything in the room that can be knocked over."),
        // Horus — mark and never miss.
        ComboDef(id: "lad_horus_1", name: "The Perch", owner: nil, source: .divine,
                 deity: .horus, devotionRequired: Devotion.passiveTier,
                 required: [.deity(.horus), .deity(.horus)], damage: 20,
                 mark: 1.25,
                 flavor: "From up here, the whole fight is one clear picture."),
        ComboDef(id: "lad_horus_2", name: "The Stooping Falcon", owner: nil, source: .divine,
                 deity: .horus, devotionRequired: Devotion.deeperTier,
                 required: [.deity(.horus), .deity(.horus), .deity(.horus)], damage: 38,
                 pierce: 0.4, mark: 1.3,
                 flavor: "Gravity does the rest."),
        // Bastet — cut and vanish.
        ComboDef(id: "lad_bastet_1", name: "Whisker-Twitch", owner: nil, source: .divine,
                 deity: .bastet, devotionRequired: Devotion.passiveTier,
                 required: [.deity(.bastet), .deity(.bastet)], damage: 18,
                 dodge: 1, bleedAmount: 5, bleedTurns: 2,
                 flavor: "She has already left the room by the time it stings."),
        ComboDef(id: "lad_bastet_2", name: "The Prowl", owner: nil, source: .divine,
                 deity: .bastet, devotionRequired: Devotion.deeperTier,
                 required: [.deity(.bastet), .deity(.bastet), .deity(.bastet)], damage: 32,
                 dodge: 2, bleedAmount: 9, bleedTurns: 3,
                 flavor: "Somewhere in the dark, a tail curls. That is the last thing they see."),
    ]

    // MARK: - Devotion signatures (five faces of one god)

    static let signatures: [ComboDef] = [
        ComboDef(id: "div_dev_ra", name: "Procession of Ra", owner: nil, source: .divine,
                 deity: .ra, devotionRequired: Devotion.signatureTier,
                 required: [.deity(.ra), .deity(.ra)], damage: 68, heal: 18, staminaNext: 2,
                 burnAmount: 14, burnTurns: 4,
                 flavor: "Every morning he is born again, furious about it."),
        ComboDef(id: "div_dev_sobek", name: "Jaws of the Nile", owner: nil, source: .divine,
                 deity: .sobek, devotionRequired: Devotion.signatureTier,
                 required: [.deity(.sobek), .deity(.sobek)], damage: 62, staminaNext: 2,
                 bleedAmount: 14, bleedTurns: 3, pierce: 0.5, lifesteal: true,
                 flavor: "The water closes over the whole of them."),
        ComboDef(id: "div_dev_anubis", name: "The Final Verdict", owner: nil, source: .divine,
                 deity: .anubis, devotionRequired: Devotion.signatureTier,
                 required: [.deity(.anubis), .deity(.anubis)], damage: 58, staminaNext: 2,
                 poisonAmount: 12, poisonTurns: 4, scalesWithWounds: true,
                 flavor: "The scales stop moving. That is the whole sentence."),
        ComboDef(id: "div_dev_bes", name: "House of Joy", owner: nil, source: .divine,
                 deity: .bes, devotionRequired: Devotion.signatureTier,
                 required: [.deity(.bes), .deity(.bes)], heal: 30, block: 40, staminaNext: 3,
                 regenAmount: 8, regenTurns: 3, reflect: 0.6,
                 blocksAll: true, carryBlock: true, cleanseBleed: true,
                 flavor: "Drums, dwarves and dancing. Nothing unkind may enter."),
        ComboDef(id: "div_dev_horus", name: "Eye of the Falcon", owner: nil, source: .divine,
                 deity: .horus, devotionRequired: Devotion.signatureTier,
                 required: [.deity(.horus), .deity(.horus)], damage: 66, staminaNext: 2,
                 pierce: 0.85, mark: 1.4, guaranteedCrit: true,
                 flavor: "The sky opens one eye and that is enough."),
        ComboDef(id: "div_dev_bastet", name: "Nine Lives Unbound", owner: nil, source: .divine,
                 deity: .bastet, devotionRequired: Devotion.signatureTier,
                 required: [.deity(.bastet), .deity(.bastet)], damage: 50, dodge: 3, staminaNext: 3,
                 bleedAmount: 12, bleedTurns: 3,
                 flavor: "She spends all nine at once and keeps every one."),
    ]
}
