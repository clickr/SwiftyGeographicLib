import Testing
import Foundation
@testable import Rhumb

@Suite("Debug")
struct DebugTests {
    @Test("Coefficient arrays have correct size")
    func coeffArraySizes() {
        #expect(AuxCoeffs.coeffs.count == 522)
        #expect(AuxCoeffs.ptrs.count == 37)
        #expect(AuxCoeffs.areaCoeffs.count == 21)
        #expect(AuxCoeffs.rectifyingRadiusCoeffs.count == 4)
        #expect(AuxCoeffs.authalicRadiusSqCoeffs.count == 7)
    }

    @Test("AuxAngle basic operations")
    func auxAngleBasics() {
        let a = AuxAngle.degrees(45)
        #expect(abs(a.degrees() - 45) < 1e-12)
        #expect(abs(a.radians() - Double.pi/4) < 1e-12)
        let n = a.normalized()
        #expect(abs(n.y - sin(Double.pi/4)) < 1e-12)
        #expect(abs(n.x - cos(Double.pi/4)) < 1e-12)
    }

    @Test("AuxLatitude constructor")
    func auxLatInit() {
        let aux = AuxLatitude(a: 6_378_137, f: 1/298.257223563)
        #expect(aux._a == 6_378_137)
        #expect(abs(aux._f - 1/298.257223563) < 1e-15)
        #expect(abs(aux._n) < 0.01) // small for WGS84
    }

    @Test("AuxLatitude rectifying radius")
    func rectifyingRadius() {
        let aux = AuxLatitude(a: 6_378_137, f: 1/298.257223563)
        let rm = aux.rectifyingRadius()
        #expect(rm > 6_356_000)
        #expect(rm < 6_378_137)
    }

    @Test("AuxLatitude convert PHI to CHI")
    func convertPhiToChi() {
        let aux = AuxLatitude(a: 6_378_137, f: 1/298.257223563)
        let phi = AuxAngle.degrees(45)
        let chi = aux.convert(0, 4, phi)
        let chiDeg = chi.degrees()
        // Conformal lat should be close to geographic for small f
        #expect(abs(chiDeg - 45) < 1.0)
        #expect(abs(chiDeg - 44.80757678) < 0.001) // approximate value
    }

    @Test("Rhumb init does not crash")
    func rhumbInit() {
        let r = Rhumb(equatorialRadius: 6_378_137, flattening: 1/298.257223563)
        #expect(r.equatorialRadius == 6_378_137)
        #expect(r._rm > 0)
        #expect(r._c2 > 0)
    }

    @Test("Rhumb simple meridional inverse")
    func simpleMeridionalInverse() {
        let r = Rhumb(equatorialRadius: 6_378_137, flattening: 1/298.257223563)
        let inv = r.inverse(latitude1: 0, longitude1: 0,
                            latitude2: 45, longitude2: 0)
        #expect(abs(inv.azimuth) < 1e-8)
        #expect(inv.distance > 0)
    }
}
