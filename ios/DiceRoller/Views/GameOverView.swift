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
                            .foregroundStyle(Theme.parchment)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background {
                                DuatImage(name: DuatArt.button(.primary, won ? .highlighted : .normal),
                                          fit: .stretch)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .clipShape(.rect(cornerRadius: 14))
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
                // Ra's disc climbing out of the water behind the barque.
                ZStack {
                    DuatImage(name: "duat_environment_sun_halo", height: 400, fit: .fit)
                        .opacity(0.55)
                    DuatImage(name: "duat_environment_sun_bright", height: 190, fit: .fit)
                        .shadow(color: Theme.sunGold.opacity(0.8), radius: 60)
                }
                .offset(y: sunRise ? 130 : 320)

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
            DuatImage(name: won ? "duat_environment_sun_bright" : "duat_environment_sun_extinguished",
                      height: 68, fit: .fit)
                .shadow(color: (won ? Theme.sunGold : Theme.blood).opacity(0.75), radius: 24)
                .scaleEffect(appeared ? 1 : 0.4)

            // The verdict on its painted banner.
            Text(won ? "DAWN" : "DEVOURED")
                .font(.fantasy(won ? 38 : 30, weight: .black))
                .foregroundStyle(
                    LinearGradient(colors: won ? [Theme.parchment, Theme.sunGold] : [Theme.parchment, Theme.blood],
                                   startPoint: .top, endPoint: .bottom)
                )
                .kerning(8)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 34)
                .padding(.vertical, 16)
                .background {
                    DuatImage(name: won ? DuatArt.bannerVictory : DuatArt.bannerDefeat, fit: .stretch)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

            WingedDivider(height: 22, opacity: 0.8)
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
            toggleTab(title: "THIS VOYAGE", art: DuatArt.utilityCodex, active: !showRecords) {
                showRecords = false
            }
            toggleTab(title: "RECORDS", art: DuatArt.utilityRecords, active: showRecords) {
                showRecords = true
            }
        }
        .padding(3)
        .background(Theme.bg.opacity(0.75), in: .capsule)
    }

    /// A painted codex tab — the selected drawing when it holds the panel.
    private func toggleTab(title: String, art: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.light()
        } label: {
            HStack(spacing: 5) {
                DuatIcon(name: art, size: 17)
                Text(title)
                    .font(.system(size: 12, weight: .black))
                    .kerning(1)
                    .foregroundStyle(active ? Theme.parchment : Theme.parchmentDim)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background {
                DuatImage(name: active ? DuatArt.tabSelected : DuatArt.tabUnselected, fit: .stretch)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(active ? 1 : 0.55)
            }
            .clipShape(.capsule)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var statsPanel: some View {
        VStack(spacing: 8) {
            statRow(DuatArt.nightCurrent, "hourglass", "Hours cleared",
                    "\(game.hoursCleared)/\(Voyage.totalHours)", Theme.gold)
            statRow(DuatArt.Status.burn, "flame.fill", "Damage dealt", "\(game.totalDamage)", Theme.ember)
            statRow(DuatArt.chainConnector, "link", "Combos landed", "\(game.totalCombos)", Theme.gold)
            statRow(DuatArt.Status.critical, "sparkles", "Critical dice", "\(game.totalCrits)", Theme.gold)
            statRow(DuatArt.classSigil(game.classID) ?? "", game.heroClass?.symbol ?? "person.fill",
                    "Demigod", game.heroClass?.name ?? "—", accent)
            if let followed = game.followedDeities.first, followed.dice > 0 {
                statRow(followed.deity.artName ?? "", followed.deity.symbol, "Closest god",
                        "\(followed.deity.name) ×\(followed.dice)", followed.deity.tint)
            }
            if let best = game.bestRecord {
                GoldRule(height: 4, opacity: 0.5)
                statRow(DuatArt.Status.champion, "crown.fill", "Deepest ever",
                        best.sawDawn ? "Dawn · \(best.className)" : "\(best.hourLabel) · \(best.className)",
                        Theme.gold)
            }
        }
    }

    private func statRow(_ art: String, _ fallback: String, _ label: String,
                         _ value: String, _ tint: Color) -> some View {
        HStack {
            DuatSymbol(art: art, fallback: fallback, size: 16, tint: tint)
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
