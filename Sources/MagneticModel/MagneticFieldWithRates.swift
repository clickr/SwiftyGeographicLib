//
//  MagneticFieldWithRates.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// The magnetic field vector together with its time derivatives.
public struct MagneticFieldWithRates: Sendable {
    /// The magnetic field.
    public let field: MagneticField
    /// Rate of change of Bx (nT/yr).
    public let Bxt: Double
    /// Rate of change of By (nT/yr).
    public let Byt: Double
    /// Rate of change of Bz (nT/yr).
    public let Bzt: Double
}