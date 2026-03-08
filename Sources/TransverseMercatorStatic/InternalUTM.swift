//
//  WGS84.swift
//  SwiftGeoLib
//
//  Created by David Hart on 6/3/2026.
//


import Foundation
import TransverseMercatorInternal
import CoreLocation
import Math

public struct InternalUTM : TransverseMercatorStaticInternal {
    public static let EquatorialRadius : Double = 6378137.0
    public static let Flattening : Double = 1.0 / 298.257223563
    public static let centralScale : Double = 0.9996
    public static let _e2 : Double = utmInt.e2
    public static let _es : Double = utmInt.es
    public static let _e2m : Double = utmInt.e2m
    public static let _c : Double = utmInt.c
    public static let _n : Double = utmInt.n
    public static let _b1 : Double = utmInt.b1
    public static let _a1 : Double = utmInt.a1
    public static let _alp : [Double] = utmInt.alp
    public static let _bet : [Double] = utmInt.bet
    static let utmInt = computeInternlTransverseMercatorValues(
        flattening: Flattening,
        equatorialRadius: EquatorialRadius
    )
}

public func computeInternlTransverseMercatorValues(flattening: Double, equatorialRadius: Double) -> (
    n: Double,
    a1: Double,
    b1: Double,
    c: Double,
    e2: Double,
    e2m: Double,
    es: Double,
    alp: [Double],
    bet: [Double]) {
    return TransverseMercatorInternal.computeInternalTransverseMercator(flattening: flattening, equatorialRadius: equatorialRadius)
}
