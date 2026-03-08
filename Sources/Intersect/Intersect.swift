//
//  Intersect.swift
//  SwiftyGeographicLib
//
//  Created by David Hart on 8/3/2026.
//

import Foundation
import Geodesic
import Math

/// A pure Swift port of `GeographicLib::Intersect`.
///
/// Finds intersections of two geodesics on an ellipsoid. Four operations are
/// supported: `closest`, `segment`, `next`, and `all`.
///
/// Create an instance with a `Geodesic` (typically `.wgs84`) and then call the
/// intersection methods.
public struct Intersect {

    /// Displacement along two geodesics at an intersection.
    public struct Point {
        /// Signed displacement along geodesic X (metres).
        public let x: Double
        /// Signed displacement along geodesic Y (metres).
        public let y: Double
        /// Coincidence indicator: 0 = transverse, +1 = parallel, −1 = antiparallel.
        public let c: Int
    }

    let geodesic: Geodesic

    // Ellipsoid-derived constants
    let a: Double       // equatorial radius
    let f: Double       // flattening
    let rR: Double      // authalic radius
    let d: Double       // pi * rR
    let eps: Double     // criterion for intersection + coincidence
    let tol: Double     // convergence for Newton in Basic
    let delta: Double   // safety margin for equality tests and tiling
    let t1: Double      // min distance between intersections
    let t2: Double      // furthest dist to closest intersection
    let t3: Double      // 1/2 furthest min dist to next intersection
    let t4: Double      // capture radius for spherical solution
    let t5: Double      // longest shortest geodesic
    let d1: Double      // tile spacing for Closest
    let d2: Double      // tile spacing for Next
    let d3: Double      // tile spacing for All

    static let numit = 100

    /// Creates an intersection solver for the given ellipsoid.
    ///
    /// - Parameter geodesic: The geodesic calculator to use (e.g. `.wgs84`).
    public init(geodesic: Geodesic) {
        self.geodesic = geodesic

        let a = geodesic.equatorialRadius
        let f = geodesic.flattening
        self.a = a
        self.f = f

        let rR = sqrt(geodesic.ellipsoidArea / (4 * .pi))
        self.rR = rR
        let d = rR * .pi
        self.d = d

        self.eps = 3 * Double.ulpOfOne
        self.tol = d * pow(Double.ulpOfOne, 0.75)
        let delta = d * pow(Double.ulpOfOne, 0.2)
        self.delta = delta

        // Polar semi-circumference
        let polarSemiCirc = a * (1 - f) * .pi

        // t5 = 2 * quarter-meridian distance (equator to pole, doubled)
        let t5 = 2 * geodesic.inverse(
            latitude1: 0, longitude1: 0,
            latitude2: 90, longitude2: 0).distance
        self.t5 = t5

        let t2 = 2 * Intersect.distpolar(geodesic: geodesic, latitude: 90,
                                          rR: rR, d: d, tol: self.tol)

        if f > 0 {
            // Oblate (e.g. WGS84)
            let t3 = Intersect.distoblique(geodesic: geodesic, rR: rR, d: d,
                                           tol: self.tol, eps: self.eps)
            self.t1 = polarSemiCirc
            self.t2 = t2
            self.t3 = t3
            self.t4 = polarSemiCirc
        } else {
            // Prolate or sphere
            let t4 = Intersect.polarb(geodesic: geodesic, f: f, rR: rR, d: d,
                                      tol: self.tol)
            self.t1 = t2
            self.t2 = polarSemiCirc
            self.t3 = t5
            self.t4 = t4
        }

        self.d1 = self.t2 / 2
        self.d2 = 2 * self.t3 / 3
        self.d3 = self.t4 - delta

        precondition(self.d1 < self.d3 && self.d2 < self.d3 && self.d2 < 2 * self.t1,
                     "Ellipsoid too eccentric for Intersect")
    }

