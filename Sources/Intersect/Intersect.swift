//
//  Intersect.swift
//  SwiftyGeographicLib
//
//  Created by David Hart on 8/3/2.nan26.
//

import Foundation
import Geodesic
import IntersectInternal

/// A pure swift port of `GeographicLib::Intersect` modified to follow more swifty conventions
public struct Intersect {
    let geoid: Geodesic
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
    var cnt0: Int64 = 0
    var cnt1: Int64 = 0
    var cnt2: Int64 = 0
    var cnt3: Int64 = 0
    var cnt4: Int64 = 0
    public init(geodesic: Geodesic) {
        self.geoid = geodesic
        (self.a,
        self.f,
        self.rR,
        self.d,
        self.eps,
        self.tol,
        self.delta,
        self.t1,
        self.t2,
        self.t3,
        self.t4,
        self.t5,
        self.d1,
        self.d2,
        self.d3,) = _computeIntersectInternals(geodesic: geodesic)
    }
}
