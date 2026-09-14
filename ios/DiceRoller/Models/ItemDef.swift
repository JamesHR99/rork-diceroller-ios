import Foundation

/// A carryable item. Items always come with a fixed pair of dice whose faces
/// are set by the item type, and every class shares their combos.
struct ItemDef: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let rarity: Rarity
    let blurb: String
    let faces: [FaceKind]

    /// Two fresh dice for the item slot.
    func makePiece() -> GearPiece {
        GearPiece(
            name: name,
            symbol: symbol,
            slot: .item,
            dice: [
                Die(name: name, slot: .item, rarity: rarity, faces: faces),
                Die(name: name, slot: .item, rarity: rarity, faces: faces),
            ]
        )
    }
}
