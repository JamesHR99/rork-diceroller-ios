import SwiftUI

/// A playable class. Weapon and armour are permanent; the item slot starts empty.
struct HeroClass: Identifiable, Hashable {
    let id: String
    let name: String
    let title: String
    let symbol: String
    let accentName: String
    let maxHP: Int
    let maxStamina: Int
    let weaponName: String
    let armorName: String
    let blurb: String
    let playstyle: String
    /// Beats this class shaves off every action's preparation. Agility decides
    /// *when* an action lands; stamina decides how much you can do. A Rogue
    /// guards almost immediately, a Warrior's heavy swings arrive late.
    let agility: Int
    /// The one-line read of this class's place on the clock.
    let timingIdentity: String

    var accent: Color {
        switch id {
        case "archer": Theme.ember
        case "warrior": Theme.steelBlue
        case "rogue": Theme.venom
        default: Theme.arcane
        }
    }

    var fighterSymbol: String {
        switch id {
        case "archer": "figure.archery"
        case "warrior": "figure.fencing"
        case "rogue": "figure.martial.arts"
        default: "figure.mind.and.body"
        }
    }

    /// Fresh weapon + armour for a new run. Three dice in the weapon, two in
    /// the armour — defence is something you play, not something you carry.
    var startingLoadout: Loadout {
        Loadout(weapon: startingWeapon, armor: startingArmor, item: nil)
    }

    private var startingWeapon: GearPiece {
        switch id {
        case "archer": ArcherContent.weapon()
        case "warrior": WarriorContent.weapon()
        case "rogue": RogueContent.weapon()
        default: MagicianContent.weapon()
        }
    }

    private var startingArmor: GearPiece {
        switch id {
        case "archer": ArcherContent.armor()
        case "warrior": WarriorContent.armor()
        case "rogue": RogueContent.armor()
        default: MagicianContent.armor()
        }
    }
}
