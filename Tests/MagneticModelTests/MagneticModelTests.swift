//
//  MagneticModelTests.swift
//  SwiftGeoLib
//
//  Tests for the pure Swift MagneticModel implementation.
//  Validates against reference values generated from C++ GeographicLib.
//

import Testing
import Foundation
@testable import MagneticModel
import Numerics

// MARK: - Geocentric Tests

/// Test that our Swift Geocentric matches C++ GeographicLib::Geocentric.
@Test func testGeocentricForward() throws {
    let swiftGeo = Geocentric.wgs84

    // Reference values generated from C++ GeographicLib::Geocentric::WGS84().Forward()
    let testCases: [(lat: Double, lon: Double, h: Double,
                     X: Double, Y: Double, Z: Double,
                     M: [Double])] = [
        (lat: 0.0, lon: 0.0, h: 0.0,
         X: 6.378137000000000e+06, Y: 0.000000000000000e+00, Z: 0.000000000000000e+00,
         M: [-0.000000000000000e+00, -0.000000000000000e+00, 1.000000000000000e+00,
             1.000000000000000e+00, -0.000000000000000e+00, 0.000000000000000e+00,
             0.000000000000000e+00, 1.000000000000000e+00, 0.000000000000000e+00]),
        (lat: 47.6, lon: -122.3, h: 100.0,
         X: -2.302381139677220e+06, Y: -3.642006824001523e+06, Z: 4.687075751821155e+06,
         M: [8.452618332218562e-01, 3.945953461829054e-01, -3.603150650045318e-01,
             -5.343523493898262e-01, 6.241881149699048e-01, -5.699620722748927e-01,
             0.000000000000000e+00, 6.743023875837234e-01, 7.384553406258838e-01]),
        (lat: -33.86, lon: 151.2, h: 50.0,
         X: -4.646149800978210e+06, Y: 2.554242467872285e+06, Z: -3.533589736855923e+06,
         M: [-4.817536741017154e-01, -4.882478628768308e-01, -7.276863485635178e-01,
             -8.763066800438635e-01, 2.684165340397155e-01, 4.000489554599637e-01,
             0.000000000000000e+00, 8.304014623363289e-01, -5.571655152193883e-01]),
        (lat: 90.0, lon: 0.0, h: 0.0,
         X: 0.000000000000000e+00, Y: 0.000000000000000e+00, Z: 6.356752314245179e+06,
         M: [-0.000000000000000e+00, -1.000000000000000e+00, 0.000000000000000e+00,
             1.000000000000000e+00, -0.000000000000000e+00, 0.000000000000000e+00,
             0.000000000000000e+00, 0.000000000000000e+00, 1.000000000000000e+00]),
        (lat: -90.0, lon: 0.0, h: 0.0,
         X: 0.000000000000000e+00, Y: 0.000000000000000e+00, Z: -6.356752314245179e+06,
         M: [-0.000000000000000e+00, 1.000000000000000e+00, 0.000000000000000e+00,
             1.000000000000000e+00, 0.000000000000000e+00, 0.000000000000000e+00,
             0.000000000000000e+00, 0.000000000000000e+00, -1.000000000000000e+00]),
        (lat: 0.0, lon: 180.0, h: 10000.0,
         X: -6.388137000000000e+06, Y: 0.000000000000000e+00, Z: 0.000000000000000e+00,
         M: [-0.000000000000000e+00, 0.000000000000000e+00, -1.000000000000000e+00,
             -1.000000000000000e+00, -0.000000000000000e+00, 0.000000000000000e+00,
             0.000000000000000e+00, 1.000000000000000e+00, 0.000000000000000e+00]),
        (lat: 45.0, lon: 45.0, h: 500.0,
         X: 3.194669145060575e+06, Y: 3.194669145060575e+06, Z: 4.487701962256514e+06,
         M: [-7.071067811865476e-01, -5.000000000000001e-01, 5.000000000000001e-01,
             7.071067811865476e-01, -5.000000000000001e-01, 5.000000000000001e-01,
             0.000000000000000e+00, 7.071067811865476e-01, 7.071067811865476e-01]),
        (lat: -80.4174, lon: 77.1166, h: 3000.0,
         X: 2.376246626214307e+05, Y: 1.038906827889181e+06, Z: -6.270427137564652e+06,
         M: [-9.748258343424321e-01, 2.198565451515164e-01, 3.711727700977661e-02,
             2.229676942935484e-01, 9.612237357614950e-01, 1.622785787161527e-01,
             0.000000000000000e+00, 1.664693045662024e-01, -9.860466371512278e-01]),
    ]

    for tc in testCases {
        let swift = swiftGeo.intForward(lat: tc.lat, lon: tc.lon, h: tc.h)

        #expect(swift.X.isApproximatelyEqual(to: tc.X, absoluteTolerance: 1e-6),
                "X mismatch at lat=\(tc.lat)")
        #expect(swift.Y.isApproximatelyEqual(to: tc.Y, absoluteTolerance: 1e-6),
                "Y mismatch at lat=\(tc.lat)")
        #expect(swift.Z.isApproximatelyEqual(to: tc.Z, absoluteTolerance: 1e-6),
                "Z mismatch at lat=\(tc.lat)")

        // Verify rotation matrix elements
        for i in 0..<9 {
            #expect(swift.M[i].isApproximatelyEqual(to: tc.M[i], absoluteTolerance: 1e-12),
                    "M[\(i)] mismatch at lat=\(tc.lat)")
        }
    }
}

