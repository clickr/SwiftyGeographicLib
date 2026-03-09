# Rhumb Module Development Notes

## Rhumb and RhumbLine — 10 March 2026 (Claude Opus 4.6)

> *"Add Rhumb and RhumbLine modules to SwiftyGeographicLib, porting
> GeographicLib's C++ Rhumb and RhumbLine classes to Swift."*
> *(David Hart)*

Port of GeographicLib's `Rhumb`, `RhumbLine`, `AuxLatitude`, and
`DAuxLatitude` classes to Swift. **Series-only** implementation (order 6,
no `exact` mode), accurate to ~10 nm for WGS84 (|f| < 0.01).

### Files created

| File | Description |
|---|---|
| `AuxAngle.swift` | `(y, x)` angle representation preserving precision near cardinal points |
| `AuxLatitudeCoefficients.swift` | Static order-6 Fourier coefficient tables (522 coefficients, 37 pointer entries, area/rectifying/authalic radius coefficients) |
| `AuxLatitude.swift` | Auxiliary latitude conversions (φ↔β↔θ↔μ↔χ↔ξ) via Fourier series in third flattening n |
| `DAuxLatitude.swift` | Divided differences of auxiliary latitudes for rhumb distance and area calculations |
| `Rhumb.swift` | Main solver: direct (start + azimuth + distance → destination), inverse (two points → azimuth + distance), line factory |
| `RhumbLine.swift` | Precomputed rhumb line with efficient position queries at arbitrary distances |
| `RhumbResult.swift` | Result structs: `RhumbDirectResult`, `RhumbInverseResult`, `RhumbPosition` |

### Key design decisions

- **Series only** — matches the Geodesic module pattern. No `exact` parameter,
  avoiding EllipticFunction and DST/FFT (kissfft) dependencies.
- **Value types** — `Rhumb` and `RhumbLine` are structs (Sendable). `RhumbLine`
  stores a copy of the parent `Rhumb` rather than holding a reference.
- **`AuxLatitude` is a class** — uses a lazily-filled Fourier coefficient cache
  (`_c`). Marked `@unchecked Sendable`; thread safety ensured by **eagerly
  pre-computing all 30 conversion pairs in `init`**, so `_c` is never mutated
  after construction.
- **Area always computed** — simplifies the API (no capability bitmask).
- **Single module** — all types live in the `Rhumb` target, depending only
  on `Math`.

### Bugs found and fixed

#### Thread safety crash (data race in coefficient cache)

`AuxLatitude._c` was originally lazily mutated in `fillcoeff()` without
synchronisation. When Swift Testing ran tests concurrently, multiple threads
raced on the shared `Rhumb.wgs84` instance's `AuxLatitude`, causing
"Index out of range" crashes.

**Fix:** Pre-compute all 30 conversion pairs eagerly in `AuxLatitude.init()`.
The `_c` array is now immutable after construction, making the class genuinely
thread-safe.

#### Anti-meridian crossing (`angDiff` bug)

The simple `angDiff(_:_:)` in the Math module uses `truncatingRemainder` and
lacks a second reduction step, so `angDiff(170, -170)` returns `-340` instead
of `+20`. The inverse rhumb solver used this function for the longitude
difference, causing the anti-meridian crossing test to produce azimuth 270°
instead of 90°.

**Fix:** The root cause was in `Math.angDiff` itself — it was not a faithful
port of the C++ `Math::AngDiff` (which always delegates to the full two-sum
algorithm). Fixed `angDiff` in `Math.swift` to delegate to `angDiffWithError`,
matching the C++ pattern. This corrects the function for all callers.

### Tests

22 tests across 6 suites, all passing. Reference values generated with
GeographicLib's `RhumbSolve` CLI tool.

| Suite | Tests | Description |
|---|---|---|
| Debug | 7 | Coefficient sizes, AuxAngle basics, AuxLatitude init/conversion, Rhumb init, simple meridional inverse |
| Rhumb inverse | 5 | JFK→LHR, equator→45°N, 60°N→60°S, short distance, anti-meridian crossing |
| Rhumb direct | 5 | JFK heading 50°, equator east/north/45°, near-pole |
| Rhumb roundtrip | 2 | Direct→inverse and inverse→direct consistency |
| RhumbLine waypoints | 2 | JFK at 500 km intervals, zero distance |
| Rhumb.wgs84 | 1 | Static instance smoke test |

Full test suite: **104 tests** (82 existing + 22 new), all passing.
