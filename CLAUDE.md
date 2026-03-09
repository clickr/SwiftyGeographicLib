# CLAUDE.md — SwiftyGeographicLib

## Project

Pure Swift library providing geographic coordinate transformations and
geomagnetic field evaluation, ported from GeographicLib (C++). No C++ runtime
dependencies.

## Development logs

Development is recorded at two levels:

- **Package-level `DEVELOPMENT.md`** — session-by-session overview with
  initiating prompts and links to module logs.
- **Module-level `Sources/<Module>/DEVELOPMENT.md`** — detailed changes
  for that module, with initiating prompts and attribution.

When making changes:

- Append a session entry with the date, model used, and what was done.
- Attribute prompts and commentary to their author (`*(David Hart)*` or
  `*(Claude Opus 4.6)*` etc.).
- Record bugs found and how they were fixed.
- Record key technical decisions and their rationale.
- Reference commit hashes where applicable.
- Update both the package-level and affected module-level logs.
- **Heading levels:** no downward jumps greater than one level (e.g. h3 → h4,
  not h3 → h6). Upward jumps of any size are fine. Maximum depth is h6.

## Conventions

- **Pure Swift.** No C++ at runtime. C++ reference values are generated
  externally (GeographicLib CLI tools or standalone programs) and hardcoded
  into tests.
- **`@testable import`** for testing internal members. No separate internal
  modules — consolidate into the public module and use `internal` access.
- **Swifty APIs.** Result structs instead of out-parameters. Descriptive
  property names (not C++ abbreviations). CoreLocation integration behind
  `#if canImport(CoreLocation)`.
- **Typealiases for domain types.** e.g. `CartesianMetres` (Double),
  `CLLocationDegrees` (Double). These carry semantic meaning and enable
  type-specific behaviour (e.g. custom string interpolation).
- **`@_exported import`** for re-exporting protocol modules. UTM and UPS
  re-export UTMUPSProtocol so consumers don't need a direct dependency.
- **Test reference values** from GeographicLib CLI tools (`GeodSolve`,
  `MagneticField`, `IntersectTool`) or standalone C++ programs. Use
  `isApproximatelyEqual(to:absoluteTolerance:)` or `relativeTolerance:` from
  swift-numerics `Numerics`.

## Module structure

See `Package.swift` for the current target/product list. Key modules:
TransverseMercator, UTM, PolarStereographic, UPS, UTMUPSProtocol, Geodesic,
Intersect, MagneticModel, Math, Constants, GeographicError.

## Committing

Run all tests before committing. Report the test count in the session log.
