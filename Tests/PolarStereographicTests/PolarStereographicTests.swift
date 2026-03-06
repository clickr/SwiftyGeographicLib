//
//  PolarStereographicTests.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Testing
@testable import PolarStereographic
import SimpleGeographicLib
import CoreLocation
import Numerics

let cppUPS : GeographicLib.PolarStereographic = GeographicLib.PolarStereographic.UPS().pointee

@Test func testForward() throws {
    let kunlun : CLLocationCoordinate2D = .init(latitude: -80.4174, longitude: 77.1166)
    var x : Double = .nan
    var y : Double = .nan
    var gamma: Double = .nan
    var k: Double = .nan
    cppUPS.Forward(false, kunlun.latitude, kunlun.longitude, &x, &y, &gamma, &k)
    
    let forward = PolarStereographic.UPS.forward(coordinate: kunlun)
    #expect(forward.northp == false)
    #expect(forward.x.isFinite)
    #expect(forward.y.isFinite)
    #expect(forward.convergence.isFinite)
    #expect(forward.centralScale.isFinite)
    
    #expect(forward.x.isApproximatelyEqual(to: x, absoluteTolerance: 1e-9))
    #expect(forward.y.isApproximatelyEqual(to: y, absoluteTolerance: 1e-9))
    #expect(forward.convergence.isApproximatelyEqual(to: gamma, absoluteTolerance: 1e-9))
    #expect(forward.centralScale.isApproximatelyEqual(to: k, absoluteTolerance: 1e-9))
}


/// Test reverse using c++ implementation as reference
@Test func testReverse() throws {
    let kunlun : CLLocationCoordinate2D = .init(latitude: -80.4174, longitude: 77.1166)
    var x : Double = .nan
    var y : Double = .nan
    var gamma: Double = .nan
    var k: Double = .nan
    cppUPS.Forward(false, kunlun.latitude, kunlun.longitude, &x, &y, &gamma, &k)
    
    var lat : Double = .nan
    var lon : Double = .nan
    
    cppUPS.Reverse(false, x, y, &lat, &lon, &gamma, &k)
    let reverse = PolarStereographic.UPS.reverse(northp: false, x: x, y: y)
    #expect(reverse.coordinate.latitude.isFinite)
    #expect(reverse.coordinate.longitude.isFinite)
    #expect(reverse.convergence.isFinite)
    #expect(reverse.centralScale.isFinite)
    
    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: lat, absoluteTolerance: 1e-9))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: lon, absoluteTolerance: 1e-9))
    #expect(reverse.convergence.isApproximatelyEqual(to: gamma, absoluteTolerance: 1e-9))
    #expect(reverse.centralScale.isApproximatelyEqual(to: k, absoluteTolerance: 1e-9))
}

@Test func testForwardUPSAlgorithm() throws {
//    echo -80.4174 77.1166 | GeoConvert -u -p 9
//    s 3039440.641302266 2237746.759453198
    let latitude = -80.4174
    let longitude = 77.1166
    
    let forward = PolarStereographic.UPS.forward(coordinate: .init(latitude: latitude, longitude: longitude))
    
    #expect(forward.northp == false)
    #expect((forward.x + 20e5).isApproximatelyEqual(to: 3039440.641302266, absoluteTolerance: 1e-9))
    #expect((forward.y + 20e5).isApproximatelyEqual(to: 2237746.759453198, absoluteTolerance: 1e-9))
}

@Test func testReverseUPSAlgorithm() throws {
    //    echo -80.4174 77.1166 | GeoConvert -u -p 9
    //    s 3039440.641302266 2237746.759453198
    let x = 3039440.641302266 - 20e5
    let y = 2237746.759453198 - 20e5
    
    let reverse = PolarStereographic.UPS.reverse(northp: false, x: x, y: y)
    
    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: -80.4174, absoluteTolerance: 1e-6))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: 77.1166, absoluteTolerance: 1e-6))
}
