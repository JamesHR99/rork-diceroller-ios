import SwiftUI

/// The six faces of a die drawn as a row of little tiles, with gold notches
/// on any face that has been imbued with extra crit.
struct DieStripView: View {
    let die: Die
    var tileSize: CGFloat = 24
    var showCrit: Bool = true
    var critBonus: Double = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(die.faces) { face in
                FaceTileView(face: face, size: tileSize, critBonus: critBonus, showCrit: showCrit)
            }
        }
    }
}

/// A single face tile: icon, imbue notches, and optional crit percentage.
struct FaceTileView: View {
    let face: DieFace
    var size: CGFloat = 24
    var critBonus: Double = 0
    var showCrit: Bool = true
    var isSelected: Bool = false

    private var chance: Double { min(DieFace.critCap, face.critChance + critBonus) }

    private var deity: Deity? { face.mark?.deity }

    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: face.kind.symbol)
                    .font(.system(size: size * 0.46, weight: .bold))
                    .foregroundStyle(deity == nil ? AnyShapeStyle(face.kind.tint) : AnyShapeStyle(
                        LinearGradient(colors: [face.kind.tint, Theme.gold],
                                       startPoint: .top, endPoint: .bottom)
                    ))
                    .frame(width: size, height: size)
                    .background(
                        deity == nil
                            ? AnyShapeStyle(Theme.bgElevated)
                            : AnyShapeStyle(RadialGradient(colors: [deity!.tint.opacity(0.32), Theme.bgElevated],
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
                    .shadow(color: deity?.tint.opacity(0.55) ?? .clear, radius: size * 0.2)

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
            .overlay(alignment: .topLeading) {
                // Depth notches: how deep the mark runs on this face.
                if let mark = face.mark {
                    HStack(spacing: 1) {
                        ForEach(0..<mark.depth.rawValue, id: \.self) { _ in
                            Circle()
                                .fill(mark.deity.tint)
                                .overlay(Circle().strokeBorder(Theme.bg.opacity(0.7), lineWidth: 0.5))
                                .frame(width: size * 0.13, height: size * 0.13)
                        }
                    }
                    .padding(2)
                }
            }

            if showCrit {
                Text("\(Int(chance * 100))%")
                    .font(.system(size: max(7, size * 0.28), weight: .bold).monospacedDigit())
                    .foregroundStyle(face.isImbued ? Theme.gold : Theme.parchmentDim.opacity(0.8))
            }
        }
    }

    /// A gift rings the face in its god's colour and thickens with depth; plain
    /// faces stay quiet.
    private var ringStyle: (color: Color, width: CGFloat) {
        if isSelected { return (Theme.gold, 2) }
        if let mark = face.mark {
            return (mark.deity.tint.opacity(0.9), mark.isFinalForm ? 2.2 : 1.3 + CGFloat(mark.depth.rawValue) * 0.2)
        }
        if face.isImbued { return (Theme.gold.opacity(0.7), 1.4) }
        return (face.kind.tint.opacity(0.28), 1)
    }
}

/// A compact recipe row of combo pattern icons.
struct ComboRecipeView: View {
    let combo: ComboDef
    var tileSize: CGFloat = 22

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(combo.required.enumerated()), id: \.offset) { index, pattern in
                Image(systemName: pattern.symbol)
                    .font(.system(size: tileSize * 0.45, weight: .bold))
                    .foregroundStyle(pattern.isDivineSlot ? pattern.tint : (pattern.isWildcard ? Theme.parchmentDim : pattern.tint))
                    .frame(width: tileSize, height: tileSize)
                    .background(Theme.bgElevated, in: .rect(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(
                                pattern.isWildcard && !pattern.isDivineSlot
                                    ? Theme.parchmentDim.opacity(0.5)
                                    : pattern.tint.opacity(pattern.isDivineSlot ? 0.75 : 0.35),
                                style: StrokeStyle(lineWidth: 1, dash: pattern.isWildcard ? [2.5, 2.5] : [])
                            )
                    )

                if index < combo.required.count - 1 {
                    Image(systemName: "chevron.compact.right")
                        .font(.system(size: tileSize * 0.4, weight: .bold))
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
