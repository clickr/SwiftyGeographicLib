//
//  Rhumb.swift
//  SwiftyGeographicLib
//
//  Port of GeographicLib::Rhumb by Charles Karney.
//  Solves the direct and inverse rhumb (loxodrome) problems on an
//  ellipsoid of revolution using order-6 series expansions.
//

import Foundation
import Math

/// Solve the direct and inverse rhumb (loxodrome) problems on an ellipsoid.
///
/// A rhumb line (loxodrome) is a path of constant azimuth on the ellipsoid.
/// Given a starting point, azimuth, and distance the **direct** problem finds
/// the destination; given two points the **inverse** problem finds the azimuth
/// and distance.
///
/// This implementation uses order-6 series expansions in the third flattening
/// and is accurate to ~10 nm for WGS84 (|f| < 0.01).
///
/// ## Usage
///
/// ```swift
/// let rhumb = Rhumb.wgs84
///
/// // Inverse: JFK → LHR
/// let inv = rhumb.inverse(latitude1: 40.6, longitude1: -73.8,
///                         latitude2: 51.6, longitude2: -0.5)
/// print(inv.distance, inv.azimuth)
///
/// // Direct: start at JFK heading 50° for 5 500 km
/// let dir = rhumb.direct(latitude: 40.6, longitude: -73.8,
///                        azimuth: 50, distance: 5_500_000)
/// print(dir.latitude, dir.longitude)
/// ```
public struct Rhumb: Sendable {
    /// Equatorial radius of the ellipsoid in metres.
    public let equatorialRadius: Double
    /// Flattening of the ellipsoid.
    public let flattening: Double

    // Internal state
    let aux: DAuxLatitude       // wraps AuxLatitude
    let _n: Double              // third flattening
    let _rm: Double             // rectifying radius
    let _c2: Double             // authalic-radius² × degree
    let _areaCoeffs: [Double]   // Fourier coefficients for rhumb area

    // Auxiliary-latitude type aliases (match C++ enum values)
    private static let PHI  = AuxType.phi.rawValue
    private static let BETA = AuxType.beta.rawValue
    private static let MU   = AuxType.mu.rawValue
    private static let CHI  = AuxType.chi.rawValue

    /// Create a rhumb solver for an ellipsoid with the given parameters.
    ///
    /// - Parameters:
    ///   - equatorialRadius: equatorial radius in metres.
    ///   - flattening: flattening of the ellipsoid.
    public init(equatorialRadius a: Double, flattening f: Double) {
        equatorialRadius = a
        flattening = f
        aux = DAuxLatitude(a: a, f: f)
        _n = f / (2 - f)

        _rm = aux.aux.rectifyingRadius()
        _c2 = aux.aux.authalicRadiusSquared() * Math.degree

        // Compute area Fourier coefficients (Q-matrix, order 6)
        let Lmax = AuxCoeffs.Lmax
        var aCoeffs = [Double](repeating: 0, count: Lmax)
        var d = _n
        var o = 0
        for l in 0 ..< Lmax {
            let m = Lmax - l - 1
            let slice = Array(AuxCoeffs.areaCoeffs[o ..< (o + m + 1)])
            aCoeffs[l] = d * polyEval(withCoefficients: slice, at: _n)
            o += m + 1
            d *= _n
        }
        _areaCoeffs = aCoeffs
    }

    // MARK: - Direct problem

    /// Solve the direct rhumb problem.
    ///
    /// Given a starting point, azimuth, and distance, find the destination
    /// and the signed area under the rhumb line.
    ///
    /// - Parameters:
    ///   - latitude: starting latitude in degrees.
    ///   - longitude: starting longitude in degrees.
    ///   - azimuth: constant bearing in degrees clockwise from north.
    ///   - distance: distance along the rhumb line in metres.
    /// - Returns: the destination and area.
    public func direct(latitude: Double, longitude: Double,
                       azimuth: Double, distance: Double) -> RhumbDirectResult {
        let ln = line(latitude: latitude, longitude: longitude, azimuth: azimuth)
        let pos = ln.position(distance: distance)
        return RhumbDirectResult(latitude: pos.latitude,
                                 longitude: pos.longitude,
                                 area: pos.area)
    }

