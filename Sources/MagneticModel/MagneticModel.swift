//
//  MagneticModel.swift
//  SwiftGeoLib
//
//  Pure Swift port of GeographicLib::MagneticModel.
//  Evaluates the Earth's magnetic field using spherical harmonic models.
//

import Foundation
import Math

/// Model of the Earth's magnetic field.
///
/// Evaluates the geomagnetic field at a given time and position using
/// spherical harmonic expansions loaded from standard model data files
/// (WMM, IGRF, EMM, etc.).
///
/// This is a pure Swift reimplementation of GeographicLib's MagneticModel,
/// designed to produce identical results.
///
/// ## Usage
/// ```swift
/// let model = try MagneticModel(name: "wmm2025")
/// let result = model.field(time: 2026.2, latitude: 47.6, longitude: -122.3, height: 0)
/// print("Declination: \(MagneticModel.fieldComponents(Bx: result.Bx, By: result.By, Bz: result.Bz).D)°")
/// ```
public struct MagneticModel: Sendable {

    // MARK: Metadata

    /// Model name (e.g. "wmm2025").
    public let name: String
    /// Human-readable description.
    public let modelDescription: String
    /// Release date string.
    public let releaseDate: String
    /// Reference epoch (years).
    public let epoch: Double
    /// Minimum valid time (years).
    public let minTime: Double
    /// Maximum valid time (years).
    public let maxTime: Double
    /// Minimum valid height above ellipsoid (meters).
    public let minHeight: Double
    /// Maximum valid height above ellipsoid (meters).
    public let maxHeight: Double
    /// Maximum degree of the model.
    public let degree: Int
    /// Maximum order of the model.
    public let order: Int

    // MARK: Internal state

    /// Reference sphere radius (meters).
    private let _a: Double
    /// Delta epoch for time interpolation.
    private let _dt0: Double
    /// Number of model epochs.
    private let _nNmodels: Int
    /// Number of constant terms (0 or 1).
    private let _nNconstants: Int
    /// Spherical harmonic objects for each epoch/constant.
    private let _harm: [SphericalHarmonic]
    /// Geocentric ellipsoid used for coordinate conversion.
    private let _earth: Geocentric

    /// The ID length in the binary coefficient file.
    private static let idLength = 8

    // MARK: Initializers

    /// Load a magnetic model from the bundled resources.
    ///
    /// - Parameter name: The model name (e.g. "wmm2025", "igrf14", "emm2017").
    /// - Throws: ``MagneticModelError`` if the model data cannot be loaded.
    public init(name: String) throws(MagneticModelError) {
        try self.init(name: name, earth: .wgs84)
    }

