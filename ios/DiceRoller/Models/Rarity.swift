import SwiftUI

/// Quality tier for anything on offer. Shops, loot and events roll higher
/// tiers the deeper you travel.
enum Rarity: Int, CaseIterable, Hashable, Comparable {
    case common = 0
    case uncommon = 1
    case rare = 2
    case signature = 3

    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Tiers are named for what they are made of.
    var label: String {
        switch self {
        case .common: "Clay"
        case .uncommon: "Copper"
        case .rare: "Lapis"
        case .signature: "Gold Leaf"
        }
    }

    var tint: Color {
        switch self {
        case .common: Theme.clay
        case .uncommon: Theme.copper
        case .rare: Theme.lapis
        case .signature: Theme.goldLeaf
        }
    }

    /// Face used for the material swatch on an offer card.
    var materialGradient: LinearGradient {
        switch self {
        case .common:
            LinearGradient(colors: [Theme.clay.opacity(0.9), Theme.clay.opacity(0.45)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .uncommon:
            LinearGradient(colors: [Theme.copper, Theme.emberDeep],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rare:
            LinearGradient(colors: [Theme.lapis, Theme.lapis.opacity(0.45), Theme.skyBlue.opacity(0.7)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .signature:
            LinearGradient(colors: [Theme.goldLeaf, Theme.goldDeep, Theme.goldLeaf],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var priceMultiplier: Double {
        switch self {
        case .common: 1.0
        case .uncommon: 1.6
        case .rare: 2.4
        case .signature: 3.6
        }
    }

    /// How likely each tier is at a given depth. Every card draws its own
    /// material independently — nothing guarantees one of each. Clay dominates
    /// the first hours and the richer materials climb steadily through the
    /// night, so gold leaf is close to unheard of at the river mouth and a real
    /// possibility by the twelfth hour.
    /// `progress` runs 0 (first hour) to 1 (Apep).
    static func weights(progress: Double) -> [Double] {
        let p = min(max(progress, 0), 1)
        return [
            0.72 - 0.42 * p,         // clay
            0.22 + 0.10 * p,         // copper
            0.05 + 0.20 * p,         // lapis
            0.01 + 0.12 * p * p,     // gold leaf
        ]
    }

    /// Weighted roll for a single tier.
    static func roll(progress: Double) -> Rarity {
        pick(from: weights(progress: progress)) ?? .common
    }

    /// Draws `count` tiers, each rolled on its own. Repeats are allowed: an
    /// altar early in the night can be all clay, and a late one can hold two
    /// pieces of lapis.
    static func rollSet(count: Int, progress: Double) -> [Rarity] {
        (0..<max(0, count)).map { _ in roll(progress: progress) }
    }

    private static func pick(from weights: [Double]) -> Rarity? {
        let total = weights.reduce(0, +)
        guard total > 0 else { return nil }
        var roll = Double.random(in: 0..<total)
        for (index, weight) in weights.enumerated() {
            if roll < weight { return Rarity(rawValue: index) }
            roll -= weight
        }
        return Rarity(rawValue: weights.count - 1)
    }
}
