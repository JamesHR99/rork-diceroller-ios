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

    /// The seam the player tapped, showing its preview card.
    @State private var previewing: BattleEngine.WeldCandidate?
    /// A transform offer the player asked to see.
    @State private var transforming: BattleEngine.WeldCandidate?
    /// Drives the short pull-together when a weld lands.
    @State private var weldPulse = 0

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
        .sheet(item: $previewing) { candidate in
            CombinePreviewView(engine: engine, candidate: candidate) {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                    engine.combine(candidate)
                    weldPulse += 1
                }
            }
        }
        .sheet(item: $transforming) { candidate in
            CombinePreviewView(engine: engine, candidate: candidate) {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                    engine.transform(into: candidate)
                    weldPulse += 1
                }
            }
        }
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
                            PharaohSWagerStaminaPip(
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
                    PharaohSWagerIcon(name: PharaohSWagerArt.echoMarker, size: 16)
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

    /// The plan, in the order it will resolve. Loose dice draw as single tiles;
    /// anything you chose to combine draws as one card carrying its ingredient
    /// dice. A run that *could* be combined wears a quiet seam you may tap —
    /// it is an offer, never something applied for you.
    private var planRow: some View {
        let steps = engine.displayedPlan
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    if step.isCombo {
                        combinedCard(step)
                    } else if let face = step.faces.first {
                        planDieCard(face)
                    }

                    // Between two loose dice that would make something, the
                    // seam itself is the offer. Tapping it opens the preview;
                    // ignoring it leaves the dice exactly as they are.
                    if let candidate = seam(after: index, in: steps) {
                        seamButton(candidate)
                    } else if index < steps.count - 1 {
                        Spacer().frame(width: 5)
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
        .animation(.spring(response: 0.34, dampingFraction: 0.62), value: engine.weldedGroups.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: weldPulse)
    }

    /// The seam sitting between two adjacent loose dice, when the run they
    /// belong to completes a real recipe. Combined cards never wear one — they
    /// are already joined, and Separate is how they come apart.
    ///
    /// A run of three or more only ever wears ONE seam, at its opening gap, so
    /// a three-die recipe does not appear to be two separate offers.
    private func seam(after index: Int, in steps: [PlanStep]) -> BattleEngine.WeldCandidate? {
        guard engine.phase == .player, index < steps.count - 1 else { return nil }
        guard !steps[index].isCombo, !steps[index + 1].isCombo else { return nil }
        guard let left = steps[index].faces.last,
              let right = steps[index + 1].faces.first else { return nil }
        return engine.weldCandidates.first {
            $0.faceIDs.first == left.id && $0.faceIDs.contains(right.id)
        }
    }

    /// A quiet copper join between two dice: how many dice it would take, and
    /// nothing about what it makes. Reading the recipe costs a tap.
    private func seamButton(_ candidate: BattleEngine.WeldCandidate) -> some View {
        Button {
            Haptics.light()
            Audio.shared.play(.uiTap)
            previewing = candidate
        } label: {
            VStack(spacing: 1) {
                PharaohSWagerSymbol(art: PharaohSWagerArt.echoMarker,
                                    fallback: "link",
                                    size: compact ? 13 : 15,
                                    tint: Theme.gold)
                Text("\(candidate.faceIDs.count)")
                    .font(.system(size: 7.5, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.gold.opacity(0.9))
            }
            .frame(width: compact ? 20 : 23, height: bodyHeight * 0.52)
            .background {
                Capsule().fill(Theme.bg.opacity(0.65))
            }
            .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1))
            .shadow(color: Theme.gold.opacity(0.3), radius: 5)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, 1.5)
        .transition(.scale(scale: 0.6).combined(with: .opacity))
    }

    /// An action you welded together: its name, its ingredient dice, its cost,
    /// and the controls to pull it apart or grow it. Tapping the body opens the
    /// same card you combined from, so you can re-read what it does.
    private func combinedCard(_ step: PlanStep) -> some View {
        let combo = step.combo
        let tint = combo?.tint ?? Theme.gold
        let known = engine.isChainKnown(step)
        let transform = step.faces.first.flatMap { engine.transformOffer(faceID: $0.id) }
        // Every row hangs off the same left edge. Without an explicit leading
        // alignment the name and the timing lines centre themselves while the
        // dice row stays left, which is what made a four- or five-die card
        // read as overlapping text.
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(engine.planTitle(for: step).uppercased())
                    .font(.fantasy(compact ? 11 : 12.5, weight: .black))
                    .kerning(0.6)
                    .foregroundStyle(known ? tint : Theme.parchmentDim)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(step.staminaCost)")
                    .font(.system(size: 10, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.gold)
            }

            // The real dice that went in, so what you spent stays visible. A
            // wide recipe draws its dice slightly smaller rather than shoving
            // the rest of the card sideways.
            HStack(spacing: 2) {
                ForEach(step.faces) { face in
                    PharaohSWagerSymbol(art: face.face.artName,
                                        fallback: face.face.symbol,
                                        size: iconSize(for: step.faces.count),
                                        tint: face.isCrit ? Theme.gold : face.face.tint)
                }
                Spacer(minLength: 0)
            }

            if let staged = combo?.stagedBeats {
                Text("\(staged.guardFirst.uppercased()) → \(staged.strikeLater.uppercased())")
                    .font(.system(size: 7.5, weight: .black))
                    .foregroundStyle(Theme.steel)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let line = engine.chiselLine(for: step) {
                Text(line)
                    .font(.system(size: 7.5, weight: .black))
                    .foregroundStyle(Theme.ptahCopper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // A held die inside this action carries its god's upgrade, so the
            // card repeats what the die already promised — the bonus is
            // visible on both the die and the action it ends up in.
            if let held = heldUpgrade(in: step) {
                HStack(spacing: 2) {
                    PharaohSWagerSymbol(art: held.god.artName, fallback: held.god.symbol,
                                        size: 10, tint: held.god.tint)
                    Text(held.effect.uppercased())
                        .font(.system(size: 7.5, weight: .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .foregroundStyle(held.god.tint)
            }

            Spacer(minLength: 0)

            HStack(spacing: 3) {
                smallControl("SEPARATE", tint: Theme.parchmentDim) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                        if let face = step.faces.first { engine.separate(faceID: face.id) }
                    }
                }
                if let transform {
                    smallControl("GROW", tint: Theme.gold) {
                        transforming = transform
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, compact ? 5 : 7)
        .frame(width: cardWidth(for: step.faces.count), height: bodyHeight, alignment: .topLeading)
        .background {
            PapyrusSurface(ground: .card, tint: Theme.bgCard, strength: 0.75, shade: 0.3)
                .clipShape(.rect(cornerRadius: 12))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(tint.opacity(0.85), lineWidth: 2)
        )
        .shadow(color: tint.opacity(0.35), radius: 8)
        .contentShape(.rect)
        .onTapGesture {
            guard engine.phase == .player, let combo else { return }
            previewing = BattleEngine.WeldCandidate(
                faceIDs: step.faces.map(\.id), combo: combo, position: 0
            )
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    /// The god upgrade riding a held die inside this action, if any.
    private func heldUpgrade(in step: PlanStep) -> (god: Deity, name: String, effect: String)? {
        for face in step.faces where face.wasHeld {
            if let held = engine.heldBoon(forFace: face.id) { return held }
        }
        return nil
    }

    /// Ingredient dice shrink a touch past three so five of them still sit on
    /// one line inside the card.
    private func iconSize(for dice: Int) -> CGFloat {
        let base: CGFloat = compact ? 17 : 20
        guard dice > 3 else { return base }
        return base - CGFloat(dice - 3) * 2
    }

    /// A combined card grows with the dice it swallowed, so a five-die working
    /// reads as the big thing it is — and so its name and timing lines have
    /// somewhere to sit. Width is whichever is larger: the room the name needs,
    /// or the room the dice need.
    private func cardWidth(for dice: Int) -> CGFloat {
        let base: CGFloat = compact ? 92 : 104
        let forName = base + CGFloat(max(0, dice - 2)) * (compact ? 16 : 18)
        let forDice = CGFloat(dice) * (iconSize(for: dice) + 2) + 20
        return max(forName, forDice)
    }

    private func smallControl(_ title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            Audio.shared.play(.uiTap)
            action()
        } label: {
            Text(title)
                .font(.system(size: 7.5, weight: .black))
                .kerning(0.5)
                .foregroundStyle(tint)
                .padding(.horizontal, 5)
                .padding(.vertical, 2.5)
                .background {
                    Capsule().fill(Theme.bg.opacity(0.55))
                }
                .overlay(Capsule().strokeBorder(tint.opacity(0.5), lineWidth: 0.8))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(engine.phase != .player)
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
                PharaohSWagerSymbol(art: face.face.artName,
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
                    PharaohSWagerIcon(name: PharaohSWagerArt.upgradeHammer, size: 16)
                        .padding(3)
                        .shadow(color: Theme.ptahCopper.opacity(0.7), radius: 5)
                } else if armable {
                    PharaohSWagerIcon(name: PharaohSWagerArt.upgradeHammer, size: 16)
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
                    PharaohSWagerIcon(name: PharaohSWagerArt.interactionHeld, size: 20)

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
    ///
    /// Anubis's Preserved Moment rides as an extra pip in his own colour, so
    /// the spare hold is something you can see sitting in the bar rather than a
    /// rule you have to remember — and it visibly leaves once a commitment
    /// actually spends it.
    private var freezePips: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<engine.freezesPerTurn, id: \.self) { index in
                let inHand = index < engine.freezesRemaining
                let isAnubisPip = engine.hasPreservedMomentSpare
                    && index == engine.freezesPerTurn - 1
                PharaohSWagerImage(
                    name: inHand ? PharaohSWagerArt.staminaFull : PharaohSWagerArt.staminaEmpty,
                    height: isAnubisPip ? 12.5 : 11,
                    fit: .fit
                )
                .colorMultiply(engine.freezeArmed
                               ? Theme.bg
                               : (isAnubisPip ? Deity.anubis.tint : Theme.frost))
                .opacity(inHand ? 1 : 0.35)
                .shadow(color: isAnubisPip && inHand && !engine.freezeArmed
                        ? Deity.anubis.tint.opacity(0.9)
                        : .clear,
                        radius: 5)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: engine.freezesRemaining)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: engine.freezesPerTurn)
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
