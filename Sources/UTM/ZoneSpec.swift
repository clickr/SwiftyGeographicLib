//
//  ZoneSpec.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//
import Foundation

/// Specifies how a UTM zone should be selected when converting from
/// latitude/longitude.
///
/// Mirrors the C++ `GeographicLib::UTMUPS` zone-selection constants.
public enum ZoneSpec : OptionSet {
    /// The raw integer value corresponding to the C++ UTMUPS zone constants.
    public var rawValue: Int32 {
        switch self {
        case .invalid:
            return -4
        case .match:
            return -3
        case .utm:
            return -2
        case .standard:
            return -1
        case .ups:
            return 0
        case .manual(zone: let zone):
            return zone
        }
    }
    
    public typealias RawValue = Int32
    
    /// - Parameters:
    ///     - rawValue: an Int32 corresponding to:
    ///         - GeographicLib::UTMUPS::INVALID (-4)
    ///         - GeographicLib::UTMUPS::MATCH (-3)
    ///         - GeographicLib::UTMUPS::UTM (-2)
    ///         - GeographicLib::UTMUPS::STANDARD (-1)
    ///         - GeographicLib::UTMUPS::UPS (0)
    ///         - a value for a UTM zone in the range [1,60]
    ///
    ///       A parameter falling outside this scope will default to .invalid

    public init(rawValue: Int32) {
        if rawValue > 0 && rawValue <= 60 {
            self = .manual(zone: rawValue)
        }
        switch rawValue {
        case -3:
            self = .match
        case -2:
            self = .utm
        case -1:
            self = .standard
        case 0:
            self = .ups
        default:
            self = .invalid
        }
    }
    /// A marker for an undefined or invalid zone.  Equivalent to .nan
    case invalid
    /// If a coordinate already include zone information (e.g., it is an MGRS
    /// coordinate), use that, otherwise apply the ```ZoneSpec.standard``` rules.
    case match
    /// Apply the standard rules for UTM zone assigment extending the UTM zone
    /// to each pole to give a zone number in [1, 60].  For example, use UTM
    /// zone 38 for longitude in [42&deg;, 48&deg;).  The rules include the
    /// Norway and Svalbard exceptions.
    case utm
    /// Apply the standard rules for zone assignment to give a zone number in
    /// [0, 60].  If the latitude is not in [&minus;80&deg;, 84&deg;), then
    /// use UTMUPS::UPS = 0, otherwise apply the rules for UTMUPS::UTM.  The
    /// tests on latitudes and longitudes are all closed on the lower end open
    /// on the upper.  Thus for UTM zone 38, latitude is in [&minus;80&deg;,
    /// 84&deg;) and longitude is in [42&deg;, 48&deg;).
    case standard
    /// USe UPS Coordinates
    case ups
    /// Specify a zone in the range [1, 60]
    case manual(zone: Int32)
}
