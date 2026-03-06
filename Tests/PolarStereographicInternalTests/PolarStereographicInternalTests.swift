//
//  PolarStereographicInternalTests.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Testing
@testable import PolarStereographicInternal
import SimpleGeographicLib

let ups : GeographicLib.PolarStereographic = GeographicLib.PolarStereographic.UPS().pointee

@Test func test_PolarStereographicInternal() throws {
    let polarStereographicInternal = polarStereographicInternal(flattening: ups.Flattening())
    #expect(polarStereographicInternal.e2 == ups._e2)
    #expect(polarStereographicInternal.e2m == ups._e2m)
    #expect(polarStereographicInternal.es == ups._es)
    #expect(polarStereographicInternal.c == ups._c)
}
