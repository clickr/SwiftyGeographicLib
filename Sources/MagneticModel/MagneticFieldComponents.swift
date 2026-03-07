//
//  MagneticFieldComponents.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// Derived geomagnetic elements.
public struct MagneticFieldComponents: Sendable {
    /// Horizontal field intensity (nT).
    public let horizontalFieldIntensity: Double
    /// Total field intensity (nT).
    public let totalFieldIntensity: Double
    /// Declination (degrees east of north).
    public let declination: Double
    /// Inclination (degrees down from horizontal).
    public let inclination: Double
}
