import SwiftUI

/// Dark lapis and carved gold: readable at any card width, without stretching a painted button.
struct TurnOrderPlaque: View {
    var accent: Color = Theme.gold
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9).fill(Theme.bg)
            LinearGradient(colors: [Color(red: 0.055, green: 0.085, blue: 0.14), Theme.bg, Theme.bgCard.opacity(0.55)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(.rect(cornerRadius: 9))
            RoundedRectangle(cornerRadius: 9).strokeBorder(Theme.goldDeep.opacity(0.6), lineWidth: 1)
            VStack {
                Rectangle().fill(LinearGradient(colors: [.clear, accent.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 2)
                Spacer()
                Rectangle().fill(Theme.goldDeep.opacity(0.25)).frame(height: 1)
            }.padding(.horizontal, 15).padding(.vertical, 4)
        }
        .goldCorners(size: 12, inset: 3, opacity: 0.8)
        .shadow(color: .black.opacity(0.5), radius: 4, y: 3)
    }
}

/// Shared by the battle result and the end-of-run screen: bright lettering always sits on opaque dark stone.
struct VerdictBanner: View {
    let title: String
    let won: Bool
    var body: some View {
        Text(title)
            .font(.fantasy(28, weight: .black))
            .foregroundStyle(Theme.parchment)
            .kerning(3)
            .lineLimit(1).minimumScaleFactor(0.65)
            .padding(.horizontal, 30).padding(.vertical, 12)
            .background { TurnOrderPlaque(accent: won ? Theme.gold : Theme.blood) }
    }
}

/// The phase is independent of the round counter and remains visible while
/// actions animate. Color is reinforced by a label and a distinct symbol.
struct BattlePhaseLabel: View {
    let engine: BattleEngine

    private var enemyTurn: Bool {
        engine.phase == .enemyActing || engine.activeTimelineEntry?.isPlayer == false
    }

    private var title: String {
        switch engine.phase {
        case .player: return "YOUR TURN"
        case .aiming: return "CHOOSE TARGET"
        case .resolving: return engine.activeTimelineEntry == nil && engine.committedPlan.isEmpty ? "ROUND END" : "YOUR ACTION"
        case .enemyActing: return "ENEMY TURN"
        case .won: return "VICTORY"
        case .lost: return "DEFEAT"
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: enemyTurn ? "exclamationmark.shield.fill" : "person.fill")
            Text(title)
                .fontWeight(.black)
            if engine.phase == .player {
                Text("· \(engine.resolveRemaining) RESOLVE")
            }
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(enemyTurn ? Theme.ember : Theme.frost)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.bg.opacity(0.95), in: .capsule)
        .overlay(Capsule().strokeBorder((enemyTurn ? Theme.ember : Theme.frost).opacity(0.5)))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("battle.phase")
    }
}

/// A preview of the chosen action above one shared enemy queue. Combo size
/// changes the Resolve cost, never secretly inserts an enemy exchange.
struct BattleDecisionPanel: View {
    let engine: BattleEngine
    @State private var inspectedAction: PlanStep?
    @State private var inspectedEnemy: TimelineEntry?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var action: PlanStep? {
        if engine.phase == .player { return engine.selectedAction }
        if engine.phase == .aiming || engine.activeTimelineEntry?.isPlayer == true {
            return engine.displayedPlan.first
        }
        return nil
    }

    private var emptyTitle: String {
        if engine.phase == .enemyActing { return engine.activeTimelineEntry?.title ?? "ENEMIES ACTING" }
        if engine.phase == .resolving { return "RESOLVING ROUND" }
        return engine.selectingReroll ? "REROLL: TAP AN UNUSED DIE" : "CHOOSE YOUR NEXT ACTION"
    }

    private var emptyDetail: String {
        if engine.phase != .player { return engine.lastAction }
        return "Tap matching dice to build a combo; tap selected dice to remove them."
    }

    private var handover: String {
        guard engine.phase == .player else {
            return engine.phase == .enemyActing ? "ENEMIES ACTING" : "RESOLVING"
        }
        guard let action else { return "Enemies wait for End Turn" }
        let cost = engine.resolveCost(for: action)
        if cost > engine.resolveRemaining { return "Not enough Resolve — select fewer dice" }
        if engine.selectionEndsTurn { return "Acts first → enemies act next" }
        return "Acts first → you keep \(engine.resolveRemaining - cost) Resolve"
    }

