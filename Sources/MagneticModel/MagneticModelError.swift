//
//  MagneticModelError.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// Errors that can occur when loading a magnetic model.
public enum MagneticModelError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case invalidSignature(String)
    case invalidVersion(String)
    case invalidMetadata(String)
    case idMismatch(expected: String, got: String)
    case invalidCoefficients(String)

    public var description: String {
        switch self {
        case .fileNotFound(let s): return "File not found: \(s)"
        case .invalidSignature(let s): return "Invalid signature: \(s)"
        case .invalidVersion(let s): return "Unknown version: \(s)"
        case .invalidMetadata(let s): return "Invalid metadata: \(s)"
        case .idMismatch(let e, let g): return "ID mismatch: expected \(e), got \(g)"
        case .invalidCoefficients(let s): return "Invalid coefficients: \(s)"
        }
    }
}