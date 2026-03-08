//
//  GeodesicCoefficients.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

// Maxima-generated coefficient functions for the geodesic series at order 6,
// plus SinCosSeries (Clenshaw summation) and Lengths.
//
// Coefficient convention used throughout this file:
//   • Coefficients are in *decreasing* power order (first element = highest power),
//     matching the Maxima-generated tables in GeographicLib.
//   • The slice passed to polyEval contains only the polynomial coefficients.
//     The divisor that follows each group in the raw coeff[] table is extracted
//     separately and divided after evaluation.
//   • polyEval (not polyValue) is used because polyValue drops its last element.

import Math

// MARK: - Static coefficient computation

extension Geodesic {

    // MARK: A1m1f

    /// Evaluates (1-eps)*A1 - 1; a polynomial in eps2 at order 3 (for N=6).
    ///
    /// C++ (order 6 case):
    /// ```
    /// coeff[] = { 1, 4, 64, 0, 256 }
    /// t = polyval(3, coeff, sq(eps)) / coeff[4];
    /// return (t + eps) / (1 - eps);
    /// ```
    static func a1m1f(_ eps: Double) -> Double {
        // N=6 → N/2 = 3
        // (1-eps)*A1 - 1, polynomial in eps2 of order 3
        let coeff: [Double] = [1, 4, 64, 0, 256]  // last element is divisor
        let m = 3
        // polyValue uses increasing-power order; coeff[0..m] are the poly, coeff[m+1] is divisor
        let slice = Array(coeff[0...m])
        let t = polyEval(withCoefficients: slice, at: eps * eps) / coeff[m + 1]
        return (t + eps) / (1 - eps)
    }

    // MARK: A2m1f

    /// Evaluates (1+eps)*A2 - 1; a polynomial in eps2 at order 3 (for N=6).
    ///
    /// C++ (order 6 case):
    /// ```
    /// coeff[] = { -11, -28, -192, 0, 256 }
    /// t = polyval(3, coeff, sq(eps)) / coeff[4];
    /// return (t - eps) / (1 + eps);
    /// ```
    static func a2m1f(_ eps: Double) -> Double {
        let coeff: [Double] = [-11, -28, -192, 0, 256]
        let m = 3
        let slice = Array(coeff[0...m])
        let t = polyEval(withCoefficients: slice, at: eps * eps) / coeff[m + 1]
        return (t - eps) / (1 + eps)
    }

    // MARK: C1f

    /// Fills c[1...6] with C1 coefficients for given eps (order 6 case).
    ///
    /// C++ (order 6 case):
    /// ```
    /// // C1[l]/eps^l, polynomial in eps2
    /// coeff[] = {
    ///   -1, 6, -16, 32,        // C1[1]: poly of order 2 + divisor 32
    ///   -9, 64, -128, 2048,    // C1[2]: poly of order 2 + divisor 2048
    ///    9, -16, 768,          // C1[3]: poly of order 1 + divisor 768
    ///    3, -5, 512,           // C1[4]: poly of order 1 + divisor 512
    ///   -7, 1280,              // C1[5]: poly of order 0 + divisor 1280
    ///   -7, 2048,              // C1[6]: poly of order 0 + divisor 2048
    /// };
    /// d = eps; for l in 1...6: c[l] = d * polyval((6-l)/2, ...) / div; d *= eps
    /// ```
    static func c1f(_ eps: Double) -> [Double] {
        let coeff: [Double] = [
            // C1[1]/eps^1, polynomial in eps2 of order 2
            -1, 6, -16, 32,
            // C1[2]/eps^2, polynomial in eps2 of order 2
            -9, 64, -128, 2048,
            // C1[3]/eps^3, polynomial in eps2 of order 1
            9, -16, 768,
            // C1[4]/eps^4, polynomial in eps2 of order 1
            3, -5, 512,
            // C1[5]/eps^5, polynomial in eps2 of order 0
            -7, 1280,
            // C1[6]/eps^6, polynomial in eps2 of order 0
            -7, 2048,
        ]
        let eps2 = eps * eps
        var c = [Double](repeating: 0, count: nC1 + 1)  // index 0 unused
        var d = eps
        var o = 0
        for l in 1...nC1 {
            let m = (nC1 - l) / 2  // order of polynomial in eps2
            let slice = Array(coeff[o..<(o + m + 1)])
            c[l] = d * polyEval(withCoefficients: slice, at: eps2) / coeff[o + m + 1]
            o += m + 2
            d *= eps
        }
        return c
    }

