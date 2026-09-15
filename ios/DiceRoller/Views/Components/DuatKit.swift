import SwiftUI
import UIKit

/// How a painted plate meets the box it is given.
enum DuatFit {
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
struct DuatImage: View {
    let name: String
    var width: CGFloat?
    var height: CGFloat?
    var fit: DuatFit = .fit
    /// Tints the whole plate — used for ghosting and state washes.
    var opacity: Double = 1

    var body: some View {
        if DuatArt.exists(name) {
            let box = DuatArt.crop(name)
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
    private func drawSize(_ box: DuatCrop) -> CGSize {
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
    private func outerSize(_ box: DuatCrop, draw: CGSize) -> CGSize {
        guard fit == .fill, let width, let height else { return draw }
        return CGSize(width: width, height: height)
    }
}

/// A square painted icon — the everyday replacement for `Image(systemName:)`.
struct DuatIcon: View {
    let name: String
    var size: CGFloat
    var opacity: Double = 1

    var body: some View {
        DuatImage(name: name, width: size, height: size, fit: .fit, opacity: opacity)
            .frame(width: size, height: size)
    }
}

/// A painted icon that falls back to an inked glyph when the drawing for this
/// thing was never made. Every icon in the game goes through here, so a
/// missing plate degrades instead of leaving a hole.
struct DuatSymbol: View {
    let art: String?
    let fallback: String
    var size: CGFloat
    var tint: Color = Theme.parchment
    /// Weight of the glyph fallback only.
    var weight: Font.Weight = .bold

    var body: some View {
        if let art, DuatArt.exists(art) {
            DuatIcon(name: art, size: size)
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
struct DuatSheet: View {
    let name: String
    var opacity: Double = 1

    var body: some View {
        if let image = DuatArt.sheet(name), let caps = DuatArt.caps(name) {
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
        DuatImage(name: DuatArt.hieroglyphStrip, height: height, fit: .fit)
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
        DuatImage(name: DuatArt.dividerGold, height: height, fit: .stretch)
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
        DuatImage(name: DuatArt.dividerWinged, height: height, fit: .fit)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

// MARK: - Panels

/// The standard framed panel: the painted papyrus sheet with a gold rule
/// inked at its head.
struct DuatPanel<Content: View>: View {
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
        DuatPanel(tint: tint, cornerRadius: cornerRadius, showsBand: showsBand, ground: ground) { self }
    }

    /// Lays the four gold corner ornaments over a panel's corners.
    func goldCorners(size: CGFloat = 20, inset: CGFloat = 2, opacity: Double = 0.85) -> some View {
        overlay {
            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    DuatImage(name: DuatArt.cornerGold, width: size, height: size, fit: .fit)
                        .rotationEffect(.degrees(Double(index) * 90))
                        .frame(maxWidth: .infinity, maxHeight: .infinity,
                               alignment: DuatCornerAlignment.all[index])
                }
            }
            .padding(inset)
            .opacity(opacity)
            .allowsHitTesting(false)
        }
    }
}

/// Corner ornament placement, clockwise from the top-left.
enum DuatCornerAlignment {
    static let all: [Alignment] = [.topLeading, .topTrailing, .bottomTrailing, .bottomLeading]
}

// MARK: - Buttons

/// A painted button plate that carries its own pressed and disabled states.
struct PaintedButtonLabel<Content: View>: View {
    var tone: DuatArt.ButtonTone = .primary
    var state: DuatArt.ButtonState = .normal
    var width: CGFloat?
    var height: CGFloat = 44
    var cornerRadius: CGFloat = 12
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .background {
                DuatImage(name: DuatArt.button(tone, state), fit: .stretch)
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
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A painted button: the plate swaps to its pressed drawing while held.
struct PaintedButtonStyle: ButtonStyle {
    var tone: DuatArt.ButtonTone = .primary
    var isEnabled: Bool = true
    var isSelected: Bool = false
    var height: CGFloat = 44
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        let state: DuatArt.ButtonState = !isEnabled
            ? .disabled
            : (configuration.isPressed ? .pressed : (isSelected ? .selected : .normal))
        return configuration.label
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background {
                DuatImage(name: DuatArt.button(tone, state), fit: .stretch)
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
enum DuatBarKind {
    case health
    case shield
    case armour

    var fillArt: String {
        switch self {
        case .health: DuatArt.barFillHealth
        case .shield: DuatArt.barFillShield
        case .armour: DuatArt.barFillArmour
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
/// The frame is drawn whole and the fill is inset to the exact trough
/// measured off the artwork — that way the fill is never hidden under the
/// bronze rim, which is what made an enemy's health impossible to read.
struct DuatBar: View {
    let kind: DuatBarKind
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
        max(height, width / DuatArt.BarFrame.aspect)
    }

    private var troughWidth: CGFloat { width * DuatArt.BarFrame.troughWidth }
    private var troughHeight: CGFloat { frameHeight * DuatArt.BarFrame.troughHeight }
    /// How far the channel's centre sits from the bar's centre.
    private var troughOffset: CGFloat {
        (DuatArt.BarFrame.troughX + DuatArt.BarFrame.troughWidth / 2 - 0.5) * width
    }

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.black.opacity(0.9))
                .frame(width: troughWidth, height: troughHeight)
                .offset(x: troughOffset)

            fill

            Image(DuatArt.barFrame)
                .resizable()
                .frame(width: width, height: frameHeight)
                .allowsHitTesting(false)
        }
        .frame(width: width, height: frameHeight)
    }

    /// The colour that runs in the channel. A painted fill plate is washed
    /// over it where the pack has one, so the bar still reads as ink.
    private var fill: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: troughHeight / 2)
                .fill(
                    LinearGradient(colors: [kind.baseTint.opacity(0.95), kind.baseTint],
                                   startPoint: .top, endPoint: .bottom)
                )
                .overlay {
                    DuatImage(name: kind.fillArt, width: troughWidth, height: troughHeight, fit: .stretch)
                        .opacity(0.55)
                        .blendMode(.overlay)
                }
                .frame(width: max(troughWidth * clamped, clamped > 0 ? 3 : 0), height: troughHeight)
                .shadow(color: kind.baseTint.opacity(0.7), radius: 4)
        }
        .frame(width: troughWidth, height: troughHeight, alignment: .leading)
        .offset(x: troughOffset)
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
    func dieFrame(_ frame: DuatArt.DieFrame, tint: Color? = nil, opacity: Double = 1) -> some View {
        overlay {
            DuatImage(name: frame.rawValue, fit: .stretch)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(TintWash(tint: tint))
                .opacity(opacity)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Stamina

/// One painted stamina pip. Points earned above the cap wear the reserve mark.
struct DuatStaminaPip: View {
    let isFilled: Bool
    let isReserve: Bool
    var size: CGFloat = 13

    private var art: String {
        if isReserve { return DuatArt.staminaReserve }
        return isFilled ? DuatArt.staminaFull : DuatArt.staminaEmpty
    }

    var body: some View {
        DuatImage(name: art, height: size, fit: .fit)
            .opacity(isFilled ? 1 : 0.5)
            .shadow(color: isFilled ? (isReserve ? Theme.sunGold : Theme.gold).opacity(0.6) : .clear,
                    radius: isFilled ? 4 : 0)
    }
}
