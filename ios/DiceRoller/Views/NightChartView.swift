import SwiftUI

/// The Night Chart — a branching map of the gate you are currently sailing.
/// Each hour runs four fifteen-minute stages; channels open ahead of the
/// barque and close behind it, so no run ever sees every node.
struct NightChartView: View {
    @Environment(GameManager.self) private var game
    @State private var pulse = false
    @State private var showInfo = false

    private let columnWidth: CGFloat = 52
    private let mapHeight: CGFloat = 244
    private let topInset: CGFloat = 30
    private let edgePadding: CGFloat = 20

    private var gate: Gate { game.gate }

    private var stagesPerGate: Int { Voyage.stagesPerHour * 4 }

    private var gateStageRange: Range<Int> {
        let start = (gate.firstHour - 1) * Voyage.stagesPerHour
        return start..<(start + stagesPerGate)
    }

    private var gateNodes: [VoyageNode] {
        game.voyage.nodes.filter { gateStageRange.contains($0.stage) }
    }

    private var contentWidth: CGFloat {
        edgePadding * 2 + columnWidth * CGFloat(stagesPerGate)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            map
            footer
        }
        .animation(.easeInOut(duration: 0.7), value: gate)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
        }
        .sheet(isPresented: $showInfo) {
            if let loadout = game.loadout {
                InfoSheetView(loadout: loadout, classID: game.classID, critBonus: game.critBonus,
                              maxStamina: game.effectiveMaxStamina, drawnDieIDs: [],
                              hasMetTrial: game.trialUsed)
            }
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    DuatSymbol(art: gate.artName, fallback: gate.symbol, size: 20, tint: gate.accent)
                        .shadow(color: gate.accent.opacity(0.7), radius: 6)
                    CarvedTitle(text: gate.name, size: 18, kerning: 3, showsRule: false)
                        .fixedSize()
                    Text("HOURS \(gate.firstHour)–\(gate.lastHour)")
                        .font(.system(size: 8, weight: .black))
                        .kerning(1.2)
                        .foregroundStyle(Theme.bg)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(gate.accent.opacity(0.85), in: .capsule)
                }
                Text(instruction)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(gate.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 5) {
                RunStatusBar(game: game)
                NightDialView(currentHour: game.currentHour, hoursCleared: game.hoursCleared)
            }

            Button {
                showInfo = true
            } label: {
                VStack(spacing: 2) {
                    DuatIcon(name: DuatArt.utilityCodex, size: 17)
                    Text("CODEX")
                        .font(.system(size: 7.5, weight: .black))
                        .kerning(0.8)
                        .foregroundStyle(Theme.gold)
                }
                .frame(width: 46, height: 42)
                .background(Theme.bgElevated.opacity(0.9), in: .rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private var instruction: String {
        let open = game.availableNodes.count
        if game.lastClearedNode == nil {
            return "\(gate.region) · The river mouth — one channel open."
        }
        if open == 1 {
            return "\(gate.region) · The channels narrow — one way forward."
        }
        return "\(gate.region) · \(open) channels open — the rest close behind you."
    }

    private var footer: some View {
        HStack(spacing: 12) {
            ForEach([StageKind.battle, .shrine, .ferryman, .mooring, .omen, .herald], id: \.self) { kind in
                HStack(spacing: 4) {
                    DuatSymbol(art: kind.artName, fallback: kind.symbol, size: 14, tint: kind.tint)
                    Text(kind.label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.parchmentDim)
                }
            }
            Spacer()
            if let message = game.statusMessage {
                Text(message)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.gold)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
    }

    // MARK: - The map

    private var map: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack {
                    columnAnchors
                    channelLayer
                    hourGuides
                    ForEach(gateNodes) { node in
                        nodeView(node)
                            .position(position(of: node))
                    }
                }
                .frame(width: contentWidth, height: mapHeight)
                .id(gate)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .frame(height: mapHeight + 14)
            .onAppear { scrollToCurrent(proxy) }
            .onChange(of: gate) { _, _ in scrollToCurrent(proxy) }
        }
    }

    private func scrollToCurrent(_ proxy: ScrollViewProxy) {
        let target: Int
        if let last = game.lastClearedNode {
            target = min(last.stage + 1, gateStageRange.upperBound - 1)
        } else {
            target = gateStageRange.lowerBound
        }
        withAnimation(.easeInOut(duration: 0.9)) {
            proxy.scrollTo("stage-\(target)", anchor: .center)
        }
    }

    /// Invisible anchors so the map can scroll itself to the barque.
    private var columnAnchors: some View {
        ForEach(gateStageRange, id: \.self) { stage in
            Color.clear
                .frame(width: 1, height: mapHeight)
                .id("stage-\(stage)")
                .position(x: x(ofStage: stage), y: mapHeight / 2)
        }
    }

    // MARK: - Geometry

    private func x(ofStage stage: Int) -> CGFloat {
        edgePadding + CGFloat(stage - gateStageRange.lowerBound) * columnWidth + columnWidth / 2
    }

    private func position(of node: VoyageNode) -> CGPoint {
        let columnNodes = game.voyage.nodes(inStage: node.stage)
        let index = columnNodes.firstIndex { $0.id == node.id } ?? 0
        let fraction: Double
        switch columnNodes.count {
        case 1: fraction = 0.5
        case 2: fraction = index == 0 ? 0.16 : 0.84
        default: fraction = [0.04, 0.5, 0.96][min(index, 2)]
        }
        let usable = mapHeight - topInset - 30
        return CGPoint(x: x(ofStage: node.stage), y: topInset + CGFloat(fraction) * usable)
    }

    // MARK: - Channels

    private var channelLayer: some View {
        Canvas { context, _ in
            for node in gateNodes {
                for targetID in node.connections {
                    guard let target = game.voyage.node(targetID),
                          gateStageRange.contains(target.stage) else { continue }

                    var path = Path()
                    path.move(to: position(of: node))
                    path.addLine(to: position(of: target))

                    let traveled = game.clearedNodeIDs.contains(node.id)
                        && game.clearedNodeIDs.contains(target.id)
                    let open = game.lastClearedNodeID == node.id
                        && game.availableNodes.contains { $0.id == target.id }

                    if open {
                        context.stroke(
                            path,
                            with: .color(Theme.gold.opacity(0.22)),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        context.stroke(
                            path,
                            with: .color(Theme.gold),
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                        )
                    } else if traveled {
                        context.stroke(
                            path,
                            with: .color(Theme.gold.opacity(0.45)),
                            style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
                        )
                    } else {
                        context.stroke(
                            path,
                            with: .color(Theme.parchmentDim.opacity(0.16)),
                            style: StrokeStyle(lineWidth: 1, lineCap: .round)
                        )
                    }
                }
            }
        }
    }

    /// Hour boundaries and roman numerals along the bottom.
    private var hourGuides: some View {
        ForEach(gate.hours, id: \.self) { hour in
            let offset = (hour - gate.hours.lowerBound) * Voyage.stagesPerHour
            Group {
                if offset > 0 {
                    VStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { tick in
                            Rectangle()
                                .fill(Theme.parchmentDim.opacity(0.14))
                                .frame(width: 1, height: 12)
                            if tick < 6 {
                                Rectangle()
                                    .fill(Theme.parchmentDim.opacity(0.06))
                                    .frame(width: 1, height: 10)
                            }
                        }
                    }
                    .frame(width: 1)
                    .position(x: edgePadding + CGFloat(offset) * columnWidth, y: topInset + 70)
                }

                HStack(spacing: 3) {
                    // The painted hour tick, with the current-hour pointer on
                    // the water you are sailing right now.
                    DuatImage(name: hour == game.currentHour ? DuatArt.nightCurrent : DuatArt.nightHour,
                              height: hour == game.currentHour ? 13 : 11,
                              fit: .fit)
                        .colorMultiply(hour == game.currentHour ? Theme.gold : Theme.parchmentDim)
                        .opacity(hour == game.currentHour ? 1 : 0.45)

                    Text(Voyage.romanNumeral(hour))
                        .font(.system(size: 8.5, weight: .black))
                        .kerning(1)
                        .foregroundStyle(hour == game.currentHour ? Theme.gold : Theme.parchmentDim.opacity(0.5))

                    if hour % 4 == 0 {
                        DuatImage(name: DuatArt.nightBoundary, height: 11, fit: .fit)
                            .colorMultiply(Theme.blood)
                            .opacity(0.8)
                    }
                }
                .position(x: edgePadding + (CGFloat(offset) + 2) * columnWidth, y: mapHeight - 10)
            }
        }
    }

    // MARK: - One node

    private func nodeView(_ node: VoyageNode) -> some View {
        let cleared = game.clearedNodeIDs.contains(node.id)
        let available = game.isNodeAvailable(node)
        let isLast = game.lastClearedNodeID == node.id
        let size: CGFloat = node.isBoss ? 56 : 40
        let tint = node.kind.tint

        // Which painted marker this stop wears: the barque's current mooring,
        // water already behind you, an open channel, a serpent-lord's gate, or
        // a channel that closed when you chose otherwise.
        let marker: DuatArt.RouteState = isLast ? .selected
            : cleared ? .cleared
            : node.isBoss ? .boss
            : available ? .available
            : .locked

        return Button {
            game.enter(node)
        } label: {
            ZStack {
                if available {
                    DuatImage(name: DuatArt.RouteState.available.rawValue,
                              height: size + 18, fit: .fit)
                        .colorMultiply(tint)
                        .scaleEffect(pulse ? 1.1 : 0.96)
                        .opacity(pulse ? 0.22 : 0.5)
                        .blur(radius: 3)
                }

                DuatImage(name: marker.rawValue, height: size, fit: .fit)
                    .modifier(TintWash(tint: available || isLast ? tint : nil))
                    .opacity(available || isLast || cleared ? 1 : 0.5)

                DuatSymbol(art: node.kind.artName,
                           fallback: node.kind.symbol,
                           size: node.isBoss ? 28 : 18,
                           tint: available ? Theme.bg
                               : isLast ? Theme.gold
                               : cleared ? Theme.forest
                               : Theme.parchmentDim.opacity(0.55))
                    .opacity(cleared && !isLast ? 0.4 : 1)
            }
            .frame(width: size + 18, height: size + 18)
            .shadow(color: available ? tint.opacity(pulse ? 0.85 : 0.4) : .clear, radius: pulse ? 14 : 6)
            .overlay(alignment: .bottom) {
                if node.isBoss {
                    Text(EnemyContent.enemy(hour: node.hour, isHerald: false).name.uppercased())
                        .font(.system(size: 6.5, weight: .black))
                        .kerning(0.8)
                        .foregroundStyle(Theme.blood.opacity(0.9))
                        .lineLimit(1)
                        .fixedSize()
                        .offset(y: 17)
                }
            }
            .contentShape(Rectangle().inset(by: -8))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!available)
    }
}
