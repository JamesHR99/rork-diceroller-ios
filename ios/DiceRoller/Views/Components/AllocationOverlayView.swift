import SwiftUI

/// The targeting step between planning and the blows. With several foes on the
/// deck, committing lists every attack in the plan — combos as single cards,
/// solo faces as rows — and each is sent at a foe with a tap. The fighters
/// stay tappable above the panel; solo fights never see this overlay.
struct AllocationOverlayView: View {
    let engine: BattleEngine

    private var steps: [PlanStep] { engine.allocatableSteps }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            panel
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
        }
    }

    private var panel: some View {
        VStack(spacing: 9) {
            header
            ScrollView {
                VStack(spacing: 5) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        row(step, order: index + 1)
                    }
                }
                .padding(.vertical, 1)
            }
            .frame(maxHeight: 214)
            footer
        }
        .padding(12)
        .frame(maxWidth: 560)
        .papyrusPanel(tint: Theme.bgElevated, cornerRadius: 18, strength: 0.55, shade: 0.45)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1.2)
        )
        .shadow(color: Theme.gold.opacity(0.22), radius: 22)
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text("NAME YOUR BLOWS")
                .font(.system(size: 11, weight: .black))
                .kerning(2.5)
                .foregroundStyle(Theme.gold)
            Text("Tap a blow, then tap a foe on the deck — or cycle its target")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(Theme.parchmentDim)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ step: PlanStep, order: Int) -> some View {
        let isSelected = engine.selectedAllocationID == step.id && engine.selectedAllocationHit == 0
        return Button {
            engine.selectAllocation(step.id)
        } label: {
            HStack(spacing: 8) {
                orderBadge(order, tint: isSelected ? Theme.gold : step.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title.uppercased())
                        .font(.fantasy(12, weight: .bold))
                        .foregroundStyle(isSelected ? Theme.parchment : step.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !step.effects.isEmpty {
                        Text(step.effects.joined(separator: " · "))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.parchmentDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: 6)

                if step.damage > 0 {
                    Text("\(engine.mainDamage(for: step))")
                        .font(.system(size: 15, weight: .black).monospacedDigit())
                        .foregroundStyle(Theme.blood)
                }

                targetChip(step)

                // Twin Bowstring's second arrow and Crescent Edge's splash:
                // their own chip, defaulted to the weakest living foe.
                if engine.hasSecondaryHit(step) {
                    secondaryChip(step)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Theme.gold.opacity(0.1) : Theme.bg.opacity(0.65),
                        in: .rect(cornerRadius: 11))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(isSelected ? Theme.gold : Theme.gold.opacity(0.18),
                                  lineWidth: isSelected ? 1.8 : 1)
            )
            .shadow(color: isSelected ? Theme.gold.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// The foe this blow is currently pointed at — tap to cycle through the
    /// living pack.
    private func targetChip(_ step: PlanStep) -> some View {
        let foeID = engine.allocatedFoeID(for: step)
        let foe = engine.enemies.first { $0.id == foeID }
        let isSelected = engine.selectedAllocationID == step.id && engine.selectedAllocationHit == 0
        return Button {
            engine.cycleTarget(for: step.id)
        } label: {
            HStack(spacing: 3) {
                DuatSymbol(art: DuatArt.Status.marked, fallback: "target",
                           size: 12, tint: isSelected ? Theme.bg : Theme.parchment)
                Text(foe?.displayName ?? "—")
                    .font(.system(size: 9.5, weight: .black))
                    .kerning(0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                DuatImage(name: DuatArt.utilityForward, width: 9, fit: .fit)
                    .colorMultiply(isSelected ? Theme.bg : Theme.parchment)
            }
            .foregroundStyle(isSelected ? Theme.bg : Theme.parchment)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(width: 104)
            .background(isSelected ? Theme.gold : Theme.bg, in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.gold.opacity(isSelected ? 1 : 0.4), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// The chisel-granted second hit's own target chip, in Ptah's copper.
    private func secondaryChip(_ step: PlanStep) -> some View {
        let foeID = engine.secondaryFoeID(for: step)
        let foe = engine.enemies.first { $0.id == foeID }
        let isSelected = engine.selectedAllocationID == step.id && engine.selectedAllocationHit == 1
        return Button {
            engine.selectSecondaryHit(step.id)
        } label: {
            HStack(spacing: 2) {
                DuatImage(name: DuatArt.chainConnector, width: 11, fit: .fit)
                    .colorMultiply(isSelected ? Theme.bg : Theme.ptahCopper)
                Text(foe?.displayName ?? "—")
                    .font(.system(size: 8.5, weight: .black))
                    .kerning(0.3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(isSelected ? Theme.bg : Theme.ptahCopper)
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(width: 84)
            .background(isSelected ? Theme.ptahCopper : Theme.bg, in: .capsule)
            .overlay(Capsule().strokeBorder(
                Theme.ptahCopper.opacity(isSelected ? 1 : 0.5), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func orderBadge(_ number: Int, tint: Color) -> some View {
        Text("\(number)")
            .font(.system(size: 10, weight: .black).monospacedDigit())
            .foregroundStyle(Theme.bg)
            .frame(width: 17, height: 17)
            .background(tint, in: .circle)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                engine.cancelAllocation()
            } label: {
                HStack(spacing: 5) {
                    DuatImage(name: DuatArt.utilityBack, width: 13, fit: .fit)
                        .colorMultiply(Theme.parchmentDim)
                    Text("BACK")
                        .font(.fantasy(12, weight: .black))
                        .kerning(1.2)
                        .foregroundStyle(Theme.parchmentDim)
                }
                .frame(width: 118, height: 46)
                .background {
                    DuatImage(name: DuatArt.button(.secondary, .normal), fit: .stretch)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .clipShape(.rect(cornerRadius: 13))
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                engine.confirmAllocation()
            } label: {
                HStack(spacing: 6) {
                    DuatIcon(name: DuatArt.Status.burn, size: 18)
                    Text("STRIKE")
                        .font(.fantasy(14, weight: .black))
                        .kerning(1.5)
                        .foregroundStyle(Theme.parchment)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background {
                    DuatImage(name: DuatArt.button(.primary, .highlighted), fit: .stretch)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .clipShape(.rect(cornerRadius: 13))
                .shadow(color: Theme.ember.opacity(0.45), radius: 10, y: 2)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }
}