/// Test Geocentric Unrotate against C++ implementation.
@Test func testGeocentricUnrotate() throws {
    let swiftGeo = Geocentric.wgs84

    let swift = swiftGeo.intForward(lat: 47.6, lon: -122.3, h: 100)

    // A test vector in geocentric coordinates
    let testVec = (X: 100.0, Y: -200.0, Z: 50.0)

    let result = Geocentric.unrotate(M: swift.M,
                                      X: testVec.X, Y: testVec.Y, Z: testVec.Z)

    // Reference from C++ GeographicLib (M^T * vec)
    let refX = 1.913966532001509e+02
    let refY = -5.166296899650424e+01
    let refZ = 1.148836749858196e+02

    #expect(result.x.isApproximatelyEqual(to: refX, absoluteTolerance: 1e-9))
    #expect(result.y.isApproximatelyEqual(to: refY, absoluteTolerance: 1e-9))
    #expect(result.z.isApproximatelyEqual(to: refZ, absoluteTolerance: 1e-9))
}

// MARK: - MagneticModel Tests

/// Test MagneticModel against C++ reference values for WMM2025.
@Test func testWMM2025Field() throws {
    let model = try MagneticModel(name: "wmm2025")

    // Reference values from C++ GeographicLib::MagneticModel
    let testCases: [(t: Double, lat: Double, lon: Double, h: Double,
                     Bx: Double, By: Double, Bz: Double,
                     Bxt: Double, Byt: Double, Bzt: Double)] = [
        (t: 2025.0, lat: 0.0, lon: 0.0, h: 0,
         Bx: -1.927587354608948e+03, By: 2.745392868141750e+04, Bz: 1.601080696334261e+04,
         Bxt: 6.076504047819352e+01, Byt: -2.040555998789081e+01, Bzt: -1.105387923080829e+01),
        (t: 2025.0, lat: 80.0, lon: 0.0, h: 0,
         Bx: 1.458869564421783e+02, By: 6.521599441280421e+03, Bz: -5.479150766224908e+04,
         Bxt: 5.945875281989447e+01, Byt: -8.309568725114923e+00, Bzt: -3.113911470514087e+01),
        (t: 2025.0, lat: -80.0, lon: 0.0, h: 0,
         Bx: -7.698864892197286e+03, By: 1.753941111434700e+04, Bz: 4.194761420895920e+04,
         Bxt: -3.004720937170342e+01, Byt: -2.090601119141013e+01, Bzt: -5.467564453525574e+01),
        (t: 2025.0, lat: 0.0, lon: 120.0, h: 0,
         Bx: -1.096063048178227e+02, By: 3.967775500236646e+04, Bz: 1.058016983197216e+04,
         Bxt: -2.310511808879683e+01, Byt: 9.544059592625468e+00, Bzt: -7.935408743674856e+01),
        (t: 2025.0, lat: 0.0, lon: -120.0, h: 0,
         Bx: 4.321402338270267e+03, By: 2.946717242392872e+04, Bz: -5.463577594777380e+03,
         Bxt: -2.068689008557411e+01, Byt: -5.458371453070067e+01, Bzt: -1.148492856486349e+01),
        (t: 2025.0, lat: 47.6, lon: -122.3, h: 0,
         Bx: 4.962391401515922e+03, By: 1.841296057855617e+04, Bz: -4.922788914228979e+04,
         Bxt: -4.070140784765751e+01, Byt: 6.846956909564785e+00, Bzt: 1.165230773085122e+02),
        (t: 2025.0, lat: -33.86, lon: 151.2, h: 0,
         Bx: 5.452699487891261e+03, By: 2.403579237454800e+04, Bz: 5.139925049605334e+04,
         Bxt: 6.782903793140191e+00, Byt: -1.175383930259874e+01, Bzt: -1.409437535501833e+01),
        (t: 2027.5, lat: 47.6, lon: -122.3, h: 1000,
         Bx: 4.857101890591575e+03, By: 1.842095652585176e+04, Bz: -4.891274925362800e+04,
         Bxt: -4.067940806214763e+01, Byt: 6.846569234698812e+00, Bzt: 1.164416960065976e+02),
        (t: 2025.5, lat: 0.0, lon: 0.0, h: 100000,
         Bx: -1.846334679390044e+03, By: 2.609114560452784e+04, Bz: 1.476131548503081e+04,
         Bxt: 5.743569152661379e+01, Byt: -1.920058373357018e+01, Bzt: -1.050806766323698e+01),
        (t: 2029.0, lat: 45.0, lon: 45.0, h: 50000,
         Bx: 3.101610206619124e+03, By: 2.177627579309874e+04, Bz: -4.521177868524045e+04,
         Bxt: 1.281049337550344e+01, Byt: 8.933638827725639e+00, Bzt: -5.992680344119984e+01),
    ]

    for tc in testCases {
        let result = model.fieldWithRates(
            time: tc.t, latitude: tc.lat,
            longitude: tc.lon, height: tc.h)

        let tol = 1e-6 // nanotesla tolerance

        #expect(result.field.Bx.isApproximatelyEqual(to: tc.Bx, absoluteTolerance: tol),
                "Bx mismatch at t=\(tc.t), lat=\(tc.lat), lon=\(tc.lon)")
        #expect(result.field.By.isApproximatelyEqual(to: tc.By, absoluteTolerance: tol),
                "By mismatch at t=\(tc.t), lat=\(tc.lat), lon=\(tc.lon)")
        #expect(result.field.Bz.isApproximatelyEqual(to: tc.Bz, absoluteTolerance: tol),
                "Bz mismatch at t=\(tc.t), lat=\(tc.lat), lon=\(tc.lon)")
        #expect(result.Bxt.isApproximatelyEqual(to: tc.Bxt, absoluteTolerance: tol),
                "Bxt mismatch at t=\(tc.t), lat=\(tc.lat), lon=\(tc.lon)")
        #expect(result.Byt.isApproximatelyEqual(to: tc.Byt, absoluteTolerance: tol),
                "Byt mismatch at t=\(tc.t), lat=\(tc.lat), lon=\(tc.lon)")
        #expect(result.Bzt.isApproximatelyEqual(to: tc.Bzt, absoluteTolerance: tol),
                "Bzt mismatch at t=\(tc.t), lat=\(tc.lat), lon=\(tc.lon)")
    }
}

