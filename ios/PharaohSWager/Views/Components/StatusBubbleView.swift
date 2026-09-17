import SwiftUI

/// The bubble that opens beside a tapped status badge: what the status is,
/// what it is doing to whoever wears it, and its live numbers.
///
/// Deliberately a small pinned bubble rather than a sheet or a card — you tap
/// a badge mid-fight to answer one question, and tapping anywhere puts it away.
struct StatusBubbleView: View {
    let status: LiveStatus
    /// Which way the tail points — up when the bubble hangs below the badge.
    var pointsUp: Bool = true

    private var kind: StatusKind { status.kind }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            header

            Text(kind.summary(onSelf: status.onSelf))
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.parchment.opacity(0.92))
                .lineSpacing(1.5)
                .fixedSize(horizontal: false, vertical: true)

            GoldRule(height: 4, opacity: 0.5)

            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(status.readout.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 6) {
                        Text(line.label.uppercased())
                            .font(.system(size: 9, weight: .black))
                            .kerning(0.5)
                            .foregroundStyle(Theme.parchmentDim)
                            .frame(width: 96, alignment: .leading)
                        Text(line.value)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.parchment.opacity(0.95))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(11)
        .frame(width: 268, alignment: .leading)
        .background {
            PapyrusSurface(ground: .card, tint: Theme.bgCard, strength: 0.75, shade: 0.3)
                .clipShape(.rect(cornerRadius: 13))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(kind.tint.opacity(0.6), lineWidth: 1.4)
        )
        .overlay(alignment: pointsUp ? .top : .bottom) {
            // A small tail so the bubble reads as belonging to the badge that
            // opened it rather than floating loose over the deck.
            Triangle()
                .fill(Theme.bgCard)
                .frame(width: 13, height: 8)
                .rotationEffect(.degrees(pointsUp ? -90 : 90))
                .offset(y: pointsUp ? -6 : 6)
        }
        .shadow(color: .black.opacity(0.7), radius: 16, y: pointsUp ? 6 : -6)
        .shadow(color: kind.tint.opacity(0.3), radius: 10)
    }

    private var header: some View {
        HStack(spacing: 7) {
            PharaohSWagerSymbol(art: kind.art, fallback: kind.fallbackSymbol, size: 20, tint: kind.tint)
                .frame(width: 28, height: 28)
                .background(kind.tint.opacity(0.16), in: .rect(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(kind.tint.opacity(0.5), lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(kind.name.uppercased())
                    .font(.fantasy(16, weight: .black))
                    .kerning(1.2)
                    .foregroundStyle(kind.tint)

                Text(status.onSelf ? "Riding you" : "Riding the creature")
                    .font(.system(size: 9, weight: .black))
                    .kerning(0.6)
                    .foregroundStyle(Theme.parchmentDim)
            }

            Spacer(minLength: 0)

            if let patron = kind.patron {
                PharaohSWagerSymbol(art: patron.artName, fallback: patron.symbol, size: 15, tint: patron.tint)
                    .frame(width: 22, height: 22)
                    .background(patron.tint.opacity(0.14), in: .circle)
            }
        }
    }
}

/// The same bubble, cut for one of Ptah's Chisels. A Chisel's rule is only
/// legible on the card you originally took it from, so the copper marks beside
/// the turn count open this instead.
struct ChiselBubbleView: View {
    let def: ChiselDef
    var isArmed: Bool = false
    /// Which way the tail points — up when the bubble hangs below the mark.
    var pointsUp: Bool = true

    private var chisel: ChiselDef { def }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                PharaohSWagerSymbol(art: chisel.artName, fallback: "hammer.fill",
                           size: 20, tint: Theme.ptahCopper)
                    .frame(width: 28, height: 28)
                    .background(Theme.ptahCopper.opacity(0.16), in: .rect(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(Theme.ptahCopper.opacity(0.5), lineWidth: 1))

                VStack(alignment: .leading, spacing: 1) {
                    Text(chisel.name.uppercased())
                        .font(.fantasy(16, weight: .black))
                        .kerning(1.2)
                        .foregroundStyle(Theme.ptahCopper)
                    Text(chisel.isOptional
                         ? (isArmed ? "Armed on a chain this turn" : "Armed per action")
                         : "Always at work")
                        .font(.system(size: 9, weight: .black))
                        .kerning(0.6)
                        .foregroundStyle(Theme.parchmentDim)
                }

                Spacer(minLength: 0)
            }

            Text(chisel.detail)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.parchment.opacity(0.92))
                .lineSpacing(1.5)
                .fixedSize(horizontal: false, vertical: true)

            GoldRule(height: 4, opacity: 0.5)

            Text(chisel.example)
                .font(.system(size: 11, weight: .semibold))
                .italic()
                .foregroundStyle(Theme.gold.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .frame(width: 268, alignment: .leading)
        .background {
            PapyrusSurface(ground: .card, tint: Theme.bgCard, strength: 0.75, shade: 0.3)
                .clipShape(.rect(cornerRadius: 13))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(Theme.ptahCopper.opacity(0.6), lineWidth: 1.4)
        )
        .overlay(alignment: pointsUp ? .top : .bottom) {
            Triangle()
                .fill(Theme.bgCard)
                .frame(width: 13, height: 8)
                .rotationEffect(.degrees(pointsUp ? -90 : 90))
                .offset(y: pointsUp ? -6 : 6)
        }
        .shadow(color: .black.opacity(0.7), radius: 16, y: pointsUp ? 6 : -6)
        .shadow(color: Theme.ptahCopper.opacity(0.3), radius: 10)
    }
}
