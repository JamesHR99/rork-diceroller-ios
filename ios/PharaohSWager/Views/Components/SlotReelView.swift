import SwiftUI
import UIKit
import QuartzCore

/// Static, decoded symbols travel on one Core Animation layer. No SwiftUI
/// timeline, image lookup, or layout work runs on each display frame.
struct SlotReelView: UIViewRepresentable {
    let faces: [FaceKind]
    let landing: FaceKind
    let rollID: UUID
    let startedAt: TimeInterval
    let duration: TimeInterval
    let symbolSize: CGFloat
    var reduceMotion = false

    func makeUIView(context: Context) -> SlotReelSurface { SlotReelSurface() }

    func updateUIView(_ view: SlotReelSurface, context: Context) {
        view.configure(faces: faces, landing: landing, rollID: rollID,
                       startedAt: startedAt, duration: duration,
                       symbolSize: symbolSize, reduceMotion: reduceMotion)
    }

    static func dismantleUIView(_ view: SlotReelSurface, coordinator: ()) {
        view.stop()
    }
}

final class SlotReelSurface: UIView {
    private let drum = CALayer()
    private var presentationID: UUID?
    private var configuredSize: CGFloat = 0
    private var configuredReduceMotion = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        clipsToBounds = true
        layer.addSublayer(drum)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(faces: [FaceKind], landing: FaceKind, rollID: UUID,
                   startedAt: TimeInterval, duration: TimeInterval,
                   symbolSize: CGFloat, reduceMotion: Bool) {
        guard presentationID != rollID || configuredSize != symbolSize
                || configuredReduceMotion != reduceMotion else { return }
        presentationID = rollID
        configuredSize = symbolSize
        configuredReduceMotion = reduceMotion
        stop()

        let symbols = faces.isEmpty ? [landing] : faces
        let rowHeight = symbolSize * 1.18
        let rows = reduceMotion ? 0 : max(10, Int(duration * 19))
        let distance = CGFloat(rows) * rowHeight

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        drum.sublayers?.forEach { $0.removeFromSuperlayer() }
        drum.bounds = CGRect(x: 0, y: 0, width: symbolSize, height: CGFloat(rows + 2) * rowHeight)
        drum.anchorPoint = .zero
        drum.position = .zero
        // Include a row beyond either end so braking never exposes empty glass.
        for row in -1...(rows + 1) {
            let kind = row == rows ? landing : symbols[(row % symbols.count + symbols.count) % symbols.count]
            let glyph = CALayer()
            let image = ReelSymbolCache.image(for: kind)
            glyph.contents = image.cgImage
            glyph.contentsScale = image.scale
            glyph.contentsGravity = .resizeAspect
            glyph.frame = CGRect(x: 0, y: CGFloat(row) * rowHeight,
                                 width: symbolSize, height: symbolSize)
            drum.addSublayer(glyph)
        }
        drum.transform = CATransform3DMakeTranslation(0, -distance, 0)
        CATransaction.commit()

        guard !reduceMotion else { return }
        let elapsed = max(0, ProcessInfo.processInfo.systemUptime - startedAt)
        guard elapsed < duration else { return }
        let motion = CAKeyframeAnimation(keyPath: "transform.translation.y")
        motion.values = [0, -distance * 0.76, -distance * 0.98,
                         -distance - rowHeight * 0.07, -distance]
        motion.keyTimes = [0, 0.68, 0.86, 0.92, 1]
        motion.timingFunctions = [
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(controlPoints: 0.15, 0.55, 0.35, 1),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        motion.duration = duration
        motion.beginTime = drum.convertTime(CACurrentMediaTime(), from: nil) - elapsed
        drum.add(motion, forKey: "roll")
    }

    func stop() { drum.removeAllAnimations() }
}

/// Rasterize the small glyph once, including its fallback, before the roll.
/// The cache is bounded and shared by reels with identical faces.
@MainActor
enum ReelSymbolCache {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 96
        cache.totalCostLimit = 8 * 1024 * 1024
        return cache
    }()

    static func image(for kind: FaceKind) -> UIImage {
        let key = kind.rawValue as NSString
        if let image = cache.object(forKey: key) { return image }
        let renderer = ImageRenderer(content:
            PharaohSWagerSymbol(art: kind.artName, fallback: kind.symbol,
                               size: 64, tint: kind.tint))
        renderer.scale = 3
        let image = renderer.uiImage ?? UIImage()
        cache.setObject(image, forKey: key, cost: 192 * 192 * 4)
        return image
    }

    static func prepare(_ dice: [Die]) {
        for kind in Set(dice.flatMap { $0.faces.map(\.kind) }) {
            _ = image(for: kind)
        }
    }
}