/// Test FieldComponents static utility.
@Test func testFieldComponents() throws {
    // Reference from C++ GeographicLib::MagneticModel::FieldComponents
    let Bx = 1234.5
    let By = 20000.0
    let Bz = -40000.0

    let comp = MagneticModel.fieldComponents(Bx: Bx, By: By, Bz: Bz)

    #expect(comp.horizontalFieldIntensity.isApproximatelyEqual(to: 2.003806353543176e+04, absoluteTolerance: 1e-6))
    #expect(comp.totalFieldIntensity.isApproximatelyEqual(to: 4.473839503435500e+04, absoluteTolerance: 1e-6))
    #expect(comp.declination.isApproximatelyEqual(to: 3.532100799536939e+00, absoluteTolerance: 1e-9))
    #expect(comp.inclination.isApproximatelyEqual(to: 6.339134782874967e+01, absoluteTolerance: 1e-9))
}

/// Test FieldComponentsWithRates static utility.
@Test func testFieldComponentsWithRates() throws {
    // Reference from C++ GeographicLib::MagneticModel::FieldComponents
    let Bx = 1234.5, By = 20000.0, Bz = -40000.0
    let Bxt = 10.0, Byt = -5.0, Bzt = 3.0

    let comp = MagneticModel.fieldComponentsWithRates(
        Bx: Bx, By: By, Bz: Bz,
        Bxt: Bxt, Byt: Byt, Bzt: Bzt)

    #expect(comp.horizontalFieldIntensity.isApproximatelyEqual(to: 2.003806353543176e+04, absoluteTolerance: 1e-6))
    #expect(comp.F.isApproximatelyEqual(to: 4.473839503435500e+04, absoluteTolerance: 1e-6))
    #expect(comp.D.isApproximatelyEqual(to: 3.532100799536939e+00, absoluteTolerance: 1e-9))
    #expect(comp.I.isApproximatelyEqual(to: 6.339134782874967e+01, absoluteTolerance: 1e-9))
    #expect(comp.horizontalFieldIntensityDeltaT.isApproximatelyEqual(to: -4.374424696528506e+00, absoluteTolerance: 1e-6))
    #expect(comp.totalIntensityDeltaT.isApproximatelyEqual(to: -4.641538880430108e+00, absoluteTolerance: 1e-6))
    #expect(comp.declinationDeltaT.isApproximatelyEqual(to: 2.941994597709088e-02, absoluteTolerance: 1e-9))
    #expect(comp.inclinationDeltaT.isApproximatelyEqual(to: 3.288071258615021e-03, absoluteTolerance: 1e-9))
}

