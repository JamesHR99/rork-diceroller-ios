import SwiftUI

/// The living PharaohSWager scene that sits behind every screen, built from the painted
/// scenery plates: a deep star field, the distant ruins drifting past, black
/// water with the sun's reflection rolling over it, the solar barque riding
/// above, and reeds framing the foreground.
///
/// Every plate in the pack is a single still image, so all the motion here is
/// code: the layers scroll at different speeds, the reeds sway from their
/// stems, the mist creeps, the halo breathes and the embers rise. The barque
/// always feels like it is travelling, even while the player reads a card.
struct PharaohSWagerSceneView: View {
    let gate: Gate
    /// Where the water begins, as a fraction of the view's height.
    var waterline: CGFloat = 0.58
    /// How fast the world slides past. 0 stops the scene dead.
    var speed: Double = 1
    /// Extra darkness laid over the whole scene, 0 through 1.
    var dim: Double = 0
    /// 0 through 1 — how brightly Ra's disc is burning right now.
    var discGlow: Double = 1
    /// Whether the scene draws the barque itself. Screens that stage their own
    /// hull — the arena, the title, the mooring — switch it off, so there is
    /// never a second boat drifting behind the one you are standing on.
    var showsBarque: Bool = true

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let horizon = size.height * waterline

            ZStack {
                skyWash(size: size, horizon: horizon)
                starField(size: size, horizon: horizon)
                sunDisc(size: size, horizon: horizon)
                ruins(size: size, horizon: horizon)
                water(size: size, horizon: horizon)
                reflection(size: size, horizon: horizon)
                if gate.hasSerpent { coil(size: size, horizon: horizon) }
                mist(size: size, horizon: horizon)
                if showsBarque { barque(size: size, horizon: horizon) }
                if gate.hasEmbers { brazier(size: size, horizon: horizon) }
                reeds(size: size, horizon: horizon)
                if gate.hasEmbers { embers(size: size) }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .overlay(Color.black.opacity(dim).allowsHitTesting(false))
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// A drifting layer: `period` seconds to travel its own width, drawn twice
    /// end to end so the wrap never shows. Stopped dead when the scene is
    /// paused, and sped up or slowed with the rest of the scene.
    private func drift(_ period: Double, width: CGFloat) -> some ViewModifier {
        DriftModifier(period: period / max(speed, 0.0001), width: width, isRunning: speed > 0)
    }

    // MARK: - Sky and stars

    private func skyWash(size: CGSize, horizon: CGFloat) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [gate.skyTop, gate.skyTop, gate.skyHorizon],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: horizon)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, gate.discColor.opacity(0.22 * discGlow)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: horizon * 0.45)
            }
            Spacer(minLength: 0)
        }
    }

    /// Painted star glints, scattered deterministically and twinkling on their
    /// own phases. Apep eats most of them in the last gate.
    private func starField(size: CGSize, horizon: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: speed == 0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate * speed
            let fade = gate == .coils ? 0.3 : 1.0
            ZStack {
                ForEach(Array(StarField.stars.enumerated()), id: \.offset) { _, star in
                    let twinkle = 0.3 + 0.7 * (0.5 + 0.5 * sin(time * star.speed + star.phase))
                    PharaohSWagerImage(name: "duat_environment_star", height: star.size, fit: .fit)
                        .opacity(twinkle * star.brightness * fade)
                        .position(x: star.x * size.width, y: star.y * horizon)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Ra's disc

    /// The disc hangs over the barque with its halo behind it. The three disc
    /// states are matched to one displayed diameter, so a gate change is a
    /// crossfade rather than a jump in size.
    private func sunDisc(size: CGSize, horizon: CGFloat) -> some View {
        let diameter = min(size.width * 0.16, horizon * 0.52)
        return TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: speed == 0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate * speed
            let breath = 0.5 + 0.5 * sin(time * 0.35)
            ZStack {
                PharaohSWagerImage(name: "duat_environment_sun_halo", height: diameter * 2.1, fit: .fit)
                    .opacity((0.22 + 0.2 * breath) * discGlow)
                    .scaleEffect(1 + 0.04 * breath)

                PharaohSWagerImage(name: gate.sunArt, height: diameter, fit: .fit)
                    .shadow(color: gate.discColor.opacity(0.55 * discGlow), radius: diameter * 0.35)
                    .id(gate)
                    .transition(.opacity)
            }
            .position(x: size.width * 0.5, y: horizon * 0.42)
        }
        .animation(.easeInOut(duration: 1.2), value: gate)
        .allowsHitTesting(false)
    }

    // MARK: - Bank

    /// The distant ruins, furthest back and slowest — a long drift so the far
    /// bank reads as depth rather than speed.
    private func ruins(size: CGSize, horizon: CGFloat) -> some View {
        let height = horizon * 0.42
        let layerWidth = size.width * 1.35
        return PharaohSWagerImage(name: "duat_environment_ruins", width: layerWidth, height: height, fit: .fill)
            .frame(width: layerWidth, height: height)
            .colorMultiply(gate.bank.opacity(0.95))
            .modifier(drift(74, width: layerWidth))
            .frame(width: size.width, height: height, alignment: .leading)
            .clipped()
            .position(x: size.width / 2, y: horizon - height * 0.5)
            .opacity(0.9)
            .allowsHitTesting(false)
    }

    // MARK: - Water

    private func water(size: CGSize, horizon: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            LinearGradient(
                colors: [gate.waterTop, gate.waterBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: size.height - horizon)
        }
    }

    /// The painted reflection lying on the water — jade, ember or violet by
    /// gate. Two copies at different speeds and opacities so the surface is
    /// never still.
    private func reflection(size: CGSize, horizon: CGFloat) -> some View {
        let waterHeight = size.height - horizon
        let nearWidth = size.width * 1.5
        let farWidth = size.width * 1.8
        return ZStack {
            PharaohSWagerImage(name: gate.rippleArt, width: nearWidth, height: waterHeight * 0.62, fit: .fill)
                .frame(width: nearWidth, height: waterHeight * 0.62)
                .modifier(drift(38, width: nearWidth))
                .opacity(0.48 * discGlow)

            PharaohSWagerImage(name: gate.rippleArt, width: farWidth, height: waterHeight * 0.9, fit: .fill)
                .frame(width: farWidth, height: waterHeight * 0.9)
                .scaleEffect(y: -1)
                .modifier(drift(23, width: farWidth))
                .opacity(0.3 * discGlow)
                .offset(y: waterHeight * 0.26)
        }
        .frame(width: size.width, height: waterHeight, alignment: .leading)
        .clipped()
        .position(x: size.width / 2, y: horizon + waterHeight / 2)
        .blendMode(.plusLighter)
        .animation(.easeInOut(duration: 1.2), value: gate)
        .allowsHitTesting(false)
    }

    /// The last gate: Apep's coil rolls under the surface, its lower ends
    /// masked by the water so it reads as one body breaking through.
    private func coil(size: CGSize, horizon: CGFloat) -> some View {
        let waterHeight = size.height - horizon
        let layerWidth = size.width * 1.4
        return TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: speed == 0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate * speed
            let roll = CGFloat(sin(time * 0.5)) * waterHeight * 0.05
            PharaohSWagerImage(name: "duat_environment_coil", width: layerWidth, height: waterHeight * 0.52, fit: .fill)
                .frame(width: layerWidth, height: waterHeight * 0.52)
                .modifier(drift(27, width: layerWidth))
                .offset(y: roll)
                .frame(width: size.width, alignment: .leading)
                .clipped()
                .position(x: size.width / 2, y: horizon + waterHeight * 0.52)
                .opacity(0.8)
        }
        .allowsHitTesting(false)
    }

    /// Mist creeping across the water, two bands at different speeds.
    private func mist(size: CGSize, horizon: CGFloat) -> some View {
        let waterHeight = size.height - horizon
        let highWidth = size.width * 1.6
        let lowWidth = size.width * 2
        return ZStack {
            PharaohSWagerImage(name: "duat_environment_mist", width: highWidth, height: waterHeight * 0.34, fit: .fill)
                .frame(width: highWidth, height: waterHeight * 0.34)
                .modifier(drift(46, width: highWidth))
                .opacity(0.3)
                .offset(y: -waterHeight * 0.18)

            PharaohSWagerImage(name: "duat_environment_mist", width: lowWidth, height: waterHeight * 0.5, fit: .fill)
                .frame(width: lowWidth, height: waterHeight * 0.5)
                .scaleEffect(x: -1)
                .modifier(drift(31, width: lowWidth))
                .opacity(0.2)
                .offset(y: waterHeight * 0.2)
        }
        .frame(width: size.width, height: waterHeight, alignment: .leading)
        .clipped()
        .position(x: size.width / 2, y: horizon + waterHeight / 2)
        .colorMultiply(gate.reflection.opacity(0.9))
        .allowsHitTesting(false)
    }

    // MARK: - Foreground

    /// The barque itself, riding the water with a slow vertical roll.
    private func barque(size: CGSize, horizon: CGFloat) -> some View {
        let width = size.width * 0.62
        return TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: speed == 0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate * speed
            let bob = CGFloat(sin(time * 0.6)) * 5
            let lean = sin(time * 0.43) * 0.7
            PharaohSWagerImage(name: "duat_environment_barque", width: width, fit: .fit)
                .rotationEffect(.degrees(lean))
                .position(x: size.width * 0.5, y: horizon + (size.height - horizon) * 0.22 + bob)
                .opacity(0.9)
        }
        .allowsHitTesting(false)
    }

    /// The second gate's brazier, its flame flickering on the coals.
    private func brazier(size: CGSize, horizon: CGFloat) -> some View {
        let height = (size.height - horizon) * 0.34
        return TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: speed == 0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate * speed
            let flicker = 0.88 + 0.12 * sin(time * 5.1)
            let lean = sin(time * 2.3) * 2.4
            ZStack(alignment: .bottom) {
                PharaohSWagerImage(name: "duat_environment_brazier", height: height, fit: .fit)

                PharaohSWagerImage(name: "duat_environment_flame", height: height * 0.95, fit: .fit)
                    .scaleEffect(x: flicker, y: 1 / flicker, anchor: .bottom)
                    .rotationEffect(.degrees(lean), anchor: .bottom)
                    .offset(y: -height * 0.52)
                    .opacity(0.92)
                    .shadow(color: Theme.ember.opacity(0.7), radius: height * 0.3)
            }
            .position(x: size.width * 0.14, y: size.height - height * 0.42)
        }
        .allowsHitTesting(false)
    }

    /// Reeds framing both edges of the frame, pivoting near their bundled
    /// stem base so they sway rather than slide.
    private func reeds(size: CGSize, horizon: CGFloat) -> some View {
        let height = size.height * 0.52
        return TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: speed == 0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate * speed
            ZStack {
                PharaohSWagerImage(name: "duat_environment_reeds_left", height: height, fit: .fit)
                    .rotationEffect(.degrees(sin(time * 0.7) * 2.2), anchor: .bottom)
                    .position(x: size.width * 0.06, y: size.height - height * 0.5 + 6)

                PharaohSWagerImage(name: "duat_environment_reeds_right", height: height * 1.05, fit: .fit)
                    .rotationEffect(.degrees(sin(time * 0.58 + 1.4) * 2.6), anchor: .bottom)
                    .position(x: size.width * 0.95, y: size.height - height * 0.52 + 6)
            }
            .colorMultiply(gate.hasReeds ? Color.white : gate.bank.opacity(0.95))
            .opacity(gate.hasReeds ? 0.95 : 0.55)
        }
        .allowsHitTesting(false)
    }

    /// Embers rising through the frame in the second gate.
    private func embers(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: speed == 0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate * speed
            ZStack {
                ForEach(Array(Embers.all.enumerated()), id: \.offset) { _, ember in
                    let cycle = (time * ember.speed + ember.phase).truncatingRemainder(dividingBy: 1)
                    let rise = CGFloat(1 - cycle)
                    let alpha = max(0, 1 - abs(cycle - 0.4) * 1.6) * 0.85
                    PharaohSWagerImage(name: "duat_environment_ember", height: ember.size, fit: .fit)
                        .opacity(alpha)
                        .position(
                            x: ember.x * size.width + CGFloat(sin(time * 1.6 + ember.phase * 6)) * 16,
                            y: size.height * rise
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Drift

/// Scrolls a layer sideways forever, with a second copy trailing it so the
/// wrap is invisible. The layer slides exactly its own width before looping,
/// which is what makes the seam land on itself instead of jumping.
private struct DriftModifier: ViewModifier {
    /// Seconds to travel one full layer width.
    let period: Double
    /// The layer's own width — the exact distance it must slide to repeat.
    let width: CGFloat
    let isRunning: Bool

    @State private var shift: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .leading) {
                // The trailing copy, laid end to end with the original.
                content.offset(x: width)
            }
            .offset(x: shift)
            .onAppear { start() }
            .onChange(of: isRunning) { _, _ in start() }
            .onChange(of: period) { _, _ in start() }
            .onChange(of: width) { _, _ in start() }
    }

    private func start() {
        shift = 0
        guard isRunning, period > 0, width > 0 else { return }
        withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) {
            shift = -width
        }
    }
}

// MARK: - Precomputed scenery

/// Deterministic star field so the sky is stable between launches.
private enum StarField {
    struct Star {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let brightness: Double
        let phase: Double
        let speed: Double
    }

    static let stars: [Star] = {
        var generator = SeededGenerator(seed: 20260802)
        return (0..<44).map { _ in
            Star(
                x: CGFloat(Double.random(in: 0...1, using: &generator)),
                y: CGFloat(Double.random(in: 0.02...0.88, using: &generator)),
                size: CGFloat(Double.random(in: 5...13, using: &generator)),
                brightness: Double.random(in: 0.3...0.95, using: &generator),
                phase: Double.random(in: 0...6.28, using: &generator),
                speed: Double.random(in: 0.4...1.8, using: &generator)
            )
        }
    }()
}

private enum Embers {
    struct Ember {
        let x: CGFloat
        let size: CGFloat
        let phase: Double
        let speed: Double
    }

    static let all: [Ember] = {
        var generator = SeededGenerator(seed: 90210)
        return (0..<18).map { _ in
            Ember(
                x: CGFloat(Double.random(in: 0...1, using: &generator)),
                size: CGFloat(Double.random(in: 7...17, using: &generator)),
                phase: Double.random(in: 0...1, using: &generator),
                speed: Double.random(in: 0.05...0.14, using: &generator)
            )
        }
    }()
}

/// Tiny deterministic PRNG so the scenery is identical every launch.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
