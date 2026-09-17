import SwiftUI

/// A carved heading: the hand-carved display face, gold leaf, with the painted
/// glyph rule inked beneath.
struct CarvedTitle: View {
    let text: String
    var size: CGFloat = 22
    var tint: Color = Theme.parchment
    var kerning: CGFloat = 4
    var showsRule: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text.uppercased())
                .font(.fantasy(size))
                .kerning(kerning)
                .foregroundStyle(
                    LinearGradient(colors: [tint, tint.opacity(0.72)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.65), radius: 0, x: 0, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if showsRule {
                GoldRule(height: 5, opacity: 0.75)
            }
        }
    }
}

/// A god's or hero's name set inside the painted cartouche loop.
struct CartoucheView: View {
    let text: String
    var tint: Color = Theme.gold
    var size: CGFloat = 12

    var body: some View {
        Text(text.uppercased())
            .font(.fantasy(size))
            .kerning(2)
            .foregroundStyle(tint)
            .padding(.horizontal, size * 1.5)
            .padding(.vertical, size * 0.42)
            .background {
                DuatImage(name: DuatArt.cartouche, fit: .stretch)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .colorMultiply(tint)
                    .allowsHitTesting(false)
            }
    }
}

/// The slim night-dial: twelve hours as a row of painted marks, filled in
/// behind you, with the gate boundaries called out.
struct NightDialView: View {
    let currentHour: Int
    let hoursCleared: Int
    var compact: Bool = false

    private var gate: Gate { Gate.forHour(currentHour) }

    var body: some View {
        HStack(spacing: compact ? 7 : 9) {
            DuatImage(name: gate.sunArt, height: compact ? 13 : 16, fit: .fit)
                .shadow(color: gate.discColor.opacity(0.8), radius: 6)

            HStack(spacing: compact ? 3 : 4) {
                ForEach(1...Voyage.totalHours, id: \.self) { hour in
                    mark(hour)
                }
            }

            if !compact {
                Text(Voyage.fullName(currentHour).uppercased())
                    .font(.system(size: 9, weight: .black))
                    .kerning(1.2)
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, compact ? 4 : 5)
        .background(Theme.bg.opacity(0.6), in: .capsule)
        .overlay(Capsule().strokeBorder(gate.accent.opacity(0.35), lineWidth: 1))
    }

    private func mark(_ hour: Int) -> some View {
        let cleared = hour <= hoursCleared
        let isNow = hour == currentHour
        let isGateEnd = hour % 4 == 0
        let tint = Gate.forHour(hour).accent
        let markSize: CGFloat = compact ? 11 : 13

        return Group {
            if isNow {
                DuatImage(name: DuatArt.nightCurrent, height: markSize * 1.15, fit: .fit)
                    .colorMultiply(Theme.parchment)
            } else if cleared {
                DuatImage(name: DuatArt.nightCleared, height: markSize, fit: .fit)
                    .colorMultiply(tint)
            } else if isGateEnd {
                DuatImage(name: DuatArt.nightBoundary, height: markSize, fit: .fit)
                    .colorMultiply(Theme.parchmentDim)
                    .opacity(0.6)
            } else {
                DuatImage(name: DuatArt.nightHour, height: markSize * 0.85, fit: .fit)
                    .colorMultiply(Theme.parchmentDim)
                    .opacity(0.45)
            }
        }
        .frame(width: compact ? 11 : 13)
        .shadow(color: isNow ? Theme.parchment.opacity(0.7) : .clear, radius: 5)
    }
}
