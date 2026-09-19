import Foundation

/// Everything one god's answer does when a face of a given kind is played.
/// Blessings fire once per role per action; the fields here are flat and
/// readable, and the engine lands them through one shared path.
struct GodAnswer: Hashable {
    var damage = 0
    var shield = 0
    var heal = 0
    /// Burn applied to the target (Ra).
    var burn = 0
    /// Bleed applied to the target (Sobek).
    var bleed = 0
    /// Judgement stored against the target (Anubis).
    var judgement = 0
    /// Guaranteed single-hit Dodge charges (Bastet).
    var dodgeCharges = 0
    /// Flat damage banked onto your next damaging action.
    var primeDamage = 0
    /// Percentage damage banked onto your next damaging action.
    var primePercent = 0
    /// Extra burn banked onto your next damaging action.
    var primeBurn = 0
    /// Healing banked onto your next damaging action.
    var primeHeal = 0
    /// Fraction of the target's block and armour this attack ignores.
    var pierce = 0.0
    /// Extra rerolls banked for the following round.
    var rerollsNext = 0

    var isEmpty: Bool {
        damage == 0 && shield == 0 && heal == 0 && burn == 0 && bleed == 0
            && judgement == 0 && dodgeCharges == 0 && primeDamage == 0
            && primePercent == 0 && primeBurn == 0 && primeHeal == 0
            && pierce == 0 && rerollsNext == 0
    }

    /// One-line readout for the codex and offer cards.
    var summary: String {
        var parts: [String] = []
        if damage > 0 { parts.append("\(damage) damage") }
        if shield > 0 { parts.append("\(shield) shield") }
        if heal > 0 { parts.append("heal \(heal)") }
        if burn > 0 { parts.append("burn \(burn)") }
        if bleed > 0 { parts.append("bleed \(bleed)") }
        if judgement > 0 { parts.append("\(judgement) judgement") }
        if dodgeCharges > 0 { parts.append("+\(dodgeCharges) Dodge") }
        if primeDamage > 0 { parts.append("prime \(primeDamage) damage") }
        if primePercent > 0 { parts.append("prime +\(primePercent)%") }
        if primeBurn > 0 { parts.append("prime \(primeBurn) burn") }
        if primeHeal > 0 { parts.append("heal \(primeHeal) on your next hit") }
        if pierce > 0 { parts.append("ignore \(Int(pierce * 100))% defences") }
        if rerollsNext > 0 { parts.append("+\(rerollsNext) reroll") }
        return parts.joined(separator: ", ")
    }
}

/// One upgrade on a god's path. Earned once; needs a blessed die of that god.
struct GodUpgrade: Identifiable, Hashable {
    let id: String
    let deity: Deity
    let name: String
    let detail: String
    let symbol: String
}

/// A god's capstone — the last word of their path. Needs two upgrades from
/// that god, and only one capstone may be carried per run.
struct GodCapstone: Identifiable, Hashable {
    let id: String
    let deity: Deity
    let name: String
    let detail: String
    let symbol: String
}

/// The blessing each god lays on the faces of their patron dice, plus their
/// upgrade and capstone paths. Blessings answer the face itself: attacks get
/// the attack answer, Block faces the block answer, Evade faces the evade
/// answer, everything else the support answer — once each per action.
enum GodKit {
    // MARK: - Blessings

    /// What the god answers when its die plays a face of each kind of role.
    static func blessing(for deity: Deity, role: BlessingRole) -> GodAnswer {
        switch (deity, role) {
        case (.ra, .attack): return GodAnswer(burn: 2)
        case (.ra, .block): return GodAnswer(shield: 4)
        case (.ra, .evade): return GodAnswer(burn: 2)
        case (.ra, .support): return GodAnswer(primeBurn: 3)

        case (.sobek, .attack): return GodAnswer(bleed: 4)
        case (.sobek, .block): return GodAnswer(shield: 4)
        case (.sobek, .evade): return GodAnswer(heal: 3)
        case (.sobek, .support): return GodAnswer(primeHeal: 5)

        case (.anubis, .attack): return GodAnswer(judgement: 6)
        case (.anubis, .block): return GodAnswer(shield: 4)
        case (.anubis, .evade): return GodAnswer(judgement: 4)
        case (.anubis, .support): return GodAnswer(primeDamage: 6)

        case (.bes, .attack): return GodAnswer(shield: 3)
        case (.bes, .block): return GodAnswer(shield: 5)
        case (.bes, .evade): return GodAnswer(primeDamage: 8)
        case (.bes, .support): return GodAnswer(shield: 4)

        case (.horus, .attack): return GodAnswer(pierce: 0.2)
        case (.horus, .block): return GodAnswer(shield: 4)
        case (.horus, .evade): return GodAnswer(primePercent: 15)
        case (.horus, .support): return GodAnswer(primePercent: 15)

        case (.bastet, .attack): return GodAnswer(damage: 4)
        case (.bastet, .block): return GodAnswer(shield: 3)
        case (.bastet, .evade): return GodAnswer(dodgeCharges: 1)
        case (.bastet, .support): return GodAnswer(primeDamage: 4)
        }
    }

