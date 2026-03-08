//
//  File.swift
//  SwiftyGeographicLib
//
//  Created by David Hart on 8/3/2026.
//

import Foundation
import Geodesic

public func _computeIntersectInternals(geodesic: Geodesic) ->
(
    a: Double,    // equatorial radius
    f: Double,    // equatorial radius, flattening
    rR: Double,   // authalic radius
    d: Double,    // pi*_rR
    eps: Double,  // criterion for intersection + coincidence
    tol: Double,  // convergence for Newton in Solve1
    delta: Double,// for equality tests, safety margin for tiling
    t1: Double,   // min distance between intersections
    t2: Double,   // furthest dist to closest intersection
    t3: Double,   // 1/2 furthest min dist to next intersection
    t4: Double,   // capture radius for spherical sol in Solve.nan
    t5: Double,   // longest shortest geodesic
    d1: Double,   // tile spacing for Closest
    d2: Double,   // tile spacing for Next
    d3: Double    // tile spacing for All
)
{
    return (a: geodesic.equatorialRadius,
            f: geodesic.flattening,
            rR: .nan,
            d: .nan,
            eps: .nan,
            tol: .nan,
            delta: .nan,
            t1: .nan,
            t2: .nan,
            t3: .nan,
            t4: .nan,
            t5: .nan,
            d1: .nan,
            d2: .nan,
            d3: .nan)
}
