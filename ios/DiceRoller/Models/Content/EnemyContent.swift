import Foundation

/// The servants of Apep, in the order the barque meets them across the night.
enum EnemyContent {
    // MARK: - The opening bout

    /// The run's first fight: a straw effigy lashed to a post on the bank.
    /// It never fights back — no damage, no armour, no scaling — so a fresh
    /// loadout rehearses the drums, the plan bar and its own chains against
    /// something real before the river sends anything with teeth.
    static let trainingDummy = EnemyDef(
        id: "trainingDummy", name: "Straw Effigy", title: "The Practice Bank",
        blurb: "A straw crewman lashed to a post, waiting to take the evening's practice swings.",
        maxHP: 56, symbol: "figure.wave", goldReward: 14,
        moves: [
            EnemyMove(id: "sway", name: "Sways in the Breeze", faces: [.evade], weight: 40),
            EnemyMove(id: "stand", name: "Stands There", faces: [.block], weight: 36),
            EnemyMove(id: "creak", name: "Creaks Quietly", faces: [.heal], weight: 24),
        ]
    )

    // MARK: - Gate of Reeds (hours 1-3)

    static let reedLurker = EnemyDef(
        id: "reedLurker", name: "Reed Lurker", title: "The Shallow Channel",
        blurb: "Something long moves under the reeds, keeping pace with the hull.",
        maxHP: 54, symbol: "leaf.fill", goldReward: 22,
        moves: [
            EnemyMove(id: "snap", name: "Snap from the Reeds", faces: [.swiftSlash], weight: 34, damage: 8),
            EnemyMove(id: "thrash", name: "Thrashing Coils", faces: [.swiftSlash, .swiftSlash], weight: 30,
                      comboName: "Frenzy", damage: 18),
            EnemyMove(id: "submerge", name: "Submerge", faces: [.block], weight: 20, block: 8),
            EnemyMove(id: "drink", name: "Drink the Channel", faces: [.heal], weight: 16, heal: 9),
        ]
    )

    static let marshShade = EnemyDef(
        id: "marshShade", name: "Marsh Shade", title: "The Drowned Crossing",
        blurb: "A crewman who never reached the far bank. He remembers your face.",
        maxHP: 68, symbol: "aqi.medium", goldReward: 26,
        moves: [
            EnemyMove(id: "grasp", name: "Cold Grasp", faces: [.daggerThrow], weight: 34, damage: 12),
            EnemyMove(id: "keening", name: "Keening", faces: [.swiftSlash, .swiftSlash], weight: 30,
                      comboName: "Flurry", damage: 20, bleedAmount: 4, bleedTurns: 2),
            EnemyMove(id: "sink", name: "Sink Away", faces: [.evade], weight: 20, block: 10),
            EnemyMove(id: "feed", name: "Feed on Breath", faces: [.runeLife], weight: 16, damage: 8, heal: 12),
        ]
    )

    static let sandCrawler = EnemyDef(
        id: "sandCrawler", name: "Sand Crawler", title: "The Silted Bend",
        blurb: "It walks on too many legs and its shell is scratched with old spells.",
        maxHP: 82, symbol: "ant.fill", goldReward: 30,
        moves: [
            EnemyMove(id: "pincer", name: "Pincer", faces: [.sideSwing], weight: 30, damage: 14),
            EnemyMove(id: "swarm", name: "Skittering Swarm", faces: [.swiftSlash, .swiftSlash, .swiftSlash], weight: 28,
                      comboName: "Pack Tactics", damage: 27),
            EnemyMove(id: "burrow", name: "Burrow", faces: [.evade, .block], weight: 22, block: 14),
            EnemyMove(id: "sting", name: "Barbed Sting", faces: [.poison], weight: 20, damage: 15, bleedAmount: 5, bleedTurns: 2),
        ]
    )

