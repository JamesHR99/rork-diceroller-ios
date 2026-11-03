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
    @State private var timelineFrames: [String: CGRect] = [:]
    @State private var draggingAction: UUID?
    @State private var dragLocation: CGPoint?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RESOLVE \(engine.plannedResolveCost) / \(engine.resolveRemaining)")
                        .font(.system(size: 15, weight: .black).monospacedDigit())
                        .foregroundStyle(engine.plannedResolveCost > engine.resolveRemaining ? Theme.ember : Theme.gold)
                    Text("\(max(0, engine.resolveRemaining - engine.plannedResolveCost)) left · drag actions · \(engine.announcedIncomingDamage) incoming*")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                        .lineLimit(1).minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if showsControls { PlayBarView(engine: engine, bodyHeight: 44) }
            }
            .frame(height: showsControls ? 44 : 30)
            // Every action remains present. Short screens add columns rather
            // than hiding a scrolling tail.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: max(1, columns)), spacing: 4) {
                ForEach(engine.timeline, id: \.scheduleKey) { entry in
                    timelineChip(entry)
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: TimelineFramesKey.self,
                                value: [entry.scheduleKey: proxy.frame(in: .named("battleTimeline"))])
                        })
                        .overlay {
                            if draggingAction != nil, let point = dragLocation,
                               timelineFrames[entry.scheduleKey]?.contains(point) == true {
                                RoundedRectangle(cornerRadius: 8).stroke(Theme.frost, lineWidth: 2)
                            }
                        }
                }
                if engine.timeline.isEmpty {
                    Text("No actions queued")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                        .frame(height: 28)
                }
            }
            .coordinateSpace(name: "battleTimeline")
            .onPreferenceChange(TimelineFramesKey.self) { timelineFrames = $0 }
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
                Text("This action lands on its numbered beat when you press Go. Drag it on the timeline to place it around enemy moves.")
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

    private func finishDrag(_ id: UUID, at point: CGPoint) {
        defer { draggingAction = nil; dragLocation = nil }
        let entries = engine.timeline
        guard let from = entries.firstIndex(where: { $0.isPlayer && $0.sourceID == id }),
              let target = entries.firstIndex(where: { timelineFrames[$0.scheduleKey]?.contains(point) == true }),
              let frame = timelineFrames[entries[target].scheduleKey] else { return }
        let insertion = target + (point.x >= frame.midX ? 1 : 0)
        engine.moveTimelineAction(id, to: max(0, insertion - (from < insertion ? 1 : 0)))
    }

    @ViewBuilder
    private func timelineChip(_ entry: TimelineEntry) -> some View {
        if entry.isPlayer { playerChip(entry) } else { enemyChip(entry) }
    }

    private func playerChip(_ entry: TimelineEntry) -> some View {
        let selected = engine.timingAction?.id == entry.sourceID
        return Button {
            engine.selectTimingAction(entry.sourceID)
            if selected { inspectedAction = engine.turnPlan.first { $0.id == entry.sourceID } }
        } label: {
            HStack(spacing: 5) {
                Text("\(entry.beat)")
                    .font(.system(size: 12, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.bg)
                    .frame(width: 20, height: 20)
                    .background(Theme.frost, in: .circle)
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.title).font(.system(size: 11, weight: .bold))
                        .minimumScaleFactor(0.5)
                    Text(entry.detail
                        .replacingOccurrences(of: "damage before defenses", with: "dmg")
                        .replacingOccurrences(of: "Shield", with: "Guard"))
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.gold)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                if let step = engine.turnPlan.first(where: { $0.id == entry.sourceID }) {
                    Text("\(engine.resolveCost(for: step)) R")
                        .font(.system(size: 10, weight: .black).monospacedDigit())
                        .foregroundStyle(Theme.gold)
                }
            }
            .foregroundStyle(Theme.parchment)
            .padding(.horizontal, 5)
            .frame(height: 37)
            .background(Theme.frost.opacity(selected ? 0.18 : 0.08), in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.frost.opacity(selected ? 0.9 : 0.3), lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .opacity(draggingAction == entry.sourceID ? 0.55 : 1)
        .simultaneousGesture(DragGesture(minimumDistance: 8, coordinateSpace: .named("battleTimeline"))
            .onChanged { value in
                guard engine.phase == .player else { return }
                draggingAction = entry.sourceID
                dragLocation = value.location
            }
            .onEnded { value in finishDrag(entry.sourceID, at: value.location) })
        .accessibilityLabel("Your action, beat \(entry.beat). \(entry.title). \(entry.detail). \(engine.turnPlan.first(where: { $0.id == entry.sourceID }).map { "\(engine.resolveCost(for: $0)) Resolve." } ?? "")")
        .accessibilityHint("Drag to reorder. Tap to select; tap again for details.")
        .accessibilityAction(named: "Move earlier") {
            if let index = engine.timeline.firstIndex(where: { $0.scheduleKey == entry.scheduleKey }) {
                engine.moveTimelineAction(entry.sourceID, to: max(0, index - 1))
            }
        }
        .accessibilityAction(named: "Move later") {
            if let index = engine.timeline.firstIndex(where: { $0.scheduleKey == entry.scheduleKey }) {
                engine.moveTimelineAction(entry.sourceID, to: min(engine.timeline.count - 1, index + 1))
            }
        }
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
                    Text(entry.title.components(separatedBy: " · ").last ?? entry.title)
                        .font(.system(size: 11, weight: .bold))
                        .minimumScaleFactor(0.7)
                    Text("\(entry.detail.replacingOccurrences(of: " damage", with: " dmg")) · \(entry.title.components(separatedBy: " · ").first ?? "")")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.gold)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            }
            .foregroundStyle(Theme.parchment)
            .padding(.horizontal, 5)
            .frame(height: 37)
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

private struct TimelineFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
