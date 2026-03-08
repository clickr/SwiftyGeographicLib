//
//  GeodesicLine+Position.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import Foundation
import Math

public extension GeodesicLine {

    // MARK: - Public position API

    /// Find the position on the line at a given distance from the origin.
    ///
    /// - Parameter distance: Distance from point 1 in metres.
    /// - Returns: `GeodesicPosition` with the point's coordinates and azimuth.
    func position(distance: Double) -> GeodesicPosition {
        return genPosition(arcmode: false, s12a12: distance)
    }

    /// Find the position on the line at a given arc length from the origin.
    ///
    /// - Parameter arcLength: Arc length from point 1 in degrees.
    /// - Returns: `GeodesicPosition` with the point's coordinates and azimuth.
    func arcPosition(arcLength: Double) -> GeodesicPosition {
        return genPosition(arcmode: true, s12a12: arcLength)
    }

    // MARK: - Internal generic position

    /// General position: arcmode selects distance (false) or arc-length (true) input.
    ///
    /// Corresponds to `GeodesicLine::GenPosition` in the C++ API.
    func genPosition(arcmode: Bool, s12a12: Double) -> GeodesicPosition {

        // Step 1 — find sig12, ssig12, csig12 from s12 or a12
        var sig12: Double
        var ssig12: Double
        var csig12: Double
        var B12 = 0.0
        var AB1 = 0.0

        if arcmode {
            sig12 = s12a12 * Math.degree
            let sc = sincosd(degrees: s12a12)
            ssig12 = sc.sin; csig12 = sc.cos
        } else {
            // Convert distance to arc-length on auxiliary sphere
            let tau12 = s12a12 / (b * (1 + aA1m1))
            let s = sin(tau12), c = cos(tau12)
            // B12 from the reverted C1p series
            B12 = -Geodesic.sinCosSeries(sinSeries: true,
                                          sinx: stau1 * c + ctau1 * s,
                                          cosx: ctau1 * c - stau1 * s,
                                          c: cC1pa, n: Geodesic.nC1p)
            sig12 = tau12 - (B12 - bB11)
            ssig12 = sin(sig12); csig12 = cos(sig12)

            // Newton correction for |f| > 0.01
            if abs(f) > 0.01 {
                let ssig2t = ssig1 * csig12 + csig1 * ssig12
                let csig2t = csig1 * csig12 - ssig1 * ssig12
                B12 = Geodesic.sinCosSeries(sinSeries: true, sinx: ssig2t, cosx: csig2t,
                                             c: cC1a, n: Geodesic.nC1)
                let serr = (1 + aA1m1) * (sig12 + (B12 - bB11)) - s12a12 / b
                sig12 -= serr / sqrt(1 + k2 * sq(ssig2t))
                ssig12 = sin(sig12); csig12 = cos(sig12)
                // B12 will be recomputed below
            }
        }

        // Step 2 — sig2 = sig1 + sig12
        let ssig2 = ssig1 * csig12 + csig1 * ssig12
        let csig2 = csig1 * csig12 - ssig1 * ssig12
        let dn2 = sqrt(1 + k2 * sq(ssig2))

        if !arcmode || abs(f) > 0.01 {
            B12 = Geodesic.sinCosSeries(sinSeries: true, sinx: ssig2, cosx: csig2,
                                         c: cC1a, n: Geodesic.nC1)
        }
        AB1 = (1 + aA1m1) * (B12 - bB11)

        // Step 3 — destination latitude and longitude
        let sbet2 = calp0 * ssig2
        let cbet2 = hypot(salp0, calp0 * csig2)
        let cbet2f = cbet2 == 0 ? 1e-15 : cbet2  // avoid degeneracy

        // azimuth at destination
        let salp2 = salp0
        let calp2 = calp0 * csig2

        let lat2 = atan2d(sbet2, f1 * cbet2f)
        let azi2 = atan2d(salp2, calp2)

        // longitude
        let somg2 = salp0 * ssig2
        let comg2 = csig2
        let E = copysign(1.0, salp0)   // east-going?
        // Long_unroll style: omg12 from arc differences
        let omg12 = E * (sig12
            - (atan2(ssig2, csig2) - atan2(ssig1, csig1))
            + (atan2(E * somg2, comg2) - atan2(E * somg1, comg1)))
        let lam12 = omg12 + aA3c * (sig12 + (Geodesic.sinCosSeries(sinSeries: true,
                                                                      sinx: ssig2, cosx: csig2,
                                                                      c: cC3a, n: Geodesic.nC3 - 1)
                                              - bB31))
        let lon12 = lam12 / Math.degree
        
        let lon2 = angNormalize(angNormalize(lon1) + angNormalize(lon12))
        
        // Step 4 — distance
        let dist: Double
        if arcmode {
            dist = b * ((1 + aA1m1) * sig12 + AB1)
        } else {
            dist = s12a12
        }

        // Step 5 — reduced length and scale
        let B22 = Geodesic.sinCosSeries(sinSeries: true, sinx: ssig2, cosx: csig2,
                                         c: cC2a, n: Geodesic.nC2)
        let AB2 = (1 + aA2m1) * (B22 - bB21)
        let J12 = (aA1m1 - aA2m1) * sig12 + (AB1 - AB2)
        let m12 = b * ((dn2 * (csig1 * ssig2) - dn1 * (ssig1 * csig2)) - csig1 * csig2 * J12)
        let csig12dot = csig1 * csig2 + ssig1 * ssig2
        let M12v = csig12dot + (k2 * (ssig2 - ssig1) * (ssig2 + ssig1) / (dn1 + dn2) * ssig2
                                - csig2 * J12) * ssig1 / dn1
        let M21v = csig12dot - (k2 * (ssig2 - ssig1) * (ssig2 + ssig1) / (dn1 + dn2) * ssig1
                                - csig1 * J12) * ssig2 / dn2

        let arcOut = arcmode ? s12a12 : sig12 / Math.degree

        return GeodesicPosition(
            latitude: lat2,
            longitude: lon2,
            azimuth: azi2,
            distance: dist,
            arcLength: arcOut,
            reducedLength: m12,
            geodesicScale12: M12v,
            geodesicScale21: M21v)
    }
}
