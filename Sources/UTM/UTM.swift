//
//  UTM.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Foundation
import CoreLocation
import TransverseMercator
import Math
import GeographicError
import UTMUPSProtocol
import Constants
import TransverseMercatorInternal
import StaticUTM

public struct UTM : MultiCoordinate {
    /// The cartesian UTM components: hemisphere, zone, easting, and northing.
    public var cartesianCoordinate: UTMCoordinate

    /// The meridian convergence at the point in degrees.
    ///
    /// This is the angle between grid north and true north.
    public var convergence: Double

    /// The scale factor of the projection at the point.
    public var centralScale: Double

    /// The geographic coordinate (latitude and longitude) represented by this UTM coordinate.
    public var geodeticCoordinate: CLLocationCoordinate2D

    // MARK: - MultiCoordinate conformance (forwarded from utmCoordinate)

    public var hemisphere: Hemisphere { cartesianCoordinate.hemisphere }
    public var zone: Int32 { cartesianCoordinate.zone }
    public var easting: Double { cartesianCoordinate.easting }
    public var northing: Double { cartesianCoordinate.northing }
    public var latitude: CLLocationDegrees { geodeticCoordinate.latitude }
    public var longitude: CLLocationDegrees { geodeticCoordinate.longitude }

    /// Init with UTM Coordinates
    ///
    /// Valid UTM zones are in the range [1, 60]
    ///
    /// UTM eastings are allowed to be in the range [0km, 1000km], northings are
    /// allowed to be in in [0km, 9600km] for the northern hemisphere and in
    /// [900km, 10000km] for the southern hemisphere.  However UTM northings
    /// can be continued across the equator.  So the actual limits on the
    /// northings are [-9100km, 9600km] for the "northern" hemisphere and
    /// [900km, 19600km] for the "southern" hemisphere.
    ///
    /// UPS eastings and northings are allowed to be in the range [1200km,
    /// 2800km] in the northern hemisphere and in [700km, 3300km] in the
    /// southern hemisphere.
    ///
    /// These ranges are 100km larger than allowed for the conversions to MGRS.
    /// (100km is the maximum extra padding consistent with eastings remaining
    /// non-negative.)  This allows generous overlaps between zones and UTM and
    /// UPS.  If `mgrslimits = true`, then all the ranges are shrunk by 100km
    /// so that they agree with the stricter MGRS ranges.  No checks are
    /// performed besides these (e.g., to limit the distance outside the
    /// standard zone boundaries).
    /// - Throws: `.invalidZone` if zone not in the range [1, 60]
    /// - Throws: `.eastingOutOfBounds` if easting not in [0m, 1,000,000m], [100,000m, 900,000m] with `mgrsLimits == true`
    /// - Throws: `.northingOutOfBounds` **Northern Hemisphere** northings not in [-9,100,000m, 9,600,000m], [-9,000,000m, 9,500,000m] `mgrsLimits == true`
    /// - Throws: `.northingOutOfBounds` **Southern Hemisphere** northings not in [900,000m, 19,600,000m], [1,000,000m, 19,500,000m] `mgrsLimits == true`
    public init(hemisphere: Hemisphere, zone: Int32, easting: Double, northing: Double, mgrsLimits: Bool = false) throws(UTMError) {
        guard zone > 0 && zone <= 60 else {
            throw .invalidZone(zone: zone)
        }
        let slop = mgrsLimits ? mgrsBuffer : 0
        guard easting >= slop && easting <= UTMConstants.maximumUTMEasting - slop else {
            throw .eastingOutOfBounds(easting: easting)
        }

        if hemisphere == .northern {
            guard northing >= UTMConstants.minimumNorthernUTMNorthing + slop &&
                  northing <= UTMConstants.maximumNorthernUTMNorthing - slop else {
                throw .northingOutOfBounds(northing: northing)
            }
        } else {
            guard northing >= UTMConstants.minimumSouthernUTMNorthing + slop &&
                  northing <= UTMConstants.maximumSouthernUTMNorthing - slop else {
                throw .northingOutOfBounds(northing: northing)
            }
        }

        let lon0 = centralMeridian(zone: Int(zone))
        let x = easting - UTMConstants.utmFalseEasting
        let y = hemisphere == .northern ? northing : northing - UTMConstants.utmNorthShift
        let reverseTM = StaticUTM.reverse(centralMeridian: lon0, x: x, y: y)

        cartesianCoordinate = UTMCoordinate(zone: zone, hemisphere: hemisphere, easting: easting, northing: northing)
        convergence = reverseTM.convergence
        centralScale = reverseTM.centralScale
        geodeticCoordinate = reverseTM.coordinate
    }

