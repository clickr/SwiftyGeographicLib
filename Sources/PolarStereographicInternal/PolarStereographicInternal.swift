//
//  PolarStereographicInternal.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//
import Foundation
import Math

public func polarStereographicInternal(flattening: Double) -> (e2: Double, es: Double, e2m: Double, c: Double) {
    let e2 = flattening * (2 - flattening)
    let es = (flattening < 0 ? -1 : 1) * sqrt(abs(e2))
    let e2m = 1 - e2
    let c = (1 - flattening) * exp(eatanhe(1, es))
    return (e2, es, e2m, c)
}
