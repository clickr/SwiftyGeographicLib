//
//  Geodesic+Inverse.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import Foundation
import Math

public extension Geodesic {

    // MARK: - Public inverse API

    /// Solve the inverse geodesic problem.
    ///
    /// Given two points, find the distance between them and the azimuths at
    /// each end.
    ///
    /// - Parameters:
    ///   - latitude1: Latitude of point 1 in degrees (−90° to 90°).
    ///   - longitude1: Longitude of point 1 in degrees.
    ///   - latitude2: Latitude of point 2 in degrees (−90° to 90°).
    ///   - longitude2: Longitude of point 2 in degrees.
    /// - Returns: `GeodesicInverseResult` with distance and azimuths.
    func inverse(latitude1: Double, longitude1: Double,
                 latitude2: Double, longitude2: Double) -> GeodesicInverseResult {
        var salp1 = 0.0, calp1 = 0.0, salp2 = 0.0, calp2 = 0.0
        var s12 = 0.0, m12 = 0.0, M12 = 0.0, M21 = 0.0
        let a12 = genInverse(lat1: latitude1, lon1: longitude1,
                             lat2: latitude2, lon2: longitude2,
                             s12: &s12,
                             salp1: &salp1, calp1: &calp1,
                             salp2: &salp2, calp2: &calp2,
                             m12: &m12, M12: &M12, M21: &M21)
        let azi1 = atan2d(salp1, calp1)
        let azi2 = atan2d(salp2, calp2)
        return GeodesicInverseResult(
            distance: s12,
            azimuth1: azi1,
            azimuth2: azi2,
            arcLength: a12,
            reducedLength: m12,
            geodesicScale12: M12,
            geodesicScale21: M21)
    }

    // MARK: - Internal generic inverse

