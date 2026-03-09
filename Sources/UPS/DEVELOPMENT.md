# UPS Development Notes

Universal Polar Stereographic projection.

---

## Session 7 — 9 March 2026 (Claude Opus 4.6)

### `CartesianMetres` adoption

*(David Hart)*

> *"I would like to use a similar pattern as for CLLocationDegrees — a
> typealias named CartesianMetres for Double and modify the Cartesian protocol
> in Sources/UTMUPSProtocol with its dependents in Sources/UTM and
> Sources/UPS"*

*(Claude Opus 4.6)*

- **`UPSCoordinate.swift`** — `easting` and `northing` properties changed
  from `Double` to `CartesianMetres`.
- **`UPS.swift`** — Forwarded `easting` and `northing` properties changed
  from `Double` to `CartesianMetres`.

### `@_exported import UTMUPSProtocol`

*(David Hart)*

> *"Can we rather re-export UTMUPSProtocol from Libraries that use it?"*

*(Claude Opus 4.6)*

- **`UPS.swift`** — `import UTMUPSProtocol` → `@_exported import UTMUPSProtocol`.
