import SwiftUI

/// Dawn or Devoured. Either the sun breaks the horizon with the barque sailing
/// into it, or the disc goes black and the water closes over it.
struct GameOverView: View {
    let won: Bool
    @Environment(GameManager.self) private var game
    @State private var appeared = false
    @State private var showRecords = false
    @State private var sunRise = false

    private var accent: Color { game.heroClass?.accent ?? Theme.ember }

    var body: some View {
        ZStack {
            endingScene

            HStack(spacing: 24) {
                verdictColumn
                    .frame(maxWidth: 320)

                VStack(spacing: 10) {
                    panelToggle

                    Group {
                        if showRecords {
                            LeaderboardView(records: game.leaderboard, highlightID: game.latestRecordID)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        } else {
                            statsPanel
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                    }
                    .padding(14)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .duatPanel(tint: won ? Theme.gold : Theme.blood, cornerRadius: 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)

                    Button {
                        game.returnToTitle()
                    } label: {
                        Text(won ? "Sail Again Tonight" : "Try Again Tomorrow Night")
                            .font(.fantasy(17, weight: .bold))
                            .foregroundStyle(Theme.bg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(
                                LinearGradient(colors: [Theme.gold, accent], startPoint: .top, endPoint: .bottom),
                                in: .capsule
                            )
                            .shadow(color: accent.opacity(0.5), radius: 14, y: 4)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .frame(maxWidth: 400)
                .padding(.vertical, 14)
            }
            .padding(.horizontal, 26)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showRecords)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.6)) { sunRise = true }
            won ? Haptics.success() : Haptics.failure()
        }
    }

    // MARK: - The ending

    /// The dawn breaking, or the river closing over the disc.
    private var endingScene: some View {
        ZStack {
            if won {
                // Sun climbing out of the water behind the barque.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.parchment, Theme.sunGold, Theme.ember.opacity(0.55), .clear],
                            center: .center, startRadius: 4, endRadius: 240
                        )
                    )
                    .frame(width: 420, height: 420)
                    .offset(y: sunRise ? 130 : 320)
                    .blur(radius: 6)

                LinearGradient(
                    colors: [.clear, Theme.sunGold.opacity(0.18), Theme.ember.opacity(0.10)],
                    startPoint: .top, endPoint: .bottom
                )
            } else {
                RadialGradient(colors: [Theme.blood.opacity(0.20), .clear],
                               center: .center, startRadius: 20, endRadius: 480)
                LinearGradient(colors: [.black.opacity(0.55), .clear, .black.opacity(0.75)],
                               startPoint: .top, endPoint: .bottom)
            }

            VStack {
                Spacer()
                BarqueView(gate: won ? .reeds : .coils, width: 460, discGlow: won ? 1 : 0.08)
                    .opacity(won ? 0.85 : 0.30)
                    .grayscale(won ? 0 : 0.7)
                    .offset(y: won ? (sunRise ? 70 : 110) : 132)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Verdict

    private var verdictColumn: some View {
        VStack(spacing: 10) {
            Image(systemName: won ? "sun.horizon.fill" : "sun.dust.fill")
                .font(.system(size: 46))
                .foregroundStyle(won ? Theme.sunGold : Theme.blood)
                .shadow(color: (won ? Theme.sunGold : Theme.blood).opacity(0.75), radius: 24)
                .scaleEffect(appeared ? 1 : 0.4)

            Text(won ? "DAWN" : "DEVOURED")
                .font(.fantasy(won ? 40 : 32, weight: .black))
                .foregroundStyle(
                    LinearGradient(colors: won ? [Theme.parchment, Theme.sunGold] : [Theme.parchment, Theme.blood],
                                   startPoint: .top, endPoint: .bottom)
                )
                .kerning(8)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            HieroglyphBand(tint: won ? Theme.gold : Theme.blood, height: 9, opacity: 0.55)
                .frame(width: 240)

            Text(won
                 ? "Apep sinks. The barque clears the twelfth gate and Ra climbs into the morning. The world gets another day because you stood on that deck."
                 : deathLine)
                .font(.paper(13))
                .italic()
                .foregroundStyle(Theme.parchmentDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            hourBanner
        }
    }

    private var deathLine: String {
        "The disc goes out in the \(Voyage.ordinal(game.currentHour)) Hour and the water closes over it. Somewhere ahead, Apep is still waiting."
    }

    /// How far into the night this voyage reached, and where it placed.
    private var hourBanner: some View {
        VStack(spacing: 3) {
            Text(won ? "THE NIGHT SURVIVED" : "THE HOUR YOU FELL")
                .font(.system(size: 9, weight: .black))
                .kerning(1.6)
                .foregroundStyle(Theme.parchmentDim)

            Text(won ? "ALL TWELVE HOURS" : "\(Voyage.ordinal(game.currentHour).uppercased()) HOUR")
                .font(.fantasy(21, weight: .black))
                .foregroundStyle(Theme.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(won ? "Gate of Coils · cleared" : Gate.forHour(game.currentHour).name)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Gate.forHour(game.currentHour).accent)

            Text(rankLine)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(game.latestRank == 1 ? Theme.gold : Theme.parchmentDim)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .duatPanel(tint: won ? Theme.gold : Theme.blood, cornerRadius: 16, showsBand: false)
        .padding(.top, 4)
    }

    private var rankLine: String {
        guard let rank = game.latestRank else {
            return "Outside your top \(LeaderboardStore.maxEntries)"
        }
        if rank == 1 { return "DEEPEST VOYAGE YET" }
        return "Personal best #\(rank)"
    }

    // MARK: - Panels

    private var panelToggle: some View {
        HStack(spacing: 4) {
            toggleTab(title: "THIS VOYAGE", icon: "chart.bar.fill", active: !showRecords) {
                showRecords = false
            }
            toggleTab(title: "RECORDS", icon: "hourglass", active: showRecords) {
                showRecords = true
            }
        }
        .padding(3)
        .background(Theme.bg.opacity(0.75), in: .capsule)
    }

    private func toggleTab(title: String, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.light()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .kerning(1)
            }
            .foregroundStyle(active ? Theme.bg : Theme.parchmentDim)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(active ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Color.clear), in: .capsule)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var statsPanel: some View {
        VStack(spacing: 8) {
            statRow(icon: "hourglass", label: "Hours cleared",
                    value: "\(game.hoursCleared)/\(Voyage.totalHours)", tint: Theme.gold)
            statRow(icon: "flame.fill", label: "Damage dealt", value: "\(game.totalDamage)", tint: Theme.ember)
            statRow(icon: "link", label: "Combos landed", value: "\(game.totalCombos)", tint: Theme.gold)
            statRow(icon: "sparkles", label: "Critical dice", value: "\(game.totalCrits)", tint: Theme.gold)
            statRow(icon: "dice.fill", label: "Dice carried", value: "\(game.diceCount)/\(Loadout.maxDice)", tint: Theme.steel)
            statRow(icon: game.heroClass?.symbol ?? "person.fill", label: "Demigod",
                    value: game.heroClass?.name ?? "—", tint: accent)
            if let followed = game.followedDeities.first, followed.count > 0 {
                statRow(icon: followed.deity.symbol, label: "Closest god",
                        value: "\(followed.deity.name) ×\(followed.count)", tint: followed.deity.tint)
            }
            if let best = game.bestRecord {
                Divider().background(Theme.parchmentDim.opacity(0.2))
                statRow(icon: "crown.fill", label: "Deepest ever",
                        value: best.sawDawn ? "Dawn · \(best.className)" : "\(best.hourLabel) · \(best.className)",
                        tint: Theme.gold)
            }
        }
    }

    private func statRow(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim)
            Spacer()
            Text(value)
                .font(.fantasy(14, weight: .bold))
                .foregroundStyle(Theme.parchment)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
