import SwiftUI

/// Horizontal shake used for big hits like Perfect Shot.
struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 9
    var shakesPerUnit: CGFloat = 4
    var animatableData: CGFloat

    nonisolated func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = travelDistance * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