    /// General inverse problem — updates all out-parameters and returns a12.
    ///
    /// Corresponds to `Geodesic::GenInverse` in the C++ API.
    internal func genInverse(lat1: Double, lon1: Double,
                              lat2: Double, lon2: Double,
                              s12: inout Double,
                              salp1: inout Double, calp1: inout Double,
                              salp2: inout Double, calp2: inout Double,
                              m12: inout Double, M12: inout Double, M21: inout Double) -> Double {

        // Longitude difference (AngDiff does this carefully with error term)
        let (lon12, lon12s) = angDiffWithError(lon1, lon2)
        let lonsign: Double = lon12.sign == .minus ? -1 : 1
        let lon12pos = lon12 * lonsign
        let lon12spos = lon12s * lonsign
        let lam12 = lon12pos * Math.degree
        let (slam12, clam12) = sincosde(lon12pos, lon12spos)
        // supplementary longitude diff
        let lon12sSupp = (hd - lon12pos) - lon12spos

        // Coarsen latitudes to avoid pole singularities
        var lat1m = angRound(latFix(lat1))
        var lat2m = angRound(latFix(lat2))

        // Swap so that |lat1| >= |lat2| (lat1 <= -0)
        let swapp: Double = abs(lat1m) < abs(lat2m) || lat2m.isNaN ? -1 : 1
        if swapp < 0 {
            // lonsign already applied, just swap lats
            swap(&lat1m, &lat2m)
        }
        let latsign: Double = lat1m.sign == .minus ? 1 : -1
        lat1m *= latsign
        lat2m *= latsign

        // Reduced latitudes
        var (sbet1, cbet1) = sincosd(degrees: lat1m)
        sbet1 *= f1
        let normBet1 = Math.norm(x: sbet1, y: cbet1)
        let sbet1n = normBet1.x
        let cbet1n = max(tiny, normBet1.y)

        var (sbet2, cbet2) = sincosd(degrees: lat2m)
        sbet2 *= f1
        let normBet2 = Math.norm(x: sbet2, y: cbet2)
        var (sbet2n, cbet2n) = (normBet2.x, max(tiny, normBet2.y))

        // Force exact symmetry
        if cbet1n < -sbet1n {
            if cbet2n == cbet1n { sbet2n = copysign(sbet1n, sbet2n) }
        } else {
            if abs(sbet2n) == -sbet1n { cbet2n = cbet1n }
        }

        let dn1 = sqrt(1 + ep2 * sq(sbet1n))
        let dn2 = sqrt(1 + ep2 * sq(sbet2n))

        var a12 = Double.nan
        var sig12 = Double.nan
        var s12x = 0.0, m12x = Double.nan

        // Scratch buffer shared across Lengths calls
        var Ca = [Double](repeating: 0, count: Geodesic.nC1 + 1)

        let meridian = lat1m == -qd || slam12 == 0

        if meridian {
            // Endpoints on a single meridian
            calp1 = clam12; salp1 = slam12
            calp2 = 1;      salp2 = 0

            let ssig1m = sbet1n, csig1m = calp1 * cbet1n
            let ssig2m = sbet2n, csig2m = calp2 * cbet2n

            sig12 = atan2(max(0.0, csig1m * ssig2m - ssig1m * csig2m) + 0,
                          csig1m * csig2m + ssig1m * ssig2m)

            let r = lengths(eps: n, sig12: sig12,
                            ssig1: ssig1m, csig1: csig1m, dn1: dn1,
                            ssig2: ssig2m, csig2: csig2m, dn2: dn2,
                            cbet1: cbet1n, cbet2: cbet2n,
                            wantDistance: true, wantReducedLength: true, wantScale: true,
                            ca: &Ca)
            s12x = r.s12b; m12x = r.m12b; M12 = r.M12; M21 = r.M21

            if sig12 < tol2 || m12x >= 0 {
                if sig12 < 3 * tiny || (sig12 < tol0 && (s12x < 0 || m12x < 0)) {
                    sig12 = 0; m12x = 0; s12x = 0
                }
                m12x *= b
                s12x *= b
                a12 = sig12 / Math.degree
            } else {
                // m12 < 0 — prolate, too close to anti-podal: fall through
            }
        }

        // Equatorial case
        if !meridian && sbet1n == 0 && (f <= 0 || lon12sSupp >= f * hd) {
            calp1 = 0; calp2 = 0; salp1 = 1; salp2 = 1
            s12x = a * lam12
            sig12 = lam12 / f1
            m12x = b * sin(sig12)
            M12 = cos(sig12); M21 = M12
            a12 = lon12pos / f1
        } else if !meridian {
            // General case: Newton's method for Lambda12
            var dnm = 0.0
            sig12 = inverseStart(sbet1: sbet1n, cbet1: cbet1n, dn1: dn1,
                                 sbet2: sbet2n, cbet2: cbet2n, dn2: dn2,
                                 lam12: lam12, slam12: slam12, clam12: clam12,
                                 salp1: &salp1, calp1: &calp1,
                                 salp2: &salp2, calp2: &calp2,
                                 dnm: &dnm, ca: &Ca)

            if sig12 >= 0 {
                // Short line — InverseStart already filled salp2, calp2, dnm
                s12x = sig12 * b * dnm
                m12x = sq(dnm) * b * sin(sig12 / dnm)
                M12 = cos(sig12 / dnm); M21 = M12
                a12 = sig12 / Math.degree
            } else {
                // Newton iteration
                var ssig1 = 0.0, csig1 = 0.0, ssig2 = 0.0, csig2 = 0.0
                var eps = 0.0, domg12 = 0.0
                var salp1a = tiny, calp1a = 1.0
                var salp1b = tiny, calp1b = -1.0
                var tripn = false, tripb = false
                var numit = 0

                while true {
                    let (v, dv) = lambda12(sbet1: sbet1n, cbet1: cbet1n, dn1: dn1,
                                           sbet2: sbet2n, cbet2: cbet2n, dn2: dn2,
                                           salp1: salp1, calp1: calp1,
                                           slam120: slam12, clam120: clam12,
                                           salp2: &salp2, calp2: &calp2,
                                           sig12: &sig12,
                                           ssig1: &ssig1, csig1: &csig1,
                                           ssig2: &ssig2, csig2: &csig2,
                                           eps: &eps, domg12: &domg12,
                                           diffp: numit < Geodesic.maxit1,
                                           ca: &Ca)

                    if tripb || !(abs(v) >= (tripn ? 8 : 1) * tol0) || numit == maxit2 {
                        break
                    }
                    // Update bracket
                    if v > 0 && (numit > Geodesic.maxit1 || calp1 / salp1 > calp1b / salp1b) {
                        salp1b = salp1; calp1b = calp1
                    } else if v < 0 && (numit > Geodesic.maxit1 || calp1 / salp1 < calp1a / salp1a) {
                        salp1a = salp1; calp1a = calp1
                    }
                    // Newton step
                    if numit < Geodesic.maxit1 && dv > 0 {
                        let dalp1 = -v / dv
                        if abs(dalp1) < .pi {
                            let sdalp1 = sin(dalp1), cdalp1 = cos(dalp1)
                            let nsalp1 = salp1 * cdalp1 + calp1 * sdalp1
                            if nsalp1 > 0 {
                                calp1 = calp1 * cdalp1 - salp1 * sdalp1
                                salp1 = nsalp1
                                let n2 = Math.norm(x: salp1, y: calp1)
                                salp1 = n2.x; calp1 = n2.y
                                tripn = abs(v) <= 16 * tol0
                                numit += 1
                                continue
                            }
                        }
                    }
                    // Bisection fallback
                    salp1 = (salp1a + salp1b) / 2
                    calp1 = (calp1a + calp1b) / 2
                    let n2 = Math.norm(x: salp1, y: calp1)
                    salp1 = n2.x; calp1 = n2.y
                    tripn = false
                    tripb = (abs(salp1a - salp1) + (calp1a - calp1) < tolb ||
                             abs(salp1 - salp1b) + (calp1 - calp1b) < tolb)
                    numit += 1
                }

                let lengthmask = true  // always compute distance
                let r = lengths(eps: eps, sig12: sig12,
                                ssig1: ssig1, csig1: csig1, dn1: dn1,
                                ssig2: ssig2, csig2: csig2, dn2: dn2,
                                cbet1: cbet1n, cbet2: cbet2n,
                                wantDistance: lengthmask,
                                wantReducedLength: true,
                                wantScale: true,
                                ca: &Ca)
                s12x = r.s12b; m12x = r.m12b; M12 = r.M12; M21 = r.M21
                m12x *= b
                s12x *= b
                a12 = sig12 / Math.degree
                // (somg12/comg12 for area computation would go here when implemented)
            }
        }

        s12 = 0 + s12x   // convert -0 to 0
        m12 = 0 + m12x

        // Restore azimuth signs for the canonical form
        if swapp < 0 {
            swap(&salp1, &salp2); swap(&calp1, &calp2)
            swap(&M12, &M21)
        }
        salp1 *= lonsign; calp1 *= swapp * latsign
        salp2 *= lonsign; calp2 *= swapp * latsign

        return a12
    }

