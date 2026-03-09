//
//  Math.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 26/2/2026.
//

import Foundation
import CoreLocation

/// Converts degrees to radians.
///
/// - Parameter degrees: An angle in degrees.
/// - Returns: The equivalent angle in radians.
@inline(__always) func deg2rad(_ degrees: Double) -> Double {
    return degrees * .pi / 180.0
}

/// Converts radians to degrees.
///
/// - Parameter radians: An angle in radians.
/// - Returns: The equivalent angle in degrees.
@inline(__always) func rad2deg(_ radians: Double) -> Double {
    return radians * 180.0 / .pi
}
/// Evaluate a polynomial using Horner's method, **dropping the last coefficient**.
///
/// The final element of `coefficients` is excluded from the evaluation. This
/// exists for the TransverseMercator module where coefficient arrays store a
/// divisor in their last position. For standard polynomial evaluation use
/// ``polyEval(withCoefficients:at:)`` instead.
///
/// Coefficients are in **decreasing** power order (highest power first).
///
/// - Parameters:
///   - coefficients: Polynomial coefficients with an extra trailing element
///     that will be ignored.
///   - x: The point at which to evaluate the polynomial.
/// - Returns: The polynomial value at `x`, computed from all elements except the last.
///
@available(macOS 10.15, *)
public func polyValue(withCoefficients coefficients: [Double], at x: Double) -> Double {
    guard coefficients.count > 0 else { return 0 }
    return coefficients.dropLast().reduce(0.0) {
        return ($0 * x + $1)
    }
}

/// Evaluate a polynomial using Horner's method, using **all** supplied coefficients.
///
/// Unlike `polyValue`, no element is dropped.
/// Coefficients are in **decreasing** power order (first element = coefficient of the
/// highest power).  This matches the ordering produced by GeographicLib's Maxima-generated
/// coefficient tables.
///
/// - Parameters:
///   - coefficients: Polynomial coefficients, highest-power first.
///   - x: The point at which to evaluate the polynomial.
/// - Returns: The polynomial value at `x`.
public func polyEval(withCoefficients coefficients: [Double], at x: Double) -> Double {
    return coefficients.reduce(0.0) { $0 * x + $1 }
}

/// A collection of mathematical constants and utility functions for geographic calculations.
///
/// This type provides constants and functions that correspond to those in
/// GeographicLib::Math, used throughout the geographic projection implementations.
public struct Math {
    /// The conversion factor from degrees to radians (π/180).
    public static let degree : Double = Double.pi / 180
    
    /// Computes the square of a value.
    ///
    /// - Parameter x: The input value.
    /// - Returns: The square of x (x²).
    public static func sq(_ x: Double) -> Double {
        return x * x
    }
    
    /// Normalizes a 2D vector to unit length.
    ///
    /// - Parameters:
    ///   - x: The x component of the vector.
    ///   - y: The y component of the vector.
    /// - Returns: A tuple containing the normalized (x, y) components.
    public static func norm(x: Double, y: Double) -> (x: Double, y: Double) {
        let h = hypot(x, y)
        return (x: x / h, y: y / h)
    }
}

/// Normalize a latitude
/// - Return x if in range [-90...90] else .nan
/// Fixes a latitude value to be in the valid range.
///
/// This function ensures the latitude is in the range [-90°, 90°]. If the
/// latitude is outside this range, NaN is returned.
///
/// - Parameter lat: The latitude in degrees.
/// - Returns: The latitude in degrees if in range [-90, 90], otherwise NaN.
public func latFix(_ lat: Double) -> Double {
    guard lat >= -90 && lat <= 90 else {
        return .nan
    }
    return lat
}

// C++ constants translated to Swift

/// 90 degrees in degrees (qd = "quadrant degrees").
public let qd : Double = 90.0
/// 180 degrees (hd = "half degrees").
public let hd : Double = 2.0 * qd
/// 360 degrees (td = "total degrees").
public let td : Double = 2.0 * hd

/// Computes the difference between two angles.
///
/// Calculates the smallest signed angular difference from angle `x` to angle `y`.
/// The result is in the range (-180°, 180°].
///
/// Delegates to ``angDiffWithError(_:_:)`` for correctness. An earlier
/// implementation used `truncatingRemainder` without a second reduction
/// step, which produced out-of-range results when `|y - x| > 180°`
/// (e.g. `angDiff(170, -170)` returned −340 instead of +20). The bug was
/// discovered while porting the Rhumb module (March 2026).
///
/// - Parameters:
///   - x: The first angle in degrees.
///   - y: The second angle in degrees.
/// - Returns: The signed angular difference from x to y in degrees.
public func angDiff(_ x: Double, _ y: Double) -> Double {
    angDiffWithError(x, y).d
}