    // MARK: C1pf

    /// Fills c[1...6] with C1p coefficients for given eps (order 6 case).
    static func c1pf(_ eps: Double) -> [Double] {
        let coeff: [Double] = [
            // C1p[1]/eps^1, polynomial in eps2 of order 2
            205, -432, 768, 1536,
            // C1p[2]/eps^2, polynomial in eps2 of order 2
            4005, -4736, 3840, 12288,
            // C1p[3]/eps^3, polynomial in eps2 of order 1
            -225, 116, 384,
            // C1p[4]/eps^4, polynomial in eps2 of order 1
            -7173, 2695, 7680,
            // C1p[5]/eps^5, polynomial in eps2 of order 0
            3467, 7680,
            // C1p[6]/eps^6, polynomial in eps2 of order 0
            38081, 61440,
        ]
        let eps2 = eps * eps
        var c = [Double](repeating: 0, count: nC1p + 1)
        var d = eps
        var o = 0
        for l in 1...nC1p {
            let m = (nC1p - l) / 2
            let slice = Array(coeff[o..<(o + m + 1)])
            c[l] = d * polyEval(withCoefficients: slice, at: eps2) / coeff[o + m + 1]
            o += m + 2
            d *= eps
        }
        return c
    }

    // MARK: C2f

    /// Fills c[1...6] with C2 coefficients for given eps (order 6 case).
    static func c2f(_ eps: Double) -> [Double] {
        let coeff: [Double] = [
            // C2[1]/eps^1, polynomial in eps2 of order 2
            1, 2, 16, 32,
            // C2[2]/eps^2, polynomial in eps2 of order 2
            35, 64, 384, 2048,
            // C2[3]/eps^3, polynomial in eps2 of order 1
            15, 80, 768,
            // C2[4]/eps^4, polynomial in eps2 of order 1
            7, 35, 512,
            // C2[5]/eps^5, polynomial in eps2 of order 0
            63, 1280,
            // C2[6]/eps^6, polynomial in eps2 of order 0
            77, 2048,
        ]
        let eps2 = eps * eps
        var c = [Double](repeating: 0, count: nC2 + 1)
        var d = eps
        var o = 0
        for l in 1...nC2 {
            let m = (nC2 - l) / 2
            let slice = Array(coeff[o..<(o + m + 1)])
            c[l] = d * polyEval(withCoefficients: slice, at: eps2) / coeff[o + m + 1]
            o += m + 2
            d *= eps
        }
        return c
    }

    // MARK: A3coeff (constructor helper)

    /// Computes the A3 coefficient array from third flattening `n`.
    ///
    /// The resulting array is stored as _aA3x and later evaluated via polyval
    /// with eps as the argument.
    ///
    /// C++ (order 6 case):
    /// ```
    /// // A3, coeff of eps^j, polynomial in n
    /// coeff[] = {
    ///   -3, 128,       // eps^5: poly of order 0
    ///   -2, -3, 64,    // eps^4: poly of order 1
    ///   -1, -3, -1, 16,// eps^3: poly of order 2
    ///    3, -1, -2, 8, // eps^2: poly of order 2
    ///    1, -1, 2,     // eps^1: poly of order 1
    ///    1, 1,         // eps^0: poly of order 0
    /// };
    /// for j in (N-1)...0: aA3x[k++] = polyval(m, ..., n) / div
    /// ```
    static func computeA3coeff(n: Double) -> [Double] {
        let coeff: [Double] = [
            // A3, coeff of eps^5, polynomial in n of order 0
            -3, 128,
            // A3, coeff of eps^4, polynomial in n of order 1
            -2, -3, 64,
            // A3, coeff of eps^3, polynomial in n of order 2
            -1, -3, -1, 16,
            // A3, coeff of eps^2, polynomial in n of order 2
            3, -1, -2, 8,
            // A3, coeff of eps^1, polynomial in n of order 1
            1, -1, 2,
            // A3, coeff of eps^0, polynomial in n of order 0
            1, 1,
        ]
        var result = [Double](repeating: 0, count: nA3x)
        var o = 0
        var k = 0
        for j in stride(from: nA3 - 1, through: 0, by: -1) {
            let m = min(nA3 - j - 1, j)  // order of polynomial in n
            let slice = Array(coeff[o..<(o + m + 1)])
            result[k] = polyEval(withCoefficients: slice, at: n) / coeff[o + m + 1]
            k += 1
            o += m + 2
        }
        return result
    }