    var body: some View {
        VStack(spacing: 4) {
            preview
            HStack(spacing: 7) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.phase == .enemyActing ? "ENEMY TURN" : "AFTER END TURN")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Theme.ember)
                    Text("\(engine.remainingEnemyActionCount) moves · \(engine.announcedIncomingDamage) dmg*")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.parchmentDim)
                }
                .frame(width: 104, alignment: .leading)

                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(engine.enemyActionOrder, id: \.scheduleKey) { entry in
                            enemyChip(entry)
                        }
                        if engine.enemyActionOrder.isEmpty {
                            Text("No enemy moves this round")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.parchmentDim)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                .accessibilityIdentifier("battle.enemyOrder")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Theme.bg.opacity(0.96), in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.gold.opacity(0.35)))
        .sheet(item: $inspectedAction) { step in
            detailSheet(title: step.title) {
                Text("\(step.diceCount) dice · \(engine.resolveCost(for: step)) Resolve")
                    .foregroundStyle(Theme.gold)
                Text(engine.damageBreakdown(for: step))
                ForEach(Array(engine.planEffectLines(for: step).enumerated()), id: \.offset) { _, line in
                    Text(line)
                }
                if let chisel = engine.chiselLine(for: step) { Text(chisel).foregroundStyle(Theme.ptahCopper) }
                Divider()
                Text("This whole action resolves before enemies. Its Resolve cost determines whether you can play again or hand over the turn.")
                Text("Damage is before target defenses. God powers and target-dependent effects resolve when played.")
                    .foregroundStyle(Theme.parchmentDim)
                if (step.combo?.shield ?? 0) > 0 {
                    Text("Guard absorbs incoming hits. Unused Guard expires at round end unless a power retains it.")
                }
            }
        }
        .sheet(item: $inspectedEnemy) { entry in
            detailSheet(title: entry.title) {
                Text("Enemy action \(entry.beat)").foregroundStyle(Theme.ember)
                Text(entry.detail)
                Text("* Announced damage is before your Guard, Evade and reactive powers. Defeated enemies lose their remaining actions. Delayed opening moves return next round.")
                    .foregroundStyle(Theme.parchmentDim)
            }
        }
    }

    private var preview: some View {
        HStack(spacing: 10) {
            Button {
                inspectedAction = action
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(action.map { "\($0.isCombo ? "COMBO" : "ACTION"): \($0.title)" }
                             ?? emptyTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.parchment)
                        if action != nil { Image(systemName: "info.circle").foregroundStyle(Theme.gold) }
                    }
                    Text(action.map { engine.planDetail(for: $0).replacingOccurrences(of: "Shield", with: "Guard") }
                         ?? emptyDetail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.parchmentDim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(action == nil)
            .accessibilityIdentifier("battle.actionPreview")

            VStack(alignment: .trailing, spacing: 2) {
                if let action {
                    Text("\(action.diceCount) DICE · \(engine.resolveCost(for: action)) RESOLVE")
                        .font(.system(size: 11, weight: .black).monospacedDigit())
                        .foregroundStyle(engine.resolveCost(for: action) > engine.resolveRemaining ? Theme.ember : Theme.gold)
                }
                Text(handover)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(engine.selectionEndsTurn ? Theme.ember : Theme.frost)
            }
            .accessibilityIdentifier("battle.handoverPreview")
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private func enemyChip(_ entry: TimelineEntry) -> some View {
        let completed = engine.completedEnemyActions.contains(entry.scheduleKey)
        let active = engine.activeTimelineEntry?.scheduleKey == entry.scheduleKey
        return Button {
            inspectedEnemy = entry
        } label: {
            HStack(spacing: 6) {
                Image(systemName: completed ? "checkmark.circle.fill" : (active ? "play.circle.fill" : "circle"))
                    .foregroundStyle(active ? Theme.ember : Theme.parchmentDim)
                Text("\(entry.beat)").font(.system(size: 13, weight: .black).monospacedDigit())
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.title).font(.system(size: 10, weight: .bold))
                    Text(entry.detail).font(.system(size: 11, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.gold)
                }
                .lineLimit(1)
            }
            .foregroundStyle(Theme.parchment)
            .padding(.horizontal, 8)
            .frame(minHeight: 30)
            .background((active ? Theme.ember : Theme.parchment).opacity(active ? 0.15 : 0.05), in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(active ? Theme.ember : Theme.gold.opacity(0.2), lineWidth: active ? 2 : 1))
            .opacity(completed ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(completed ? "Completed. " : active ? "Acting now. " : "")Enemy action \(entry.beat). \(entry.title). \(entry.detail)")
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: active)
    }

    private func detailSheet<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14, content: content)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.parchment)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
            .background(Theme.bg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { inspectedAction = nil; inspectedEnemy = nil }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
