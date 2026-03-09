# Agent Instructions — MagneticModel Reference Generator

## Purpose

`magnetic_ref_values.cpp` generates reference values for
`MagneticModelTests.swift` covering Geocentric coordinate conversion,
WMM2025 magnetic field evaluation, and FieldComponents derivation.

## When to regenerate

Regenerate if:
- The Swift `Geocentric`, `MagneticModel`, or `FieldComponents` implementation changes
- You add new test cases or locations
- A new WMM model version is released (e.g. WMM2030)
- GeographicLib is updated to a new version

## Build and run

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options and WMM2025 data setup. Set `GEOLIB_INC` and
`GEOLIB_LIB` per that guide, then:

```sh
cd Tests/MagneticModelTests/ReferenceGenerators
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib -Dprivate=public magnetic_ref_values.cpp \
    -o magnetic_ref_values
./magnetic_ref_values
```

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib -Dprivate=public magnetic_ref_values.cpp \
    -o magnetic_ref_values
./magnetic_ref_values
```

## Convention notes

**Critical**: The C++ GeographicLib `MagneticModel` returns `(Bx, By, Bz)` where
Bx=northward, By=eastward, Bz=downward in the standard geomagnetic convention.

The Swift implementation stores field components in GeographicLib parameter
order: `east=Bx`, `north=By`, `up=Bz`. This C++ generator outputs values in the
**Swift convention** so they match the test file directly:
- `east` in output = Bx (first C++ parameter)
- `north` in output = By (second C++ parameter)
- `up` in output = Bz (third C++ parameter)

**FieldComponents formulas** (matching the Swift implementation):
- `H = hypot(east, north)`
- `F = hypot(H, up)`
- `D = atan2(east, north)` (degrees)
- `I = atan2(-up, H)` (degrees)
- `Fdt = (east*eastDt + north*northDt + up*upDt) / F`
- `Idt = (-upDt*H + up*Hdt) / F^2` (degrees)

## Test tolerances

- Geocentric X, Y, Z: `absoluteTolerance: 1e-6`
- Geocentric rotation matrix: `absoluteTolerance: 1e-12`
- WMM2025 field values: `absoluteTolerance: 1e-6`
- FieldComponents H, F: `absoluteTolerance: 1e-6`
- FieldComponents D, I, Ddt, Idt: `absoluteTolerance: 1e-9`

## Corresponding Swift test

`Tests/MagneticModelTests/MagneticModelTests.swift`
