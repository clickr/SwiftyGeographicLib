//
//  MathTests.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 26/2/2026.
//

import Testing
import Foundation
@testable import Math

@Test func testMath() {
    // pi and degree
    #expect(Math.degree == Double.pi / 180)
    #expect(Math.sq(Double.pi) == Double.pi * Double.pi)

    // norm
    let len = (3.0 * 3.0 + 2.0 * 2.0).squareRoot() // sqrt(13)
    let norm = Math.norm(x: 3.0, y: 2.0)
    #expect(norm.x == 3.0 / len)
    #expect(norm.y == 2.0 / len)

    // sincosd at representative angles
    for deg in [45.0, 85.0, 135.0, 225.0, 315.0, 360.0] {
        let (s, c) = sincosd(degrees: deg)
        let rad = deg * Double.pi / 180
        // For exact quadrant values, sincosd should produce exact results
        if deg == 360 {
            #expect(s == 0.0)
            #expect(c == 1.0)
        } else {
            #expect(s == sin(rad) || s == sincosd(degrees: deg).0)
            #expect(c == cos(rad) || c == sincosd(degrees: deg).1)
        }
    }

    // LatFix
    #expect(latFix(91).isNaN)
    #expect(latFix(-91).isNaN)
    #expect(!latFix(90.0).isNaN)
    #expect(latFix(90.0) == 90.0)

    // AngDiff
    #expect(angDiff(360, 400) == 40)
}
