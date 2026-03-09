//
//  RhumbLine.swift
//  SwiftyGeographicLib
//
//  Port of GeographicLib::RhumbLine by Charles Karney.
//  A precomputed rhumb line allowing efficient computation of
//  positions at arbitrary distances from the starting point.
//

import Foundation
import Math

/// A rhumb line (loxodrome) defined by a starting point and azimuth.
///
/// Created via ``Rhumb/line(latitude:longitude:azimuth:)`` and reused to
/// compute positions at multiple distances along the same rhumb line.
///
/// ```swift
/// let line = Rhumb.wgs84.line(latitude: 40.6, longitude: -73.8, azimuth: 50)
/// for d in stride(from: 0, through: 5_000_000, by: 500_000) {
///     let pos = line.position(distance: d)
///     print(pos.latitude, pos.longitude)
/// }
/// ```
public struct RhumbLine: Sendable {
    /// Starting latitude in degrees.
    public let latitude: Double
    /// Starting longitude in degrees.
    public let longitude: Double
    /// Constant bearing (azimuth) in degrees clockwise from north.
    public let azimuth: Double

    // Internal state
    let rhumb: Rhumb
    let _salp: Double       // sin(azimuth)
    let _calp: Double       // cos(azimuth)
    let _mu1: Double        // rectifying latitude of start (degrees)
    let _psi1: Double       // isometric latitude of start
    let _phi1: AuxAngle     // geographic latitude as AuxAngle
    let _chi1: AuxAngle     // conformal latitude as AuxAngle

    private static let PHI = AuxType.phi.rawValue
    private static let MU  = AuxType.mu.rawValue
    private static let CHI = AuxType.chi.rawValue

    init(rhumb: Rhumb, latitude: Double, longitude: Double, azimuth: Double) {
        self.rhumb = rhumb
        self.latitude = latFix(latitude)
        self.longitude = longitude
        self.azimuth = angNormalize(azimuth)

        let sc = sincosd(degrees: self.azimuth)
        _salp = sc.sin
        _calp = sc.cos

        _phi1 = AuxAngle.degrees(latitude)
        _mu1 = rhumb.aux.aux.convert(Self.PHI, Self.MU, _phi1).degrees()
        _chi1 = rhumb.aux.aux.convert(Self.PHI, Self.CHI, _phi1)
        _psi1 = _chi1.lam()
    }

    /// Compute a position at a given distance along the rhumb line.
    ///
    /// - Parameter distance: distance from the starting point in metres.
    /// - Returns: the position (latitude, longitude, area).
    public func position(distance s12: Double) -> RhumbPosition {
        // scaled distance in degrees
        let r12 = s12 / (rhumb._rm * Math.degree)
        let mu12 = r12 * _calp
        let mu2 = _mu1 + mu12

        if Swift.abs(mu2) <= qd {
            let mu2a = AuxAngle.degrees(mu2)
            let phi2 = rhumb.aux.aux.convert(Self.MU, Self.PHI, mu2a)
            let chi2 = rhumb.aux.aux.convert(Self.PHI, Self.CHI, phi2)
            let lat2 = phi2.degrees()

            let dmudpsi =
                rhumb.aux.dConvert(Self.CHI, Self.MU, _chi1, chi2)
                / DAuxLatitude.dlam(_chi1.tan, chi2.tan)

            let lon12 = r12 * _salp / dmudpsi

            let S12 = rhumb._c2 * lon12 * rhumb.meanSinXi(_chi1, chi2)

            let lon2 = angNormalize(angNormalize(longitude) + lon12)

            return RhumbPosition(latitude: lat2, longitude: lon2, area: S12)
        } else {
            // Past the pole — latitude wraps, longitude is undefined.
            let mu2n = angNormalize(mu2)
            let mu2c: Double
            if Swift.abs(mu2n) > qd {
                mu2c = angNormalize(hd - mu2n)
            } else {
                mu2c = mu2n
            }
            let lat2 = rhumb.aux.aux.convert(
                Self.MU, Self.PHI, AuxAngle.degrees(mu2c)
            ).degrees()

            return RhumbPosition(latitude: lat2, longitude: .nan, area: .nan)
        }
    }
}
