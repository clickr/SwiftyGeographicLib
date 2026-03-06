//
//  MathTests.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 26/2/2026.
//

import Testing
import Foundation
@testable import Math
@testable import SimpleGeographicLib

@Test func testMath() {
    #expect(GeographicLib.Math.pi() == Double.pi)
    #expect(GeographicLib.Math.degree() == Math.degree)
    #expect(Math.sq(Double.pi) == GeographicLib.Math.sq(Double.pi))
    var x = 3.0
    var y = 2.0
    GeographicLib.Math.norm(&x, &y)
    let norm = Math.norm(x: x, y: y)
    #expect(x == norm.x)
    #expect(y == norm.y)
    
    var sinX: Double = .nan
    var cosX: Double = .nan
    GeographicLib.Math.sincosd(45.0, &sinX, &cosX)
    #expect(sincosd(degrees: 45) == (sinX, cosX))
    
    GeographicLib.Math.sincosd(85.0, &sinX, &cosX)
    #expect(sincosd(degrees: 85) == (sinX, cosX))
    
    GeographicLib.Math.sincosd(135, &sinX, &cosX)
    #expect(sincosd(degrees: 135) == (sinX, cosX))
    
    GeographicLib.Math.sincosd(225, &sinX, &cosX)
    #expect(sincosd(degrees: 225) == (sinX, cosX))
    
    GeographicLib.Math.sincosd(315, &sinX, &cosX)
    #expect(sincosd(degrees: 315) == (sinX, cosX))
    
    GeographicLib.Math.sincosd(360, &sinX, &cosX)
    #expect(sincosd(degrees: 360) == (sinX, cosX))
    
    #expect(GeographicLib.Math.LatFix(91.0).isNaN)
    #expect(latFix(91).isNaN)
    #expect(GeographicLib.Math.LatFix(-91.0).isNaN)
    #expect(latFix(-91).isNaN)
    #expect(!latFix(90.0).isNaN)
    #expect(!GeographicLib.Math.LatFix(90.0).isNaN)
    
    #expect(angDiff(360, 400) == 40)
    #expect(angDiff(360, 400) == GeographicLib.Math.AngDiff(360.0, 400.0))
}
