import Foundation

/// A relic: a named curiosity the barque fishes out of the river. Equipping
/// one fills the item slot with its three dice, each cut to the relic's own
/// character — so the choice shapes which faces can surface in your draws.
struct RelicDef: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let rarity: Rarity
    let blurb: String
    /// Face sets for the relic's three dice, in order.
    let dice: [[FaceKind]]

    /// A fresh item-slot piece carrying the relic's three dice.
    func makePiece() -> GearPiece {
        GearPiece(
            name: name,
            symbol: symbol,
            slot: .item,
            dice: dice.enumerated().map { index, faces in
                Die(name: dieName(index), slot: .item, rarity: rarity, faces: faces)
            }
        )
    }

    private func dieName(_ index: Int) -> String {
        let numerals = ["I", "II", "III"]
        let suffix = index < numerals.count ? " \(numerals[index])" : ""
        return name + suffix
    }
}
