import Foundation

/// Chains every class shares, and the crit-etching tiers.
enum SharedContent {
    // MARK: - Shared combos (every class)

    /// Chains built only out of the shared armour and utility faces, so every
    /// class can find them. The old item-only recipes retired with the third
    /// gear slot; these need nothing but the faces everyone carries.
    static let combos: [ComboDef] = [
        ComboDef(id: "shr_steadiedStrike", name: "Steadied Strike", owner: nil, source: .armor,
                 required: [ComboIngredient(.exact(.heal)), ComboIngredient(.anyStrike)],
                 damage: 16, heal: 14,
                 flavor: "Bind the wound, then get back to work."),
        ComboDef(id: "shr_coveredAdvance", name: "Covered Advance", owner: nil, source: .armor,
                 required: [ComboIngredient(.exact(.block)), ComboIngredient(.anyStrike)],
                 damage: 14, shield: 10,
                 flavor: "Put the shield where the answer will come from, then answer."),
        ComboDef(id: "shr_slipAndCut", name: "Slip and Cut", owner: nil, source: .armor,
                 required: [ComboIngredient(.exact(.evade)), ComboIngredient(.anyStrike)],
                 damage: 18, dodgeCharges: 1,
                 flavor: "They cannot hit what they cannot find."),
    ]

    // MARK: - Crit imbue tiers

    /// How much crit an imbue adds at each tier, and what it costs to buy.
    static func imbueAmount(_ rarity: Rarity) -> Double {
        switch rarity {
        case .common: 0.06
        case .uncommon: 0.10
        case .rare: 0.15
        case .signature: 0.22
        }
    }
}

