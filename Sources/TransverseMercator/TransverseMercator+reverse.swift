//
//  TransverseMercator+reverse.swift
//  SwiftGeoLib
//
//  Created by David Hart on 6/3/2026.
//


import Foundation
import CoreLocation
import ComplexModule
import TransverseMercatorInternal
import Math

public extension TransverseMercator {
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
    func reverse(centralMeridian: Double,
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