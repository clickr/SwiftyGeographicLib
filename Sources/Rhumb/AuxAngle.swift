//
//  AuxAngle.swift
//  SwiftyGeographicLib
//
//  Port of GeographicLib::AuxAngle by Charles Karney.
//  An accurate representation of angles stored as (y, x) coordinates
//  (proportional to sin and cos), preserving precision near cardinal points.
//

import Foundation
import Math

/// An angle represented by its (y, x) components — proportional to (sin, cos).
///
/// This avoids precision loss when working with angles near 0°, 90°, or 180°
/// and saves on redundant trigonometric recomputations.
struct AuxAngle: Sendable {
    /// The y component (sin of the angle when normalised).
    var y: Double
    /// The x component (cos of the angle when normalised).
    var x: Double

    /// Creates an `AuxAngle` from (y, x) components.
    ///
    /// With one argument, `AuxAngle(t)` represents an angle whose tangent is `t`.
    /// With no arguments, the angle is 0°.
    init(_ y: Double = 0, _ x: Double = 1) {
        self.y = y
        self.x = x
    }

    /// The tangent of the angle.
    var tan: Double { y / x }

    /// The angle in degrees, computed via `atan2d(y, x)`.
    func degrees() -> Double {
        atan2d(y, x)
    }

    /// The angle in radians, computed via `atan2(y, x)`.
    func radians() -> Double {
        atan2(y, x)
    }

    /// The lambertian (isometric latitude): `asinh(tan(angle))`.
    func lam() -> Double {
        asinh(tan)
    }

    /// Returns a new `AuxAngle` normalised to lie on the unit circle.
    ///
    /// After normalisation, `y` = sin(angle) and `x` = cos(angle).
    func normalized() -> AuxAngle {
        let h = hypot(x, y)
        guard h > 0 else { return self }
        return AuxAngle(y / h, x / h)
    }

    /// Returns a new `AuxAngle` with the same magnitude but in the quadrant of `p`.
    func copyquadrant(from p: AuxAngle) -> AuxAngle {
        AuxAngle(
            copysign(y, p.y),
            copysign(x, p.x)
        )
    }

    /// In-place addition using complex-number multiplication:
    /// `(y, x) = (y*p.x + x*p.y, x*p.x - y*p.y)`.
    mutating func add(_ p: AuxAngle) {
        let newY = y * p.x + x * p.y
        let newX = x * p.x - y * p.y
        y = newY
        x = newX
    }

    // MARK: - Factory methods

    /// Creates an `AuxAngle` from an angle given in degrees.
    static func degrees(_ d: Double) -> AuxAngle {
        let sc = sincosd(degrees: d)
        return AuxAngle(sc.sin, sc.cos)
    }

    /// Creates an `AuxAngle` from an angle given in radians.
    static func radians(_ r: Double) -> AuxAngle {
        AuxAngle(sin(r), cos(r))
    }

    /// A NaN `AuxAngle`.
    static var nan: AuxAngle {
        AuxAngle(.nan, .nan)
    }

    // MARK: - Internal helpers

    /// `hypot(1, tphi)` — convert tan to sec.
    static func sc(_ tphi: Double) -> Double {
        hypot(1, tphi)
    }

    /// `tphi / hypot(1, tphi)` — convert tan to sin.
    static func sn(_ tphi: Double) -> Double {
        tphi.isInfinite ? copysign(1, tphi) : tphi / sc(tphi)
    }
}
