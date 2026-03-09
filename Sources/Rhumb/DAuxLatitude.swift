//
//  DAuxLatitude.swift
//  SwiftyGeographicLib
//
//  Port of GeographicLib::DAuxLatitude by Charles Karney.
//  Divided differences of auxiliary latitudes and related helpers
//  needed for rhumb line calculations.
//

import Foundation
import Math

/// Divided differences of auxiliary latitudes.
///
/// Wraps an `AuxLatitude` and adds divided-difference methods needed by
/// the rhumb solver.
struct DAuxLatitude: Sendable {
    let aux: AuxLatitude

    init(a: Double, f: Double) {
        aux = AuxLatitude(a: a, f: f)
    }

    // MARK: - Series-based divided difference

    /// Divided difference of one auxiliary latitude with respect to another,
    /// using the Fourier series.
    ///
    /// Returns `(eta2 - eta1) / (zeta2 - zeta1)` where the angles are
    /// measured in radians.
    func dConvert(_ auxin: Int, _ auxout: Int,
                  _ zeta1: AuxAngle, _ zeta2: AuxAngle) -> Double {
        let k = AuxCoeffs.ind(auxout, auxin)
        guard k >= 0 else { return .nan }
        if auxin == auxout { return 1 }

        let z1n = zeta1.normalized()
        let z2n = zeta2.normalized()
        let cSlice = aux.coeffSlice(forPairIndex: k)
        return 1 + Self.dClenshaw(sinSeries: true,
                                  delta: z2n.radians() - z1n.radians(),
                                  szeta1: z1n.y, czeta1: z1n.x,
                                  szeta2: z2n.y, czeta2: z2n.x,
                                  c: cSlice)
    }

    // MARK: - Static divided-difference helpers

    /// Divided difference of the isometric latitude with respect to the
    /// conformal latitude: `(psi2 - psi1) / (chi2 - chi1)`.
    ///
    /// Parameters are **tangents** of the conformal latitudes.
    static func dlam(_ x: Double, _ y: Double) -> Double {
        if x == y { return AuxAngle.sc(x) }
        if x.isNaN || y.isNaN { return .nan }
        if x.isInfinite || y.isInfinite { return .infinity }
        return dasinh(x, y) / datan(x, y)
    }

    /// Divided difference of the spherical rhumb area term with respect to
    /// the isometric latitude: `(p0(chi2) - p0(chi1)) / (psi2 - psi1)`
    /// where `p0(chi) = log(sec(chi))`.
    ///
    /// Parameters are **tangents** of the conformal latitudes.
    static func dp0Dpsi(_ x: Double, _ y: Double) -> Double {
        if x == y { return AuxAngle.sn(x) }
        if (x + y).isNaN { return x + y }   // nan for inf - inf
        if x.isInfinite { return copysign(1, x) }
        if y.isInfinite { return copysign(1, y) }
        return dasinh(h(x), h(y)) * dh(x, y) / dasinh(x, y)
    }

    /// `h(x) = x * sn(x) / 2`
    private static func h(_ x: Double) -> Double {
        x * AuxAngle.sn(x) / 2
    }

    // MARK: - DClenshaw (divided difference of Clenshaw sum)

