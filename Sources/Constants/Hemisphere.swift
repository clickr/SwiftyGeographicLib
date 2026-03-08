//
//  Hemisphere.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 27/7/2025.
//

import Foundation

/// Indicates whether a projected coordinate lies in the northern or southern hemisphere.
///
/// Used by UTM and UPS to distinguish the two hemispheric grids.
public enum Hemisphere {
    /// The northern hemisphere.
    case northern
    /// The southern hemisphere.
    case southern
}
