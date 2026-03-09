# Intersect Reference Value Generator

Standalone C++ program that extracts internal constructor constants from
`GeographicLib::Intersect` and computes `Geodesic::WGS84().EllipsoidArea()`.

## Prerequisites

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options (Homebrew, apt, or build from source).

## Build

Set `GEOLIB_INC` and `GEOLIB_LIB` per the setup guide, then:

```sh
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib -Dprivate=public intersect_ref_values.cpp \
    -o intersect_ref_values
```

The `-Dprivate=public` flag is required to access private fields (`_rR`, `_d`,
`_eps`, `_tol`, `_delta`, `_t1`–`_t5`, `_d1`–`_d3`).

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib -Dprivate=public intersect_ref_values.cpp \
    -o intersect_ref_values
```

## Run

```sh
./intersect_ref_values
```

## Values Generated

- `a`, `f` — WGS84 ellipsoid parameters (tested with exact equality)
- `rR`, `d`, `tol`, `delta`, `t1`–`t5`, `d1`–`d3` — derived constants
  (tested with `relativeTolerance: 1e-9` to `1e-12`)
- `eps` — `3 * Double.ulpOfOne` (tested with exact equality)
- `area` — `Geodesic::WGS84().EllipsoidArea()` (tested with
  `relativeTolerance: 1e-12`)
