import Foundation

/// Items and item combos, shared by every class.
enum SharedContent {
    // MARK: - Items

    static let items: [ItemDef] = [
        ItemDef(id: "healingPotion", name: "Healing Potion", symbol: "cross.vial.fill", rarity: .common,
                blurb: "Four draughts of restoration. The deepest healing in one glass.",
                faces: [.heal, .heal, .heal, .heal, .energize, .evade]),
        ItemDef(id: "smokeBomb", name: "Smoke Bomb", symbol: "cloud.fog.fill", rarity: .common,
                blurb: "Evasion in a jar. Stack the puffs and blows stop finding you.",
                faces: [.evade, .evade, .evade, .evade, .energize, .heal]),
        ItemDef(id: "poisonVial", name: "Poison Vial", symbol: "drop.triangle.fill", rarity: .uncommon,
                blurb: "Venom that eats away for turns on end.",
                faces: [.poison, .poison, .poison, .heal, .energize, .evade]),
        ItemDef(id: "explosive", name: "Explosive Charge", symbol: "burst.fill", rarity: .uncommon,
                blurb: "Heavy burst damage. Three charges, one very bad day for someone.",
                faces: [.bomb, .bomb, .bomb, .energize, .heal, .evade]),
        ItemDef(id: "alchemistKit", name: "Alchemist's Kit", symbol: "flask.fill", rarity: .rare,
                blurb: "Bombs, venom and draughts in one satchel.",
                faces: [.bomb, .bomb, .poison, .poison, .heal, .energize]),
        ItemDef(id: "warlockCharm", name: "Warlock's Charm", symbol: "sparkle", rarity: .rare,
                blurb: "Bottled momentum — energy and escape when you need them.",
                faces: [.energize, .energize, .evade, .evade, .heal, .bomb]),
        ItemDef(id: "phoenixFlask", name: "Phoenix Flask", symbol: "flame.circle.fill", rarity: .signature,
                blurb: "Fire and life in the same glass. The best of both item routes.",
                faces: [.bomb, .bomb, .heal, .heal, .evade, .energize]),
    ]

    static func item(id: String) -> ItemDef? {
        items.first { $0.id == id }
    }

    static func items(upTo rarity: Rarity) -> [ItemDef] {
        let pool = items.filter { $0.rarity <= rarity }
        return pool.isEmpty ? items : pool
    }

    // MARK: - Item combos (every class)

    static let combos: [ComboDef] = [
        ComboDef(id: "itm_detonate", name: "Detonate", owner: nil, source: .item,
                 required: [ComboIngredient(.exact(.bomb), 2)], damage: 36,
                 burnAmount: 5, burnTurns: 2,
                 flavor: "Two charges, one fuse, a lot of noise."),
        ComboDef(id: "itm_venomCoat", name: "Venom Coat", owner: nil, source: .item,
                 required: [ComboIngredient(.exact(.poison), 2)], poisonAmount: 8, poisonTurns: 3,
                 flavor: "Two drops make a death sentence."),
        ComboDef(id: "itm_steadiedStrike", name: "Steadied Strike", owner: nil, source: .item,
                 required: [ComboIngredient(.exact(.heal)), ComboIngredient(.anyStrike)],
                 damage: 16, heal: 14,
                 flavor: "Bind the wound, then get back to work."),
        ComboDef(id: "itm_breachAndStrike", name: "Breach and Strike", owner: nil, source: .item,
                 required: [ComboIngredient(.exact(.bomb)), ComboIngredient(.anyStrike)],
                 damage: 28, pierce: 0.5,
                 flavor: "Blow the guard open and put something through the hole."),
        ComboDef(id: "itm_envenomedEdge", name: "Envenomed Edge", owner: nil, source: .item,
                 required: [ComboIngredient(.exact(.poison)), ComboIngredient(.anyStrike)],
                 damage: 18, poisonAmount: 6, poisonTurns: 3,
                 flavor: "Coat the edge, then find the soft part."),
        ComboDef(id: "itm_blindingBlast", name: "Blinding Blast", owner: nil, source: .item,
                 required: [ComboIngredient(.exact(.evade)), ComboIngredient(.exact(.bomb))],
                 damage: 26, evadePercent: 20,
                 flavor: "They cannot hit what they cannot see."),
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
