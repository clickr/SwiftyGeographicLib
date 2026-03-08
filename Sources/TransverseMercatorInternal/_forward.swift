//
//  _forward.swift
//  SwiftGeoLib
//
//  Created by David Hart on 8/3/2026.
//

import Foundation
import CoreLocation
import ComplexModule
import RealModule
import Math

/// Core Krüger forward projection: geographic → transverse Mercator.
///
/// Converts a geographic coordinate to easting/northing using Krüger's method with a
/// 6th-order series, achieving ~5 nm accuracy within 35° of the central meridian.
/// All ellipsoid parameters are passed explicitly so this single implementation can be
/// shared between the dynamic `TransverseMercator` instance and any
/// `TransverseMercatorStaticInternal` conformer without code duplication.
///
/// Marked `@inlinable` so the compiler can inline the body at each call site across
/// module boundaries. This allows constant-folding of `static let` parameter values
/// (e.g. from `InternalUTM`) in the static code path, preserving the performance
/// advantage of the static design.
///
/// **Algorithm outline:**
/// 1. Normalise latitude/longitude signs and detect the "backside" of the projection
///    (longitude offset > 90° from the central meridian).
/// 2. Convert geodetic latitude to conformal latitude τ′ via `taupf`.
/// 3. Map (τ′, λ) to intermediate transverse-sphere coordinates (ξ′, η′).
/// 4. Apply the Krüger α series (Clenshaw summation in complex arithmetic) to obtain
///    the projected coordinates (ξ, η) and their derivatives for scale and convergence.
/// 5. Scale to metres and restore latitude/longitude signs; adjust for the backside case.
///
/// - Parameters:
///   - centralMeridian: Longitude of the central meridian in degrees.
///   - geodeticCoordinate: The geographic coordinate to project.
///   - centralScale: Central-meridian scale factor k₀ (0.9996 for UTM).
///   - _e2: First eccentricity squared `e²`.
///   - _es: Signed eccentricity `√|e²|`.
///   - _e2m: Eccentricity complement `1 − e²`.
///   - _c: Polar scale factor `√(1−e²) · exp(eatanhe(1, es))`.
///   - _b1: Conformal-sphere scale factor.
///   - _a1: Conformal-sphere radius in metres (`a × b1`).
///   - _alp: Krüger forward coefficients α₁–α₆; index 0 is unused.
/// - Returns: Easting `x` and northing `y` in metres, meridian convergence γ in degrees,
///   and the scale factor at the projected point.
@inlinable
public func _forward(centralMeridian: Double,
                    geodeticCoordinate: CLLocationCoordinate2D,
                    centralScale: Double,
                    _e2 : Double,
                    _es : Double,
                    _e2m : Double,
                    _c : Double,
                    _b1 : Double,
                    _a1 : Double,
                    _alp : [Double]) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
    var lat = latFix(geodeticCoordinate.latitude)
    var lon = angDiff(centralMeridian, geodeticCoordinate.longitude)
    var latsign : Int = lat.sign == .minus ? -1 : 1
    let lonsign : Int = lon.sign == .minus ? -1 : 1
    lon *= Double(lonsign)
    lat *= Double(latsign)
    
    let backside = lon > qd
    if backside {
        if lat == 0 {
            latsign = -1
        }
        lon = hd - lon
    }
    var sphi, cphi : Double
    (sphi, cphi) = sincosd(degrees: lat)
    
    var slam, clam : Double
    (slam, clam) = sincosd(degrees: lon)
    
    var etap, xip : Double
    var gamma: Double = .nan
    var k: Double = .nan
    if lat != qd {
        let tau = sphi / cphi
        let taup = taupf(tau, _es)
        xip = atan2(taup, clam)
        etap = asinh(slam / hypot(taup, clam))
        gamma = atan2d(slam * taup, clam * hypot(1.0, taup))
        k = sqrt(_e2m + _e2 * sq(cphi)) * hypot(1.0, tau) / hypot(taup, clam)
    } else {
        xip = .pi / 2
        etap = 0
        gamma = lon
        k = _c
    }
    
    let c0 = cos(2 * xip)
    let ch0 = cosh(2 * etap)
    let s0 = sin(2 * xip)
    let sh0 = sinh(2 * etap)
    
    let aComplex = Complex<Double>(2 * c0 * ch0, -2 * s0 * sh0)
    let n = _alp.count - 1
    var y0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(_alp[n], 0) : Complex<Double>(0, 0)
    var y1: Complex<Double> = Complex<Double>(0, 0)
    var z0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(2 * Double(n) * _alp[n], 0) : Complex<Double>(0, 0)
    var z1: Complex<Double> = Complex<Double>(0, 0)
    var nn = n
    if (nn & 1) != 0 { nn -= 1 }
    while nn > 0 {
        y1 = aComplex * y0 - y1 + Complex<Double>(_alp[nn], 0)
        z1 = aComplex * z0 - z1 + Complex<Double>(2 * Double(nn) * _alp[nn], 0)
        nn -= 1
        y0 = aComplex * y1 - y0 + Complex<Double>(_alp[nn], 0)
        z0 = aComplex * z1 - z0 + Complex<Double>(2 * Double(nn) * _alp[nn], 0)
        nn -= 1
    }
    var aDiv2 = aComplex / Complex<Double>(2, 0)
    z1 = Complex<Double>(1, 0) - z1 + aDiv2 * z0
    aDiv2 = Complex<Double>(s0 * ch0, c0 * sh0)
    y1 = Complex<Double>(xip, etap) + aDiv2 * y0
    
    let xi = y1.real
    let eta = y1.imaginary
    
    gamma -= atan2d(z1.imaginary, z1.real)
    let z1Mag = sqrt(z1.real * z1.real + z1.imaginary * z1.imaginary)
    k *= _b1 * z1Mag
    
    let x = _a1 * centralScale * eta * Double(lonsign)
    let y = _a1 * centralScale * (backside ? .pi - xi : xi) * Double(latsign)
    
    if backside {
        gamma = hd - gamma
    }
    gamma *= Double(latsign * lonsign)
    
    while gamma > 180 { gamma -= 360 }
    while gamma <= -180 { gamma += 360 }
    
    k *= centralScale
    
    return (x: x, y: y, convergence: gamma, centralScale: k)
}
