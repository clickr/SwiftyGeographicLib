# Agent Instructions — UPS Reference Generator

## Purpose

`ups_ref_values.cpp` generates reference values for `UPSTests.swift` using the
public C++ GeographicLib `UTMUPS::Forward` and `UTMUPS::Reverse` API.

## When to regenerate

Regenerate if:
- The Swift `UPS` implementation changes its forward/reverse logic
- You add new test cases for different coordinates or hemispheres
- GeographicLib is updated to a new version

## Build and run

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options. Set `GEOLIB_INC` and `GEOLIB_LIB` per that
guide, then:

```sh
cd Tests/UPSTests/ReferenceGenerators
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib ups_ref_values.cpp -o ups_ref_values
./ups_ref_values
```

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib ups_ref_values.cpp -o ups_ref_values
./ups_ref_values
```

## Convention notes

- This generator does NOT need `-Dprivate=public` — it uses only the public
  UTMUPS API.
- The C++ `UTMUPS::Forward` returns `zone=0` for UPS (zones 1-60 are UTM).
- The C++ `northp` boolean maps to the Swift `hemisphere` enum
  (`true` = `.northern`, `false` = `.southern`).
- The C++ x/y values include the 2,000,000 m false easting/northing offset
  that UTMUPS applies on top of PolarStereographic.
- Forward values use `absoluteTolerance: 1e-9`; Reverse lat/lon use `1e-6`.

## Corresponding Swift test

`Tests/UPSTests/UPSTests.swift`