    /// Init with latitude and longitude
    ///
    /// UTM eastings are allowed to be in the range [0km, 1000km], northings are
    /// allowed to be in in [0km, 9600km] for the northern hemisphere and in
    /// [900km, 10000km] for the southern hemisphere.  However UTM northings
    /// can be continued across the equator.  So the actual limits on the
    /// northings are [-9100km, 9600km] for the "northern" hemisphere and
    /// [900km, 19600km] for the "southern" hemisphere.
    ///
    /// UPS eastings and northings are allowed to be in the range [1200km,
    /// 2800km] in the northern hemisphere and in [700km, 3300km] in the
    /// southern hemisphere.
    ///
    /// These ranges are 100km larger than allowed for the conversions to MGRS.
    /// (100km is the maximum extra padding consistent with eastings remaining
    /// non-negative.)  This allows generous overlaps between zones and UTM and
    /// UPS.  If `mgrslimits = true`, then all the ranges are shrunk by 100km
    /// so that they agree with the stricter MGRS ranges.  No checks are
    /// performed besides these (e.g., to limit the distance outside the
    /// standard zone boundaries).
    /// - Throws: `CoordinateError.eastingOutOfBounds` if self.easting not in [0m, 1,000,000m], [100,000m, 900,000m] with `mgrsLimits == true`
    /// - Throws: `CoordinateError.northingOutOfBounds` **Northern Hemisphere** self.northing not in [-9,100,000m, 9,600,000m], [-9,000,000m, 9,500,000m] `mgrsLimits == true`
    /// - Throws: `CoordinateError.northingOutOfBounds` **Southern Hemisphere** self.northing not in [900,000m, 19,600,000m], [1,000,000m, 19,500,000m] `mgrsLimits == true`
    /// - Throws:  `CoordinateError.illegalLatitude` if latitude not in -90&deg;... 90&deg;
    public init(latitude: Double, longitude: Double, zoneSpec: ZoneSpec = .utm, mgrsLimits: Bool = false) throws {

        // This will throw if latitude is not legal
        let standardZone = try UTM.standardZone(latitude: latitude, longitude: longitude, zoneSpec: zoneSpec)
        let lon0 = centralMeridian(zone: Int(standardZone))

        let forwardTM = StaticUTM.forward(centralMeridian: lon0, geodeticCoordinate: .init(latitude: latitude, longitude: longitude))

        let e = forwardTM.x + UTMConstants.utmFalseEasting
        let n = forwardTM.y + (latitude < 0 ? UTMConstants.utmNorthShift : 0)
        let h: Hemisphere = latitude >= 0 ? .northern : .southern
        let slop = mgrsLimits ? mgrsBuffer : 0

        guard e >= slop && e <= UTMConstants.maximumUTMEasting - slop else {
            throw CoordinateError.eastingOutOfBounds(easting: e)
        }
        if h == .northern {
            guard n >= UTMConstants.minimumNorthernUTMNorthing + slop else {
                throw CoordinateError.northingOutOfBounds(northing: n)
            }
        } else {
            guard n >= UTMConstants.minimumSouthernUTMNorthing + slop &&
                  n <= UTMConstants.maximumSouthernUTMNorthing - slop else {
                throw CoordinateError.northingOutOfBounds(northing: n)
            }
        }

        cartesianCoordinate = UTMCoordinate(zone: standardZone, hemisphere: h, easting: e, northing: n)
        convergence = forwardTM.convergence
        centralScale = forwardTM.centralScale
        geodeticCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// The Standard Zone
    /// - Parameters:
    ///     - latitude: location Latitude
    ///     - longitude: location Longitude
    ///     - zoneSpec: ```ZoneSpec```
    static func standardZone(latitude: Double, longitude: Double, zoneSpec: ZoneSpec = .utm) throws -> Int32 {
        guard latitude >= -90 && latitude <= 90 else {
            throw CoordinateError.illegalLatitude(latitude: latitude)
        }
        if zoneSpec == .utm && (latitude >= -80 && latitude < 84) {
            let ilon = Int(floor(angNormalize(longitude)))
            let zone = (ilon + 186)/6;
            let band = band(latitude: latitude)
            if band == 7 && zone == 31 && ilon >= 3 {
                return 32
            } else if band == 9 && ilon >= 0 && ilon < 42 {
                return Int32(2 * ((ilon + 183)/12) + 1)
            }
            return Int32(zone)
        }
        return -4;//GeographicLib.UTMUPS.StandardZone(latitude, longitude, zoneSpec.rawValue)
    }
}
