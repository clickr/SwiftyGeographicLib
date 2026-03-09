//
//  AuxLatitude.swift
//  SwiftyGeographicLib
//
//  Port of GeographicLib::AuxLatitude by Charles Karney.
//  Series-only (order 6) conversions between auxiliary latitudes:
//  geographic (φ), parametric (β), geocentric (θ), rectifying (μ),
//  conformal (χ), and authalic (ξ).
//

import Foundation
import Math

// MARK: - Auxiliary latitude types

/// The six auxiliary latitudes and a count sentinel.
enum AuxType: Int {
    case phi   = 0  // geographic
    case beta  = 1  // parametric
    case theta = 2  // geocentric
    case mu    = 3  // rectifying
    case chi   = 4  // conformal
    case xi    = 5  // authalic
    static let count = 6
}

// MARK: - AuxLatitude

/// Conversions between auxiliary latitudes via order-6 Fourier series in
/// the third flattening n.
///
/// Coefficient arrays are lazily computed on first use for each conversion
/// pair and cached for subsequent calls.
final class AuxLatitude: @unchecked Sendable {
    // Ellipsoid parameters
    let _a: Double      // equatorial radius
    let _b: Double      // polar semiaxis
    let _f: Double      // flattening
    let _fm1: Double    // 1 - f
    let _e2: Double     // eccentricity squared, e² = f(2-f)
    let _e2m1: Double   // 1 - e² = (1-f)²
    let _e12: Double    // e'² = e²/(1-e²)
    let _e12p1: Double  // 1 + e'² = 1/(1-e²)
    let _n: Double      // third flattening, n = f/(2-f)
    let _e: Double      // eccentricity, |e|
    let _e1: Double     // second eccentricity, |e'|
    let _n2: Double     // n²
    let _q: Double      // 1/(1-e²) + atanh(e)/e (or equivalent for oblate/prolate)

    private let Lmax = AuxCoeffs.Lmax       // 6
    private let AUXNUMBER = AuxCoeffs.AUXNUMBER  // 6

    /// Cache for computed Fourier coefficients.
    /// Size: Lmax × AUXNUMBER × AUXNUMBER = 6 × 36 = 216.
    /// Initialised to NaN; filled lazily per conversion pair.
    private var _c: [Double]

    init(a: Double, f: Double) {
        _a = a
        _f = f
        _b = a * (1 - f)
        _fm1 = 1 - f
        _e2 = f * (2 - f)
        _e2m1 = _fm1 * _fm1
        _e12 = _e2 / (1 - _e2)
        _e12p1 = 1 / _e2m1
        _n = f / (2 - f)
        _e = Swift.abs(_e2).squareRoot()
        _e1 = Swift.abs(_e12).squareRoot()
        _n2 = _n * _n
        if f == 0 {
            _q = _e12p1 + 1
        } else if f > 0 {
            _q = _e12p1 + Foundation.asinh(_e1) / _e
        } else {
            _q = _e12p1 + Foundation.atan(_e) / _e
        }
        _c = [Double](repeating: .nan, count: Lmax * AUXNUMBER * AUXNUMBER)

        // Eagerly pre-fill ALL conversion pair coefficients so that _c is
        // never mutated after init.  This makes the class truly thread-safe
        // (justifying @unchecked Sendable).
        for auxout in 0 ..< AUXNUMBER {
            for auxin in 0 ..< AUXNUMBER {
                let k = AuxCoeffs.ind(auxout, auxin)
                guard k >= 0 else { continue }
                fillcoeff(auxin, auxout, k)
            }
        }
    }

    // MARK: - Convert (series path)

