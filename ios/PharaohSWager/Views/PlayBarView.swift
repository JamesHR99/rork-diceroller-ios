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

    /// A seam offering more than one recipe, waiting for the player to pick.
    @State private var picking: SeamChoice?
    /// Drives the short pull-together when a weld lands.
    @State private var weldPulse = 0
    /// The action that just formed, and how far its impact burst has played.
    @State private var burstStepID: UUID?
    @State private var burstProgress: CGFloat = 0

    /// A seam whose dice could make either a smaller or a larger recipe.
    struct SeamChoice: Identifiable {
        let options: [BattleEngine.WeldCandidate]
        /// The die the seam opens on, so the picker pops from that seam.
        let anchorID: UUID
        var id: String { options.map(\.id).joined() }
    }

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
    private var columnHeight: CGFloat { max(94, bodyHeight + (compact ? 22 : 28)) }
    private var freezeHeight: CGFloat { 44 }
    private var commitHeight: CGFloat { columnHeight - freezeHeight - 6 }
    private var controlWidth: CGFloat { compact ? 108 : 120 }

    var body: some View {
        HStack(spacing: 7) {
            staminaRail
            planSection
            VStack(spacing: 6) {
                freezeButton
                commitButton
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, compact ? 2 : 4)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: engine.hasCombo)
    }

    // MARK: - Combining

    /// Welds a run and throws the impact: the dice snap together, the plate
    /// lands with a shock ring and sparks, and the bar kicks once.
    private func performCombine(_ candidate: BattleEngine.WeldCandidate, transform: Bool = false) {
        guard engine.phase == .player else { return }
        Haptics.heavy()
        Audio.shared.play(.chain)
        Audio.shared.play(.diceLock, after: 0.04, volumeScale: 0.7)

        burstStepID = candidate.faceIDs.first
        burstProgress = 0
        withAnimation(.spring(response: 0.26, dampingFraction: 0.52)) {
            if transform {
                engine.transform(into: candidate)
            } else {
                engine.combine(candidate)
            }
            weldPulse += 1
        }
        withAnimation(.easeOut(duration: 0.55)) { burstProgress = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            burstProgress = 0
            burstStepID = nil
        }
    }

    /// When a seam can make both a small and a large recipe, the player picks
    /// rather than the game guessing. Known recipes are named; unknown ones
    /// show only their size, so the discovery is still yours to make.
    private func seamPicker(_ choice: SeamChoice) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("COMBINE HOW MANY?")
                .font(.system(size: 9, weight: .black))
                .kerning(1)
                .foregroundStyle(Theme.gold.opacity(0.75))

            ForEach(choice.options) { option in
                Button {
                    picking = nil
                    performCombine(option)
                } label: {
                    HStack(spacing: 8) {
                        Text("\(option.faceIDs.count)")
                            .font(.system(size: 13, weight: .black).monospacedDigit())
                            .foregroundStyle(Theme.bg)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(option.combo.tint))
                        Text(engine.knowsCombo(option.combo) ? option.combo.name.uppercased()
                                                             : "UNKNOWN RECIPE")
                            .font(.fantasy(13, weight: .black))
                            .kerning(0.5)
                            .foregroundStyle(engine.knowsCombo(option.combo)
                                             ? Theme.parchment : Theme.parchmentDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .frame(minWidth: 190, minHeight: 44, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.bgCard.opacity(0.8))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(option.combo.tint.opacity(0.6), lineWidth: 1)
                    )
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(12)
        .background {
            PapyrusSurface(ground: .panel, tint: Theme.bg, strength: 0.6, shade: 0.45)
                .ignoresSafeArea()
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
        .frame(width: 42, height: columnHeight - 8)
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
                    // seam itself is the offer. Tapping it combines them right
                    // here; ignoring it leaves the dice exactly as they are.
                    if let candidate = seam(after: index, in: steps) {
                        seamButton(candidate, steps: steps, at: index)
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

    /// A gold join between two dice: tap it and they combine on the spot. It
    /// prints how many dice it will take so a three- or four-die recipe is not
    /// a surprise. If the run could make more than one recipe, the tap opens a
    /// small picker instead of guessing for you.
    private func seamButton(_ candidate: BattleEngine.WeldCandidate,
                            steps: [PlanStep], at index: Int) -> some View {
        Button {
            guard let left = steps[index].faces.last,
                  let right = steps[index + 1].faces.first else { return }
            let options = engine.weldOptions(openingAt: left.id, including: right.id)
            if options.count > 1 {
                Haptics.light()
                Audio.shared.play(.uiTap)
                picking = SeamChoice(options: options, anchorID: left.id)
            } else {
                performCombine(options.first ?? candidate)
            }
        } label: {
            VStack(spacing: 1) {
                PharaohSWagerSymbol(art: PharaohSWagerArt.echoMarker,
                                    fallback: "link",
                                    size: compact ? 14 : 16,
                                    tint: Theme.gold)
                Text("\(candidate.faceIDs.count)")
                    .font(.system(size: 8.5, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.gold.opacity(0.95))
            }
            .frame(width: compact ? 26 : 30, height: bodyHeight * 0.56)
            .background {
                Capsule().fill(Theme.bg.opacity(0.7))
            }
            .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.75), lineWidth: 1.2))
            .shadow(color: Theme.gold.opacity(0.45), radius: 6)
            // The tappable area runs the full height of the row, so a seam
            // never demands a precise hit on a narrow capsule.
            .frame(width: compact ? 34 : 38, height: bodyHeight)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        // The picker belongs to this seam, so it pops from this seam rather
        // than from the middle of the bar.
        .popover(isPresented: Binding(
            get: { picking?.anchorID == steps[index].faces.last?.id },
            set: { if !$0 { picking = nil } }
        )) {
            if let choice = picking {
                seamPicker(choice)
                    .presentationCompactAdaptation(.popover)
            }
        }
        .transition(.scale(scale: 0.6).combined(with: .opacity))
    }

    /// Which pending combo a loose die belongs to, so every die a seam would
    /// swallow can wear the same bracket. Seams never overlap, so a die is in
    /// at most one of these.
    private func pendingGroup(for faceID: UUID) -> BattleEngine.WeldCandidate? {
        guard engine.phase == .player else { return nil }
        return engine.weldCandidates.first { $0.faceIDs.contains(faceID) }
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

            // What this action actually does, right on the plate — the whole
            // reason the preview screen is gone.
            if let combo {
                effectChips(combo: combo, step: step)
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
                        performCombine(transform, transform: true)
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
        .shadow(color: tint.opacity(burstStepID == step.id ? 0.9 : 0.35),
                radius: burstStepID == step.id ? 16 : 8)
        // The plate lands: it overshoots, throws a ring and a spray of shards,
        // then settles. This is the moment the dice became one thing.
        .scaleEffect(burstStepID == step.id ? 1 + (1 - burstProgress) * 0.16 : 1)
        .overlay {
            if burstStepID == step.id {
                CombineBurst(progress: burstProgress, tint: tint)
                    .allowsHitTesting(false)
            }
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    /// Damage, defence and statuses as tight chips — the numbers the preview
    /// screen used to carry, now on the plate itself.
    private func effectChips(combo: ComboDef, step: PlanStep) -> some View {
        let scale = step.comboScale
        var chips: [(String, Color)] = []
        let damage = engine.displayedDamage(for: step)
        if damage > 0 { chips.append(("\(damage) DMG", Theme.ember)) }
        if combo.shield > 0 { chips.append(("+\(GameData.scaleUp(combo.shield, by: scale)) SHD", Theme.steel)) }
        if combo.heal > 0 { chips.append(("+\(GameData.scaleUp(combo.heal, by: scale)) HP", Theme.forest)) }
        if combo.evadePercent > 0 { chips.append(("\(combo.evadePercent)% EVA", Theme.steel)) }
        if combo.burnAmount > 0 {
            chips.append(("BURN \(min(GameData.scaleUp(combo.burnAmount, by: scale), GameData.burnStackCap))", Theme.ember))
        }
        if combo.bleedAmount > 0 {
            chips.append(("BLEED \(min(GameData.scaleUp(combo.bleedAmount, by: scale), GameData.bleedStackCap))", Theme.blood))
        }
        if combo.poisonAmount > 0 {
            chips.append(("PSN \(min(GameData.scaleUp(combo.poisonAmount, by: scale), GameData.poisonStackCap))", Theme.venom))
        }
        if combo.weaken > 0 {
            chips.append(("WEAK \(Int(min(combo.weaken, GameData.weakenCeiling) * 100))%", Theme.frost))
        }
        if combo.markPercent > 0 { chips.append(("MARK +\(combo.markPercent)%", Theme.venom)) }
        if combo.pierce > 0 { chips.append(("PRC \(Int(combo.pierce * 100))%", Theme.gold)) }

        return HStack(spacing: 3) {
            ForEach(Array(chips.prefix(4).enumerated()), id: \.offset) { _, chip in
                Text(chip.0)
                    .font(.system(size: 7.5, weight: .black).monospacedDigit())
                    .foregroundStyle(chip.1)
                    .padding(.horizontal, 3.5)
                    .padding(.vertical, 1)
                    .background(chip.1.opacity(0.16), in: .rect(cornerRadius: 3))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            Spacer(minLength: 0)
        }
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
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background {
                    Capsule().fill(Theme.bg.opacity(0.55))
                }
                .overlay(Capsule().strokeBorder(tint.opacity(0.5), lineWidth: 0.8))
                // A pill this small needs a bigger hit area than it draws, or
                // it reads as an unresponsive button.
                .frame(minHeight: 30)
                .contentShape(.rect)
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
        // Every die the neighbouring seam would swallow wears the same gold
        // bracket, so a three- or four-die recipe shows its full reach before
        // you commit to it.
        let group = pendingGroup(for: face.id)
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
            .overlay {
                if let group {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.gold.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        .shadow(color: Theme.gold.opacity(0.5), radius: 7)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .bottomLeading) {
                // Its place in the pending recipe, so "2 of 3" is explicit.
                if let group, let slot = group.faceIDs.firstIndex(of: face.id) {
                    Text("\(slot + 1)/\(group.faceIDs.count)")
                        .font(.system(size: 7.5, weight: .black).monospacedDigit())
                        .foregroundStyle(Theme.bg)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Theme.gold, in: .capsule)
                        .padding(4)
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
        // Dragging is a deliberate press-and-hold. Without this a quick tap is
        // often swallowed by the drag recogniser, which is what made dice in
        // the plan feel unresponsive.
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
            .frame(width: controlWidth, height: freezeHeight)
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
        .accessibilityIdentifier("battle.freeze")
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
