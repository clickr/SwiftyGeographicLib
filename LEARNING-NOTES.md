# SwiftyGeographicLib Learning Notes

Technical insights and clarifications gathered during development.

---

## Swift module system

### `@_exported import`

`@_exported import` only needs to appear once in a single file within the
exporting module. It does not need to be repeated in other files within the
same module, nor by consumers. Any consumer who imports the module
automatically sees the re-exported symbols.

### `@testable import`

`@testable import` makes `internal` members accessible from test targets.
This eliminates the need for separate "Internal" modules just to expose
implementation details for testing. Consolidate into a single module and
use `internal` access — tests can still reach everything via `@testable`.

### `@inlinable`

Marking a function `@inlinable` makes its body available for cross-module
inlining. At the call site the compiler can see through the function and
constant-fold static values. This is the standard technique in
`swift-collections` and `swift-numerics`. When caller and callee are in the
same module, `@inlinable` is unnecessary — the compiler can already inline.

### `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`

When this build setting is `YES`, transitive imports are not visible to
consumers. Symbols from a dependency's dependencies are hidden unless
explicitly imported or re-exported with `@_exported import`.

### Module consolidation

Separate internal modules (`FooInternal`) are unnecessary if `@testable
import` is used. Consolidating into a single module simplifies the
dependency graph and reduces `public` surface area. Properties that were
`public` only for cross-module access become `internal`.

## GeographicLib porting

### `polyValue` vs `polyEval`

GeographicLib's `Math::polyval` uses a non-standard Horner's method: it
drops the last coefficient (which is used elsewhere as a divisor) and
assumes coefficients are already in decreasing power order. The Swift
`polyValue` mirrors this behaviour. For standard polynomial evaluation
(all coefficients used), use `polyEval` instead. Mixing these up caused
bugs at 11 call sites during the Geodesic port.

### Coefficient indexing conventions

GeographicLib's internal coefficient arrays are 1-indexed (not 0-indexed)
and stored in decreasing power order (highest power first). This is
unconventional and has tripped AI-assisted porting attempts. The A/C
coefficient arrays in `C1f`, `C1pf`, `C3f`, etc. all follow this pattern.

### `sincosd` IEEE 754 compliance

For multiples of 180°, the quadrant-2 case can return `-0.0` for sine.
This causes `atan2d(-0, negative) = -180` instead of `+180`, producing
wrong azimuths on southbound meridional geodesics. Fix: apply
`copysign(sinx, degrees)` when `sinx == 0`.

### Reference value generation

GeographicLib CLI tools (`GeodSolve`, `MagneticField`, `IntersectTool`)
installed via Homebrew (`brew install geographiclib`) can generate test
reference values without writing any C++:

```sh
# Direct: start at (47.6°N, 122.3°W), bearing 45°, distance 1000 km
echo "47.6 -122.3 45 1000000" | GeodSolve

# Inverse: distance and bearings between two points
echo "47.6 -122.3 48.2 -121.5" | GeodSolve -i

# Magnetic field: WMM2025 at position and date
echo "47.6 -122.3 0 2025.5" | MagneticField
```

For internal C++ values not exposed by CLI tools, compile a standalone
program against `/opt/homebrew/lib/libGeographicLib.dylib` with
`-Dprivate=public` to access private fields. This violates the C++
standard but works in practice. Note: `#define private public` does NOT
work within the Swift Package Manager build system.

### UTC for fractional year conversion

The `fractionalYear(from:)` helper must use UTC explicitly. Using local
timezone causes Jan 1 UTC to produce ~2025.001 instead of 2025.0 in some
timezones — a bug caught during MagneticModel development.

### Bundled magnetic model data

WMM2025 data files (`.wmm` metadata and `.wmm.cof` binary coefficients)
are bundled in `Sources/MagneticModel/Resources`. Additional models (IGRF,
EMM) can be loaded from `/usr/local/share/GeographicLib/magnetic/` via
`init(name:directory:)` after running `sudo geographiclib-get-magnetic all`.

## Swift architecture

### Static dispatch via protocol + `static let`

`static let` properties in a protocol conformer are evaluated lazily once
by Swift and stored forever — equivalent to C++ `static const` class
members. Combined with `@inlinable` for cross-module use, this gives
zero-allocation, constant-folded access to ellipsoid constants. Used in
`StaticUTM` / `TransverseMercatorStaticProtocol`.

### Extension-based file splitting

Splitting `forward` and `reverse` into separate extension files is
idiomatic Swift. It also works well for AI-assisted development: the stub
(interface contract) and implementation are clearly separated, making it
easy to hand stubs and tests to an AI for implementation.

### Access control for default arguments

An `internal` type (e.g. `Geocentric.wgs84`) cannot appear as a default
argument in a `public` initializer. Use convenience initializers that pass
the internal value explicitly instead.

## AI-assisted development

### Model selection guidance

- **Sonnet**: sufficient for mechanical transcription (coefficient
  functions, series evaluation, straightforward arithmetic porting).
- **Opus**: needed for complex algorithmic porting (Newton's method loops
  with many interdependent mutated variables, symmetry normalisation,
  sign-restoration logic).

Rule of thumb: start with Sonnet, switch to Opus when the code involves
iterative numerical methods with many interdependent state variables.

### Testing is essential for porting

All four bugs in the Geodesic port were discovered only through running
tests against `GeodSolve` reference values — none were visible from code
review alone. Write tests first, port second.

### AI limitations with non-standard C++

AI models struggle with non-conventional C++ patterns: reversed coefficient
arrays, 1-based indexing, last-element-as-divisor. The TransverseMercator
port initially failed because the AI didn't recognise these conventions.
Providing granular tests against C++ internal values (not just final
outputs) was key to diagnosing and fixing the issues.
