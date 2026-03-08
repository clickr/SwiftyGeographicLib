//
//  IntersectTests.swift
//  SwiftyGeographicLib
//
//  Created by David Hart on 8/3/2026.
//

import Testing
@testable import Intersect
@testable import IntersectInternal
import Geodesic
import SimpleGeographicLib


@Test func setupInternalsNotNAN() {
    
    let a: Double    // equatorial radius
    let f: Double    // equatorial radius, flattening
    let rR: Double   // authalic radius
    let d: Double    // pi*_rR
    let eps: Double  // criterion for intersection + coincidence
    let tol: Double  // convergence for Newton in Solve1
    let delta: Double// for equality tests, safety margin for tiling
    let t1: Double   // min distance between intersections
    let t2: Double   // furthest dist to closest intersection
    let t3: Double   // 1/2 furthest min dist to next intersection
    let t4: Double   // capture radius for spherical sol in Solve.nan
    let t5: Double   // longest shortest geodesic
    let d1: Double   // tile spacing for Closest
    let d2: Double   // tile spacing for Next
    let d3: Double    // tile spacing for All
    
    (a, f, rR, d, eps, tol, delta, t1, t2, t3, t4, t5, d1, d2, d3) = _computeIntersectInternals(geodesic: .wgs84)
    #expect(a.isFinite)
    #expect(f.isFinite)
    #expect(rR.isFinite)
    #expect(d.isFinite)
    #expect(eps.isFinite)
    #expect(tol.isFinite)
    #expect(delta.isFinite)
    #expect(t1.isFinite)
    #expect(t2.isFinite)
    #expect(t3.isFinite)
    #expect(t4.isFinite)
    #expect(t5.isFinite)
    #expect(d1.isFinite)
    #expect(d2.isFinite)
    #expect(d3.isFinite)
}

@Test func test_computeIntersectInternals() {
    let swiftGeodesic = Geodesic.wgs84
    let geodesic = GeographicLib.Geodesic(swiftGeodesic.equatorialRadius, swiftGeodesic.flattening, false)
//    let intersect = GeographicLib.Intersect(GeographicLib.Geodesic.WGS84().pointee)
    let a: Double    // equatorial radius
    let f: Double    // equatorial radius, flattening
    let rR: Double   // authalic radius
    let d: Double    // pi*_rR
    let eps: Double  // criterion for intersection + coincidence
    let tol: Double  // convergence for Newton in Solve1
    let delta: Double// for equality tests, safety margin for tiling
    let t1: Double   // min distance between intersections
    let t2: Double   // furthest dist to closest intersection
    let t3: Double   // 1/2 furthest min dist to next intersection
    let t4: Double   // capture radius for spherical sol in Solve.nan
    let t5: Double   // longest shortest geodesic
    let d1: Double   // tile spacing for Closest
    let d2: Double   // tile spacing for Next
    let d3: Double    // tile spacing for All
    
    (a, f, rR, d, eps, tol, delta, t1, t2, t3, t4, t5, d1, d2, d3) = _computeIntersectInternals(geodesic: .wgs84)
    
}