    /// Short label for a blessing slot, used in the codex.
    static func blessingLabel(for role: BlessingRole) -> String {
        switch role {
        case .attack: "Attacks"
        case .block: "Block faces"
        case .evade: "Evade: on the next dodge"
        case .support: "Mends & support"
        }
    }

    // MARK: - Upgrade paths

    static let upgrades: [GodUpgrade] = [
        GodUpgrade(id: "ra_kindling", deity: .ra, name: "Kindling",
                   detail: "Ra's burn bites one deeper — his blessing applies 3 instead of 2.",
                   symbol: "flame.fill"),
        GodUpgrade(id: "ra_sunEdge", deity: .ra, name: "Sun's Edge",
                   detail: "Your attacks cut through a quarter of a burning enemy's defences.",
                   symbol: "flame.circle.fill"),
        GodUpgrade(id: "ra_solarWind", deity: .ra, name: "Solar Wind",
                   detail: "An action holding a kept Ra attack face deals 8 more damage.",
                   symbol: "wind.circle.fill"),
        GodUpgrade(id: "ra_ashes", deity: .ra, name: "Ashes to Ashes",
                   detail: "When a burning enemy dies, its fire spreads to another living foe.",
                   symbol: "wind"),

        GodUpgrade(id: "sob_deepWater", deity: .sobek, name: "Deep Water",
                   detail: "Sobek's bleed ticks for 2 more.",
                   symbol: "drop.fill"),
        GodUpgrade(id: "sob_bloodScent", deity: .sobek, name: "Blood Scent",
                   detail: "+20% damage against bleeding enemies.",
                   symbol: "nose"),
        GodUpgrade(id: "sob_firstFeast", deity: .sobek, name: "First Feast",
                   detail: "The first attack each turn that draws blood heals you 4.",
                   symbol: "fork.knife"),
        GodUpgrade(id: "sob_riptide", deity: .sobek, name: "Riptide",
                   detail: "Attacks against enemies below half health ignore 30% of defences.",
                   symbol: "water.waves"),

        GodUpgrade(id: "an_greatTally", deity: .anubis, name: "Great Tally",
                   detail: "Anubis's judgement grows — his blessing adds 9 instead of 6.",
                   symbol: "scalemass.fill"),
        GodUpgrade(id: "an_secondReading", deity: .anubis, name: "Second Reading",
                   detail: "Judgement added to an enemy already under judgement is doubled.",
                   symbol: "scale.3d"),
        GodUpgrade(id: "an_burialGift", deity: .anubis, name: "Burial Gift",
                   detail: "When a judged enemy dies before its judgement falls, gain 8 health and 8 shield.",
                   symbol: "gift.fill"),
        GodUpgrade(id: "an_weighed", deity: .anubis, name: "Weighed to the Grain",
                   detail: "An action holding a kept Anubis attack face adds 6 more judgement.",
                   symbol: "scalemass"),

        GodUpgrade(id: "be_stout", deity: .bes, name: "The Stout Door",
                   detail: "Bes's shield grants 2 more, whatever the face.",
                   symbol: "door.left.hand.closed"),
        GodUpgrade(id: "be_rebuild", deity: .bes, name: "Rebuild the Wall",
                   detail: "The first time your shield breaks each battle, restore 8 of it.",
                   symbol: "arrow.counterclockwise"),
        GodUpgrade(id: "be_counter", deity: .bes, name: "The Counter-Swing",
                   detail: "When your shield absorbs a hit, your next attack this turn deals 10 more.",
                   symbol: "bolt.fill"),
        GodUpgrade(id: "be_joy", deity: .bes, name: "House of Joy",
                   detail: "Playing a Bes support face heals you 5.",
                   symbol: "music.note"),

        GodUpgrade(id: "ho_falconEye", deity: .horus, name: "Falcon's Eye",
                   detail: "An action holding a kept Horus attack face deals 25% more damage.",
                   symbol: "eye.fill"),
        GodUpgrade(id: "ho_keen", deity: .horus, name: "The Keen Edge",
                   detail: "Horus attack blessings ignore 40% of defences instead of a fifth.",
                   symbol: "scope"),
        GodUpgrade(id: "ho_windRead", deity: .horus, name: "Wind-Reader",
                   detail: "Horus patron dice roll 8% more critical chance.",
                   symbol: "wind.snow"),
        GodUpgrade(id: "ho_thermal", deity: .horus, name: "Thermal",
                   detail: "The first kept Horus face each turn hands back 1 reroll.",
                   symbol: "arrow.up.circle.fill"),

        GodUpgrade(id: "ba_pounce", deity: .bastet, name: "Pounce",
                   detail: "Chains of exactly two faces deal 6 more damage.",
                   symbol: "pawprint.fill"),
        GodUpgrade(id: "ba_lightLanding", deity: .bastet, name: "Light Landing",
                   detail: "Your first successful evade each enemy turn banks 1 reroll.",
                   symbol: "figure.run"),
        GodUpgrade(id: "ba_claws", deity: .bastet, name: "Claws Out",
                   detail: "Your first successful evade each enemy turn primes 10 damage on your next attack.",
                   symbol: "slash.circle"),
        GodUpgrade(id: "ba_unscathed", deity: .bastet, name: "Unscathed",
                   detail: "Take no health damage during an enemy turn and gain 6 shield at the start of your next turn.",
                   symbol: "checkmark.seal.fill"),
    ]

