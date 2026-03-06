//
//  PolarStereographic.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//
import Foundation
import Math
import PolarStereographicInternal
import CoreLocation

/// A polar stereographic projection implementation.
///
/// This struct provides functionality for converting between geographic coordinates
/// (latitude and longitude) and polar stereographic projection coordinates
/// (easting and northing).
///
/// The polar stereographic projection is a conformal map projection that
/// represents the earth as a plane viewed from one of the poles. It is commonly
/// used for mapping polar regions.
///
/// The projection is defined by:
/// - A central scale factor at the pole
/// - An ellipsoid (defined by equatorial radius and flattening)
///
/// - Note: This projection does not include false easting or false northing.
///   These can be added by the caller if needed (as done in UTMUPS).
///
/// ## Example
/// ```swift
/// let ups = PolarStereographic.UPS
/// let coord = CLLocationCoordinate2D(latitude: 80.0, longitude: 0.0)
/// let result = ups.forward(coordinate: coord)
/// print("Easting: \\(result.x), Northing: \\(result.y)")
/// ```
public struct PolarStereographic: Sendable {
    /// The equatorial radius of the ellipsoid in meters.
    public let equatorialRadius : Double
    /// The flattening of the ellipsoid.
    public let flattening : Double
    /// The central scale factor at the pole.
    public let centralScale : Double

    private let e2: Double
    private let es: Double
    private let e2m: Double
    private let c: Double
    
    /// Creates a new polar stereographic projection.
    ///
    /// - Parameters:
    ///   - equatorialRadius: The equatorial radius of the ellipsoid in meters.
    ///   - flattening: The flattening of the ellipsoid.
    ///   - centralScaleFactor: The central scale factor at the pole.
    public init(equatorialRadius: Double, flattening: Double, centralScaleFactor: Double) {
        self.equatorialRadius = equatorialRadius
        self.flattening = flattening
        self.centralScale = centralScaleFactor

        (e2, es, e2m, c) = polarStereographicInternal(flattening: flattening)
    }
    
    /// Swift implementation of GeographicLib::PolarStereographic::Forward
    /// 
    /// - Parameter coordinate: The geographic coordinate to convert.
    /// - Returns: A tuple containing:
    ///   - northp: Whether the latitude is in the northern hemisphere.
    ///   - x: The easting of the point in meters.
    ///   - y: The northing of the point in meters.
    ///   - convergence: The meridian convergence at the point in degrees.
    ///   - centralScale: The scale factor of the projection at the point.
    public func forward(coordinate: CLLocationCoordinate2D) -> (northp: Bool, x: Double, y: Double, convergence: Double, centralScale: Double) {
        var lat = latFix(coordinate.latitude)
        let northp = lat >= 0
        if !northp {
            lat = -lat
        }
        
        let tau = tand(lat)
        let secphi = hypot(1, tau)
        let taup = taupf(tau, self.es)
        var rho = hypot(1, taup) + abs(taup)
        if taup >= 0 {
            rho = lat != qd ? 1/rho : 0
        }
        rho *= 2 * self.centralScale * self.equatorialRadius / self.c
        
        let scaleFactor: Double
        if lat != qd {
            scaleFactor = (rho / self.equatorialRadius) * secphi * sqrt(self.e2m + self.e2 / sq(secphi))
        } else {
            scaleFactor = self.centralScale
        }
        
        let (sinLon, cosLon) = sincosd(degrees: coordinate.longitude)
        let x = sinLon * rho
        let y = northp ? -cosLon * rho : cosLon * rho
        let convergence = northp ? coordinate.longitude : -coordinate.longitude
        
        return (northp: northp, x: x, y: y, convergence: angNormalize(convergence), centralScale: scaleFactor)
    }
    
    /// Reverse projection, from polar stereographic to geographic.
    ///
    /// This function converts polar stereographic projection coordinates (easting,
    /// northing) back to geographic coordinates (latitude, longitude).
    ///
    /// - Parameters:
    ///   - northp: Whether the latitude is in the northern hemisphere.
    ///   - x: The easting of the point in meters.
    ///   - y: The northing of the point in meters.
    ///
    /// - Returns: A tuple containing:
    ///   - coordinate: The geographic coordinate (latitude and longitude in degrees).
    ///   - convergence: The meridian convergence at the point in degrees.
    ///   - centralScale: The scale factor of the projection at the point.
    public func reverse(northp: Bool, x: Double, y: Double) -> (coordinate: CLLocationCoordinate2D, convergence: Double, centralScale: Double) {
        let rho = hypot(x, y)
        let t = rho != 0 ? rho / (2 * self.centralScale * self.equatorialRadius / self.c) : sq(Double.ulpOfOne)
        let taup = (1 / t - t) / 2
        let tau = tauf(taup, self.es)
        let secphi = hypot(1, tau)
        
        let scaleFactor: Double
        if rho != 0 {
            scaleFactor = (rho / self.equatorialRadius) * secphi * sqrt(self.e2m + self.e2 / sq(secphi))
        } else {
            scaleFactor = self.centralScale
        }
        
        let lat = northp ? atand(tau) : -1 * atand(tau)
        let lon = atan2d(x, northp ? -y : y)
        let convergence = northp ? lon : -lon
        
        return (coordinate: .init(latitude: lat, longitude: lon), convergence: angNormalize(convergence), centralScale: scaleFactor)
    }
    
    /// The Universal Polar Screen (UPS) projection using WGS84 ellipsoid.
    ///
    /// This is a convenience static property that creates a PolarStereographic
    /// projection with WGS84 parameters and the standard UPS scale factor (0.994).
    public static let UPS: PolarStereographic = PolarStereographic(
        equatorialRadius: 6378137.0,
        flattening: 1.0 / 298.257223563,
        centralScaleFactor: 0.994)
}