/// Test full pipeline: model evaluation → field components.
@Test func testFullPipeline() throws {
    let model = try MagneticModel(name: "wmm2025")

    // Evaluate at t=2026.0, lat=47.6, lon=-122.3, h=0
    let result = model.fieldWithRates(
        time: 2026.0, latitude: 47.6, longitude: -122.3, height: 0)

    let comp = MagneticModel.fieldComponentsWithRates(
        Bx: result.field.Bx, By: result.field.By, Bz: result.field.Bz,
        Bxt: result.Bxt, Byt: result.Byt, Bzt: result.Bzt)

    // Reference from C++ GeographicLib full pipeline
    #expect(result.field.Bx.isApproximatelyEqual(
        to: 4.921689993668267e+03, absoluteTolerance: 1e-6))
    #expect(result.field.By.isApproximatelyEqual(
        to: 1.841980753546573e+04, absoluteTolerance: 1e-6))
    #expect(result.field.Bz.isApproximatelyEqual(
        to: -4.911136606498128e+04, absoluteTolerance: 1e-6))

    #expect(comp.horizontalFieldIntensity.isApproximatelyEqual(
        to: 1.906599963383442e+04, absoluteTolerance: 1e-6))
    #expect(comp.F.isApproximatelyEqual(
        to: 5.268243178523528e+04, absoluteTolerance: 1e-6))
    #expect(comp.D.isApproximatelyEqual(
        to: 1.495970265520563e+01, absoluteTolerance: 1e-9))
    #expect(comp.I.isApproximatelyEqual(
        to: 6.878280704213833e+01, absoluteTolerance: 1e-9))
}

/// Test loading model metadata.
@Test func testModelMetadata() throws {
    let model = try MagneticModel(name: "wmm2025")
    #expect(model.name == "wmm2025")
    #expect(model.epoch == 2025)
    #expect(model.minTime == 2025)
    #expect(model.maxTime == 2030)
    #expect(model.minHeight == -1000)
    #expect(model.maxHeight == 850000)
    #expect(model.degree == 12)
    #expect(model.order == 12)
}

