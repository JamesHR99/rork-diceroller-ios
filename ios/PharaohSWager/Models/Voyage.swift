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
/// a wheel chooses the encounter, with fixed herald and lord milestones.
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

/// Twenty-four stops: an opening guardian, ordinary wheel spins, and fixed
/// herald/lord milestones. The result and reroll purse belong to the voyage.
struct Voyage: Hashable, Codable {
    static let totalHours = 12
    static let stagesPerHour = 2
    static let stagesPerGate = 8
    static var totalStages: Int { totalHours * stagesPerHour }
    static let heraldIndex = 3
    static let lordIndex = 7
    static let pathRerollCap = 3

    /// Equal-sized wedges: eight guardians, two omens, a shrine and a shop.
    static let wheelKinds: [StageKind] = [
        .battle, .omen, .battle, .shrine, .battle, .battle,
        .omen, .battle, .ferryman, .battle, .battle, .battle
    ]
    static var wedgeDegrees: Double { 360 / Double(wheelKinds.count) }
    static func rotation(for index: Int) -> Double { -Double(index) * wedgeDegrees }

    var nodes: [VoyageNode]
    // Optional for compatibility with existing version-4 runs.
    var pathRerolls: Int? = nil
    var wheelResults: [Int: Int]? = nil

    var rerollsRemaining: Int { min(Self.pathRerollCap, max(0, pathRerolls ?? 1)) }

    @discardableResult
    mutating func grantPathRerolls(_ amount: Int) -> Int {
        let before = rerollsRemaining
        pathRerolls = min(Self.pathRerollCap, before + min(Self.pathRerollCap, max(0, amount)))
        return rerollsRemaining - before
    }

    func result(inStage stage: Int) -> Int? { wheelResults?[stage] }

    func canReroll(_ node: VoyageNode) -> Bool {
        nodes.contains(where: { $0.id == node.id }) && node.stage > 0
            && !Self.spine(ofStage: node.stage).isForced
            && result(inStage: node.stage) != nil && rerollsRemaining > 0
    }

    /// Commit before the animation: relaunching cannot undo a spend or fish
    /// for another first spin. An old two-channel stage collapses to one node.
    @discardableResult
    mutating func spin(stage: Int, usingReroll: Bool = false) -> Int? {
        guard stage > 0, !Self.spine(ofStage: stage).isForced,
              let old = nodes(inStage: stage).first else { return nil }
        if usingReroll {
            guard canReroll(old) else { return nil }
            pathRerolls = rerollsRemaining - 1
        } else {
            guard result(inStage: stage) == nil else { return nil }
        }
        let index = Int.random(in: Self.wheelKinds.indices)
        nodes.removeAll { $0.stage == stage && $0.id != old.id }
        if let position = nodes.firstIndex(where: { $0.id == old.id }) {
            nodes[position] = VoyageNode(id: old.id, kind: Self.wheelKinds[index],
                stage: stage, hour: old.hour, isRevealed: true)
        }
        if wheelResults == nil { wheelResults = [:] }
        wheelResults?[stage] = index
        return index
    }

    @discardableResult
    mutating func rerollDestination(_ id: UUID) -> Bool {
        guard let node = node(id), canReroll(node) else { return false }
        return spin(stage: node.stage, usingReroll: true) != nil
    }

    func node(_ id: UUID) -> VoyageNode? { nodes.first { $0.id == id } }
    func nodes(inStage stage: Int) -> [VoyageNode] { nodes.filter { $0.stage == stage } }
    func nodes(inHour hour: Int) -> [VoyageNode] { nodes.filter { $0.hour == hour } }
    var entryNode: VoyageNode? { nodes.first { $0.stage == 0 } }

    static func spine(ofStage stage: Int) -> StageKind {
        switch stage % stagesPerGate {
        case heraldIndex: .herald
        case lordIndex: .boss
        default: .battle
        }
    }

    static func generate() -> Voyage {
        Voyage(nodes: (0..<totalStages).map { stage in
            VoyageNode(id: UUID(), kind: spine(ofStage: stage), stage: stage,
                hour: stage / stagesPerHour + 1, isRevealed: true)
        }, pathRerolls: 1, wheelResults: [:])
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


