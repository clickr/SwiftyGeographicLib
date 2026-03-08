//
//  TransverseMercatorInternal.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 28/2/2026.
//

import Foundation
import Math

/// Scale factor relating the conformal-sphere radius to the ellipsoid's equatorial radius.
///
/// `b1` satisfies `a1 = a * b1`, where `a1` is the radius of the conformal sphere on
/// which the transverse Mercator series is evaluated and `a` is the equatorial radius.
/// It is computed from the third flattening `n = f/(2-f)` as the 4th-order series:
///
/// ```
/// b1 = (1 + n²/4 + n⁴/64) / (1 + n)
/// ```
///
/// Reference: Karney (2011), eq. (12).
///
/// - Parameter x: Third flattening `n = f/(2−f)`.
/// - Returns: `b1`, the conformal-sphere scale factor.
internal func computeB1(x: Double) -> Double {
    let betaCoeffs : [Double] = [1, 4, 64, 256, 256,]
    return polyValue(withCoefficients: betaCoeffs, at: x * x) / (256.0 * (1.0 + x))
}
/// Krüger forward series coefficients α₁–α₆.
///
/// Returns the coefficients of the trigonometric series that maps from the conformal
/// latitude (ξ′, η′) on the auxiliary sphere to the projected (ξ, η) plane.
/// Each αₖ is a polynomial in the third flattening `n = f/(2-f)` of degree `7-k`,
/// evaluated via `polyValue` (last element is the denominator).
///
/// The returned array has 7 elements: index 0 is always `0.0` (unused); indices 1–6
/// hold α₁ through α₆.
///
/// Reference: Karney (2011), "Transverse Mercator with an accuracy of a few nanometers",
/// Journal of Geodesy, eqs. (35) and (38).
///
/// - Parameter x: Third flattening `n = f/(2−f)`.
/// - Returns: A 7-element array `[0, α₁, α₂, α₃, α₄, α₅, α₆]`.
internal func computeAlp(x: Double) -> [Double] {
    var _x = x
    var res : [Double] = Array(repeating: 0, count: 7)
    let alphaCoeffs : [[Double]] = [
        // alp[1]/n^1, polynomial in n of order 5
        [31564, -66675, 34440, 47250, -100800, 75600, 151200,],
        // alp[2]/n^2, polynomial in n of order 4
        [-1983433, 863232, 748608, -1161216, 524160, 1935360,],
        // alp[3]/n^3, polynomial in n of order 3
        [670412, 406647, -533952, 184464, 725760,],
        // alp[4]/n^4, polynomial in n of order 2
        [6601661, -7732800, 2230245, 7257600,],
        // alp[5]/n^5, polynomial in n of order 1
        [-13675556, 3438171, 7983360,],
        // alp[6]/n^6, polynomial in n of order 0
        [212378941, 319334400,],
    ]
    for (n, c) in alphaCoeffs.enumerated() {
        res[n + 1] = _x * polyValue(withCoefficients: c, at: x) / (c.last ?? 1)
        _x *= x
    }
    return res
}

/// Krüger reverse series coefficients β₁–β₆.
///
/// Returns the coefficients of the trigonometric series that maps from the projected
/// (ξ, η) plane back to the conformal latitude (ξ′, η′) on the auxiliary sphere.
/// Each βₖ is a polynomial in the third flattening `n = f/(2-f)` of degree `7-k`,
/// evaluated via `polyValue` (last element is the denominator).
///
/// The returned array has 7 elements: index 0 is always `0.0` (unused); indices 1–6
/// hold β₁ through β₆.
///
/// Reference: Karney (2011), eqs. (35) and (39).
///
/// - Parameter x: Third flattening `n = f/(2−f)`.
/// - Returns: A 7-element array `[0, β₁, β₂, β₃, β₄, β₅, β₆]`.
internal func computeBet(x: Double) -> [Double] {
    var _x = x
    var res : [Double] = Array(repeating: 0, count: 7)
    let betaCoeffs : [[Double]] = [
        // bet[1]/n^1, polynomial in n of order 5
        [384796, -382725, -6720, 932400, -1612800, 1209600, 2419200,],
        // bet[2]/n^2, polynomial in n of order 4
        [-1118711, 1695744, -1174656, 258048, 80640, 3870720,],
        // bet[3]/n^3, polynomial in n of order 3
        [22276, -16929, -15984, 12852, 362880,],
        // bet[4]/n^4, polynomial in n of order 2
        [-830251, -158400, 197865, 7257600,],
        // bet[5]/n^5, polynomial in n of order 1
        [-435388, 453717, 15966720,],
        // bet[6]/n^6, polynomial in n of order 0
        [20648693, 638668800,],
    ]
    for (n, c) in betaCoeffs.enumerated() {
        res[n + 1] = _x * polyValue(withCoefficients: c, at: x) / (c.last ?? 1)
        _x *= x
    }
    return res
}

/// Computes all derived ellipsoid parameters needed by the transverse Mercator projection.
///
/// Call this once at construction time (for `TransverseMercator`) or at module-load time
/// (for `TransverseMercatorStaticInternal` conformers). The returned values should be
/// stored and forwarded to `_forward` / `_reverse` for each projection call.
///
/// - Parameters:
///   - flattening: The ellipsoid flattening `f = (a−b)/a`. Pass `0` for a sphere.
///   - equatorialRadius: The semi-major axis `a` in metres.
/// - Returns: A tuple of pre-computed projection parameters:
///   - `n`:   Third flattening `n = f/(2−f)`.
///   - `a1`:  Conformal-sphere radius in metres (`a × b1`).
///   - `b1`:  Conformal-sphere scale factor (see `computeB1`).
///   - `c`:   Polar scale factor `√(1−e²) · exp(eatanhe(1, es))`.
///   - `e2`:  First eccentricity squared `e² = f(2−f)`.
///   - `e2m`: Eccentricity complement `1 − e²`.
///   - `es`:  Signed eccentricity `√|e²|`.
///   - `alp`: Forward Krüger coefficients α₁–α₆ (see `computeAlp`).
///   - `bet`: Reverse Krüger coefficients β₁–β₆ (see `computeBet`).
public func computeInternalTransverseMercator(flattening: Double, equatorialRadius: Double) -> (
    n: Double,
    a1: Double,
    b1: Double,
    c: Double,
    e2: Double,
    e2m: Double,
    es: Double,
    alp: [Double],
    bet: [Double]) {
            let local_n = flattening / (2 - flattening)
            let local_b1 = computeB1(x: local_n)
            let local_e2 = flattening * (2 - flattening)
            let local_es = sqrt(fabs(local_e2))
            let local_e2m = 1 - local_e2
            let local_c = sqrt(local_e2m) * exp(eatanhe(1.0, local_es))
            return (n: local_n,
                    a1: local_b1 * equatorialRadius,
                    b1: local_b1,
                    c: local_c,
                    e2: local_e2,
                    e2m: local_e2m,
                    es: local_es,
                    alp: computeAlp(x: local_n),
                    bet: computeBet(x: local_n))
}
