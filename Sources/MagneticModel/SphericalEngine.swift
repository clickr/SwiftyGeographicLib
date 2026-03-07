//
//  SphericalEngine.swift
//  SwiftGeoLib
//
//  Pure Swift port of GeographicLib::SphericalEngine
//  Implements Clenshaw summation for evaluating spherical harmonic sums.
//

import Foundation

// MARK: - Normalization

/// Normalization types for associated Legendre polynomials.
enum Normalization: Int, Sendable {
    /// Fully normalized: mean squared value over the sphere is 1.
    case full = 0
    /// Schmidt semi-normalized: mean squared value is 1/(2n+1).
    case schmidt = 1
}

// MARK: - SphericalCoefficients

/// Storage for spherical harmonic coefficients (C and S arrays) with
/// column-major indexing matching GeographicLib.
struct SphericalCoefficients: Sendable {
    /// Storage layout degree.
    let nN: Int
    /// Maximum degree used in sums.
    let nmx: Int
    /// Maximum order used in sums.
    let mmx: Int
    /// Cosine coefficients (column-major).
    let C: [Double]
    /// Sine coefficients (column-major, m=0 column omitted).
    let S: [Double]

    /// Default (empty) coefficients.
    init() {
        nN = -1; nmx = -1; mmx = -1
        C = []; S = []
    }

    /// Full constructor with explicit degree/order bounds.
    init(C: [Double], S: [Double], N: Int, nmx: Int, mmx: Int) {
        self.nN = N
        self.nmx = nmx
        self.mmx = mmx
        self.C = C
        self.S = S
    }

    /// Convenience: N = nmx = mmx.
    init(C: [Double], S: [Double], N: Int) {
        self.init(C: C, S: S, N: N, nmx: N, mmx: N)
    }

    /// One-dimensional index into C (and offset index into S).
    @inline(__always)
    func index(_ n: Int, _ m: Int) -> Int {
        m * nN - m * (m - 1) / 2 + n
    }

    /// Retrieve a C coefficient by flat index.
    @inline(__always)
    func Cv(_ k: Int) -> Double { C[k] }

    /// Retrieve an S coefficient by flat index
    /// (adjusting for the missing m=0 column).
    @inline(__always)
    func Sv(_ k: Int) -> Double { S[k - (nN + 1)] }

    /// Size of the C vector for given degree N and order M.
    static func cSize(_ N: Int, _ M: Int) -> Int {
        (M + 1) * (2 * N - M + 2) / 2
    }

    /// Size of the S vector for given degree N and order M.
    static func sSize(_ N: Int, _ M: Int) -> Int {
        cSize(N, M) - (N + 1)
    }
}

// MARK: - SphericalEngine

/// Core evaluation engine for spherical harmonic sums via Clenshaw recursion.
///
/// This is a faithful port of `SphericalEngine::Value<true, norm, 1>` from
/// GeographicLib. It always computes the gradient (gradp=true) with a single
/// coefficient set (L=1), which is what MagneticModel needs.
enum SphericalEngine {

    // MARK: Constants

    /// Internal scaling factor to prevent overflow for high-degree models.
    /// For Double: 2^(−614).
    static let scale: Double = pow(2.0, Double(-3 * 1024 / 5))

    /// Minimum value of sin(θ) to avoid the pole singularity.
    static let eps: Double = Double.ulpOfOne * sqrt(Double.ulpOfOne)

    // MARK: Square root table

    /// Cached table of √i for integer indices.
    /// Access is protected by `_rootLock`.
    nonisolated(unsafe) private static var _rootTable: [Double] = []
    private static let _rootLock = NSLock()

    /// Ensure the square root table is large enough for degree N.
    static func ensureRootTable(_ N: Int) {
        let needed = Swift.max(2 * N + 5, 15) + 1
        _rootLock.lock()
        defer { _rootLock.unlock() }
        let oldCount = _rootTable.count
        guard oldCount < needed else { return }
        _rootTable.reserveCapacity(needed)
        for i in oldCount..<needed {
            _rootTable.append(sqrt(Double(i)))
        }
    }

    /// Access a precomputed square root.
    @inline(__always)
    private static func root(_ i: Int) -> Double { _rootTable[i] }

    // MARK: Evaluation