    // MARK: - Astroid

    /// Solve k⁴ + 2k³ − (x²+y²−1)k² − 2y²k − y² = 0 for the positive root.
    ///
    /// Corresponds to `Geodesic::Astroid` in the C++ API.
    internal static func astroid(x: Double, y: Double) -> Double {
        let p = sq(x), q = sq(y)
        let r = (p + q - 1) / 6
        guard !(q == 0 && r <= 0) else { return 0 }
        let S = p * q / 4
        let r2 = sq(r), r3 = r * r2
        let disc = S * (S + 2 * r3)
        var u = r
        if disc >= 0 {
            var T3 = S + r3
            T3 += T3 < 0 ? -sqrt(disc) : sqrt(disc)
            let T = cbrt(T3)
            u += T + (T != 0 ? r2 / T : 0)
        } else {
            let ang = atan2(sqrt(-disc), -(S + r3))
            u += 2 * r * cos(ang / 3)
        }
        let v = sqrt(sq(u) + q)
        let uv = u < 0 ? q / (v - u) : u + v
        let w = (uv - q) / (2 * v)
        return uv / (sqrt(uv + sq(w)) + w)
    }

    // MARK: - InverseStart

    /// Find a starting azimuth for Newton's method.
    ///
    /// Returns sig12 >= 0 for short lines (also sets salp2, calp2, dnm).
    /// Returns sig12 < 0 for the general case (salp1, calp1 are a good start).
    ///
    /// Corresponds to `Geodesic::InverseStart` in the C++ API.
    internal func inverseStart(sbet1: Double, cbet1: Double, dn1: Double,
                                sbet2: Double, cbet2: Double, dn2: Double,
                                lam12: Double, slam12: Double, clam12: Double,
                                salp1: inout Double, calp1: inout Double,
                                salp2: inout Double, calp2: inout Double,
                                dnm: inout Double, ca: inout [Double]) -> Double {
        var sig12: Double = -1
        let sbet12  = sbet2 * cbet1 - cbet2 * sbet1
        let cbet12  = cbet2 * cbet1 + sbet2 * sbet1
        let sbet12a = sbet2 * cbet1 + cbet2 * sbet1

        let shortline = cbet12 >= 0 && sbet12 < 0.5 && cbet2 * lam12 < 0.5
        var somg12: Double, comg12: Double
        if shortline {
            var sbetm2 = sq(sbet1 + sbet2)
            sbetm2 /= sbetm2 + sq(cbet1 + cbet2)
            dnm = sqrt(1 + ep2 * sbetm2)
            let omg12 = lam12 / (f1 * dnm)
            somg12 = sin(omg12); comg12 = cos(omg12)
        } else {
            somg12 = slam12; comg12 = clam12
        }

        salp1 = cbet2 * somg12
        calp1 = comg12 >= 0
            ? sbet12  + cbet2 * sbet1 * sq(somg12) / (1 + comg12)
            : sbet12a - cbet2 * sbet1 * sq(somg12) / (1 - comg12)

        let ssig12 = hypot(salp1, calp1)
        let csig12 = sbet1 * sbet2 + cbet1 * cbet2 * comg12

        if shortline && ssig12 < etol2 {
            salp2 = cbet1 * somg12
            calp2 = sbet12 - cbet1 * sbet2 *
                (comg12 >= 0 ? sq(somg12) / (1 + comg12) : 1 - comg12)
            let n2 = Math.norm(x: salp2, y: calp2)
            salp2 = n2.x; calp2 = n2.y
            sig12 = atan2(ssig12, csig12)
        } else if abs(n) > 0.1 || csig12 >= 0 || ssig12 >= 6 * abs(n) * .pi * sq(cbet1) {
            // nothing — use the spherical estimate as-is
        } else {
            // Scale to antipodal coordinate system and use astroid
            let lam12x = atan2(-slam12, -clam12)
            var lamscale: Double, betscale: Double, x: Double, y: Double
            if f >= 0 {
                let k2 = sq(sbet1) * ep2
                let epsA = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
                lamscale = f * cbet1 * a3f(epsA) * .pi
                betscale = lamscale * cbet1
                x = lam12x / lamscale
                y = sbet12a / betscale
            } else {
                let cbet12a = cbet2 * cbet1 - sbet2 * sbet1
                let bet12a = atan2(sbet12a, cbet12a)
                let rr = lengths(eps: n, sig12: .pi + bet12a,
                                 ssig1: sbet1, csig1: -cbet1, dn1: dn1,
                                 ssig2: sbet2, csig2: cbet2, dn2: dn2,
                                 cbet1: cbet1, cbet2: cbet2,
                                 wantDistance: false, wantReducedLength: true, wantScale: false,
                                 ca: &ca)
                x = -1 + rr.m12b / (cbet1 * cbet2 * rr.m0 * .pi)
                betscale = x < -0.01 ? sbet12a / x : -f * sq(cbet1) * .pi
                lamscale = betscale / cbet1
                y = lam12x / lamscale
            }

            if y > -tol1 && x > -1 - xthresh {
                if f >= 0 {
                    salp1 = min(1.0, -x); calp1 = -sqrt(1 - sq(salp1))
                } else {
                    calp1 = max(x > -tol1 ? 0.0 : -1.0, x)
                    salp1 = sqrt(1 - sq(calp1))
                }
            } else {
                let k = Geodesic.astroid(x: x, y: y)
                let omg12a = lamscale * (f >= 0 ? -x * k / (1 + k) : -y * (1 + k) / k)
                somg12 = sin(omg12a); comg12 = -cos(omg12a)
                salp1 = cbet2 * somg12
                calp1 = sbet12a - cbet2 * sbet1 * sq(somg12) / (1 - comg12)
            }
        }

        if !(salp1 <= 0) {
            let n2 = Math.norm(x: salp1, y: calp1)
            salp1 = n2.x; calp1 = n2.y
        } else {
            salp1 = 1; calp1 = 0
        }
        return sig12
    }

