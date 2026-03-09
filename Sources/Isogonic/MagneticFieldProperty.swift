/// The scalar magnetic field quantity to extract contours for.
public enum MagneticFieldProperty: Sendable {
    /// Magnetic declination in degrees east of true north.
    case declination
    /// Magnetic inclination (dip angle) in degrees below horizontal.
    case inclination
    /// Total field intensity in nanotesla.
    case totalIntensity
    /// Horizontal field intensity in nanotesla.
    case horizontalIntensity
}
