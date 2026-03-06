// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import CoreLocation
import ComplexModule
import TransverseMercatorInternal
import Math

public enum TransverseMercatorError: Error, Equatable {
    case equatorialRadiusNotPositive
    case polarSemiAxisNotPositive
    case scaleNotPositive
    case illegalLatitude(latitude: Double)
}

/// A transverse Mercator projection implementation.
///
/// This struct provides functionality for converting between geographic coordinates
/// (latitude and longitude) and transverse Mercator projection coordinates
/// (easting and northing).
///
/// The transverse Mercator projection is a conformal map projection that
/// stretches the sphere along a central meridian. This implementation uses
/// Krüger's method as described in:
/// - L. Krüger, "Konforme Abbildung des Erdellipsoids in der Ebene" (1912)
/// - C. F. F. Karney, "Transverse Mercator with an accuracy of a few
///   nanometers," J. Geodesy 85(8), 475--485 (2011)
///
/// The projection achieves accuracy of about 5 nanometers within 35 degrees
/// of the central meridian, with a convergence error of about 2 × 10⁻¹⁵ arcseconds
/// and relative scale error of about 6 × 10⁻¹².
///
/// There is a singularity in the projection at latitude 0° and longitude offset
/// of approximately ±82.6° from the central meridian. Beyond this point, the
/// series ceases to converge and results will be unreliable.
///
/// - Note: This projection does not include false easting or false northing.
///   These can be added by the caller if needed (as done in UTMUPS).
///
/// ## Example
/// ```swift
/// let utm = TransverseMercator.UTM
/// let coord = CLLocationCoordinate2D(latitude: 45.0, longitude: -75.0)
/// let result = utm.forward(centralMeridian: -75, coordinate2D: coord)
/// print("Easting: \\(result.x), Northing: \\(result.y)")
/// ```
public struct TransverseMercator : Sendable{
    public static let UTM : TransverseMercator = try! TransverseMercator(
        equatorialRadius: 6378137.0,
        flattening: 1.0 / 298.257223563,
        scaleFactor: 0.9996)
    internal let a: Double
    internal let f: Double
    internal let k0: Double
    internal let e2: Double
    internal let es: Double
    internal let e2m: Double
    internal let c: Double
    internal let n: Double
    internal let b1: Double
    internal let a1: Double
    internal let alp: [Double]
    internal let bet: [Double]
    public init(equatorialRadius: Double, flattening: Double, scaleFactor: Double) throws (TransverseMercatorError) {
        guard equatorialRadius.isFinite, equatorialRadius > 0 else {
            throw .equatorialRadiusNotPositive
        }
        guard flattening.isFinite, flattening < 1 else {
            throw .polarSemiAxisNotPositive
        }
        guard scaleFactor.isFinite, scaleFactor > 0 else {
            throw .scaleNotPositive
        }
        
        (self.n,
         self.a1,
         self.b1,
         self.c,
         self.e2,
         self.e2m,
         self.es,
         self.alp,
         self.bet) = computeInternlTransverseMercator(flattening: flattening,
                                                      equatorialRadius: equatorialRadius)
        self.a = equatorialRadius
        self.f = flattening
        self.k0 = scaleFactor
    }
    
