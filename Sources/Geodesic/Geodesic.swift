//
//  Geodesic.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import Foundation
import Math

/// A geodesic calculator for a given ellipsoid.
///
/// Solves the direct and inverse geodesic problems on an ellipsoid using
/// Charles Karney's series method at order 6, giving accuracy of about 15 nm
/// for WGS84. `GeodesicExact` (elliptic integral variant) is out of scope.
///
/// The standard entry point is `Geodesic.wgs84` which uses the WGS84 ellipsoid.
///
/// ## Direct problem
/// Given a starting point (lat₁, lon₁), azimuth azi₁, and distance s₁₂,
/// find the destination and arrival azimuth.
///
/// ## Inverse problem
/// Given two points, find the distance and both azimuths.
///
/// ## GeodesicLine
/// For routes where many equidistant points are needed along the same geodesic,
/// create a `GeodesicLine` via `Geodesic.line(...)` and call
/// `GeodesicLine.position(distance:)` repeatedly.
///
/// - SeeAlso: ``GeodesicLine``
public struct Geodesic: Sendable {

    // MARK: - Order of series approximation
    static let nA1: Int = 6   // order of A1 series
    static let nA2: Int = 6   // order of A2 series
    static let nA3: Int = 6   // order of A3 series
    static let nC1: Int = 6   // number of C1 coefficients
    static let nC1p: Int = 6  // number of C1p coefficients
    static let nC2: Int = 6   // number of C2 coefficients
    static let nC3: Int = 6   // number of C3 coefficients
    static let nC4: Int = 6   // number of C4 coefficients

    // Derived array sizes
    static let nA3x: Int = nA3                   // 6
    static let nC3x: Int = (nC3 * (nC3 - 1)) / 2 // 15
    static let nC4x: Int = (nC4 * (nC4 + 1)) / 2 // 21

    // Iteration limits
    static let maxit1: Int = 20
    let maxit2: Int

    // MARK: - Tolerance values
    let tiny: Double
    let tol0: Double
    let tol1: Double
    let tol2: Double
    let tolb: Double
    let xthresh: Double

    // MARK: - Ellipsoid parameters

    /// Equatorial radius in metres.
    public let a: Double
    /// Flattening of the ellipsoid. Negative for prolate.
    public let f: Double

    let f1: Double    // 1 - f
    let e2: Double    // f*(2-f), square of first eccentricity
    let ep2: Double   // e2 / (1-e2), square of second eccentricity
    let n: Double     // f/(2-f), third flattening
    let b: Double     // a*f1, polar semi-axis
    let c2: Double    // authalic radius²
    let etol2: Double // "really short" threshold on auxiliary sphere

    // MARK: - Coefficient arrays (pre-computed in init)

    /// Coefficients for A3 series (size nA3x = 6).
    var aA3x: [Double]
    /// Coefficients for C3 series (size nC3x = 15).
    var cC3x: [Double]
    /// Coefficients for C4 series (size nC4x = 21).
    var cC4x: [Double]

    // MARK: - Standard instances

    /// The WGS84 ellipsoid (a = 6378137 m, f = 1/298.257223563).
    public static let wgs84 = Geodesic(
        equatorialRadius: 6_378_137.0,
        flattening: 1.0 / 298.257223563)

    // MARK: - Initialiser

    /// Creates a geodesic calculator for the given ellipsoid.
    ///
    /// - Parameters:
    ///   - equatorialRadius: Equatorial radius in metres (must be positive).
    ///   - flattening: Flattening of the ellipsoid (0 for sphere, negative for prolate).
    public init(equatorialRadius a: Double, flattening f: Double) {
        let tol0 = Double.ulpOfOne
        let tol2 = sqrt(tol0)

        self.a = a
        self.f = f
        self.f1 = 1 - f
        self.e2 = f * (2 - f)
        self.ep2 = e2 / (f1 * f1)
        self.n = f / (2 - f)
        self.b = a * f1
        // authalic radius²: (a² + b²·atanh(e)/e) / 2  for oblate (e2>0)
        let aA = a * a
        let bB = b * b
        let eatanheVal: Double
        if e2 == 0 {
            eatanheVal = 1.0
        } else {
            let esign: Double = f < 0 ? -1 : 1
            let sqrtAbsE2 = sqrt(abs(e2))
            eatanheVal = eatanhe(1.0, esign * sqrtAbsE2) / e2
        }
        self.c2 = (aA + bB * eatanheVal) / 2

        self.tiny = sqrt(Double.leastNormalMagnitude)
        self.tol0 = tol0
        // Increase multiplier from 100 to 200 to fix a specific inverse case
        self.tol1 = 200 * tol0
        self.tol2 = tol2
        self.tolb = tol0  // check on bisection interval
        self.xthresh = 1000 * tol2
        self.maxit2 = Geodesic.maxit1 + Int(Double.significandBitCount) + 10

        // "really short" geodesic threshold
        let fabs_f = abs(f)
        self.etol2 = 0.1 * tol2 / sqrt(max(0.001, fabs_f) * min(1.0, 1 - f / 2) / 2)

        // Initialise coefficient arrays (will be filled below)
        self.aA3x = [Double](repeating: 0, count: Geodesic.nA3x)
        self.cC3x = [Double](repeating: 0, count: Geodesic.nC3x)
        self.cC4x = [Double](repeating: 0, count: Geodesic.nC4x)

        // Compute coefficients
        self.aA3x = Geodesic.computeA3coeff(n: n)
        self.cC3x = Geodesic.computeC3coeff(n: n)
        self.cC4x = Geodesic.computeC4coeff(n: n)
    }

    // MARK: - A3f / C3f / C4f helpers used during inverse computation

    /// Evaluates A3 for given `eps`.
    func a3f(_ eps: Double) -> Double {
        return polyEval(withCoefficients: aA3x, at: eps)
    }

    /// Fills `c[1...nC3-1]` with C3 coefficients for given `eps`.
    func c3f(_ eps: Double) -> [Double] {
        var c = [Double](repeating: 0, count: Geodesic.nC3)
        var mult = 1.0
        var o = 0
        for l in 1..<Geodesic.nC3 {
            let m = Geodesic.nC3 - l - 1  // order of polynomial in eps
            mult *= eps
            let slice = Array(cC3x[o..<(o + m + 1)])
            c[l] = mult * polyEval(withCoefficients: slice, at: eps)
            o += m + 1
        }
        return c
    }

    /// Fills `c[0...nC4-1]` with C4 coefficients for given `eps`.
    func c4f(_ eps: Double) -> [Double] {
        var c = [Double](repeating: 0, count: Geodesic.nC4)
        var mult = 1.0
        var o = 0
        for l in 0..<Geodesic.nC4 {
            let m = Geodesic.nC4 - l - 1  // order of polynomial in eps
            let slice = Array(cC4x[o..<(o + m + 1)])
            c[l] = mult * polyEval(withCoefficients: slice, at: eps)
            o += m + 1
            mult *= eps
        }
        return c
    }
}
