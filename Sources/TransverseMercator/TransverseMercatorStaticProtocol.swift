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

/// A protocol for defining static transverse Mercator projections.
///
/// Conforming types supply ellipsoid parameters and pre-computed Krüger series
/// coefficients as `static let` properties. The compiler can constant-fold these
/// values, eliminating the setup cost that the dynamic ``TransverseMercator``
/// type pays at initialisation.
///
/// The bundled ``StaticUTM`` type wraps `InternalUTM` (the WGS84 conformance)
/// and is ready to use out of the box. To project on a different ellipsoid,
/// create your own conforming type.
///
/// ## Performance
///
/// Because every requirement is a `static let`, the forward and reverse
/// projection methods supplied by the default implementations can inline the
/// constant values directly, avoiding dictionary lookups or stored-property
/// access through an instance. This makes the static path measurably faster
/// than the equivalent ``TransverseMercator`` instance path for repeated
/// projections on the same ellipsoid.
///
/// ## Default Implementations
///
/// The protocol provides complete default implementations of the projection
/// methods. Conformers should **not** re-implement these — the Krüger series
/// logic is non-trivial:
///
/// - ``forward(centralMeridian:geodeticCoordinate:)``
/// - ``forward(centralMeridian:latitude:longitude:)``
/// - ``reverse(centralMeridian:x:y:)``
///
/// ## Creating a Conformance
///
/// Use ``computeInternalTransverseMercator(flattening:equatorialRadius:)`` to
/// derive the coefficients, then store each field as a `static let`:
///
/// ```swift
/// struct MyEllipsoid: TransverseMercatorStaticProtocol {
///     static let EquatorialRadius: Double = 6378137.0
///     static let Flattening: Double = 1.0 / 298.257223563
///     static let centralScale: Double = 0.9996
///
///     private static let tm = computeInternalTransverseMercator(
///         flattening: Flattening, equatorialRadius: EquatorialRadius)
///
///     static let _e2:  Double   = tm.e2
///     static let _es:  Double   = tm.es
///     static let _e2m: Double   = tm.e2m
///     static let _c:   Double   = tm.c
///     static let _n:   Double   = tm.n
///     static let _b1:  Double   = tm.b1
///     static let _a1:  Double   = tm.a1
///     static let _alp: [Double] = tm.alp
///     static let _bet: [Double] = tm.bet
/// }
///
/// // Use directly:
/// let fwd = MyEllipsoid.forward(centralMeridian: lon0, latitude: lat, longitude: lon)
///
/// // Or wrap in a cleaner public type like StaticUTM does:
/// public struct MyProjection {
///     public static func forward(...) { MyEllipsoid.forward(...) }
/// }
/// ```
public protocol TransverseMercatorStaticProtocol {
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