    /// Load a magnetic model with a custom ellipsoid.
    ///
    /// - Parameters:
    ///   - name: The model name.
    ///   - earth: The Geocentric ellipsoid to use.
    /// - Throws: ``MagneticModelError`` if the model data cannot be loaded.
    init(name: String, earth: Geocentric) throws(MagneticModelError) {
        self._earth = earth

        // Locate the metadata file in the bundle.
        guard let metaURL = Bundle.module.url(
            forResource: name, withExtension: "wmm")
        else {
            throw .fileNotFound("\(name).wmm not found in bundle")
        }

        // Parse metadata.
        let meta = try Self.readMetadata(url: metaURL)

        self.name = meta.name
        self.modelDescription = meta.description
        self.releaseDate = meta.date
        self.epoch = meta.t0
        self._a = meta.a
        self._dt0 = meta.dt0
        self.minTime = meta.tmin
        self.maxTime = meta.tmax
        self.minHeight = meta.hmin
        self.maxHeight = meta.hmax
        self._nNmodels = meta.nNmodels
        self._nNconstants = meta.nNconstants

        // Locate the coefficient file.
        guard let cofURL = Bundle.module.url(
            forResource: "\(name).wmm", withExtension: "cof")
        else {
            throw .fileNotFound("\(name).wmm.cof not found in bundle")
        }

        // Load binary coefficients.
        let cofData: Data
        do {
            cofData = try Data(contentsOf: cofURL)
        } catch {
            throw .fileNotFound("Cannot read \(cofURL.path)")
        }

        // Verify ID header.
        guard cofData.count >= Self.idLength else {
            throw .invalidCoefficients("Coefficient file too short")
        }
        let fileID = String(
            data: cofData.prefix(Self.idLength),
            encoding: .ascii)?.trimmingCharacters(in: .whitespaces) ?? ""
        if fileID != meta.id {
            throw .idMismatch(expected: meta.id, got: fileID)
        }

        // Read coefficient sets.
        let totalSets = meta.nNmodels + 1 + meta.nNconstants
        var offset = Self.idLength
        var harmonics: [SphericalHarmonic] = []
        harmonics.reserveCapacity(totalSets)
        var maxNmx = -1
        var maxMmx = -1

        for _ in 0..<totalSets {
            let (coeff, bytesRead) = try Self.readCoeffs(
                data: cofData, offset: offset)
            offset += bytesRead

            let harm = SphericalHarmonic(
                C: coeff.C, S: coeff.S,
                N: coeff.nmx, nmx: coeff.nmx, mmx: coeff.mmx,
                a: meta.a, norm: meta.norm)

            // Verify degree-0 term is zero (required by GeographicLib).
            if coeff.mmx >= 0 && !coeff.C.isEmpty && coeff.C[0] != 0 {
                throw .invalidCoefficients("A degree 0 term is not permitted")
            }

            maxNmx = Swift.max(maxNmx, coeff.nmx)
            maxMmx = Swift.max(maxMmx, coeff.mmx)
            harmonics.append(harm)
        }

        // Verify we consumed the entire file.
        if offset != cofData.count {
            throw .invalidCoefficients(
                "Extra data in coefficient file (\(cofData.count - offset) bytes)")
        }

        self._harm = harmonics
        self.degree = maxNmx
        self.order = maxMmx
    }

    // MARK: Field evaluation

    /// Evaluate the magnetic field at a given time and position.
    ///
    /// - Parameters:
    ///   - time: Fractional year (e.g. 2026.5).
    ///   - latitude: Geodetic latitude in degrees.
    ///   - longitude: Longitude in degrees.
    ///   - height: Height above the ellipsoid in meters.
    /// - Returns: The magnetic field in the local (east, north, up) basis.
    public func field(time: Double, latitude: Double,
                       longitude: Double, height: Double) -> MagneticField
    {
        let result = fieldInternal(
            time: time, lat: latitude, lon: longitude, h: height, diffp: false)
        return result.field
    }

    /// Evaluate the magnetic field and its time derivatives.
    ///
    /// - Parameters:
    ///   - time: Fractional year (e.g. 2026.5).
    ///   - latitude: Geodetic latitude in degrees.
    ///   - longitude: Longitude in degrees.
    ///   - height: Height above the ellipsoid in meters.
    /// - Returns: The field and its time derivatives.
    public func fieldWithRates(time: Double, latitude: Double,
                                longitude: Double, height: Double)
        -> MagneticFieldWithRates
    {
        fieldInternal(
            time: time, lat: latitude, lon: longitude, h: height, diffp: true)
    }

    /// Evaluate the magnetic field at a given date and position.
    ///
    /// - Parameters:
    ///   - date: The date at which to evaluate the field.
    ///   - latitude: Geodetic latitude in degrees.
    ///   - longitude: Longitude in degrees.
    ///   - height: Height above the ellipsoid in meters.
    /// - Returns: The magnetic field in the local (east, north, up) basis.
    public func field(date: Date, latitude: Double,
                       longitude: Double, height: Double) -> MagneticField
    {
        field(time: Self.fractionalYear(from: date),
              latitude: latitude, longitude: longitude, height: height)
    }

    /// Evaluate the magnetic field and its time derivatives at a given date.
    ///
    /// - Parameters:
    ///   - date: The date at which to evaluate the field.
    ///   - latitude: Geodetic latitude in degrees.
    ///   - longitude: Longitude in degrees.
    ///   - height: Height above the ellipsoid in meters.
    /// - Returns: The field and its time derivatives.
    public func fieldWithRates(date: Date, latitude: Double,
                                longitude: Double, height: Double)
        -> MagneticFieldWithRates
    {
        fieldWithRates(time: Self.fractionalYear(from: date),
                       latitude: latitude, longitude: longitude, height: height)
    }

