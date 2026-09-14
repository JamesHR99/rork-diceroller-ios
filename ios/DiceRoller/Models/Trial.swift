import Foundation

/// A god's Trial: an ordinary fight that turns out to carry a champion lent
/// that god's own power. At most one per run; declining costs nothing. The
/// encounter stays ordinary — the god lends a mechanic, never health or damage.
struct DivineTrial: Identifiable, Hashable {
    let deity: Deity
    /// The god's epithet for the trial, e.g. "Burning Sun".
    let title: String
    /// What the lent power does, spelled out in one line.
    let power: String

    var id: String { deity.rawValue }

    var name: String { "\(deity.name), \(title)" }

    /// The boon on offer: a choice of three of the god's own — a blessing, an
    /// upgrade, or their capstone if the run's limits allow.
    var boonLine: String {
        "Beat the champion and \(deity.name) offers a choice of three boons — a new blessing, one of their upgrades, or their capstone if you have earned it."
    }

    static let all: [DivineTrial] = [
        DivineTrial(
            deity: .ra, title: "Burning Sun",
            power: "The champion's first health-damaging hit each turn sets you burning 2 for two ticks. Block or evade it fully and nothing catches."
        ),
        DivineTrial(
            deity: .sobek, title: "Hungry River",
            power: "The champion's first health-damaging hit each turn opens 2 bleed for two ticks and feeds it 4 health. Watch its forecast — you can see the feeding coming."
        ),
        DivineTrial(
            deity: .anubis, title: "Weighed Heart",
            power: "Every second turn the champion passes Sentence instead of attacking — 6 judgement that falls at the end of your next turn. Kill the judge first and the sentence dies with it."
        ),
        DivineTrial(
            deity: .bes, title: "Unbroken Gate",
            power: "After acting, the champion raises 8 shield that stands against your next turn. Separate the gate from the health in your forecast."
        ),
        DivineTrial(
            deity: .horus, title: "Watching Falcon",
            power: "Every third turn the champion strikes with a heavily telegraphed blow that ignores half your shield. Evasion still avoids it outright."
        ),
        DivineTrial(
            deity: .bastet, title: "Vanishing Step",
            power: "Every second turn of yours the champion gains one evade charge that expires at the end of that turn. Lead with something cheap to strip it — burn and bleed already running are unaffected."
        ),
    ]

    static func random() -> DivineTrial {
        all.randomElement() ?? all[0]
    }
}
