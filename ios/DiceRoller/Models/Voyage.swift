import SwiftUI

/// What waits at a stage of the river. Fights dominate; the rest are chances
/// to prepare, trade, or gamble on the strange.
enum StageKind: String, CaseIterable, Hashable {
    case battle
    case herald
    case shrine
    case ferryman
    case mooring
    case omen
    case boss

    var label: String {
        switch self {
        case .battle: "Guardian"
        case .herald: "Herald"
        case .shrine: "Shrine"
        case .ferryman: "Ferryman"
        case .mooring: "Mooring"
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
        case .mooring: "Mooring the Barque"
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
        case .mooring: "Tie off. Heal, or work the whetstone."
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
        case .mooring: "moon.stars.fill"
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
        case .mooring: Theme.nileGreen
        case .omen: Theme.duskViolet
        case .boss: Theme.blood
        }
    }
}

/// One stage of the night: a single fifteen-minute chunk of the voyage, drawn
/// on the chart as a node. Edges to later stages are the open channels; every
/// stage you clear closes the ones you did not take.
struct VoyageNode: Identifiable, Hashable {
    let id: UUID
    let kind: StageKind
    /// Index across the whole night, 0 through 47.
    let stage: Int
    /// Which hour this chunk belongs to, 1 through 12.
    let hour: Int
    /// Stages the barque may sail to from here.
    var connections: [UUID] = []

    var isHourEnd: Bool { stage % Voyage.stagesPerHour == Voyage.stagesPerHour - 1 }
    var isGateMouth: Bool { stage % Voyage.stagesPerHour == 0 }
    var isBoss: Bool { kind == .boss }
    var isCombat: Bool { kind == .battle || kind == .herald || kind == .boss }
    var gate: Gate { Gate.forHour(hour) }
}

/// The whole night as a branching river, generated fresh for every run.
/// Structure: four stages per hour, sixteen per gate. Each hour opens with a
/// single forced fight, branches through its middle chunks, offers one last
/// chance to prepare, then seals with a lone herald — or, at hours 4, 8 and 12,
/// with the gate's serpent-lord.
struct Voyage: Hashable {
    static let totalHours = 12
    static let stagesPerHour = 4
    static var totalStages: Int { totalHours * stagesPerHour }

    var nodes: [VoyageNode]

    func node(_ id: UUID) -> VoyageNode? { nodes.first { $0.id == id } }

    func nodes(inStage stage: Int) -> [VoyageNode] { nodes.filter { $0.stage == stage } }

    func nodes(inHour hour: Int) -> [VoyageNode] { nodes.filter { $0.hour == hour } }

    var entryNode: VoyageNode? { nodes.first { $0.stage == 0 } }

    // MARK: - Generation

    static func generate() -> Voyage {
        var columns: [[VoyageNode]] = []

        for stage in 0..<totalStages {
            let hour = stage / stagesPerHour + 1
            let inHour = stage % stagesPerHour
            let isBoss = hour % 4 == 0 && inHour == stagesPerHour - 1

            let kinds: [StageKind]
            if isBoss {
                // The serpent-lord stands alone at the end of the gate.
                kinds = [.boss]
            } else if inHour == stagesPerHour - 1 {
                // Every hour is sealed by a herald of Apep — a lone, forced
                // mini-boss standing between you and the next hour.
                kinds = [.herald]
            } else if inHour == 0 {
                // The mouth of every hour is a single, forced channel.
                kinds = [.battle]
            } else if inHour == stagesPerHour - 2 {
                // The last quiet water before the herald: a chance to prepare.
                kinds = distinctKinds(count: 2, hour: hour, preparation: true)
            } else {
                kinds = distinctKinds(count: Bool.random() ? 3 : 2, hour: hour, preparation: false)
            }

            let column = kinds.map { kind in
                VoyageNode(id: UUID(), kind: kind, stage: stage, hour: hour)
            }
            columns.append(column)
        }

        var nodes = columns.flatMap { $0 }

        // Channels: from every node in a column, one or two ways onward — but
        // every node in the next column must be reachable by someone, so the
        // branches converge and split again down the river.
        var links: [UUID: [UUID]] = [:]
        for index in 1..<columns.count {
            let previous = columns[index - 1]
            let current = columns[index]
            var incoming: Set<UUID> = []

            for node in previous {
                let count = current.count == 1 ? 1 : Int.random(in: 1...min(2, current.count))
                let targets = current.shuffled().prefix(count)
                links[node.id, default: []].append(contentsOf: targets.map(\.id))
                incoming.formUnion(targets.map(\.id))
            }

            // A channel nobody can reach would be invisible — hand it a donor.
            for node in current where !incoming.contains(node.id) {
                guard let donor = previous.randomElement() else { continue }
                if !(links[donor.id]?.contains(node.id) ?? false) {
                    links[donor.id, default: []].append(node.id)
                }
                incoming.insert(node.id)
            }
        }

        nodes = nodes.map { node in
            var n = node
            n.connections = links[node.id] ?? []
            return n
        }
        return Voyage(nodes: nodes)
    }

    /// Rolls kinds for one stage column, never repeating a kind within it.
    private static func distinctKinds(count: Int, hour: Int, preparation: Bool) -> [StageKind] {
        var picked: [StageKind] = []
        var attempts = 0
        while picked.count < count && attempts < 40 {
            attempts += 1
            let candidate: StageKind = preparation
                ? [StageKind.mooring, .shrine, .ferryman, .battle].randomElement() ?? .battle
                : rolledKind(hour: hour)
            // Lead columns with a fight more often than not.
            let lead: StageKind = picked.isEmpty && !preparation && Bool.random() ? .battle : candidate
            guard !picked.contains(lead) else { continue }
            picked.append(lead)
        }
        return picked.isEmpty ? [.battle] : picked
    }

    private static func rolledKind(hour: Int) -> StageKind {
        switch Int.random(in: 0..<100) {
        case 0..<50: .battle
        case 50..<60: .omen
        case 60..<70: .shrine
        case 70..<80: .ferryman
        case 80..<88: .mooring
        // Heralds are reserved for the close of the hour, so mid-hour water
        // never spends one early.
        default: .battle
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