/// Calculates the central meridian for a given UTM zone.
///
/// - Parameter zone: The UTM zone number (1-60).
/// - Returns: The central meridian for the zone in degrees.
public func centralMeridian(zone: Int) -> Double {
    return Double(6 * zone) - 183.0
}


/// Swift implementation of GeographicLib::Math::sincosd
/// Compute sin & cos of an angle given in degrees.
///
/// The implementation follows the original C++ algorithm that first reduces the
/// argument to the range [-45°, 45°] and then uses a fast `sincos` call on the
/// radian value.  Edge‑cases for multiples of 30°/45° are handled explicitly.
///
/// C++ Code
/// ``` c++
/// template<typename T> void Math::sincosd(T x, T& sinx, T& cosx) {
/// // In order to minimize round-off errors, this function exactly reduces
/// // the argument to the range [-45, 45] before converting it to radians.
///   T d, r; int q = 0;
///   d = remquo (x, T(qd), &q);   // now abs(r) <= 45
///   r = d * degree<T>();
///    // g++ -O turns these two function calls into a call to sincos
///   T s = sin(r), c = cos(r);
///   if (2 * fabs(d) == qd) {
///     c = sqrt(1/T(2));
///     s = copysign(c, r);
///   } else if (3 * fabs(d) == qd) {
///     c = sqrt(T(3))/2;
///     s = copysign(1/T(2), r);
///   }
///   switch (unsigned(q) & 3U) {
///   case 0U: sinx =  s; cosx =  c; break;
///   case 1U: sinx =  c; cosx = -s; break;
///   case 2U: sinx = -s; cosx = -c; break;
///   default: sinx = -c; cosx =  s; break; // case 3U
///   }
///    // http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1950.pdf
///    // mpreal needs T(0) here
///   cosx += T(0);                            // special values froF.10.1.12
///   if (sinx == 0) sinx = copysign(sinx, x); // special values froF.10.1.13
/// }
///```
public func sincosd(degrees: Double) -> (sin: Double, cos: Double) {
    // Reduce the angle to the range [-90°, 90°] and obtain the quadrant `q`.
    var d: Double = .nan
    var q: Int   = 0
    
    // `remquo` returns the remainder (`d`) and stores the quotient in `q`.
    (d, q) = remquo(degrees, 90.0)
    
    // Convert the reduced angle to radians.
    let r = d * .pi / 180.0
    
    // Compute sin & cos for the reduced angle.
    var s: Double = .nan
    var c: Double = .nan
    __sincos(r, &s, &c)
    
    // Handle exact multiples where rounding errors would be noticeable.
    if 2.0 * fabs(d) == qd {               // |d| == 45°
        c = sqrt(0.5)
        s = copysign(sqrt(0.5), r)         // sin = ±√½, sign matches `r`
    } else if 3.0 * fabs(d) == qd {        // |d| == 30°
        c = sqrt(3.0) / 2.0                // cos 30° = √3/2
        s = copysign(0.5, r)               // sin 30° = ±½
    }
    
    // Adjust the sign/order of the results according to the original quadrant.
    // The C++ code uses `unsigned(q) & 3U` – in Swift we cast `q` to UInt and mask with 3.
    let quadrantMask = UInt(bitPattern: q) & 3

    var sinx: Double
    var cosx: Double
    switch quadrantMask {
    case 0:
        // Quadrant 0: sin =  s, cos =  c
        sinx =  s; cosx =  c
    case 1:
        // Quadrant 1: sin =  c, cos = -s
        sinx =  c; cosx = -s
    case 2:
        // Quadrant 2: sin = -s, cos = -c
        sinx = -s; cosx = -c
    default: // case 3
        // Quadrant 3: sin = -c, cos =  s
        sinx = -c; cosx =  s
    }
    // Per IEEE 754 F.10.1.12–13: ensure +0 for zero cosine; sign of zero sine matches input.
    cosx += 0
    if sinx == 0 { sinx = copysign(sinx, degrees) }
    return (sinx, cosx)
}