    // MARK: - L1 distance

    static func dist(_ x: Double, _ y: Double) -> Double {
        abs(x) + abs(y)
    }
}

// MARK: - Constructor helper functions

extension Intersect {

    /// Find a conjugate (or semi-conjugate) point on a geodesic line near `s3`.
    ///
    /// Corresponds to `Intersect::ConjugateDist` in C++.
    static func conjugateDist(
        line: GeodesicLine, s3: Double, semi: Bool,
        m12: Double = 0, M12: Double = 1, M21: Double = 1,
        tol: Double
    ) -> Double {
        var s = s3
        for _ in 0..<100 {
            let p = line.position(distance: s)
            let m13 = p.reducedLength!
            let M13 = p.geodesicScale12!
            let M31 = p.geodesicScale21!

            let m23 = m13 * M12 - m12 * M13
            let M23 = M13 * M21 + (m12 == 0 ? 0 : (1 - M12 * M21) * m13 / m12)
            let M32 = M31 * M12 + (m13 == 0 ? 0 : (1 - M13 * M31) * m12 / m13)

            let ds = semi ? m23 * M23 / (1 - M23 * M32) : -m23 / M32
            s += ds
            if !(abs(ds) > tol) { break }
        }
        return s
    }

    /// Distance to the semi-conjugate point for a meridional geodesic at `latitude`.
    ///
    /// Corresponds to `Intersect::distpolar` in C++.
    static func distpolar(
        geodesic: Geodesic, latitude: Double,
        rR: Double, d: Double, tol: Double
    ) -> Double {
        let line = geodesic.line(latitude: latitude, longitude: 0, azimuth: 0)
        let f = geodesic.flattening
        let a = geodesic.equatorialRadius
        return conjugateDist(line: line,
                             s3: (1 + f / 2) * a * .pi / 2,
                             semi: true, tol: tol)
    }

    /// Find the latitude that extremises `distpolar` using quadratic fit.
    ///
    /// Returns 2 * distpolar at the extremal latitude.
    /// Corresponds to `Intersect::polarb` in C++.
    static func polarb(
        geodesic: Geodesic, f: Double,
        rR: Double, d: Double, tol: Double
    ) -> Double {
        if f == 0 { return d }

        var lat0 = 63.0, s0 = distpolar(geodesic: geodesic, latitude: lat0, rR: rR, d: d, tol: tol)
        var lat1 = 65.0, s1 = distpolar(geodesic: geodesic, latitude: lat1, rR: rR, d: d, tol: tol)
        var lat2 = 64.0, s2 = distpolar(geodesic: geodesic, latitude: lat2, rR: rR, d: d, tol: tol)
        var latx = lat2, sx = s2

        for _ in 0..<10 {
            let den = (lat1 - lat0) * s2 + (lat0 - lat2) * s1 + (lat2 - lat1) * s0
            if !(den < 0 || den > 0) { break }
            let latn = ((lat1 - lat0) * (lat1 + lat0) * s2 +
                        (lat0 - lat2) * (lat0 + lat2) * s1 +
                        (lat2 - lat1) * (lat2 + lat1) * s0) / (2 * den)
            lat0 = lat1; s0 = s1
            lat1 = lat2; s1 = s2
            lat2 = latn; s2 = distpolar(geodesic: geodesic, latitude: lat2, rR: rR, d: d, tol: tol)
            if f < 0 ? (s2 < sx) : (s2 > sx) {
                sx = s2; latx = lat2
            }
        }
        _ = latx  // used only when returning lat via out-param in C++
        return 2 * sx
    }

