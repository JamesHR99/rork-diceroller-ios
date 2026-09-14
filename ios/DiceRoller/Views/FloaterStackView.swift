import SwiftUI

/// Renders floating combat text (damage numbers, statuses) rising and fading.
struct FloaterStackView: View {
    let floaters: [FloatText]

    var body: some View {
        ZStack {
            ForEach(floaters) { floater in
                SingleFloaterView(floater: floater)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SingleFloaterView: View {
    let floater: FloatText
    @State private var rise = false

    var body: some View {
        Text(floater.text)
            .font(.fantasy(floater.big ? 27 : 19, weight: .black))
            .foregroundStyle(floater.color)
            .shadow(color: .black.opacity(0.8), radius: 2, y: 1)
            .shadow(color: floater.color.opacity(0.6), radius: floater.big ? 12 : 6)
            .offset(x: floater.xJitter, y: rise ? -52 : 0)
            .opacity(rise ? 0 : 1)
            .scaleEffect(rise ? 1.05 : (floater.big ? 1.15 : 1))
            .onAppear {
                withAnimation(.easeOut(duration: 1.3)) {
                    rise = true
                }
            }
    }
}