    static let sekhen = EnemyDef(
        id: "sekhen", name: "Sekhen the Reed Serpent", title: "The Fourth Hour · Gate of Reeds",
        blurb: "It has the barque by the stern and it is pulling you toward the bank.",
        maxHP: 168, symbol: "lizard.fill", goldReward: 70, isBoss: true,
        moves: [
            EnemyMove(id: "haul", name: "Haul the Barque", faces: [.overhead, .overhead], weight: 28,
                      comboName: "Crushing Blow", damage: 40),
            EnemyMove(id: "lash", name: "Reed Lash", faces: [.sideSwing, .sideSwing], weight: 26,
                      comboName: "Wide Sweep", damage: 33, bleedAmount: 6, bleedTurns: 2),
            EnemyMove(id: "scales", name: "Silted Scales", faces: [.block, .block], weight: 22,
                      comboName: "Bulwark", block: 26),
            EnemyMove(id: "swallow", name: "Swallow the Shallows", faces: [.overhead, .heal], weight: 24,
                      damage: 22, heal: 18),
        ]
    )

    // MARK: - Gate of Fire (hours 5-7)

    static let emberWraith = EnemyDef(
        id: "emberWraith", name: "Ember Wraith", title: "The Lake of Flame",
        blurb: "It is the shape a man makes when he burns, and it is still standing.",
        maxHP: 106, symbol: "flame.circle.fill", goldReward: 38,
        moves: [
            EnemyMove(id: "scorch", name: "Scorch", faces: [.runeFire], weight: 30, damage: 18),
            EnemyMove(id: "conflagrate", name: "Conflagrate", faces: [.runeFire, .runeFire], weight: 28,
                      comboName: "Fireball", damage: 36, bleedAmount: 6, bleedTurns: 3),
            EnemyMove(id: "emberWard", name: "Ember Ward", faces: [.block, .block], weight: 22,
                      comboName: "Arcane Shield", block: 22),
            EnemyMove(id: "draw", name: "Draw from the Lake", faces: [.runeLife], weight: 20, damage: 14, heal: 16),
        ]
    )

    static let flamekeeper = EnemyDef(
        id: "flamekeeper", name: "Flamekeeper of the Fourth Hour", title: "The Furnace Hall",
        blurb: "A gatekeeper with a brazier for a head. It has been waiting a long time.",
        maxHP: 132, symbol: "shield.checkered", goldReward: 44,
        moves: [
            EnemyMove(id: "brand", name: "Brand", faces: [.overhead], weight: 28, damage: 22),
            EnemyMove(id: "furnace", name: "Open the Furnace", faces: [.runeFire, .runeFire], weight: 26,
                      comboName: "Fireball", damage: 42, bleedAmount: 7, bleedTurns: 3),
            EnemyMove(id: "wall", name: "Wall of Coals", faces: [.block, .block, .block], weight: 24,
                      comboName: "Fortress", block: 32),
            EnemyMove(id: "shove", name: "Brazier Shove", faces: [.block, .sideSwing], weight: 22,
                      comboName: "Shield Bash", damage: 20, block: 14),
        ]
    )

    static let ashJackal = EnemyDef(
        id: "ashJackal", name: "Ash Jackal", title: "The Cinder Road",
        blurb: "Anubis keeps jackals. This is not one of his.",
        maxHP: 148, symbol: "hare.fill", goldReward: 50,
        moves: [
            EnemyMove(id: "rend", name: "Rend", faces: [.swiftSlash, .swiftSlash], weight: 30,
                      comboName: "Flurry", damage: 32, bleedAmount: 7, bleedTurns: 2),
            EnemyMove(id: "pounce", name: "Cinder Pounce", faces: [.daggerThrow, .daggerThrow], weight: 26,
                      comboName: "Twin Fang", damage: 38),
            EnemyMove(id: "circle", name: "Circle the Hull", faces: [.evade, .evade], weight: 22, block: 24),
            EnemyMove(id: "howl", name: "Ash Howl", faces: [.runeFire, .runeArcane], weight: 22,
                      comboName: "Amplify", damage: 34, heal: 10),
        ]
    )

