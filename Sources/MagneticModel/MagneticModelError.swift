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
    /// The coefficient file could not be found at the given path.
    case fileNotFound(String)
    /// The file header does not match the expected magic bytes.
    case invalidSignature(String)
    /// The file format version is not supported.
    case invalidVersion(String)
    /// Required metadata fields are missing or malformed.
    case invalidMetadata(String)
    /// The model ID in the secular-variation file does not match the main file.
    case idMismatch(expected: String, got: String)
    /// One or more coefficient lines could not be parsed.
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