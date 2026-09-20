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

    /// Ptah takes the whole bench when he comes: three Chisels, one taken.
    private var isForge: Bool { game.isPtahForge }

    private var accent: Color {
        isForge ? Theme.ptahCopper : (deity?.tint ?? Theme.gold)
    }

    /// The altar holds up to four cards — Ptah's Chisel card, when it turns
    /// up, takes its place beside the rest.
    private var offers: [Offer] { Array(game.rewardOffers.prefix(4)) }

    /// Spoils on the bank can draw more than one god's hand.
    private var hasSeveralGods: Bool {
        Set(offers.compactMap(\.deity)).count > 1
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 8) {
                rewardHeader
                altar
                actions
                    .frame(height: 48)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
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

    private var rewardHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            if let deity { HaloedSigilView(deity: deity, diameter: 46) }
            VStack(alignment: .leading, spacing: 3) {
                Text(isForge ? "Ptah at the Bench" : (deity?.name ?? "Spoils on the Bank"))
                    .font(.fantasy(20, weight: .bold)).foregroundStyle(accent)
                if let deity {
                    Text(deity.domain.uppercased())
                        .font(.system(size: 9, weight: .black)).foregroundStyle(accent)
                    Text(deity.greeting)
                        .font(.paper(11)).italic().foregroundStyle(Theme.parchmentDim)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(game.statusMessage ?? "Choose one favour for the voyage.")
                        .font(.paper(11)).foregroundStyle(Theme.parchmentDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let deity { patronStrip(deity).frame(width: 174) }
            VStack(spacing: 4) {
                RunStatusBar(game: game, compact: true)
                HStack {
                    NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared, compact: true)
                    PauseButton()
                }
            }
            .frame(width: 155)
        }
        .fixedSize(horizontal: false, vertical: true)
    }


    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                if let offer = game.rewardOffers.first(where: { $0.id == selectedID }) {
                    game.claimReward(offer)
                }
            } label: {
                Text(selectedID == nil
                     ? (isForge ? "Choose a Chisel" : "Choose a Favour")
                     : (isForge ? "Strike the Chisel"
                        : (deity == nil ? "Claim the Spoils" : "Accept the Blessing")))
                    .font(.fantasy(17, weight: .bold))
                    .kerning(0.8)
                    .foregroundStyle(
                        selectedID == nil
                            ? LinearGradient(colors: [Theme.parchmentDim, Theme.parchmentDim],
                                             startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Theme.parchment, Theme.gold],
                                             startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .black.opacity(0.75), radius: 2, y: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background {
                        DeckButtonSurface(tone: .primary,
                                          state: selectedID == nil ? .disabled : .highlighted,
                                          rim: selectedID == nil ? Theme.parchmentDim : accent,
                                          cornerRadius: 14,
                                          emphasis: selectedID == nil ? 0 : 1)
                    }
                    .goldCorners(size: 14, inset: 3, opacity: selectedID == nil ? 0.25 : 0.8)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(selectedID == nil)

            Button {
                game.skipReward()
                Haptics.light()
            } label: {
                HStack(spacing: 5) {
                    PharaohSWagerIcon(name: PharaohSWagerArt.currency, size: 19)
                    Text(game.isShrine ? "Offer 15 gold" : "Take 15 gold")
                        .font(.fantasy(14, weight: .bold))
                        .foregroundStyle(Theme.parchment.opacity(0.8))
                        .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background {
                    DeckButtonSurface(tone: .secondary, state: .normal, rim: Theme.gold,
                                      cornerRadius: 11)
                }
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    // MARK: - The altar

    /// All offered choices share the available width; no carousel or nested scroll.
    private var altar: some View {
        GeometryReader { proxy in
            let count = max(offers.count, 1)
            let width = max(1, (proxy.size.width - 8 - CGFloat(count - 1) * 8) / CGFloat(count))
                HStack(alignment: .top, spacing: 8) {
                    ForEach(Array(offers.enumerated()), id: \.element.id) { index, offer in
                        OfferCardView(offer: offer, isSelected: selectedID == offer.id,
                                      affordable: true, width: width, fixedPresentation: true) {
                            withAnimation(.snappy(duration: 0.18)) { selectedID = offer.id }
                            Haptics.medium()
                        }
                        .frame(height: max(1, proxy.size.height - 8))
                        .opacity(risen ? 1 : 0)
                        .offset(y: risen ? 0 : 12)
                        .animation(.easeOut(duration: 0.22).delay(Double(index) * 0.045), value: risen)
                    }
                }
                .padding(4)
        }
    }


    /// How much of this god you already carry: claimed dice, earned upgrades,
    /// and where their path stands.
    private func patronStrip(_ deity: Deity) -> some View {
        let dice = game.allDice.filter { $0.patron == deity }.count
        let earned = GodKit.upgrades(for: deity).filter { game.activeUpgrades.contains($0.id) }.count
        let capstone = GodKit.capstone(for: deity)
        let capstoneTaken = game.activeCapstone?.deity == deity
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { index in
                        PharaohSWagerImage(name: index < earned ? PharaohSWagerArt.nightCleared : PharaohSWagerArt.nightHour,
                                  height: 10, fit: .fit)
                            .colorMultiply(index < earned ? accent : Theme.parchmentDim)
                            .opacity(index < earned ? 1 : 0.35)
                    }
                }
                Text(dice == 0
                     ? "No dice claimed yet"
                     : "\(dice) claimed dice · \(earned) upgrade\(earned == 1 ? "" : "s")")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if let capstone {
                Text(capstoneTaken
                     ? "\(capstone.name) rides with you"
                     : (game.capstoneUnlocked(capstone)
                        ? "\(capstone.name) unlocked — one capstone per run"
                        : "Two upgrades unlock \(capstone.name)"))
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(capstoneTaken ? accent.opacity(0.9) : Theme.parchmentDim.opacity(0.9))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgElevated.opacity(0.85), in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accent.opacity(0.3), lineWidth: 1))
    }
}
