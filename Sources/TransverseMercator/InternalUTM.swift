//
//  WGS84.swift
//  SwiftGeoLib
//
//  Created by David Hart on 6/3/2026.
//


import Foundation
import CoreLocation
import Math

struct InternalUTM : TransverseMercatorStaticProtocol {
    static let EquatorialRadius : Double = 6378137.0
    static let Flattening : Double = 1.0 / 298.257223563
    static let centralScale : Double = 0.9996
    static let _e2 : Double = utmInt.e2
    static let _es : Double = utmInt.es
    static let _e2m : Double = utmInt.e2m
    static let _c : Double = utmInt.c
    static let _n : Double = utmInt.n
    static let _b1 : Double = utmInt.b1
    static let _a1 : Double = utmInt.a1
    static let _alp : [Double] = utmInt.alp
    static let _bet : [Double] = utmInt.bet
    static let utmInt = computeInternalTransverseMercator(
        flattening: Flattening,
        equatorialRadius: EquatorialRadius
    )
}
