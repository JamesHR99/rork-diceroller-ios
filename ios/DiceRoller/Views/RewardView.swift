import SwiftUI

/// Spoils on the water's edge. A god rises out of the river on a shaft of light
/// and lays their favours out as cards. A Shrine on the Bank uses the same
/// stage with a wider altar.
///
/// Laid out for landscape: the god, the run readout and the two actions live in
/// a fixed left rail, so the three cards get the whole right side of the screen
/// and nothing is ever pushed off the bottom edge.
struct RewardView: View {
    @Environment(GameManager.self) private var game
    @State private var selectedID: UUID?
    @State private var risen = false
    @State private var shimmer = false

    private var deity: Deity? { game.visitingDeity }

    private var accent: Color { deity?.tint ?? Theme.gold }

    /// The altar never holds more than three cards, so they all fit on screen.
    private var offers: [Offer] { Array(game.rewardOffers.prefix(3)) }

    /// Spoils on the bank can draw more than one god's hand.
    private var hasSeveralGods: Bool {
        Set(offers.compactMap(\.deity)).count > 1
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            rail
            altar
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RadialGradient(colors: [accent.opacity(0.20), .clear],
                               center: .leading, startRadius: 20, endRadius: 560)
                LinearGradient(colors: [accent.opacity(shimmer ? 0.10 : 0.03), .clear],
                               startPoint: .leading, endPoint: .trailing)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) { risen = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { shimmer = true }
        }
    }

    // MARK: - Left rail

    private var rail: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: game.isShrine ? "building.columns.fill" : "sparkles")
                    .font(.system(size: 15))
                    .foregroundStyle(accent)
                    .shadow(color: accent.opacity(0.6), radius: 9)

                CarvedTitle(text: game.isShrine
                            ? "Shrine on the Bank"
                            : (deity == nil ? "Spoils on the Bank"
                              : (hasSeveralGods ? "The Gods Attend" : "A God Attends")),
                            size: 14, kerning: 1.8)
            }

            Text(game.isShrine
                 ? "Choose one favour from the altar."
                 : (game.statusMessage ?? (deity == nil
                     ? "One relic may join the voyage."
                     : "One blessing may join the voyage.")))
                .font(.paper(10.5))
                .italic()
                .foregroundStyle(accent)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                RunStatusBar(game: game, compact: true)
                Spacer(minLength: 0)
            }

            NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared, compact: true)

            Spacer(minLength: 6)

            sigil

            Spacer(minLength: 6)

            actions
        }
        .frame(width: 212, alignment: .leading)
        .frame(maxHeight: .infinity)
    }

    private var actions: some View {
        VStack(spacing: 6) {
            Button {
                if let offer = game.rewardOffers.first(where: { $0.id == selectedID }) {
                    game.claimReward(offer)
                }
            } label: {
                Text(selectedID == nil
                     ? "Choose a Favour"
                     : (deity == nil ? "Claim the Spoils" : "Accept the Blessing"))
                    .font(.fantasy(15, weight: .bold))
                    .foregroundStyle(selectedID == nil ? Theme.parchmentDim : Theme.bg)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        selectedID == nil
                            ? AnyShapeStyle(Theme.bgCard.opacity(0.9))
                            : AnyShapeStyle(LinearGradient(colors: [Theme.parchment, accent],
                                                           startPoint: .top, endPoint: .bottom)),
                        in: .capsule
                    )
                    .shadow(color: selectedID == nil ? .clear : accent.opacity(0.4), radius: 12, y: 3)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(selectedID == nil)

            Button {
                game.skipReward()
            } label: {
                Text(game.isShrine ? "Offer 15 gold" : "Take 15 gold")
                    .font(.fantasy(12.5, weight: .bold))
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Theme.bgCard.opacity(0.9), in: .capsule)
                    .overlay(Capsule().strokeBorder(Theme.parchmentDim.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    // MARK: - The altar

    /// Three cards side by side, sharing the right side evenly.
    private var altar: some View {
        HStack(alignment: .top, spacing: 10) {
            ForEach(Array(offers.enumerated()), id: \.element.id) { index, offer in
                OfferCardView(
                    offer: offer,
                    isSelected: selectedID == offer.id,
                    affordable: true,
                    width: nil
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedID = offer.id
                    }
                    Haptics.medium()
                }
                .opacity(risen ? 1 : 0)
                .offset(y: risen ? 0 : 26)
                .animation(.spring(response: 0.5, dampingFraction: 0.8)
                    .delay(0.28 + Double(index) * 0.08), value: risen)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 340)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    // MARK: - The god

    @ViewBuilder
    private var sigil: some View {
        if let deity {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 9) {
                    ZStack {
                        // Shaft of light coming up off the water.
                        Capsule()
                            .fill(LinearGradient(colors: [accent.opacity(0.30), .clear],
                                                 startPoint: .center, endPoint: .bottom))
                            .frame(width: 64, height: 110)
                            .blur(radius: 12)
                            .offset(y: 26)

                        Circle()
                            .fill(RadialGradient(colors: [accent.opacity(0.35), .clear],
                                                 center: .center, startRadius: 2, endRadius: 40))
                            .frame(width: 78, height: 78)

                        PortraitMedallionView(art: CharacterArt.god(deity),
                                              fallbackSymbol: deity.symbol,
                                              tint: accent,
                                              diameter: 72)
                            .shadow(color: accent.opacity(shimmer ? 0.7 : 0.35), radius: shimmer ? 16 : 8)
                    }
                    .frame(width: 74, height: 74)
                    .scaleEffect(risen ? 1 : 0.7)

                    VStack(alignment: .leading, spacing: 4) {
                        CartoucheView(text: deity.name, tint: accent, size: 13)

                        Text(deity.domain.uppercased())
                            .font(.system(size: 8.5, weight: .black))
                            .kerning(1.8)
                            .foregroundStyle(accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }

                Text(deity.greeting)
                    .font(.paper(13))
                    .italic()
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                devotionStrip(deity)
            }
            .opacity(risen ? 1 : 0)
        }
    }

    private func devotionStrip(_ deity: Deity) -> some View {
        let count = game.devotion[deity] ?? 0
        let next = deity.passives.first { count < $0.threshold }
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index < count ? accent : Theme.bgCard)
                            .frame(width: 6, height: 6)
                    }
                }
                Text(count == 0
                     ? "No faces yet"
                     : "\(count) face\(count == 1 ? "" : "s") of \(deity.name)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if let line = currentPassive(deity, count) {
                Text(line)
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(accent.opacity(0.9))
                    .lineLimit(2)
            }

            if let next {
                Text("→ \(next.threshold): \(next.text)")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(Theme.parchmentDim.opacity(0.9))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgElevated.opacity(0.85), in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accent.opacity(0.3), lineWidth: 1))
    }

    private func currentPassive(_ deity: Deity, _ count: Int) -> String? {
        deity.passives.last { count >= $0.threshold }?.text
    }
}
