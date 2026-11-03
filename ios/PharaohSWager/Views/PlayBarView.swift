import SwiftUI

/// Secondary controls beneath the featured hand, with 44-point touch targets.
struct PlayBarView: View {
    let engine: BattleEngine
    var bodyHeight: CGFloat = 108
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var compact: Bool { bodyHeight < 100 }
    private var controlHeight: CGFloat { compact ? 44 : 54 }
    private var rerollWidth: CGFloat { compact ? 92 : 108 }
    private var primaryWidth: CGFloat { compact ? 72 : 96 }

    private var hasSelection: Bool { !engine.playedFaces.isEmpty }
    private var primaryEnabled: Bool { engine.canEndTurn }

    var body: some View {
        HStack(spacing: compact ? 3 : 8) {
            rerollButton
            primaryButton
        }
        .frame(maxHeight: bodyHeight)
    }

    private var rerollButton: some View {
        Button {
            engine.rerollUnused(reduceMotion: reduceMotion)
            Haptics.medium()
            Audio.shared.play(.uiTap)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: compact ? 14 : 17, weight: .black))
                VStack(spacing: 1) {
                    Text("ROLL REST")
                        .font(.system(size: 9, weight: .black))
                    Text(engine.rerollChargeText + " left")
                        .font(.system(size: 8, weight: .bold).monospacedDigit())
                }
            }
            .foregroundStyle(Theme.gold)
            .frame(width: rerollWidth, height: controlHeight)
            .background {
                DeckButtonSurface(
                    tone: .secondary,
                    state: engine.canRerollUnused ? .normal : .disabled,
                    rim: Theme.gold,
                    cornerRadius: 14
                )
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!engine.canRerollUnused)
        .accessibilityIdentifier("battle.reroll")
        .accessibilityLabel("Roll all unused dice. \(engine.rerollChargeText) pulls left")
        .anchorPreference(key: RerollChargeAnchorKey.self, value: .bounds) { ["reroll": $0] }
    }

    private var primaryButton: some View {
        Button {
            engine.endPlayerTurn()
            Haptics.medium()
            Audio.shared.play(.uiConfirm)
        } label: {
            VStack(spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                    Text("GO")
                        .font(.fantasy(compact ? 12 : 14, weight: .black))
                }
                Text(hasSelection ? "\(engine.plannedResolveCost)/\(engine.resolveRemaining) RESOLVE" : "PASS")
                    .font(.system(size: compact ? 9 : 10, weight: .bold))
                    .foregroundStyle(engine.plannedResolveCost > engine.resolveRemaining ? Theme.ember : Theme.parchmentDim)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(primaryEnabled ? Theme.parchment : Theme.parchmentDim)
            .frame(width: primaryWidth, height: controlHeight)
            .background {
                DeckButtonSurface(
                    tone: hasSelection ? .primary : .secondary,
                    state: primaryEnabled ? (hasSelection ? .highlighted : .normal) : .disabled,
                    rim: hasSelection ? Theme.gold : Theme.frost,
                    cornerRadius: 14,
                    emphasis: hasSelection && primaryEnabled ? 1 : 0
                )
            }
            .goldCorners(size: 15, inset: 3, opacity: primaryEnabled ? 0.8 : 0.28)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!primaryEnabled)
        .accessibilityIdentifier("battle.endTurn")
        .accessibilityHint(engine.plannedResolveCost > engine.resolveRemaining ? "Over Resolve budget. Remove dice to end your turn." :
            hasSelection ? "Resolve the visible player and enemy timeline" : "Pass to the announced enemy actions")
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: hasSelection)
    }
}

/// The one action budget read kept outside the dice row. It is deliberately
/// numeric rather than explanatory so the battle view stays visually quiet.
struct ResolveMedallionView: View {
    let engine: BattleEngine
    var diameter: CGFloat = 72

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.gold.opacity(0.34), Theme.bgElevated, Theme.bg],
                        center: .center,
                        startRadius: 2,
                        endRadius: 42
                    )
                )
                .overlay(
                    Circle()
                        .strokeBorder(Theme.gold.opacity(0.75), lineWidth: 2)
                )
                .shadow(color: Theme.gold.opacity(0.22), radius: 10)

            VStack(spacing: 0) {
                Text("\(engine.resolveRemaining)/\(BattleRules.resolvePerTurn)")
                    .font(.fantasy(max(15, diameter * 0.3), weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.parchment)
                    .contentTransition(.numericText())
                Text("RESOLVE")
                    .font(.system(size: max(6, diameter * 0.104), weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(Theme.gold)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Resolve \(engine.resolveRemaining) of \(BattleRules.resolvePerTurn)")
    }
}