    /// Conjugate distance for a geodesic at the equator with given azimuth.
    ///
    /// Corresponds to `Intersect::conjdist` in C++.
    static func conjdist(
        geodesic: Geodesic, azimuth: Double,
        rR: Double, d: Double, tol: Double, eps: Double
    ) -> (s: Double, ds: Double) {
        let line = geodesic.line(latitude: 0, longitude: 0, azimuth: azimuth)
        let s = conjugateDist(line: line, s3: d, semi: false, tol: tol)
        let p = basic(lineX: line, lineY: line,
                      x0: s / 2, y0: -3 * s / 2,
                      rR: rR, eps: eps, tol: tol, geodesic: geodesic)
        let ds = Intersect.dist(p.x, p.y) - 2 * s
        return (s, ds)
    }

    /// Find the azimuth that makes ds = 0 in conjdist (secant method).
    ///
    /// Returns the conjugate distance at the optimal azimuth.
    /// Corresponds to `Intersect::distoblique` in C++.
    static func distoblique(
        geodesic: Geodesic, rR: Double, d: Double,
        tol: Double, eps: Double
    ) -> Double {
        let f = geodesic.flattening
        if f == 0 { return d }

        var azi0 = 46.0
        var r0 = conjdist(geodesic: geodesic, azimuth: azi0,
                          rR: rR, d: d, tol: tol, eps: eps)
        var azi1 = 44.0
        var r1 = conjdist(geodesic: geodesic, azimuth: azi1,
                          rR: rR, d: d, tol: tol, eps: eps)
        var dsx = abs(r1.ds), sx = r1.s

        for _ in 0..<10 {
            if r1.ds == r0.ds { break }
            let azin = (azi0 * r1.ds - azi1 * r0.ds) / (r1.ds - r0.ds)
            azi0 = azi1; r0 = r1
            azi1 = azin
            r1 = conjdist(geodesic: geodesic, azimuth: azi1,
                          rR: rR, d: d, tol: tol, eps: eps)
            if abs(r1.ds) < dsx {
                dsx = abs(r1.ds); sx = r1.s
                if r1.ds == 0 { break }
            }
        }
        return sx
    }
}

// MARK: - Spherical and Basic (layers 1–2)

extension Intersect {

    /// Solve the spherical intersection triangle — initial approximation.
    ///
    /// Corresponds to `Intersect::Spherical` in C++.
    static func spherical(
        lineX: GeodesicLine, lineY: GeodesicLine,
        x0: Double, y0: Double,
        rR: Double, eps: Double, geodesic: Geodesic
    ) -> (x: Double, y: Double, c: Int) {
        let pX = lineX.position(distance: x0)
        let pY = lineY.position(distance: y0)
        let inv = geodesic.inverse(
            latitude1: pX.latitude, longitude1: pX.longitude,
            latitude2: pY.latitude, longitude2: pY.longitude)
        let z = inv.distance
        let aziXa = inv.azimuth1
        let aziYa = inv.azimuth2

        let sinz = sin(z / rR), cosz = cos(z / rR)

        // X = interior angle at X, Y = exterior angle at Y
        let (X, dX) = angDiffWithError(pX.azimuth, aziXa)
        let (Y, dY) = angDiffWithError(pY.azimuth, aziYa)
        let (XY, dXY) = angDiffWithError(X, Y)
        let s = copysign(1.0, XY + (dXY + dY - dX))

        let (sinX, cosX) = sincosde(s * X, s * dX)
        let (sinY, cosY) = sincosde(s * Y, s * dY)

        let sX: Double, sY: Double
        let c: Int

        if z <= eps * rR {
            sX = 0; sY = 0
            if abs(sinX - sinY) <= eps && abs(cosX - cosY) <= eps {
                c = 1
            } else if abs(sinX + sinY) <= eps && abs(cosX + cosY) <= eps {
                c = -1
            } else {
                c = 0
            }
        } else if abs(sinX) <= eps && abs(sinY) <= eps {
            c = cosX * cosY > 0 ? 1 : -1
            sX =  cosX * z / 2
            sY = -cosY * z / 2
        } else {
            sX = rR * atan2(sinY * sinz,  sinY * cosX * cosz - cosY * sinX)
            sY = rR * atan2(sinX * sinz, -sinX * cosY * cosz + cosX * sinY)
            c = 0
        }
        return (sX, sY, c)
    }