    static let nehebkau = EnemyDef(
        id: "nehebkau", name: "Nehebkau, the Furnace Coil", title: "The Eighth Hour · Gate of Fire",
        blurb: "It has swallowed the lake and the lake is still burning inside it.",
        maxHP: 262, symbol: "flame.fill", goldReward: 110, isBoss: true,
        moves: [
            EnemyMove(id: "molten", name: "Molten Coil", faces: [.runeFire, .runeFire, .runeFire], weight: 28,
                      comboName: "Dragonfire", damage: 46, bleedAmount: 8, bleedTurns: 3),
            EnemyMove(id: "constrict", name: "Constrict", faces: [.overhead, .sideSwing], weight: 26,
                      comboName: "Cleaving Follow-Through", damage: 42),
            EnemyMove(id: "glow", name: "Scales Glow White", faces: [.block, .block], weight: 22,
                      comboName: "Fortress", block: 32, heal: 14),
            EnemyMove(id: "sear", name: "Sear the Deck", faces: [.runeFire, .sideSwing], weight: 24,
                      damage: 36, bleedAmount: 9, bleedTurns: 2),
        ],
        heatPerTurn: 4
    )

    // MARK: - Gate of Coils (hours 9-11)

    static let devourerSpawn = EnemyDef(
        id: "devourerSpawn", name: "Devourer Spawn", title: "The Lightless Reach",
        blurb: "Ammit's leavings, grown fat on hearts that failed the scales.",
        maxHP: 172, symbol: "hexagon.fill", goldReward: 56,
        moves: [
            EnemyMove(id: "maul", name: "Maul", faces: [.overhead], weight: 28, damage: 28),
            EnemyMove(id: "gorge", name: "Gorge", faces: [.overhead, .heal], weight: 26, damage: 26, heal: 22),
            EnemyMove(id: "bile", name: "Black Bile", faces: [.poison, .poison], weight: 24,
                      comboName: "Venom Coat", damage: 18, bleedAmount: 9, bleedTurns: 3),
            EnemyMove(id: "hide", name: "Thickened Hide", faces: [.block, .block], weight: 22,
                      comboName: "Bulwark", block: 30),
        ]
    )

    static let uncreatedShadow = EnemyDef(
        id: "uncreatedShadow", name: "Shadow of the Uncreated", title: "The Place Before Names",
        blurb: "It is what the world was before Ra opened his eye. It resents the change.",
        maxHP: 190, symbol: "moon.haze.fill", goldReward: 62,
        moves: [
            EnemyMove(id: "unmake", name: "Unmake", faces: [.runeArcane], weight: 28, damage: 30),
            EnemyMove(id: "wail", name: "Wail of the Void", faces: [.runeFrost, .runeArcane], weight: 26,
                      comboName: "Soul Wail", damage: 46, bleedAmount: 9, bleedTurns: 3),
            EnemyMove(id: "fade", name: "Fade from the Light", faces: [.evade, .evade], weight: 24, block: 30),
            EnemyMove(id: "drink", name: "Drink the Disc", faces: [.runeLife], weight: 22, damage: 24, heal: 26),
        ]
    )

    static let hourEater = EnemyDef(
        id: "hourEater", name: "Hour-Eater", title: "The Eleventh Hour",
        blurb: "Every hour it swallows is one the sun will not get back. Dawn is close. So is it.",
        maxHP: 208, symbol: "hourglass", goldReward: 70,
        moves: [
            EnemyMove(id: "devourTime", name: "Devour the Hour", faces: [.overhead, .overhead], weight: 28,
                      comboName: "Crushing Blow", damage: 48),
            EnemyMove(id: "stall", name: "Stall the Barque", faces: [.block, .block], weight: 24,
                      comboName: "Riposte", block: 30),
            EnemyMove(id: "grind", name: "Grind the Sand", faces: [.sideSwing, .sideSwing, .sideSwing], weight: 24,
                      comboName: "Wide Sweep", damage: 42),
            EnemyMove(id: "rewind", name: "Turn the Glass", faces: [.runeFrost, .runeLife], weight: 24,
                      damage: 30, heal: 24),
        ]
    )

    // MARK: - Apep

