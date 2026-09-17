import SwiftUI

/// What a tooltip is explaining. Kept as a value so a badge can publish it up
/// to the root layer through a preference without handing over a closure.
enum TooltipPayload {
    case status(LiveStatus)
    case chisel(ChiselDef, isArmed: Bool)
}

/// One open tooltip, with the on-screen rectangle of the badge that opened it.
struct TooltipRequest: Identifiable {
    let id: String
    let anchor: Anchor<CGRect>
    let payload: TooltipPayload
}

/// Carries open tooltips from wherever the badge lives up to the root of the
/// app, so the bubble can be drawn above every panel, the deck and the grain.
struct TooltipPreferenceKey: PreferenceKey {
    nonisolated static var defaultValue: [TooltipRequest] { [] }

    nonisolated static func reduce(
        value: inout [TooltipRequest],
        nextValue: () -> [TooltipRequest]
    ) {
        value.append(contentsOf: nextValue())
    }
}

/// Which tooltip is open, shared across the whole app.
///
/// One place rather than one `@State` per panel, for two reasons: only a single
/// bubble is ever up at a time, and a tap anywhere else can put it away without
/// every screen having to reach into its children.
@Observable
@MainActor
final class TooltipCenter {
    static let shared = TooltipCenter()

    private(set) var openID: String?

    private init() {}

    func isOpen(_ id: String) -> Bool { openID == id }

    func toggle(_ id: String) {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
            openID = openID == id ? nil : id
        }
    }

    func close() {
        guard openID != nil else { return }
        withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
            openID = nil
        }
    }
}

extension View {
    /// Marks this view as the badge a tooltip belongs to. The bubble itself is
    /// drawn by the root layer, so it is never clipped by whatever panel,
    /// scroll view or capsule the badge happens to sit in.
    func tooltipAnchor(id: String, payload: TooltipPayload?) -> some View {
        anchorPreference(key: TooltipPreferenceKey.self, value: .bounds) { anchor in
            guard let payload else { return [] }
            return [TooltipRequest(id: id, anchor: anchor, payload: payload)]
        }
    }

    /// Hosts every tooltip in the app, above all other content.
    func tooltipLayer() -> some View {
        modifier(TooltipLayerModifier())
    }
}

private struct TooltipLayerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.overlayPreferenceValue(TooltipPreferenceKey.self) { requests in
            GeometryReader { proxy in
                if let request = requests.last {
                    ZStack {
                        // A tap anywhere puts the bubble away, the same way
                        // tapping the badge again does.
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { TooltipCenter.shared.close() }

                        TooltipBubble(
                            payload: request.payload,
                            badge: proxy[request.anchor],
                            container: proxy.size
                        )
                    }
                    .transition(.opacity)
                }
            }
            .ignoresSafeArea()
        }
    }
}

/// Places one bubble beside its badge and keeps it on screen: it slides
/// sideways rather than running off an edge, and flips above the badge when
/// there is no room below.
private struct TooltipBubble: View {
    let payload: TooltipPayload
    let badge: CGRect
    let container: CGSize

    @State private var height: CGFloat = 0

    private static let width: CGFloat = 268
    private static let margin: CGFloat = 10
    private static let gap: CGFloat = 8

    /// Below the badge when it fits, otherwise above it.
    private var pointsUp: Bool {
        let fitsBelow = badge.maxY + Self.gap + height <= container.height - Self.margin
        let fitsAbove = badge.minY - Self.gap - height >= Self.margin
        return fitsBelow || !fitsAbove
    }

    private var origin: CGPoint {
        let maxX = max(Self.margin, container.width - Self.width - Self.margin)
        let x = min(max(Self.margin, badge.midX - Self.width / 2), maxX)

        let rawY = pointsUp ? badge.maxY + Self.gap : badge.minY - Self.gap - height
        let maxY = max(Self.margin, container.height - height - Self.margin)
        let y = min(max(Self.margin, rawY), maxY)

        return CGPoint(x: x, y: y)
    }

    var body: some View {
        bubble
            .frame(width: Self.width)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
            .offset(x: origin.x, y: origin.y)
            // Held back for the one frame before the bubble has been measured,
            // so it never flashes in the wrong place.
            .opacity(height > 0 ? 1 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var bubble: some View {
        switch payload {
        case .status(let status):
            StatusBubbleView(status: status, pointsUp: pointsUp)
        case .chisel(let def, let isArmed):
            ChiselBubbleView(def: def, isArmed: isArmed, pointsUp: pointsUp)
        }
    }
}
