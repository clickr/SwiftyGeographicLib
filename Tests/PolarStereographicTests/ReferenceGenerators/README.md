# PolarStereographic Reference Value Generator

Standalone C++ program that extracts internal constants and computes
Forward/Reverse projections from `GeographicLib::PolarStereographic::UPS()`.

## Prerequisites

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options (Homebrew, apt, or build from source).

## Build

Set `GEOLIB_INC` and `GEOLIB_LIB` per the setup guide, then:

```sh
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib -Dprivate=public ps_ref_values.cpp -o ps_ref_values
```

The `-Dprivate=public` flag is required to access internal fields (`_e2`,
`_e2m`, `_es`, `_c`).

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib -Dprivate=public ps_ref_values.cpp -o ps_ref_values
```

## Run

```sh
./ps_ref_values
```

## Values Generated

- `e2`, `e2m`, `es`, `c` — UPS internal fields (tested with exact equality)
- Forward(-80.4174, 77.1166) — x, y, convergence, centralScale
- Reverse round-trip — lat, lon, convergence, centralScale

Forward/Reverse values are tested with `absoluteTolerance: 1e-9`.
