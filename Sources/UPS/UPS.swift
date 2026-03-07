//
//  UPS.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Foundation
import UTMUPSProtocol
import CoreLocation
import PolarStereographic
import GeographicError
import Constants

/// Universal Polar Screen (UPS) coordinate representation.
///
/// UPS is used to represent coordinates in the polar regions where UTM is not
/// applicable—specifically north of 84° N or south of 80° S latitude.
///
/// The UPS coordinate system uses a polar stereographic projection centered
/// on the appropriate pole. Coordinates are expressed as easting and northing
/// in meters, similar to UTM but without zones.
///
/// ## Example
/// ```swift
/// // Create UPS coordinate from latitude/longitude
/// let ups = try UPS(latitude: 85.0, longitude: 45.0)
/// print("Easting: \\(ups.easting), Northing: \\(ups.northing)")
///
/// // Convert back to latitude/longitude
/// let reversed = try UPS(hemisphere: .northern, easting: ups.easting, northing: ups.northing)
/// print("Latitude: \\(reversed.latitude), Longitude: \\(reversed.longitude)")
/// ```
///
/// - Note: UPS coordinates include a false easting and false northing of 2,000,000 meters
///   to avoid negative coordinates. These must be subtracted to get the actual
///   polar stereographic coordinates.
public struct UPS : MultiCoordinate {
    /// The hemisphere (northern or southern) of the coordinate.
    public var hemisphere: Hemisphere
    
    /// The easting coordinate in meters.
    ///
    /// This includes a false easting of 2,000,000 meters.
    public var easting: Double
    
    /// The northing coordinate in meters.
    ///
    /// This includes a false northing of 2,000,000 meters.
    public var northing: Double
    
    /// The meridian convergence at the point in degrees.
    ///
    /// This is the angle between grid north and true north.
    public var convergence: Double
    
    /// The scale factor of the projection at the point.
    public var centralScale: Double
    
    /// The geographic coordinate (latitude and longitude) represented by this UPS coordinate.
    public var geodeticCoordinate: CLLocationCoordinate2D
    
    /// Creates a UPS coordinate from a latitude and longitude.
    ///
    /// This initializer performs the forward projection from geographic coordinates
    /// to UPS coordinates.
    ///
    /// - Parameters:
    ///   - latitude: The latitude in degrees. Must be outside the UTM zone
    ///     (>= 83.5° N or < -79.5° S).
    ///   - longitude: The longitude in degrees.
    ///
    /// - Throws: `UPSError` if the latitude is within the UTM zone or invalid.
    public init(latitude: Double, longitude: Double) throws(UPSError) {
        guard latitude >= -90.0 && latitude <= 90.0 else {
            throw .invalidLatitude(latitude: latitude)
        }
        guard latitude >= 83.5 || latitude < -79.5 else {
            throw .latitudeOutOfBounds(latitude: latitude)
        }
        
        let forward = PolarStereographic.UPS.forward(coordinate: .init(latitude: latitude, longitude: longitude))
        
        self.easting = forward.x + 20e5
        self.northing = forward.y + 20e5
        self.convergence = forward.convergence
        self.centralScale = forward.centralScale
        self.geodeticCoordinate = .init(latitude: latitude, longitude: longitude)
        self.hemisphere = forward.northp ? .northern : .southern
    }
    
    /// Creates a UPS coordinate from easting and northing.
    ///
    /// This initializer performs the reverse projection from UPS coordinates
    /// to geographic coordinates.
    ///
    /// - Parameters:
    ///   - hemisphere: The hemisphere (northern or southern).
    ///   - easting: The easting coordinate in meters (including false easting).
    ///   - northing: The northing coordinate in meters (including false northing).
    ///
    /// - Throws: `CoordinateError` if the easting or northing are outside valid bounds.
    public init(hemisphere: Hemisphere, easting: Double, northing: Double) throws {
        if hemisphere == .northern {
            guard easting >= UPSConstants.minUPSNorthernCoordinate &&
                    easting <= UPSConstants.maxUPSNorthernCoordinate else {
                throw CoordinateError.eastingOutOfBounds(easting: easting)
            }
            guard northing >= UPSConstants.minUPSNorthernCoordinate &&
                    northing <= UPSConstants.maxUPSNorthernCoordinate else {
                throw CoordinateError.northingOutOfBounds(northing: northing)
            }
        } else {
            guard easting >= UPSConstants.minUPSSouthernCoordinate &&
                    easting <= UPSConstants.maxUPSSouthernCoordinate else {
                throw CoordinateError.eastingOutOfBounds(easting: easting)
            }
            guard northing >= UPSConstants.minUPSSouthernCoordinate &&
                    northing <= UPSConstants.maxUPSSouthernCoordinate else {
                throw CoordinateError.northingOutOfBounds(northing: northing)
            }
        }
        self.hemisphere = hemisphere
        self.easting = easting
        self.northing = northing
        let reverse = PolarStereographic.UPS.reverse(northp: hemisphere == .northern,
                                                     x: easting - 20e5,
                                                     y: northing - 20e5)
        
        self.geodeticCoordinate = .init(latitude: reverse.coordinate.latitude, longitude: reverse.coordinate.longitude)
        self.centralScale = reverse.centralScale
        self.convergence = reverse.convergence
    }
    /// The latitude in degrees.
    public var latitude : CLLocationDegrees { return geodeticCoordinate.latitude }
    
    /// The longitude in degrees.
    public var longitude : CLLocationDegrees { return geodeticCoordinate.longitude }
}
