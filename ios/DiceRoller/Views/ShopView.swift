import SwiftUI

/// The Ferryman: a hooded boatman who comes alongside and trades in gold.
/// His stock is rolled fresh for your class and climbs with the hour.
///
/// Landscape layout: boatman, purse and the Push Off action sit in a fixed left
/// rail; his shelf scrolls across the whole right side at full height.
struct ShopView: View {
    @Environment(GameManager.self) private var game
    @State private var showInfo = false
    @State private var drift = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            rail
            shelf
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ferrymanBackdrop)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) { drift = true }
        }
        .sheet(isPresented: $showInfo) {
            if let loadout = game.loadout {
                InfoSheetView(loadout: loadout, classID: game.classID, critBonus: game.critBonus,
                              maxStamina: game.effectiveMaxStamina, drawnDieIDs: [])
            }
        }
    }

    // MARK: - Left rail

    private var rail: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "ferry.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.gold)
                    .shadow(color: Theme.gold.opacity(0.6), radius: 10)

                CarvedTitle(text: "The Ferryman", size: 15, kerning: 2.2)
            }

            Text(game.statusMessage ?? "\"Name yourself, and the price is fair.\"")
                .font(.paper(11))
                .italic()
                .foregroundStyle(game.statusMessage == nil ? Theme.parchmentDim : Theme.gold)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Stock rolled for a \(game.heroClass?.name ?? "demigod").")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
                RunStatusBar(game: game, compact: true)
                Spacer(minLength: 0)
            }

            NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared, compact: true)

            Spacer(minLength: 6)

            Button { showInfo = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("CODEX")
                        .font(.system(size: 9.5, weight: .black))
                        .kerning(1.2)
                }
                .foregroundStyle(Theme.gold)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Theme.bgElevated.opacity(0.9), in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                game.leaveEncounter()
            } label: {
                Text("Push Off")
                    .font(.fantasy(16, weight: .bold))
                    .foregroundStyle(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(colors: [Theme.gold, Theme.ember], startPoint: .top, endPoint: .bottom),
                        in: .capsule
                    )
                    .shadow(color: Theme.ember.opacity(0.4), radius: 12, y: 3)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .frame(width: 212, alignment: .leading)
        .frame(maxHeight: .infinity)
    }

    // MARK: - The shelf

    @ViewBuilder
    private var shelf: some View {
        if game.shopStock.isEmpty {
            VStack {
                Spacer()
                Text("The boat is empty. He pushes off without a word.")
                    .font(.paper(15))
                    .italic()
                    .foregroundStyle(Theme.parchmentDim)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(game.shopStock) { offer in
                        OfferCardView(
                            offer: offer,
                            isSelected: false,
                            affordable: game.gold >= offer.price,
                            width: 158
                        ) {
                            game.purchase(offer)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .scrollClipDisabled()
            .frame(maxWidth: .infinity, maxHeight: 340)
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    /// A second, smaller skiff drifting alongside the barque.
    private var ferrymanBackdrop: some View {
        ZStack {
            RadialGradient(colors: [Theme.gold.opacity(0.13), .clear],
                           center: .leading, startRadius: 30, endRadius: 540)

            VStack {
                Spacer()
                HStack {
                    ZStack(alignment: .bottom) {
                        BarqueView(gate: game.gate, width: 220, discGlow: 0.15, animated: false)
                            .opacity(0.45)
                        // The hooded figure at the tiller.
                        Image(systemName: "figure.stand")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(Theme.bg)
                            .shadow(color: Theme.gold.opacity(0.5), radius: 14)
                            .offset(y: -30)
                    }
                    .offset(x: drift ? -10 : 10, y: 54)
                    Spacer()
                }
                .padding(.leading, 24)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
