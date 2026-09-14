import SwiftUI

/// Bottom play bar — the centre of the turn. A slim stamina rail on the far
/// left, the tall turn plan taking the whole middle (fused combos drawn as one
/// welded card), and the freeze / commit buttons on the right.
struct PlayBarView: View {
    let engine: BattleEngine

    /// How tall the plan cards run. Everything in the bar is sized off this so
    /// the row stays level.
    private let bodyHeight: CGFloat = 104

    var body: some View {
        HStack(spacing: 9) {
            staminaRail
            planSection
            VStack(spacing: 6) {
                freezeButton
                commitButton
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .papyrusPanel(tint: Theme.bgElevated, cornerRadius: 18, strength: 0.45)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(engine.hasCombo ? Theme.ember.opacity(0.55) : Theme.gold.opacity(0.18),
                              lineWidth: engine.hasCombo ? 1.8 : 1)
        )
        .shadow(color: Theme.ember.opacity(engine.hasCombo ? 0.28 : 0), radius: 16)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: engine.hasCombo)
    }

    // MARK: - Stamina rail

    /// Stamina now lives in a narrow column so the plan can have the width.
    private var staminaRail: some View {
        VStack(spacing: 4) {
            Text("STM")
                .font(.system(size: 8, weight: .black))
                .kerning(1)
                .foregroundStyle(Theme.parchmentDim)

            staminaPips

            Spacer(minLength: 0)

            VStack(spacing: 0) {
                Text("NEXT")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(Theme.parchmentDim.opacity(0.7))
                Text("\(engine.projectedNextTurnStamina)")
                    .font(.system(size: 13, weight: .black).monospacedDigit())
                    .foregroundStyle(engine.projectedNextTurnStamina > engine.maxStamina
                                     ? Theme.sunGold : Theme.parchmentDim)
            }
        }
        .frame(width: 42, height: bodyHeight + 13)
        .padding(.vertical, 4)
        .background(Theme.bg.opacity(0.5), in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Theme.gold.opacity(0.2), lineWidth: 1)
        )
    }

    /// Pips stack down the rail, wrapping into a second column once the turn's
    /// budget runs long. Pips above the cap are earned bonus.
    private var staminaPips: some View {
        let total = max(engine.maxStamina, engine.stamina)
        let columns = total > 5 ? 2 : 1
        let perColumn = Int(ceil(Double(total) / Double(columns)))
        return HStack(alignment: .top, spacing: 4) {
            ForEach(0..<columns, id: \.self) { column in
                VStack(spacing: 2.5) {
                    ForEach(0..<perColumn, id: \.self) { row in
                        let index = column * perColumn + row
                        if index < total {
                            let isBonus = index >= engine.maxStamina
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundStyle(index < engine.stamina
                                                 ? (isBonus ? Theme.sunGold : Theme.gold)
                                                 : Theme.bg)
                                .shadow(color: index < engine.stamina
                                        ? (isBonus ? Theme.sunGold.opacity(0.85) : Theme.gold.opacity(0.55))
                                        : .clear, radius: 3)
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: engine.stamina)
    }

    // MARK: - Turn plan

    private var plan: [PlanStep] { engine.displayedPlan }

    private var planSection: some View {
        VStack(spacing: 3) {
            planHeader
            planRow
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Theme.bg.opacity(0.65), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    engine.hasCombo ? Theme.ember.opacity(0.65) : Theme.parchmentDim.opacity(0.15),
                    lineWidth: engine.hasCombo ? 2 : 1
                )
        )
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first, let faceID = UUID(uuidString: idString) else { return false }
            engine.placeInPlayBar(faceID: faceID)
            return true
        }
    }

    private var planHeader: some View {
        HStack(spacing: 8) {
            Text("TURN PLAN")
                .font(.system(size: 9, weight: .black))
                .kerning(1)
                .foregroundStyle(Theme.parchmentDim)

            Text(hintText)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            if engine.projectedDamage > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "burst.fill").font(.system(size: 9))
                    Text("\(engine.projectedDamage) TOTAL DMG")
                        .font(.system(size: 10, weight: .black).monospacedDigit())
                }
                .foregroundStyle(Theme.ember)
                .shadow(color: Theme.ember.opacity(0.6), radius: 5)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .frame(height: 13)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: engine.projectedDamage)
    }

    private var planRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(Array(plan.enumerated()), id: \.element.id) { index, step in
                    planCard(step, number: index + 1, isActive: engine.activeStepIndex == index)

                    if index < plan.count - 1 {
                        Image(systemName: "chevron.compact.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.parchmentDim.opacity(0.4))
                    }
                }

                if engine.phase == .player {
                    ForEach(0..<emptySlotCount, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Theme.parchmentDim.opacity(0.22),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            .frame(width: 50, height: bodyHeight)
                    }
                }
            }
            .padding(.horizontal, 1)
            .frame(minHeight: bodyHeight, alignment: .leading)
        }
        .frame(height: bodyHeight)
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: engine.playOrder)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: engine.activeStepIndex)
    }

    private var emptySlotCount: Int {
        max(0, min(engine.stamina, engine.maxStamina))
    }

    @ViewBuilder
    private func planCard(_ step: PlanStep, number: Int, isActive: Bool) -> some View {
        Button {
            guard engine.phase == .player else { return }
            for face in step.faces { engine.returnToTray(faceID: face.id) }
        } label: {
            Group {
                if step.isCombo {
                    comboCard(step, number: number)
                } else {
                    soloCard(step, number: number)
                }
            }
            .frame(height: bodyHeight)
            .background(Theme.bgCard, in: .rect(cornerRadius: 11))
            .overlay {
                // A fused chain wears its own colour as an inner wash so it
                // reads as one welded object, not a run of loose chips.
                if step.isCombo {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(
                            LinearGradient(colors: [step.tint.opacity(0.22), .clear],
                                           startPoint: .bottom, endPoint: .top)
                        )
                        .allowsHitTesting(false)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(step.tint.opacity(isActive ? 1 : (step.isCombo ? 0.75 : 0.4)),
                                  lineWidth: isActive ? 2.6 : (step.isCombo ? 2 : 1))
            )
            .shadow(color: step.tint.opacity(isActive ? 0.85 : (step.isCombo ? 0.45 : 0)),
                    radius: isActive ? 12 : 6)
            .scaleEffect(isActive ? 1.06 : 1)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(engine.phase != .player)
        .draggable(step.faces.first?.id.uuidString ?? "")
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first,
                  let droppedID = UUID(uuidString: idString),
                  let targetID = step.faces.first?.id else { return false }
            engine.placeInPlayBar(faceID: droppedID, before: targetID)
            return true
        }
        .transition(.scale(scale: 0.6).combined(with: .opacity))
    }

    /// A fused chain: name in full type, the chain badge, every contributing
    /// face welded in order, the whole effect line and the crit odds.
    private func comboCard(_ step: PlanStep, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                orderBadge(number, tint: step.tint)

                Text(step.title.uppercased())
                    .font(.fantasy(16, weight: .black))
                    .kerning(0.5)
                    .foregroundStyle(step.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                Spacer(minLength: 2)

                Text("\(step.faces.count)-CHAIN")
                    .font(.system(size: 8.5, weight: .black))
                    .kerning(0.5)
                    .foregroundStyle(Theme.bg)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(step.tint, in: .capsule)

                HStack(spacing: 1.5) {
                    Image(systemName: "bolt.fill").font(.system(size: 8, weight: .black))
                    Text("\(step.staminaCost)")
                        .font(.system(size: 9, weight: .black).monospacedDigit())
                }
                .foregroundStyle(Theme.bg)
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .background(step.staminaCost < step.faces.count ? Theme.sunGold : Theme.parchmentDim,
                            in: .capsule)
            }

            weldedFaces(step)

            Text(step.valueLine)
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(step.damage > 0 ? Theme.ember : Theme.parchment.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            critLine(step)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(minWidth: 176, maxWidth: 300, alignment: .leading)
    }

    /// The chain's faces, linked together by welds rather than spaced apart.
    private func weldedFaces(_ step: PlanStep) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(step.faces.enumerated()), id: \.element.id) { index, face in
                Image(systemName: face.face.symbol)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(face.isCrit ? Theme.gold : (face.patron?.tint ?? face.face.tint))
                    .frame(width: 29, height: 27)
                    .background(Theme.bg.opacity(0.55), in: .rect(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(face.isCrit ? Theme.gold.opacity(0.9) : step.tint.opacity(0.45),
                                          lineWidth: 1)
                    )
                    .shadow(color: face.isCrit ? Theme.gold.opacity(0.7) : .clear, radius: 4)

                if index < step.faces.count - 1 {
                    Rectangle()
                        .fill(step.tint.opacity(0.75))
                        .frame(width: 8, height: 3)
                }
            }
        }
    }

    /// A face played on its own — deliberately small next to a real chain.
    private func soloCard(_ step: PlanStep, number: Int) -> some View {
        VStack(spacing: 3) {
            orderBadge(number, tint: step.tint)

            Image(systemName: step.faces.first?.face.symbol ?? "questionmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(step.tint)

            Text(step.title.uppercased())
                .font(.system(size: 8.5, weight: .black))
                .foregroundStyle(Theme.parchment.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(step.valueLine)
                .font(.system(size: 8.5, weight: .bold).monospacedDigit())
                .foregroundStyle(step.damage > 0 ? Theme.ember : Theme.parchmentDim)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)

            if step.hasCritFace {
                Text("CRIT")
                    .font(.system(size: 7.5, weight: .black))
                    .kerning(0.5)
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 6)
        .frame(width: 70)
    }

    private func orderBadge(_ number: Int, tint: Color) -> some View {
        Text("\(number)")
            .font(.system(size: 9, weight: .black).monospacedDigit())
            .foregroundStyle(Theme.bg)
            .frame(width: 15, height: 15)
            .background(tint, in: .circle)
    }

    /// The crit read-out under a chain: how many crit dice fed it and what the
    /// chain jumps to if its own roll lands.
    @ViewBuilder
    private func critLine(_ step: PlanStep) -> some View {
        if step.comboCritChance > 0 {
            HStack(spacing: 3) {
                Image(systemName: "sparkles").font(.system(size: 9, weight: .bold))
                Text(step.isGuaranteedCrit
                     ? "CRIT GUARANTEED"
                     : "\(step.critDice)◆ · \(Int(step.comboCritChance * 100))% → \(step.critDamage)")
                    .font(.system(size: 9.5, weight: .black).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(Theme.gold)
        } else {
            Color.clear.frame(height: 11)
        }
    }

    private var hintText: String {
        guard engine.phase == .player else { return "Resolving in order..." }
        if engine.playedFaces.isEmpty {
            if !engine.hasRolled { return "Roll your dice first" }
            return engine.stamina == 0 ? "No stamina left" : "Tap dice in — fused chains cost less"
        }
        return "Tap a step to take it back · order matters"
    }

    // MARK: - Freeze

    /// Arm freeze mode, then tap a die in the tray to ice it for next turn.
    /// Free — one a turn — and the pip shows whether it is still in hand.
    private var freezeButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                engine.freezeArmed.toggle()
            }
            Haptics.light()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "snowflake")
                    .font(.system(size: 12, weight: .bold))
                    .symbolEffect(.pulse, isActive: engine.freezeArmed)

                Text("FREEZE")
                    .font(.fantasy(11, weight: .black))
                    .kerning(0.8)

                freezePips
            }
            .foregroundStyle(engine.freezeArmed ? Theme.bg : Theme.frost)
            .frame(width: 112, height: 32)
            .background(freezeBackground, in: .rect(cornerRadius: 11))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(Theme.frost.opacity(engine.freezeArmed ? 0 : 0.5), lineWidth: 1.3)
            )
            .shadow(color: Theme.frost.opacity(engine.freezeArmed ? 0.7 : 0.15),
                    radius: engine.freezeArmed ? 12 : 4)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!canFreeze)
        .opacity(canFreeze ? 1 : 0.4)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: engine.freezeArmed)
    }

    private var canFreeze: Bool {
        guard engine.phase == .player, engine.hasRolled, !engine.isRolling else { return false }
        return engine.freezeArmed || (engine.freezesRemaining > 0 && engine.canFreezeAny)
    }

    /// One pip per freeze; filled pips are still in hand.
    private var freezePips: some View {
        HStack(spacing: 3) {
            ForEach(0..<engine.freezesPerTurn, id: \.self) { index in
                Circle()
                    .fill(index < engine.freezesRemaining
                          ? (engine.freezeArmed ? Theme.bg : Theme.frost)
                          : (engine.freezeArmed ? Theme.bg.opacity(0.3) : Theme.frost.opacity(0.22)))
                    .frame(width: 5, height: 5)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: engine.freezesRemaining)
    }

    private var freezeBackground: AnyShapeStyle {
        engine.freezeArmed
            ? AnyShapeStyle(LinearGradient(colors: [Theme.frost, Theme.steelBlue],
                                           startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(Theme.frost.opacity(0.12))
    }

    // MARK: - Commit

    private var commitButton: some View {
        Button {
            engine.beginCommit()
        } label: {
            VStack(spacing: 1) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15, weight: .bold))
                Text(engine.playedFaces.isEmpty ? "END TURN" : "FIGHT!")
                    .font(.fantasy(12, weight: .black))
            }
            .foregroundStyle(engine.canCommit ? Theme.bg : Theme.parchmentDim)
            .frame(width: 112, height: 61)
            .background(
                engine.canCommit
                    ? AnyShapeStyle(LinearGradient(colors: [Theme.gold, Theme.ember], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Theme.bgCard),
                in: .rect(cornerRadius: 16)
            )
            .shadow(color: engine.canCommit ? Theme.ember.opacity(0.4) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!engine.canCommit)
    }
}