    // MARK: C3coeff (constructor helper)

    /// Computes the C3 coefficient array from third flattening `n`.
    static func computeC3coeff(n: Double) -> [Double] {
        let coeff: [Double] = [
            // C3[1], coeff of eps^5, polynomial in n of order 0
            3, 128,
            // C3[1], coeff of eps^4, polynomial in n of order 1
            2, 5, 128,
            // C3[1], coeff of eps^3, polynomial in n of order 2
            -1, 3, 3, 64,
            // C3[1], coeff of eps^2, polynomial in n of order 2
            -1, 0, 1, 8,
            // C3[1], coeff of eps^1, polynomial in n of order 1
            -1, 1, 4,
            // C3[2], coeff of eps^5, polynomial in n of order 0
            5, 256,
            // C3[2], coeff of eps^4, polynomial in n of order 1
            1, 3, 128,
            // C3[2], coeff of eps^3, polynomial in n of order 2
            -3, -2, 3, 64,
            // C3[2], coeff of eps^2, polynomial in n of order 2
            1, -3, 2, 32,
            // C3[3], coeff of eps^5, polynomial in n of order 0
            7, 512,
            // C3[3], coeff of eps^4, polynomial in n of order 1
            -10, 9, 384,
            // C3[3], coeff of eps^3, polynomial in n of order 2
            5, -9, 5, 192,
            // C3[4], coeff of eps^5, polynomial in n of order 0
            7, 512,
            // C3[4], coeff of eps^4, polynomial in n of order 1
            -14, 7, 512,
            // C3[5], coeff of eps^5, polynomial in n of order 0
            21, 2560,
        ]
        var result = [Double](repeating: 0, count: nC3x)
        var o = 0
        var k = 0
        for l in 1..<nC3 {
            for j in stride(from: nC3 - 1, through: l, by: -1) {
                let m = min(nC3 - j - 1, j)
                let slice = Array(coeff[o..<(o + m + 1)])
                result[k] = polyEval(withCoefficients: slice, at: n) / coeff[o + m + 1]
                k += 1
                o += m + 2
            }
        }
        return result
    }

    // MARK: C4coeff (constructor helper)

