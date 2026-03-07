// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import CoreLocation
import ComplexModule
import TransverseMercatorInternal
import Math

public enum TransverseMercatorError: Error, Equatable {
    case equatorialRadiusNotPositive
    case polarSemiAxisNotPositive
    case scaleNotPositive
    case illegalLatitude(latitude: Double)
}

/// A transverse Mercator projection implementation.
///
/// This struct provides functionality for converting between geographic coordinates
/// (latitude and longitude) and transverse Mercator projection coordinates
/// (easting and northing).
///
/// The transverse Mercator projection is a conformal map projection that
/// stretches the sphere along a central meridian. This implementation uses
/// Krüger's method as described in:
/// - L. Krüger, "Konforme Abbildung des Erdellipsoids in der Ebene" (1912)
/// - C. F. F. Karney, "Transverse Mercator with an accuracy of a few
///   nanometers," J. Geodesy 85(8), 475--485 (2011)
///
/// The projection achieves accuracy of about 5 nanometers within 35 degrees
/// of the central meridian, with a convergence error of about 2 × 10⁻¹⁵ arcseconds
/// and relative scale error of about 6 × 10⁻¹².
///
/// There is a singularity in the projection at latitude 0° and longitude offset
/// of approximately ±82.6° from the central meridian. Beyond this point, the
/// series ceases to converge and results will be unreliable.
///
/// - Note: This projection does not include false easting or false northing.
///   These can be added by the caller if needed (as done in UTMUPS).
///
/// ## Example
/// ```swift
/// let utm = TransverseMercator.UTM
/// let coord = CLLocationCoordinate2D(latitude: 45.0, longitude: -75.0)
/// let result = utm.forward(centralMeridian: -75, coordinate2D: coord)
/// print("Easting: \\(result.x), Northing: \\(result.y)")
/// ```
public struct TransverseMercator : Sendable{
    public static let UTM : TransverseMercator = try! TransverseMercator(
        equatorialRadius: 6378137.0,
        flattening: 1.0 / 298.257223563,
        scaleFactor: 0.9996)
    public var flattening: Double { f }
    public var equatorialRadius: Double { a }
    public var centralScale: Double { k0 }
    internal let a: Double
    internal let f: Double
    internal let k0: Double
    internal let e2: Double
    internal let es: Double
    internal let e2m: Double
    internal let c: Double
    internal let n: Double
    internal let b1: Double
    internal let a1: Double
    internal let alp: [Double]
    internal let bet: [Double]
    public init(equatorialRadius: Double, flattening: Double, scaleFactor: Double) throws (TransverseMercatorError) {
        guard equatorialRadius.isFinite, equatorialRadius > 0 else {
            throw .equatorialRadiusNotPositive
        }
        guard flattening.isFinite, flattening < 1 else {
            throw .polarSemiAxisNotPositive
        }
        guard scaleFactor.isFinite, scaleFactor > 0 else {
            throw .scaleNotPositive
        }
        
        (self.n,
         self.a1,
         self.b1,
         self.c,
         self.e2,
         self.e2m,
         self.es,
         self.alp,
         self.bet) = computeInternlTransverseMercator(flattening: flattening,
                                                      equatorialRadius: equatorialRadius)
        self.a = equatorialRadius
        self.f = flattening
        self.k0 = scaleFactor
    }
    
    
    
    /// Forward projection, from geographic to transverse Mercator.
    ///
    /// This function converts a geographic coordinate (latitude and longitude) to
    /// transverse Mercator projection coordinates (easting, northing).
    ///
    /// - Parameters:
    ///   - centralMeridian: The central meridian of the projection in degrees.
    ///   - latitude: The latitude of the point in degrees.
    ///   - longitude: The longitude of the point in degrees.
    ///
    /// - Returns: A tuple containing:
    ///   - x: The easting of the point in meters.
    ///   - y: The northing of the point in meters.
    ///   - convergence: The meridian convergence at the point in degrees.
    ///   - scale: The scale factor of the projection at the point.
    ///
    /// - Note: This is a convenience overload that accepts separate latitude and
    ///   longitude parameters instead of a `CLLocationCoordinate2D`.
    ///
    /// - SeeAlso: ``forward(centralMeridian:coordinate2D:)-9d7s0``
    public func forward(centralMeridian: Double, latitude: Double, longitude: Double) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
        return self.forward(centralMeridian: centralMeridian, geodeticCoordinate: .init(latitude: latitude, longitude: longitude))
    }
}



