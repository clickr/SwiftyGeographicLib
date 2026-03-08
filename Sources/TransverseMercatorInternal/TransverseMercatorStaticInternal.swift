//
//  TransverseMercatorStatic.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import CoreLocation
import ComplexModule
import RealModule
import Math

/// Protocol for specifiying static representations of the TransverseMercator projection
///
/// ## Performance
/// 
/// ## Default Implementations
/// - warning: Complicated logic. Recommend do not re-implement
/// - Forward(centralMeridian:coordinate2d)
/// - Forward(centralMeridian:latitude:longitude)
/// - Reverse(centralMeridian:x:y)
///
/// ## Canonical Conformance
/// ```swift
///public struct WGS84 : TransverseMercatorStatic {
///    public static let EquatorialRadius : Double = 6378137.0
///    public static let Flattening : Double = 1.0 / 298.257223563
///    public static let CentralScale : Double = 0.9996
///    public static let _e2 : Double = utmInt.e2
///    public static let _es : Double = utmInt.es
///    public static let _e2m : Double = utmInt.e2m
///    public static let _c : Double = utmInt.c
///    public static let _n : Double = utmInt.n
///    public static let _b1 : Double = utmInt.b1
///    public static let _a1 : Double = utmInt.a1
///    public static let _alp : [Double] = utmInt.alp
///    public static let _bet : [Double] = utmInt.bet
///        // Get our internal values
///    static let utmInt = computeInternlTransverseMercator(
///        flattening: Flattening,
///        equatorialRadius: EquatorialRadius
///    )
///}
///```
public protocol TransverseMercatorStaticInternal {
    static var EquatorialRadius: Double { get }
    static var Flattening: Double { get }
    static var centralScale: Double { get }
    static var _e2: Double { get }
    static var _es: Double { get }
    static var _e2m: Double { get }
    static var _c: Double { get }
    static var _n: Double { get }
    static var _b1: Double { get }
    static var _a1: Double { get }
    static var _alp: [Double] { get }
    static var _bet: [Double] { get }
}