/// Swift Implementation of GeographicLib::Math::eatanhe
///
/// C++ Code
/// ```c++
///template<typename T> T Math::eatanhe(T x, T es)  {
///  return es > 0 ? es * atanh(es * x) : -es * atan(es * x);
///}
/// ```

/// Computes the elliptic atanh function.
///
/// This function computes es * atanh(es * x) for es > 0, or -es * atan(es * x) for es < 0.
/// It's used in the conversion between geodetic and conformal latitudes.
///
/// - Parameters:
///   - x: The input value.
///   - es: The ellipsoid parameter (first eccentricity), positive or negative.
/// - Returns: The result of the elliptic atanh function.
public func eatanhe(_ x: Double, _ es: Double) -> Double {
    return es > 0 ? es * atanh(es * x) : -es * atan(es * x)
}

/// Swift Implementation of GeographicLib::Math::taupf
///
/// C++ Code
/// ``` c++
///template<typename T> T Math::taupf(T tau, T es) {
///  // Need this test, otherwise tau = +/-inf gives taup = nan.
///  if (isfinite(tau)) {
///    T tau1 = hypot(T(1), tau),
///      sig = sinh( eatanhe(tau / tau1, es ) );
///    return hypot(T(1), sig) * tau - sig * tau1;
///  } else
///    return tau;
///}
///```
/// Converts from geodetic latitude parameter to conformal latitude parameter.
///
/// Given tau = tan(phi) where phi is the geodetic latitude, this function
/// returns taup = tan(phi') where phi' is the conformal latitude.
///
/// The conformal latitude is used in the transverse Mercator projection
/// to simplify the conformal mapping.
///
/// - Parameters:
///   - tau: The parameter tan(phi) where phi is the geodetic latitude.
///   - es: The ellipsoid parameter (first eccentricity).
/// - Returns: The parameter tan(phi') where phi' is the conformal latitude.
public func taupf(_ tau: Double, _ es: Double) -> Double {
    if tau.isFinite {
        let tau1 = hypot(1, tau)
        let sig = sinh( eatanhe(tau / tau1, es))
        return hypot(1.0, sig) * tau - sig * tau1
    } else {
        return tau
    }
}

/// Swift Implementation of GeographicLib::Math::atan2d
///
/// ``` c++
///template<typename T> T Math::atan2d(T y, T x) {
///  // In order to minimize round-off errors, this function rearranges the
///  // arguments so that result of atan2 is in the range [-pi/4, pi/4] before
///  // converting it to degrees and mapping the result to the correct quadrant.
///  // With mpreal we could use T(mpfr::atan2u(y, x, td)); but we're not ready
///  // for this yet.
///  int q = 0;
///  if (fabs(y) > fabs(x)) { swap(x, y); q = 2; }
///  if (signbit(x)) { x = -x; ++q; }
///  // here x >= 0 and x >= abs(y), so angle is in [-pi/4, pi/4]
///  // Replace atan2(y, x) / degree<T>() by this to ensure that special values
///  // (45, 90, etc.) are returned.
///  T ang = (atan2(y, x) / pi<T>()) * T(hd);
///  switch (q) {
///  case 1: ang = copysign(T(hd), y) - ang; break;
///  case 2: ang =            qd      - ang; break;
///  case 3: ang =           -qd      + ang; break;
///  default: break;
///  }
///  return ang;
///}
///```
/// Computes the arc tangent of y/x and returns the result in degrees.
///
/// This function computes the angle in degrees whose tangent is y/x, using
/// the signs of both arguments to determine the correct quadrant.
///
/// The implementation is designed to minimize round-off errors by ensuring
/// the result is in the range [-π/4, π/4] before converting to degrees
/// and mapping to the correct quadrant. Special handling is provided for
/// angles of 45°, 90°, 135°, etc.
///
/// - Parameters:
///   - y: The y component (sin component).
///   - x: The x component (cos component).
/// - Returns: The arc tangent of y/x in degrees, in the range (-180°, 180°].
public func atan2d(_ y: Double, _ x: Double) -> Double {
    // Work with mutable copies so we can swap / modify as needed.
    var xx = x
    var yy = y
    var q = 0                     // quadrant indicator

    // If |y| > |x| we swap the arguments and note the change.
    if fabs(yy) > fabs(xx) {
        swap(&xx, &yy)
        q = 2
    }

    // If the (possibly swapped) x is negative we flip its sign and
    // increment the quadrant counter.
    if xx.sign == .minus {
        xx = -xx
        q += 1
    }

    // At this point: xx >= 0 and xx >= |yy|, so atan2(yy, xx) lies in [-π/4, π/4].
    // Convert the result from radians to degrees using the constant `hd` (180°).
    let ang = atan2(yy, xx) / .pi * hd

    // Adjust the angle according to the original quadrant.
    switch q {
    case 1:
        // Quadrant 1: angle = sign(y)*hd - ang
        return copysign(hd, y) - ang
    case 2:
        // Quadrant 2: angle = qd - ang (90° – ang)
        return qd - ang
    case 3:
        // Quadrant 3: angle = -qd + ang (-90° + ang)
        return -qd + ang
    default:
        // Quadrant 0 (no adjustment needed).
        return ang
    }
}

