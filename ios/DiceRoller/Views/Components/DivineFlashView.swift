import SwiftUI

/// What the gods did to this action, held up in the middle of the deck before
/// the blow lands.
///
/// A god's answer used to be a floater that flew past while the numbers were
/// still moving — you saw a colour and a name and never learned what it was
/// worth. This card names the power, the god behind it and the exact effect,
/// and holds for long enough to read. It is not the chain spectacle: no
/// shockwave, no embers, nothing that competes with a landing combo — a
/// carved tablet rising out of the dark, then gone.
struct DivineFlashView: View {
    let flash: DivineFlash

    @State private var risen = false
    @State private var glow = false

    /// The gods answering, in the order they landed, each named once even when
    /// several of their powers spoke.
    private var gods: [Deity] {
        var seen: Set<Deity> = []
        return flash.entries.compactMap { entry in
            guard !seen.contains(entry.god) else { return nil }
            seen.insert(entry.god)
            return entry.god
        }
    }

    /// The card takes its colour from the first god to answer.
    private var accent: Color { flash.entries.first?.god.tint ?? Theme.gold }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) { risen = true }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { glow = true }
        }
    }

    private var card: some View {
        VStack(spacing: 7) {
            sigilRow
            GoldRule(height: 4, opacity: 0.6).frame(width: 200)
            ForEach(flash.entries) { entry in
                entryRow(entry)
            }
            Text(flash.action.uppercased())
                .font(.system(size: 8.5, weight: .black))
                .kerning(1.6)
                .foregroundStyle(Theme.parchmentDim.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: 340)
        .background {
            PapyrusSurface(ground: .panel, tint: Theme.bgElevated, strength: 0.6, shade: 0.42)
                .clipShape(.rect(cornerRadius: 18))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(colors: [accent.opacity(0.9), accent.opacity(0.35)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.6
                )
        )
        .goldCorners(size: 18, inset: 4, opacity: 0.7)
        .shadow(color: accent.opacity(glow ? 0.55 : 0.3), radius: glow ? 26 : 16)
        .shadow(color: .black.opacity(0.7), radius: 14, y: 6)
        .scaleEffect(risen ? 1 : 0.82)
        .opacity(risen ? 1 : 0)
        .blur(radius: risen ? 0 : 5)
    }

    /// The gods who spoke, haloed, over the heading.
    private var sigilRow: some View {
        VStack(spacing: 5) {
            HStack(spacing: 10) {
                ForEach(gods.prefix(3), id: \.self) { god in
                    DuatSymbol(art: god.artName, fallback: god.symbol, size: 34, tint: god.tint)
                        .shadow(color: god.tint.opacity(0.9), radius: glow ? 14 : 8)
                }
            }

            Text(gods.count == 1
                 ? "\(gods[0].name.uppercased()) ANSWERS"
                 : "THE GODS ANSWER")
                .font(.fantasy(15, weight: .black))
                .kerning(2.4)
                .foregroundStyle(
                    LinearGradient(colors: [Theme.parchment, accent],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: accent.opacity(0.8), radius: 10)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    /// One power: its god's colour, its name, and exactly what it did.
    private func entryRow(_ entry: DivineFlashEntry) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(entry.god.tint)
                .frame(width: 6, height: 6)
                .shadow(color: entry.god.tint.opacity(0.9), radius: 4)

            Text(entry.name.uppercased())
                .font(.system(size: 11, weight: .black))
                .kerning(0.6)
                .foregroundStyle(Theme.parchment)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 6)

            Text(entry.effect)
                .font(.system(size: 11.5, weight: .black).monospacedDigit())
                .foregroundStyle(entry.god.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Theme.bg.opacity(0.62), in: .rect(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(entry.god.tint.opacity(0.35), lineWidth: 1)
        )
    }
}
