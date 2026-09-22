import SwiftUI

/// The river's wheel of fate. A fixed pointer chooses one visible encounter.
struct NightChartView: View {
    @Environment(GameManager.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation = 0.0
    @State private var isSpinning = false
    @State private var rerollTask: Task<Void, Never>?
    @State private var pulse = false
    @State private var showInfo = false

    private var gate: Gate { game.gate }

    /// One destination after spinning, or the next fixed milestone.
    private var options: [VoyageNode] { game.availableNodes }

    /// Where the next stop sits inside its gate, 0 through 7.
    private var indexInGate: Int { game.nextStage % Voyage.stagesPerGate }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                header
                gateRibbon
                wheelArea(diameter: min(280, max(160, proxy.size.height - 118)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                footer
            }
        }
        .onAppear {
            rotation = Voyage.rotation(for: game.wheelResult ?? 0)
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
            }
        }
        .onDisappear {
            rerollTask?.cancel()
            isSpinning = false
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
        if options.first?.kind.isForced == true { return "A fixed milestone on the river." }
        if isSpinning { return "The wheel of fate is turning…" }
        return game.needsWheelSpin ? "Spin to discover your next encounter." : "Accept your fate, or spend a path reroll."
    }

    private var footer: some View {
        HStack(spacing: 10) {
            ForEach([StageKind.battle, .omen, .shrine, .ferryman], id: \.self) { kind in
                Label(kind.label, systemImage: kind.symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(kind.tint)
            }
            Spacer(minLength: 0)
            Text("8 guardians · 2 omens · 1 shrine · 1 shop")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.parchmentDim)
        }
        .padding(.horizontal, 20)
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

    // MARK: - Wheel and locked result

    private func wheelArea(diameter: CGFloat) -> some View {
        HStack(spacing: 24) {
            if let node = options.first, node.kind.isForced || game.nextStage == 0 {
                PharaohSWagerSymbol(art: node.kind.artName, fallback: node.kind.symbol,
                    size: diameter * 0.55, tint: node.kind.tint)
                    .frame(width: diameter, height: diameter)
                    .duatPanel(tint: node.kind.tint, cornerRadius: 24)
            } else {
                EncounterWheelView(rotation: rotation, diameter: diameter, isSpinning: isSpinning)
            }
            FittingScrollColumn {
                resultControls
                    .frame(maxWidth: 340)
                    .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: 360)
        }
        .padding(.horizontal, 26)
    }

    private var resultControls: some View {
        VStack(spacing: 8) {
            Text("PATH REROLLS  \(game.pathRerolls)/3")
                .font(.system(size: 12, weight: .black))
                .kerning(1.2)
                .foregroundStyle(Theme.gold)
            if isSpinning {
                Text("Fate is turning…")
                    .font(.fantasy(22, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                Text("Wait for the wheel to lock.")
                    .font(.paper(14)).foregroundStyle(Theme.parchmentDim)
            } else if game.needsWheelSpin {
                Text("Wheel of Fate")
                    .font(.fantasy(24, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                wheelButton("SPIN THE WHEEL", symbol: "sparkles") { spin() }
            } else if let node = options.first {
                Text(node.kind.title)
                    .font(.fantasy(22, weight: .bold))
                    .foregroundStyle(node.kind.tint)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(node.kind.blurb)
                    .font(.paper(14)).foregroundStyle(Theme.parchmentDim)
                    .multilineTextAlignment(.center)
                HStack(spacing: 8) {
                    wheelButton("SAIL ONWARD", symbol: "arrow.right") { game.enter(node) }
                    if !node.kind.isForced && game.nextStage > 0 {
                        wheelButton(game.pathRerolls > 0 ? "REROLL · 1" : "NO REROLLS",
                            symbol: "arrow.triangle.2.circlepath", enabled: game.canRerollDestination) {
                            spin(usingReroll: true)
                        }
                    }
                }
            }
            if !isSpinning {
                Text("Gain path rerolls from omens and the Ferryman.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.parchmentDim)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
    }

    private func wheelButton(_ title: String, symbol: String, enabled: Bool = true,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.fantasy(14, weight: .bold))
                .foregroundStyle(Theme.parchment)
                .paintedContentInsets()
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    DeckButtonSurface(tone: .primary, state: .normal, rim: Theme.gold,
                        cornerRadius: 12, emphasis: 0.6)
                }
                .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled || isSpinning)
    }

    private func spin(usingReroll: Bool = false) {
        guard !isSpinning, let index = game.spinEncounterWheel(usingReroll: usingReroll) else { return }
        isSpinning = true
        let normalized = rotation.truncatingRemainder(dividingBy: 360)
        let landing = (Voyage.rotation(for: index) - normalized + 720)
            .truncatingRemainder(dividingBy: 360)
        let target = rotation + 360 * 5 + landing
        let duration = reduceMotion ? 0.25 : 3.4
        Audio.shared.play(.diceRoll)
        withAnimation(reduceMotion ? nil : .timingCurve(0.12, 0.78, 0.18, 1, duration: duration)) {
            rotation = reduceMotion ? Voyage.rotation(for: index) : target
        }
        rerollTask = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(duration)) } catch { return }
            guard !Task.isCancelled else { return }
            isSpinning = false
            Haptics.success()
            Audio.shared.play(.diceLock)
        }
    }
}

/// The pointer remains fixed while every wedge rotates under it. Wedge zero
/// is centred on twelve o'clock, matching Voyage.rotation(for:).
struct EncounterWheelView: View {
    let rotation: Double
    let diameter: CGFloat
    let isSpinning: Bool

    var body: some View {
        ZStack {
            ZStack {
                ForEach(Voyage.wheelKinds.indices, id: \.self) { index in
                    let kind = Voyage.wheelKinds[index]
                    WheelWedge(index: index)
                        .fill(kind.tint.opacity(index.isMultiple(of: 2) ? 0.6 : 0.38))
                    WheelWedge(index: index)
                        .stroke(Theme.gold.opacity(0.8), lineWidth: 1)
                    Image(systemName: kind.symbol)
                        .font(.system(size: diameter * 0.075, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .shadow(color: .black, radius: 2)
                        .offset(y: -diameter * 0.36)
                        .rotationEffect(.degrees(Double(index) * Voyage.wedgeDegrees))
                }
            }
            .background(Theme.bg, in: Circle())
            .clipShape(Circle())
            .rotationEffect(.degrees(rotation))
            Circle().strokeBorder(Theme.gold, lineWidth: 5)
            Circle().strokeBorder(Theme.parchment.opacity(0.45), lineWidth: 1).padding(7)
            Circle().fill(Theme.bg).frame(width: diameter * 0.27, height: diameter * 0.27)
                .overlay(Circle().strokeBorder(Theme.gold, lineWidth: 3))
            Image(systemName: "eye.fill")
                .font(.system(size: diameter * 0.12, weight: .bold))
                .foregroundStyle(Theme.gold)
            Image(systemName: "triangle.fill")
                .font(.system(size: 23, weight: .black))
                .rotationEffect(.degrees(180))
                .foregroundStyle(Theme.gold)
                .shadow(color: .black, radius: 2)
                .offset(y: -diameter / 2 + 3)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: Theme.gold.opacity(isSpinning ? 0.5 : 0.2), radius: 12)
        .accessibilityLabel("Encounter wheel: eight guardian wedges, two omens, one shrine, one Ferryman")
        .accessibilityValue(isSpinning ? "Spinning" : "Stopped")
        .accessibilityElement(children: .ignore)
    }
}

private struct WheelWedge: Shape {
    let index: Int
    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let angle = Double(index) * Voyage.wedgeDegrees - 90
        var path = Path()
        path.move(to: centre)
        path.addArc(center: centre, radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(angle - Voyage.wedgeDegrees / 2),
            endAngle: .degrees(angle + Voyage.wedgeDegrees / 2), clockwise: false)
        path.closeSubpath()
        return path
    }
}
