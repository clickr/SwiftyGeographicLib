//
//  _reverse.swift
//  SwiftGeoLib
//
//  Created by David Hart on 8/3/2026.
//

import Foundation
import CoreLocation
import ComplexModule
import RealModule
import Math

/// Core Krüger reverse projection: transverse Mercator → geographic.
///
/// Converts easting/northing back to a geographic coordinate using Krüger's method with a
/// 6th-order series, achieving ~5 nm accuracy within 35° of the central meridian.
/// All ellipsoid parameters are passed explicitly so this single implementation can be
/// shared between the dynamic `TransverseMercator` instance and any
/// `TransverseMercatorStaticInternal` conformer without code duplication.
///
/// Marked `@inlinable` for the same reasons as `_forward`: it allows the compiler to
/// inline the body at each call site and constant-fold `static let` values in the
/// static code path.
///
/// **Algorithm outline:**
/// 1. Normalise (x, y) to dimensionless (ξ, η) and record signs; detect the backside.
/// 2. Apply the Krüger β series (Clenshaw summation in complex arithmetic) to recover
///    the transverse-sphere coordinates (ξ′, η′) and their derivatives.
/// 3. Recover the conformal latitude from (ξ′, η′) and convert back to geodetic
///    latitude via `tauf`.
/// 4. Restore sign conventions and wrap longitude to [−180°, 180°].
///
/// - Parameters:
///   - centralMeridian: Longitude of the central meridian in degrees.
///   - x: Easting in metres.
///   - y: Northing in metres.
///   - centralScale: Central-meridian scale factor k₀ (0.9996 for UTM).
///   - _e2: First eccentricity squared `e²`.
///   - _es: Signed eccentricity `√|e²|`.
///   - _e2m: Eccentricity complement `1 − e²`.
///   - _c: Polar scale factor `√(1−e²) · exp(eatanhe(1, es))`.
///   - _b1: Conformal-sphere scale factor.
///   - _a1: Conformal-sphere radius in metres (`a × b1`).
///   - _bet: Krüger reverse coefficients β₁–β₆; index 0 is unused.
/// - Returns: Geographic `coordinate` (latitude and longitude in degrees),
///   meridian convergence γ in degrees, and the scale factor at the point.
@inlinable
public func _reverse(centralMeridian: Double,
                    x: Double,
                    y: Double,
                    centralScale: Double,
                    _e2 : Double,
                    _es : Double,
                    _e2m : Double,
                    _c : Double,
                    _b1 : Double,
                    _a1 : Double,
                    _bet : [Double]) -> (coordinate: CLLocationCoordinate2D, convergence: Double, centralScale: Double) {
    var xi = y / (_a1 * centralScale)
    var eta = x / (_a1 * centralScale)
    
    let xisign: Int = xi.sign == .minus ? -1 : 1
    let etasign: Int = eta.sign == .minus ? -1 : 1
    xi *= Double(xisign)
    eta *= Double(etasign)
    
    let backside = xi > .pi / 2
    if backside {
        xi = .pi - xi
    }
    
    let c0 = cos(2 * xi)
    let ch0 = cosh(2 * eta)
    let s0 = sin(2 * xi)
    let sh0 = sinh(2 * eta)
    
    let aComplex = Complex<Double>(2 * c0 * ch0, -2 * s0 * sh0)
    let n = _bet.count - 1
    var y0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(-_bet[n], 0) : Complex<Double>(0, 0)
    var y1: Complex<Double> = Complex<Double>(0, 0)
    var z0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(-2 * Double(n) * _bet[n], 0) : Complex<Double>(0, 0)
    var z1: Complex<Double> = Complex<Double>(0, 0)
    var nn = n
    if (nn & 1) != 0 { nn -= 1 }
    while nn > 0 {
        y1 = aComplex * y0 - y1 - Complex<Double>(_bet[nn], 0)
        z1 = aComplex * z0 - z1 - Complex<Double>(2 * Double(nn) * _bet[nn], 0)
        nn -= 1
        y0 = aComplex * y1 - y0 - Complex<Double>(_bet[nn], 0)
        z0 = aComplex * z1 - z0 - Complex<Double>(2 * Double(nn) * _bet[nn], 0)
        nn -= 1
    }
    var aDiv2 = aComplex / Complex<Double>(2, 0)
    z1 = Complex<Double>(1, 0) - z1 + aDiv2 * z0
    aDiv2 = Complex<Double>(s0 * ch0, c0 * sh0)
    y1 = Complex<Double>(xi, eta) + aDiv2 * y0
    
    var gamma = atan2d(z1.imaginary, z1.real)
    var k = _b1 / sqrt(z1.real * z1.real + z1.imaginary * z1.imaginary)
    
    let xip = y1.real
    let etap = y1.imaginary
    
    let s = Foundation.sinh(etap)
    let c = max(0.0, cos(xip))
    let r = hypot(s, c)
    
    var lat: Double = .nan
    var lon: Double = .nan
    if r != 0 {
        lon = atan2d(s, c)
        let sxip = sin(xip)
        let tau = tauf(sxip / r, _es)
        gamma += atan2d(sxip * Foundation.tanh(etap), c)
        lat = atand(tau)
        k *= sqrt(_e2m + _e2 / (1 + sq(tau))) * hypot(1.0, tau) * r
    } else {
        lat = qd
        lon = 0
        k *= _c
    }
    
    lat *= Double(xisign)
    if backside {
        lon = hd - lon
    }
    lon *= Double(etasign)
    
    while lon > 180 { lon -= 360 }
    while lon <= -180 { lon += 360 }
    lon += centralMeridian
    
    if backside {
        gamma = hd - gamma
    }
    gamma *= Double(xisign * etasign)
    
    while gamma > 180 { gamma -= 360 }
    while gamma <= -180 { gamma += 360 }
    
    k *= centralScale
    
    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    return (coordinate: coordinate, convergence: gamma, centralScale: k)
}
