import Foundation

/// Items and item combos, shared by every class.
enum SharedContent {
    // MARK: - Items

    static let items: [ItemDef] = [
        ItemDef(id: "healingPotion", name: "Healing Potion", symbol: "cross.vial.fill", rarity: .common,
                blurb: "Two dice of restoration. Stack two Elixirs for a big draught.",
                faces: [.heal, .heal, .elixir, .elixir, .energize, .dodge]),
        ItemDef(id: "smokeBomb", name: "Smoke Bomb", symbol: "cloud.fog.fill", rarity: .common,
                blurb: "Evasion in a jar. Two Smokes and nothing touches you.",
                faces: [.smoke, .smoke, .smoke, .dodge, .energize, .heal]),
        ItemDef(id: "poisonVial", name: "Poison Vial", symbol: "drop.triangle.fill", rarity: .uncommon,
                blurb: "Venom that eats away for turns on end.",
                faces: [.poison, .poison, .poison, .elixir, .energize, .smoke]),
        ItemDef(id: "explosive", name: "Explosive Charge", symbol: "burst.fill", rarity: .uncommon,
                blurb: "Heavy burst damage. Detonate two at once and something dies.",
                faces: [.bomb, .bomb, .bomb, .energize, .heal, .smoke]),
        ItemDef(id: "alchemistKit", name: "Alchemist's Kit", symbol: "flask.fill", rarity: .rare,
                blurb: "Bombs, venom and elixirs in one satchel.",
                faces: [.bomb, .bomb, .poison, .poison, .elixir, .energize]),
        ItemDef(id: "warlockCharm", name: "Warlock's Charm", symbol: "sparkle", rarity: .rare,
                blurb: "Bottled momentum — energy and escape when you need them.",
                faces: [.energize, .energize, .smoke, .smoke, .elixir, .bomb]),
        ItemDef(id: "phoenixFlask", name: "Phoenix Flask", symbol: "flame.circle.fill", rarity: .signature,
                blurb: "Fire and life in the same glass. The best of both item combos.",
                faces: [.bomb, .bomb, .elixir, .elixir, .smoke, .energize]),
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
                 required: [.exact(.bomb), .exact(.bomb)], damage: 48,
                 burnAmount: 8, burnTurns: 2,
                 flavor: "Two charges, one fuse, a lot of noise."),
        ComboDef(id: "itm_vanish", name: "Vanish", owner: nil, source: .item,
                 required: [.exact(.smoke), .exact(.smoke)], dodge: 1, blocksAll: true,
                 flavor: "A grey bloom, and you were never there."),
        ComboDef(id: "itm_venomCoat", name: "Venom Coat", owner: nil, source: .item,
                 required: [.exact(.poison), .exact(.poison)], poisonAmount: 10, poisonTurns: 3,
                 flavor: "Two drops make a death sentence."),
        ComboDef(id: "itm_draught", name: "Great Draught", owner: nil, source: .item,
                 required: [.exact(.elixir), .exact(.elixir)], heal: 30, staminaNext: 2,
                 flavor: "Both flasks, straight down."),
        ComboDef(id: "itm_quickSip", name: "Quick Sip", owner: nil, source: .item,
                 required: [.exact(.heal), .exact(.elixir)], heal: 22,
                 flavor: "Bandage first, then the good stuff."),
        ComboDef(id: "itm_blindingBlast", name: "Blinding Blast", owner: nil, source: .item,
                 required: [.exact(.smoke), .exact(.bomb)], damage: 30, dodge: 1, stagger: 0.4,
                 flavor: "They cannot hit what they cannot see."),
        ComboDef(id: "itm_toxicBlast", name: "Toxic Blast", owner: nil, source: .item,
                 required: [.exact(.bomb), .exact(.poison)], damage: 26,
                 poisonAmount: 8, poisonTurns: 3,
                 flavor: "Shrapnel with something nasty on it."),

        // MARK: Items blended with whatever gear you carry

        ComboDef(id: "itm_breachAndStrike", name: "Breach and Strike", owner: nil, source: .item,
                 required: [.exact(.bomb), .anyStrike], damage: 38, pierce: 0.5,
                 flavor: "Blow the guard open and put something through the hole."),
        ComboDef(id: "itm_envenomedEdge", name: "Envenomed Edge", owner: nil, source: .item,
                 required: [.exact(.poison), .anyStrike], damage: 24,
                 poisonAmount: 8, poisonTurns: 3,
                 flavor: "Coat the edge, then find the soft part."),
        ComboDef(id: "itm_smokeAndSteel", name: "Smoke and Steel", owner: nil, source: .item,
                 required: [.exact(.smoke), .anyStrike], damage: 26, dodge: 1,
                 flavor: "They swing at grey air; you are already past them."),
        ComboDef(id: "itm_steadiedDraught", name: "Steadied Draught", owner: nil, source: .item,
                 required: [.exact(.elixir), .exact(.heal), .anyStrike],
                 damage: 30, heal: 22, staminaNext: 2,
                 flavor: "Drink, bind the wound, and get back to work."),
        ComboDef(id: "itm_demolition", name: "Demolition", owner: nil, source: .item,
                 required: [.exact(.bomb), .anyStrike, .anyStrike],
                 damage: 58, burnAmount: 8, burnTurns: 2, stagger: 0.3,
                 flavor: "The charge opens it. You do the rest by hand."),
        ComboDef(id: "itm_ambush", name: "Ambush", owner: nil, source: .item,
                 required: [.exact(.smoke), .anyStrike, .anyStrike],
                 damage: 52, dodge: 1, mark: 1.3,
                 flavor: "Out of the cloud, twice, and gone again."),
        ComboDef(id: "itm_alchemistsEnd", name: "Alchemist's End", owner: nil, source: .item,
                 required: [.exact(.poison), .exact(.bomb), .anyStrike, .anyStrike],
                 damage: 74, poisonAmount: 10, poisonTurns: 3, burnAmount: 8, burnTurns: 2,
                 flavor: "Venom, fire and steel, in the only order that works."),
        ComboDef(id: "itm_fortifiedGuard", name: "Fortified Guard", owner: nil, source: .item,
                 required: [.exact(.elixir), .exact(.smoke), .exact(.energize)],
                 heal: 24, dodge: 1, staminaNext: 3, blocksAll: true,
                 flavor: "Drink, vanish, and come back with your wind up."),
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