    /// Newton refinement of a spherical approximation.
    ///
    /// Corresponds to `Intersect::Basic` in C++.
    static func basic(
        lineX: GeodesicLine, lineY: GeodesicLine,
        x0: Double, y0: Double,
        rR: Double, eps: Double, tol: Double, geodesic: Geodesic
    ) -> (x: Double, y: Double, c: Int) {
        var qx = x0, qy = y0, qc = 0
        for n in 0..<numit {
            let dq = spherical(lineX: lineX, lineY: lineY,
                               x0: qx, y0: qy,
                               rR: rR, eps: eps, geodesic: geodesic)
            qx += dq.x; qy += dq.y
            if dq.c != 0 { qc = dq.c }
            if qc != 0 || !(Intersect.dist(dq.x, dq.y) > tol) { break }
            if n == numit - 1 {
                preconditionFailure("Convergence failure in Intersect.basic")
            }
        }
        return (qx, qy, qc)
    }
}

// MARK: - fixcoincident

extension Intersect {

    /// Adjust an intersection on a coincident line to be centred relative to p0.
    ///
    /// Corresponds to `Intersect::fixcoincident` in C++.
    static func fixcoincident(
        p0x: Double, p0y: Double,
        px: Double, py: Double, c: Int
    ) -> (x: Double, y: Double, c: Int) {
        if c == 0 { return (px, py, c) }
        let s = ((p0x + Double(c) * p0y) - (px + Double(c) * py)) / 2
        return (px + s, py + Double(c) * s, c)
    }
}

// MARK: - Layer 3: ClosestInt and NextInt

extension Intersect {

    /// Find the closest intersection using a 5-point grid search.
    ///
    /// Corresponds to `Intersect::ClosestInt` in C++.
    func closestInt(
        lineX: GeodesicLine, lineY: GeodesicLine,
        p0x: Double, p0y: Double
    ) -> (x: Double, y: Double, c: Int) {
        let ix = [ 0,  1, -1,  0,  0]
        let iy = [ 0,  0,  0,  1, -1]
        var skip = [false, false, false, false, false]

        var qx = Double.nan, qy = Double.nan, qc = 0

        for n in 0..<5 {
            if skip[n] { continue }
            var qxn = Intersect.basic(
                lineX: lineX, lineY: lineY,
                x0: p0x + Double(ix[n]) * d1,
                y0: p0y + Double(iy[n]) * d1,
                rR: rR, eps: eps, tol: tol, geodesic: geodesic)
            qxn = Intersect.fixcoincident(p0x: p0x, p0y: p0y,
                                          px: qxn.x, py: qxn.y, c: qxn.c)
            // Check if equal to current best
            if Intersect.dist(qx - qxn.x, qy - qxn.y) <= delta { continue }
            let distNew = Intersect.dist(qxn.x - p0x, qxn.y - p0y)
            if distNew < t1 {
                qx = qxn.x; qy = qxn.y; qc = qxn.c; break
            }
            let distCur = Intersect.dist(qx - p0x, qy - p0y)
            if n == 0 || distNew < distCur {
                qx = qxn.x; qy = qxn.y; qc = qxn.c
            }
            for m in (n + 1)..<5 {
                let dm = Intersect.dist(
                    qxn.x - (p0x + Double(ix[m]) * d1),
                    qxn.y - (p0y + Double(iy[m]) * d1))
                skip[m] = skip[m] || dm < 2 * t1 - d1 - delta
            }
        }
        return (qx, qy, qc)
    }