    static let apep = EnemyDef(
        id: "apep", name: "Apep, the Uncoiled", title: "The Twelfth Hour · Gate of Coils",
        blurb: "It fills the river from bank to bank. Behind you, Ra's disc is guttering.",
        maxHP: 420, symbol: "lizard.fill", goldReward: 0, isBoss: true,
        moves: [],
        stages: [
            EnemyStage(
                id: "apep_head", name: "Apep — The Head That Bites", beginsBelow: 1.0,
                arrival: "Apep uncoils across the whole river.",
                moves: [
                    EnemyMove(id: "bite", name: "The Bite", faces: [.overhead, .overhead], weight: 30,
                              comboName: "Crushing Blow", damage: 50),
                    EnemyMove(id: "venom", name: "Black Venom", faces: [.poison, .poison], weight: 24,
                              comboName: "Venom Coat", damage: 26, bleedAmount: 10, bleedTurns: 3),
                    EnemyMove(id: "scaleWall", name: "Scale Wall", faces: [.block, .block, .block], weight: 22,
                              comboName: "Fortress", block: 38),
                    EnemyMove(id: "lash", name: "Tail Lash", faces: [.sideSwing, .sideSwing], weight: 24,
                              comboName: "Wide Sweep", damage: 42),
                ]
            ),
            EnemyStage(
                id: "apep_coils", name: "Apep — The Coils That Crush", beginsBelow: 0.66,
                arrival: "The head withdraws. The coils come up around the hull.",
                moves: [
                    EnemyMove(id: "crush", name: "Crush the Hull", faces: [.overhead, .sideSwing], weight: 30,
                              comboName: "Cleaving Follow-Through", damage: 56),
                    EnemyMove(id: "blind", name: "Blind the Crew", faces: [.evade, .runeFrost], weight: 26,
                              damage: 34, bleedAmount: 8, bleedTurns: 3),
                    EnemyMove(id: "squeeze", name: "Squeeze", faces: [.overhead, .overhead, .overhead], weight: 22,
                              comboName: "Crushing Blow", damage: 62),
                    EnemyMove(id: "shed", name: "Shed the Wounds", faces: [.runeLife, .block], weight: 22,
                              block: 30, heal: 34),
                ]
            ),
            EnemyStage(
                id: "apep_maw", name: "Apep — The Maw", beginsBelow: 0.33,
                arrival: "It stops fighting you. It turns toward the disc and opens.",
                moves: [
                    EnemyMove(id: "swallow", name: "Swallow the Sun", faces: [.runeFire, .runeFire, .runeFire], weight: 32,
                              comboName: "Dragonfire", damage: 68, bleedAmount: 12, bleedTurns: 3),
                    EnemyMove(id: "unmake", name: "Unmake the Morning", faces: [.runeArcane, .runeArcane], weight: 26,
                              comboName: "Arcane Storm", damage: 58),
                    EnemyMove(id: "thrash", name: "Death Thrash", faces: [.sideSwing, .sideSwing, .sideSwing], weight: 24,
                              comboName: "Wide Sweep", damage: 52),
                    EnemyMove(id: "coilTight", name: "Coil Tight", faces: [.block, .block], weight: 18,
                              comboName: "Bulwark", block: 34),
                ]
            ),
        ],
        heatPerTurn: 2
    )

    // MARK: - Armoured heavies

    /// A silt-crusted scarab colossus of the Gate of Reeds. Slow, heavy, and
    /// its shell has to be cracked open before anything inside can be hurt.
    static let siltColossus = EnemyDef(
        id: "siltColossus", name: "Silt Colossus", title: "The Sunken Ford",
        blurb: "A scarab grown vast on drowned centuries, its shell plated with the riverbed itself.",
        maxHP: 128, symbol: "ant.fill", goldReward: 42,
        moves: [
            EnemyMove(id: "slam", name: "Silt Slam", faces: [.overhead, .overhead], weight: 28,
                      comboName: "Crushing Blow", damage: 24),
            EnemyMove(id: "crust", name: "Crust the Shell", faces: [.block, .block], weight: 26,
                      comboName: "Bulwark", block: 28),
            EnemyMove(id: "sweep", name: "Pincer Sweep", faces: [.sideSwing, .sideSwing], weight: 24,
                      comboName: "Wide Sweep", damage: 22, bleedAmount: 5, bleedTurns: 2),
            EnemyMove(id: "settle", name: "Settle into the Silt", faces: [.block], weight: 22, block: 18),
        ],
        armour: 26
    )

