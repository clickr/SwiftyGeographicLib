//
//  Geocentric.swift
//  SwiftGeoLib
//
//  Pure Swift port of GeographicLib::Geocentric
//

import Foundation
import Math

/// Geodetic to geocentric coordinate conversion.
///
/// Converts between geodetic coordinates (latitude, longitude, height above
/// the ellipsoid) and geocentric Cartesian coordinates (X, Y, Z).
/// Also computes the 3×3 rotation matrix that transforms vectors
/// between the local (east, north, up) and geocentric frames.
struct Geocentric: Sendable {
    let a: Double    // equatorial radius (meters)
    let f: Double    // flattening
    let e2: Double   // eccentricity squared: f*(2-f)
    let e2m: Double  // 1 - e2 = (1-f)^2

    /// WGS84 ellipsoid.
    static let wgs84 = Geocentric(a: 6378137.0, f: 1.0 / 298.257223563)

    init(a: Double, f: Double) {
        self.a = a
        self.f = f
        self.e2 = f * (2 - f)
        self.e2m = (1 - f) * (1 - f)
    }

    /// Convert geodetic to geocentric coordinates with rotation matrix.
    ///
    /// The rotation matrix M is stored as a flat 9-element array in the
    /// same layout as GeographicLib: M[0]…M[8] where
    ///
    /// ```
    /// Rotate (local → geocentric):
    ///   X = M[0]*east + M[1]*north + M[2]*up
    ///   Y = M[3]*east + M[4]*north + M[5]*up
    ///   Z = M[6]*east + M[7]*north + M[8]*up
    ///
    /// Unrotate (geocentric → local) = M^T:
    ///   east  = M[0]*X + M[3]*Y + M[6]*Z
    ///   north = M[1]*X + M[4]*Y + M[7]*Z
    ///   up    = M[2]*X + M[5]*Y + M[8]*Z
    /// ```
    ///
    /// - Parameters:
    ///   - lat: Latitude in degrees.
    ///   - lon: Longitude in degrees.
    ///   - h: Height above the ellipsoid in meters.
    /// - Returns: Geocentric (X, Y, Z) in meters and rotation matrix M.
    func intForward(lat: Double, lon: Double, h: Double)
        -> (X: Double, Y: Double, Z: Double, M: [Double])
    {
        let phiSC = sincosd(degrees: latFix(lat))
        let sphi = phiSC.sin
        let cphi = phiSC.cos
        let lamSC = sincosd(degrees: lon)
        let slam = lamSC.sin
        let clam = lamSC.cos

        let n = a / sqrt(1 - e2 * sphi * sphi)
        let Z = (e2m * n + h) * sphi
        var X = (n + h) * cphi
        let Y = X * slam
        X *= clam

        let M = Self.rotation(sphi: sphi, cphi: cphi, slam: slam, clam: clam)
        return (X, Y, Z, M)
    }

    /// Build the 3×3 rotation matrix (local → geocentric).
    ///
    /// Stored as a flat array matching the GeographicLib C++ layout:
    /// - M[0], M[1], M[2] = first row  (geocentric X from east, north, up)
    /// - M[3], M[4], M[5] = second row (geocentric Y from east, north, up)
    /// - M[6], M[7], M[8] = third row  (geocentric Z from east, north, up)
    static func rotation(sphi: Double, cphi: Double,
                          slam: Double, clam: Double) -> [Double]
    {
        // Row-major: each row gives the geocentric component from local basis.
        //
        // C++ stores:
        //   M[0] = -slam;        M[3] =  clam;        M[6] = 0;
        //   M[1] = -clam*sphi;   M[4] = -slam*sphi;   M[7] = cphi;
        //   M[2] =  clam*cphi;   M[5] =  slam*cphi;   M[8] = sphi;
        //
        // But C++ Rotate() uses M[0]*x + M[1]*y + M[2]*z for X,
        // meaning row 0 = [M[0], M[1], M[2]].
        //
        // Row 0 = [-slam, -clam*sphi, clam*cphi]  → geocentric X
        // Row 1 = [ clam, -slam*sphi, slam*cphi]  → geocentric Y
        // Row 2 = [    0,       cphi,      sphi]  → geocentric Z
        return [
            -slam,        -clam * sphi,  clam * cphi,
             clam,        -slam * sphi,  slam * cphi,
             0,            cphi,          sphi
        ]
    }

    /// Transform a vector from geocentric to local (east, north, up) basis.
    ///
    /// Computes `(x, y, z) = M^T * (X, Y, Z)`.
    @inline(__always)
    static func unrotate(M: [Double],
                          X: Double, Y: Double, Z: Double)
        -> (x: Double, y: Double, z: Double)
    {
        let x = M[0] * X + M[3] * Y + M[6] * Z
        let y = M[1] * X + M[4] * Y + M[7] * Z
        let z = M[2] * X + M[5] * Y + M[8] * Z
        return (x, y, z)
    }
}
