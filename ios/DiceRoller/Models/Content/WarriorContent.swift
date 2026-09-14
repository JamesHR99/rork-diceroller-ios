import Foundation

/// Warrior: longsword and plate. Heavy, committed swings behind a shield that
/// stays until it breaks.
enum WarriorContent {
    // MARK: - Starting gear

    /// Sword die: 3× Overhead Swing, 2× Side Swing, 1× Block.
    static func swordDie(rarity: Rarity = .common, name: String = "Longsword") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.overhead, .overhead, .overhead, .sideSwing, .sideSwing, .block])
    }

    /// Plate die: 4× Block, 1× Heal, 1× Focus.
    static func armorDie(rarity: Rarity = .common, name: String = "Plate Armour") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.block, .block, .block, .block, .heal, .focus])
    }

    /// Opening blade three: wide swings and shields — Riposte fuel.
    static func siegeAxe(rarity: Rarity = .common) -> Die {
        Die(name: "Siege Axe", slot: .weapon, rarity: rarity,
            faces: [.overhead, .overhead, .sideSwing, .sideSwing, .block, .block])
    }

    /// Opening blade four: pure swing weight — Blood Tide fuel.
    static func boardingMaul(rarity: Rarity = .common) -> Die {
        Die(name: "Boarding Maul", slot: .weapon, rarity: rarity,
            faces: [.overhead, .overhead, .overhead, .sideSwing, .sideSwing, .sideSwing])
    }

    /// Opening armour three: bronze and breath — Second Wind fuel.
    static func bronzeAegis(rarity: Rarity = .common) -> Die {
        Die(name: "Bronze Aegis", slot: .armor, rarity: rarity,
            faces: [.block, .block, .block, .heal, .heal, .focus])
    }

    static func weapon() -> GearPiece {
        GearPiece(name: "Longsword", symbol: "arrow.down.circle.fill", slot: .weapon,
                  dice: [swordDie(), swordDie(), siegeAxe(), boardingMaul()])
    }

    static func armor() -> GearPiece {
        GearPiece(name: "Plate Armour", symbol: "shield.fill", slot: .armor,
                  dice: [armorDie(), bronzeAegis()])
    }

    // MARK: - Combos

    static let combos: [ComboDef] = [
        // Weapon — momentum and mixed swings
        ComboDef(id: "war_crushingBlow", name: "Crushing Blow", owner: "warrior", source: .weapon,
                 required: [ComboIngredient(.exact(.overhead), 2)], damage: 30,
                 flavor: "Both hands, all your weight, straight down."),
        ComboDef(id: "war_wideSweep", name: "Wide Sweep", owner: "warrior", source: .weapon,
                 required: [ComboIngredient(.exact(.sideSwing), 2)], damage: 24, stagger: 0.25,
                 flavor: "A hip-high arc that clears the whole line."),
        ComboDef(id: "war_earthshaker", name: "Earthshaker", owner: "warrior", source: .weapon,
                 required: [ComboIngredient(.exact(.overhead), 3)], damage: 46, stagger: 0.4,
                 flavor: "Three hammer-falls. The ground remembers."),
        ComboDef(id: "war_riposte", name: "Riposte", owner: "warrior", source: .armor,
                 required: [ComboIngredient(.exact(.block), 2)], shield: 20, reflect: 0.5,
                 flavor: "Catch it, turn it, give it back."),
        ComboDef(id: "war_secondWind", name: "Second Wind", owner: "warrior", source: .armor,
                 required: [ComboIngredient(.exact(.heal)), ComboIngredient(.exact(.block))],
                 heal: 12, shield: 10,
                 flavor: "Armour holds, lungs fill, you stand taller."),
        ComboDef(id: "war_executioner", name: "Executioner", owner: "warrior", source: .weapon,
                 required: [ComboIngredient(.anySwing, 2), ComboIngredient(.anyStrike)],
                 damage: 44, scalesWithWounds: true,
                 flavor: "The wounded do not get to leave."),

        // Signatures
        ComboDef(id: "war_warlordsAnswer", name: "Warlord's Answer", owner: "warrior", source: .armor,
                 required: [ComboIngredient(.anySwing, 3), ComboIngredient(.exact(.block))],
                 damage: 58, shield: 14, stagger: 0.35,
                 flavor: "Call them in, eat the blow, and take the whole line apart."),
        ComboDef(id: "war_bloodTide", name: "Blood Tide", owner: "warrior", source: .weapon,
                 required: [ComboIngredient(.anySwing, 4)], damage: 68, lifesteal: true,
                 flavor: "Four falls of steel. The floor turns red."),
    ]

    // MARK: - Offer pools

    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Iron Broadsword", slot: .weapon, rarity: rarity,
                     faces: [.overhead, .overhead, .sideSwing, .sideSwing, .block, .block]), "Crushing Blow · Wide Sweep"),
                (Die(name: "Banded Mail", slot: .armor, rarity: rarity,
                     faces: [.block, .block, .block, .heal, .heal, .focus]), "Riposte · Second Wind"),
            ]
        case .uncommon:
            [
                (Die(name: "Warblade", slot: .weapon, rarity: rarity,
                     faces: [.overhead, .overhead, .overhead, .sideSwing, .sideSwing, .sideSwing]), "Blood Tide · Earthshaker"),
                (Die(name: "Guardian's Plate", slot: .armor, rarity: rarity,
                     faces: [.block, .block, .block, .block, .heal, .heal]), "Riposte · Warlord's Answer"),
            ]
        case .rare:
            [
                (Die(name: "Executioner's Edge", slot: .weapon, rarity: rarity,
                     faces: [.overhead, .overhead, .overhead, .overhead, .sideSwing, .block]), "Earthshaker · Executioner"),
                (Die(name: "Bastion Harness", slot: .armor, rarity: rarity,
                     faces: [.block, .block, .block, .block, .block, .heal]), "Riposte · Warlord's Answer"),
            ]
        case .signature:
            [
                (Die(name: "Cyclone Greatsword", slot: .weapon, rarity: rarity,
                     faces: [.overhead, .sideSwing, .overhead, .sideSwing, .overhead, .sideSwing]), "Blood Tide — pure swing mixing"),
                (Die(name: "Warlord's Bulwark", slot: .armor, rarity: rarity,
                     faces: [.block, .block, .block, .block, .block, .block]), "Riposte — the wall made dice"),
            ]
        }
    }

    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.sideSwing, "Wide Sweep · Executioner"), (.block, "Riposte")]
        case .uncommon: [(.overhead, "Crushing Blow · Earthshaker"), (.heal, "Second Wind")]
        case .rare: [(.overhead, "Earthshaker · Blood Tide"), (.block, "Riposte · Warlord's Answer")]
        case .signature: [(.sideSwing, "Blood Tide"), (.overhead, "Earthshaker · Executioner")]
        }
    }

    static let imbueName = "Grindstone Oil"
    static let imbueSymbol = "hammer.fill"
}
