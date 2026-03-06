//
//  TransverseMercatorInternal.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 28/2/2026.
//

import Foundation
import Math

//
//func eatanhe(_ x: Double, _ e: Double) -> Double {
//    if e > 0 {
//        return e * atanh(e * x)
//    } else {
//        return -e * atan(e * x)
//    }
//}
//
//func angDiff(_ lon0: Double, _ lon: Double) -> Double {
//    var d = (lon - lon0).truncatingRemainder(dividingBy: 360)
//    while d > 180 { d -= 360 }
//    while d < -180 { d += 360 }
//    return d
//}
//
//
///// Normalize a latitude
///// - Return x if in range [-90...90] else .nan
//func latFix(_ lat: Double) -> Double {
//    guard lat >= -90 && lat <= 90 else {
//        return .nan
//    }
//    return lat
//}

/// Calculate a polynomial
///
/// Uses Horner's method as referenced
/// [Rosetta Code](https://rosettacode.org/wiki/Horner%27s_rule_for_polynomial_evaluation#Swift)
/// except coefficients are for increasing powers of x and the final term is ignored (intended to be used in further calculations)
///
@available(macOS 10.15, *)
public func polyValue(withCoefficients coefficients: [Double], at x: Double) -> Double {
    guard coefficients.count > 0 else { return 0 }
    return coefficients.dropLast().reduce(0) {
        return ($0 * x + $1)
    }
}

public func computeB1(x: Double) -> Double {
    let betaCoeffs : [Double] = [1, 4, 64, 256, 256,]
    return polyValue(withCoefficients: betaCoeffs, at: x * x) / (256.0 * (1.0 + x))
}
public func computeAlp(x: Double) -> [Double] {
    var _x = x
    var res : [Double] = Array(repeating: 0, count: 7)
    let alphaCoeffs : [[Double]] = [
        // alp[1]/n^1, polynomial in n of order 5
        [31564, -66675, 34440, 47250, -100800, 75600, 151200,],
        // alp[2]/n^2, polynomial in n of order 4
        [-1983433, 863232, 748608, -1161216, 524160, 1935360,],
        // alp[3]/n^3, polynomial in n of order 3
        [670412, 406647, -533952, 184464, 725760,],
        // alp[4]/n^4, polynomial in n of order 2
        [6601661, -7732800, 2230245, 7257600,],
        // alp[5]/n^5, polynomial in n of order 1
        [-13675556, 3438171, 7983360,],
        // alp[6]/n^6, polynomial in n of order 0
        [212378941, 319334400,],
    ]
    for (n, c) in alphaCoeffs.enumerated() {
        res[n + 1] = _x * polyValue(withCoefficients: c, at: x) / (c.last ?? 1)
        _x *= x
    }
    return res
}

public func computeBet(x: Double) -> [Double] {
    var _x = x
    var res : [Double] = Array(repeating: 0, count: 7)
    let betaCoeffs : [[Double]] = [
        // bet[1]/n^1, polynomial in n of order 5
        [384796, -382725, -6720, 932400, -1612800, 1209600, 2419200,],
        // bet[2]/n^2, polynomial in n of order 4
        [-1118711, 1695744, -1174656, 258048, 80640, 3870720,],
        // bet[3]/n^3, polynomial in n of order 3
        [22276, -16929, -15984, 12852, 362880,],
        // bet[4]/n^4, polynomial in n of order 2
        [-830251, -158400, 197865, 7257600,],
        // bet[5]/n^5, polynomial in n of order 1
        [-435388, 453717, 15966720,],
        // bet[6]/n^6, polynomial in n of order 0
        [20648693, 638668800,],
    ]
    for (n, c) in betaCoeffs.enumerated() {
        res[n + 1] = _x * polyValue(withCoefficients: c, at: x) / (c.last ?? 1)
        _x *= x
    }
    return res
}

public func computeInternlTransverseMercator(flattening: Double, equatorialRadius: Double) -> (
    n: Double,
    a1: Double,
    b1: Double,
    c: Double,
    e2: Double,
    e2m: Double,
    es: Double,
    alp: [Double],
    bet: [Double]) {
            let local_n = flattening / (2 - flattening)
            let local_b1 = computeB1(x: local_n)
            let local_e2 = flattening * (2 - flattening)
            let local_es = sqrt(fabs(local_e2))
            let local_e2m = 1 - local_e2
            let local_c = sqrt(local_e2m) * exp(eatanhe(1.0, local_es))
            return (n: local_n,
                    a1: local_b1 * equatorialRadius,
                    b1: computeB1(x: local_n),
                    c: local_c,
                    e2: local_e2,
                    e2m: local_e2m,
                    es: local_es,
                    alp: computeAlp(x: local_n),
                    bet: computeBet(x: local_n))
}
