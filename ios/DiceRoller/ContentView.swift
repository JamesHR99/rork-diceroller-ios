import SwiftUI

/// Root router between the voyage's screens. The Duat river scene sits behind
/// every one of them, so the barque never stops travelling.
struct ContentView: View {
    @State private var game = GameManager()

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            DuatSceneView(
                gate: game.gate,
                waterline: 0.56,
                speed: game.screen == .battle ? 0.45 : 1,
                dim: sceneDim,
                discGlow: game.discGlow,
                showsBarque: !stagesOwnBarque
            )
            .animation(.easeInOut(duration: 1.2), value: game.gate)

            switch game.screen {
            case .title:
                TitleView()
                    .transition(.opacity)
            case .tutorial:
                TutorialView()
                    .transition(.opacity)
            case .chart:
                NightChartView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            case .battle:
                BattleView()
                    .transition(.asymmetric(insertion: .scale(scale: 1.04).combined(with: .opacity), removal: .opacity))
            case .reward:
                RewardView()
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            case .shop:
                ShopView()
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            case .event:
                EventView()
                    .transition(.opacity)
            case .rest:
                RestView()
                    .transition(.opacity)
            case .gameOver(let won):
                GameOverView(won: won)
                    .transition(.opacity)
            }

            if let selection = game.pendingSelection {
                SelectionOverlayView(selection: selection)
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .zIndex(10)
            }

            if game.isPaused {
                PauseView()
                    .transition(.opacity)
                    .zIndex(25)
            }

            if let gate = game.crossedGate, game.screen == .chart {
                GateTitleCardView(gate: gate) {
                    game.crossedGate = nil
                }
                .zIndex(20)
            }

            // Everything — scene and UI alike — is painted on one sheet of
            // papyrus; the grain ties the whole game together.
            PaperGrain()
                .ignoresSafeArea()
                .zIndex(30)
        }
        .environment(game)
        .animation(.easeInOut(duration: 0.35), value: game.screen)
        .animation(.easeInOut(duration: 0.25), value: game.pendingSelection)
        .animation(.easeInOut(duration: 0.25), value: game.isPaused)
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onAppear { Audio.shared.play(music) }
        .onChange(of: game.screen) { old, _ in
            Audio.shared.play(music)
            // A change of screen passes like a page turning — but not into or
            // out of the title, where the theme's own entrance carries it.
            if old != .title, game.screen != .title {
                Audio.shared.play(.uiTransition)
            }
        }
    }

    /// Which of the four tracks belongs under the screen that is up. The
    /// serpent-lords and a god's Trial get the heavier bed; everything quiet
    /// shares the drifting river.
    private var music: MusicTrack {
        switch game.screen {
        case .title, .tutorial, .gameOver:
            return .title
        case .battle:
            guard let battle = game.battle else { return .battle }
            let isBoss = game.activeNode?.isBoss == true
                || battle.enemies.contains { $0.def.isBoss }
            return (isBoss || battle.trialAccepted) ? .boss : .battle
        default:
            return .river
        }
    }

    /// Screens that stage their own hull, close up and lit for the moment.
    /// The river stops drawing its own the whole time one of these is up, so
    /// there is never a second barque drifting behind the one you are on.
    private var stagesOwnBarque: Bool {
        switch game.screen {
        case .title, .tutorial, .battle, .rest, .shop, .gameOver: true
        default: false
        }
    }

    /// How much the river is pushed back behind whatever screen is up.
    private var sceneDim: Double {
        switch game.screen {
        case .title: 0.05
        case .tutorial: 0.5
        // The chart is read, not watched — the river drops well back so the
        // route markers are the brightest thing on screen.
        case .chart: 0.55
        case .battle: 0.16
        case .gameOver: 0.28
        default: 0.52
        }
    }
}

/// The card that names a new gate as the barque passes under its pylons.
struct GateTitleCardView: View {
    let gate: Gate
    let onFinish: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [gate.skyTop.opacity(0.94), gate.skyHorizon.opacity(0.86), gate.skyTop.opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            HStack(spacing: 28) {
                pylon
                VStack(spacing: 10) {
                    Text(gate.ordinal.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .kerning(4)
                        .foregroundStyle(gate.accent)

                    Text(gate.name.uppercased())
                        .font(.fantasy(38, weight: .black))
                        .kerning(6)
                        .foregroundStyle(
                            LinearGradient(colors: [Theme.parchment, Theme.gold],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    HieroglyphBand(tint: Theme.gold, height: 10, opacity: 0.6)
                        .frame(width: 260)

                    Text(gate.arrival)
                        .font(.fantasy(13, weight: .medium))
                        .italic()
                        .foregroundStyle(Theme.parchmentDim)
                        .multilineTextAlignment(.center)

                    Text("Hours \(gate.hours.lowerBound)–\(gate.hours.upperBound)")
                        .font(.system(size: 10, weight: .black))
                        .kerning(2)
                        .foregroundStyle(gate.accent.opacity(0.85))
                }
                pylon
            }
            .scaleEffect(shown ? 1 : 0.9)
            .opacity(shown ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { shown = true }
            Haptics.medium()
            Audio.shared.play(.gate)
            Task {
                try? await Task.sleep(for: .milliseconds(2400))
                dismiss()
            }
        }
    }

    private var pylon: some View {
        Image(systemName: gate.symbol)
            .font(.system(size: 34, weight: .black))
            .foregroundStyle(gate.accent)
            .shadow(color: gate.accent.opacity(0.8), radius: 18)
            .frame(width: 60, height: 150)
            .background(
                LinearGradient(colors: [gate.bank.opacity(0.9), gate.bank.opacity(0.4)],
                               startPoint: .top, endPoint: .bottom),
                in: .rect(cornerRadius: 6)
            )
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1))
    }

    private func dismiss() {
        guard shown else { return }
        withAnimation(.easeOut(duration: 0.35)) { shown = false }
        Task {
            try? await Task.sleep(for: .milliseconds(340))
            onFinish()
        }
    }
}

#Preview {
    ContentView()
}