/// Computes the square of a value.
///
/// - Parameter x: The input value.
/// - Returns: The square of x (x²).
public func sq(_ x: Double) -> Double {
    return x * x
}

/// Computes the arc tangent of a value and returns the result in degrees.
///
/// - Parameter x: The tangent value.
/// - Returns: The arc tangent of x in degrees, in the range [-90°, 90°].
public func atand(_ x: Double) -> Double {
    return rad2deg(atan(x))
}

/// Computes the tangent of an angle given in degrees.
///
/// - Parameter degrees: The angle in degrees.
/// - Returns: The tangent of the angle.
public func tand(_ degrees: Double) -> Double {
    return tan(deg2rad(degrees))
}

/// Converts from conformal latitude parameter to geodetic latitude parameter.
///
/// This is the inverse of `taupf`. Given the parameter taup = tan(phi') where
/// phi' is the conformal latitude, this function returns tau = tan(phi) where
/// phi is the geodetic latitude.
///
/// The conversion uses Newton's method to solve for tau.
///
/// - Parameters:
///   - taup: The parameter tan(phi') where phi' is the conformal latitude.
///   - es: The ellipsoid parameter (first eccentricity).
/// - Returns: The parameter tan(phi) where phi is the geodetic latitude.
public func tauf(_ taup: Double, _ es: Double) -> Double {
    let numit = 5
    let tol = sqrt(Double.ulpOfOne) / 10
    let taumax = 2 / sqrt(Double.ulpOfOne)
    let e2m = 1 - es * es
    var tau = fabs(taup) > 70 ? taup * exp(eatanhe(1, es)) : taup / e2m
    if !(fabs(tau) < taumax) { return tau }
    let stol = tol * max(1.0, fabs(taup))
    for _ in 0..<numit {
        let taupa = taupf(tau, es)
        let dtau = (taup - taupa) * (1 + e2m * sq(tau)) /
            (e2m * hypot(1, tau) * hypot(1, taupa))
        tau += dtau
        if !(fabs(dtau) >= stol) { break }
    }
    return tau
}

/// Swift implementation of GeographicLib:Math::AngNormalize
///
/// ``` c++
/// template<typename T> T Math::AngNormalize(T x) {
///  T y = remainder(x, T(td));
///   return fabs(y) == T(hd) ? copysign(T(hd), x) : y;
/// }
/// ```
public func angNormalize(_ x: Double) -> Double {
    let y = remainder(x, td)
    return fabs(y) == hd ? copysign(hd, x) : y
}

/// Swift implementation of GeographicLib::Math::sum (Knuth two-sum).
///
/// Returns s = u + v exactly and sets t to the round-off error such that
/// s + t == u + v to infinite precision.  The `volatile` qualifier in the
/// C++ source exists to prevent the compiler from collapsing the arithmetic;
/// Swift's IEEE-754 semantics make that unnecessary here.
///
/// C++ Code:
/// ```cpp
/// template<typename T> T Math::sum(T u, T v, T& t) {
///   volatile T s = u + v, up = s - v, vpp = s - up;
///   up -= u; vpp -= v;
///   t = s != 0 ? -(up + vpp) : s;
///   return s;
/// }
/// ```
@inline(__always) func mathSum(_ u: Double, _ v: Double) -> (s: Double, t: Double) {
    let s = u + v
    let up = s - v
    let vpp = s - up
    let t: Double = s != 0 ? -((up - u) + (vpp - v)) : s
    return (s, t)
}

