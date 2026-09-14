import Foundation

/// The relics the river gives up. Each one is a three-die set for the item
/// slot with a distinct character, drawn from the shared item and utility
/// faces so every class's item combos stay live.
enum RelicContent {
    /// Burn and blast — the Detonate route.
    static let brazierOfTheDawn = RelicDef(
        id: "brazierOfTheDawn", name: "Brazier of the Dawn", symbol: "flame.circle.fill",
        rarity: .rare,
        blurb: "Coals stolen from Ra's own brazier. Everything it touches goes up.",
        dice: [
            [.bomb, .bomb, .bomb, .energize, .heal, .evade],
            [.bomb, .bomb, .evade, .evade, .energize, .heal],
            [.bomb, .heal, .heal, .energize, .evade, .heal],
        ]
    )

    /// Venom that works turn after turn — the Venom Coat route.
    static let vialOfTheNile = RelicDef(
        id: "vialOfTheNile", name: "Vial of the Nile", symbol: "drop.triangle.fill",
        rarity: .rare,
        blurb: "River water steeped with everything the current has carried down.",
        dice: [
            [.poison, .poison, .poison, .heal, .energize, .evade],
            [.poison, .poison, .heal, .heal, .heal, .evade],
            [.poison, .bomb, .heal, .energize, .evade, .heal],
        ]
    )

    /// Guards and mends — the wall route.
    static let wardOfBes = RelicDef(
        id: "wardOfBes", name: "Ward of Bes", symbol: "shield.fill",
        rarity: .rare,
        blurb: "The household god's own amulet. Nothing crosswise gets past it.",
        dice: [
            [.block, .block, .block, .heal, .evade, .energize],
            [.block, .block, .block, .heal, .heal, .evade],
            [.block, .block, .block, .heal, .heal, .energize],
        ]
    )

    /// Focus and energy — the engine route.
    static let eyeOfHorus = RelicDef(
        id: "eyeOfHorus", name: "Eye of Horus", symbol: "eye.fill",
        rarity: .rare,
        blurb: "It sees the turn before this one. Stamina gathers where it looks.",
        dice: [
            [.focus, .focus, .energize, .energize, .evade, .evade],
            [.focus, .energize, .energize, .heal, .heal, .evade],
            [.focus, .focus, .evade, .evade, .heal, .heal],
        ]
    )

    /// Evasion and grey air — the untouchable route.
    static let ferrymansToll = RelicDef(
        id: "ferrymansToll", name: "The Ferryman's Toll", symbol: "cloud.fog.fill",
        rarity: .rare,
        blurb: "Coins for the crossing, and the grey mist they are handed through.",
        dice: [
            [.evade, .evade, .evade, .evade, .energize, .heal],
            [.evade, .evade, .evade, .evade, .heal, .energize],
            [.evade, .evade, .evade, .heal, .heal, .heal],
        ]
    )

    /// Restoration — the long-night route.
    static let canopicHeart = RelicDef(
        id: "canopicHeart", name: "Canopic Heart", symbol: "heart.circle.fill",
        rarity: .rare,
        blurb: "A preserved heart that never learned to stop beating.",
        dice: [
            [.heal, .heal, .heal, .heal, .heal, .energize],
            [.heal, .heal, .heal, .heal, .evade, .evade],
            [.heal, .heal, .heal, .block, .energize, .evade],
        ]
    )

    static let relics: [RelicDef] = [
        brazierOfTheDawn, vialOfTheNile, wardOfBes,
        eyeOfHorus, ferrymansToll, canopicHeart,
    ]
}
