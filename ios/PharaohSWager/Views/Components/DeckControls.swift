import SwiftUI

/// The lever you pull to start the turn: a carved basalt housing, a gold
/// collar, and a lotus knob on a shaft that slams down and springs back when
/// it is pulled. It is the loudest control on the deck on purpose — the whole
/// turn starts here.
struct RollLeverButton: View {
    var height: CGFloat
    var width: CGFloat = 104
    var isEnabled = true
    var isRolling = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var pulled: Bool { isRolling && !reduceMotion }
    private var glow: Bool { isEnabled }

    /// A housing too short for the full lever — knob, glyph and word stacked
    /// at full size need about 118pt.
    private var compact: Bool { height < 118 }

    private var glyphSize: CGFloat {
        compact ? max(18, min(30, height - 46)) : 34
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                housing

                // The lever is cut to the housing it is given. On a short
                // landscape screen the knob is dropped and the glyph shrinks
                // rather than letting the stack spill out over the tray
                // heading and the stamina rail below it.
                VStack(spacing: compact ? 2 : 5) {
                    if !compact { knob }
                    PharaohSWagerIcon(name: PharaohSWagerArt.interactionRoll, size: glyphSize)
                        .shadow(color: Theme.ember.opacity(0.7), radius: glow ? 12 : 5)
                    Text(isEnabled ? "ROLL" : (isRolling ? "SPIN" : "READY"))
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
                .frame(width: width, height: height)
                .clipped()
            }
            .frame(width: width, height: height)
            .opacity(isEnabled || isRolling ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.8), value: isRolling)
        .accessibilityLabel("Roll dice")
        .accessibilityValue(isRolling ? "Rolling" : (isEnabled ? "Ready to roll" : "Roll complete"))
        .accessibilityIdentifier("battle.roll")
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
        // The painted lever housing already includes its ornamental edge.
        // A second SwiftUI rim made the control look boxed in bright yellow.
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
/// over it. The painted asset supplies its own edge and corner ornaments, so
/// code adds depth and emphasis without drawing a second yellow border.
struct DeckButtonSurface: View {
    var tone: PharaohSWagerArt.ButtonTone = .primary
    var state: PharaohSWagerArt.ButtonState = .normal
    var rim: Color = Theme.gold
    var cornerRadius: CGFloat = 13
    /// Turned up while the button is the one thing you should be looking at.
    var emphasis: Double = 0

    var body: some View {
        ZStack {
            PapyrusSurface(ground: .card, tint: Theme.bgElevated, strength: 0.55, shade: 0.4)
                .clipShape(.rect(cornerRadius: cornerRadius))

            PharaohSWagerImage(name: PharaohSWagerArt.button(tone, state), fit: .stretch)
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
        .shadow(color: rim.opacity(0.25 + 0.4 * emphasis), radius: 8 + 10 * emphasis)
        .shadow(color: .black.opacity(0.55), radius: 8, y: 4)
        .allowsHitTesting(false)
    }
}
