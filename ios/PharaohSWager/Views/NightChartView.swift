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
                .frame(width: 58, height: 52)
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
        if options.count == 1 {
            return first.kind == .boss
                ? "\(gate.region) · The river ends here. There is no way around it."
                : "\(gate.region) · The channels close to one. It is waiting for you."
        }
        let dark = options.filter { !$0.isRevealed }.count
        switch dark {
        case 0: return "\(gate.region) · Two channels, both read clearly."
        case 1: return "\(gate.region) · Two channels — one of them is dark water."
        default: return "\(gate.region) · Two channels, both dark. Pick a side."
        }
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
        let tint = known ? node.kind.tint : Theme.duskViolet
        let marker: PharaohSWagerArt.RouteState = node.isBoss ? .boss : .available

        return Button {
            game.enter(node)
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    PharaohSWagerImage(name: PharaohSWagerArt.RouteState.available.rawValue,
                              height: (solo ? 128 : 108) + 18, fit: .fit)
                        .colorMultiply(tint)
                        .scaleEffect(pulse ? 1.08 : 0.96)
                        .opacity(pulse ? 0.22 : 0.48)
                        .blur(radius: 3)

                    PharaohSWagerImage(name: marker.rawValue, height: solo ? 128 : 108, fit: .fit)
                        .modifier(TintWash(tint: tint))

                    PharaohSWagerSymbol(art: known ? node.kind.artName : nil,
                               fallback: known ? node.kind.symbol : "questionmark",
                               size: solo ? 62 : 50,
                               tint: Theme.parchment)
                        .padding(solo ? 12 : 9)
                        .background {
                            Circle()
                                .fill(Theme.bg.opacity(0.82))
                                .overlay(Circle().strokeBorder(tint.opacity(0.6), lineWidth: 1))
                        }
                        .shadow(color: .black.opacity(0.8), radius: 5)
                }
                .shadow(color: tint.opacity(pulse ? 0.7 : 0.3), radius: 14)

                Text(known ? node.kind.label.uppercased() : "DARK WATER")
                    .font(.fantasy(solo ? 20 : 17, weight: .black))
                    .kerning(1.4)
                    .foregroundStyle(node.isBoss ? Theme.blood : tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(known
                     ? (node.isBoss
                        ? EnemyContent.enemy(hour: node.hour, isHerald: false).name
                        : node.kind.title)
                     : "The water tells you nothing")
                    .font(.fantasy(13, weight: .bold))
                    .foregroundStyle(Theme.parchment.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(known ? node.kind.blurb : "You will know when you are in it.")
                    .font(.paper(11.5))
                    .italic()
                    .foregroundStyle(Theme.parchmentDim)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(Voyage.fullName(node.hour).uppercased())
                    .font(.system(size: 8, weight: .black))
                    .kerning(1)
                    .foregroundStyle(Theme.parchmentDim.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: solo ? 360 : .infinity)
            .duatPanel(tint: tint, cornerRadius: 20)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

