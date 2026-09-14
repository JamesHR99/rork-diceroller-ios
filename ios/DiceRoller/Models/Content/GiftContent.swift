import Foundation

/// One god's gift for one kind of face. A gift is laid on top of a face you
/// already own — the face keeps its kind, its numbers and every chain it fed,
/// and the gift's effect rides on top each time the face plays. The same gift
/// deepens three times on the same face; the third depth is a named final form.
struct GiftDef: Identifiable, Hashable {
    let id: String
    let deity: Deity
    let role: MarkRole
    let name: String
    /// Compact label for tight chips once the face reaches its final form.
    let shortName: String
    let symbol: String
    let flavor: String
    /// The title the face earns when this gift reaches its final form.
    let finalFormName: String
    /// Index 0 = touched, 1 = deepened, 2 = final form.
    let effects: [DivineFaceEffect]

    func effect(_ depth: MarkDepth) -> DivineFaceEffect {
        effects[min(max(depth.rawValue - 1, 0), effects.count - 1)]
    }

    var touched: DivineFaceEffect { effects[0] }
    var finalForm: DivineFaceEffect { effects[effects.count - 1] }
}

/// The seventy-two blessings of the pantheon: six gods, four gifts each for
/// attacks, guards, and mends & support. All four gifts of one role read the
/// same god but pull in different directions — following Ra does not mean the
/// same run twice.
enum GiftContent {
    static let all: [GiftDef] = ra + sobek + anubis + bes + horus + bastet

    static let byID: [String: GiftDef] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func gift(id: String) -> GiftDef? { byID[id] }

    static func gifts(_ deity: Deity) -> [GiftDef] {
        all.filter { $0.deity == deity }
    }

    static func gifts(_ deity: Deity, _ role: MarkRole) -> [GiftDef] {
        all.filter { $0.deity == deity && $0.role == role }
    }

    // MARK: - Ra, the Sun

