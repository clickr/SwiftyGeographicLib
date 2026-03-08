//
//  reverse.swift
//  SwiftGeoLib
//
//  Created by David Hart on 6/3/2026.
//
import Foundation
import CoreLocation
import ComplexModule
import RealModule
import Math
import TransverseMercatorInternal


public extension TransverseMercatorStaticInternal {
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
    /// - SeeAlso: ``reverse(centralMeridian:x:y:)``
    static func forward(centralMeridian: Double,
                        geodeticCoordinate: CLLocationCoordinate2D) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
        return _TransverseMercatorStaticInternal.forward(centralMeridian: centralMeridian, geodeticCoordinate: geodeticCoordinate,
                                                         
                                                         centralScale: centralScale,
                                                         _e2: _e2,
                                                         _es: _es,
                                                         _e2m: _e2m,
                                                         _c: _c,
                                                         _b1: _b1,
                                                         _a1: _a1,
                                                         _alp: _alp)
//        var lat = latFix(geodeticCoordinate.latitude)
//        var lon = angDiff(centralMeridian, geodeticCoordinate.longitude)
//        var latsign : Int = lat.sign == .minus ? -1 : 1
//        let lonsign : Int = lon.sign == .minus ? -1 : 1
//        lon *= Double(lonsign)
//        lat *= Double(latsign)
//        
//        let backside = lon > qd
//        if backside {
//            if lat == 0 {
//                latsign = -1
//            }
//            lon = hd - lon
//        }
//        var sphi, cphi : Double
//        (sphi, cphi) = sincosd(degrees: lat)
//        
//        var slam, clam : Double
//        (slam, clam) = sincosd(degrees: lon)
//        
//        var etap, xip : Double
//        var gamma: Double = .nan
//        var k: Double = .nan
//        if lat != qd {
//            let tau = sphi / cphi
//            let taup = taupf(tau, _es)
//            xip = atan2(taup, clam)
//            etap = asinh(slam / hypot(taup, clam))
//            gamma = atan2d(slam * taup, clam * hypot(1.0, taup))
//            k = sqrt(_e2m + _e2 * sq(cphi)) * hypot(1.0, tau) / hypot(taup, clam)
//        } else {
//            xip = .pi / 2
//            etap = 0
//            gamma = lon
//            k = _c
//        }
//        
//        let c0 = cos(2 * xip)
//        let ch0 = cosh(2 * etap)
//        let s0 = sin(2 * xip)
//        let sh0 = sinh(2 * etap)
//        
//        let aComplex = Complex<Double>(2 * c0 * ch0, -2 * s0 * sh0)
//        let n = _alp.count - 1
//        var y0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(_alp[n], 0) : Complex<Double>(0, 0)
//        var y1: Complex<Double> = Complex<Double>(0, 0)
//        var z0: Complex<Double> = (n & 1) == 1 ? Complex<Double>(2 * Double(n) * _alp[n], 0) : Complex<Double>(0, 0)
//        var z1: Complex<Double> = Complex<Double>(0, 0)
//        var nn = n
//        if (nn & 1) != 0 { nn -= 1 }
//        while nn > 0 {
//            y1 = aComplex * y0 - y1 + Complex<Double>(_alp[nn], 0)
//            z1 = aComplex * z0 - z1 + Complex<Double>(2 * Double(nn) * _alp[nn], 0)
//            nn -= 1
//            y0 = aComplex * y1 - y0 + Complex<Double>(_alp[nn], 0)
//            z0 = aComplex * z1 - z0 + Complex<Double>(2 * Double(nn) * _alp[nn], 0)
//            nn -= 1
//        }
//        var aDiv2 = aComplex / Complex<Double>(2, 0)
//        z1 = Complex<Double>(1, 0) - z1 + aDiv2 * z0
//        aDiv2 = Complex<Double>(s0 * ch0, c0 * sh0)
//        y1 = Complex<Double>(xip, etap) + aDiv2 * y0
//        
//        let xi = y1.real
//        let eta = y1.imaginary
//        
//        gamma -= atan2d(z1.imaginary, z1.real)
//        let z1Mag = sqrt(z1.real * z1.real + z1.imaginary * z1.imaginary)
//        k *= _b1 * z1Mag
//        
//        let x = _a1 * centralScale * eta * Double(lonsign)
//        let y = _a1 * centralScale * (backside ? .pi - xi : xi) * Double(latsign)
//        
//        if backside {
//            gamma = hd - gamma
//        }
//        gamma *= Double(latsign * lonsign)
//        
//        while gamma > 180 { gamma -= 360 }
//        while gamma <= -180 { gamma += 360 }
//        
//        k *= centralScale
//        
//        return (x: x, y: y, convergence: gamma, centralScale: k)
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
    ///   - latitude: geodetic latitude.
    ///   - longitude: longitude.
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
    /// - SeeAlso: ``forward(centralMeridian:geodeticCoordinate:)``
    static func forward(centralMeridian: Double, latitude: Double, longitude: Double) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
        return forward(centralMeridian: centralMeridian, geodeticCoordinate: .init(latitude: latitude, longitude: longitude))
    }
}
