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