    /// Computes the C4 coefficient array from third flattening `n`.
    static func computeC4coeff(n: Double) -> [Double] {
        let coeff: [Double] = [
            // C4[0], coeff of eps^5, polynomial in n of order 0
            97, 15015,
            // C4[0], coeff of eps^4, polynomial in n of order 1
            1088, 156, 45045,
            // C4[0], coeff of eps^3, polynomial in n of order 2
            -224, -4784, 1573, 45045,
            // C4[0], coeff of eps^2, polynomial in n of order 3
            -10656, 14144, -4576, -858, 45045,
            // C4[0], coeff of eps^1, polynomial in n of order 4
            64, 624, -4576, 6864, -3003, 15015,
            // C4[0], coeff of eps^0, polynomial in n of order 5
            100, 208, 572, 3432, -12012, 30030, 45045,
            // C4[1], coeff of eps^5, polynomial in n of order 0
            1, 9009,
            // C4[1], coeff of eps^4, polynomial in n of order 1
            -2944, 468, 135135,
            // C4[1], coeff of eps^3, polynomial in n of order 2
            5792, 1040, -1287, 135135,
            // C4[1], coeff of eps^2, polynomial in n of order 3
            5952, -11648, 9152, -2574, 135135,
            // C4[1], coeff of eps^1, polynomial in n of order 4
            -64, -624, 4576, -6864, 3003, 135135,
            // C4[2], coeff of eps^5, polynomial in n of order 0
            8, 10725,
            // C4[2], coeff of eps^4, polynomial in n of order 1
            1856, -936, 225225,
            // C4[2], coeff of eps^3, polynomial in n of order 2
            -8448, 4992, -1144, 225225,
            // C4[2], coeff of eps^2, polynomial in n of order 3
            -1440, 4160, -4576, 1716, 225225,
            // C4[3], coeff of eps^5, polynomial in n of order 0
            -136, 63063,
            // C4[3], coeff of eps^4, polynomial in n of order 1
            1024, -208, 105105,
            // C4[3], coeff of eps^3, polynomial in n of order 2
            3584, -3328, 1144, 315315,
            // C4[4], coeff of eps^5, polynomial in n of order 0
            -128, 135135,
            // C4[4], coeff of eps^4, polynomial in n of order 1
            -2560, 832, 405405,
            // C4[5], coeff of eps^5, polynomial in n of order 0
            128, 99099,
        ]
        var result = [Double](repeating: 0, count: nC4x)
        var o = 0
        var k = 0
        for l in 0..<nC4 {
            for j in stride(from: nC4 - 1, through: l, by: -1) {
                let m = nC4 - j - 1  // order of polynomial in n
                let slice = Array(coeff[o..<(o + m + 1)])
                result[k] = polyEval(withCoefficients: slice, at: n) / coeff[o + m + 1]
                k += 1
                o += m + 2
            }
        }
        return result
    }

    // MARK: - SinCosSeries (Clenshaw summation)

    /// Evaluate Fourier series using Clenshaw summation.
    ///
    /// - Parameters:
    ///   - sinSeries: `true` → evaluate ∑ c[i]·sin(2i·x), `false` → ∑ c[i]·cos((2i+1)·x)
    ///   - sinx: sin(x)
    ///   - cosx: cos(x)
    ///   - c:  coefficient array (1-indexed; c[0] unused for sin series)
    ///   - n:  number of terms
    ///
    /// C++ reference: `Geodesic::SinCosSeries`
    static func sinCosSeries(sinSeries: Bool, sinx: Double, cosx: Double,
                              c: [Double], n: Int) -> Double {
        // ar = 2 * cos(2x)
        let ar = 2 * (cosx - sinx) * (cosx + sinx)
        var nn = n
        // start from the element one beyond last (C++ pointer arithmetic: c += n + sinp)
        // In Swift we use an index into the array
        var idx = n + (sinSeries ? 1 : 0)   // points one past the last coeff we'll use
        var y0: Double = (nn & 1 == 1) ? c[idx - 1] : 0  // c[--idx] when odd
        if nn & 1 == 1 { idx -= 1 }
        var y1: Double = 0
        nn /= 2
        while nn > 0 {
            y1 = ar * y0 - y1 + c[idx - 1]; idx -= 1
            y0 = ar * y1 - y0 + c[idx - 1]; idx -= 1
            nn -= 1
        }
        return sinSeries
            ? 2 * sinx * cosx * y0        // sin(2x) * y0
            : cosx * (y0 - y1)            // cos(x) * (y0 - y1)
    }

    // MARK: - Lengths