    /// Convert between two auxiliary latitudes using the order-6 Fourier series.
    func convert(_ auxin: Int, _ auxout: Int, _ zeta: AuxAngle) -> AuxAngle {
        let k = AuxCoeffs.ind(auxout, auxin)
        guard k >= 0 else { return .nan }
        if auxin == auxout { return zeta }

        let zn = zeta.normalized()
        let cSlice = Array(_c[(Lmax * k) ..< (Lmax * (k + 1))])
        let d = Self.clenshaw(sinSeries: true, szeta: zn.y, czeta: zn.x,
                              c: cSlice)
        var result = zn
        result.add(AuxAngle.radians(d))
        return result
    }

    // MARK: - Exact simple conversions (for phi ↔ beta, used internally)

    /// Convert geographic latitude to parametric latitude.
    func parametric(_ phi: AuxAngle) -> AuxAngle {
        AuxAngle(phi.y * _fm1, phi.x)
    }

    // MARK: - Radii

    /// Rectifying radius via order-6 series in n².
    func rectifyingRadius() -> Double {
        let c = AuxCoeffs.rectifyingRadiusCoeffs
        return (_a + _b) / 2 * polyEval(withCoefficients: c, at: _n2)
    }

    /// Authalic radius squared via order-6 series in n.
    func authalicRadiusSquared() -> Double {
        let c = AuxCoeffs.authalicRadiusSqCoeffs
        return _a * (_a + _b) / 2 * polyEval(withCoefficients: c, at: _n)
    }

    // MARK: - Clenshaw summation

    /// Evaluate a Fourier series using Clenshaw summation.
    ///
    /// Computes `sum(c[k] * sin((2k+2)*zeta), k=0..K-1)` if sinSeries is true,
    /// or the cosine analogue if false.
    static func clenshaw(sinSeries sinp: Bool, szeta: Double, czeta: Double,
                         c: [Double]) -> Double {
        let K = c.count
        var k = K
        var u0 = 0.0, u1 = 0.0
        let x = 2 * (czeta - szeta) * (czeta + szeta) // 2*cos(2*zeta)
        while k > 0 {
            k -= 1
            let t = x * u0 - u1 + c[k]
            u1 = u0
            u0 = t
        }
        let f0 = sinp ? 2 * szeta * czeta : x / 2
        let fm1 = sinp ? 0.0 : 1.0
        return f0 * u0 - fm1 * u1
    }

    // MARK: - fillcoeff

    /// Compute and cache the Fourier coefficients for a conversion pair.
    func fillcoeff(_ auxin: Int, _ auxout: Int, _ k: Int) {
        guard k >= 0 else { return }
        if auxout == auxin {
            for i in 0 ..< Lmax { _c[Lmax * k + i] = 0 }
            return
        }
        let RECTIFYING = AuxType.mu.rawValue  // 3
        var o = AuxCoeffs.ptrs[k]
        var d = _n

        if auxin <= RECTIFYING && auxout <= RECTIFYING {
            // "Even" conversion: polynomial in n²
            for l in 0 ..< Lmax {
                let m = (Lmax - l - 1) / 2  // polynomial degree in n²
                let slice = Array(AuxCoeffs.coeffs[o ..< (o + m + 1)])
                _c[Lmax * k + l] = d * polyEval(withCoefficients: slice, at: _n2)
                o += m + 1
                d *= _n
            }
        } else {
            // "Full" conversion: polynomial in n
            for l in 0 ..< Lmax {
                let m = Lmax - l - 1  // polynomial degree in n
                let slice = Array(AuxCoeffs.coeffs[o ..< (o + m + 1)])
                _c[Lmax * k + l] = d * polyEval(withCoefficients: slice, at: _n)
                o += m + 1
                d *= _n
            }
        }
    }

    // MARK: - Coefficient cache access (used by DAuxLatitude)

    /// Return the cached Fourier coefficients for conversion pair `k`.
    func coeffSlice(forPairIndex k: Int) -> [Double] {
        Array(_c[(Lmax * k) ..< (Lmax * (k + 1))])
    }

    // MARK: - Shared WGS84 instance

    static let wgs84 = AuxLatitude(a: 6_378_137, f: 1 / 298.257223563)
}