    /// Solve the inverse rhumb problem.
    ///
    /// Given two points, find the constant-bearing azimuth, the rhumb
    /// distance, and the signed area under the rhumb line.
    ///
    /// - Parameters:
    ///   - latitude1, longitude1: first point in degrees.
    ///   - latitude2, longitude2: second point in degrees.
    /// - Returns: the azimuth, distance, and area.
    public func inverse(latitude1: Double, longitude1: Double,
                        latitude2: Double, longitude2: Double) -> RhumbInverseResult {
        let phi1 = AuxAngle.degrees(latitude1)
        let phi2 = AuxAngle.degrees(latitude2)
        let chi1 = aux.aux.convert(Self.PHI, Self.CHI, phi1)
        let chi2 = aux.aux.convert(Self.PHI, Self.CHI, phi2)

        let lon12 = angDiffWithError(longitude1, longitude2).d
        let lam12 = lon12 * Math.degree
        let psi1 = chi1.lam()
        let psi2 = chi2.lam()
        let psi12 = psi2 - psi1

        // Azimuth
        let azi12 = atan2d(lam12, psi12)

        // Distance
        let s12: Double
        if psi1.isInfinite || psi2.isInfinite {
            s12 = Swift.abs(
                aux.aux.convert(Self.PHI, Self.MU, phi2).radians()
                - aux.aux.convert(Self.PHI, Self.MU, phi1).radians()
            ) * _rm
        } else {
            let h = hypot(lam12, psi12)
            let dmudpsi =
                aux.dConvert(Self.CHI, Self.MU, chi1, chi2)
                / DAuxLatitude.dlam(chi1.tan, chi2.tan)
            s12 = h * dmudpsi * _rm
        }

        // Area
        let S12 = _c2 * lon12 * meanSinXi(chi1, chi2)

        return RhumbInverseResult(distance: s12, azimuth: azi12, area: S12)
    }

    // MARK: - Line factory

    /// Create a ``RhumbLine`` from a starting point and azimuth.
    ///
    /// The line can then be used to compute multiple positions along the
    /// same rhumb line efficiently.
    public func line(latitude: Double, longitude: Double,
                     azimuth: Double) -> RhumbLine {
        RhumbLine(rhumb: self, latitude: latitude,
                  longitude: longitude, azimuth: azimuth)
    }

    // MARK: - Inspectors

    /// The total area of the ellipsoid (m²).
    public var ellipsoidArea: Double { 2 * 360 * _c2 }

    // MARK: - Internal: MeanSinXi for area computation

    /// Compute the mean value of sin(xi) between two conformal latitudes,
    /// needed for the area under a rhumb line.
    func meanSinXi(_ chix: AuxAngle, _ chiy: AuxAngle) -> Double {
        let phix = aux.aux.convert(Self.CHI, Self.PHI, chix)
        let phiy = aux.aux.convert(Self.CHI, Self.PHI, chiy)
        let betax = aux.aux.parametric(phix).normalized()
        let betay = aux.aux.parametric(phiy).normalized()

        let dpbetaDbeta = DAuxLatitude.dClenshaw(
            sinSeries: false,
            delta: betay.radians() - betax.radians(),
            szeta1: betax.y, czeta1: betax.x,
            szeta2: betay.y, czeta2: betay.x,
            c: _areaCoeffs)

        let tx = chix.tan, ty = chiy.tan
        let dbetaDpsi =
            aux.dConvert(Self.CHI, Self.BETA, chix, chiy)
            / DAuxLatitude.dlam(tx, ty)

        return DAuxLatitude.dp0Dpsi(tx, ty) + dpbetaDbeta * dbetaDpsi
    }

    // MARK: - WGS84 static instance

    /// A pre-configured rhumb solver for the WGS84 ellipsoid.
    public static let wgs84 = Rhumb(equatorialRadius: 6_378_137,
                                     flattening: 1 / 298.257223563)
}
