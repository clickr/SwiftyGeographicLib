//
//  MagneticFieldComponentsWithRates.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// Derived geomagnetic elements with time derivatives.
public struct MagneticFieldComponentsWithRates: Sendable {
    /// Horizontal field intensity (nT).
    public let horizontalFieldIntensity: Double
    /// Total field intensity (nT).
    public let F: Double
    /// Declination (degrees east of north).
    public let D: Double
    /// Inclination (degrees down from horizontal).
    public let I: Double
    /// Rate of change of horizontalFieldIntensity (nT/yr).
    public let horizontalFieldIntensityDeltaT: Double
    /// Rate of change of totalFieldIntensity (nT/yr).
    public let totalIntensityDeltaT: Double
    /// Rate of change of declination (degrees/yr).
    public let declinationDeltaT: Double
    /// Rate of change of inclination (degrees/yr).
    public let inclinationDeltaT: Double
}