    static func upgrades(for deity: Deity) -> [GodUpgrade] {
        upgrades.filter { $0.deity == deity }
    }

    // MARK: - Capstones

    static let capstones: [GodCapstone] = [
        GodCapstone(id: "ra_solarFlare", deity: .ra, name: "Solar Flare",
                    detail: "Once a turn, a chain of three or more holding a Ra attack face detonates the target's burn for 3 a stack, then applies fresh burn.",
                    symbol: "sun.max.fill"),
        GodCapstone(id: "sob_jaws", deity: .sobek, name: "Jaws of the Nile",
                    detail: "Once a turn, an attack against a bleeding foe bites its bleed early — one tick paid without shortening it — and heals you for what it dealt, up to 8.",
                    symbol: "water.waves"),
        GodCapstone(id: "an_finalVerdict", deity: .anubis, name: "Final Verdict",
                    detail: "Detonations deal double against ordinary enemies below a quarter health, and half again more against bosses.",
                    symbol: "scalemass.fill"),
        GodCapstone(id: "be_unbroken", deity: .bes, name: "Unbroken House",
                    detail: "After each enemy turn, strike back at the foe that hit you hardest for half the damage your shield absorbed, up to 20.",
                    symbol: "shield.checkered"),
        GodCapstone(id: "ho_eyeFalcon", deity: .horus, name: "Eye of the Falcon",
                    detail: "Once a turn, a chain holding a kept Horus face and containing a critical face ignores all block and armour.",
                    symbol: "bird.fill"),
        GodCapstone(id: "ba_nineLives", deity: .bastet, name: "Nine Lives Unbound",
                    detail: "Once a battle, a lethal blow leaves you at 1 health instead, prepares two guaranteed Dodges, and primes 10 damage.",
                    symbol: "cat.fill"),
    ]

    static func capstone(for deity: Deity) -> GodCapstone? {
        capstones.first { $0.deity == deity }
    }

    /// True when the run may take this capstone: two upgrades of that god.
    static func capstoneUnlocked(_ capstone: GodCapstone, upgrades acquired: Set<String>) -> Bool {
        upgrades(for: capstone.deity).filter { acquired.contains($0.id) }.count >= 2
    }
}

/// The role a played face answers to. Block and Evade are separate answers —
/// a god reads the face itself, not just "defence".
enum BlessingRole: CaseIterable, Hashable {
    case attack
    case block
    case evade
    case support

    static func role(for kind: FaceKind) -> BlessingRole {
        switch kind.soloKind {
        case .damage: .attack
        case .block: .block
        case .evade: .evade
        case .heal, .poison, .focus: .support
        }
    }
}