    /// A furnace-armoured effigy of the Gate of Fire. The bronze was cast
    /// around it in worship and the casting never came off.
    static let bronzeEffigy = EnemyDef(
        id: "bronzeEffigy", name: "Bronze Effigy", title: "The Foundry Verge",
        blurb: "Cast in worship of the fire it tends, and the casting never came off.",
        maxHP: 160, symbol: "shield.checkered", goldReward: 52,
        moves: [
            EnemyMove(id: "crush", name: "Brazier Crush", faces: [.overhead, .sideSwing], weight: 26,
                      comboName: "Cleaving Follow-Through", damage: 28),
            EnemyMove(id: "plate", name: "Molten Plate", faces: [.block, .block], weight: 26,
                      comboName: "Fortress", block: 32),
            EnemyMove(id: "burst", name: "Furnace Burst", faces: [.runeFire, .runeFire], weight: 24,
                      comboName: "Fireball", damage: 34, bleedAmount: 6, bleedTurns: 2),
            EnemyMove(id: "stamp", name: "Effigy's Stamp", faces: [.sideSwing], weight: 24, damage: 20),
        ],
        armour: 34
    )

    /// A bone-plated devourer of the Gate of Coils. The plates are the hearts
    /// of the failed, and they do not chip easily.
    static let boneplateDevourer = EnemyDef(
        id: "boneplateDevourer", name: "Boneplate Devourer", title: "The Silent Reach",
        blurb: "It wears the scales of the judged like armour. They have not finished weighing.",
        maxHP: 200, symbol: "hexagon.fill", goldReward: 64,
        moves: [
            EnemyMove(id: "maul", name: "Maul", faces: [.overhead, .overhead], weight: 26,
                      comboName: "Crushing Blow", damage: 36),
            EnemyMove(id: "wall", name: "Bone Wall", faces: [.block, .block], weight: 26,
                      comboName: "Bulwark", block: 34),
            EnemyMove(id: "gnaw", name: "Gnaw", faces: [.swiftSlash, .swiftSlash], weight: 24,
                      comboName: "Flurry", damage: 26, bleedAmount: 8, bleedTurns: 2),
            EnemyMove(id: "gorge", name: "Gorge", faces: [.overhead, .heal], weight: 24, damage: 24, heal: 20),
        ],
        armour: 42
    )

    // MARK: - Lookup

    /// Guardians of hours 1-3, 5-7 and 9-11, in order.
    static let guardians: [EnemyDef] = [
        reedLurker, marshShade, sandCrawler,
        emberWraith, flamekeeper, ashJackal,
        devourerSpawn, uncreatedShadow, hourEater,
    ]

    /// The serpent-lord that closes each gate.
    static let serpentLords: [EnemyDef] = [sekhen, nehebkau, apep]

    /// Rank-and-file servants of a gate, so stages within an hour vary.
    /// The armoured heavies march with them — solo or in packs.
    static func gateRoster(_ gate: Gate) -> [EnemyDef] {
        switch gate {
        case .reeds: [reedLurker, marshShade, sandCrawler, siltColossus]
        case .fire: [emberWraith, flamekeeper, ashJackal, bronzeEffigy]
        case .coils: [devourerSpawn, uncreatedShadow, hourEater, boneplateDevourer]
        }
    }

    /// Whatever waits at the given hour of the night.
    static func enemy(hour: Int, isHerald: Bool) -> EnemyDef {
        let clamped = min(max(hour, 1), Voyage.totalHours)
        let base: EnemyDef
        if clamped % 4 == 0 {
            base = serpentLords[min(clamped / 4 - 1, serpentLords.count - 1)]
        } else {
            let index = min((clamped - 1) - (clamped - 1) / 4, guardians.count - 1)
            base = guardians[index]
        }
        return isHerald ? base.herald() : base
    }
}