    private static let ra: [GiftDef] = [
        GiftDef(id: "ra_fire", deity: .ra, role: .attack,
                name: "Fire Arrows", shortName: "FIRE", symbol: "flame.fill",
                flavor: "The shaft is alight before it leaves the string.",
                finalFormName: "Solar Flare",
                effects: [
                    DivineFaceEffect(burnAmount: 3, burnTurns: 2),
                    DivineFaceEffect(burnAmount: 5, burnTurns: 3),
                    DivineFaceEffect(damage: 6, burnAmount: 7, burnTurns: 3, stagger: 0.2),
                ]),
        GiftDef(id: "ra_ray", deity: .ra, role: .attack,
                name: "Piercing Ray", shortName: "RAY", symbol: "sun.max.fill",
                flavor: "Noon goes through everything it is pointed at.",
                finalFormName: "The Sun's Lance",
                effects: [
                    DivineFaceEffect(damage: 4, pierce: 0.3),
                    DivineFaceEffect(damage: 7, pierce: 0.5),
                    DivineFaceEffect(damage: 12, pierce: 0.7),
                ]),
        GiftDef(id: "ra_heat", deity: .ra, role: .attack,
                name: "Sun-Hardened", shortName: "HEAT", symbol: "thermometer.sun.fill",
                flavor: "Strikes land harder on anything already smouldering.",
                finalFormName: "Desert Heat",
                effects: [
                    DivineFaceEffect(damage: 4, scalesWithBurn: true),
                    DivineFaceEffect(damage: 6, scalesWithBurn: true),
                    DivineFaceEffect(damage: 9, burnAmount: 4, burnTurns: 2, scalesWithBurn: true),
                ]),
        GiftDef(id: "ra_flare", deity: .ra, role: .attack,
                name: "Blinding Flare", shortName: "BLIND", symbol: "sun.dust.fill",
                flavor: "They will be seeing spots when they swing.",
                finalFormName: "Noon's Eye",
                effects: [
                    DivineFaceEffect(stagger: 0.15),
                    DivineFaceEffect(stagger: 0.25),
                    DivineFaceEffect(damage: 4, stagger: 0.35),
                ]),

        GiftDef(id: "ra_guard", deity: .ra, role: .defend,
                name: "Scorching Guard", shortName: "SCORCH", symbol: "shield.lefthalf.filled",
                flavor: "Whoever swings at noon swings into noon.",
                finalFormName: "The Long Noon",
                effects: [
                    DivineFaceEffect(block: 4, reflect: 0.15),
                    DivineFaceEffect(block: 6, reflect: 0.25),
                    DivineFaceEffect(block: 9, reflect: 0.35),
                ]),
        GiftDef(id: "ra_mirror", deity: .ra, role: .defend,
                name: "Mirror of Morning", shortName: "MIRROR", symbol: "rectangle.on.rectangle",
                flavor: "The guard is polished bright enough to answer back.",
                finalFormName: "The Mirror of Morning",
                effects: [
                    DivineFaceEffect(block: 3, burnAmount: 2, burnTurns: 2),
                    DivineFaceEffect(block: 5, burnAmount: 3, burnTurns: 2),
                    DivineFaceEffect(block: 7, burnAmount: 4, burnTurns: 3),
                ]),
        GiftDef(id: "ra_vigil", deity: .ra, role: .defend,
                name: "The Bright Vigil", shortName: "VIGIL", symbol: "moon.zzz",
                flavor: "The sun keeps watch even while you sleep.",
                finalFormName: "The Bright Vigil",
                effects: [
                    DivineFaceEffect(block: 4),
                    DivineFaceEffect(block: 6, staminaNext: 1),
                    DivineFaceEffect(block: 8, staminaNext: 1),
                ]),
        GiftDef(id: "ra_veil", deity: .ra, role: .defend,
                name: "Sandstorm Veil", shortName: "VEIL", symbol: "tornado",
                flavor: "Step sideways into the blowing sand and be gone.",
                finalFormName: "Sandstorm Veil",
                effects: [
                    DivineFaceEffect(dodgeGain: 1, burnAmount: 2, burnTurns: 2),
                    DivineFaceEffect(block: 3, dodgeGain: 1, burnAmount: 3, burnTurns: 2),
                    DivineFaceEffect(block: 4, dodgeGain: 2, burnAmount: 4, burnTurns: 3),
                ]),

        GiftDef(id: "ra_gift", deity: .ra, role: .support,
                name: "Gift of the Sun", shortName: "SUNGIFT", symbol: "sun.min.fill",
                flavor: "Healing that cooks while it knits.",
                finalFormName: "Hearth of Noon",
                effects: [
                    DivineFaceEffect(heal: 3, burnAmount: 2, burnTurns: 2),
                    DivineFaceEffect(heal: 5, burnAmount: 3, burnTurns: 2),
                    DivineFaceEffect(heal: 8, burnAmount: 5, burnTurns: 3),
                ]),
        GiftDef(id: "ra_life", deity: .ra, role: .support,
                name: "Warm Blood", shortName: "WARM", symbol: "heart.fill",
                flavor: "Sunlight in the veins, doing the work of sleep.",
                finalFormName: "The Life-Giver",
                effects: [
                    DivineFaceEffect(heal: 4),
                    DivineFaceEffect(heal: 6),
                    DivineFaceEffect(heal: 10),
                ]),
        GiftDef(id: "ra_breath", deity: .ra, role: .support,
                name: "Sunlit Breath", shortName: "BREATH", symbol: "wind",
                flavor: "A long day in the lungs, and stamina to spend.",
                finalFormName: "The Long Day",
                effects: [
                    DivineFaceEffect(staminaNext: 1),
                    DivineFaceEffect(heal: 3, staminaNext: 1),
                    DivineFaceEffect(heal: 4, staminaNext: 2),
                ]),
        GiftDef(id: "ra_pure", deity: .ra, role: .support,
                name: "Dawn's Cleansing", shortName: "CLEANSE", symbol: "sparkles",
                flavor: "First light burns off everything the night left in you.",
                finalFormName: "The Dawn's Cleansing",
                effects: [
                    DivineFaceEffect(heal: 2, cleanse: true),
                    DivineFaceEffect(heal: 4, cleanse: true),
                    DivineFaceEffect(heal: 6, burnAmount: 3, burnTurns: 2, cleanse: true),
                ]),
    ]

    // MARK: - Sobek, the Nile Crocodile