    /// Find the next closest intersection using an 8-point grid search.
    ///
    /// Corresponds to `Intersect::NextInt` in C++.
    func nextInt(
        lineX: GeodesicLine, lineY: GeodesicLine
    ) -> (x: Double, y: Double, c: Int) {
        let ix = [-1, -1,  1,  1, -2,  0,  2,  0]
        let iy = [-1,  1, -1,  1,  0,  2,  0, -2]
        var skip = [false, false, false, false, false, false, false, false]

        var qx = Double.infinity, qy = 0.0, qc = 0

        for n in 0..<8 {
            if skip[n] { continue }
            let qxn = Intersect.basic(
                lineX: lineX, lineY: lineY,
                x0: Double(ix[n]) * d2,
                y0: Double(iy[n]) * d2,
                rR: rR, eps: eps, tol: tol, geodesic: geodesic)
            let fc = Intersect.fixcoincident(p0x: 0, p0y: 0,
                                             px: qxn.x, py: qxn.y, c: qxn.c)
            let zerop = Intersect.dist(fc.x, fc.y) <= delta

            if qxn.c == 0 && zerop { continue }

            if qxn.c != 0 && zerop {
                // On a coincident line through origin — find conjugate points
                for sgn in stride(from: -1, through: 1, by: 2) {
                    let s = Intersect.conjugateDist(
                        line: lineX, s3: Double(sgn) * d, semi: false, tol: tol)
                    let qax = s, qay = Double(qxn.c) * s
                    if Intersect.dist(qax, qay) < Intersect.dist(qx, qy) {
                        qx = qax; qy = qay; qc = qxn.c
                    }
                }
            } else {
                if Intersect.dist(qxn.x, qxn.y) < Intersect.dist(qx, qy) {
                    qx = qxn.x; qy = qxn.y; qc = qxn.c
                }
            }

            for sgn in -1...1 {
                if (qxn.c == 0 && sgn != 0) || (zerop && sgn == 0) { continue }
                let qyx: Double, qyy: Double
                if qxn.c != 0 {
                    qyx = qxn.x + Double(sgn) * d2
                    qyy = qxn.y + Double(qxn.c * sgn) * d2
                } else {
                    qyx = qxn.x; qyy = qxn.y
                }
                for m in (n + 1)..<8 {
                    let dm = Intersect.dist(
                        qyx - Double(ix[m]) * d2,
                        qyy - Double(iy[m]) * d2)
                    skip[m] = skip[m] || dm < 2 * t1 - d2 - delta
                }
            }
        }
        return (qx, qy, qc)
    }
}

// MARK: - Layer 4: Public API

extension Intersect {

