//
//  RhumbResult.swift
//  SwiftyGeographicLib
//
//  Result types for rhumb line (loxodrome) calculations.
//

/// The result of a direct rhumb problem.
///
/// Given a starting point, azimuth, and distance, the direct problem
/// computes the destination point and the area under the rhumb line.
public struct RhumbDirectResult: Sendable {
    /// Destination latitude in degrees.
    public let latitude: Double
    /// Destination longitude in degrees.
    public let longitude: Double
    /// Area under the rhumb line (m²).
    public let area: Double
}

/// The result of an inverse rhumb problem.
///
/// Given two points, the inverse problem computes the constant-bearing
/// azimuth, the rhumb distance, and the area under the rhumb line.
public struct RhumbInverseResult: Sendable {
    /// Rhumb distance between the two points (m).
    public let distance: Double
    /// Constant bearing (azimuth) of the rhumb line, in degrees clockwise
    /// from north.
    public let azimuth: Double
    /// Area under the rhumb line (m²).
    public let area: Double
}

/// A position along a rhumb line, computed via ``RhumbLine/position(distance:)``.
public struct RhumbPosition: Sendable {
    /// Latitude at the computed position, in degrees.
    public let latitude: Double
    /// Longitude at the computed position, in degrees.
    public let longitude: Double
    /// Area under the rhumb line from the start to this position (m²).
    public let area: Double
}