    private static let sobek: [GiftDef] = [
        GiftDef(id: "sobek_flood", deity: .sobek, role: .attack,
                name: "The Flood Beneath", shortName: "FLOOD", symbol: "water.waves",
                flavor: "The strike goes under the shield, not against it.",
                finalFormName: "The Drowning Deep",
                effects: [
                    DivineFaceEffect(heal: 2, pierce: 0.3),
                    DivineFaceEffect(heal: 4, pierce: 0.5),
                    DivineFaceEffect(heal: 6, pierce: 0.8),
                ]),
        GiftDef(id: "sobek_jaws", deity: .sobek, role: .attack,
                name: "River's Teeth", shortName: "TEETH", symbol: "mouth.fill",
                flavor: "It does not let go. That is the whole trick.",
                finalFormName: "Crocodile Jaws",
                effects: [
                    DivineFaceEffect(bleedAmount: 3, bleedTurns: 2),
                    DivineFaceEffect(bleedAmount: 5, bleedTurns: 3),
                    DivineFaceEffect(damage: 4, bleedAmount: 8, bleedTurns: 3),
                ]),
        GiftDef(id: "sobek_hunger", deity: .sobek, role: .attack,
                name: "The River's Hunger", shortName: "HUNGER", symbol: "arrow.down.left.and.arrow.up.right",
                flavor: "What the river takes, the river keeps. You are the river.",
                finalFormName: "Jaws That Never Let Go",
                effects: [
                    DivineFaceEffect(damage: 3, lifesteal: true),
                    DivineFaceEffect(damage: 5, lifesteal: true),
                    DivineFaceEffect(damage: 8, pierce: 0.3, lifesteal: true),
                ]),
        GiftDef(id: "sobek_ambush", deity: .sobek, role: .attack,
                name: "Ambush Current", shortName: "AMBUSH", symbol: "figure.open.water.swim",
                flavor: "Still water, then no water at all.",
                finalFormName: "The Water Line",
                effects: [
                    DivineFaceEffect(damage: 3, stagger: 0.15),
                    DivineFaceEffect(damage: 5, stagger: 0.25),
                    DivineFaceEffect(damage: 8, stagger: 0.35),
                ]),

        GiftDef(id: "sobek_hide", deity: .sobek, role: .defend,
                name: "Scaled Hide", shortName: "HIDE", symbol: "square.grid.3x3.fill",
                flavor: "Old scars grow back thicker than skin.",
                finalFormName: "Scaled Hide",
                effects: [
                    DivineFaceEffect(regenAmount: 3, regenTurns: 2),
                    DivineFaceEffect(regenAmount: 4, regenTurns: 3),
                    DivineFaceEffect(block: 6, regenAmount: 5, regenTurns: 3),
                ]),
        GiftDef(id: "sobek_scars", deity: .sobek, role: .defend,
                name: "Thick Blood", shortName: "THICK", symbol: "drop.fill",
                flavor: "Cold water heals what cold water wounds.",
                finalFormName: "Old Scars",
                effects: [
                    DivineFaceEffect(block: 4),
                    DivineFaceEffect(block: 6, regenAmount: 2, regenTurns: 2),
                    DivineFaceEffect(block: 9, regenAmount: 3, regenTurns: 3),
                ]),
        GiftDef(id: "sobek_bank", deity: .sobek, role: .defend,
                name: "Mud Wall", shortName: "MUD", symbol: "rectangle.fill",
                flavor: "The riverbank has stood ten thousand floods.",
                finalFormName: "The Bank Holds",
                effects: [
                    DivineFaceEffect(block: 5, reflect: 0.1),
                    DivineFaceEffect(block: 7, reflect: 0.15),
                    DivineFaceEffect(block: 10, reflect: 0.25),
                ]),
        GiftDef(id: "sobek_carry", deity: .sobek, role: .defend,
                name: "Carry the Current", shortName: "CARRY", symbol: "arrow.right",
                flavor: "The guard does not stop at the turn of the tide.",
                finalFormName: "River-Borne",
                effects: [
                    DivineFaceEffect(block: 4, carryBlock: true),
                    DivineFaceEffect(block: 6, carryBlock: true),
                    DivineFaceEffect(block: 9, reflect: 0.15, carryBlock: true),
                ]),

        GiftDef(id: "sobek_river", deity: .sobek, role: .support,
                name: "The River's Gift", shortName: "RIVER", symbol: "drop.circle.fill",
                flavor: "What the flood takes, the low water returns.",
                finalFormName: "The Nile Gives",
                effects: [
                    DivineFaceEffect(heal: 4),
                    DivineFaceEffect(heal: 6),
                    DivineFaceEffect(heal: 9),
                ]),
        GiftDef(id: "sobek_due", deity: .sobek, role: .support,
                name: "The Bank's Due", shortName: "DUE", symbol: "banknote",
                flavor: "A little armour layered on the healing.",
                finalFormName: "The Ferryman's Cut",
                effects: [
                    DivineFaceEffect(heal: 3, block: 2),
                    DivineFaceEffect(heal: 5, block: 3),
                    DivineFaceEffect(heal: 8, block: 5),
                ]),
        GiftDef(id: "sobek_cool", deity: .sobek, role: .support,
                name: "Cold Current", shortName: "COOL", symbol: "snowflake",
                flavor: "Slip under and let the river carry the blood away.",
                finalFormName: "The Cold Current",
                effects: [
                    DivineFaceEffect(heal: 3),
                    DivineFaceEffect(heal: 5, cleanse: true),
                    DivineFaceEffect(heal: 7, regenAmount: 2, regenTurns: 2, cleanse: true),
                ]),
        GiftDef(id: "sobek_surge", deity: .sobek, role: .support,
                name: "Nile Surge", shortName: "SURGE", symbol: "waveform.path",
                flavor: "The flood rises and so do you.",
                finalFormName: "The Flood Rises",
                effects: [
                    DivineFaceEffect(block: 2, staminaNext: 1),
                    DivineFaceEffect(heal: 3, block: 2, staminaNext: 1),
                    DivineFaceEffect(heal: 4, staminaNext: 2),
                ]),
    ]

    // MARK: - Anubis, Judge of the Dead

