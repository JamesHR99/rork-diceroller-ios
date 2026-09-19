import SwiftUI
import UIKit

/// How a painted plate meets the box it is given.
enum PharaohSWagerFit {
    /// Preserve the drawing's own proportions inside the box.
    case fit
    /// Preserve proportions but cover the box, clipping the overflow.
    case fill
    /// Pull the drawing to exactly the box — for the wide plates (buttons,
    /// bars, banners, intent) that were drawn to be stretched.
    case stretch
}

/// One painted plate, displayed by its real ink rather than its canvas.
///
/// Every drawing in the pack floats inside a much larger transparent square.
/// Rendering the raw asset leaves the art tiny and off-centre; this crops to
/// the manifest's content rectangle first, so a 20pt icon is 20pt of drawing.
struct PharaohSWagerImage: View {
    let name: String
    var width: CGFloat?
    var height: CGFloat?
    var fit: PharaohSWagerFit = .fit
    /// Tints the whole plate — used for ghosting and state washes.
    var opacity: Double = 1

    var body: some View {
        if width == nil && height == nil {
            // Background plates take the control's proposed size. Previously
            // an unsized .stretch plate resolved to 0 x 0 before the outer
            // frame expanded, leaving the painted button/panel invisible.
            GeometryReader { proxy in
                PharaohSWagerImage(name: name, width: proxy.size.width,
                                   height: proxy.size.height, fit: fit, opacity: opacity).plate
            }
        } else {
            plate
        }
    }

    @ViewBuilder
    private var plate: some View {
        if PharaohSWagerArt.exists(name) {
            let box = PharaohSWagerArt.crop(name)
            let draw = drawSize(box)
            let outer = outerSize(box, draw: draw)
            let fullWidth = draw.width / max(box.width, 0.0001)
            let fullHeight = draw.height / max(box.height, 0.0001)

            Image(name)
                .resizable()
                .frame(width: fullWidth, height: fullHeight)
                .offset(x: -box.x * fullWidth, y: -box.y * fullHeight)
                .frame(width: draw.width, height: draw.height, alignment: .topLeading)
                .clipped()
                .frame(width: outer.width, height: outer.height)
                .clipped()
                .opacity(opacity)
        }
    }

    /// The size the drawing itself is rendered at.
    private func drawSize(_ box: PharaohSWagerCrop) -> CGSize {
        let aspect = max(box.aspect, 0.0001)
        switch fit {
        case .stretch:
            return CGSize(width: width ?? (height ?? 0) * aspect,
                          height: height ?? (width ?? 0) / aspect)
        case .fit, .fill:
            guard let width else {
                let height = height ?? 0
                return CGSize(width: height * aspect, height: height)
            }
            guard let height else {
                return CGSize(width: width, height: width / aspect)
            }
            let widthLed = CGSize(width: width, height: width / aspect)
            let heightLed = CGSize(width: height * aspect, height: height)
            if fit == .fit {
                return widthLed.height <= height ? widthLed : heightLed
            }
            return widthLed.height >= height ? widthLed : heightLed
        }
    }

    /// The box the view actually occupies in the layout.
    private func outerSize(_ box: PharaohSWagerCrop, draw: CGSize) -> CGSize {
        guard fit == .fill, let width, let height else { return draw }
        return CGSize(width: width, height: height)
    }
}

/// A square painted icon — the everyday replacement for `Image(systemName:)`.
struct PharaohSWagerIcon: View {
    @Environment(\.displayScale) private var displayScale
    let name: String
    var size: CGFloat
    var opacity: Double = 1

    var body: some View {
        Group {
            if let image = PharaohSWagerArt.icon(name, pixels: Int(ceil(size * displayScale))) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .opacity(opacity)
    }
}

/// A painted icon that falls back to an inked glyph when the drawing for this
/// thing was never made. Every icon in the game goes through here, so a
/// missing plate degrades instead of leaving a hole.
struct PharaohSWagerSymbol: View {
    let art: String?
    let fallback: String
    var size: CGFloat
    var tint: Color = Theme.parchment
    /// Weight of the glyph fallback only.
    var weight: Font.Weight = .bold

