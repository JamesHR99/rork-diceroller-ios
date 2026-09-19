import SwiftUI

/// What waits at a stage of the river. Fights dominate; the rest are chances
/// to prepare, trade, or gamble on the strange.
enum StageKind: String, CaseIterable, Hashable, Codable {
    case battle
    case herald
    case shrine
    case ferryman
    case omen
    case boss

    var label: String {
        switch self {
        case .battle: "Guardian"
        case .herald: "Herald"
        case .shrine: "Shrine"
        case .ferryman: "Ferryman"
        case .omen: "Omen"
        case .boss: "Serpent-Lord"
        }
    }

    var title: String {
        switch self {
        case .battle: "A Guardian of the Deep"
        case .herald: "Herald of Apep"
        case .shrine: "Shrine on the Bank"
        case .ferryman: "The Ferryman"
        case .omen: "An Omen on the River"
        case .boss: "The Serpent-Lord"
        }
    }

    var blurb: String {
        switch self {
        case .battle: "Something rises to bar the channel."
        case .herald: "A harder fight, guarding richer spoils."
        case .shrine: "A god's altar rises out of the water."
        case .ferryman: "A hooded boatman trades in gold."
        case .omen: "Something on the river wants your attention."
        case .boss: "It fills the river from bank to bank."
        }
    }

    var symbol: String {
        switch self {
        case .battle: "skull.fill"
        case .herald: "crown.fill"
        case .shrine: "building.columns.fill"
        case .ferryman: "ferry.fill"
        case .omen: "eye.fill"
        case .boss: "lizard.fill"
        }
    }

    var tint: Color {
        switch self {
        case .battle: Theme.ember
        case .herald: Theme.blood
        case .shrine: Theme.sunGold
        case .ferryman: Theme.gold
        case .omen: Theme.duskViolet
        case .boss: Theme.blood
        }
    }

    /// Forced stops are the spine of a gate — they are never a choice and are
    /// always named on the chart.
    var isForced: Bool { self == .herald || self == .boss }
}

/// One stop on the river. The night is a straight run of stages; at each one
/// the water forks into two channels and you commit to a side.
struct VoyageNode: Identifiable, Hashable, Codable {
    let id: UUID
    let kind: StageKind
    /// Index across the whole night, 0 through 23.
    let stage: Int
    /// Which hour this stop belongs to, 1 through 12.
    let hour: Int
    /// True when the barque can see what is waiting. A dark channel is a
    /// gamble: you learn what it was by sailing into it.
    let isRevealed: Bool

    var isHourEnd: Bool { stage % Voyage.stagesPerHour == Voyage.stagesPerHour - 1 }
    var isBoss: Bool { kind == .boss }
    var isCombat: Bool { kind == .battle || kind == .herald || kind == .boss }
    var gate: Gate { Gate.forHour(hour) }
    /// Where this stop sits inside its gate, 0 through 7.
    var indexInGate: Int { stage % Voyage.stagesPerGate }
}

/// The whole night as a straight run of forks, generated fresh for every run.
///
/// A gate is eight stops: three ordinary encounters, the gate's herald, three
/// more encounters, then its serpent-lord. Every ordinary stop offers two
/// channels — sometimes both named, often one or both dark — and the herald
/// and the serpent-lord stand alone, because a gate has to be fought through
/// rather than sailed around.
struct Voyage: Hashable, Codable {
    static let totalHours = 12
    /// Two stops to an hour, so twelve hours still read as twelve hours.
    static let stagesPerHour = 2
    /// Eight stops to a gate: 3 · herald · 3 · serpent-lord.
    static let stagesPerGate = 8
    static var totalStages: Int { totalHours * stagesPerHour }

    /// Where the herald and the serpent-lord stand inside every gate.
    static let heraldIndex = 3
    static let lordIndex = 7

    var nodes: [VoyageNode]
    var rerolledStages: Set<Int>? = nil

    func canReroll(_ node: VoyageNode) -> Bool {
        nodes.contains(where: { $0.id == node.id }) && !node.kind.isForced
            && nodes(inStage: node.stage).count == 2
            && !(rerolledStages ?? []).contains(node.stage)
    }

