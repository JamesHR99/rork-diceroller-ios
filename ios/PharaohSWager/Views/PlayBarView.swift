import SwiftUI

struct PlayBarView: View {
    let engine: BattleEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var impactTask: Task<Void, Never>?
    @State private var impactSize = 2

    @State private var showingOrder = false
    @State private var burstStepID: UUID?
    @State private var burstProgress: CGFloat = 0

    var bodyHeight: CGFloat = 116

    private var compact: Bool { bodyHeight < 104 }

    private var columnHeight: CGFloat { max(94, bodyHeight + (compact ? 22 : 28)) }
    private var rerollHeight: CGFloat { 44 }
    private var commitHeight: CGFloat { columnHeight - rerollHeight - 6 }
    private var controlWidth: CGFloat { compact ? 108 : 120 }

    var body: some View {
        HStack(spacing: 7) {
            diceRail
            planSection
            VStack(spacing: 6) {
                rerollButton
                commitButton
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, compact ? 2 : 4)
        .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.8), value: engine.hasCombo)
        .onChange(of: engine.weldedGroups) { old, new in
            guard engine.phase == .player,
                  let formed = new.filter({ !old.contains($0) }).max(by: { $0.count < $1.count }),
                  formed.count > 1 else { return }
            impactTask?.cancel()
            impactSize = formed.count
            burstStepID = formed.first
            burstProgress = 0
            Haptics.chain(length: formed.count, crit: false)
            Audio.shared.play(.chain, volumeScale: min(1, 0.35 + Float(formed.count) * 0.1))
            if formed.count >= 4 { Audio.shared.play(.diceLock, after: 0.07) }
            impactTask = Task { @MainActor in
                // Let the initial impact reach the screen before animating it away.
                do { try await Task.sleep(for: .milliseconds(20)) } catch { return }
                withAnimation(.easeOut(duration: reduceMotion ? 0.18 : 0.35 + Double(formed.count) * 0.07)) {
                    burstProgress = 1
                }
                do { try await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 900)) } catch { return }
                burstStepID = nil
            }
        }
        .onDisappear { impactTask?.cancel() }
    }

    // MARK: - Combining

    private var diceRail: some View {
        VStack(spacing: 5) {
            Image(systemName: "dice.fill")
            Text("\(planFaces.count)/\(BattleRules.handSize)")
                .font(.system(size: 13, weight: .black).monospacedDigit())
            Text("DICE").font(.system(size: 8, weight: .bold))
            Spacer(minLength: 0)
            Image(systemName: "arrow.triangle.2.circlepath")
            Text(engine.rerollChargeText).font(.system(size: 13, weight: .black))
        }
        .foregroundStyle(Theme.gold)
        .padding(.vertical, 8)
        .frame(width: 42, height: columnHeight)
        .background(Theme.bg.opacity(0.7), in: .rect(cornerRadius: 12))
    }

    // MARK: - Turn plan

    private var planFaces: [RolledFace] {
        engine.phase == .player ? engine.playedFaces : engine.committedPlan.flatMap(\.faces)
    }

    private var planSection: some View {
        VStack(spacing: compact ? 2 : 3) {
            planHeader
            planRow
        }
        .padding(.horizontal, 9)
        .padding(.vertical, compact ? 4 : 6)
        .frame(maxWidth: .infinity)
        .background { TurnOrderPlaque(accent: Theme.gold) }
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first, let faceID = UUID(uuidString: idString) else { return false }
            engine.placeInPlayBar(faceID: faceID)
            return true
        }
    }

    private var planHeader: some View {
        HStack(spacing: 8) {
            Button { showingOrder = true } label: {
                Label(compact ? "ORDER" : "TURN ORDER", systemImage: "list.number")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Theme.gold)
            }
            .sheet(isPresented: $showingOrder) {
                NavigationStack {
                    List {
                        Section("Alternating actions") {
                            ForEach(engine.timeline) { entry in
                                HStack {
                                    Text("\(entry.beat)").monospacedDigit()
                                    VStack(alignment: .leading) {
                                        Text(entry.isPlayer ? "You · \(entry.title)" : entry.title)
                                        Text(entry.detail).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("This round")
                    .toolbar { Button("Done") { showingOrder = false } }
                }
            }
            if engine.pendingRerollHalfCharges > 0 {
                Text("+\(BattleEngine.chargeText(engine.pendingRerollHalfCharges)) REROLL ON COMMIT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.frost)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            // The header is a title, not a narrator. The only line that earns
            // its place is the held Chisel prompt, which is an instruction.
            if let chisel = engine.armingChisel {
                Text("\(chisel.name.uppercased()) — tap a die to spend it")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Theme.ptahCopper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 4)

            // The plan prints how many dice are committed, never what they add
            // up to — a total would give the chain away before it lands.
            if engine.hasEchoPending {
                HStack(spacing: 3) {
                    PharaohSWagerIcon(name: PharaohSWagerArt.echoMarker, size: 16)
                    Text(compact ? "ECHO" : "ECHO WAITS")
                        .font(.system(size: 10.5, weight: .black))
                        .kerning(0.8)
                }
                .foregroundStyle(Theme.ptahCopper)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .frame(height: compact ? 14 : 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: planFaces.count)
    }

    private var planRow: some View {
        let steps = engine.displayedPlan
        return GeometryReader { geometry in
            let reserved = CGFloat(max(0, steps.count - 1)) * 6
            let diceCount = max(1, steps.reduce(0) { $0 + $1.faces.count })
            let share = max(78, (geometry.size.width - reserved - 2) / CGFloat(diceCount))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if steps.isEmpty {
                        Text("PLACE DICE IN ORDER · MATCHING NEIGHBOURS COMBINE")
                            .font(.fantasy(compact ? 13 : 17, weight: .bold))
                            .foregroundStyle(Theme.parchment.opacity(0.75))
                            .frame(width: max(0, geometry.size.width - 2), height: bodyHeight)
                    }
                    ForEach(steps) { step in
                        combinedCard(step, width: share * CGFloat(step.faces.count))
                    }
                }
                .padding(.horizontal, 1)
                .frame(minHeight: bodyHeight)
            }
        }
        .frame(height: bodyHeight)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.72), value: engine.playOrder)
    }

    private func combinedCard(_ step: PlanStep, width: CGFloat) -> some View {
        let roomy = width >= 350
        let tint = step.tint
        let titleSize = min(34, min(bodyHeight * 0.29, max(12, width * 0.085)))
        let iconSize = min(bodyHeight * (roomy ? 0.42 : 0.2), max(12, (width - 28) / CGFloat(step.faces.count + 2)))
        let content = roomy ? AnyLayout(HStackLayout(alignment: .center, spacing: 18))
                            : AnyLayout(VStackLayout(alignment: .leading, spacing: 3))
        return content {
            HStack(spacing: 3) {
                ForEach(step.faces) { face in
                    PharaohSWagerSymbol(art: face.matchFace.artName, fallback: face.matchFace.symbol,
                        size: iconSize, tint: face.isCrit ? Theme.gold : face.matchFace.tint)
                        .draggable(face.id.uuidString)
                        .accessibilityLabel(face.displayName + (face.isCrit ? ", critical" : ""))
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 3) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(step.title.uppercased())
                            .font(.fantasy(titleSize, weight: .black))
                            .foregroundStyle(Theme.parchment)
                            .lineLimit(2).minimumScaleFactor(0.65)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(step.isCombo ? "\(step.faces.count) DICE COMBO" : "1 DIE")
                            .font(.system(size: max(9, titleSize * 0.46), weight: .black))
                            .foregroundStyle(Theme.gold)
                    }
                    if engine.phase == .player {
                        Button {
                            if let face = step.faces.last { engine.returnToTray(faceID: face.id) }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: max(16, titleSize * 0.65)))
                                .foregroundStyle(Theme.gold)
                                .frame(minWidth: 30, minHeight: 30)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Return last die from \(step.title) to tray")
                    }
                }
                ScrollView(.vertical, showsIndicators: false) {
                    let labels = (engine.displayedDamage(for: step) > 0 ? ["\(engine.displayedDamage(for: step)) DAMAGE"] : []) + step.effects
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: min(max(60, width - 24), roomy ? 150 : 100)), spacing: 4)], alignment: .leading, spacing: 3) {
                        ForEach(labels, id: \.self) { label in
                            Text(label.uppercased())
                                .font(.system(size: min(20, max(10, min(bodyHeight * 0.18, width / 15))), weight: .bold))
                                .foregroundStyle(label.contains("DAMAGE") ? Theme.gold : Theme.parchment)
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(tint.opacity(0.13), in: .rect(cornerRadius: 3))
                        }
                    }
                    if let line = engine.chiselLine(for: step) {
                        Text(line).font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.ptahCopper)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, roomy ? 18 : 8).padding(.vertical, 7)
        .frame(width: width, height: bodyHeight)
        .background { TurnOrderPlaque(accent: tint) }
        .onTapGesture {
            if engine.armingChiselID != nil, let face = step.faces.first { _ = engine.armHeldChisel(ontoFace: face.id) }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let value = items.first, let id = UUID(uuidString: value), let first = step.faces.first else { return false }
            engine.placeInPlayBar(faceID: id, before: first.id)
            return true
        }
        .contextMenu {
            ForEach(step.faces) { face in
                Button("Return \(face.displayName)") { engine.returnToTray(faceID: face.id) }
            }
            if let action = step.combo, action.dodgeCharges > 0 {
                ForEach(Array(step.faces.prefix(action.dodgeCharges).enumerated()), id: \.element.id) { index, face in
                    Menu("Dodge \(index + 1): \(engine.evadeTargetLabel(faceID: face.id))") {
                        Button("Next strike") { engine.assignEvade(faceID: face.id, strikeID: nil) }
                        ForEach(engine.incomingStrikes) { strike in
                            Button(strike.title) { engine.assignEvade(faceID: face.id, strikeID: strike.id) }
                        }
                    }
                }
            }
        }
        .scaleEffect(!reduceMotion && burstStepID == step.id ? 1 + (1 - burstProgress) * CGFloat(impactSize) * 0.018 : 1)
        .shadow(color: Theme.gold.opacity(burstStepID == step.id ? Double(1 - burstProgress) * 0.7 : 0), radius: CGFloat(impactSize * 3))
        .overlay {
            if !reduceMotion && burstStepID == step.id {
                CombineBurst(progress: burstProgress, tint: Theme.gold, size: impactSize).allowsHitTesting(false)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.92)))
    }

    private var rerollButton: some View {
        Button {
            engine.selectingReroll.toggle()
            Haptics.light()
        } label: {
            VStack(spacing: 2) {
                Label(engine.selectingReroll ? "CANCEL" : "REROLL", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .black))
                Text(engine.selectingReroll ? "Tap a die to roll now" : "\(engine.rerollChargeText)/\(engine.rerollCapacity) charges")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(Theme.gold)
            .frame(width: controlWidth, height: rerollHeight)
            .background {
                DeckButtonSurface(tone: .secondary, state: engine.selectingReroll ? .selected : .normal, rim: Theme.gold)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!engine.canReroll)
        .accessibilityIdentifier("battle.reroll")
    }

    // MARK: - Commit

    private var commitButton: some View {
        let armed = engine.canCommit && !engine.playedFaces.isEmpty
        let layout = commitHeight < 56 ? AnyLayout(HStackLayout(spacing: 4))
                                       : AnyLayout(VStackLayout(spacing: 2))
        return Button {
            engine.beginCommit()
            Haptics.medium()
            Audio.shared.play(.uiConfirm)
        } label: {
            layout {
                PharaohSWagerIcon(name: PharaohSWagerArt.Status.burn, size: compact ? 21 : 26)
                    .shadow(color: Theme.ember.opacity(armed ? 0.8 : 0), radius: 8)
                Text(engine.playedFaces.isEmpty ? "END TURN" : "FIGHT!")
                    .font(.fantasy(armed ? 20 : 15, weight: .black))
                    .kerning(1.4)
                    .foregroundStyle(
                        engine.canCommit
                            ? LinearGradient(colors: [Theme.parchment, Theme.gold],
                                             startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Theme.parchmentDim, Theme.parchmentDim],
                                             startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .black.opacity(0.8), radius: 2, y: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: controlWidth, height: commitHeight)
            .background {
                DeckButtonSurface(
                    tone: .primary,
                    state: engine.canCommit ? .highlighted : .disabled,
                    rim: armed ? Theme.ember : Theme.gold,
                    cornerRadius: 15,
                    emphasis: armed ? 1 : 0
                )
            }
            .goldCorners(size: 15, inset: 3, opacity: engine.canCommit ? 0.8 : 0.3)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!engine.canCommit)
        .accessibilityIdentifier("battle.commit")
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: armed)
    }
}

