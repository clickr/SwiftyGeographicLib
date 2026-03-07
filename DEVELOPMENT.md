# SwiftGeoLib Development Notes

This document records how SwiftGeoLib was developed, including the use of AI
assistants at various stages. It is intended as a transparent record for
contributors and anyone curious about the process. David Hart will add his own
recollections of earlier development below.

---

## Project overview

SwiftGeoLib is a pure Swift library providing geographic coordinate
transformations and geomagnetic field evaluation, ported from Charles Karney's
[GeographicLib](https://geographiclib.sourceforge.io) C++ library.

### Libraries

| Library | Description |
|---|---|
| **Math** | Shared mathematical utilities (e.g. `atan2d`, `degree`) |
| **Constants** | Geodetic constants |
| **TransverseMercatorInternal** | Core Transverse Mercator projection (uses `swift-numerics` `ComplexModule`) |
| **TransverseMercator** | Public Transverse Mercator API |
| **TransverseMercatorStatic** | Static (compile-time) Transverse Mercator variant |
| **StaticUTM** | Lightweight UTM using the static Transverse Mercator |
| **UTM** | Full UTM projection |
| **PolarStereographicInternal** | Core Polar Stereographic projection |
| **PolarStereographic** | Public Polar Stereographic API |
| **UPS** | Universal Polar Stereographic projection |
| **UTMUPSProtocol** | Shared protocol for UTM/UPS coordinate types |
| **MagneticModel** | Geomagnetic field evaluation (WMM, IGRF, EMM) |
| **SimpleGeographicLib** | Vendored C++ GeographicLib subset (test-only reference) |

---

## AI assistance log

The project was developed interactively using Claude Code (Anthropic's CLI
agent). Different models were used at different stages, as reflected in the
`Co-Authored-By` trailers on each commit.

### Session 1 — 7 March 2026 (Claude Sonnet 4.6)

Used **Claude Sonnet 4.6** via Claude Code.

Work performed in this session:

- **Separated StaticUTM into its own library** (`1963661`). Previously it was
  part of another target; this made it independently consumable.
- **Documented StaticUTM** (`e1ed1d0`). Added doc comments to the public API.
- **Introduced `UTMCoordinate`** (`1aa2619`, `0a43425`). Created a value type
  for UTM coordinates and refactored the UTM module to use it, replacing raw
  tuples.
- **Merged UTMCoordinate refactor** (`24cf8df`). Resolved conflicts between the
  StaticUTM and UTMCoordinate branches.
- **Introduced `UPSCoordinate`** (`e9d1a2c`). Analogous coordinate type for
  UPS, with consistent `cartesian` property naming across UTM and UPS.
- **Added MagneticModel skeleton** (`e05f424`). Scaffolded the MagneticModel
  target with a stub implementation and vendored the necessary C++ GeographicLib
  header files as a reference. David directed that the implementation should be
  pure Swift, not a C++ wrapper.

### Session 2 — 7 March 2026 (Claude Opus 4.6)

Switched to **Claude Opus 4.6** via Claude Code for the more demanding
MagneticModel implementation.

Work performed in this session:

- **Implemented MagneticModel in pure Swift** (`d7a777a`, `6b05f43`). This was
  the major piece of work. Ported the following C++ classes to Swift:
  - `Geocentric` — geodetic-to-geocentric coordinate conversion with rotation
    matrices, including `IntForward` and `Unrotate`.
  - `SphericalEngine` — Clenshaw summation for evaluating spherical harmonic
    series, ported from `SphericalEngine::Value`.
  - `SphericalHarmonic` — coefficient storage and callable wrapper around the
    engine, ported from `SphericalHarmonic1`.
  - `MagneticModel` — the main model: binary coefficient file parsing
    (`.wmm.cof`), metadata parsing (`.wmm`), time interpolation between
    epochs, and field evaluation in both geocentric and local (east, north, up)
    coordinates.

  The implementation reads the same binary data files as the C++ library and
  produces identical results. A standalone C++ program was written against the
  installed GeographicLib to generate reference values, which were then
  hard-coded into the Swift test suite (the C++ interop route was abandoned
  because the needed methods — `IntForward`, `Unrotate` — are private in the
  C++ headers and inaccessible via Swift-C++ interop).

- **Refactored types into separate files** (`16a397e`). David extracted result
  types (`MagneticField`, `MagneticFieldWithRates`, `MagneticFieldComponents`,
  `MagneticFieldComponentsWithRates`, `MagneticModelError`) from
  `MagneticModel.swift` into their own files and renamed single-letter
  properties to descriptive names (e.g. `H` to `horizontalFieldIntensity`).
  Claude committed these user-made changes.

- **Added `Date`-based API** (`3bb419d`). Added `field(date:...)` and
  `fieldWithRates(date:...)` overloads that accept Foundation `Date` values
  instead of fractional year `Double`s. Includes a `fractionalYear(from:)`
  helper that uses the UTC Gregorian calendar and correctly handles leap years.

- **Added directory-based initializer** (`a8d3941`). Added
  `init(name:directory:)` so models outside the bundle (e.g. user-installed
  IGRF or EMM files) can be loaded from a URL on disk.

- **Renamed Bx/By/Bz to east/north/up** (`5beab44`). Replaced the abbreviated
  C++ names (`Bx`, `By`, `Bz`, `Bxt`, `Byt`, `Bzt`) with descriptive names
  (`east`, `north`, `up`, `eastDeltaT`, `northDeltaT`, `upDeltaT`) across all
  source and test files.

- **Added C++ API cross-references** (`f872642`). Added doc comments on every
  renamed property and method referencing the original GeographicLib C++ name,
  so users familiar with the C++ API can orient themselves.

### Key technical decisions made during AI sessions

1. **Pure Swift, no C++ runtime dependency.** The MagneticModel reads the same
   binary coefficient files as GeographicLib but has zero C++ code at runtime.
   The vendored C++ sources (`SimpleGeographicLib`) are only used in test
   targets for other modules.

2. **Reference values from a standalone C++ program.** Swift-C++ interop
   couldn't access private methods needed for testing (`IntForward`,
   `Unrotate`). Instead, a temporary C++ program was compiled against the
   system-installed GeographicLib to print reference values, which were
   hard-coded into Swift tests.

3. **UTC-based fractional year conversion.** The `fractionalYear(from:)` helper
   explicitly uses UTC to avoid timezone-dependent results (a bug caught during
   development where local timezone caused Jan 1 UTC to produce ~2025.001
   instead of 2025.0).

4. **No default `Geocentric` parameter on public init.** `Geocentric.wgs84` is
   internal, so it can't appear as a default argument in a public initializer.
   The convenience initializers pass `.wgs84` explicitly.

---

## Earlier development

*David Hart to add recollections of development prior to AI-assisted sessions,
including the initial TransverseMercator, PolarStereographic, UTM, and UPS
implementations.*