    private static let anubis: [GiftDef] = [
        GiftDef(id: "anubis_rot", deity: .anubis, role: .attack,
                name: "Grave Rot", shortName: "ROT", symbol: "bandage.fill",
                flavor: "Linen, natron, and a long patient wait.",
                finalFormName: "The Slow Rot",
                effects: [
                    DivineFaceEffect(poisonAmount: 3, poisonTurns: 2),
                    DivineFaceEffect(poisonAmount: 5, poisonTurns: 3),
                    DivineFaceEffect(damage: 3, poisonAmount: 7, poisonTurns: 3),
                ]),
        GiftDef(id: "anubis_weigh", deity: .anubis, role: .attack,
                name: "The Heart Weighed", shortName: "WEIGH", symbol: "scalemass",
                flavor: "Struck at whatever is already failing.",
                finalFormName: "The Final Scales",
                effects: [
                    DivineFaceEffect(damage: 4, scalesWithWounds: true),
                    DivineFaceEffect(damage: 6, scalesWithWounds: true),
                    DivineFaceEffect(damage: 10, poisonAmount: 3, poisonTurns: 2, scalesWithWounds: true),
                ]),
        GiftDef(id: "anubis_toll", deity: .anubis, role: .attack,
                name: "Soul Toll", shortName: "TOLL", symbol: "moon.stars.fill",
                flavor: "The ferryman is paid in what leaves them.",
                finalFormName: "The Ferryman's Due",
                effects: [
                    DivineFaceEffect(damage: 3, lifesteal: true),
                    DivineFaceEffect(damage: 5, lifesteal: true),
                    DivineFaceEffect(damage: 7, poisonAmount: 2, poisonTurns: 2, lifesteal: true),
                ]),
        GiftDef(id: "anubis_judge", deity: .anubis, role: .attack,
                name: "Judgement Struck", shortName: "JUDGE", symbol: "gavel",
                flavor: "Read the wounds first. Then add to them.",
                finalFormName: "Judgement Read",
                effects: [
                    DivineFaceEffect(poisonAmount: 2, scalesWithWounds: true),
                    DivineFaceEffect(poisonAmount: 4, scalesWithWounds: true),
                    DivineFaceEffect(damage: 5, poisonAmount: 6, poisonTurns: 2, scalesWithWounds: true),
                ]),

        GiftDef(id: "anubis_wrap", deity: .anubis, role: .defend,
                name: "Grave Wraps", shortName: "WRAP", symbol: "circle.grid.3x3",
                flavor: "Whatever touches the linen comes away rotting.",
                finalFormName: "Bandage and Natron",
                effects: [
                    DivineFaceEffect(block: 4, poisonAmount: 2, poisonTurns: 2),
                    DivineFaceEffect(block: 6, poisonAmount: 3, poisonTurns: 2),
                    DivineFaceEffect(block: 9, poisonAmount: 4, poisonTurns: 3),
                ]),
        GiftDef(id: "anubis_gate", deity: .anubis, role: .defend,
                name: "The Toll Gate", shortName: "GATE", symbol: "door.left.hand.open",
                flavor: "Every blade that crosses pays something on the way through.",
                finalFormName: "The Toll Gate",
                effects: [
                    DivineFaceEffect(heal: 2, block: 4),
                    DivineFaceEffect(heal: 3, block: 6),
                    DivineFaceEffect(heal: 5, block: 9),
                ]),
        GiftDef(id: "anubis_still", deity: .anubis, role: .defend,
                name: "The Quiet Scales", shortName: "QUIET", symbol: "scalemass.fill",
                flavor: "Step aside, and let the verdict land elsewhere.",
                finalFormName: "The Quiet Scales",
                effects: [
                    DivineFaceEffect(dodgeGain: 1, poisonAmount: 2, poisonTurns: 2),
                    DivineFaceEffect(block: 3, dodgeGain: 1, poisonAmount: 3, poisonTurns: 2),
                    DivineFaceEffect(block: 4, dodgeGain: 2, poisonAmount: 4, poisonTurns: 3),
                ]),
        GiftDef(id: "anubis_watch", deity: .anubis, role: .defend,
                name: "Jackal's Watch", shortName: "WATCH", symbol: "eye",
                flavor: "The watcher at the gate grows fat on what passes.",
                finalFormName: "The Watcher at the Gate",
                effects: [
                    DivineFaceEffect(block: 4, regenAmount: 2, regenTurns: 2),
                    DivineFaceEffect(block: 6, regenAmount: 3, regenTurns: 2),
                    DivineFaceEffect(block: 8, regenAmount: 4, regenTurns: 3),
                ]),

        GiftDef(id: "anubis_mercy", deity: .anubis, role: .support,
                name: "Mercy of the Scales", shortName: "MERCY", symbol: "heart.circle",
                flavor: "Even the judge forgives, once, briefly.",
                finalFormName: "Mercy of the Scales",
                effects: [
                    DivineFaceEffect(heal: 3),
                    DivineFaceEffect(heal: 5, cleanse: true),
                    DivineFaceEffect(heal: 8, cleanse: true),
                ]),
        GiftDef(id: "anubis_care", deity: .anubis, role: .support,
                name: "Embalmer's Care", shortName: "CARE", symbol: "cross.case.fill",
                flavor: "No one keeps a body longer than she does.",
                finalFormName: "The Long Embalming",
                effects: [
                    DivineFaceEffect(heal: 3, regenAmount: 2, regenTurns: 2),
                    DivineFaceEffect(heal: 5, regenAmount: 3, regenTurns: 2),
                    DivineFaceEffect(heal: 7, regenAmount: 4, regenTurns: 3),
                ]),
        GiftDef(id: "anubis_book", deity: .anubis, role: .support,
                name: "Book of Breath", shortName: "BOOK", symbol: "book.fill",
                flavor: "The dead taught him how breath returns. He teaches you.",
                finalFormName: "The Book of Breath",
                effects: [
                    DivineFaceEffect(staminaNext: 1),
                    DivineFaceEffect(heal: 3, staminaNext: 1),
                    DivineFaceEffect(heal: 3, staminaNext: 2),
                ]),
        GiftDef(id: "anubis_sin", deity: .anubis, role: .support,
                name: "Weight of Sins", shortName: "SIN", symbol: "scale.3d",
                flavor: "Heal, and lay your hurts on the other pan.",
                finalFormName: "Sins Made Heavy",
                effects: [
                    DivineFaceEffect(heal: 2, poisonAmount: 3, poisonTurns: 2),
                    DivineFaceEffect(heal: 3, poisonAmount: 5, poisonTurns: 3),
                    DivineFaceEffect(heal: 5, poisonAmount: 7, poisonTurns: 3),
                ]),
    ]

