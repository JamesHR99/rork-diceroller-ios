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

/// One truthful, editable schedule: blue player actions and announced enemy
/// moves share the same numbered clock before the player presses Go.
struct BattleDecisionPanel: View {
    let engine: BattleEngine
    var columns = 3
    var showsControls = false
    @State private var inspectedAction: PlanStep?
    @State private var inspectedEnemy: TimelineEntry?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                timingEditor
                if showsControls { PlayBarView(engine: engine, bodyHeight: 44) }
            }
            .frame(height: showsControls ? 44 : 30)
            HStack(spacing: 6) {
                Text(engine.displayedPlan.isEmpty ? "ENEMY TIMELINE" : "YOUR ACTIONS + ENEMY TIMELINE")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(engine.displayedPlan.isEmpty ? Theme.ember : Theme.frost)
                Spacer(minLength: 0)
                Text("\(engine.remainingEnemyActionCount) moves · \(engine.announcedIncomingDamage) dmg*")
                    .font(.system(size: 9, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.parchmentDim)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(height: 12)

            // Every action remains present. Short screens add columns rather
            // than hiding a scrolling tail.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: max(1, columns)), spacing: 4) {
                ForEach(engine.timeline, id: \.scheduleKey) { entry in
                    timelineChip(entry)
                }
                if engine.timeline.isEmpty {
                    Text("No actions queued")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                        .frame(height: 28)
                }
            }
            .accessibilityIdentifier("battle.timeline")
        }
        .padding(.horizontal, 8)
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
                Text("This action lands on its numbered beat when you press Go. Use Earlier and Later to place it around enemy moves.")
                Text("Damage is before target defenses. God powers and target-dependent effects resolve when played.")
                    .foregroundStyle(Theme.parchmentDim)
                if (step.combo?.shield ?? 0) > 0 {
                    Text("Guard absorbs incoming hits. Unused Guard expires at round end unless a power retains it.")
                }
            }
        }
        .sheet(item: $inspectedEnemy) { entry in
            detailSheet(title: entry.title) {
                Text("Timeline beat \(entry.beat)").foregroundStyle(Theme.ember)
                Text(entry.detail)
                Text("* Announced damage is before your Guard, Evade and reactive powers. Defeated enemies lose their remaining actions. Delayed opening moves return next round.")
                    .foregroundStyle(Theme.parchmentDim)
            }
        }
    }

    /// The latest action is selected automatically. Tapping any blue timeline
    /// chip selects it; these two controls then move it across enemy gaps.
    private var timingEditor: some View {
        HStack(spacing: 4) {
            if let step = engine.timingAction {
                Button { inspectedAction = step } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.system(size: 10, weight: .black))
                        Text("BEAT \(engine.timeline.first(where: { $0.isPlayer && $0.sourceID == step.id })?.beat ?? 0) · \(engine.planDetail(for: step))")
                            .font(.system(size: 9, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Theme.gold)
                    }
                    .foregroundStyle(Theme.parchment)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .frame(height: showsControls ? 40 : 30)
                    .background(Theme.frost.opacity(0.08), in: .rect(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                timingButton(offset: -1, symbol: "chevron.left", label: "Earlier")
                timingButton(offset: 1, symbol: "chevron.right", label: "Later")
            } else {
                Text("BUILD YOUR TIMELINE")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Theme.frost)
                Spacer(minLength: 0)
                Text("\(engine.resolveRemaining) RESOLVE")
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundStyle(Theme.gold)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func timingButton(offset: Int, symbol: String, label: String) -> some View {
        Button { engine.moveTimingAction(by: offset) } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(engine.canMoveTimingAction(by: offset) ? Theme.frost : Theme.parchmentDim)
                .frame(width: 34, height: showsControls ? 40 : 30)
                .background(Theme.frost.opacity(0.08), in: .rect(cornerRadius: 7))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!engine.canMoveTimingAction(by: offset))
        .accessibilityLabel("Move \(engine.timingAction?.title ?? "action") \(label.lowercased())")
    }

    @ViewBuilder
    private func timelineChip(_ entry: TimelineEntry) -> some View {
        if entry.isPlayer { playerChip(entry) } else { enemyChip(entry) }
    }

    private func playerChip(_ entry: TimelineEntry) -> some View {
        let selected = engine.timingAction?.id == entry.sourceID
        return Button {
            engine.selectTimingAction(entry.sourceID)
        } label: {
            HStack(spacing: 5) {
                Text("\(entry.beat)")
                    .font(.system(size: 12, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.bg)
                    .frame(width: 20, height: 20)
                    .background(Theme.frost, in: .circle)
                VStack(alignment: .leading, spacing: 1) {
                    Text("YOU · \(entry.title)").font(.system(size: 9, weight: .bold))
                    Text(entry.detail
                        .replacingOccurrences(of: "damage before defenses", with: "dmg")
                        .replacingOccurrences(of: "Shield", with: "Guard"))
                        .font(.system(size: 9, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.gold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            }
            .foregroundStyle(Theme.parchment)
            .padding(.horizontal, 5)
            .frame(height: 28)
            .background(Theme.frost.opacity(selected ? 0.18 : 0.08), in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.frost.opacity(selected ? 0.9 : 0.3), lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Your action, beat \(entry.beat). \(entry.title). \(entry.detail). Select to move earlier or later")
        .accessibilityIdentifier("battle.playerAction.\(entry.beat)")
    }

    private func enemyChip(_ entry: TimelineEntry) -> some View {
        let completed = engine.completedEnemyActions.contains(entry.scheduleKey)
        let active = engine.activeTimelineEntry?.scheduleKey == entry.scheduleKey
        return Button {
            inspectedEnemy = entry
        } label: {
            HStack(spacing: 5) {
                Text(completed ? "✓" : "\(entry.beat)")
                    .font(.system(size: 12, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.bg)
                    .frame(width: 20, height: 20)
                    .background(active ? Theme.ember : Theme.gold, in: .circle)
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.title).font(.system(size: 9, weight: .bold))
                    Text(entry.detail).font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.gold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            }
            .foregroundStyle(Theme.parchment)
            .padding(.horizontal, 5)
            .frame(height: 28)
            .background((active ? Theme.ember : Theme.parchment).opacity(active ? 0.15 : 0.05), in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(active ? Theme.ember : Theme.gold.opacity(0.2), lineWidth: active ? 2 : 1))
            .opacity(completed ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(completed ? "Completed. " : active ? "Acting now. " : "")Enemy action \(entry.beat). \(entry.title). \(entry.detail)")
        .accessibilityIdentifier("battle.enemyAction.\(entry.beat)")
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
