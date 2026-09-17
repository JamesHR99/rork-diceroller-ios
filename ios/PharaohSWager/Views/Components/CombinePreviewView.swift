import SwiftUI

/// The card you get when you tap a seam in the plan: exactly what these dice
/// would make if you welded them, set against what the same dice would do left
/// apart. Nothing here changes the fight — the numbers come from the real
/// `PlanStep` maths, so the preview cannot drift from what actually happens.
struct CombinePreviewView: View {
    let engine: BattleEngine
    let candidate: BattleEngine.WeldCandidate
    /// Called when the player commits to the weld, so the caller can dismiss.
    let onCombine: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let preview = engine.preview(for: candidate) {
                    header(preview)
                    ingredientRow(preview)
                    outcome(preview)
                    if let beats = preview.combo.stagedBeats {
                        timing(beats)
                    }
                    comparison(preview)
                    if !preview.qualifyingGods.isEmpty {
                        gods(preview)
                    }
                    combineButton
                } else {
                    Text("These dice no longer make anything.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                }
            }
            .padding(18)
        }
        .background {
            PapyrusSurface(ground: .panel, tint: Theme.bg, strength: 0.6, shade: 0.5)
                .ignoresSafeArea()
        }
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
    }

    // MARK: - Pieces

    private func header(_ preview: BattleEngine.WeldPreview) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(preview.combo.name.uppercased())
                .font(.fantasy(24, weight: .black))
                .kerning(1.2)
                .foregroundStyle(preview.combo.tint)

            Text(preview.combo.flavor)
                .font(.system(size: 12))
                .italic()
                .foregroundStyle(Theme.parchmentDim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The real dice going in — faces, crit marks and held marks included, so
    /// you can see precisely what is being spent.
    private func ingredientRow(_ preview: BattleEngine.WeldPreview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label("SPENDS")
            HStack(spacing: 6) {
                ForEach(preview.ingredients) { face in
                    VStack(spacing: 2) {
                        PharaohSWagerSymbol(art: face.face.artName,
                                            fallback: face.face.symbol,
                                            size: 26,
                                            tint: face.isCrit ? Theme.gold : face.face.tint)
                        Text(face.face.label.uppercased())
                            .font(.system(size: 7.5, weight: .black))
                            .foregroundStyle(Theme.parchmentDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        if face.isCrit {
                            Text("CRIT")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(Theme.gold)
                        } else if face.wasHeld {
                            Text("HELD")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(Theme.frost)
                        }
                    }
                    .frame(width: 46)
                    .padding(.vertical, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.bgCard.opacity(0.7))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder((face.isCrit ? Theme.gold : Theme.gold.opacity(0.3)),
                                          lineWidth: face.isCrit ? 1.6 : 1)
                    )
                }

                Spacer(minLength: 0)

                VStack(spacing: 1) {
                    Text("\(preview.staminaCost)")
                        .font(.system(size: 19, weight: .black).monospacedDigit())
                        .foregroundStyle(Theme.gold)
                    Text("STAM")
                        .font(.system(size: 7.5, weight: .black))
                        .foregroundStyle(Theme.parchmentDim)
                }
            }
        }
    }

    /// Damage on its own line, then defence, then statuses — never mixed
    /// together, so a status is never mistaken for damage.
    private func outcome(_ preview: BattleEngine.WeldPreview) -> some View {
        let step = preview.combined
        let combo = preview.combo
        return VStack(alignment: .leading, spacing: 6) {
            label("DOES")

            if step.damage > 0 {
                readout("Damage", "\(step.damage)", Theme.ember)
            }
            if combo.pierce > 0 {
                readout("Pierce", "\(Int(combo.pierce * 100))%", Theme.gold)
            }
            if combo.shield > 0 {
                readout("Shield", "+\(GameData.scaleUp(combo.shield, by: step.comboScale))", Theme.steel)
            }
            if combo.heal > 0 {
                readout("Heals", "+\(GameData.scaleUp(combo.heal, by: step.comboScale))", Theme.forest)
            }
            if combo.evadePercent > 0 {
                readout("Evade", "+\(combo.evadePercent)%", Theme.steel)
            }
            if combo.reflect > 0 {
                readout("Reflects", "\(Int(combo.reflect * 100))%", Theme.gold)
            }

            let statuses = statusLines(combo: combo, step: step)
            if !statuses.isEmpty {
                label("LEAVES")
                ForEach(statuses, id: \.name) { entry in
                    readout(entry.name, entry.value, entry.tint)
                }
            }
        }
    }

    /// Statuses with their capped effective gain, so a card never promises
    /// more than the ceiling will actually allow.
    private func statusLines(combo: ComboDef, step: PlanStep)
        -> [(name: String, value: String, tint: Color)] {
        var lines: [(String, String, Color)] = []
        if combo.burnAmount > 0 {
            let raw = GameData.scaleUp(combo.burnAmount, by: step.comboScale)
            lines.append(("Burn", "+\(min(raw, GameData.burnStackCap))", Theme.ember))
        }
        if combo.bleedAmount > 0 {
            let raw = GameData.scaleUp(combo.bleedAmount, by: step.comboScale)
            lines.append(("Bleed", "\(min(raw, GameData.bleedStackCap))", Theme.blood))
        }
        if combo.poisonAmount > 0 {
            let raw = GameData.scaleUp(combo.poisonAmount, by: step.comboScale)
            lines.append(("Poison", "+\(min(raw, GameData.poisonStackCap))", Theme.venom))
        }
        if combo.weaken > 0 {
            let capped = min(combo.weaken, GameData.weakenCeiling)
            lines.append(("Weaken", "\(Int(capped * 100))%", Theme.frost))
        }
        if combo.markPercent > 0 {
            lines.append(("Mark", "+\(combo.markPercent)%", Theme.venom))
        }
        if combo.regenAmount > 0 {
            lines.append(("Regen", "\(combo.regenAmount)×\(combo.regenTurns)", Theme.forest))
        }
        return lines.map { (name: $0.0, value: $0.1, tint: $0.2) }
    }

    /// A staged recipe says both of its moments out loud, because the whole
    /// point is that the guard is standing before the blow arrives.
    private func timing(_ beats: (guardFirst: String, strikeLater: String)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            label("TIMING")
            beat("1", beats.guardFirst, Theme.steel)
            beat("2", beats.strikeLater, Theme.ember)
        }
    }

    private func beat(_ number: String, _ text: String, _ tint: Color) -> some View {
        HStack(spacing: 7) {
            Text(number)
                .font(.system(size: 10, weight: .black).monospacedDigit())
                .foregroundStyle(Theme.bg)
                .frame(width: 16, height: 16)
                .background(Circle().fill(tint))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.parchment)
        }
    }

    /// The honest alternative: what these same dice do if you leave them
    /// alone. A smaller recipe is allowed to be the better play.
    private func comparison(_ preview: BattleEngine.WeldPreview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            label("OR LEAVE THEM APART")
            HStack(spacing: 10) {
                Text("\(preview.separateSteps.count) separate actions")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.parchmentDim)
                Spacer(minLength: 0)
                if preview.separateDamage > 0 {
                    Text("\(preview.separateDamage) dmg")
                        .font(.system(size: 12, weight: .black).monospacedDigit())
                        .foregroundStyle(Theme.parchmentDim)
                }
                Text("\(preview.separateStamina) stam")
                    .font(.system(size: 12, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.parchmentDim)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.bgCard.opacity(0.5))
        }
    }

    private func gods(_ preview: BattleEngine.WeldPreview) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            label("GODS WHO ANSWER")
            HStack(spacing: 6) {
                ForEach(preview.qualifyingGods, id: \.self) { god in
                    Text(god.name.uppercased())
                        .font(.system(size: 9.5, weight: .black))
                        .kerning(0.6)
                        .foregroundStyle(god.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule().fill(god.tint.opacity(0.16))
                        }
                        .overlay(Capsule().strokeBorder(god.tint.opacity(0.6), lineWidth: 1))
                }
            }
        }
    }

    private var combineButton: some View {
        Button {
            onCombine()
            dismiss()
        } label: {
            Text("COMBINE")
                .font(.fantasy(19, weight: .black))
                .kerning(1.4)
                .foregroundStyle(Theme.parchment)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background {
                    DeckButtonSurface(tone: .primary, state: .highlighted,
                                      rim: Theme.gold, cornerRadius: 14, emphasis: 1)
                }
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.top, 2)
    }

    // MARK: - Small parts

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .black))
            .kerning(1.1)
            .foregroundStyle(Theme.gold.opacity(0.7))
    }

    private func readout(_ name: String, _ value: String, _ tint: Color) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Theme.parchment)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 13.5, weight: .black).monospacedDigit())
                .foregroundStyle(tint)
        }
    }
}
