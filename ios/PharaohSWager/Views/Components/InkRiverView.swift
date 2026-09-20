import SwiftUI

/// Quiet painted depth, with sharp moving reflections kept below the combatants.
struct InkRiverView: View {
    let gate: Gate
    var speed: Double = 1
    var discGlow: Double = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion || speed == 0)) { tick in
                let time = reduceMotion || speed == 0 ? 0 : tick.date.timeIntervalSinceReferenceDate * speed
                ZStack {
                    PharaohSWagerImage(name: "ink.region.\(gate.rawValue)",
                        width: proxy.size.width * 1.035, height: proxy.size.height, fit: .fill)
                        .offset(x: sin(time * 0.055) * proxy.size.width * 0.012)
                    LinearGradient(colors: [.black.opacity(0.12), .clear, .black.opacity(0.32)],
                                   startPoint: .top, endPoint: .bottom)
                    Canvas { context, size in
                        for index in 0..<30 {
                            let phase = Double(index) * 2.399
                            let x = (Double(index) * 0.173 + time * 0.007).truncatingRemainder(dividingBy: 1)
                            let y = size.height * (0.70 + CGFloat(index % 7) * 0.043)
                            let width = CGFloat(12 + index % 5 * 9)
                            let rect = CGRect(x: CGFloat(x) * size.width, y: y, width: width, height: 1.5)
                            let opacity = (0.12 + 0.1 * sin(time + phase)) * discGlow
                            context.fill(Path(rect), with: .color(gate.accent.opacity(opacity)))
                        }
                        if gate == .fire {
                            for index in 0..<16 {
                                let progress = (time * 0.085 + Double(index) / 16).truncatingRemainder(dividingBy: 1)
                                let x = CGFloat((Double(index) * 0.618).truncatingRemainder(dividingBy: 1)) * size.width
                                let y = size.height * CGFloat(1 - progress)
                                var shard = Path()
                                shard.move(to: CGPoint(x: x, y: y - 4))
                                shard.addLines([CGPoint(x: x + 2, y: y), CGPoint(x: x, y: y + 3), CGPoint(x: x - 1, y: y)])
                                shard.closeSubpath()
                                context.fill(shard, with: .color(Color.orange.opacity(0.55 * (1 - progress))))
                            }
                        }
                    }
                    if let foreground = InkWorldArt.cell("ink_foregrounds", index: gate.rawValue, columns: 1, rows: 3) {
                        Image(uiImage: foreground).resizable().scaledToFill()
                            .frame(width: proxy.size.width * 1.035, height: proxy.size.height * 0.32)
                            .clipped()
                            .offset(x: sin(time * 0.085) * proxy.size.width * 0.01,
                                    y: proxy.size.height * 0.34)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// An inked tapered stroke rather than a soft capsule of light.
struct InkStreak: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLines([CGPoint(x: rect.maxX * 0.76, y: rect.minY),
                       CGPoint(x: rect.maxX, y: rect.midY),
                       CGPoint(x: rect.maxX * 0.7, y: rect.maxY)])
        path.closeSubpath()
        return path
    }
}

struct InkImpactFlare: View {
    var tint: Color
    var magnitude: Int
    var isCrit: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    var body: some View {
        GeometryReader { proxy in
            let edge = min(proxy.size.width, proxy.size.height)
            ZStack {
                ForEach(0..<(isCrit ? 10 : 6), id: \.self) { index in
                    InkStreak()
                        .fill(index.isMultiple(of: 2) ? tint : Theme.parchment)
                        .frame(width: edge * (0.17 + Double(min(magnitude, 6)) * 0.016), height: isCrit ? 5 : 3)
                        .offset(x: edge * (expanded ? 0.32 : 0.08))
                        .rotationEffect(.degrees(Double(index) * (isCrit ? 36 : 60) + 17))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .opacity(expanded ? 0 : 1)
            .task {
                guard !reduceMotion else { expanded = true; return }
                try? await Task.sleep(for: .milliseconds(20))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.24)) { expanded = true }
            }
        }
        .allowsHitTesting(false)
    }
}
