/// A single contour line of constant magnetic field value.
///
/// Each contour line is an ordered sequence of coordinates forming a
/// polyline. For open contours (those that exit the bounding region),
/// the first and last points lie on the boundary. For closed contours,
/// the first and last points coincide.
public struct ContourLine: Sendable {
    /// The constant field value along this contour.
    ///
    /// For declination contours this is degrees east of true north.
    /// For inclination contours this is degrees below horizontal.
    /// For intensity contours this is nanotesla.
    public let value: Double

    /// Ordered coordinates forming the polyline.
    public let coordinates: [(latitude: Double, longitude: Double)]

    /// Creates a contour line with the given value and coordinates.
    public init(value: Double, coordinates: [(latitude: Double, longitude: Double)]) {
        self.value = value
        self.coordinates = coordinates
    }
}

#if canImport(CoreLocation)
import CoreLocation

extension ContourLine {
    /// The contour as an array of `CLLocationCoordinate2D`, suitable
    /// for use with MapKit's `MapPolyline`.
    public var clLocationCoordinates: [CLLocationCoordinate2D] {
        coordinates.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }
}
#endif