    // MARK: - Bes, Guardian of the Household

    private static let bes: [GiftDef] = [
        GiftDef(id: "bes_laugh", deity: .bes, role: .attack,
                name: "The Roaring Laugh", shortName: "LAUGH", symbol: "face.smiling.inverse",
                flavor: "Ugly enough to turn a curse around.",
                finalFormName: "The Roaring Laugh",
                effects: [
                    DivineFaceEffect(stagger: 0.15),
                    DivineFaceEffect(stagger: 0.25),
                    DivineFaceEffect(damage: 4, stagger: 0.35),
                ]),
        GiftDef(id: "bes_drum", deity: .bes, role: .attack,
                name: "Drumbeat", shortName: "DRUM", symbol: "drum.fill",
                flavor: "Every blow lands on the beat.",
                finalFormName: "The War Drum",
                effects: [
                    DivineFaceEffect(damage: 4, stagger: 0.1),
                    DivineFaceEffect(damage: 6, stagger: 0.15),
                    DivineFaceEffect(damage: 9, stagger: 0.25),
                ]),
        GiftDef(id: "bes_grin", deity: .bes, role: .attack,
                name: "The Warding Grin", shortName: "GRIN", symbol: "face.dashed",
                flavor: "Laugh in their face and your own strikes find their mark.",
                finalFormName: "The Warding Grin",
                effects: [
                    DivineFaceEffect(damage: 3, critBoost: 0.03),
                    DivineFaceEffect(damage: 5, critBoost: 0.05),
                    DivineFaceEffect(damage: 8, critBoost: 0.08),
                ]),
        GiftDef(id: "bes_door", deity: .bes, role: .attack,
                name: "Door Slam", shortName: "SLAM", symbol: "door.left.hand.closed",
                flavor: "Nothing gets past a slammed door.",
                finalFormName: "No Entry",
                effects: [
                    DivineFaceEffect(damage: 3, stagger: 0.2),
                    DivineFaceEffect(damage: 5, stagger: 0.3),
                    DivineFaceEffect(damage: 8, stagger: 0.4),
                ]),

        GiftDef(id: "bes_stand", deity: .bes, role: .defend,
                name: "Stand Behind Me", shortName: "STAND", symbol: "figure.arms.open",
                flavor: "A small god making a very large door of himself.",
                finalFormName: "Stand Behind Me",
                effects: [
                    DivineFaceEffect(block: 5, carryBlock: true),
                    DivineFaceEffect(block: 8, carryBlock: true),
                    DivineFaceEffect(block: 12, carryBlock: true),
                ]),
        GiftDef(id: "bes_amulet", deity: .bes, role: .defend,
                name: "Amulet Charm", shortName: "AMULET", symbol: "seal.fill",
                flavor: "Worn smooth by a hundred frightened thumbs.",
                finalFormName: "The Amulet Turns It",
                effects: [
                    DivineFaceEffect(block: 4, reflect: 0.2),
                    DivineFaceEffect(block: 6, reflect: 0.3),
                    DivineFaceEffect(block: 9, reflect: 0.4),
                ]),
        GiftDef(id: "bes_wall", deity: .bes, role: .defend,
                name: "Household Wall", shortName: "WALL", symbol: "house.and.flag.fill",
                flavor: "Clay, timber, and a god leaning on it.",
                finalFormName: "The Household Wall",
                effects: [
                    DivineFaceEffect(block: 6),
                    DivineFaceEffect(block: 9),
                    DivineFaceEffect(block: 13),
                ]),
        GiftDef(id: "bes_dance", deity: .bes, role: .defend,
                name: "The Leaping Step", shortName: "LEAP", symbol: "figure.dance",
                flavor: "He dances. It looks ridiculous. It works.",
                finalFormName: "The Leaping Step",
                effects: [
                    DivineFaceEffect(block: 3, dodgeGain: 1),
                    DivineFaceEffect(block: 5, dodgeGain: 1),
                    DivineFaceEffect(block: 7, dodgeGain: 2, stagger: 0.15),
                ]),

        GiftDef(id: "bes_hearth", deity: .bes, role: .support,
                name: "Hearth-Warmth", shortName: "HEARTH", symbol: "flame.circle.fill",
                flavor: "Somewhere, a fire is kept lit for you.",
                finalFormName: "Hearth-Warmth",
                effects: [
                    DivineFaceEffect(heal: 3, block: 3),
                    DivineFaceEffect(heal: 5, block: 4),
                    DivineFaceEffect(heal: 8, block: 6),
                ]),
        GiftDef(id: "bes_feast", deity: .bes, role: .support,
                name: "Beer and Bread", shortName: "FEAST", symbol: "fork.knife",
                flavor: "The household god takes feeding seriously.",
                finalFormName: "The Feast",
                effects: [
                    DivineFaceEffect(heal: 4),
                    DivineFaceEffect(heal: 6),
                    DivineFaceEffect(heal: 10),
                ]),
        GiftDef(id: "bes_joy", deity: .bes, role: .support,
                name: "The Laugh Itself", shortName: "JOY", symbol: "music.note",
                flavor: "Drums, dwarves and dancing: stamina comes back.",
                finalFormName: "The House of Joy",
                effects: [
                    DivineFaceEffect(heal: 2, staminaNext: 1),
                    DivineFaceEffect(heal: 4, staminaNext: 1),
                    DivineFaceEffect(heal: 5, staminaNext: 2),
                ]),
        GiftDef(id: "bes_ward", deity: .bes, role: .support,
                name: "The Loud Ward", shortName: "WARD", symbol: "speaker.wave.3.fill",
                flavor: "Sung loud enough to drown out anything clinging to you.",
                finalFormName: "The Loud Ward",
                effects: [
                    DivineFaceEffect(block: 3, cleanse: true),
                    DivineFaceEffect(block: 5, cleanse: true),
                    DivineFaceEffect(heal: 3, block: 7, cleanse: true),
                ]),
    ]

