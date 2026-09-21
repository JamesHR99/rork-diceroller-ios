import SwiftUI

/// The Night Chart. The river runs straight now: at every stop the water forks
/// into two channels and you commit to one. A gate is eight stops — three
/// encounters, its herald, three more, then its serpent-lord — and the ribbon
/// along the top shows exactly where in that shape the barque is sitting.
///
/// Channels are often dark. A dark channel says nothing about what is in it
/// until you sail in, which is what makes the fork a real decision rather than
/// a menu.
struct NightChartView: View {
    @Environment(GameManager.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rollingIDs: Set<UUID> = []
    @State private var rollFrame = 0
    @State private var rerollTask: Task<Void, Never>?
    @State private var pulse = false
    @State private var showInfo = false

    private var gate: Gate { game.gate }

    /// The channels open right now — two at an ordinary stop, one at a herald
    /// or a serpent-lord.
    private var options: [VoyageNode] { game.availableNodes }

    /// Where the next stop sits inside its gate, 0 through 7.
    private var indexInGate: Int { game.nextStage % Voyage.stagesPerGate }

    var body: some View {
        FittingScrollColumn {
            VStack(spacing: 0) {
                header
                gateRibbon
                Spacer(minLength: 0)
                channels
                Spacer(minLength: 0)
                footer
            }
        }
        .animation(.easeInOut(duration: 0.7), value: gate)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
        }
        .task(id: game.nextStage) {
            if options.count == 2 { await animateDestinations(Set(options.map(\.id))) }
        }
        .onDisappear { rerollTask?.cancel() }
        .sheet(isPresented: $showInfo) {
            if let loadout = game.loadout {
                InfoSheetView(loadout: loadout, classID: game.classID, critBonus: game.critBonus, drawnDieIDs: [],
                              hasMetTrial: game.trialUsed,
                              boons: game.equippedBoons)
            }
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    PharaohSWagerSymbol(art: gate.artName, fallback: gate.symbol, size: 20, tint: gate.accent)
                        .shadow(color: gate.accent.opacity(0.7), radius: 6)
                    CarvedTitle(text: gate.name, size: 18, kerning: 3, showsRule: false)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("HOURS \(gate.firstHour)–\(gate.lastHour)")
                        .font(.system(size: 8, weight: .black))
                        .kerning(1.2)
                        .foregroundStyle(Theme.bg)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(gate.accent.opacity(0.85), in: .capsule)
                }
                Text(instruction)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(gate.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 5) {
                RunStatusBar(game: game, compact: true)
                NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared, compact: true)
            }

            Button {
                showInfo = true
                Haptics.light()
            } label: {
                VStack(spacing: 2) {
                    PharaohSWagerIcon(name: PharaohSWagerArt.utilityCodex, size: 22)
                    Text("CODEX")
                        .font(.fantasy(11, weight: .black))
                        .kerning(0.8)
                        .foregroundStyle(Theme.parchment)
                        .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                }
                .paintedContentInsets()
                .frame(width: 76, height: 52)
                .background {
                    DeckButtonSurface(tone: .secondary, state: .normal, rim: Theme.gold,
                                      cornerRadius: 11)
                }
            }
            .buttonStyle(PressableButtonStyle())

            PauseButton()
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private var instruction: String {
        guard let first = options.first else { return gate.region }
        if options.count == 1 { return "\(first.kind.label) ahead · This encounter cannot be rerolled." }
        if !rollingIDs.isEmpty { return "The river dice are rolling…" }
        return game.canRerollDestination ? "Two destinations · Reroll either die once, or choose your route."
            : "Reroll spent · Choose one die to sail onward."
    }

