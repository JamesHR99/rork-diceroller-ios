import SwiftUI

/// The six faces of a die drawn as a row of little tiles, with gold notches
/// on any face that has been imbued with extra crit. A claimed die tints its
/// tiles with the patron god's colour.
struct DieStripView: View {
    let die: Die
    var tileSize: CGFloat = 24
    var showCrit: Bool = true
    var critBonus: Double = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(die.faces) { face in
                FaceTileView(face: face, size: tileSize, critBonus: critBonus,
                             showCrit: showCrit, patron: die.patron)
            }
        }
    }
}

/// A single face tile: icon, imbue notches, and optional crit percentage.
/// A patron god's claim rings the tile in their colour; plain faces stay quiet.
struct FaceTileView: View {
    let face: DieFace
    var size: CGFloat = 24
    var critBonus: Double = 0
    var showCrit: Bool = true
    var isSelected: Bool = false
    /// The god who claims the die this face sits on, if any.
    var patron: Deity? = nil

    private var chance: Double { min(DieFace.critCap, face.critChance + critBonus) }

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: face.kind.symbol)
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundStyle(patron == nil ? AnyShapeStyle(face.kind.tint) : AnyShapeStyle(
                    LinearGradient(colors: [face.kind.tint, Theme.gold],
                                   startPoint: .top, endPoint: .bottom)
                ))
                .frame(width: size, height: size)
                .background(
                    patron == nil
                        ? AnyShapeStyle(Theme.bgElevated)
                        : AnyShapeStyle(RadialGradient(colors: [patron!.tint.opacity(0.32), Theme.bgElevated],
                                                       center: .center, startRadius: 0, endRadius: size)),
                    in: .rect(cornerRadius: size * 0.24)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24)
                        .strokeBorder(
                            isSelected ? Theme.gold : ringStyle.color,
                            lineWidth: isSelected ? 2 : ringStyle.width
                        )
                )
                .shadow(color: patron?.tint.opacity(0.55) ?? .clear, radius: size * 0.2)
                .overlay(alignment: .topTrailing) {
                    if face.isImbued {
                        HStack(spacing: 1) {
                            ForEach(0..<min(face.imbueTiers, 3), id: \.self) { _ in
                                Circle()
                                    .fill(Theme.gold)
                                    .frame(width: size * 0.11, height: size * 0.11)
                            }
                        }
                        .offset(x: -2, y: 2)
                    }
                }

            if showCrit {
                Text("\(Int(chance * 100))%")
                    .font(.system(size: max(7, size * 0.28), weight: .bold).monospacedDigit())
                    .foregroundStyle(face.isImbued ? Theme.gold : Theme.parchmentDim.opacity(0.8))
            }
        }
    }

    /// A claimed die rings its faces in the patron's colour; plain faces stay quiet.
    private var ringStyle: (color: Color, width: CGFloat) {
        if isSelected { return (Theme.gold, 2) }
        if let patron { return (patron.tint.opacity(0.9), 1.5) }
        if face.isImbued { return (Theme.gold.opacity(0.7), 1.4) }
        return (face.kind.tint.opacity(0.28), 1)
    }
}

/// A compact recipe row of combo ingredient icons, with quantities.
struct ComboRecipeView: View {
    let combo: ComboDef
    var tileSize: CGFloat = 22

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(combo.required.enumerated()), id: \.offset) { index, ingredient in
                HStack(spacing: 1) {
                    Image(systemName: ingredient.pattern.symbol)
                        .font(.system(size: tileSize * 0.45, weight: .bold))
                        .foregroundStyle(ingredient.pattern.isWildcard ? Theme.parchmentDim : ingredient.pattern.tint)
                        .frame(width: tileSize, height: tileSize)
                        .background(Theme.bgElevated, in: .rect(cornerRadius: 5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(
                                    ingredient.pattern.tint.opacity(ingredient.pattern.isWildcard ? 0.5 : 0.35),
                                    style: StrokeStyle(lineWidth: 1, dash: ingredient.pattern.isWildcard ? [2.5, 2.5] : [])
                                )
                        )

                    if ingredient.count > 1 {
                        Text("×\(ingredient.count)")
                            .font(.system(size: tileSize * 0.38, weight: .black).monospacedDigit())
                            .foregroundStyle(Theme.parchment)
                    }
                }

                if index < combo.required.count - 1 {
                    Image(systemName: "plus")
                        .font(.system(size: tileSize * 0.32, weight: .bold))
                        .foregroundStyle(Theme.parchmentDim.opacity(0.4))
                }
            }
        }
    }
}

/// Health / gold / dice readout used on the chart, Ferryman and omen screens.
struct RunStatusBar: View {
    let game: GameManager
    /// Drops the class pill so the bar fits alongside the night dial.
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            pill(icon: "heart.fill", text: "\(game.currentHP)/\(game.maxHP)", tint: Theme.blood)
            pill(icon: "circle.hexagongrid.fill", text: "\(game.gold)", tint: Theme.gold)
            pill(icon: "dice.fill", text: "\(game.diceCount)/\(Loadout.maxDice)", tint: Theme.steel)
            if let hero = game.heroClass, !compact {
                pill(icon: hero.symbol, text: hero.name, tint: hero.accent)
            }
        }
        .fixedSize()
    }

    private func pill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 11, weight: .black).monospacedDigit())
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Theme.bgElevated, in: .capsule)
        .overlay(Capsule().strokeBorder(tint.opacity(0.25), lineWidth: 1))
    }
}