    /// Evaluate a spherical harmonic sum and its gradient using Clenshaw
    /// recursion.
    ///
    /// Port of `SphericalEngine::Value<true, norm, 1>`.
    ///
    /// - Parameters:
    ///   - coeff: The spherical harmonic coefficients.
    ///   - x: Geocentric X coordinate.
    ///   - y: Geocentric Y coordinate.
    ///   - z: Geocentric Z coordinate.
    ///   - a: Reference radius.
    ///   - norm: Normalization type.
    /// - Returns: The gradient (gradx, grady, gradz) in geocentric Cartesian.
    static func evaluate(coeff c: SphericalCoefficients,
                          x: Double, y: Double, z: Double,
                          a: Double, norm: Normalization)
        -> (gradx: Double, grady: Double, gradz: Double)
    {
        let N = c.nmx
        let M = c.mmx

        let p = hypot(x, y)
        let cl = p != 0 ? x / p : 1.0   // cos(λ)
        let sl = p != 0 ? y / p : 0.0   // sin(λ)
        let r = hypot(z, p)
        let t = r != 0 ? z / r : 0.0    // cos(θ)
        let u = r != 0 ? Swift.max(p / r, eps) : 1.0 // sin(θ)
        let q = a / r

        let q2 = q * q
        let uq = u * q
        let uq2 = uq * uq
        let tu = t / u

        // Outer sum accumulators: v[N+1], v[N+2]
        var vc: Double = 0, vc2: Double = 0
        var vs: Double = 0, vs2: Double = 0
        var vrc: Double = 0, vrc2: Double = 0
        var vrs: Double = 0, vrs2: Double = 0
        var vtc: Double = 0, vtc2: Double = 0
        var vts: Double = 0, vts2: Double = 0
        var vlc: Double = 0, vlc2: Double = 0
        var vls: Double = 0, vls2: Double = 0

        for m in stride(from: M, through: 0, by: -1) {
            // Inner sum accumulators
            var wc: Double = 0, wc2: Double = 0
            var ws: Double = 0, ws2: Double = 0
            var wrc: Double = 0, wrc2: Double = 0
            var wrs: Double = 0, wrs2: Double = 0
            var wtc: Double = 0, wtc2: Double = 0
            var wts: Double = 0, wts2: Double = 0

            var k = c.index(N, m) + 1

            for n in stride(from: N, through: m, by: -1) {
                let Ax: Double, A: Double, B: Double

                switch norm {
                case .full:
                    let w = root(2 * n + 1) / (root(n - m + 1) * root(n + m + 1))
                    Ax = q * w * root(2 * n + 3)
                    A = t * Ax
                    B = -q2 * root(2 * n + 5) /
                        (w * root(n - m + 2) * root(n + m + 2))
                case .schmidt:
                    let w = root(n - m + 1) * root(n + m + 1)
                    Ax = q * Double(2 * n + 1) / w
                    A = t * Ax
                    B = -q2 * w / (root(n - m + 2) * root(n + m + 2))
                }

                k -= 1
                let R = c.Cv(k) * scale

                var w: Double
                w = A * wc + B * wc2 + R; wc2 = wc; wc = w
                // Gradient: r-derivative
                w = A * wrc + B * wrc2 + Double(n + 1) * R; wrc2 = wrc; wrc = w
                // Gradient: θ-derivative
                w = A * wtc + B * wtc2 - u * Ax * wc2; wtc2 = wtc; wtc = w

                if m > 0 {
                    let Rs = c.Sv(k) * scale
                    w = A * ws + B * ws2 + Rs; ws2 = ws; ws = w
                    w = A * wrs + B * wrs2 + Double(n + 1) * Rs; wrs2 = wrs; wrs = w
                    w = A * wts + B * wts2 - u * Ax * ws2; wts2 = wts; wts = w
                }
            }

            // Outer sum
            if m > 0 {
                let A: Double, B: Double
                switch norm {
                case .full:
                    let vv = root(2) * root(2 * m + 3) / root(m + 1)
                    A = cl * vv * uq
                    B = -vv * root(2 * m + 5) / (root(8) * root(m + 2)) * uq2
                case .schmidt:
                    let vv = root(2) * root(2 * m + 1) / root(m + 1)
                    A = cl * vv * uq
                    B = -vv * root(2 * m + 3) / (root(8) * root(m + 2)) * uq2
                }

                var v: Double
                v = A * vc  + B * vc2  + wc;  vc2  = vc;  vc  = v
                v = A * vs  + B * vs2  + ws;  vs2  = vs;  vs  = v

                // Include Sc[m] * P'[m,m](t) and Ss[m] * P'[m,m](t)
                wtc += Double(m) * tu * wc
                wts += Double(m) * tu * ws

                v = A * vrc + B * vrc2 + wrc; vrc2 = vrc; vrc = v
                v = A * vrs + B * vrs2 + wrs; vrs2 = vrs; vrs = v
                v = A * vtc + B * vtc2 + wtc; vtc2 = vtc; vtc = v
                v = A * vts + B * vts2 + wts; vts2 = vts; vts = v
                v = A * vlc + B * vlc2 + Double(m) * ws; vlc2 = vlc; vlc = v
                v = A * vls + B * vls2 - Double(m) * wc; vls2 = vls; vls = v
            } else {
                // m == 0: finalize the sum
                let A: Double, B: Double
                switch norm {
                case .full:
                    A = root(3) * uq
                    B = -root(15) / 2.0 * uq2
                case .schmidt:
                    A = uq
                    B = -root(3) / 2.0 * uq2
                }

                let qs = q / scale
                vc = qs * (wc + A * (cl * vc + sl * vs) + B * vc2)

                let qs_r = qs / r
                vrc = -qs_r * (wrc + A * (cl * vrc + sl * vrs) + B * vrc2)
                vtc =  qs_r * (wtc + A * (cl * vtc + sl * vts) + B * vtc2)
                vlc =  qs_r / u * (   A * (cl * vlc + sl * vls) + B * vlc2)
            }
        }

        // Rotate gradient from spherical (r, θ, λ) to Cartesian (X, Y, Z).
        let gradx = cl * (u * vrc + t * vtc) - sl * vlc
        let grady = sl * (u * vrc + t * vtc) + cl * vlc
        let gradz = t * vrc - u * vtc

        return (gradx, grady, gradz)
    }
}
