import SwiftUI

/// How a face behaves once it has left the fighter's hand. Only faces that are
/// genuinely thrown or cast own one of these — an axe swing never leaves the
/// deck, so it has no flight.
struct ProjectileStyle: Equatable {
    /// Drawn size of the shot, in points.
    var size: CGFloat = 38
    /// Degrees the drawing already points, measured from "flying right". The
    /// arrow plates are painted pointing up and to the right, so they are
    /// turned back 45° before the shot's heading is applied.
    var baseAngle: Double = 0
    /// How high the shot lobs over the water. 0 flies flat.
    var arc: CGFloat = 0
    /// Seconds the shot spends in the air.
    var flight: Double = 0.28
    /// Whether it tumbles end over end on the way across.
    var spins: Bool = false
    /// What it leaves behind it.
    var trail: ProjectileTrail = .streak
}

/// The wake a shot drags across the water.
enum ProjectileTrail: Equatable {
    case streak
    case flame
    case frost
    case arcane
    case smoke
}

extension FaceKind {
    /// The flight this face takes when it is thrown or cast at a foe, or nil
    /// for the faces that are swung where the fighter stands.
    var projectile: ProjectileStyle? {
        switch self {
        case .arrow1:
            return ProjectileStyle(size: 34, baseAngle: -45, flight: 0.26)
        case .arrow2:
            return ProjectileStyle(size: 38, baseAngle: -45, flight: 0.24)
        case .arrow3:
            return ProjectileStyle(size: 46, baseAngle: -45, flight: 0.22)
        case .daggerThrow:
            return ProjectileStyle(size: 36, arc: 14, flight: 0.3, spins: true)
        case .runeFire:
            return ProjectileStyle(size: 40, arc: 26, flight: 0.34, trail: .flame)
        case .runeFrost:
            return ProjectileStyle(size: 34, flight: 0.3, spins: true, trail: .frost)
        case .runeArcane:
            return ProjectileStyle(size: 38, arc: 16, flight: 0.32, spins: true, trail: .arcane)
        case .wandZap:
            return ProjectileStyle(size: 34, flight: 0.2, trail: .arcane)
        case .bomb:
            return ProjectileStyle(size: 42, arc: 74, flight: 0.44, spins: true, trail: .smoke)
        case .poison:
            return ProjectileStyle(size: 32, arc: 48, flight: 0.36, spins: true, trail: .smoke)
        default:
            return nil
        }
    }
}

/// One shot in the air right now: what it is, who threw it and which foe it
/// flies to or from. Purely presentational — the damage is resolved by the
/// engine, which waits out the flight so the numbers land with the shot.
struct ProjectileShot: Identifiable, Equatable {
    let id = UUID()
    let face: FaceKind
    let style: ProjectileStyle
    let tint: Color
    /// True when the demigod threw it; false when it came out of the river.
    let fromPlayer: Bool
    /// The foe at the far end (player shots) or the one that threw it.
    let foeID: UUID
}
