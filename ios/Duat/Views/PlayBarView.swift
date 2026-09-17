import SwiftUI

/// Bottom play bar — the centre of the turn. A slim stamina rail on the far
/// left, the turn plan taking the whole middle, and the freeze / commit buttons
/// on the right.
///
/// The plan is deliberately only an *order*: one numbered tile per die, in the
/// sequence they will resolve. It never groups chained dice, never names a
/// chain and never totals the damage — a chain is a complete surprise until it
/// fires. The stamina rail still prints the cost, because a cost is not a
/// spoiler.
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

    /// The plan as a flat run of dice in play order. Chains still form behind
    /// the scenes; they simply are not drawn here.
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
                    DuatIcon(name: DuatArt.echoMarker, size: 16)
                    Text("ECHO WAITS")
                        .font(.system(size: 10.5, weight: .black))
                        .kerning(0.8)
                }
                .foregroundStyle(Theme.ptahCopper)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else if !planFaces.isEmpty {
                Text("\(planFaces.count) \(planFaces.count == 1 ? "DIE" : "DICE")")
                    .font(.system(size: 11, weight: .black).monospacedDigit())
                    .kerning(0.8)
                    .foregroundStyle(Theme.gold.opacity(0.75))
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .frame(height: compact ? 14 : 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: planFaces.count)
    }

    /// The plan: one tile per die, in the order they will resolve. No numbers,
    /// no connectors, no grouping — the row says what you will play and in what
    /// order, and nothing about what it will add up to.
    private var planRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(planFaces) { face in
                    planDieCard(face)
                }

                // Nothing stands in for stamina you have not spent — an empty
                // plan just reads as empty.
            }
            .padding(.horizontal, 1)
            .frame(minHeight: bodyHeight, alignment: .leading)
        }
        .frame(height: bodyHeight)
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: engine.playOrder)
    }

    /// One die in the plan: its face and what that face does on its own. Its
    /// place in the row is its order. Tapping takes it back; dragging reorders.
    private func planDieCard(_ face: RolledFace) -> some View {
        let tint = face.isCrit ? Theme.gold : (face.patron?.tint ?? face.face.tint)
        // A held copper mark lights the dice whose hidden chain could carry it.
        // The plan never names that chain — the die simply glows and takes the
        // mark, so a Chisel can still be spent without giving the chain away.
        let armable = engine.armableChisel(forFace: face.id) != nil
        let armed = engine.isChiselArmed(onFace: face.id)
        return Button {
            guard engine.phase == .player else { return }
            if engine.armHeldChisel(ontoFace: face.id) { return }
            if engine.armingChisel != nil {
                // A held mark makes every other tap a miss rather than an
                // accidental dismantling of the plan.
                engine.cancelArming()
                return
            }
            engine.returnToTray(faceID: face.id)
        } label: {
            VStack(spacing: compact ? 3 : 5) {
                DuatSymbol(art: face.face.artName,
                           fallback: face.face.symbol,
                           size: compact ? 30 : 36,
                           tint: tint)
                    .modifier(FaceWash(tint: Theme.gold, active: face.isCrit))

                Text(face.face.label.uppercased())
                    .font(.system(size: 9.5, weight: .black))
                    .kerning(0.4)
                    .foregroundStyle(Theme.parchment.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(face.face.soloTag)
                    .font(.system(size: 9.5, weight: .bold).monospacedDigit())
                    .foregroundStyle(Theme.parchmentDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if face.isCrit {
                    Text("CRIT")
                        .font(.system(size: 8.5, weight: .black))
                        .kerning(0.5)
                        .foregroundStyle(Theme.gold)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, compact ? 5 : 7)
            .frame(width: compact ? 76 : 84, height: bodyHeight)
            .background {
                PapyrusSurface(ground: .card, tint: Theme.bgCard, strength: 0.7, shade: 0.34)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(tint.opacity(face.isCrit ? 0.9 : 0.45),
                                  lineWidth: face.isCrit ? 2 : 1.2)
            )
            .shadow(color: face.isCrit ? Theme.gold.opacity(0.5) : .clear, radius: 6)
            .overlay {
                if armable {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.ptahCopper, lineWidth: 2.4)
                        .shadow(color: Theme.ptahCopper.opacity(0.8), radius: 9)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .topTrailing) {
                if armed {
                    DuatIcon(name: DuatArt.upgradeHammer, size: 16)
                        .padding(3)
                        .shadow(color: Theme.ptahCopper.opacity(0.7), radius: 5)
                } else if armable {
                    DuatIcon(name: DuatArt.upgradeHammer, size: 16)
                        .padding(3)
                        .opacity(0.65)
                        .shadow(color: Theme.ptahCopper.opacity(0.6), radius: 6)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(engine.phase != .player)
        .draggable(face.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first,
                  let droppedID = UUID(uuidString: idString) else { return false }
            engine.placeInPlayBar(faceID: droppedID, before: face.id)
            return true
        }
        .transition(.scale(scale: 0.6).combined(with: .opacity))
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
            Audio.shared.play(.uiTap)
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
            Audio.shared.play(.uiConfirm)
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