    /// Divided difference (or plain difference if delta == 1) of the
    /// Clenshaw summation.
    ///
    /// - Parameters:
    ///   - sinSeries: true for sine series, false for cosine.
    ///   - delta: **must** be either 1 (plain difference) or `zeta2 - zeta1`
    ///     in radians (divided difference). Other values give nonsense.
    ///   - szeta1, czeta1: sin/cos of zeta1.
    ///   - szeta2, czeta2: sin/cos of zeta2.
    ///   - c: Fourier coefficient array.
    static func dClenshaw(sinSeries sinp: Bool, delta Delta: Double,
                          szeta1: Double, czeta1: Double,
                          szeta2: Double, czeta2: Double,
                          c: [Double]) -> Double {
        let K = c.count
        let D2 = Delta * Delta
        let czetap = czeta2 * czeta1 - szeta2 * szeta1
        let szetap = szeta2 * czeta1 + czeta2 * szeta1
        let czetam = czeta2 * czeta1 + szeta2 * szeta1
        // sin(zetam) / Delta
        let szetamd: Double
        if Delta == 1 {
            szetamd = szeta2 * czeta1 - czeta2 * szeta1
        } else if Delta != 0 {
            szetamd = Foundation.sin(Delta) / Delta
        } else {
            szetamd = 1
        }

        let Xa =  2 * czetap * czetam
        let Xb = -2 * szetap * szetamd
        var u0a = 0.0, u0b = 0.0, u1a = 0.0, u1b = 0.0

        var k = K - 1
        while k >= 0 {
            let ta = Xa * u0a + D2 * Xb * u0b - u1a + c[k]
            let tb = Xb * u0a +      Xa * u0b - u1b
            u1a = u0a; u0a = ta
            u1b = u0b; u0b = tb
            k -= 1
        }

        let F0a  = (sinp ? szetap :  czetap) * czetam
        let F0b  = (sinp ? czetap : -szetap) * szetamd
        let Fm1a = sinp ? 0.0 : 1.0

        return 2 * (F0a * u0b + F0b * u0a - Fm1a * u1b)
    }

    // MARK: - Internal divided-difference primitives

    /// `(sn(y) - sn(x)) / (y - x)`
    static func dsn(_ x: Double, _ y: Double) -> Double {
        let sc1 = AuxAngle.sc(x)
        if x == y { return 1 / (sc1 * (1 + x * x)) }
        let sc2 = AuxAngle.sc(y)
        let sn1 = AuxAngle.sn(x), sn2 = AuxAngle.sn(y)
        if x * y > 0 {
            return (sn1 / sc2 + sn2 / sc1) / ((sn1 + sn2) * sc1 * sc2)
        } else {
            return (sn2 - sn1) / (y - x)
        }
    }

    /// `(atan(y) - atan(x)) / (y - x)` with proper limits.
    static func datan(_ x: Double, _ y: Double) -> Double {
        let d = y - x
        let xy = x * y
        if x == y { return 1 / (1 + xy) }
        if xy.isInfinite && xy > 0 { return 0 }
        if 2 * xy > -1 {
            return Foundation.atan(d / (1 + xy)) / d
        } else {
            return (Foundation.atan(y) - Foundation.atan(x)) / d
        }
    }

    /// `(asinh(y) - asinh(x)) / (y - x)` with proper limits.
    static func dasinh(_ x: Double, _ y: Double) -> Double {
        let d = y - x
        let xy = x * y
        let hx = AuxAngle.sc(x), hy = AuxAngle.sc(y)
        if x == y { return 1 / hx }
        if d.isInfinite { return 0 }
        if xy > 0 {
            let ratio: Double
            if xy < 1 {
                ratio = (x + y) / (x * hy + y * hx)
            } else {
                ratio = (1 / x + 1 / y) / (hy / y + hx / x)
            }
            return Foundation.asinh(d * ratio) / d
        } else {
            return (Foundation.asinh(y) - Foundation.asinh(x)) / d
        }
    }

    /// Divided difference of `h(x) = x * sn(x) / 2`.
    static func dh(_ x: Double, _ y: Double) -> Double {
        if (x + y).isNaN { return x + y }
        if x.isInfinite { return copysign(0.5, x) }
        if y.isInfinite { return copysign(0.5, y) }
        let sx = AuxAngle.sn(x), sy = AuxAngle.sn(y)
        let d = sx * x + sy * y
        if d / 2 == 0 { return (x + y) / 2 }   // handle underflow
        if x * y <= 0 { return (h(y) - h(x)) / (y - x) }  // excludes x==y==0
        let scx = AuxAngle.sc(x), scy = AuxAngle.sc(y)
        return ((x + y) / (2 * d))
            * (Math.sq(sx * sy)
               + Math.sq(sy / scx)
               + Math.sq(sx / scy))
    }

    /// `(sin(y) - sin(x)) / (y - x)` with care near x=y.
    static func dsin(_ x: Double, _ y: Double) -> Double {
        let d = (x - y) / 2
        return Foundation.cos((x + y) / 2) * (d != 0 ? Foundation.sin(d) / d : 1)
    }
}
