//
//  SphericalHarmonic.swift
//  SwiftGeoLib
//
//  Pure Swift port of GeographicLib::SphericalHarmonic
//  Wraps coefficient storage and delegates evaluation to SphericalEngine.
//

import Foundation

/// A spherical harmonic series that can be evaluated at any point.
///
/// This wraps a set of C/S coefficients and a reference radius, delegating
/// the actual Clenshaw summation to ``SphericalEngine``.
struct SphericalHarmonic: Sendable {
    /// The spherical harmonic coefficients.
    let coefficients: SphericalCoefficients
    /// The reference radius appearing in the definition of the sum.
    let a: Double
    /// The normalization used for associated Legendre polynomials.
    let norm: Normalization

    /// Construct from coefficient vectors with explicit degree/order bounds.
    ///
    /// - Parameters:
    ///   - C: Cosine coefficients in column-major order.
    ///   - S: Sine coefficients in column-major order (m=0 column omitted).
    ///   - N: Storage layout degree.
    ///   - nmx: Maximum degree used in sums.
    ///   - mmx: Maximum order used in sums.
    ///   - a: Reference radius.
    ///   - norm: Normalization type (default: SCHMIDT).
    init(C: [Double], S: [Double],
         N: Int, nmx: Int, mmx: Int,
         a: Double, norm: Normalization = .schmidt)
    {
        self.coefficients = SphericalCoefficients(
            C: C, S: S, N: N, nmx: nmx, mmx: mmx)
        self.a = a
        self.norm = norm
        SphericalEngine.ensureRootTable(nmx)
    }

    /// Evaluate the spherical harmonic sum and return the gradient.
    ///
    /// The gradient components are in geocentric Cartesian coordinates.
    /// For magnetic field evaluation, these are proportional to the
    /// field components in geocentric basis before the −a scaling.
    ///
    /// - Parameters:
    ///   - x: Geocentric X coordinate.
    ///   - y: Geocentric Y coordinate.
    ///   - z: Geocentric Z coordinate.
    /// - Returns: Gradient (gradx, grady, gradz).
    func callAsFunction(_ x: Double, _ y: Double, _ z: Double)
        -> (gradx: Double, grady: Double, gradz: Double)
    {
        SphericalEngine.evaluate(
            coeff: coefficients, x: x, y: y, z: z, a: a, norm: norm)
    }
}