    // MARK: - Horus, the Falcon

    private static let horus: [GiftDef] = [
        GiftDef(id: "horus_dive", deity: .horus, role: .attack,
                name: "The Hunting Dive", shortName: "DIVE", symbol: "arrowshape.down.fill",
                flavor: "A stoop from the sun. Nothing survives being seen.",
                finalFormName: "The Hunting Dive",
                effects: [
                    DivineFaceEffect(mark: 1.15, critBoost: 0.02),
                    DivineFaceEffect(mark: 1.25, critBoost: 0.04),
                    DivineFaceEffect(damage: 3, mark: 1.35, critBoost: 0.06),
                ]),
        GiftDef(id: "horus_eye", deity: .horus, role: .attack,
                name: "Falcon's Eye", shortName: "EYE", symbol: "eye.circle.fill",
                flavor: "From very high up, everything holds still.",
                finalFormName: "The Eye That Never Blinks",
                effects: [
                    DivineFaceEffect(critBoost: 0.04),
                    DivineFaceEffect(damage: 2, critBoost: 0.06),
                    DivineFaceEffect(damage: 3, critBoost: 0.1),
                ]),
        GiftDef(id: "horus_talon", deity: .horus, role: .attack,
                name: "Sky Talon", shortName: "TALON", symbol: "bird.fill",
                flavor: "Straight through the plate like it was linen.",
                finalFormName: "Sky Talon",
                effects: [
                    DivineFaceEffect(damage: 4, pierce: 0.3),
                    DivineFaceEffect(damage: 6, pierce: 0.5),
                    DivineFaceEffect(damage: 10, pierce: 0.7),
                ]),
        GiftDef(id: "horus_high", deity: .horus, role: .attack,
                name: "High Ground", shortName: "HIGH", symbol: "mountain.2.fill",
                flavor: "Strike from where they cannot reach you.",
                finalFormName: "Above the Storm",
                effects: [
                    DivineFaceEffect(dodgeGain: 1),
                    DivineFaceEffect(damage: 3, dodgeGain: 1),
                    DivineFaceEffect(damage: 5, dodgeGain: 2),
                ]),

        GiftDef(id: "horus_wedjat", deity: .horus, role: .defend,
                name: "The Wedjat Eye", shortName: "WEDJAT", symbol: "circle.hexagonpath.fill",
                flavor: "The eye watches both ways.",
                finalFormName: "The Wedjat Eye",
                effects: [
                    DivineFaceEffect(dodgeGain: 1),
                    DivineFaceEffect(block: 3, dodgeGain: 1),
                    DivineFaceEffect(block: 5, dodgeGain: 2),
                ]),
        GiftDef(id: "horus_wing", deity: .horus, role: .defend,
                name: "Watchful Wing", shortName: "WING", symbol: "bird",
                flavor: "One wing over you and the blow goes wide.",
                finalFormName: "The Outstretched Wing",
                effects: [
                    DivineFaceEffect(block: 4, dodgeGain: 1),
                    DivineFaceEffect(block: 6, dodgeGain: 1),
                    DivineFaceEffect(block: 9, dodgeGain: 2),
                ]),
        GiftDef(id: "horus_sight", deity: .horus, role: .defend,
                name: "Keen Sight", shortName: "KEEN", symbol: "eye.fill",
                flavor: "See the swing coming and it lands softer.",
                finalFormName: "The Far Horizon",
                effects: [
                    DivineFaceEffect(block: 3, critBoost: 0.03),
                    DivineFaceEffect(block: 5, critBoost: 0.05),
                    DivineFaceEffect(block: 7, critBoost: 0.08),
                ]),
        GiftDef(id: "horus_storm", deity: .horus, role: .defend,
                name: "Storm Cover", shortName: "STORM", symbol: "cloud.hail.fill",
                flavor: "The storm's shadow staggers what steps into it.",
                finalFormName: "The Storm's Shadow",
                effects: [
                    DivineFaceEffect(block: 5, stagger: 0.1),
                    DivineFaceEffect(block: 7, stagger: 0.15),
                    DivineFaceEffect(block: 10, stagger: 0.25),
                ]),

        GiftDef(id: "horus_clear", deity: .horus, role: .support,
                name: "Clear Skies", shortName: "CLEAR", symbol: "sun.max",
                flavor: "High, calm air. Plenty of room to breathe.",
                finalFormName: "Clear Skies",
                effects: [
                    DivineFaceEffect(staminaNext: 1),
                    DivineFaceEffect(staminaNext: 1, critBoost: 0.03),
                    DivineFaceEffect(staminaNext: 2, critBoost: 0.05),
                ]),
        GiftDef(id: "horus_sharp", deity: .horus, role: .support,
                name: "The Sharp Eye", shortName: "SHARP", symbol: "scope",
                flavor: "Rest is also aiming.",
                finalFormName: "The Sharp Eye",
                effects: [
                    DivineFaceEffect(heal: 2, critBoost: 0.03),
                    DivineFaceEffect(heal: 4, critBoost: 0.05),
                    DivineFaceEffect(heal: 6, critBoost: 0.08),
                ]),
        GiftDef(id: "horus_msg", deity: .horus, role: .support,
                name: "Swift Messenger", shortName: "SWIFT", symbol: "paperplane.fill",
                flavor: "The winged one is back before the prayer is finished.",
                finalFormName: "The Swift Messenger",
                effects: [
                    DivineFaceEffect(dodgeGain: 1, staminaNext: 1),
                    DivineFaceEffect(heal: 2, dodgeGain: 1, staminaNext: 1),
                    DivineFaceEffect(dodgeGain: 2, staminaNext: 2),
                ]),
        GiftDef(id: "horus_dawn", deity: .horus, role: .support,
                name: "First Light", shortName: "FIRST", symbol: "sunrise.fill",
                flavor: "The first light of morning washes everything clean.",
                finalFormName: "The First Light",
                effects: [
                    DivineFaceEffect(heal: 3, cleanse: true),
                    DivineFaceEffect(heal: 5, critBoost: 0.03, cleanse: true),
                    DivineFaceEffect(heal: 7, critBoost: 0.05, cleanse: true),
                ]),
    ]

