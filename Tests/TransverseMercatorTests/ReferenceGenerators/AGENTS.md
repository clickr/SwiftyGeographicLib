# Agent Instructions — TransverseMercator Reference Generator

## Purpose

`tm_ref_values.cpp` generates reference values for `TransverseMercatorTests.swift`
by extracting internal constants from the C++ GeographicLib
`TransverseMercator::UTM()` singleton.

## When to regenerate

Regenerate if:
- The Swift `TransverseMercator` implementation changes its internal constants
- You need to verify that the Swift port matches the C++ library
- GeographicLib is updated to a new version

## Build and run

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options. Set `GEOLIB_INC` and `GEOLIB_LIB` per that
guide, then:

```sh
cd Tests/TransverseMercatorTests/ReferenceGenerators
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib -Dprivate=public tm_ref_values.cpp -o tm_ref_values
./tm_ref_values
```

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib -Dprivate=public tm_ref_values.cpp -o tm_ref_values
./tm_ref_values
```

## Convention notes

- The `-Dprivate=public` compiler flag exposes private C++ fields for extraction.
- All 19 values (n, a1, b1, c, e2, e2m, es, alp[1-6], bet[1-6]) are tested with
  exact equality in the Swift tests — the literal strings in the test file must
  match the C++ output exactly.
- Output uses `%.17e` format for maximum double-precision fidelity.

## Corresponding Swift test

`Tests/TransverseMercatorTests/TransverseMercatorTests.swift`
