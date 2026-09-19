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
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 8) {
                FittingScrollColumn { rail }
                actions
            }
            .frame(width: 200)
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
                PharaohSWagerSymbol(art: isForge ? PharaohSWagerArt.upgradeHammer
                               : (game.isShrine ? StageKind.shrine.artName : deity?.artName),
                           fallback: isForge ? "hammer.fill"
                               : (game.isShrine ? "building.columns.fill" : "sparkles"),
                           size: 20,
                           tint: accent)
                    .shadow(color: accent.opacity(0.6), radius: 9)

                CarvedTitle(text: isForge
                            ? "Ptah at the Bench"
                            : (game.isShrine
                               ? "Shrine on the Bank"
                               : (deity == nil ? "Spoils on the Bank"
                                 : (hasSeveralGods ? "The Gods Attend" : "A God Attends"))),
                            size: 14, kerning: 1.8)
            }

            Text(isForge
                 ? "The craftsman lays out three Chisels. One reshapes your whole weapon — your gods are untouched."
                 : (game.isShrine
                    ? "Choose one favour from the altar."
                    : (game.statusMessage ?? (deity == nil
                        ? "One of the river's own spoils may join the voyage."
                        : "One blessing may join the voyage."))))
                .font(.paper(10.5))
                .italic()
                .foregroundStyle(accent)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                RunStatusBar(game: game, compact: true)
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared, compact: true)
                Spacer(minLength: 0)
                PauseButton()
            }

            // Chisels of Ptah carried this run, struck in his copper.
            if !game.ownedChisels.isEmpty {
                HStack(spacing: 4) {
                    ForEach(game.ownedChisels, id: \.self) { id in
                        HStack(spacing: 3) {
                            PharaohSWagerSymbol(art: PharaohSWagerArt.chisel(id),
                                       fallback: ChiselCatalog.def(id)?.symbol ?? "hammer.fill",
                                       size: 13,
                                       tint: Theme.ptahCopper)
                            Text(ChiselCatalog.def(id)?.name ?? "Chisel")
                                .font(.system(size: 8.5, weight: .black))
                                .foregroundStyle(Theme.ptahCopper)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.bg.opacity(0.7), in: .capsule)
                        .overlay(Capsule().strokeBorder(Theme.ptahCopper.opacity(0.5), lineWidth: 1))
                    }
                }
            }

            Spacer(minLength: 6)

            sigil

            Spacer(minLength: 6)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .frame(height: 52)
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

    /// Keep cards readable; smaller screens scroll the altar horizontally.
    private var altar: some View {
        GeometryReader { proxy in
            let count = max(offers.count, 1)
            let width = max(180, min(230, (proxy.size.width - 8 - CGFloat(count - 1) * 10) / CGFloat(count)))
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(Array(offers.enumerated()), id: \.element.id) { index, offer in
                        OfferCardView(offer: offer, isSelected: selectedID == offer.id,
                                      affordable: true, width: width) {
                            withAnimation(.snappy(duration: 0.18)) { selectedID = offer.id }
                            Haptics.medium()
                        }
                        .frame(height: max(240, min(334, proxy.size.height - 8)))
                        .opacity(risen ? 1 : 0)
                        .offset(y: risen ? 0 : 12)
                        .animation(.easeOut(duration: 0.22).delay(Double(index) * 0.045), value: risen)
                    }
                }
                .padding(4)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
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

                        HaloedSigilView(deity: deity, diameter: 80)
                            .shadow(color: accent.opacity(shimmer ? 0.7 : 0.35), radius: shimmer ? 16 : 8)
                    }
                    .frame(width: 80, height: 80)
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

                patronStrip(deity)
            }
            .opacity(risen ? 1 : 0)
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
