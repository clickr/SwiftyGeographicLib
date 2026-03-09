# MagneticModel Reference Value Generator

Standalone C++ program that generates reference values for the Geocentric,
MagneticModel (WMM2025), and FieldComponents tests.

## Prerequisites

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options (Homebrew, apt, or build from source).

This generator additionally requires WMM2025 magnetic coefficient data — see
the "WMM2025 magnetic data" section of the setup guide.

## Build

Set `GEOLIB_INC` and `GEOLIB_LIB` per the setup guide, then:

```sh
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib -Dprivate=public magnetic_ref_values.cpp \
    -o magnetic_ref_values
```

The `-Dprivate=public` flag is required to access `Geocentric::IntForward()`.

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib -Dprivate=public magnetic_ref_values.cpp \
    -o magnetic_ref_values
```

## Run

```sh
./magnetic_ref_values
```

## Values Generated

### Geocentric

8 test cases of `Geocentric::WGS84().IntForward()` producing X, Y, Z
coordinates and 3x3 rotation matrix M. Tested with `absoluteTolerance: 1e-6`
(positions) and `1e-12` (rotation matrix).

### Unrotate

M^T * test vector at (47.6, -122.3, 100). Tested with `absoluteTolerance: 1e-9`.

### WMM2025 field values

10 test cases at various locations, times, and altitudes producing east, north,
up components and their time derivatives. Tested with `absoluteTolerance: 1e-6`.

### Full pipeline

Model evaluation at (t=2026.0, lat=47.6, lon=-122.3, h=0) followed by
FieldComponents derivation (H, F, D, I).

### FieldComponents

Pure mathematical derivation of H, F, D, I and their time rates from given
east/north/up inputs and rates.

## Convention note

The C++ output uses the Swift convention where `east=Bx`, `north=By`, `up=Bz`
(matching the GeographicLib parameter order). This differs from the standard
geomagnetic convention where Bx=north and By=east. The Swift test file uses
the same parameter-order convention, so values match directly.