    // MARK: - Bastet, the Cat

    private static let bastet: [GiftDef] = [
        GiftDef(id: "bastet_claw", deity: .bastet, role: .attack,
                name: "Nine-Fold Claw", shortName: "CLAW", symbol: "pawprint.fill",
                flavor: "Nine lines, all of them weeping.",
                finalFormName: "Nine-Fold Claw",
                effects: [
                    DivineFaceEffect(bleedAmount: 3, bleedTurns: 2),
                    DivineFaceEffect(bleedAmount: 5, bleedTurns: 3),
                    DivineFaceEffect(bleedAmount: 8, bleedTurns: 3, stagger: 0.15),
                ]),
        GiftDef(id: "bastet_grace", deity: .bastet, role: .attack,
                name: "Cat's Grace", shortName: "GRACE", symbol: "cat.fill",
                flavor: "You were never off balance. You meant that.",
                finalFormName: "Landed on Her Feet",
                effects: [
                    DivineFaceEffect(dodgeGain: 1),
                    DivineFaceEffect(damage: 3, dodgeGain: 1),
                    DivineFaceEffect(damage: 5, dodgeGain: 2),
                ]),
        GiftDef(id: "bastet_pounce", deity: .bastet, role: .attack,
                name: "The Pounce", shortName: "POUNCE", symbol: "arrow.down.circle",
                flavor: "From the shelf, onto the table, into the neck.",
                finalFormName: "The Pounce",
                effects: [
                    DivineFaceEffect(damage: 4, bleedAmount: 2, bleedTurns: 2),
                    DivineFaceEffect(damage: 6, bleedAmount: 3, bleedTurns: 2),
                    DivineFaceEffect(damage: 9, bleedAmount: 4, bleedTurns: 3),
                ]),
        GiftDef(id: "bastet_silent", deity: .bastet, role: .attack,
                name: "Silent Pads", shortName: "SILENT", symbol: "pawprint",
                flavor: "You never hear the second cut.",
                finalFormName: "The Silent Kill",
                effects: [
                    DivineFaceEffect(bleedAmount: 2, bleedTurns: 2, critBoost: 0.03),
                    DivineFaceEffect(bleedAmount: 3, bleedTurns: 2, critBoost: 0.05),
                    DivineFaceEffect(damage: 3, bleedAmount: 4, bleedTurns: 2, critBoost: 0.08),
                ]),

        GiftDef(id: "bastet_land", deity: .bastet, role: .defend,
                name: "Soft Landing", shortName: "LAND", symbol: "arrow.down.to.line",
                flavor: "Dropped from any height, she lands on her feet.",
                finalFormName: "Nine Lives",
                effects: [
                    DivineFaceEffect(dodgeGain: 1),
                    DivineFaceEffect(block: 2, dodgeGain: 1),
                    DivineFaceEffect(block: 4, dodgeGain: 2),
                ]),
        GiftDef(id: "bastet_puff", deity: .bastet, role: .defend,
                name: "The Puffed Tail", shortName: "PUFF", symbol: "exclamationmark.triangle.fill",
                flavor: "Twice the size, all of it attitude.",
                finalFormName: "The Puffed Tail",
                effects: [
                    DivineFaceEffect(block: 4, reflect: 0.15),
                    DivineFaceEffect(block: 6, reflect: 0.25),
                    DivineFaceEffect(block: 9, reflect: 0.35),
                ]),
        GiftDef(id: "bastet_whisker", deity: .bastet, role: .defend,
                name: "Whisker-Sense", shortName: "WHISKER", symbol: "sensor.tag.radiowaves.forward",
                flavor: "She reads the air and is already gone.",
                finalFormName: "Whisker-Sense",
                effects: [
                    DivineFaceEffect(block: 2, dodgeGain: 1),
                    DivineFaceEffect(block: 4, dodgeGain: 1),
                    DivineFaceEffect(block: 6, dodgeGain: 2),
                ]),
        GiftDef(id: "bastet_nap", deity: .bastet, role: .defend,
                name: "Cat Nap", shortName: "NAP", symbol: "moon.zzz.fill",
                flavor: "Guard duty, technically. Also a nap.",
                finalFormName: "The Warm Windowsill",
                effects: [
                    DivineFaceEffect(block: 3, regenAmount: 2, regenTurns: 2),
                    DivineFaceEffect(block: 5, regenAmount: 3, regenTurns: 2),
                    DivineFaceEffect(block: 7, regenAmount: 4, regenTurns: 3),
                ]),

        GiftDef(id: "bastet_feline", deity: .bastet, role: .support,
                name: "Feline Grace", shortName: "GRACE", symbol: "heart",
                flavor: "Heal fast, move fast, land soft.",
                finalFormName: "Feline Grace",
                effects: [
                    DivineFaceEffect(heal: 3),
                    DivineFaceEffect(heal: 4, staminaNext: 1),
                    DivineFaceEffect(heal: 6, staminaNext: 1),
                ]),
        GiftDef(id: "bastet_sistrum", deity: .bastet, role: .support,
                name: "Sistrum Song", shortName: "SISTRUM", symbol: "music.note.list",
                flavor: "A rattle of bronze, and the bleeding stops.",
                finalFormName: "Sistrum Song",
                effects: [
                    DivineFaceEffect(heal: 3, cleanse: true),
                    DivineFaceEffect(heal: 5, cleanse: true),
                    DivineFaceEffect(heal: 8, cleanse: true),
                ]),
        GiftDef(id: "bastet_purr", deity: .bastet, role: .support,
                name: "The Purr", shortName: "PURR", symbol: "waveform",
                flavor: "A sound that knits wounds all by itself.",
                finalFormName: "The Purr",
                effects: [
                    DivineFaceEffect(regenAmount: 2, regenTurns: 2),
                    DivineFaceEffect(regenAmount: 3, regenTurns: 3),
                    DivineFaceEffect(regenAmount: 5, regenTurns: 3),
                ]),
        GiftDef(id: "bastet_night", deity: .bastet, role: .support,
                name: "The Night Hunt", shortName: "HUNT", symbol: "moon.stars",
                flavor: "Fed and restless, all at once.",
                finalFormName: "The Night Hunt",
                effects: [
                    DivineFaceEffect(staminaNext: 1, bleedAmount: 2, bleedTurns: 2),
                    DivineFaceEffect(staminaNext: 1, bleedAmount: 3, bleedTurns: 2),
                    DivineFaceEffect(staminaNext: 2, bleedAmount: 4, bleedTurns: 2),
                ]),
    ]
}