    /// Find the closest intersection of two geodesics.
    ///
    /// Corresponds to `Intersect::Closest` in C++.
    public func closest(
        latitudeX: Double, longitudeX: Double, azimuthX: Double,
        latitudeY: Double, longitudeY: Double, azimuthY: Double,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> Point {
        let lineX = geodesic.line(latitude: latitudeX, longitude: longitudeX,
                                  azimuth: azimuthX)
        let lineY = geodesic.line(latitude: latitudeY, longitude: longitudeY,
                                  azimuth: azimuthY)
        return closest(lineX: lineX, lineY: lineY, offset: offset)
    }

    /// Find the closest intersection of two geodesic lines.
    ///
    /// Corresponds to `Intersect::Closest` (GeodesicLine overload) in C++.
    public func closest(
        lineX: GeodesicLine, lineY: GeodesicLine,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> Point {
        let r = closestInt(lineX: lineX, lineY: lineY,
                           p0x: offset.x, p0y: offset.y)
        return Point(x: r.x, y: r.y, c: r.c)
    }

    /// Find the next closest intersection from a known intersection point.
    ///
    /// Both geodesics must start from the same point.
    ///
    /// Corresponds to `Intersect::Next` in C++.
    public func next(
        latitude: Double, longitude: Double,
        azimuthX: Double, azimuthY: Double
    ) -> Point {
        let lineX = geodesic.line(latitude: latitude, longitude: longitude,
                                  azimuth: azimuthX)
        let lineY = geodesic.line(latitude: latitude, longitude: longitude,
                                  azimuth: azimuthY)
        return next(lineX: lineX, lineY: lineY)
    }

    /// Find the next closest intersection from a known intersection point.
    ///
    /// Both geodesic lines must start from the same point.
    ///
    /// Corresponds to `Intersect::Next` (GeodesicLine overload) in C++.
    public func next(
        lineX: GeodesicLine, lineY: GeodesicLine
    ) -> Point {
        let r = nextInt(lineX: lineX, lineY: lineY)
        return Point(x: r.x, y: r.y, c: r.c)
    }

    /// Find the intersection of two geodesic segments defined by endpoints.
    ///
    /// Returns `(point, segmentMode)` where `segmentMode` is 0 if the segments
    /// actually intersect.
    ///
    /// Corresponds to `Intersect::Segment` in C++.
    public func segment(
        latitudeX1: Double, longitudeX1: Double,
        latitudeX2: Double, longitudeX2: Double,
        latitudeY1: Double, longitudeY1: Double,
        latitudeY2: Double, longitudeY2: Double
    ) -> (point: Point, segmentMode: Int) {
        let invX = geodesic.inverse(latitude1: latitudeX1, longitude1: longitudeX1,
                                    latitude2: latitudeX2, longitude2: longitudeX2)
        let invY = geodesic.inverse(latitude1: latitudeY1, longitude1: longitudeY1,
                                    latitude2: latitudeY2, longitude2: longitudeY2)
        let lineX = geodesic.inverseLine(latitude1: latitudeX1, longitude1: longitudeX1,
                                         latitude2: latitudeX2, longitude2: longitudeX2)
        let lineY = geodesic.inverseLine(latitude1: latitudeY1, longitude1: longitudeY1,
                                         latitude2: latitudeY2, longitude2: longitudeY2)
        let r = segmentInt(lineX: lineX, lineY: lineY,
                           sx: invX.distance, sy: invY.distance)
        return (Point(x: r.x, y: r.y, c: r.c), r.segmode)
    }

    /// Find all intersections within a distance.
    ///
    /// Returns intersections sorted by L1 distance from `offset`.
    ///
    /// Corresponds to `Intersect::All` in C++.
    public func all(
        latitudeX: Double, longitudeX: Double, azimuthX: Double,
        latitudeY: Double, longitudeY: Double, azimuthY: Double,
        maxDistance: Double,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> [Point] {
        let lineX = geodesic.line(latitude: latitudeX, longitude: longitudeX,
                                  azimuth: azimuthX)
        let lineY = geodesic.line(latitude: latitudeY, longitude: longitudeY,
                                  azimuth: azimuthY)
        return all(lineX: lineX, lineY: lineY, maxDistance: maxDistance, offset: offset)
    }

    /// Find all intersections within a distance using geodesic lines.
    ///
    /// Corresponds to `Intersect::All` (GeodesicLine overload) in C++.
    public func all(
        lineX: GeodesicLine, lineY: GeodesicLine,
        maxDistance: Double,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> [Point] {
        let results = allInt0(lineX: lineX, lineY: lineY,
                              maxdist: max(0, maxDistance),
                              p0x: offset.x, p0y: offset.y)
        return results.map { Point(x: $0.x, y: $0.y, c: $0.c) }
    }
}

// MARK: - Layer 3: SegmentInt, AllInt0, fixsegment

extension Intersect {

    static func segmentmode(_ sx: Double, _ sy: Double,
                            _ px: Double, _ py: Double) -> Int {
        let kx = px < 0 ? -1 : (px <= sx ? 0 : 1)
        let ky = py < 0 ? -1 : (py <= sy ? 0 : 1)
        return kx * 3 + ky
    }

    static func fixsegment(
        sx: Double, sy: Double,
        px: Double, py: Double, c: Int
    ) -> (x: Double, y: Double, c: Int) {
        if c == 0 { return (px, py, c) }
        let fc = Double(c)
        let pya = py - fc *  px,       sa =             -px
        let pyb = py - fc * (px - sx),  sb =         sx - px
        let pxc = px - fc *  py,       sc = fc *      -py
        let pxd = px - fc * (py - sy),  sd = fc * (sy - py)
        let ga = 0 <= pya && pya <= sy
        let gb = 0 <= pyb && pyb <= sy
        let gc = 0 <= pxc && pxc <= sx
        let gd = 0 <= pxd && pxd <= sx
        let s: Double
        if      ga && gb { s = (sa + sb) / 2 }
        else if gc && gd { s = (sc + sd) / 2 }
        else if ga && gc { s = (sa + sc) / 2 }
        else if ga && gd { s = (sa + sd) / 2 }
        else if gb && gc { s = (sb + sc) / 2 }
        else if gb && gd { s = (sb + sd) / 2 }
        else {
            if c > 0 {
                if abs((px - py) + sy) < abs((px - py) - sx) {
                    s = (sy - (px + py)) / 2
                } else {
                    s = (sx - (px + py)) / 2
                }
            } else {
                if abs(px + py) < abs((px + py) - (sx + sy)) {
                    s = (0 - (px - py)) / 2
                } else {
                    s = ((sx - sy) - (px - py)) / 2
                }
            }
        }
        return (px + s, py + fc * s, c)
    }

    func segmentInt(
        lineX: GeodesicLine, lineY: GeodesicLine,
        sx: Double, sy: Double
    ) -> (x: Double, y: Double, c: Int, segmode: Int) {
        let conjectureproved = false
        let p0x = sx / 2, p0y = sy / 2
        var q = closestInt(lineX: lineX, lineY: lineY, p0x: p0x, p0y: p0y)
        q = Intersect.fixsegment(sx: sx, sy: sy, px: q.x, py: q.y, c: q.c)
        var segmode = Intersect.segmentmode(sx, sy, q.x, q.y)

        if !conjectureproved && segmode != 0 &&
            Intersect.dist(p0x, p0y) >= Intersect.dist(p0x - q.x, p0y - q.y) {
            var segmodex = 1
            var qxx = 0.0, qxy = 0.0, qxc = 0
            for ix in 0..<2 {
                if segmodex == 0 { break }
                for iy in 0..<2 {
                    if segmodex == 0 { break }
                    let tx = Double(ix) * sx, ty = Double(iy) * sy
                    if Intersect.dist(q.x - tx, q.y - ty) >= 2 * t1 {
                        let b = Intersect.basic(lineX: lineX, lineY: lineY,
                                                x0: tx, y0: ty,
                                                rR: rR, eps: eps, tol: tol,
                                                geodesic: geodesic)
                        let fc = Intersect.fixcoincident(p0x: tx, p0y: ty,
                                                         px: b.x, py: b.y, c: b.c)
                        qxx = fc.0; qxy = fc.1; qxc = fc.2
                        segmodex = Intersect.segmentmode(sx, sy, qxx, qxy)
                    }
                }
            }
            if segmodex == 0 { segmode = 0; q = (qxx, qxy, qxc) }
        }
        return (q.x, q.y, q.c, segmode)
    }

    // Internal XPoint-like type for AllInt0
    struct XP {
        var x: Double
        var y: Double
        var c: Int
        func dist() -> Double { Intersect.dist(x, y) }
        func dist(to other: XP) -> Double {
            Intersect.dist(x - other.x, y - other.y)
        }
    }

    func allInt0(
        lineX: GeodesicLine, lineY: GeodesicLine,
        maxdist: Double, p0x: Double, p0y: Double
    ) -> [(x: Double, y: Double, c: Int)] {
        let maxdistx = maxdist + delta
        let m = Int(ceil(maxdistx / d3))
        let m2 = m * m + (m - 1) % 2
        let n = m - 1
        let d3l = maxdistx / Double(m)

        var start = [XP](repeating: XP(x: 0, y: 0, c: 0), count: m2)
        var skip = [Bool](repeating: false, count: m2)

        var h = 0
        start[h] = XP(x: p0x, y: p0y, c: 0); h += 1
        var i = -n
        while i <= n {
            var j = -n
            while j <= n {
                if !(i == 0 && j == 0) {
                    start[h] = XP(
                        x: p0x + d3l * Double(i + j) / 2,
                        y: p0y + d3l * Double(i - j) / 2, c: 0)
                    h += 1
                }
                j += 2
            }
            i += 2
        }

        // Use array-based set with delta-equality
        var results = [XP]()
        var coincidentSet = [XP]()
        var c0 = 0

        func findInSet(_ set: [XP], _ q: XP) -> Bool {
            set.contains { Intersect.dist($0.x - q.x, $0.y - q.y) <= delta }
        }

        for k in 0..<m2 {
            if skip[k] { continue }
            let qr = Intersect.basic(lineX: lineX, lineY: lineY,
                                     x0: start[k].x, y0: start[k].y,
                                     rR: rR, eps: eps, tol: tol, geodesic: geodesic)
            var q = XP(x: qr.x, y: qr.y, c: qr.c)

            if findInSet(results, q) { continue }
            if c0 != 0 {
                let fc = Intersect.fixcoincident(p0x: p0x, p0y: p0y,
                                                 px: q.x, py: q.y, c: c0)
                if findInSet(coincidentSet, XP(x: fc.x, y: fc.y, c: fc.c)) { continue }
            }

            var added = [XP]()

            if q.c != 0 {
                c0 = q.c
                let fc = Intersect.fixcoincident(p0x: p0x, p0y: p0y,
                                                 px: q.x, py: q.y, c: q.c)
                q = XP(x: fc.x, y: fc.y, c: fc.c)
                coincidentSet.append(q)

                // Remove existing results on this coincident line
                results.removeAll { r in
                    let fcr = Intersect.fixcoincident(p0x: p0x, p0y: p0y,
                                                      px: r.x, py: r.y, c: c0)
                    return Intersect.dist(fcr.x - q.x, fcr.y - q.y) <= delta
                }

                // Compute conjugate points along the coincident line
                let p = lineX.position(distance: q.x)
                let m12 = p.reducedLength!
                let M12v = p.geodesicScale12!
                let M21v = p.geodesicScale21!

                for sgn in stride(from: -1, through: 1, by: 2) {
                    var sa = 0.0
                    repeat {
                        sa = Intersect.conjugateDist(
                            line: lineX, s3: q.x + sa + Double(sgn) * d,
                            semi: false, m12: m12, M12: M12v, M21: M21v,
                            tol: tol) - q.x
                        let qc = XP(x: q.x + sa, y: q.y + Double(c0) * sa, c: q.c)
                        added.append(qc)
                        results.append(qc)
                    } while Intersect.dist(
                        added.last!.x - p0x, added.last!.y - p0y) <= maxdistx
                }
            }

            added.append(q)
            results.append(q)

            for qp in added {
                for l in (k + 1)..<m2 {
                    let dm = Intersect.dist(qp.x - start[l].x, qp.y - start[l].y)
                    skip[l] = skip[l] || dm < 2 * t1 - d3l - delta
                }
            }
        }

        // Trim to maxdist and sort by distance from p0
        results = results.filter {
            Intersect.dist($0.x - p0x, $0.y - p0y) <= maxdist
        }
        results.sort {
            Intersect.dist($0.x - p0x, $0.y - p0y) <
            Intersect.dist($1.x - p0x, $1.y - p0y)
        }
        return results.map { ($0.x, $0.y, $0.c) }
    }
}
