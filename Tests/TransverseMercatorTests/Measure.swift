//
//  Measure.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import XCTest
@testable import TransverseMercator
@testable import TransverseMercatorInternal
@testable import TransverseMercatorStatic
import Math
@testable import SimpleGeographicLib
import CoreLocation

final class MeasureTests: XCTestCase {
    let utmSwift = TransverseMercator.UTM
    func testTransverseMercator() throws {
        let lon0 = centralMeridian(zone: 50)
        let geodeticCoordinate = CLLocationCoordinate2D(latitude: 31.93980, longitude: 115.96650)
        measure {
            for _ in 0..<10000 {
                _ = utmSwift.forward(centralMeridian: lon0, geodeticCoordinate: geodeticCoordinate)
            }
        }
    }
    let utmCPP = GeographicLib.TransverseMercator.UTM().pointee
    func testCPPTransverseMercator() throws {
        let lon0 = centralMeridian(zone: 50)
        measure {
            for _ in 0..<10000 {
                var x : Double = .nan
                var y : Double = .nan
                var gamma : Double = .nan
                var k : Double = .nan
                utmCPP.Forward(lon0, 31.93980, 115.96650, &x, &y, &gamma, &k)
            }
        }
    }
    func testTransverseMercator2() throws {
        let lon0 = centralMeridian(zone: 50)
        let geodeticCoordinate = CLLocationCoordinate2D(latitude: 31.93980, longitude: 115.96650)
        measure {
            for _ in 0..<10000 {
                _ = InternalUTM.forward(centralMeridian: lon0, geodeticCoordinate: geodeticCoordinate)
            }
        }
    }
    func testTransverseMercatorReverse() throws {
        let lon0 = centralMeridian(zone: 50)
        measure {
            for _ in 0..<10000 {
                _ = utmSwift.reverse(centralMeridian: lon0, x: 1000000, y: 0)
            }
        }
    }
    func testStaticUTMForward() throws {
        let lon0 = centralMeridian(zone: 50)
        let geodeticCoordinate = CLLocationCoordinate2D(latitude: 31.93980, longitude: 115.96650)
        measure {
            for _ in 0..<10000 {
                _ = StaticUTM.forward(centralMeridian: lon0, geodeticCoordinate: geodeticCoordinate)
            }
        }
    }
    func testWGS84Reverse() throws {
        measure {
            for _ in 0..<10000 {
                _ = InternalUTM.reverse(centralMeridian: 0, x: 1000000, y: 0)
            }
        }
    }
}
