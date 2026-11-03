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

    private var selectedDraftDie: Offer? {
        guard !isForge, deity == nil,
              let offer = offers.first(where: { $0.id == selectedID }),
              case .die = offer.kind else { return nil }
        return offer
    }

    /// Spoils on the bank can draw more than one god's hand.
    private var hasSeveralGods: Bool {
        Set(offers.compactMap(\.deity)).count > 1
    }

    var body: some View {
        GeometryReader { proxy in
            Group {
                if game.isShrine && deity == nil {
                    shrineChooser
                } else {
                    VStack(spacing: 8) {
                        rewardHeader
                        altar
                        actions
                            .frame(height: 48)
                    }
                }
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
        .onChange(of: deity) { _, _ in selectedID = nil }
    }

    private var shrineChooser: some View {
        VStack(spacing: 7) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CHOOSE A GOD")
                        .font(.fantasy(20, weight: .bold)).foregroundStyle(Theme.gold)
                    Text("Approach a god to see their powers. You may return and compare.")
                        .font(.system(size: 11)).foregroundStyle(Theme.parchmentDim)
                }
                Spacer()
                RunStatusBar(game: game, compact: true)
                PauseButton()
            }
            GeometryReader { proxy in
                let width = max(1, (proxy.size.width - 16) / 3)
                let height = max(1, (proxy.size.height - 8) / 2)
                VStack(spacing: 8) {
                    ForEach(0..<2) { row in
                        HStack(spacing: 8) {
                            ForEach(Array(Deity.allCases[(row * 3)..<(row * 3 + 3)])) { god in
                                shrineGodCard(god)
                                    .frame(width: width, height: height)
                            }
                        }
                    }
                }
            }
            Button("Leave the Shrine") { game.skipReward() }
                .font(.fantasy(13, weight: .bold))
                .foregroundStyle(Theme.parchmentDim)
                .frame(minHeight: 30)
        }
    }

    private func shrineGodCard(_ god: Deity) -> some View {
        let owned = game.boons(of: god)
        return Button {
            game.chooseShrineDeity(god)
            Haptics.light()
        } label: {
            HStack(spacing: 8) {
                PharaohSWagerSymbol(art: god.artName, fallback: god.symbol, size: 30, tint: god.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(god.name.uppercased())
                        .font(.fantasy(14, weight: .bold)).foregroundStyle(god.tint)
                    Text(shrinePitch(god))
                        .font(.system(size: 10)).foregroundStyle(Theme.parchment)
                        .lineLimit(2).minimumScaleFactor(0.8)
                    Text(owned.isEmpty ? "NO POWERS YET" : "\(owned.count) POWER\(owned.count == 1 ? "" : "S") EQUIPPED")
                        .font(.system(size: 8, weight: .black)).foregroundStyle(Theme.parchmentDim)
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .duatPanel(tint: god.tint, cornerRadius: 12, showsBand: false)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityIdentifier("shrine.god.\(god.rawValue)")
    }

    private func shrinePitch(_ god: Deity) -> String {
        switch god {
        case .ra: "Burn foes and unleash solar attacks."
        case .sobek: "Bleed foes and turn healing into attacks."
        case .anubis: "Build Judgement, then strike health."
        case .bes: "Keep Guard and counterattack."
        case .horus: "Prepare dice, reroll and pierce."
        case .bastet: "Evade, mark and counterattack."
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
                    if let bagPreview {
                        Text(bagPreview)
                            .font(.system(size: 9.5, weight: .black).monospacedDigit())
                            .kerning(0.6)
                            .foregroundStyle(Theme.gold.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .accessibilityIdentifier("reward.bagPreview")
                    }
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

    /// Dice rewards are a deckbuilding decision, not an automatic power-up.
    /// Showing the bag before and after the pick makes the consistency cost
    /// visible at the same moment the player compares the offered faces.
    private var bagPreview: String? {
        guard !isForge, deity == nil, let loadout = game.loadout else { return nil }
        let count = loadout.diceCount
        guard let selectedID,
              let offer = game.rewardOffers.first(where: { $0.id == selectedID }),
              case .die = offer.kind else {
            return "BAG \(count) · DRAW \(BattleRules.handSize) · SKIP TO KEEP IT FOCUSED"
        }
        if loadout.isFull {
            return "BAG \(count)/\(Loadout.maxDice) · CLAIMING WILL SWAP A DIE"
        }
        return "ADD: BAG \(count) → \(count + 1) · REPLACE: BAG \(count) · DRAW \(BattleRules.handSize)"
    }


    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                if let offer = game.rewardOffers.first(where: { $0.id == selectedID }) {
                    game.claimReward(offer)
                }
            } label: {
                Text(selectedDraftDie != nil && game.loadout?.isFull == false ? "Add to Bag" : (selectedID == nil
                     ? (isForge ? "Choose a Chisel" : "Choose a Favour")
                     : (isForge ? "Strike the Chisel"
                        : (deity == nil ? "Claim the Spoils" : "Accept the Blessing"))))
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
                    .paintedContentInsets()
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

            if game.isShrine, deity != nil {
                Button {
                    game.backToShrineDeities()
                } label: {
                    Text("Other Gods")
                        .font(.fantasy(14, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background { DeckButtonSurface(tone: .secondary, state: .normal, rim: Theme.gold, cornerRadius: 11) }
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityIdentifier("shrine.back")
            }

            if let offer = selectedDraftDie, game.loadout?.isFull == false {
                Button {
                    game.replaceDraftDie(with: offer)
                } label: {
                    Text("Replace a Die")
                        .font(.fantasy(15, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .paintedContentInsets()
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background {
                            DeckButtonSurface(tone: .secondary, state: .normal, rim: Theme.gold,
                                              cornerRadius: 11)
                        }
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityIdentifier("reward.replaceDie")
            }

            Button {
                game.skipReward()
                Haptics.light()
            } label: {
                HStack(spacing: 5) {
                    PharaohSWagerIcon(name: PharaohSWagerArt.currency, size: 19)
                    Text("Skip")
                        .font(.fantasy(14, weight: .bold))
                        .foregroundStyle(Theme.parchment.opacity(0.8))
                        .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .paintedContentInsets()
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


    /// Powers carried now, with levels, so the offer is read in build context.
    private func patronStrip(_ deity: Deity) -> some View {
        let owned = game.boons(of: deity)
        return VStack(alignment: .leading, spacing: 3) {
            Text("YOUR \(deity.name.uppercased()) POWERS")
                .font(.system(size: 9, weight: .black)).foregroundStyle(accent)
            Text(owned.isEmpty ? "None yet" : owned.map { "\($0.def?.name ?? "Power") · Lv \($0.level)" }.joined(separator: "\n"))
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim)
                .lineLimit(3)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgElevated.opacity(0.85), in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accent.opacity(0.3), lineWidth: 1))
    }
}

