//
//  TransverseMercatorTests.swift
//  GeographicLib
//
//  Created by David Hart on 5/3/2026.
//

import Testing
import Math
import CoreLocation
@testable import TransverseMercator
import SimpleGeographicLib
import Numerics

@Test func testTransverseForward() {
    let centralMeridian = centralMeridian(zone: 50)
    let cppUTM = GeographicLib.TransverseMercator.UTM().pointee
    var x : Double = .nan
    var y : Double = .nan
    var gamma : Double = .nan
    var k : Double = .nan
    let ypph : CLLocationCoordinate2D = .init(latitude: -31.93980, longitude: 115.96650)
    cppUTM.Forward(centralMeridian, ypph.latitude, ypph.longitude, &x, &y, &gamma, &k)
    let utm = TransverseMercator.UTM
    let forward = utm.forward(centralMeridian: centralMeridian, coordinate2D: ypph)
    #expect(forward.x.isApproximatelyEqual(to: x, absoluteTolerance: 1e-9))
    #expect(forward.y.isApproximatelyEqual(to: y, absoluteTolerance: 1e-9))
    #expect(forward.convergence.isApproximatelyEqual(to: gamma, absoluteTolerance: 1e-9))
    #expect(forward.centralScale.isApproximatelyEqual(to: k, absoluteTolerance: 1e-9))
}

@Test func testTransverseReverse() {
    let centralMeridian = centralMeridian(zone: 50)
    let cppUTM = GeographicLib.TransverseMercator.UTM().pointee
    var x : Double = .nan
    var y : Double = .nan
    var gamma : Double = .nan
    var k : Double = .nan
    let ypph : CLLocationCoordinate2D = .init(latitude: -31.93980, longitude: 115.96650)
    cppUTM.Forward(centralMeridian, ypph.latitude, ypph.longitude, &x, &y, &gamma, &k)
    
    var lat : Double = .nan
    var lon : Double = .nan

    cppUTM.Reverse(centralMeridian, x, y, &lat, &lon, &gamma, &k)
    let utm = TransverseMercator.UTM
    let reverse = utm.reverse(centralMeridian: centralMeridian, x: x, y: y)
    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: lat, absoluteTolerance: 1e-9))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: lon, absoluteTolerance: 1e-9))
    #expect(reverse.convergence.isApproximatelyEqual(to: gamma, absoluteTolerance: 1e-9))
    #expect(reverse.centralScale.isApproximatelyEqual(to: k, absoluteTolerance: 1e-9))
}
