/// A geographic bounding box defined by latitude and longitude ranges.
///
/// Both latitude and longitude are specified in degrees. Latitude must be
/// in the range −90 to 90; longitude must be in −180 to 180. The minimum
/// values must not exceed the corresponding maximum values.
///
/// > Note: Regions that cross the antimeridian (180°/−180°) are not
/// > supported. Split such regions into two separate bounds.
public struct LatLonBounds: Sendable {
    /// Southern boundary in degrees (−90 to 90).
    public let minLatitude: Double
    /// Northern boundary in degrees (−90 to 90).
    public let maxLatitude: Double
    /// Western boundary in degrees (−180 to 180).
    public let minLongitude: Double
    /// Eastern boundary in degrees (−180 to 180).
    public let maxLongitude: Double

    /// Creates a geographic bounding box.
    ///
    /// - Parameters:
    ///   - minLatitude: Southern boundary in degrees.
    ///   - maxLatitude: Northern boundary in degrees.
    ///   - minLongitude: Western boundary in degrees.
    ///   - maxLongitude: Eastern boundary in degrees.
    public init(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) {
        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }
}

#if canImport(MapKit)
import MapKit

extension LatLonBounds {
    /// Creates a bounding box from a MapKit coordinate region.
    public init(_ region: MKCoordinateRegion) {
        let centre = region.center
        let span = region.span
        self.init(
            minLatitude: centre.latitude - span.latitudeDelta / 2,
            maxLatitude: centre.latitude + span.latitudeDelta / 2,
            minLongitude: centre.longitude - span.longitudeDelta / 2,
            maxLongitude: centre.longitude + span.longitudeDelta / 2
        )
    }
}
#endif
