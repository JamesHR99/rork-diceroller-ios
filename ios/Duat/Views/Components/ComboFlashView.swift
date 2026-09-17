import SwiftUI

/// The spectacle a landing chain throws across the whole arena: a shockwave
/// scaled to the length of the chain, a wash of its own colour, embers off the
/// impact, and a banner that slams in naming the chain and what it just did.
struct ComboFlashView: View {
    let flash: ComboFlash

    @State private var wave: CGFloat = 0
    @State private var sparks: CGFloat = 0
    @State private var wash: Double = 0
    @State private var bannerIn = false
    @State private var hold = false

    /// 0 for a two-face pair, 1 for a five-face chain — everything here scales
    /// off it, so a long chain genuinely hits harder than a short one.
    private var weight: Double {
        min(max(Double(flash.chain) - 2, 0) / 3.0, 1)
    }

    private var ringCount: Int { flash.crit ? 3 : (flash.chain >= 4 ? 3 : 2) }
    private var bannerSize: CGFloat { 22 + CGFloat(weight) * 16 + (flash.crit ? 6 : 0) }

    var body: some View {
        ZStack {
            arenaDarken
            colourWash
            shockwave
            emberBurst
            banner
        }
        .allowsHitTesting(false)
        .onAppear { run() }
    }

    /// A long chain takes the whole deck: the arena sinks into the dark so the
    /// chain's own colour is the only thing left burning. A modest pair barely
    /// dims at all.
    private var arenaDarken: some View {
        Theme.bg
            .opacity(0.72 * wash * weight)
            .ignoresSafeArea()
    }

    /// The arena edges take the chain's colour for a beat.
    private var colourWash: some View {
        ZStack {
            RadialGradient(
                colors: [.clear, flash.tint.opacity(0.55)],
                center: .center,
                startRadius: 120,
                endRadius: 470
            )
            flash.tint.opacity(0.16 + 0.12 * weight)
                .blendMode(.plusLighter)
        }
        .opacity(wash)
        .ignoresSafeArea()
    }

    /// Rings thrown out from the middle of the deck. The longer the chain, the
    /// further and harder they travel.
    private var shockwave: some View {
        ZStack {
            ForEach(0..<ringCount, id: \.self) { index in
                let delay = Double(index) * 0.12
                let progress = max(0, min(1, Double(wave) - delay)) / max(0.001, 1 - delay)
                Circle()
                    .strokeBorder(
                        index == 0 ? flash.tint : flash.tint.opacity(0.6),
                        lineWidth: (index == 0 ? 6 : 3) * (1 + weight)
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(0.3 + progress * (2.6 + weight * 2.4))
                    .opacity((1 - progress) * (0.85 - Double(index) * 0.18))
                    .blur(radius: 2)
            }
        }
        .ignoresSafeArea()
    }

    /// Embers off the impact, tinted to the chain.
    private var emberBurst: some View {
        ZStack {
            ForEach(0..<sparkCount, id: \.self) { index in
                let angle = Double(index) / Double(sparkCount) * 2 * .pi
                let reach = 130.0 + Double((index * 37) % 90) + weight * 120
                Capsule()
                    .fill(index.isMultiple(of: 3) ? Theme.gold : flash.tint)
                    .frame(width: 3 + CGFloat(weight) * 1.6, height: 14 + CGFloat(weight) * 12)
                    .offset(y: -reach * Double(sparks))
                    .rotationEffect(.radians(angle))
                    .opacity((1 - Double(sparks)) * 0.9)
            }
        }
        .blur(radius: 0.7)
    }

    private var sparkCount: Int { flash.crit ? 22 : (10 + flash.chain * 3) }

    /// The name of the chain slamming into the middle of the deck.
    private var banner: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    DuatImage(name: DuatArt.chainConnector, width: 14, fit: .fit)
                        .colorMultiply(Theme.bg)
                    Text("\(flash.chain)-CHAIN")
                        .font(.system(size: 10 + weight * 3, weight: .black))
                        .kerning(2)
                        .foregroundStyle(Theme.bg)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(flash.tint, in: .capsule)

                if flash.crit {
                    HStack(spacing: 4) {
                        DuatIcon(name: DuatArt.Status.critical, size: 14)
                        Text("CRITICAL")
                            .font(.system(size: 11, weight: .black))
                            .kerning(2.4)
                            .foregroundStyle(Theme.gold)
                    }
                }
            }

            // The chain's name burning on the painted banner.
            Text(flash.name.uppercased())
                .font(.fantasy(bannerSize, weight: .black))
                .kerning(2.5)
                .foregroundStyle(
                    LinearGradient(colors: [Theme.parchment, flash.tint],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: flash.tint.opacity(0.9), radius: 18)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background {
                    DuatImage(name: DuatArt.banner, fit: .stretch)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .colorMultiply(flash.tint)
                }

            GoldRule(height: 5, opacity: 0.7)
                .frame(width: 220 + weight * 120)

            Text(flash.summary)
                .font(.system(size: 11, weight: .black).monospacedDigit())
                .kerning(0.6)
                .foregroundStyle(Theme.parchment.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 24)
        .scaleEffect(bannerIn ? (hold ? 1.06 : 1) : 1.9)
        .opacity(bannerIn ? 1 : 0)
        .blur(radius: bannerIn ? 0 : 6)
    }

    private func run() {
        // The banner slams down out of nothing, then hangs — on a critical the
        // hang runs long, so the deck holds its breath before the numbers fly.
        withAnimation(.spring(response: 0.26, dampingFraction: 0.55)) { bannerIn = true }
        withAnimation(.easeOut(duration: 0.55 + weight * 0.35)) { wave = 1 }
        withAnimation(.easeOut(duration: 0.6 + weight * 0.3)) { sparks = 1 }
        wash = 0.9
        withAnimation(.easeOut(duration: 0.5 + weight * 0.3)) { wash = 0 }
        if flash.crit {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { hold = true }
        }
    }
}