/// Test loading a model from a directory URL produces the same results.
@Test func testLoadFromDirectory() throws {
    let bundleModel = try MagneticModel(name: "wmm2025")

    // Find the resource directory via Bundle.module
    let metaURL = Bundle.module.url(forResource: "wmm2025", withExtension: "wmm")!
    let directory = metaURL.deletingLastPathComponent()

    let dirModel = try MagneticModel(name: "wmm2025", directory: directory)

    // Metadata should match
    #expect(dirModel.name == bundleModel.name)
    #expect(dirModel.epoch == bundleModel.epoch)
    #expect(dirModel.degree == bundleModel.degree)

    // Field evaluation should be identical
    let bundleField = bundleModel.field(
        time: 2026.0, latitude: 47.6, longitude: -122.3, height: 0)
    let dirField = dirModel.field(
        time: 2026.0, latitude: 47.6, longitude: -122.3, height: 0)

    #expect(bundleField.Bx == dirField.Bx)
    #expect(bundleField.By == dirField.By)
    #expect(bundleField.Bz == dirField.Bz)
}

/// Test Date-based API produces the same results as fractional year API.
@Test func testFieldWithDate() throws {
    let model = try MagneticModel(name: "wmm2025")
    let cal = Calendar(identifier: .gregorian)

    // 2025-07-02 12:00:00 UTC ≈ 2025.5
    let midYear = cal.date(from: DateComponents(
        timeZone: TimeZone(identifier: "UTC"),
        year: 2025, month: 7, day: 2, hour: 12))!
    let fractional = MagneticModel.fractionalYear(from: midYear)

    // Verify fractional year is close to 2025.5
    #expect(fractional.isApproximatelyEqual(to: 2025.5, absoluteTolerance: 0.01))

    // field(date:) should match field(time:)
    let dateResult = model.field(
        date: midYear, latitude: 47.6, longitude: -122.3, height: 0)
    let timeResult = model.field(
        time: fractional, latitude: 47.6, longitude: -122.3, height: 0)

    #expect(dateResult.Bx == timeResult.Bx)
    #expect(dateResult.By == timeResult.By)
    #expect(dateResult.Bz == timeResult.Bz)

    // fieldWithRates(date:) should match fieldWithRates(time:)
    let dateRates = model.fieldWithRates(
        date: midYear, latitude: 47.6, longitude: -122.3, height: 0)
    let timeRates = model.fieldWithRates(
        time: fractional, latitude: 47.6, longitude: -122.3, height: 0)

    #expect(dateRates.field.Bx == timeRates.field.Bx)
    #expect(dateRates.Bxt == timeRates.Bxt)
}

/// Test fractionalYear handles leap years correctly.
@Test func testFractionalYearLeapYear() throws {
    let cal = Calendar(identifier: .gregorian)

    // 2024 is a leap year (366 days)
    let leapMid = cal.date(from: DateComponents(
        timeZone: TimeZone(identifier: "UTC"),
        year: 2024, month: 7, day: 2))!
    let leapFrac = MagneticModel.fractionalYear(from: leapMid)

    // 2025 is not a leap year (365 days)
    let normalMid = cal.date(from: DateComponents(
        timeZone: TimeZone(identifier: "UTC"),
        year: 2025, month: 7, day: 2))!
    let normalFrac = MagneticModel.fractionalYear(from: normalMid)

    // Both should be close to X.5 but slightly different due to leap day
    #expect(leapFrac.isApproximatelyEqual(to: 2024.5, absoluteTolerance: 0.01))
    #expect(normalFrac.isApproximatelyEqual(to: 2025.5, absoluteTolerance: 0.01))

    // Jan 1 of any year should give exactly that year
    let jan1 = cal.date(from: DateComponents(
        timeZone: TimeZone(identifier: "UTC"),
        year: 2025, month: 1, day: 1))!
    #expect(MagneticModel.fractionalYear(from: jan1) == 2025.0)
}

/// Test that field values are finite for various positions.
@Test func testFieldIsFinite() throws {
    let model = try MagneticModel(name: "wmm2025")

    let positions: [(lat: Double, lon: Double)] = [
        (0, 0), (90, 0), (-90, 0),
        (45, 90), (-45, -90),
        (0, 180), (0, -180),
    ]

    for pos in positions {
        let field = model.field(
            time: 2025, latitude: pos.lat,
            longitude: pos.lon, height: 0)
        #expect(field.Bx.isFinite, "Bx not finite at \(pos)")
        #expect(field.By.isFinite, "By not finite at \(pos)")
        #expect(field.Bz.isFinite, "Bz not finite at \(pos)")
    }
}
