import Foundation

/// Warrior: longsword and plate armour. Heavy, committed swings and a wall of guard.
enum WarriorContent {
    // MARK: - Starting gear

    /// Sword die: 3× Overhead Swing, 2× Side Swing, 1× Parry.
    static func swordDie(rarity: Rarity = .common, name: String = "Longsword") -> Die {
        Die(name: name, slot: .weapon, rarity: rarity,
            faces: [.overhead, .overhead, .overhead, .sideSwing, .sideSwing, .parry])
    }

    /// Plate die: 3× Block, 1× Brace, 1× Heal, 1× Taunt.
    static func armorDie(rarity: Rarity = .common, name: String = "Plate Armour") -> Die {
        Die(name: name, slot: .armor, rarity: rarity,
            faces: [.block, .block, .block, .brace, .heal, .taunt])
    }

    /// Opening blade three: wide swings and parries — Whirlwind and Riposte fuel.
    static func siegeAxe(rarity: Rarity = .common) -> Die {
        Die(name: "Siege Axe", slot: .weapon, rarity: rarity,
            faces: [.overhead, .overhead, .sideSwing, .sideSwing, .parry, .parry])
    }

    /// Opening blade four: pure swing weight — Earthshaker and Executioner fuel.
    static func boardingMaul(rarity: Rarity = .common) -> Die {
        Die(name: "Boarding Maul", slot: .weapon, rarity: rarity,
            faces: [.overhead, .overhead, .overhead, .sideSwing, .sideSwing, .sideSwing])
    }

    /// Opening armour three: bronze and breath — carries Brace and Riposte fuel.
    static func bronzeAegis(rarity: Rarity = .common) -> Die {
        Die(name: "Bronze Aegis", slot: .armor, rarity: rarity,
            faces: [.block, .block, .brace, .heal, .taunt, .parry])
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
        ComboDef(id: "war_crushing", name: "Crushing Blow", owner: "warrior", source: .weapon,
                 required: [.exact(.overhead), .exact(.overhead)], damage: 38,
                 flavor: "Both hands, all your weight, straight down."),
        ComboDef(id: "war_wideSweep", name: "Wide Sweep", owner: "warrior", source: .weapon,
                 required: [.exact(.sideSwing), .exact(.sideSwing)], damage: 30, stagger: 0.25,
                 flavor: "A hip-high arc that clears the whole line."),
        ComboDef(id: "war_cleaving", name: "Cleaving Follow-Through", owner: "warrior", source: .weapon,
                 required: [.exact(.overhead), .exact(.sideSwing)], damage: 34, momentumNext: 12,
                 flavor: "Down, then across — the blade never stops."),
        ComboDef(id: "war_guillotine", name: "Rising Guillotine", owner: "warrior", source: .weapon,
                 required: [.exact(.sideSwing), .exact(.overhead)], damage: 36, pierce: 0.5,
                 flavor: "Sweep the guard aside, bring it down through the gap."),
        ComboDef(id: "war_shieldBash", name: "Shield Bash", owner: "warrior", source: .weapon,
                 required: [.exact(.parry), .anySwing], damage: 24, block: 12,
                 flavor: "Steel to the face, then steel to the ribs."),
        ComboDef(id: "war_riposte", name: "Riposte", owner: "warrior", source: .weapon,
                 required: [.exact(.parry), .exact(.parry)], reflect: 1.0, blocksAll: true,
                 flavor: "Catch it, turn it, give it back."),
        ComboDef(id: "war_earthshaker", name: "Earthshaker", owner: "warrior", source: .weapon,
                 required: [.exact(.overhead), .exact(.overhead), .exact(.overhead)],
                 damage: 62, stagger: 0.4,
                 flavor: "Three hammer-falls. The ground remembers."),
        ComboDef(id: "war_executioner", name: "Executioner", owner: "warrior", source: .weapon,
                 required: [.exact(.overhead), .exact(.overhead), .exact(.sideSwing)],
                 damage: 52, scalesWithWounds: true,
                 flavor: "The wounded do not get to leave."),
        ComboDef(id: "war_whirlwind", name: "Whirlwind Crush", owner: "warrior", source: .weapon,
                 required: [.exact(.overhead), .exact(.sideSwing), .exact(.overhead)],
                 damage: 72, staminaNext: 3, stagger: 0.3,
                 flavor: "Down, around, down again. Nothing stands in the circle."),

        // Armour — plate
        ComboDef(id: "war_bulwark", name: "Bulwark", owner: "warrior", source: .armor,
                 required: [.exact(.block), .exact(.block)], block: 24,
                 flavor: "Plant your feet. Become the wall."),
        ComboDef(id: "war_fortress", name: "Fortress", owner: "warrior", source: .armor,
                 required: [.exact(.block), .exact(.block), .exact(.block)],
                 reflect: 0.5, blocksAll: true,
                 flavor: "Let it come. Let it break."),
        ComboDef(id: "war_brace", name: "Brace for Impact", owner: "warrior", source: .armor,
                 required: [.exact(.brace), .exact(.block)], block: 20, carryBlock: true,
                 flavor: "Set the shoulder. Hold it there."),
        ComboDef(id: "war_secondWind", name: "Second Wind", owner: "warrior", source: .armor,
                 required: [.exact(.brace), .exact(.heal)], heal: 12, scalesWithBlock: true,
                 flavor: "Armour holds, lungs fill, you stand taller."),
        ComboDef(id: "war_drawAggro", name: "Draw Aggro", owner: "warrior", source: .armor,
                 required: [.exact(.taunt), .anySwing], damage: 22, block: 14, stagger: 0.2,
                 flavor: "Come on then. Right here."),

        // Blended — plate opening into the punish
        ComboDef(id: "war_shieldbreaker", name: "Shieldbreaker", owner: "warrior", source: .armor,
                 required: [.exact(.block), .exact(.overhead), .exact(.overhead)],
                 damage: 54, block: 10, pierce: 0.5,
                 flavor: "Take it on the plate, then break what swung."),
        ComboDef(id: "war_anvilStance", name: "Anvil Stance", owner: "warrior", source: .armor,
                 required: [.exact(.brace), .exact(.block), .anySwing],
                 damage: 34, block: 22, carryBlock: true,
                 flavor: "Set, hold, and swing from behind the wall."),
        ComboDef(id: "war_counterCharge", name: "Counter-Charge", owner: "warrior", source: .armor,
                 required: [.exact(.parry), .exact(.block), .exact(.overhead)],
                 damage: 48, stagger: 0.3, reflect: 0.4,
                 flavor: "Catch the blade, plant the foot, come back through it."),
        ComboDef(id: "war_ironLungs", name: "Iron Lungs", owner: "warrior", source: .armor,
                 required: [.exact(.taunt), .exact(.heal), .exact(.block)],
                 heal: 18, block: 20, staminaNext: 2, scalesWithBlock: true,
                 flavor: "Bellow, breathe, brace. They come to you now."),
        ComboDef(id: "war_warlordsAnswer", name: "Warlord's Answer", owner: "warrior", source: .armor,
                 required: [.exact(.taunt), .exact(.block), .exact(.overhead), .exact(.sideSwing)],
                 damage: 82, block: 14, stagger: 0.35, momentumNext: 10,
                 flavor: "Call them in, eat the blow, and take the whole line apart."),
        ComboDef(id: "war_bloodTide", name: "Blood Tide", owner: "warrior", source: .weapon,
                 required: [.anySwing, .anySwing, .anySwing, .anySwing],
                 damage: 88, staminaNext: 2, lifesteal: true,
                 flavor: "Four falls of steel. The floor turns red."),
    ]