/// A named pairing of two gods. Unlocked by carrying one upgrade from both —
/// fires at most once per turn while both gods stay equipped.
struct PairingDef: Identifiable, Hashable {
    let id: String
    let name: String
    let first: Deity
    let second: Deity
    let detail: String
    let symbol: String

    var tint: Deity { first }
}

/// The fifteen pairings, one for every way two gods can stand together.
enum PairingContent {
    static let pairings: [PairingDef] = [
        PairingDef(id: "pair_ra_sobek", name: "Boiling Nile", first: .ra, second: .sobek,
                   detail: "At the end of your turn, a foe burning and bleeding at once is scalded for its burn again — once a turn.",
                   symbol: "flame.circle"),
        PairingDef(id: "pair_ra_anubis", name: "Funeral Pyre", first: .ra, second: .anubis,
                   detail: "Detonations burn brighter: +2 damage per burn stack on the judged foe.",
                   symbol: "flame.square.fill"),
        PairingDef(id: "pair_ra_bes", name: "Forge Song", first: .ra, second: .bes,
                   detail: "Once a turn, when your shield absorbs a hit, the striker is set alight.",
                   symbol: "anvil.fill"),
        PairingDef(id: "pair_ra_horus", name: "Sunstrike", first: .ra, second: .horus,
                   detail: "Once a turn, an action holding a kept Ra attack face and a kept Horus face lands an early burn tick.",
                   symbol: "sun.haze.fill"),
        PairingDef(id: "pair_ra_bastet", name: "Dancing Flame", first: .ra, second: .bastet,
                   detail: "Your first successful evade each enemy turn sets the attacker alight.",
                   symbol: "flame.rectangle"),
        PairingDef(id: "pair_sobek_anubis", name: "The Crossing", first: .sobek, second: .anubis,
                   detail: "Once a turn, a detonation against a bleeding foe carries you across — heal 5.",
                   symbol: "arrow.right.circle.fill"),
        PairingDef(id: "pair_sobek_bes", name: "Crocodile Hide", first: .sobek, second: .bes,
                   detail: "Your first heal each turn hardens into 5 shield.",
                   symbol: "lizard.fill"),
        PairingDef(id: "pair_sobek_horus", name: "Reed and Sky", first: .sobek, second: .horus,
                   detail: "Once a turn, an action holding a kept Horus face deals 25% more damage against a bleeding foe.",
                   symbol: "water.holder"),
        PairingDef(id: "pair_sobek_bastet", name: "Death Roll", first: .sobek, second: .bastet,
                   detail: "After a successful evade, the attacker is bitten for its bleed early — once a turn.",
                   symbol: "arrow.uturn.down.circle.fill"),
        PairingDef(id: "pair_anubis_bes", name: "Guardian of the Tomb", first: .anubis, second: .bes,
                   detail: "Once a turn, when your shield absorbs a hit, the striker takes 4 more judgement.",
                   symbol: "building.columns.fill"),
        PairingDef(id: "pair_anubis_horus", name: "The Weighing Eye", first: .anubis, second: .horus,
                   detail: "Once a turn, an action holding a kept Horus face adds 6 judgement to the target.",
                   symbol: "eye.circle.fill"),
        PairingDef(id: "pair_anubis_bastet", name: "Borrowed Life", first: .anubis, second: .bastet,
                   detail: "Your first successful evade each enemy turn weighs the attacker — 4 judgement.",
                   symbol: "heart.circle"),
        PairingDef(id: "pair_bes_horus", name: "Watchful Guardian", first: .bes, second: .horus,
                   detail: "Once a turn, an action holding a kept Horus face grants 4 shield.",
                   symbol: "bird.square"),
        PairingDef(id: "pair_bes_bastet", name: "Warm Doorstep", first: .bes, second: .bastet,
                   detail: "Your first successful evade each enemy turn banks 4 shield.",
                   symbol: "house.fill"),
        PairingDef(id: "pair_horus_bastet", name: "Silent Descent", first: .horus, second: .bastet,
                   detail: "After a successful evade, your next chain of two or more faces holding a Horus face ignores all defences — once a turn.",
                   symbol: "moon.haze.fill"),
    ]

    static func pairing(_ first: Deity, _ second: Deity) -> PairingDef? {
        pairings.first { ($0.first == first && $0.second == second) || ($0.first == second && $0.second == first) }
    }
}

