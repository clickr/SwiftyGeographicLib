import MagneticModel
import Foundation

/// Computes contour lines of constant magnetic field properties
/// (declination, inclination, or intensity) over a geographic region.
///
/// The primary use case is generating isogonic lines — curves of constant
/// magnetic declination — for display on a map.
///
/// ```swift
/// let model = try MagneticModel(name: "wmm2025")
/// let bounds = LatLonBounds(
///     minLatitude: 24, maxLatitude: 50,
///     minLongitude: -130, maxLongitude: -60)
/// let isogonic = Isogonic(model: model)
/// let contours = isogonic.contours(
///     values: stride(from: -20, through: 20, by: 5).map { Double($0) },
///     bounds: bounds,
///     time: 2026.0)
/// ```
public struct Isogonic: Sendable {

    /// The magnetic model used for field evaluation.
    public let model: MagneticModel

    /// Height above the WGS 84 ellipsoid in metres for field evaluation.
    public let height: Double

    /// Creates an isogonic contour generator.
    ///
    /// - Parameters:
    ///   - model: A magnetic model (e.g. `MagneticModel(name: "wmm2025")`).
    ///   - height: Height above the WGS 84 ellipsoid in metres.
    ///     Defaults to 0 (sea level).
    public init(model: MagneticModel, height: Double = 0) {
        self.model = model
        self.height = height
    }

    /// Extracts contour lines for the given magnetic field property.
    ///
    /// - Parameters:
    ///   - property: Which field quantity to contour. Defaults to
    ///     `.declination`.
    ///   - values: The specific constant values to trace contours for.
    ///     For declination, these are degrees east of true north.
    ///   - bounds: The geographic region to cover.
    ///   - time: Fractional year (e.g. 2026.0).
    ///   - gridSpacing: Grid cell size in degrees. Defaults to 1.0.
    ///     Smaller values produce smoother contours at the cost of more
    ///     field evaluations.
    /// - Returns: An array of ``ContourLine``. A single target value
    ///   may produce multiple entries if the contour is disconnected
    ///   within the region.
    public func contours(
        property: MagneticFieldProperty = .declination,
        values: [Double],
        bounds: LatLonBounds,
        time: Double,
        gridSpacing: Double = 1.0
    ) -> [ContourLine] {
        let (grid, nRows, nCols) = sampleGrid(
            property: property, bounds: bounds,
            time: time, gridSpacing: gridSpacing
        )

        var result: [ContourLine] = []
        for value in values {
            let polylines = extractContours(
                grid: grid, nRows: nRows, nCols: nCols,
                minLat: bounds.minLatitude, minLon: bounds.minLongitude,
                gridSpacing: gridSpacing, value: value
            )
            for coords in polylines {
                result.append(ContourLine(value: value, coordinates: coords))
            }
        }
        return result
    }

    /// Extracts contour lines using a `Date` instead of fractional year.
    ///
    /// - Parameters:
    ///   - property: Which field quantity to contour. Defaults to
    ///     `.declination`.
    ///   - values: The specific constant values to trace contours for.
    ///   - bounds: The geographic region to cover.
    ///   - date: The date for field evaluation.
    ///   - gridSpacing: Grid cell size in degrees. Defaults to 1.0.
    /// - Returns: An array of ``ContourLine``.
    public func contours(
        property: MagneticFieldProperty = .declination,
        values: [Double],
        bounds: LatLonBounds,
        date: Date,
        gridSpacing: Double = 1.0
    ) -> [ContourLine] {
        let (grid, nRows, nCols) = sampleGrid(
            property: property, bounds: bounds,
            date: date, gridSpacing: gridSpacing
        )

        var result: [ContourLine] = []
        for value in values {
            let polylines = extractContours(
                grid: grid, nRows: nRows, nCols: nCols,
                minLat: bounds.minLatitude, minLon: bounds.minLongitude,
                gridSpacing: gridSpacing, value: value
            )
            for coords in polylines {
                result.append(ContourLine(value: value, coordinates: coords))
            }
        }
        return result
    }

    // MARK: - Grid sampling

    /// Samples the magnetic field property on a regular lat/lon grid
    /// using a fractional year.
    private func sampleGrid(
        property: MagneticFieldProperty,
        bounds: LatLonBounds,
        time: Double,
        gridSpacing: Double
    ) -> (grid: [Double], nRows: Int, nCols: Int) {
        sampleGrid(property: property, bounds: bounds, gridSpacing: gridSpacing) {
            lat, lon in
            model.field(time: time, latitude: lat, longitude: lon, height: height)
        }
    }

    /// Samples the magnetic field property on a regular lat/lon grid
    /// using a `Date`.
    private func sampleGrid(
        property: MagneticFieldProperty,
        bounds: LatLonBounds,
        date: Date,
        gridSpacing: Double
    ) -> (grid: [Double], nRows: Int, nCols: Int) {
        sampleGrid(property: property, bounds: bounds, gridSpacing: gridSpacing) {
            lat, lon in
            model.field(date: date, latitude: lat, longitude: lon, height: height)
        }
    }

    /// Core grid sampling implementation.
    private func sampleGrid(
        property: MagneticFieldProperty,
        bounds: LatLonBounds,
        gridSpacing: Double,
        evaluate: (Double, Double) -> MagneticField
    ) -> (grid: [Double], nRows: Int, nCols: Int) {
        let nRows = Int(ceil((bounds.maxLatitude - bounds.minLatitude) / gridSpacing)) + 1
        let nCols = Int(ceil((bounds.maxLongitude - bounds.minLongitude) / gridSpacing)) + 1

        var grid = [Double](repeating: 0, count: nRows * nCols)

        for row in 0..<nRows {
            let lat = min(
                bounds.minLatitude + Double(row) * gridSpacing,
                bounds.maxLatitude
            )
            for col in 0..<nCols {
                let lon = min(
                    bounds.minLongitude + Double(col) * gridSpacing,
                    bounds.maxLongitude
                )
                let field = evaluate(lat, lon)
                grid[row * nCols + col] = extractValue(field, property: property)
            }
        }

        return (grid, nRows, nCols)
    }

    /// Extracts the scalar value for the requested property from a
    /// magnetic field evaluation.
    private func extractValue(
        _ field: MagneticField,
        property: MagneticFieldProperty
    ) -> Double {
        let components = MagneticModel.fieldComponents(
            east: field.east, north: field.north, up: field.up
        )
        switch property {
        case .declination:         return components.declination
        case .inclination:         return components.inclination
        case .totalIntensity:      return components.totalFieldIntensity
        case .horizontalIntensity: return components.horizontalFieldIntensity
        }
    }
}