    @discardableResult
    mutating func rerollDestination(_ id: UUID) -> Bool {
        guard let index = nodes.firstIndex(where: { $0.id == id }), canReroll(nodes[index]) else { return false }
        let old = nodes[index]
        nodes[index] = VoyageNode(id: old.id, kind: Self.rolledKind(), stage: old.stage,
            hour: old.hour, isRevealed: Double.random(in: 0..<1) < Self.revealChance)
        if rerolledStages == nil { rerolledStages = [] }
        rerolledStages?.insert(old.stage)
        return true
    }

    func node(_ id: UUID) -> VoyageNode? { nodes.first { $0.id == id } }

    func nodes(inStage stage: Int) -> [VoyageNode] { nodes.filter { $0.stage == stage } }

    func nodes(inHour hour: Int) -> [VoyageNode] { nodes.filter { $0.hour == hour } }

    var entryNode: VoyageNode? { nodes.first { $0.stage == 0 } }

    /// What kind of stop stage `n` is, before its channels are rolled. Read by
    /// the chart's gate ribbon so the shape of a gate is legible up front.
    static func spine(ofStage stage: Int) -> StageKind {
        switch stage % stagesPerGate {
        case heraldIndex: .herald
        case lordIndex: .boss
        default: .battle
        }
    }

    // MARK: - Generation

    static func generate() -> Voyage {
        var nodes: [VoyageNode] = []

        for stage in 0..<totalStages {
            let hour = stage / stagesPerHour + 1
            let spineKind = spine(ofStage: stage)

            if spineKind.isForced {
                // A herald or a serpent-lord is the one channel there is, and
                // you always see it coming.
                nodes.append(VoyageNode(id: UUID(), kind: spineKind, stage: stage,
                                        hour: hour, isRevealed: true))
                continue
            }

            for kind in optionPair() {
                nodes.append(VoyageNode(id: UUID(), kind: kind, stage: stage, hour: hour,
                                        isRevealed: Double.random(in: 0..<1) < revealChance))
            }
        }

        return Voyage(nodes: nodes)
    }

    /// How often a channel tells you what is in it. The rest of the time the
    /// water is dark and the choice is a genuine gamble.
    private static let revealChance = 0.55

    /// The two channels at one ordinary stop. Two identical quiet stops would
    /// be a choice in name only, so the pair is nudged apart — but two fights
    /// are left to stand, because which creature rises is its own difference.
    private static func optionPair() -> [StageKind] {
        let first = rolledKind()
        var second = rolledKind()
        if first == second {
            if first == .battle {
                // Half of the double-fight forks open one quieter channel, so
                // the run still breathes without handing out a stop every time.
                if Bool.random() { second = quietKind() }
            } else {
                second = .battle
            }
        }
        return [first, second]
    }

    /// What ordinary water holds. The river is dangerous: three channels in
    /// four are something that has to be fought. A god's altar and the
    /// Ferryman are deliberately scarce — finding one should feel like luck.
    private static func rolledKind() -> StageKind {
        switch Int.random(in: 0..<100) {
        case 0..<76: .battle
        case 76..<88: .omen
        case 88..<95: .shrine
        default: .ferryman
        }
    }

    /// The quiet stops, for when a fork needs one.
    private static func quietKind() -> StageKind {
        switch Int.random(in: 0..<100) {
        case 0..<56: .omen
        case 56..<83: .shrine
        default: .ferryman
        }
    }

    // MARK: - Naming

    static func ordinal(_ hour: Int) -> String {
        switch hour {
        case 1: "First"
        case 2: "Second"
        case 3: "Third"
        case 4: "Fourth"
        case 5: "Fifth"
        case 6: "Sixth"
        case 7: "Seventh"
        case 8: "Eighth"
        case 9: "Ninth"
        case 10: "Tenth"
        case 11: "Eleventh"
        default: "Twelfth"
        }
    }

    static func romanNumeral(_ hour: Int) -> String {
        switch hour {
        case 1: "I"
        case 2: "II"
        case 3: "III"
        case 4: "IV"
        case 5: "V"
        case 6: "VI"
        case 7: "VII"
        case 8: "VIII"
        case 9: "IX"
        case 10: "X"
        case 11: "XI"
        default: "XII"
        }
    }

    /// "The Ninth Hour · Gate of Coils"
    static func fullName(_ hour: Int) -> String {
        "The \(ordinal(hour)) Hour · \(Gate.forHour(hour).name)"
    }
}