    var body: some View {
        if let art, PharaohSWagerArt.exists(art) {
            PharaohSWagerIcon(name: art, size: size)
        } else {
            Image(systemName: fallback)
                .font(.system(size: size * 0.82, weight: weight))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Papyrus sheets

/// A painted plate stretched from its middle so its inked border and corner
/// ornaments keep their weight at any size. Only used where a panel really is
/// close to the plate's drawn proportions — wide trays use a plain ground and
/// draw their own edge instead, so nothing smears.
struct PharaohSWagerSheet: View {
    let name: String
    var opacity: Double = 1

    var body: some View {
        if let image = PharaohSWagerArt.sheet(name), let caps = PharaohSWagerArt.caps(name) {
            Image(uiImage: image)
                .resizable(capInsets: caps, resizingMode: .stretch)
                .opacity(opacity)
                .allowsHitTesting(false)
        }
    }
}

/// The painted glyph rule — a strip of carved marks, used under headings and
/// along panel edges where the game used to draw its own.
struct HieroglyphBand: View {
    var tint: Color = Theme.gold
    var height: CGFloat = 9
    var opacity: Double = 0.5

    var body: some View {
        PharaohSWagerImage(name: PharaohSWagerArt.hieroglyphStrip, height: height, fit: .fit)
            .frame(maxWidth: .infinity)
            .clipped()
            .colorMultiply(tint)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

/// The gold-and-lapis rule: a thin painted divider.
struct GoldRule: View {
    var height: CGFloat = 5
    var opacity: Double = 0.8

    var body: some View {
        PharaohSWagerImage(name: PharaohSWagerArt.dividerGold, height: height, fit: .stretch)
            .frame(maxWidth: .infinity)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

/// The winged divider — the heavier flourish, for a panel that deserves one.
struct WingedDivider: View {
    var height: CGFloat = 22
    var opacity: Double = 0.9

    var body: some View {
        PharaohSWagerImage(name: PharaohSWagerArt.dividerWinged, height: height, fit: .fit)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

// MARK: - Panels

/// The standard framed panel: the painted papyrus sheet with a gold rule
/// inked at its head.
struct PharaohSWagerPanel<Content: View>: View {
    var tint: Color = Theme.gold
    var cornerRadius: CGFloat = 16
    var showsBand: Bool = true
    var ground: PapyrusGround = .panel
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                PapyrusSurface(ground: ground, tint: Theme.bgCard, shade: 0.4)
                    .clipShape(.rect(cornerRadius: cornerRadius))
            }
            .overlay(alignment: .top) {
                if showsBand {
                    HieroglyphBand(tint: tint, height: 8, opacity: 0.28)
                        .padding(.horizontal, cornerRadius * 0.7)
                        .padding(.top, 3)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(tint.opacity(0.34), lineWidth: 1)
            )
    }
}

extension View {
    /// Wraps any view in the standard painted panel.
    func duatPanel(tint: Color = Theme.gold, cornerRadius: CGFloat = 16,
                   showsBand: Bool = true, ground: PapyrusGround = .panel) -> some View {
        PharaohSWagerPanel(tint: tint, cornerRadius: cornerRadius, showsBand: showsBand, ground: ground) { self }
    }

    /// Lays the four gold corner ornaments over a panel's corners.
    func goldCorners(size: CGFloat = 20, inset: CGFloat = 2, opacity: Double = 0.85) -> some View {
        overlay {
            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    PharaohSWagerImage(name: PharaohSWagerArt.cornerGold, width: size, height: size, fit: .fit)
                        .rotationEffect(.degrees(Double(index) * 90))
                        .frame(maxWidth: .infinity, maxHeight: .infinity,
                               alignment: PharaohSWagerCornerAlignment.all[index])
                }
            }
            .padding(inset)
            .opacity(opacity)
            .allowsHitTesting(false)
        }
    }
}

/// Corner ornament placement, clockwise from the top-left.
enum PharaohSWagerCornerAlignment {
    static let all: [Alignment] = [.topLeading, .topTrailing, .bottomTrailing, .bottomLeading]
}

// MARK: - Buttons

/// A painted button plate that carries its own pressed and disabled states.
struct PaintedButtonLabel<Content: View>: View {
    var tone: PharaohSWagerArt.ButtonTone = .primary
    var state: PharaohSWagerArt.ButtonState = .normal
    var width: CGFloat?
    var height: CGFloat = 44
    var cornerRadius: CGFloat = 12
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .background {
                PharaohSWagerImage(name: PharaohSWagerArt.button(tone, state), fit: .stretch)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
    }
}

/// The press feel shared by every button in the game: a quick squash with a
/// touch of dim, so a tap reads even where the art has no pressed plate.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Without this the button is only hittable where its label actually
            // paints, so transparent padding, Spacers and gaps between glyphs
            // swallow taps and the control reads as unresponsive.
            .contentShape(.rect)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// The shockwave a freshly combined action throws: a ring pushing outward and
/// a spray of shards, thrown once as the dice snap into one plate.
struct CombineBurst: View {
    let progress: CGFloat
    let tint: Color
    var size: Int = 2

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(tint, lineWidth: 3)
                .scaleEffect(1 + progress * 0.4)
                .opacity(Double(1 - progress) * 0.9)

            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.parchment)
                .opacity(Double(max(0, 0.55 - progress)) * 0.9)
                .blendMode(.plusLighter)

            ForEach(0..<(size * 5), id: \.self) { index in
                let angle = Double(index) / Double(size * 5) * 2 * .pi
                Capsule()
                    .fill(index.isMultiple(of: 2) ? tint : Theme.gold)
                    .frame(width: 2.6, height: 11)
                    .offset(y: -20 - progress * CGFloat(20 + size * 7))
                    .rotationEffect(.radians(angle))
                    .scaleEffect(0.4 + progress * 1.1)
                    .opacity(Double(1 - progress) * 0.95)
            }
        }
        .blur(radius: 0.5)
    }
}

/// A painted button: the plate swaps to its pressed drawing while held.
struct PaintedButtonStyle: ButtonStyle {
    var tone: PharaohSWagerArt.ButtonTone = .primary
    var isEnabled: Bool = true
    var isSelected: Bool = false
    var height: CGFloat = 44
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        let state: PharaohSWagerArt.ButtonState = !isEnabled
            ? .disabled
            : (configuration.isPressed ? .pressed : (isSelected ? .selected : .normal))
        return configuration.label
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background {
                PharaohSWagerImage(name: PharaohSWagerArt.button(tone, state), fit: .stretch)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Resource bars

/// Which painted fill runs inside a bar's channel.
enum PharaohSWagerBarKind {
    case health
    case shield
    case armour

    var fillArt: String {
        switch self {
        case .health: PharaohSWagerArt.barFillHealth
        case .shield: PharaohSWagerArt.barFillShield
        case .armour: PharaohSWagerArt.barFillArmour
        }
    }

    /// The solid colour under the painted fill, so the level reads instantly.
    var baseTint: Color {
        switch self {
        case .health: Theme.blood
        case .shield: Theme.steel
        case .armour: Theme.bronze
        }
    }
}

/// A painted resource bar: the gilded trough with its lotus caps, and a solid
/// fill laid inside the channel so the remaining health is unmistakable.
///
/// The frame plate is opaque where its channel runs, so the fill is drawn
/// *over* the frame and inset to the exact channel measured off the artwork.
/// Laying the fill underneath hid it completely — which is what left every
/// bar reading as empty.
struct PharaohSWagerBar: View {
    let kind: PharaohSWagerBarKind
    /// 0 through 1.
    let fraction: Double
    var width: CGFloat
    var height: CGFloat = 10
    /// Colour wash over the fill — lets a hero's accent ride the health bar.
    var tint: Color? = nil
    var showsCaps: Bool = true

    private var clamped: CGFloat { CGFloat(min(max(fraction, 0), 1)) }

    /// The frame keeps its drawn proportions, so a wider bar is a taller bar.
    private var frameHeight: CGFloat {
        max(height, width / PharaohSWagerArt.BarFrame.aspect)
    }

    private var troughWidth: CGFloat { width * PharaohSWagerArt.BarFrame.troughWidth }
    private var troughHeight: CGFloat { frameHeight * PharaohSWagerArt.BarFrame.troughHeight }

    var body: some View {
        Image(PharaohSWagerArt.barFrame)
            .resizable()
            .frame(width: width, height: frameHeight)
            .overlay(alignment: .leading) {
                // The channel is centred vertically on the plate, so leading
                // alignment plus a leading inset lands the fill exactly in it.
                fill.padding(.leading, PharaohSWagerArt.BarFrame.troughX * width)
            }
            .frame(width: width, height: frameHeight)
            .allowsHitTesting(false)
    }

    /// The colour that runs in the channel. A painted fill plate is washed
    /// over it where the pack has one, so the bar still reads as ink.
    private var fill: some View {
        Capsule()
            .fill(
                LinearGradient(colors: [kind.baseTint.opacity(0.92), kind.baseTint],
                               startPoint: .top, endPoint: .bottom)
            )
            .overlay {
                PharaohSWagerImage(name: kind.fillArt, width: troughWidth, height: troughHeight, fit: .stretch)
                    .opacity(0.5)
                    .blendMode(.overlay)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                // A bright lip along the top so the fill reads as liquid.
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(height: max(troughHeight * 0.26, 1))
                    .padding(.horizontal, 1)
            }
            .clipShape(.capsule)
            .frame(width: max(troughWidth * clamped, clamped > 0 ? 3 : 0),
                   height: troughHeight,
                   alignment: .leading)
            .modifier(TintWash(tint: tint))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: clamped)
    }
}

/// Multiplies a painted plate by a colour without flattening its ink.
struct TintWash: ViewModifier {
    let tint: Color?

    func body(content: Content) -> some View {
        if let tint {
            content.colorMultiply(tint)
        } else {
            content
        }
    }
}

/// Washes a face plate in a state colour — gold for a critical, frost for a
/// held die — while leaving an ordinary roll in its own painted ink.
struct FaceWash: ViewModifier {
    let tint: Color
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.colorMultiply(tint)
        } else {
            content
        }
    }
}

// MARK: - Die frames

extension View {
    /// Lays a painted die frame around a reel. The frames have open centres,
    /// so the face and its numbers show through the window.
    func dieFrame(_ frame: PharaohSWagerArt.DieFrame, tint: Color? = nil, opacity: Double = 1) -> some View {
        overlay {
            PharaohSWagerImage(name: frame.rawValue, fit: .stretch)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(TintWash(tint: tint))
                .opacity(opacity)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Stamina

/// One painted stamina pip. Points earned above the cap wear the reserve mark.
struct PharaohSWagerStaminaPip: View {
    let isFilled: Bool
    let isReserve: Bool
    var size: CGFloat = 13

    private var art: String {
        if isReserve { return PharaohSWagerArt.staminaReserve }
        return isFilled ? PharaohSWagerArt.staminaFull : PharaohSWagerArt.staminaEmpty
    }

    var body: some View {
        PharaohSWagerImage(name: art, height: size, fit: .fit)
            .opacity(isFilled ? 1 : 0.5)
            .shadow(color: isFilled ? (isReserve ? Theme.sunGold : Theme.gold).opacity(0.6) : .clear,
                    radius: isFilled ? 4 : 0)
    }
}

