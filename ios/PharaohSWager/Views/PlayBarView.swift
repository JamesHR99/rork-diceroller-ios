import SwiftUI

struct PlayBarView: View {
    let engine: BattleEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var impactTask: Task<Void, Never>?
    @State private var impactSize = 2

    @State private var showingOrder = false
    @State private var detailStep: PlanStep?
    @State private var burstStepID: UUID?
    @State private var burstProgress: CGFloat = 0

    var bodyHeight: CGFloat = 116

    private var compact: Bool { bodyHeight < 104 }

    private var columnHeight: CGFloat { max(110, bodyHeight + 28) }
    private var rerollHeight: CGFloat { 52 }
    private var commitHeight: CGFloat { columnHeight - rerollHeight - 6 }
    private var controlWidth: CGFloat { compact ? 108 : 120 }

    var body: some View {
        HStack(spacing: 7) {
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
        .sheet(item: $detailStep) { step in
            NavigationStack {
                List {
                    Section("Action") {
                        Text(engine.damageBreakdown(for: step))
                        ForEach(engine.nativePlanEffectLines(for: step), id: \.self) { Text($0) }
                        if let line = engine.chiselLine(for: step) { Text(line) }
                        ForEach(step.faces) { face in
                            Button("Return \(face.displayName) to tray") {
                                engine.returnToTray(faceID: face.id)
                                detailStep = nil
                            }
                            .disabled(engine.phase != .player)
                        }
                    }
                    Section("God boons · conditional") {
                        ForEach(engine.comboBoonCandidates(for: step)) { boon in
                            VStack(alignment: .leading, spacing: 6) {
                                Label("\(boon.def?.god.name ?? "God") · \(boon.def?.name ?? boon.defID)",
                                      systemImage: boon.def?.god.symbol ?? "sparkles")
                                    .foregroundStyle(boon.def?.god.tint ?? Theme.gold)
                                Text(boon.text)
                            }
                        }
                        Text("These powers can answer this action. Target, action order, actual healing and activation limits are checked when it resolves.")
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle(step.title)
                .toolbar { Button("Done") { detailStep = nil } }
            }
            .tint(Theme.gold)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Combining

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
                    .font(.system(size: 12, weight: .bold))
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.frost)
                    .lineLimit(1)
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
        .frame(minHeight: 22)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: planFaces.count)
    }

    private var planRow: some View {
        let steps = engine.displayedPlan
        return GeometryReader { geometry in
            let columns = min(3, max(1, steps.count))
            let rows = max(1, (steps.count + columns - 1) / columns)
            let cardWidth = max(1, (geometry.size.width - CGFloat(columns - 1) * 6) / CGFloat(columns))
            let cardHeight = (bodyHeight - CGFloat(rows - 1) * 6) / CGFloat(rows)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
                if steps.isEmpty {
                    Text("PLACE DICE IN ORDER · MATCHING NEIGHBOURS COMBINE")
                        .font(.fantasy(13, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                ForEach(steps) { step in combinedCard(step, width: cardWidth, height: cardHeight) }
            }
        }
        .frame(height: bodyHeight)
    }

    private func combinedCard(_ step: PlanStep, width: CGFloat, height: CGFloat) -> some View {
        let tint = step.tint
        let boons = engine.comboBoonCandidates(for: step)
        return VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top, spacing: 4) {
                    Text("\(engine.beat(for: step).map { "\($0). " } ?? "")\(step.title)")
                        .font(.system(size: height < 70 ? 13 : 14, weight: .bold))
                        .foregroundStyle(Theme.parchment)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let face = step.faces.first, width > 240 {
                        HStack(spacing: 2) {
                            PharaohSWagerSymbol(art: face.matchFace.artName, fallback: face.matchFace.symbol,
                                size: 17, tint: step.hasCritFace ? Theme.gold : face.matchFace.tint)
                                .draggable(face.id.uuidString)
                            Text("×\(step.faces.count)").font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(Theme.gold)
                        .fixedSize()
                    }
                }
                Text(([engine.displayedDamage(for: step) > 0 ? "\(engine.displayedDamage(for: step)) dmg" : ""]
                    + step.effects.map { $0.replacingOccurrences(of: "Shield", with: "Guard")
                        .replacingOccurrences(of: "Evade (50% base)", with: "Evade 50%") }).filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                if !boons.isEmpty {
                    Label(width < 175 ? "\(boons.count) boon\(boons.count == 1 ? "" : "s") · if eligible" : boonLabel(boons), systemImage: "sparkles")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.gold)
                }
        }
        .padding(height < 70 ? 4 : 6)
        .frame(width: width, height: height, alignment: .topLeading)
        .background { TurnOrderPlaque(accent: tint) }
        .contentShape(Rectangle())
        .onTapGesture {
            if engine.armingChiselID != nil, let face = step.faces.first { _ = engine.armHeldChisel(ontoFace: face.id) }
            else { detailStep = step }
        }
        .accessibilityAction(named: "Action and god boon details") { detailStep = step }
        .draggable(step.faces.first?.id.uuidString ?? "")
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
                    Menu("Evade \(index + 1): \(engine.evadeTargetLabel(faceID: face.id))") {
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

    private func boonLabel(_ boons: [EquippedBoon]) -> String {
        let names = Array(Set(boons.compactMap { $0.def?.god.name })).sorted()
        if names.count > 2 { return "\(boons.count) boons · conditional" }
        return names.joined(separator: "/") + " · if eligible"
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
                    .font(.system(size: 12, weight: .semibold))
                GeometryReader { proxy in
                    Capsule().fill(Theme.gold.opacity(0.2))
                        .overlay(alignment: .leading) {
                            Capsule().fill(Theme.gold)
                                .frame(width: proxy.size.width * CGFloat(engine.availableRerollHalfCharges) / CGFloat(max(1, engine.rerollCapacity * 2)))
                        }
                }
                .frame(height: 4)
                .animation(.easeOut(duration: 0.7), value: engine.rerollHalfCharges)
            }
            .foregroundStyle(Theme.gold)
            .paintedContentInsets()
            .frame(width: controlWidth, height: rerollHeight)
            .background {
                DeckButtonSurface(tone: .secondary, state: engine.selectingReroll ? .selected : .normal, rim: Theme.gold)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!engine.canReroll)
        .accessibilityIdentifier("battle.reroll")
        .anchorPreference(key: RerollChargeAnchorKey.self, value: .bounds) { ["reroll": $0] }
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
            .paintedContentInsets()
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