    /// Convert a `Date` to a fractional year.
    ///
    /// Accounts for leap years by interpolating between the start of the
    /// current year and the start of the next year.
    ///
    /// - Parameter date: The date to convert.
    /// - Returns: The fractional year (e.g. 2025-07-02 ≈ 2025.5).
    static func fractionalYear(from date: Date) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let year = cal.component(.year, from: date)
        let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let startOfNextYear = cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        let yearLength = startOfNextYear.timeIntervalSince(startOfYear)
        let elapsed = date.timeIntervalSince(startOfYear)
        return Double(year) + elapsed / yearLength
    }

    /// Compute derived field components from the field vector.
    ///
    /// - Parameters:
    ///   - Bx: Easterly component (nT).
    ///   - By: Northerly component (nT).
    ///   - Bz: Vertical (up) component (nT).
    /// - Returns: H (horizontal), F (total), D (declination), I (inclination).
    public static func fieldComponents(Bx: Double, By: Double, Bz: Double)
        -> MagneticFieldComponents
    {
        let full = fieldComponentsWithRates(
            Bx: Bx, By: By, Bz: Bz, Bxt: 0, Byt: 1, Bzt: 0)
        return MagneticFieldComponents(
            horizontalFieldIntensity: full.horizontalFieldIntensity, totalFieldIntensity: full.F, declination: full.D, inclination: full.I)
    }

    /// Compute derived field components with time derivatives.
    ///
    /// - Parameters:
    ///   - Bx: Easterly component (nT).
    ///   - By: Northerly component (nT).
    ///   - Bz: Vertical (up) component (nT).
    ///   - Bxt: Time derivative of Bx (nT/yr).
    ///   - Byt: Time derivative of By (nT/yr).
    ///   - Bzt: Time derivative of Bz (nT/yr).
    /// - Returns: Field components and their rates.
    public static func fieldComponentsWithRates(
        Bx: Double, By: Double, Bz: Double,
        Bxt: Double, Byt: Double, Bzt: Double)
        -> MagneticFieldComponentsWithRates
    {
        let H = hypot(Bx, By)
        let Ht = H != 0
            ? (Bx * Bxt + By * Byt) / H
            : hypot(Bxt, Byt)
        let D = H != 0
            ? atan2d(Bx, By)
            : atan2d(Bxt, Byt)
        let Dt = (H != 0
            ? (By * Bxt - Bx * Byt) / (H * H)
            : 0) / Math.degree
        let F = hypot(H, Bz)
        let Ft = F != 0
            ? (H * Ht + Bz * Bzt) / F
            : hypot(Ht, Bzt)
        let I = F != 0
            ? atan2d(-Bz, H)
            : atan2d(-Bzt, Ht)
        let It = (F != 0
            ? (Bz * Ht - H * Bzt) / (F * F)
            : 0) / Math.degree

        return MagneticFieldComponentsWithRates(
            horizontalFieldIntensity: H, F: F, D: D, I: I,
            horizontalFieldIntensityDeltaT: Ht, totalIntensityDeltaT: Ft, declinationDeltaT: Dt, inclinationDeltaT: It)
    }

    // MARK: - Private implementation

    /// Internal field evaluation implementing both Field() and
    /// FieldGeocentric() from the C++ code.
    private func fieldInternal(time: Double, lat: Double, lon: Double,
                                h: Double, diffp: Bool)
        -> MagneticFieldWithRates
    {
        // Convert geodetic to geocentric.
        let geo = _earth.intForward(lat: lat, lon: lon, h: h)

        // Evaluate in geocentric coordinates.
        let geocentric = fieldGeocentric(
            time: time, X: geo.X, Y: geo.Y, Z: geo.Z)

        // Transform geocentric field to local (east, north, up).
        let local = Geocentric.unrotate(
            M: geo.M, X: geocentric.BX, Y: geocentric.BY, Z: geocentric.BZ)

        var Bxt = 0.0, Byt = 0.0, Bzt = 0.0
        if diffp {
            let localT = Geocentric.unrotate(
                M: geo.M,
                X: geocentric.BXt, Y: geocentric.BYt, Z: geocentric.BZt)
            Bxt = localT.x
            Byt = localT.y
            Bzt = localT.z
        }

        return MagneticFieldWithRates(
            field: MagneticField(Bx: local.x, By: local.y, Bz: local.z),
            Bxt: Bxt, Byt: Byt, Bzt: Bzt)
    }

    /// Evaluate the magnetic field in geocentric coordinates with time
    /// interpolation between model epochs.
    private func fieldGeocentric(time: Double, X: Double, Y: Double,
                                  Z: Double)
        -> (BX: Double, BY: Double, BZ: Double,
            BXt: Double, BYt: Double, BZt: Double)
    {
        var t = time - epoch
        let n = Swift.max(Swift.min(Int(floor(t / _dt0)), _nNmodels - 1), 0)
        let interpolate = n + 1 < _nNmodels
        t -= Double(n) * _dt0

        // Evaluate field at epoch n.
        let field0 = _harm[n](X, Y, Z)
        var BX = field0.gradx
        var BY = field0.grady
        var BZ = field0.gradz

        // Evaluate field at epoch n+1.
        let field1 = _harm[n + 1](X, Y, Z)
        var BXt = field1.gradx
        var BYt = field1.grady
        var BZt = field1.gradz

        // Optional constant term.
        var BXc = 0.0, BYc = 0.0, BZc = 0.0
        if _nNconstants > 0 {
            let fieldC = _harm[_nNmodels + 1](X, Y, Z)
            BXc = fieldC.gradx
            BYc = fieldC.grady
            BZc = fieldC.gradz
        }

        if interpolate {
            // Convert to time derivative.
            BXt = (BXt - BX) / _dt0
            BYt = (BYt - BY) / _dt0
            BZt = (BZt - BZ) / _dt0
        }

        // Interpolate: B(t) = B[n] + t * dB/dt + B_constant
        BX += t * BXt + BXc
        BY += t * BYt + BYc
        BZ += t * BZt + BZc

        // Scale by −a to convert from potential gradient to field (nT).
        BXt *= -_a
        BYt *= -_a
        BZt *= -_a
        BX *= -_a
        BY *= -_a
        BZ *= -_a

        return (BX, BY, BZ, BXt, BYt, BZt)
    }

    // MARK: - Metadata parsing

    private struct Metadata {
        var name: String = ""
        var description: String = "NONE"
        var date: String = "UNKNOWN"
        var id: String = ""
        var t0: Double = .nan      // epoch
        var dt0: Double = 1        // delta epoch
        var tmin: Double = .nan
        var tmax: Double = .nan
        var a: Double = .nan       // reference radius
        var hmin: Double = .nan
        var hmax: Double = .nan
        var nNmodels: Int = 1
        var nNconstants: Int = 0
        var norm: Normalization = .schmidt
    }

    /// Parse the .wmm metadata file.
    private static func readMetadata(url: URL) throws(MagneticModelError)
        -> Metadata
    {
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw .fileNotFound("Cannot read \(url.path)")
        }

        let lines = content.components(separatedBy: .newlines)
        guard let firstLine = lines.first,
              firstLine.count >= 6,
              firstLine.hasPrefix("WMMF-")
        else {
            throw .invalidSignature(url.lastPathComponent)
        }

        // Extract version number.
        let versionPart = firstLine.dropFirst(5)
            .trimmingCharacters(in: .whitespaces)
        let version = versionPart.components(
            separatedBy: .whitespaces).first ?? versionPart
        guard version == "1" || version == "2" else {
            throw .invalidVersion(version)
        }

        var meta = Metadata()

        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            // Split into key and value at first whitespace.
            let parts = trimmed.split(
                maxSplits: 1,
                whereSeparator: { $0.isWhitespace })
            guard parts.count == 2 else { continue }
            let key = String(parts[0])
            let val = String(parts[1]).trimmingCharacters(in: .whitespaces)

            switch key {
            case "Name":          meta.name = val
            case "Description":   meta.description = val
            case "ReleaseDate":   meta.date = val
            case "Radius":        meta.a = Double(val) ?? .nan
            case "Epoch":         meta.t0 = Double(val) ?? .nan
            case "DeltaEpoch":    meta.dt0 = Double(val) ?? 1
            case "NumModels":     meta.nNmodels = Int(val) ?? 1
            case "NumConstants":  meta.nNconstants = Int(val) ?? 0
            case "MinTime":       meta.tmin = Double(val) ?? .nan
            case "MaxTime":       meta.tmax = Double(val) ?? .nan
            case "MinHeight":     meta.hmin = Double(val) ?? .nan
            case "MaxHeight":     meta.hmax = Double(val) ?? .nan
            case "ID":            meta.id = val
            case "Normalization":
                let lower = val.lowercased()
                if lower == "full" {
                    meta.norm = .full
                } else if lower == "schmidt" {
                    meta.norm = .schmidt
                } else {
                    throw .invalidMetadata("Unknown normalization: \(val)")
                }
            case "ByteOrder":
                let lower = val.lowercased()
                if lower == "big" {
                    throw .invalidMetadata(
                        "Only little-endian ordering is supported")
                } else if lower != "little" {
                    throw .invalidMetadata("Unknown byte ordering: \(val)")
                }
            case "Type":
                let lower = val.lowercased()
                if lower != "linear" {
                    throw .invalidMetadata("Only linear models are supported")
                }
            default:
                break // Ignore unknown keys.
            }
        }

        // Validate.
        guard meta.a.isFinite && meta.a > 0 else {
            throw .invalidMetadata("Reference radius must be positive")
        }
        guard meta.t0 > 0 else {
            throw .invalidMetadata("Epoch time not defined")
        }
        guard meta.tmin < meta.tmax else {
            throw .invalidMetadata("Min time exceeds max time")
        }
        guard meta.hmin < meta.hmax else {
            throw .invalidMetadata("Min height exceeds max height")
        }
        guard meta.id.count == idLength else {
            throw .invalidMetadata("Invalid ID length: \(meta.id)")
        }
        guard meta.nNmodels >= 1 else {
            throw .invalidMetadata("NumModels must be positive")
        }
        guard meta.nNconstants == 0 || meta.nNconstants == 1 else {
            throw .invalidMetadata("NumConstants must be 0 or 1")
        }
        if meta.dt0 <= 0 {
            if meta.nNmodels > 1 {
                throw .invalidMetadata("DeltaEpoch must be positive")
            }
            meta.dt0 = 1
        }

        return meta
    }

    // MARK: - Binary coefficient reading

    /// Read one set of coefficients from the binary .cof data.
    ///
    /// - Parameters:
    ///   - data: The full binary data.
    ///   - offset: Byte offset to start reading from.
    /// - Returns: The coefficients and number of bytes consumed.
    private static func readCoeffs(data: Data, offset: Int)
        throws(MagneticModelError)
        -> (SphericalCoefficients, Int)
    {
        var pos = offset

        // Read N and M as 4-byte little-endian ints.
        guard pos + 8 <= data.count else {
            throw .invalidCoefficients("Unexpected end of coefficient data")
        }
        let N = Int(data.withUnsafeBytes { buf in
            buf.loadUnaligned(fromByteOffset: pos, as: Int32.self)
        })
        let M = Int(data.withUnsafeBytes { buf in
            buf.loadUnaligned(fromByteOffset: pos + 4, as: Int32.self)
        })
        pos += 8

        guard (N >= M && M >= 0) || (N == -1 && M == -1) else {
            throw .invalidCoefficients(
                "Bad degree and order: N=\(N), M=\(M)")
        }

        let cCount = SphericalCoefficients.cSize(N, M)
        let sCount = SphericalCoefficients.sSize(N, M)
        let totalDoubles = cCount + sCount
        let bytesNeeded = totalDoubles * MemoryLayout<Double>.size

        guard pos + bytesNeeded <= data.count else {
            throw .invalidCoefficients(
                "Not enough coefficient data (need \(bytesNeeded) bytes)")
        }

        // Read C coefficients.
        var C = [Double](repeating: 0, count: cCount)
        data.withUnsafeBytes { buf in
            for i in 0..<cCount {
                C[i] = buf.loadUnaligned(
                    fromByteOffset: pos + i * 8, as: Double.self)
            }
        }
        pos += cCount * 8

        // Read S coefficients.
        var S = [Double](repeating: 0, count: sCount)
        data.withUnsafeBytes { buf in
            for i in 0..<sCount {
                S[i] = buf.loadUnaligned(
                    fromByteOffset: pos + i * 8, as: Double.self)
            }
        }
        pos += sCount * 8

        let coeff = SphericalCoefficients(C: C, S: S, N: N, nmx: N, mmx: M)
        return (coeff, pos - offset)
    }
}