    /// Forward projection, from geographic to transverse Mercator.
    ///
    /// This function converts a geographic coordinate (latitude and longitude) to
    /// transverse Mercator projection coordinates (easting, northing).
    ///
    /// The transverse Mercator projection is a conformal map projection that
    /// stretches the sphere along a central meridian. This implementation uses
    /// Krüger's method with a 6th order series approximation, providing accuracy
    /// of about 5 nanometers within 35 degrees of the central meridian.
    ///
    /// - Parameters:
    ///   - centralMeridian: The central meridian of the projection in degrees.
    ///     This is the longitude at which the projection has no distortion.
    ///   - coordinate2D: The geographic coordinate to convert.
    ///
    /// - Returns: A tuple containing:
    ///   - x: The easting of the point in meters.
    ///   - y: The northing of the point in meters.
    ///   - convergence: The meridian convergence at the point in degrees. This is
    ///     the angle between grid north and true north.
    ///   - centralScale: The scale factor of the projection at the point.
    ///
    /// - Note: No false easting or false northing is added. The latitude should
    ///   be in the range [-90°, 90°].
    ///
    /// - SeeAlso: ``reverse(centralMeridian:x:y:)-7x4k4``
    public func forward(centralMeridian: Double, coordinate2D: CLLocationCoordinate2D) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
        var lat = latFix(coordinate2D.latitude)
        var lon = angDiff(centralMeridian, coordinate2D.longitude)
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
            let taup = taupf(tau, self.es)
            xip = atan2(taup, clam)
            etap = asinh(slam / hypot(taup, clam))
            gamma = atan2d(slam * taup, clam * hypot(1.0, taup))
            k = sqrt(self.e2m + self.e2 * sq(cphi)) * hypot(1.0, tau) / hypot(taup, clam)
        } else {
            xip = .pi / 2
            etap = 0
            gamma = lon
            k = c
        }
        
        let c0 = cos(2 * xip)
        let ch0 = cosh(2 * etap)
        let s0 = sin(2 * xip)
        let sh0 = sinh(2 * etap)
        
        let aComplex = Complex<Double>(2 * c0 * ch0, -2 * s0 * sh0)
        let n = alp.count - 1
        var y0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(alp[n], 0) : Complex<Double>(0, 0)
        var y1: Complex<Double> = Complex<Double>(0, 0)
        var z0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(2 * Double(n) * alp[n], 0) : Complex<Double>(0, 0)
        var z1: Complex<Double> = Complex<Double>(0, 0)
        var nn = n
        if (nn & 1) != 0 { nn -= 1 }
        while nn > 0 {
            y1 = aComplex * y0 - y1 + Complex<Double>(alp[nn], 0)
            z1 = aComplex * z0 - z1 + Complex<Double>(2 * Double(nn) * alp[nn], 0)
            nn -= 1
            y0 = aComplex * y1 - y0 + Complex<Double>(alp[nn], 0)
            z0 = aComplex * z1 - z0 + Complex<Double>(2 * Double(nn) * alp[nn], 0)
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
        k *= self.b1 * z1Mag
        
        let x = self.a1 * self.k0 * eta * Double(lonsign)
        let y = self.a1 * self.k0 * (backside ? .pi - xi : xi) * Double(latsign)
        
        if backside {
            gamma = hd - gamma
        }
        gamma *= Double(latsign * lonsign)
        
        while gamma > 180 { gamma -= 360 }
        while gamma <= -180 { gamma += 360 }
        
        k *= self.k0
        
        return (x: x, y: y, convergence: gamma, centralScale: k)
    }
    
    /// Forward projection, from geographic to transverse Mercator.
    ///
    /// This function converts a geographic coordinate (latitude and longitude) to
    /// transverse Mercator projection coordinates (easting, northing).
    ///
    /// - Parameters:
    ///   - centralMeridian: The central meridian of the projection in degrees.
    ///   - latitude: The latitude of the point in degrees.
    ///   - longitude: The longitude of the point in degrees.
    ///
    /// - Returns: A tuple containing:
    ///   - x: The easting of the point in meters.
    ///   - y: The northing of the point in meters.
    ///   - convergence: The meridian convergence at the point in degrees.
    ///   - scale: The scale factor of the projection at the point.
    ///
    /// - Note: This is a convenience overload that accepts separate latitude and
    ///   longitude parameters instead of a `CLLocationCoordinate2D`.
    ///
    /// - SeeAlso: ``forward(centralMeridian:coordinate2D:)-9d7s0``
    public func forward(centralMeridian: Double, latitude: Double, longitude: Double) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
        return self.forward(centralMeridian: centralMeridian, coordinate2D: .init(latitude: latitude, longitude: longitude))
    }
    
    /// Reverse projection, from transverse Mercator to geographic.
    ///
    /// This function converts transverse Mercator projection coordinates (easting,
    /// northing) back to geographic coordinates (latitude, longitude).
    ///
    /// The transverse Mercator projection is a conformal map projection that
    /// stretches the sphere along a central meridian. This implementation uses
    /// Krüger's method with a 6th order series approximation, providing accuracy
    /// of about 5 nanometers within 35 degrees of the central meridian.
    ///
    /// - Parameters:
    ///   - centralMeridian: The central meridian of the projection in degrees.
    ///     This is the longitude at which the projection has no distortion.
    ///   - x: The easting of the point in meters.
    ///   - y: The northing of the point in meters.
    ///
    /// - Returns: A tuple containing:
    ///   - coordinate: The geographic coordinate (latitude and longitude in degrees).
    ///   - convergence: The meridian convergence at the point in degrees. This is
    ///     the angle between grid north and true north.
    ///   - centralScale: The scale factor of the projection at the point.
    ///
    /// - Note: No false easting or false northing is added. The longitude returned
    ///   is in the range [-180°, 180°].
    ///
    /// - SeeAlso: ``forward(centralMeridian:coordinate2D:)-9d7s0``
    public func reverse(centralMeridian: Double,
                        x: Double,
                        y: Double) -> (coordinate: CLLocationCoordinate2D, convergence: Double, centralScale: Double) {
        var xi = y / (self.a1 * self.k0)
        var eta = x / (self.a1 * self.k0)
        
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
        let n = bet.count - 1
        var y0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(-bet[n], 0) : Complex<Double>(0, 0)
        var y1: Complex<Double> = Complex<Double>(0, 0)
        var z0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(-2 * Double(n) * bet[n], 0) : Complex<Double>(0, 0)
        var z1: Complex<Double> = Complex<Double>(0, 0)
        var nn = n
        if (nn & 1) != 0 { nn -= 1 }
        while nn > 0 {
            y1 = aComplex * y0 - y1 - Complex<Double>(bet[nn], 0)
            z1 = aComplex * z0 - z1 - Complex<Double>(2 * Double(nn) * bet[nn], 0)
            nn -= 1
            y0 = aComplex * y1 - y0 - Complex<Double>(bet[nn], 0)
            z0 = aComplex * z1 - z0 - Complex<Double>(2 * Double(nn) * bet[nn], 0)
            nn -= 1
        }
        var aDiv2 = aComplex / Complex<Double>(2, 0)
        z1 = Complex<Double>(1, 0) - z1 + aDiv2 * z0
        aDiv2 = Complex<Double>(s0 * ch0, c0 * sh0)
        y1 = Complex<Double>(xi, eta) + aDiv2 * y0
        
        var gamma = atan2d(z1.imaginary, z1.real)
        var k = self.b1 / sqrt(z1.real * z1.real + z1.imaginary * z1.imaginary)
        
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
            let tau = tauf(sxip / r, self.es)
            gamma += atan2d(sxip * Foundation.tanh(etap), c)
            lat = atand(tau)
            k *= sqrt(self.e2m + self.e2 / (1 + sq(tau))) * hypot(1.0, tau) * r
        } else {
            lat = qd
            lon = 0
            k *= self.c
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
        
        k *= self.k0
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return (coordinate: coordinate, convergence: gamma, centralScale: k)
    }
}

