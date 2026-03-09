# Agent Instructions — PolarStereographic Reference Generator

## Purpose

`ps_ref_values.cpp` generates reference values for
`PolarStereographicTests.swift` by extracting internal constants and computing
Forward/Reverse projections from the C++ GeographicLib
`PolarStereographic::UPS()` singleton.

## When to regenerate

Regenerate if:
- The Swift `PolarStereographic` implementation changes
- You add new test cases for different coordinates
- GeographicLib is updated to a new version

## Build and run

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options. Set `GEOLIB_INC` and `GEOLIB_LIB` per that
guide, then:

```sh
cd Tests/PolarStereographicTests/ReferenceGenerators
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib -Dprivate=public ps_ref_values.cpp -o ps_ref_values
./ps_ref_values
```

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib -Dprivate=public ps_ref_values.cpp -o ps_ref_values
./ps_ref_values
```

## Convention notes

- Internal fields (`e2`, `e2m`, `es`, `c`) are tested with exact equality.
- Forward/Reverse values use `absoluteTolerance: 1e-9`.
- The test point (-80.4174, 77.1166) is in the southern UPS zone — the `northp`
  parameter is `false` in the Forward call.

## Corresponding Swift test

`Tests/PolarStereographicTests/PolarStereographicTests.swift`
