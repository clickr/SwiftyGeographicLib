//
//  TransverseMercatorInternalTests.swift
//  GeographicLib
//
//  Created by David Hart on 5/3/2026.
//

import Testing
@testable import TransverseMercatorInternal
import SimpleGeographicLib


let utm = GeographicLib.TransverseMercator.UTM().pointee

@Test func initUTM() {
    let internalUTM = computeInternalTransverseMercator(flattening: utm.Flattening(), equatorialRadius: utm.EquatorialRadius())

    #expect(internalUTM.n == utm._n)
    #expect(internalUTM.a1 == utm._a1)
    #expect(internalUTM.b1 == utm._b1)
    #expect(internalUTM.c == utm._c)
    #expect(internalUTM.e2 == utm._e2)
    #expect(internalUTM.e2m == utm._e2m)
    #expect(internalUTM.es == utm._es)
    let alp = internalUTM.alp
    let bet = internalUTM.bet
    #expect(alp[1] == utm._alp.1)
    #expect(bet[1] == utm._bet.1)
    #expect(alp[2] == utm._alp.2)
    #expect(bet[2] == utm._bet.2)
    #expect(alp[3] == utm._alp.3)
    #expect(bet[3] == utm._bet.3)
    #expect(alp[4] == utm._alp.4)
    #expect(bet[4] == utm._bet.4)
    #expect(alp[5] == utm._alp.5)
    #expect(bet[5] == utm._bet.5)
    #expect(alp[6] == utm._alp.6)
    #expect(bet[6] == utm._bet.6)
}
