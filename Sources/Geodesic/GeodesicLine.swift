//
//  GeodesicLine.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import Foundation
import Math

/// A geodesic line — a precomputed geodesic starting at a fixed point with
/// a fixed azimuth, suitable for computing many equidistant points along
/// the same great-ellipse path.
///
/// Create via `Geodesic.line(...)`, `Geodesic.directLine(...)`, or
/// `Geodesic.inverseLine(...)`.  Then call `position(distance:)` or
/// `arcPosition(arcLength:)` to find points along it.
///
/// Corresponds to `GeographicLib::GeodesicLine` in the C++ API (non-exact variant).
public struct GeodesicLine: Sendable {

    // Ellipsoid-derived constants (copied from parent Geodesic)
    let tiny: Double
    let a: Double
    let f: Double
    let b: Double
    let c2: Double
    let f1: Double
    let ep2: Double  // second eccentricity squared

    // Starting-point quantities
    let lat1: Double
    let lon1: Double
    let azi1: Double

    // sin/cos of the initial azimuth
    let salp1: Double
    let calp1: Double

    // sin/cos of beta1 (reduced latitude)
    let ssig1: Double
    let csig1: Double
    let somg1: Double
    let comg1: Double

    // Cross-track sin/cos of equatorial-crossing azimuth
    let salp0: Double
    let calp0: Double

    let dn1: Double

    // Precomputed coefficients
    let k2: Double
    let eps: Double

    // A1m1, B11, stau1, ctau1 for distance-mode position
    let aA1m1: Double
    let bB11: Double
    let stau1: Double
    let ctau1: Double

    // A2m1, B21 for reduced-length computation
    let aA2m1: Double
    let bB21: Double

    // A3c, B31 for longitude
    let aA3c: Double
    let bB31: Double

    // A4, B41 for geodesic area
    let aA4: Double
    let bB41: Double

    // Coefficient arrays for the line
    let cC1a: [Double]   // C1 evaluated at eps (size nC1+1, index 0 unused)
    let cC1pa: [Double]  // C1p evaluated at eps
    let cC2a: [Double]   // C2 evaluated at eps
    let cC3a: [Double]   // C3 evaluated at eps (size nC3, index 0 unused)
    let cC4a: [Double]   // C4 evaluated at eps (size nC4)

    // MARK: - Initialiser

    /// Creates a GeodesicLine from a parent Geodesic, starting point, and azimuth.
    ///
    /// Corresponds to `GeodesicLine::LineInit` in the C++ API.
    init(geodesic g: Geodesic, lat1: Double, lon1: Double, azi1 aziIn: Double,
         salp1 salp1In: Double? = nil, calp1 calp1In: Double? = nil) {

        let azi = angNormalize(aziIn)
        let (salp, calp): (Double, Double)
        if let s = salp1In, let c = calp1In {
            (salp, calp) = (s, c)
        } else {
            (salp, calp) = sincosd(degrees: angRound(azi))
        }

        self.tiny = g.tiny
        self.a = g.equatorialRadius
        self.f = g.flattening
        self.b = g.b
        self.c2 = g.c2
        self.f1 = g.f1
        self.ep2 = g.ep2
        self.lat1 = latFix(lat1)
        self.lon1 = lon1
        self.azi1 = azi
        self.salp1 = salp
        self.calp1 = calp

        // Compute reduced latitude beta1
        let (sbet1raw, cbet1raw) = sincosd(degrees: angRound(self.lat1))
        let sbet1 = f1 * sbet1raw
        var cbet1 = cbet1raw
        let normBet = Math.norm(x: sbet1, y: cbet1)
        let sbet1n = normBet.x
        cbet1 = max(g.tiny, normBet.y)

        self.dn1 = sqrt(1 + g.ep2 * sq(sbet1n))

        // alp0: equatorial-crossing azimuth
        let salp0 = salp * cbet1
        let calp0 = hypot(calp, salp * sbet1n)
        self.salp0 = salp0
        self.calp0 = calp0

        // sig1, omg1
        let ssig1 = sbet1n
        let somg1 = salp0 * sbet1n
        let csig1comg1 = (sbet1n != 0 || calp != 0) ? cbet1 * calp : 1.0
        let normSig = Math.norm(x: ssig1, y: csig1comg1)
        self.ssig1 = normSig.x
        self.csig1 = normSig.y
        self.somg1 = somg1
        self.comg1 = csig1comg1   // not normalised (see C++ comment)

        // k2 and eps
        let k2 = sq(calp0) * g.ep2
        self.k2 = k2
        let eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
        self.eps = eps

        // C1 series
        let cC1a = Geodesic.c1f(eps)
        self.cC1a = cC1a

        // aA1m1 and B11
        let aA1m1 = Geodesic.a1m1f(eps)
        self.aA1m1 = aA1m1
        let bB11 = Geodesic.sinCosSeries(sinSeries: true, sinx: self.ssig1, cosx: self.csig1,
                                          c: cC1a, n: Geodesic.nC1)
        self.bB11 = bB11
        let sB11 = sin(bB11), cB11 = cos(bB11)
        self.stau1 = self.ssig1 * cB11 + self.csig1 * sB11
        self.ctau1 = self.csig1 * cB11 - self.ssig1 * sB11

        // C1p series
        self.cC1pa = Geodesic.c1pf(eps)

        // C2 series and aA2m1, B21
        let cC2a = Geodesic.c2f(eps)
        self.cC2a = cC2a
        self.aA2m1 = Geodesic.a2m1f(eps)
        self.bB21 = Geodesic.sinCosSeries(sinSeries: true, sinx: self.ssig1, cosx: self.csig1,
                                           c: cC2a, n: Geodesic.nC2)

        // C3 series, aA3c, B31
        let cC3a = g.c3f(eps)
        self.cC3a = cC3a
        self.aA3c = -g.flattening * salp0 * g.a3f(eps)
        self.bB31 = Geodesic.sinCosSeries(sinSeries: true, sinx: self.ssig1, cosx: self.csig1,
                                           c: cC3a, n: Geodesic.nC3 - 1)

        // C4 series, aA4, B41
        let cC4a = g.c4f(eps)
        self.cC4a = cC4a
        self.aA4 = sq(a) * calp0 * salp0 * g.e2
        self.bB41 = Geodesic.sinCosSeries(sinSeries: false, sinx: self.ssig1, cosx: self.csig1,
                                           c: cC4a, n: Geodesic.nC4)
    }
}
