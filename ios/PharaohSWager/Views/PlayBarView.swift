import SwiftUI

/// Compact controls for the always-visible battle hand. The old planning bar
/// is deliberately gone: dice themselves are the selection UI.
struct PlayBarView: View {
    let engine: BattleEngine
    var bodyHeight: CGFloat = 108

    private var compact: Bool { bodyHeight < 100 }
    private var controlHeight: CGFloat { compact ? 58 : 68 }
    private var rerollWidth: CGFloat { compact ? 64 : 76 }
    private var primaryWidth: CGFloat { compact ? 106 : 126 }

    private var hasSelection: Bool { !engine.playedFaces.isEmpty }
    private var primaryEnabled: Bool {
        hasSelection ? engine.canCommit : engine.canEndTurn
    }

    var body: some View {
        HStack(spacing: 8) {
            rerollButton
            primaryButton
        }
        .frame(maxHeight: bodyHeight)
    }

    private var rerollButton: some View {
        Button {
            engine.selectingReroll.toggle()
            Haptics.light()
            Audio.shared.play(.uiTap)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: engine.selectingReroll ? "xmark" : "arrow.triangle.2.circlepath")
                    .font(.system(size: compact ? 14 : 17, weight: .black))
                Text(engine.selectingReroll ? "CANCEL" : "REROLL")
                    .font(.system(size: 10, weight: .black))
                    .kerning(0.8)
                if !engine.selectingReroll {
                    Text(engine.rerollChargeText)
                        .font(.system(size: 10, weight: .black).monospacedDigit())
                }
            }
            .foregroundStyle(engine.selectingReroll ? Theme.frost : Theme.gold)
            .frame(width: rerollWidth, height: controlHeight)
            .background {
                DeckButtonSurface(
                    tone: .secondary,
                    state: engine.selectingReroll ? .selected : (engine.canReroll ? .normal : .disabled),
                    rim: engine.selectingReroll ? Theme.frost : Theme.gold,
                    cornerRadius: 14
                )
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!engine.canReroll && !engine.selectingReroll)
        .accessibilityIdentifier("battle.reroll")
        .anchorPreference(key: RerollChargeAnchorKey.self, value: .bounds) { ["reroll": $0] }
    }

    private var primaryButton: some View {
        Button {
            if hasSelection {
                engine.beginCommit()
            } else {
                engine.endPlayerTurn()
            }
            Haptics.medium()
            Audio.shared.play(.uiConfirm)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: hasSelection ? "play.fill" : "hourglass.bottomhalf.filled")
                    .font(.system(size: 17, weight: .black))
                Text(hasSelection ? "PLAY" : "END TURN")
                    .font(.fantasy(compact ? 14 : 17, weight: .black))
                    .kerning(1.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(primaryEnabled ? Theme.parchment : Theme.parchmentDim)
            .frame(width: primaryWidth, height: controlHeight)
            .background {
                DeckButtonSurface(
                    tone: hasSelection ? .primary : .secondary,
                    state: primaryEnabled ? (hasSelection ? .highlighted : .normal) : .disabled,
                    rim: hasSelection ? Theme.gold : Theme.frost,
                    cornerRadius: 16,
                    emphasis: hasSelection && primaryEnabled ? 1 : 0
                )
            }
            .goldCorners(size: 15, inset: 3, opacity: primaryEnabled ? 0.8 : 0.28)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!primaryEnabled)
        .accessibilityIdentifier(hasSelection ? "battle.commit" : "battle.endTurn")
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: hasSelection)
    }
}

/// The one action budget read kept outside the dice row. It is deliberately
/// numeric rather than explanatory so the battle view stays visually quiet.
struct ResolveMedallionView: View {
    let engine: BattleEngine

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
                    .font(.fantasy(22, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.parchment)
                    .contentTransition(.numericText())
                Text("RESOLVE")
                    .font(.system(size: 7.5, weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(Theme.gold)
            }
        }
        .frame(width: 72, height: 72)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Resolve \(engine.resolveRemaining) of \(BattleRules.resolvePerTurn)")
    }
}
