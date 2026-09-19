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

    init(screenHeight: CGFloat, headerHeight: CGFloat) {
        height = max(0, screenHeight - headerHeight - 8)
        let content = max(0, height - (height < 240 ? 63 : 88))
        planHeight = min(116, max(72, content * 0.48))
        reelHeight = min(130, max(60, content - planHeight))
    }
}
