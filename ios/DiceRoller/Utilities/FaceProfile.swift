import Foundation

/// A digest of a multi-dice offer.
///
/// Cards used to draw every face of every die, which was too wide for the card
/// and too dense to read. What actually decides the pick is which faces the
/// set is built around and which way it leans, so that is all this keeps.
struct FaceProfile {
    /// One face kind and how many times the set carries it.
    struct Tally: Identifiable, Hashable {
        let kind: FaceKind
        let count: Int

        var id: FaceKind { kind }
    }

    /// The face kinds that give the set its character, commonest first.
    let signature: [Tally]

    /// How the set leans overall, as a short phrase.
    let leaning: String

    init(_ faces: [FaceKind]) {
        var counts: [FaceKind: Int] = [:]
        for face in faces { counts[face, default: 0] += 1 }

        // Commonest first; ties break on the stronger face so the digest shows
        // the one worth knowing about.
        signature = counts
            .map { Tally(kind: $0.key, count: $0.value) }
            .sorted {
                $0.count != $1.count
                    ? $0.count > $1.count
                    : $0.kind.baseValue > $1.kind.baseValue
            }

        leaning = Self.describeLeaning(faces)
    }

    /// Sorts the set into the handful of shapes a player actually cares about.
    private static func describeLeaning(_ faces: [FaceKind]) -> String {
        guard !faces.isEmpty else { return "empty" }

        var attack = 0
        var guarding = 0
        var restorative = 0
        var utility = 0

        for face in faces {
            if face.isAttack {
                attack += 1
                continue
            }
            switch face.soloKind {
            case .block: guarding += 1
            case .heal: restorative += 1
            case .poison: attack += 1
            default: utility += 1
            }
        }

        let total = Double(faces.count)
        let share = { (count: Int) in Double(count) / total }

        if share(attack) >= 0.6 { return "aggressive" }
        if share(guarding) >= 0.5 { return "defensive" }
        if share(restorative) >= 0.34 { return "restorative" }
        if share(utility) >= 0.4 { return "utility" }
        if attack > guarding { return "attack-leaning" }
        if guarding > attack { return "guard-leaning" }
        return "balanced"
    }
}