    /// Compute geodesic arc lengths and related quantities.
    ///
    /// - Parameters:
    ///   - eps: eccentricity-related parameter
    ///   - sig12: sig2 - sig1 on auxiliary sphere
    ///   - ssig1, csig1: sin/cos of sig1
    ///   - dn1: sqrt(1 + k²·sin²sig1)
    ///   - ssig2, csig2: sin/cos of sig2
    ///   - dn2: sqrt(1 + k²·sin²sig2)
    ///   - cbet1, cbet2: cos of reduced latitudes
    ///   - wantDistance: compute s12b
    ///   - wantReducedLength: compute m12b and m0
    ///   - wantScale: compute M12, M21
    ///
    /// Returns (s12b, m12b, m0, M12, M21) where s12b = distance/_b etc.
    ///
    /// C++ reference: `Geodesic::Lengths`
    func lengths(eps: Double, sig12: Double,
                 ssig1: Double, csig1: Double, dn1: Double,
                 ssig2: Double, csig2: Double, dn2: Double,
                 cbet1: Double, cbet2: Double,
                 wantDistance: Bool, wantReducedLength: Bool, wantScale: Bool,
                 ca: inout [Double]) -> (s12b: Double, m12b: Double, m0: Double,
                                         M12: Double, M21: Double) {
        var s12b = 0.0, m12b = 0.0, m0 = 0.0, M12 = 0.0, M21 = 0.0

        var m0x = 0.0, j12 = 0.0, A1 = 0.0, A2 = 0.0

        // We always need C1 for distance; C2 for reduced length/scale
        if wantDistance || wantReducedLength || wantScale {
            A1 = Geodesic.a1m1f(eps)
            ca = Geodesic.c1f(eps)  // fills ca[1...nC1]
            if wantReducedLength || wantScale {
                A2 = Geodesic.a2m1f(eps)
                var cb = Geodesic.c2f(eps)  // fills cb[1...nC2]
                m0x = A1 - A2
                A2 = 1 + A2

                if wantDistance {
                    let B1 = Geodesic.sinCosSeries(sinSeries: true, sinx: ssig2, cosx: csig2,
                                                    c: ca, n: Geodesic.nC1)
                              - Geodesic.sinCosSeries(sinSeries: true, sinx: ssig1, cosx: csig1,
                                                      c: ca, n: Geodesic.nC1)
                    s12b = (1 + A1) * (sig12 + B1)
                    let B2 = Geodesic.sinCosSeries(sinSeries: true, sinx: ssig2, cosx: csig2,
                                                    c: cb, n: Geodesic.nC2)
                              - Geodesic.sinCosSeries(sinSeries: true, sinx: ssig1, cosx: csig1,
                                                      c: cb, n: Geodesic.nC2)
                    j12 = m0x * sig12 + ((1 + A1) * B1 - A2 * B2)
                } else {
                    // Assume nC1 >= nC2; compute combined series
                    for l in 1...Geodesic.nC2 {
                        cb[l] = (1 + A1) * ca[l] - A2 * cb[l]
                    }
                    j12 = m0x * sig12 + (Geodesic.sinCosSeries(sinSeries: true, sinx: ssig2, cosx: csig2,
                                                                 c: cb, n: Geodesic.nC2)
                                         - Geodesic.sinCosSeries(sinSeries: true, sinx: ssig1, cosx: csig1,
                                                                  c: cb, n: Geodesic.nC2))
                }
            } else if wantDistance {
                // Only distance, no reduced length
                let B1 = Geodesic.sinCosSeries(sinSeries: true, sinx: ssig2, cosx: csig2,
                                                c: ca, n: Geodesic.nC1)
                          - Geodesic.sinCosSeries(sinSeries: true, sinx: ssig1, cosx: csig1,
                                                  c: ca, n: Geodesic.nC1)
                s12b = (1 + A1) * (sig12 + B1)
            }
        }

        if wantReducedLength {
            m0 = m0x
            m12b = dn2 * (csig1 * ssig2) - dn1 * (ssig1 * csig2) - csig1 * csig2 * j12
        }
        if wantScale {
            let csig12 = csig1 * csig2 + ssig1 * ssig2
            let t = ep2 * (cbet1 - cbet2) * (cbet1 + cbet2) / (dn1 + dn2)
            M12 = csig12 + (t * ssig2 - csig2 * j12) * ssig1 / dn1
            M21 = csig12 - (t * ssig1 - csig1 * j12) * ssig2 / dn2
        }
        return (s12b, m12b, m0, M12, M21)
    }
}