    // MARK: - Offer pools

    static func diceOffers(_ rarity: Rarity) -> [(die: Die, hint: String)] {
        switch rarity {
        case .common:
            [
                (Die(name: "Iron Broadsword", slot: .weapon, rarity: rarity,
                     faces: [.overhead, .overhead, .sideSwing, .sideSwing, .parry, .brace]), "Cleaving Follow-Through · Wide Sweep"),
                (Die(name: "Banded Mail", slot: .armor, rarity: rarity,
                     faces: [.block, .block, .block, .brace, .heal, .taunt]), "Bulwark · Brace for Impact"),
            ]
        case .uncommon:
            [
                (Die(name: "Warblade", slot: .weapon, rarity: rarity,
                     faces: [.overhead, .overhead, .overhead, .sideSwing, .sideSwing, .sideSwing]), "Whirlwind Crush · Earthshaker"),
                (Die(name: "Guardian's Plate", slot: .armor, rarity: rarity,
                     faces: [.block, .block, .brace, .brace, .taunt, .heal]), "Fortress · Brace for Impact"),
            ]
        case .rare:
            [
                (Die(name: "Executioner's Edge", slot: .weapon, rarity: rarity,
                     faces: [.overhead, .overhead, .overhead, .overhead, .sideSwing, .parry]), "Earthshaker · Executioner"),
                (Die(name: "Bastion Harness", slot: .armor, rarity: rarity,
                     faces: [.block, .block, .block, .block, .brace, .taunt]), "Fortress · Bulwark"),
            ]
        case .signature:
            [
                (Die(name: "Cyclone Greatsword", slot: .weapon, rarity: rarity,
                     faces: [.overhead, .sideSwing, .overhead, .sideSwing, .overhead, .sideSwing]), "Whirlwind Crush — pure swing mixing"),
                (Die(name: "Warlord's Bulwark", slot: .armor, rarity: rarity,
                     faces: [.brace, .brace, .block, .block, .block, .taunt]), "Fortress · Brace for Impact"),
            ]
        }
    }

    static func faceOffers(_ rarity: Rarity) -> [(face: FaceKind, hint: String)] {
        switch rarity {
        case .common: [(.sideSwing, "Wide Sweep · Cleaving Follow-Through"), (.block, "Bulwark")]
        case .uncommon: [(.overhead, "Crushing Blow · Cleaving Follow-Through"), (.brace, "Brace for Impact")]
        case .rare: [(.overhead, "Earthshaker · Executioner"), (.parry, "Riposte · Shield Bash")]
        case .signature: [(.sideSwing, "Whirlwind Crush"), (.overhead, "Whirlwind Crush · Earthshaker")]
        }
    }

    static let imbueName = "Grindstone Oil"
    static let imbueSymbol = "hammer.fill"
}
