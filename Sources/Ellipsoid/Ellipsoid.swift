/// A reference ellipsoid defined by its equatorial radius and flattening.
///
/// An ellipsoid models the Earth as an oblate spheroid characterised by two
/// geometric parameters: the semi-major axis *a* (equatorial radius) and the
/// flattening *f*.  Predefined constants are provided for the historically
/// significant World Geodetic System series and other widely used ellipsoids.
///
/// ```swift
/// let tm = try TransverseMercator(ellipsoid: .wgs72, scaleFactor: 0.9996)
/// ```
public struct Ellipsoid: Sendable, Equatable {

    /// Semi-major axis (equatorial radius) in metres.
    public let equatorialRadius: Double

    /// Flattening of the ellipsoid (*f*).
    public let flattening: Double

    /// Creates an ellipsoid from explicit geometric parameters.
    ///
    /// - Parameters:
    ///   - equatorialRadius: Semi-major axis *a* in metres.
    ///   - flattening: Flattening *f*  (not inverse flattening).
    public init(equatorialRadius: Double, flattening: Double) {
        self.equatorialRadius = equatorialRadius
        self.flattening = flattening
    }

    // MARK: - WGS Series

    /// WGS 84 — the current World Geodetic System (1984).
    ///
    /// Standard reference ellipsoid for GPS and modern geospatial applications.
    /// - SeeAlso: ``TransverseMercator/UTM`` which uses this ellipsoid with
    ///   scale factor 0.9996.
    public static let wgs84 = Ellipsoid(
        equatorialRadius: 6_378_137.0,
        flattening: 1.0 / 298.257223563)

    /// WGS 72 — third World Geodetic System (1972).
    ///
    /// Used extensively for GPS predecessor systems and satellite tracking;
    /// remained the standard for GPS until replaced by WGS 84 in 1987.
    public static let wgs72 = Ellipsoid(
        equatorialRadius: 6_378_135.0,
        flattening: 1.0 / 298.26)

    /// WGS 66 — second World Geodetic System (1966).
    ///
    /// Refined the first WGS using additional satellite and surface-gravity data.
    public static let wgs66 = Ellipsoid(
        equatorialRadius: 6_378_145.0,
        flattening: 1.0 / 298.25)

    /// WGS 60 — the first World Geodetic System (1960).
    ///
    /// Developed by the U.S. Department of Defense combining surface gravity,
    /// astro-geodetic data, and early satellite observations.
    public static let wgs60 = Ellipsoid(
        equatorialRadius: 6_378_165.0,
        flattening: 1.0 / 298.3)

    // MARK: - Other Reference Ellipsoids

    /// GRS 80 — Geodetic Reference System 1980.
    ///
    /// Adopted by the IUGG in 1979 and used as the basis for NAD 83.
    /// Shares the same semi-major axis as WGS 84; the two ellipsoids differ
    /// only in the 9th significant digit of the inverse flattening (semi-minor
    /// axis differs by approximately 0.1 mm).
    public static let grs80 = Ellipsoid(
        equatorialRadius: 6_378_137.0,
        flattening: 1.0 / 298.257222101)

    /// International 1924 (Hayford) ellipsoid.
    ///
    /// Adopted at the 1924 IUGG General Assembly; used as the basis for the
    /// European Datum 1950 (ED50) and many national datums worldwide until
    /// the 1980s.
    public static let international1924 = Ellipsoid(
        equatorialRadius: 6_378_388.0,
        flattening: 1.0 / 297.0)

    /// Clarke 1866 ellipsoid.
    ///
    /// Defined by Alexander Ross Clarke using meridian-arc measurements in
    /// western Europe, Russia, India, South Africa, and Peru. Used as the
    /// basis for the original North American Datum (1901) and NAD 27.
    public static let clarke1866 = Ellipsoid(
        equatorialRadius: 6_378_206.4,
        flattening: 1.0 / 294.978698213898)
}
