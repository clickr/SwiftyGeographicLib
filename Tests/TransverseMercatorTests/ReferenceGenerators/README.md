# TransverseMercator Reference Value Generator

Standalone C++ program that extracts internal constants from
`GeographicLib::TransverseMercator::UTM()` for use as test reference values.

## Prerequisites

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options (Homebrew, apt, or build from source).

## Build

Set `GEOLIB_INC` and `GEOLIB_LIB` per the setup guide, then:

```sh
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib -Dprivate=public tm_ref_values.cpp -o tm_ref_values
```

The `-Dprivate=public` flag is required to access internal fields (`_n`, `_a1`,
`_alp[]`, etc.) that are private in the C++ API.

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib -Dprivate=public tm_ref_values.cpp -o tm_ref_values
```

## Run

```sh
./tm_ref_values
```

## Values Generated

- `n`, `a1`, `b1`, `c`, `e2`, `e2m`, `es` — ellipsoid-derived constants
- `alp[1..6]` — forward projection coefficients
- `bet[1..6]` — reverse projection coefficients

These are compared with exact equality (`==`) in
`TransverseMercatorTests.swift`.