/// Exact angle difference of two angles, also returning the round-off error.
///
/// Returns (d, e) where d is the principal difference in (−180°, 180°] and
/// e is the error such that the true difference equals d + e (with |e| much
/// smaller than ulp(d)).
///
/// C++ Code:
/// ```cpp
/// template<typename T> T Math::AngDiff(T x, T y, T& e) {
///   T d = sum(remainder(-x,td), remainder(y,td), e);
///   d = sum(remainder(d,td), e, e);
///   if (d == 0 || fabs(d) == hd)
///     d = copysign(d, e == 0 ? y - x : -e);
///   return d;
/// }
/// ```
public func angDiffWithError(_ x: Double, _ y: Double) -> (d: Double, e: Double) {
    var (d, e) = mathSum(remainder(-x, td), remainder(y, td))
    let s2: Double
    (d, s2) = mathSum(remainder(d, td), e)
    let e2 = s2
    var df = d
    if df == 0 || abs(df) == hd {
        df = copysign(df, e2 == 0 ? y - x : -e2)
    }
    return (df, e2)
}

/// Swift implementation of GeographicLib::Math::AngRound
///
/// Coarsens a value close to zero so that near-zero inputs are not treated
/// as essentially zero. The smallest non-zero gap for doubles is 1/2^57 ≈ 7 pm
/// on the Earth (for angles in degrees). The sign of ±0 is preserved.
///
/// C++ Code:
/// ```cpp
/// template<typename T> T Math::AngRound(T x) {
///   static const T z = T(1)/T(16);
///   GEOGRAPHICLIB_VOLATILE T y = fabs(x);
///   GEOGRAPHICLIB_VOLATILE T w = z - y;
///   y = w > 0 ? z - w : y;
///   return copysign(y, x);
/// }
/// ```
public func angRound(_ x: Double) -> Double {
    let z: Double = 1.0 / 16.0
    let y = abs(x)
    let w = z - y
    let yr = w > 0 ? z - w : y
    return copysign(yr, x)
}

/// Swift implementation of GeographicLib::Math::sincosde
///
/// Evaluates sin and cos of (x + t) where x is in [-180°, 180°] and t is a small
/// correction. AngRound is applied to the reduced angle to prevent problems with
/// x + t being extremely close but not exactly equal to a cardinal direction.
///
/// C++ Code:
/// ```cpp
/// template<typename T> void Math::sincosde(T x, T t, T& sinx, T& cosx) {
///   int q = 0;
///   T d = AngRound(remquo(x, T(qd), &q) + t),
///     r = d * degree<T>();
///   T s = sin(r), c = cos(r);
///   if (2 * fabs(d) == qd) { c = sqrt(1/T(2)); s = copysign(c, r); }
///   else if (3 * fabs(d) == qd) { c = sqrt(T(3))/2; s = copysign(1/T(2), r); }
///   switch (unsigned(q) & 3U) {
///   case 0U: sinx =  s; cosx =  c; break;
///   case 1U: sinx =  c; cosx = -s; break;
///   case 2U: sinx = -s; cosx = -c; break;
///   default: sinx = -c; cosx =  s; break;
///   }
/// }
/// ```
public func sincosde(_ x: Double, _ t: Double) -> (sin: Double, cos: Double) {
    var qi: Int = 0
    let rem: Double
    (rem, qi) = remquo(x, qd)
    let d = angRound(rem + t)
    let r = d * Math.degree
    var s = sin(r)
    var c = cos(r)
    if 2.0 * abs(d) == qd {
        c = sqrt(0.5)
        s = copysign(sqrt(0.5), r)
    } else if 3.0 * abs(d) == qd {
        c = sqrt(3.0) / 2.0
        s = copysign(0.5, r)
    }
    let quadrantMask = UInt(bitPattern: qi) & 3
    switch quadrantMask {
    case 0: return (s, c)
    case 1: return (c, -s)
    case 2: return (-s, -c)
    default: return (-c, s)
    }
}

/// Returns the MGRS latitude band index for a given latitude.
///
/// The index ranges from −10 to 9, corresponding to the 20 MGRS latitude
/// bands (each 8° wide) that span from 80° S to 84° N.
///
/// - Parameter latitude: The latitude in degrees.
/// - Returns: The band index in the range [−10, 9].
public func band(latitude: Double) -> Int {
//    static int LatitudeBand(real lat) {
//      using std::floor;
//      int ilat = int(floor(lat));
//      return (std::max)(-10, (std::min)(9, (ilat + 80)/8 - 10));
//    }
    let ilat = Int(floor(latitude))
    return max(-10, min(9, (ilat + 80)/8 - 10))
}
