import SwiftUI

/// Bottom play bar — the centre of the turn. A slim stamina rail on the far
/// left, the tall turn plan taking the whole middle (fused combos drawn as one
/// welded card), and the freeze / commit buttons on the right.
struct PlayBarView: View {
    let engine: BattleEngine

    /// How tall the plan cards run. Everything in the bar is sized off this, and
    /// the deck measures the screen it has to fit into before handing it down —
    /// on a short landscape iPhone the whole plan stays on screen instead of
    /// running off the bottom edge.
    var bodyHeight: CGFloat = 116

    /// A short screen tightens the type and the padding rather than dropping a
    /// row out of the read.
    private var compact: Bool { bodyHeight < 104 }

    /// The plan panel's full height. The freeze and commit slabs beside it are
    /// cut from the same measure so the row reads as one shelf.
    private var columnHeight: CGFloat { bodyHeight + (compact ? 22 : 28) }
    private var freezeHeight: CGFloat { min(42, columnHeight * 0.3) }
    private var commitHeight: CGFloat { max(46, columnHeight - freezeHeight - 6) }

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
        .padding(.vertical, compact ? 2 : 4)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: engine.hasCombo)
    }

    // MARK: - Stamina rail

    /// Stamina now lives in a narrow column so the plan can have the width.
    private var staminaRail: some View {
        VStack(spacing: 4) {
            Text("STM")
                .font(.system(size: 8, weight: .black))
                .kerning(0.8)
                .foregroundStyle(Theme.gold.opacity(0.8))

            staminaPips

            Spacer(minLength: 0)

            VStack(spacing: 0) {
                Text("NEXT")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(Theme.parchmentDim.opacity(0.7))
                Text("\(engine.projectedNextTurnStamina)")
                    .font(.system(size: 12.5, weight: .black).monospacedDigit())
                    .foregroundStyle(engine.projectedNextTurnStamina > engine.roundAllowance
                                     ? Theme.sunGold : Theme.parchmentDim)
            }
        }
        .frame(width: 48, height: columnHeight - 8)
        .padding(.vertical, 4)
        .background {
            PapyrusSurface(ground: .card, tint: Theme.bg, strength: 0.6, shade: 0.45)
                .clipShape(.rect(cornerRadius: 13))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1)
        )
    }

    /// Painted pips stack down the rail, wrapping into a second column once
    /// the turn's budget runs long. Pips above the cap wear the reserve mark.
    private var staminaPips: some View {
        // The round's own allowance sets the rail; anything above it is
        // overcharge a named power earned, and wears the reserve mark.
        let total = max(engine.roundAllowance, engine.stamina)
        // Four to a column, so a five or six point round wraps instead of
        // running the pips off the bottom of the rail.
        let columns = total > 4 ? 2 : 1
        let perColumn = Int(ceil(Double(total) / Double(columns)))
        let size = pipSize(perColumn: perColumn, columns: columns)
        return HStack(alignment: .top, spacing: 3) {
            ForEach(0..<columns, id: \.self) { column in
                VStack(spacing: 2) {
                    ForEach(0..<perColumn, id: \.self) { row in
                        let index = column * perColumn + row
                        if index < total {
                            DuatStaminaPip(
                                isFilled: index < engine.stamina,
                                isReserve: index >= engine.roundAllowance,
                                size: size
                            )
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: engine.stamina)
    }

    /// Pips cut to the room the rail actually has. A five or six point round was
    /// drawing its pips at the same size as a three point one and spilling out
    /// of the rail, so the column measures both axes and takes the smaller fit.
    private func pipSize(perColumn: Int, columns: Int) -> CGFloat {
        // The rail's inner width, shared by however many columns are up.
        let byWidth = (44 - CGFloat(columns - 1) * 3) / CGFloat(columns)
        // What is left between the STM heading and the NEXT readout.
        let free = columnHeight - 8 - 44
        let byHeight = free / CGFloat(max(perColumn, 1)) - 2
        return max(9, min(17, min(byWidth, byHeight)))
    }

    // MARK: - Turn plan

    private var plan: [PlanStep] { engine.displayedPlan }

    private var planSection: some View {
        VStack(spacing: compact ? 2 : 3) {
            planHeader
            planRow
        }
        .padding(.horizontal, 9)
        .padding(.vertical, compact ? 4 : 6)
        .frame(maxWidth: .infinity)
        .background {
            PapyrusSurface(ground: .panel, tint: Theme.bg, strength: 0.55, shade: 0.5)
                .clipShape(.rect(cornerRadius: 15))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(
                    engine.hasCombo ? Theme.ember.opacity(0.7) : Theme.gold.opacity(0.28),
                    lineWidth: engine.hasCombo ? 2 : 1
                )
        )
        .shadow(color: Theme.ember.opacity(engine.hasCombo ? 0.3 : 0), radius: 14)
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first, let faceID = UUID(uuidString: idString) else { return false }
            engine.placeInPlayBar(faceID: faceID)
            return true
        }
    }

    private var planHeader: some View {
        HStack(spacing: 8) {
            Text("TURN PLAN")
                .font(.fantasy(12, weight: .black))
                .kerning(1.4)
                .foregroundStyle(Theme.gold.opacity(0.85))

            Text(engine.armingChisel.map { "\($0.name.uppercased()) — tap a chain to spend it" } ?? hintText)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(engine.armingChisel != nil
                                 ? Theme.ptahCopper
                                 : Theme.parchmentDim.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            if engine.hasEchoPending {
                HStack(spacing: 3) {
                    DuatIcon(name: DuatArt.echoMarker, size: 16)
                    Text("ECHO WAITS")
                        .font(.system(size: 10.5, weight: .black))
                        .kerning(0.8)
                }
                .foregroundStyle(Theme.ptahCopper)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else if engine.projectedDamage > 0 {
                HStack(spacing: 3) {
                    DuatIcon(name: DuatArt.Status.critical, size: 15)
                    Text("\(engine.projectedDamage) TOTAL DMG")
                        .font(.system(size: 12, weight: .black).monospacedDigit())
                }
                .foregroundStyle(Theme.ember)
                .shadow(color: Theme.ember.opacity(0.6), radius: 5)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .frame(height: compact ? 14 : 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: engine.projectedDamage)
    }

    private var planRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(Array(plan.enumerated()), id: \.element.id) { index, step in
                    planCard(step, number: index + 1, isActive: engine.activeStepIndex == index)

                    if index < plan.count - 1 {
                        DuatImage(name: DuatArt.chainConnector, width: 18, fit: .fit)
                            .colorMultiply(Theme.parchmentDim)
                            .opacity(0.65)
                    }
                }

                // Nothing stands in for stamina you have not spent — an empty
                // plan just reads as empty.
            }
            .padding(.horizontal, 1)
            .frame(minHeight: bodyHeight, alignment: .leading)
        }
        .frame(height: bodyHeight)
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: engine.playOrder)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: engine.activeStepIndex)
    }

    @ViewBuilder
    private func planCard(_ step: PlanStep, number: Int, isActive: Bool) -> some View {
        // While a copper mark is held up, the chains it can ride glow and a
        // tap arms it there instead of breaking the chain apart.
        let armable = engine.armableChisel(for: step)
        Button {
            guard engine.phase == .player else { return }
            if engine.armHeldChisel(onto: step) { return }
            if engine.armingChisel != nil {
                // A held mark makes every other tap a miss rather than an
                // accidental dismantling of the plan.
                engine.cancelArming()
                return
            }
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
            .background {
                // Every step is a slab of painted paper, so a plan reads as a
                // row of carved tablets rather than flat chips.
                PapyrusSurface(ground: .card, tint: Theme.bgCard, strength: 0.7, shade: 0.34)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .overlay {
                // A fused chain wears its own colour as an inner wash so it
                // reads as one welded object, not a run of loose chips.
                if step.isCombo {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(colors: [step.tint.opacity(0.26), .clear],
                                           startPoint: .bottom, endPoint: .top)
                        )
                        .allowsHitTesting(false)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(step.tint.opacity(isActive ? 1 : (step.isCombo ? 0.75 : 0.45)),
                                  lineWidth: isActive ? 2.6 : (step.isCombo ? 2 : 1.2))
            )
            .shadow(color: step.tint.opacity(isActive ? 0.85 : (step.isCombo ? 0.45 : 0)),
                    radius: isActive ? 12 : 6)
            .scaleEffect(isActive ? 1.06 : 1)
            // A chain the held Chisel could ride wears Ptah's copper until it
            // is either taken or the mark is put back down.
            .overlay {
                if armable != nil {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.ptahCopper, lineWidth: 2.4)
                        .shadow(color: Theme.ptahCopper.opacity(0.8), radius: 9)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .topTrailing) {
                // A copper hammer when an optional Chisel rides this recipe,
                // and a beckoning one while a mark is waiting to be placed.
                if engine.isComboArmed(step) {
                    DuatIcon(name: DuatArt.upgradeHammer, size: 18)
                        .padding(5)
                        .shadow(color: Theme.ptahCopper.opacity(0.7), radius: 5)
                } else if armable != nil {
                    DuatIcon(name: DuatArt.upgradeHammer, size: 18)
                        .padding(5)
                        .opacity(0.65)
                        .shadow(color: Theme.ptahCopper.opacity(0.6), radius: 6)
                }
            }
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
        VStack(alignment: .leading, spacing: compact ? 2 : 3) {
            HStack(spacing: 4) {
                orderBadge(number, tint: step.tint)

                Text(step.title.uppercased())
                    .font(.fantasy(compact ? 15.5 : 18, weight: .black))
                    .kerning(0.5)
                    .foregroundStyle(step.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                Spacer(minLength: 2)

                targetChip(step)

                beatChip(step)

                Text("\(step.faces.count)-CHAIN")
                    .font(.system(size: 10, weight: .black))
                    .kerning(0.5)
                    .foregroundStyle(Theme.bg)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(step.tint, in: .capsule)

                // The painted cost badge carries the stamina this step spends.
                Text("\(step.staminaCost)")
                    .font(.system(size: 12, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.parchment)
                    .frame(width: 26, height: 26)
                    .background {
                        DuatImage(name: DuatArt.costBadge, width: 28, height: 28, fit: .fit)
                            .modifier(TintWash(
                                tint: step.staminaCost < step.faces.count ? Theme.sunGold : nil
                            ))
                    }
            }

            weldedFaces(step)

            Text(step.valueLine)
                .font(.system(size: 11.5, weight: .bold).monospacedDigit())
                .foregroundStyle(step.damage > 0 ? Theme.ember : Theme.parchment.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let chiselLine = engine.chiselLine(for: step) {
                Text(chiselLine)
                    .font(.system(size: 9.5, weight: .black))
                    .kerning(0.4)
                    .foregroundStyle(Theme.ptahCopper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            critLine(step)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, compact ? 5 : 7)
        .frame(minWidth: compact ? 174 : 190, maxWidth: 320, alignment: .leading)
    }

    /// The chain's faces, welded together by the painted connector rather
    /// than spaced apart — a chain reads as one object, not a run of chips.
    private func weldedFaces(_ step: PlanStep) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(step.faces.enumerated()), id: \.element.id) { index, face in
                DuatSymbol(art: face.face.artName,
                           fallback: face.face.symbol,
                           size: compact ? 23 : 28,
                           tint: face.isCrit ? Theme.gold : (face.patron?.tint ?? face.face.tint))
                    .modifier(FaceWash(tint: Theme.gold, active: face.isCrit))
                    .frame(width: compact ? 28 : 34, height: compact ? 26 : 32)
                    .background(Theme.bg.opacity(0.55), in: .rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(face.isCrit ? Theme.gold.opacity(0.9) : step.tint.opacity(0.5),
                                          lineWidth: 1)
                    )
                    .shadow(color: face.isCrit ? Theme.gold.opacity(0.7) : .clear, radius: 4)

                if index < step.faces.count - 1 {
                    DuatImage(name: DuatArt.chainConnector, width: compact ? 11 : 14, fit: .fit)
                        .colorMultiply(step.tint)
                }
            }
        }
    }

    /// A face played on its own — deliberately small next to a real chain.
    private func soloCard(_ step: PlanStep, number: Int) -> some View {
        VStack(spacing: compact ? 2 : 3) {
            HStack(spacing: 3) {
                orderBadge(number, tint: step.tint)
                beatChip(step)
            }

            targetChip(step)

            DuatSymbol(art: step.faces.first?.face.artName,
                       fallback: step.faces.first?.face.symbol ?? "questionmark",
                       size: compact ? 28 : 34,
                       tint: step.tint)

            Text(step.title.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(Theme.parchment.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(step.valueLine)
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(step.damage > 0 ? Theme.ember : Theme.parchmentDim)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)

            if step.hasCritFace {
                Text("CRIT")
                    .font(.system(size: 9, weight: .black))
                    .kerning(0.5)
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, compact ? 5 : 7)
        .frame(width: compact ? 74 : 82)
    }

    private func orderBadge(_ number: Int, tint: Color) -> some View {
        Text("\(number)")
            .font(.system(size: 11, weight: .black).monospacedDigit())
            .foregroundStyle(Theme.bg)
            .frame(width: 18, height: 18)
            .background(tint, in: .circle)
            .overlay(Circle().strokeBorder(Theme.bg.opacity(0.5), lineWidth: 0.8))
    }

    /// The beat this step lands on, in the same numerals the hour strip uses.
    /// Reordering the plan moves it, so a card always says when it will fire.
    @ViewBuilder
    private func beatChip(_ step: PlanStep) -> some View {
        if let beat = engine.beat(for: step) {
            HStack(spacing: 1.5) {
                Image(systemName: "hourglass")
                    .font(.system(size: 7, weight: .black))
                Text("\(beat)")
                    .font(.system(size: 9, weight: .black).monospacedDigit())
            }
            .foregroundStyle(Theme.bg)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Theme.frost, in: .capsule)
        }
    }

    /// Who this attack is pointed at, on the card itself. The old targeting
    /// popup is gone: the foe is chosen by tapping the fighter on the deck, and
    /// this chip is both the read of where the blow is going and the control
    /// that says which attack the next tap will point. Only drawn when there is
    /// more than one foe standing — a single foe needs no aiming.
    @ViewBuilder
    private func targetChip(_ step: PlanStep) -> some View {
        if engine.canTarget, step.targetsEnemy {
            let isPointing = engine.activeTargetingStep?.id == step.id
            let foe = engine.enemies.first { $0.id == engine.allocatedFoeID(for: step) }
            Button {
                engine.selectTargeting(step.id)
            } label: {
                HStack(spacing: 2) {
                    DuatSymbol(art: DuatArt.Status.marked, fallback: "target",
                               size: 9, tint: isPointing ? Theme.bg : Theme.parchmentDim)
                    Text(foe?.displayName.uppercased() ?? "—")
                        .font(.system(size: 8, weight: .black))
                        .kerning(0.3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundStyle(isPointing ? Theme.bg : Theme.parchmentDim)
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .frame(maxWidth: 92)
                .background(isPointing ? Theme.gold : Theme.bg.opacity(0.7), in: .capsule)
                .overlay(
                    Capsule().strokeBorder(Theme.gold.opacity(isPointing ? 1 : 0.35),
                                           lineWidth: isPointing ? 1.4 : 0.8)
                )
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(engine.phase != .player)
        }
    }

    /// The crit read-out under a chain: how many crit dice fed it and what the
    /// chain jumps to if its own roll lands.
    @ViewBuilder
    private func critLine(_ step: PlanStep) -> some View {
        if step.comboCritChance > 0 {
            HStack(spacing: 3) {
                DuatIcon(name: DuatArt.Status.critical, size: 15)
                Text(step.isGuaranteedCrit
                     ? "CRIT GUARANTEED"
                     : "\(step.critDice)◆ · \(Int(step.comboCritChance * 100))% → \(step.critDamage)")
                    .font(.system(size: 11, weight: .black).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(Theme.gold)
        } else {
            Color.clear.frame(height: compact ? 10 : 13)
        }
    }

    private var hintText: String {
        guard engine.phase == .player else { return "Resolving in order..." }
        if engine.playedFaces.isEmpty {
            if !engine.hasRolled { return "Roll your dice first" }
            return engine.stamina == 0 ? "No stamina left" : "Tap dice in — fused chains cost less"
        }
        if engine.canTarget {
            return "Tap a foe to aim the lit attack · order matters"
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
            VStack(spacing: 1) {
                HStack(spacing: 5) {
                    DuatIcon(name: DuatArt.interactionHeld, size: 20)

                    Text("FREEZE")
                        .font(.fantasy(15, weight: .black))
                        .kerning(1.2)
                }
                freezePips
            }
            .foregroundStyle(engine.freezeArmed ? Theme.bg : Theme.frost)
            .shadow(color: engine.freezeArmed ? .clear : .black.opacity(0.7), radius: 2, y: 1)
            .frame(width: 128, height: freezeHeight)
            .background {
                DeckButtonSurface(
                    tone: .secondary,
                    state: engine.freezeArmed ? .selected : (canFreeze ? .normal : .disabled),
                    rim: Theme.frost,
                    emphasis: engine.freezeArmed ? 1 : 0
                )
                .modifier(TintWash(tint: engine.freezeArmed ? Theme.frost : nil))
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!canFreeze)
        .opacity(canFreeze ? 1 : 0.45)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: engine.freezeArmed)
    }

    private var canFreeze: Bool {
        guard engine.phase == .player, engine.hasRolled, !engine.isRolling else { return false }
        return engine.freezeArmed || (engine.freezesRemaining > 0 && engine.canFreezeAny)
    }

    /// One painted pip per freeze; filled pips are still in hand.
    private var freezePips: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<engine.freezesPerTurn, id: \.self) { index in
                DuatImage(
                    name: index < engine.freezesRemaining ? DuatArt.staminaFull : DuatArt.staminaEmpty,
                    height: 11,
                    fit: .fit
                )
                .colorMultiply(engine.freezeArmed ? Theme.bg : Theme.frost)
                .opacity(index < engine.freezesRemaining ? 1 : 0.35)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: engine.freezesRemaining)
    }

    // MARK: - Commit

    private var commitButton: some View {
        let armed = engine.canCommit && !engine.playedFaces.isEmpty
        return Button {
            engine.beginCommit()
            Haptics.medium()
        } label: {
            VStack(spacing: 2) {
                DuatIcon(name: DuatArt.Status.burn, size: compact ? 21 : 26)
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
            .frame(width: 128, height: commitHeight)
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
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: armed)
    }
}