    // MARK: - Lambda12

    /// Evaluate Lambda12(alp1) − lam12, and its derivative dLambda/dalp1.
    ///
    /// Returns (v, dv) where v = lambda12(alp1) - lam12 and dv is the derivative.
    /// Updates all pass-by-reference quantities for the Newton iteration.
    ///
    /// Corresponds to `Geodesic::Lambda12` in the C++ API.
    internal func lambda12(sbet1: Double, cbet1: Double, dn1: Double,
                            sbet2: Double, cbet2: Double, dn2: Double,
                            salp1 salp1In: Double, calp1 calp1In: Double,
                            slam120: Double, clam120: Double,
                            salp2: inout Double, calp2: inout Double,
                            sig12: inout Double,
                            ssig1: inout Double, csig1: inout Double,
                            ssig2: inout Double, csig2: inout Double,
                            eps: inout Double, domg12: inout Double,
                            diffp: Bool,
                            ca: inout [Double]) -> (v: Double, dv: Double) {

        var salp1 = salp1In, calp1 = calp1In

        if sbet1 == 0 && calp1 == 0 {
            calp1 = -tiny
        }

        let salp0 = salp1 * cbet1
        let calp0 = hypot(calp1, salp1 * sbet1)

        var somg1: Double, comg1: Double
        var somg2: Double, comg2: Double

        ssig1 = sbet1; somg1 = salp0 * sbet1
        csig1 = calp1 * cbet1; comg1 = csig1
        let n1 = Math.norm(x: ssig1, y: csig1)
        ssig1 = n1.x; csig1 = n1.y

        salp2 = cbet2 != cbet1 ? salp0 / cbet2 : salp1
        calp2 = cbet2 != cbet1 || abs(sbet2) != -sbet1
            ? sqrt(sq(calp1 * cbet1) +
                    (cbet1 < -sbet1
                     ? (cbet2 - cbet1) * (cbet1 + cbet2)
                     : (sbet1 - sbet2) * (sbet1 + sbet2))) / cbet2
            : abs(calp1)

        ssig2 = sbet2; somg2 = salp0 * sbet2
        csig2 = calp2 * cbet2; comg2 = csig2
        let n2 = Math.norm(x: ssig2, y: csig2)
        ssig2 = n2.x; csig2 = n2.y

        sig12 = atan2(max(0.0, csig1 * ssig2 - ssig1 * csig2) + 0,
                      csig1 * csig2 + ssig1 * ssig2)

        let somg12 = max(0.0, comg1 * somg2 - somg1 * comg2) + 0
        let comg12 = comg1 * comg2 + somg1 * somg2
        let eta = atan2(somg12 * clam120 - comg12 * slam120,
                        comg12 * clam120 + somg12 * slam120)

        let k2 = sq(calp0) * ep2
        eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
        let cC3a = c3f(eps)
        let B312 = (Geodesic.sinCosSeries(sinSeries: true, sinx: ssig2, cosx: csig2,
                                           c: cC3a, n: Geodesic.nC3 - 1)
                    - Geodesic.sinCosSeries(sinSeries: true, sinx: ssig1, cosx: csig1,
                                            c: cC3a, n: Geodesic.nC3 - 1))
        domg12 = -f * a3f(eps) * salp0 * (sig12 + B312)
        let lam12 = eta + domg12

        var dlam12 = 0.0
        if diffp {
            if calp2 == 0 {
                dlam12 = -2 * f1 * dn1 / sbet1
            } else {
                let rr = lengths(eps: eps, sig12: sig12,
                                 ssig1: ssig1, csig1: csig1, dn1: dn1,
                                 ssig2: ssig2, csig2: csig2, dn2: dn2,
                                 cbet1: cbet1, cbet2: cbet2,
                                 wantDistance: false, wantReducedLength: true, wantScale: false,
                                 ca: &ca)
                dlam12 = rr.m12b
                dlam12 *= f1 / (calp2 * cbet2)
            }
        }

        // eta already incorporates the target (eta = omg12 - lam120), so
        // lam12 = eta + domg12 = computed_lambda12 - target_lambda12 = residual.
        return (lam12, dlam12)
    }
}

