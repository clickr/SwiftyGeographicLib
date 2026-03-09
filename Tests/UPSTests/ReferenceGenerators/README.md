# UPS Reference Value Generator

Standalone C++ program that computes UTMUPS Forward/Reverse reference values
using `GeographicLib::UTMUPS`.

## Prerequisites

See [ReferenceGenerators-SETUP.md](../../ReferenceGenerators-SETUP.md) for
GeographicLib installation options (Homebrew, apt, or build from source).

## Build

Set `GEOLIB_INC` and `GEOLIB_LIB` per the setup guide, then:

```sh
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB \
    -lGeographicLib ups_ref_values.cpp -o ups_ref_values
```

No `-Dprivate=public` flag needed — this uses only public UTMUPS API.

**Quick start (macOS Apple Silicon with Homebrew):**

```sh
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lGeographicLib ups_ref_values.cpp -o ups_ref_values
```

## Run

```sh
./ups_ref_values
```

## Values Generated

- **Forward (northern)**: (84.5, 45.0) — zone, northp, x, y, gamma, k
- **Forward (southern)**: (-80.4174, 77.1166) — zone, northp, x, y, gamma, k
- **Reverse (southern)**: round-trip from southern forward output
- **Reverse (northern)**: round-trip with different coordinates

Forward values are tested with `absoluteTolerance: 1e-9`.
Reverse lat/lon are tested with `absoluteTolerance: 1e-6`.
