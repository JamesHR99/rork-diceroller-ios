import SwiftUI

/// Keeps a column within its safe-area proposal. Short screens can scroll
/// long text and controls instead of clipping them or scaling down touch targets.
struct FittingScrollColumn<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                content
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        }
    }
}

/// Point sizes, never a transform applied to the whole UI. The deck's
/// scroll fallback handles exceptionally short windows at readable sizes.
struct BattleDeckMetrics {
    let height: CGFloat
    let reelHeight: CGFloat
    let planHeight: CGFloat
    var isCompact: Bool { height < 240 }

    init(screenHeight: CGFloat, headerHeight: CGFloat, planCount: Int = 0) {
        height = max(0, screenHeight - headerHeight - 8)
        let content = max(0, height - 58)
        planHeight = planCount > 3 ? max(140, min(180, height - 42)) : min(112, max(82, content * 0.53))
        reelHeight = min(124, max(44, content - planHeight))
    }
}


/// Measures every line before scaling; no truncation or hidden scroll content.
struct FittedActionContent<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var measuredHeight: CGFloat = 1

    var body: some View {
        GeometryReader { proxy in
            let width = max(150, proxy.size.width)
            let scale = min(1, min(proxy.size.width / width, proxy.size.height / max(1, measuredHeight)))
            content()
                .frame(width: width, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { measuredHeight = $0 }
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
    }
}

struct RerollChargeAnchorKey: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

/// Runs while the committed dice are still visible; resolution waits for it.
struct RerollChargeFlight: View {
    let sources: [CGRect]
    let destination: CGRect
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false

    var body: some View {
        ZStack {
            ForEach(Array(sources.enumerated()), id: \.offset) { index, rect in
                Image(systemName: "sparkle")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .shadow(color: Theme.gold, radius: 8)
                    .position(x: arrived || reduceMotion ? destination.midX : rect.midX,
                              y: arrived || reduceMotion ? destination.midY : rect.midY)
                    .opacity(arrived ? 0 : 1)
                    .animation(.easeInOut(duration: reduceMotion ? 0.18 : 0.55).delay(Double(index) * 0.06), value: arrived)
            }
        }
        .allowsHitTesting(false)
        .onAppear { arrived = true }
    }
}