    private var footer: some View {
        HStack(spacing: 12) {
            ForEach([StageKind.battle, .shrine, .ferryman, .omen, .herald], id: \.self) { kind in
                HStack(spacing: 4) {
                    PharaohSWagerSymbol(art: kind.artName, fallback: kind.symbol, size: 20, tint: kind.tint)
                    Text(kind.label)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(Theme.parchment.opacity(0.85))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.bg.opacity(0.6), in: .capsule)
            }
            Spacer()
            if let message = game.statusMessage {
                Text(message)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.gold)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
    }

    // MARK: - The gate ribbon

    /// The shape of a gate, drawn once: three encounters, the herald, three
    /// more, the serpent-lord. Stops behind the barque are struck through, the
    /// one you are choosing for glows, and the two ahead stay dim.
    private var gateRibbon: some View {
        HStack(spacing: 5) {
            ForEach(0..<Voyage.stagesPerGate, id: \.self) { index in
                ribbonBead(index)
                if index < Voyage.stagesPerGate - 1 {
                    Rectangle()
                        .fill(index < indexInGate
                              ? Theme.gold.opacity(0.55)
                              : Theme.parchmentDim.opacity(0.18))
                        .frame(height: 1.5)
                        .frame(maxWidth: 34)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .animation(.easeInOut(duration: 0.4), value: indexInGate)
    }

    private func ribbonBead(_ index: Int) -> some View {
        let kind = Voyage.spine(ofStage: index)
        let done = index < indexInGate
        let here = index == indexInGate
        let tint = kind.isForced ? kind.tint : Theme.gold
        let size: CGFloat = kind.isForced ? 30 : 22

        return VStack(spacing: 2) {
            PharaohSWagerSymbol(art: kind.artName, fallback: kind.symbol,
                       size: size * 0.66,
                       tint: here ? Theme.parchment
                           : done ? Theme.forest
                           : tint.opacity(0.55))
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .fill(here ? tint.opacity(0.32) : Theme.bg.opacity(0.7))
                        .overlay(Circle().strokeBorder(
                            here ? tint : tint.opacity(done ? 0.5 : 0.22),
                            lineWidth: here ? 2 : 1))
                }
                .shadow(color: here ? tint.opacity(pulse ? 0.8 : 0.35) : .clear,
                        radius: here ? 10 : 0)

            if kind.isForced {
                Text(kind == .boss ? "LORD" : "HERALD")
                    .font(.system(size: 7, weight: .black))
                    .kerning(0.6)
                    .foregroundStyle(here ? tint : tint.opacity(done ? 0.6 : 0.35))
            }
        }
    }

    // MARK: - The fork

    private var channels: some View {
        HStack(spacing: 18) {
            ForEach(options) { node in
                channelCard(node)
            }
        }
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: options.map(\.id))
    }

    /// One channel. A revealed channel says what it is; a dark one only says
    /// that it is dark, and finding out costs you the choice.
    private func channelCard(_ node: VoyageNode) -> some View {
        let solo = options.count == 1
        let known = node.isRevealed || node.kind.isForced
        let rolling = rollingIDs.contains(node.id)
        let tint = known ? node.kind.tint : Theme.duskViolet
        let faces: [StageKind] = [.battle, .ferryman, .omen, .shrine, .battle, .omen]
        let rollingFace = faces[rollFrame % faces.count]
        let face = rolling ? rollingFace : node.kind
        return VStack(spacing: 7) {
            Button {
                guard rollingIDs.isEmpty else { return }
                game.enter(node)
            } label: {
                VStack(spacing: 5) {
                    ZStack {
                        TurnOrderPlaque(accent: tint)
                        VStack(spacing: 4) {
                            PharaohSWagerSymbol(art: rolling || known ? face.artName : PharaohSWagerArt.interactionRoll,
                                fallback: rolling || known ? face.symbol : "questionmark", size: 47,
                                tint: rolling ? Theme.gold : tint)
                            Text(rolling ? "ROLLING" : known ? node.kind.label.uppercased() : "DARK WATER")
                                .font(.fantasy(14, weight: .black))
                                .foregroundStyle(Theme.parchment)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }.padding(10)
                        VStack {
                            HStack { Circle().frame(width: 4, height: 4); Spacer(); Circle().frame(width: 4, height: 4) }
                            Spacer()
                            HStack { Circle().frame(width: 4, height: 4); Spacer(); Circle().frame(width: 4, height: 4) }
                        }.foregroundStyle(Theme.gold).padding(10)
                    }
                    .frame(width: solo ? 112 : 104, height: solo ? 112 : 104)
                    .rotation3DEffect(.degrees(rolling && !reduceMotion ? Double(rollFrame) * 180 : 0), axis: (x: 1, y: 0.4, z: 0))
                    .rotationEffect(.degrees(rolling && !reduceMotion ? (rollFrame.isMultiple(of: 2) ? -9 : 9) : 0))
                    .scaleEffect(rolling && !reduceMotion ? 0.9 : 1)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.11), value: rollFrame)
                    Text(rolling ? "Reading the river…" : known ? node.kind.blurb : "A hidden destination. Discover it when you arrive.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.parchment)
                        .multilineTextAlignment(.center).lineLimit(2)
                        .frame(height: 28)
                    Text(solo ? "SAIL ONWARD" : "CHOOSE THIS DIE")
                        .font(.fantasy(12, weight: .bold)).foregroundStyle(Theme.gold)
                }
                .frame(maxWidth: solo ? 360 : .infinity)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!rollingIDs.isEmpty)
            .accessibilityLabel(known ? "Choose \(node.kind.label)" : "Choose Dark Water, a hidden destination")
            if !solo {
                Button {
                    guard rollingIDs.isEmpty, game.rerollDestination(node.id) else { return }
                    rerollTask = Task { await animateDestinations([node.id]) }
                } label: {
                    Label(game.canRerollDestination ? "REROLL THIS DIE" : "REROLL SPENT", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(game.canRerollDestination ? Theme.gold : Theme.parchmentDim)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background { TurnOrderPlaque(accent: Theme.gold) }
                }
                .buttonStyle(.plain)
                .disabled(!game.canRerollDestination || !rollingIDs.isEmpty)
                .accessibilityLabel("Reroll \(known ? node.kind.label : "Dark Water") destination")
            }
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    private func animateDestinations(_ ids: Set<UUID>) async {
        rollingIDs = ids
        defer { rollingIDs = [] }
        Audio.shared.play(.diceRoll)
        for frame in 0..<(reduceMotion ? 2 : 8) {
            rollFrame = frame
            do { try await Task.sleep(for: .milliseconds(reduceMotion ? 70 : 95)) } catch { return }
        }
        Haptics.medium()
        Audio.shared.play(.diceLock)
    }
}



