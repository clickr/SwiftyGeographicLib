# Agent Instructions — Intersect Reference Generator

## Purpose

`intersect_ref_values.cpp` generates reference values for `IntersectTests.swift`
by extracting private constructor constants from the C++ GeographicLib
`Intersect` class and computing `EllipsoidArea()`.

## When to regenerate

Regenerate if:
- The Swift `Intersect` constructor logic changes
- You need to verify derived constants against a new GeographicLib version
- The `Geodesic` implementation changes (affects EllipsoidArea)

## Build and run

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options. Set `GEOLIB_INC` and `GEOLIB_LIB` per that
guide, then:

```sh
cd Tests/IntersectTests/ReferenceGenerators
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib -Dprivate=public intersect_ref_values.cpp \
    -o intersect_ref_values
./intersect_ref_values
```

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib -Dprivate=public intersect_ref_values.cpp \
    -o intersect_ref_values
./intersect_ref_values
```

## Convention notes

- The `-Dprivate=public` compiler flag exposes private C++ fields.
- `a` and `f` are tested with exact equality (`==`).
- `eps` is tested with exact equality against `3 * Double.ulpOfOne`.
- All other constants use `relativeTolerance` ranging from `1e-9` to `1e-12`.
- Output uses `%.17e` format for maximum double-precision fidelity.

## Corresponding Swift test

`Tests/IntersectTests/IntersectTests.swift`
