# UTMUPSProtocol Development Notes

Shared protocols and types for UTM and UPS coordinate systems.

---

## Session 7 — 9 March 2026 (Claude Opus 4.6)

### `CartesianMetres` typealias

*(David Hart)*

> *"I would like to use a similar pattern as for CLLocationDegrees — a
> typealias named CartesianMetres for Double and modify the Cartesian protocol
> in Sources/UTMUPSProtocol with its dependents in Sources/UTM and
> Sources/UPS"*

*(Claude Opus 4.6)*

- **`MultiCoordinate.swift`** — Added `public typealias CartesianMetres = Double`.
  Updated `easting` and `northing` properties in `MultiCoordinate` and
  `Cartesian` protocols from `Double` to `CartesianMetres`.
