import SwiftUI

/// The lever you pull to start the turn: a carved basalt housing, a gold
/// collar, and a lotus knob on a shaft that slams down and springs back when
/// it is pulled. It is the loudest control on the deck on purpose — the whole
/// turn starts here.
struct RollLeverButton: View {
    var height: CGFloat
    let action: () -> Void

    @State private var pulled = false
    @State private var glow = false

    /// A housing too short for the full lever — knob, glyph and word stacked
    /// at full size need about 118pt.
    private var compact: Bool { height < 118 }

    private var glyphSize: CGFloat {
        compact ? max(18, min(30, height - 46)) : 34
    }

    var body: some View {
        Button {
            Haptics.medium()
            withAnimation(.spring(response: 0.16, dampingFraction: 0.5)) { pulled = true }
            action()
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.spring(response: 0.42, dampingFraction: 0.55)) { pulled = false }
            }
        } label: {
            ZStack {
                housing

                // The lever is cut to the housing it is given. On a short
                // landscape screen the knob is dropped and the glyph shrinks
                // rather than letting the stack spill out over the tray
                // heading and the stamina rail below it.
                VStack(spacing: compact ? 2 : 5) {
                    if !compact { knob }
                    DuatIcon(name: DuatArt.interactionRoll, size: glyphSize)
                        .shadow(color: Theme.ember.opacity(0.7), radius: glow ? 12 : 5)
                    Text("ROLL")
                        .font(.fantasy(compact ? 14 : 17, weight: .black))
                        .kerning(compact ? 1.2 : 2)
                        .foregroundStyle(
                            LinearGradient(colors: [Theme.parchment, Theme.gold],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .black.opacity(0.8), radius: 2, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.vertical, compact ? 4 : 8)
                .frame(width: 104, height: height)
                .clipped()
            }
            .frame(width: 104, height: height)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }

    /// The carved housing: painted paper over basalt, gold collar, lit lip.
    private var housing: some View {
        ZStack {
            PapyrusSurface(ground: .card, tint: Theme.bgElevated, strength: 0.6, shade: 0.42)
                .clipShape(.rect(cornerRadius: 18))

            LinearGradient(
                colors: [Theme.ember.opacity(glow ? 0.26 : 0.14), .clear, Color.black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(.rect(cornerRadius: 18))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(colors: [Theme.gold, Theme.goldDeep.opacity(0.5)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .inset(by: 4)
                .strokeBorder(Theme.rule.opacity(0.3), lineWidth: 0.8)
        )
        .goldCorners(size: 15, inset: 3, opacity: 0.7)
        .shadow(color: Theme.ember.opacity(glow ? 0.5 : 0.28), radius: 16)
        .shadow(color: .black.opacity(0.6), radius: 10, y: 5)
    }

    /// The lotus knob riding its shaft. The shaft compresses as the lever is
    /// pulled, so the pull has real travel rather than a colour change.
    private var knob: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(
                    RadialGradient(colors: [Theme.gold, Theme.goldDeep],
                                   center: .topLeading, startRadius: 1, endRadius: 22)
                )
                .frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(Theme.parchment.opacity(0.5), lineWidth: 1))
                .shadow(color: Theme.gold.opacity(0.7), radius: 7)

            Capsule()
                .fill(
                    LinearGradient(colors: [Theme.goldDeep, Theme.bronze.opacity(0.6)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 6, height: pulled ? 3 : 15)
        }
        .offset(y: pulled ? 10 : 0)
    }
}

/// The deck's own button: a slab of carved stone with the painted plate laid
/// over it, a gold rim and corner ornaments. Used for the controls that must
/// read as buttons at a glance — commit and freeze.
struct DeckButtonSurface: View {
    var tone: DuatArt.ButtonTone = .primary
    var state: DuatArt.ButtonState = .normal
    var rim: Color = Theme.gold
    var cornerRadius: CGFloat = 13
    /// Turned up while the button is the one thing you should be looking at.
    var emphasis: Double = 0

    var body: some View {
        ZStack {
            PapyrusSurface(ground: .card, tint: Theme.bgElevated, strength: 0.55, shade: 0.4)
                .clipShape(.rect(cornerRadius: cornerRadius))

            DuatImage(name: DuatArt.button(tone, state), fit: .stretch)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(.rect(cornerRadius: cornerRadius))

            // A lit top edge so the slab has relief even where the painted
            // plate is flat.
            LinearGradient(
                colors: [Theme.parchment.opacity(0.12), .clear, Color.black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(.rect(cornerRadius: cornerRadius))
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(colors: [rim.opacity(0.9), rim.opacity(0.35)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.6
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .inset(by: 3)
                .strokeBorder(rim.opacity(0.2), lineWidth: 0.8)
        )
        .shadow(color: rim.opacity(0.25 + 0.4 * emphasis), radius: 8 + 10 * emphasis)
        .shadow(color: .black.opacity(0.55), radius: 8, y: 4)
        .allowsHitTesting(false)
    }
}
