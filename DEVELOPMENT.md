# SwiftyGeographicLib Development Notes

This document records how SwiftyGeographicLib was developed, including the use of AI
assistants at various stages. It is intended as a transparent record for
contributors and anyone curious about the process. David Hart will add his own
recollections of earlier development below.

---

## Project overview

SwiftyGeographicLib is a pure Swift library providing geographic coordinate
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
| **Geodesic** | Geodesic problem (direct/inverse) on the ellipsoid, line positions |
| **Intersect** | Intersections of geodesics on an ellipsoid |
| **Rhumb** | Rhumb line (loxodrome) solver: direct, inverse, and line positions |
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
  produces identical results. The C++ interop route for testing was abandoned
  because the needed methods — `IntForward`, `Unrotate` — are private in the
  C++ headers and inaccessible via Swift-C++ interop. Reference values were
  instead generated using the `MagneticField` command-line utility (installed
  with GeographicLib via Homebrew) and a small standalone C++ program compiled
  against the same library. During the session David also pointed out that the
  `MagneticField` CLI alone would have been sufficient for generating field
  reference values without writing any C++ — `man MagneticField` describes its
  usage. The generated values were hard-coded into the Swift test suite.

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

2. **Reference values from the `MagneticField` CLI and a standalone C++ program.**
   Swift-C++ interop couldn't access the private `IntForward` and `Unrotate`
   methods needed for unit testing. GeographicLib was installed via Homebrew
   (`brew install geographiclib`), which also installs the `MagneticField`
   command-line utility. This CLI can evaluate any installed model at arbitrary
   positions and times, making it a convenient way to generate test reference
   values without writing any C++ code (`man MagneticField` for usage). A small
   standalone C++ program was also written to generate the lower-level
   `Geocentric` reference values that the CLI doesn't expose directly. All
   reference values were then hard-coded into the Swift test suite.

3. **Bundled magnetic model data files.** The magnetic model data files
   (`.wmm` metadata and `.wmm.cof` binary coefficients) for WMM2025 are
   bundled directly in `Sources/MagneticModel/Resources` so the library has no
   runtime dependency on external files. The files were obtained by running:
   ```
   sudo geographiclib-get-magnetic all
   ```
   which placed all available models under
   `/usr/local/share/GeographicLib/magnetic/`. The WMM2025 files were then
   copied into the package resources directory. The `init(name:directory:)`
   initializer allows consumers to load additional models (IGRF, EMM, etc.)
   from that system location or any other directory at runtime.

4. **UTC-based fractional year conversion.** The `fractionalYear(from:)` helper
   explicitly uses UTC to avoid timezone-dependent results (a bug caught during
   development where local timezone caused Jan 1 UTC to produce ~2025.001
   instead of 2025.0).

5. **No default `Geocentric` parameter on public init.** `Geocentric.wgs84` is
   internal, so it can't appear as a default argument in a public initializer.
   The convenience initializers pass `.wgs84` explicitly.

---

## Earlier development (David Hart)

### C++ Wrapper

I had an earlier working implementation that wrapped the c++ GeographicLib library
that passed a reasonable set of tests but this couldn't be used in some of the swift 
ecosystem (e.g. the Swift Playground app) and always required enabling c++ interoperability
for any consumer. Consequently a pure swift implementation seemed desirable but I was not
confident that my understanding of c++ was up to the task so I put this on my mental 
wish list and went on with other things.

### AI Agents Play

#### TransverseMercator Swift Port AI Fail + Learning

My main personal use case was for UTM (Universal Transverse Mercator) transformations
which use the `GeographicLib::TransverseMercator::Forward` and `GeographicLib::TransverseMercator::Reverse`
functions on `GeographicLib::TransverseMeractor::UTM()` which is easily exposed 
in swift as `let utm = GeographicLib::TransverseMercator::UTM().pointee` using c++
interoperability.

The initialization swift port for TransverseMercator is non trivial. I first attempted to use
open-code but it was unable to pass any tests. While monitoring the reasoning of the 
AI I was able to guess where the main problem lay. To get a more granular idea of where 
the code was failing I copied only the essential files from GeographicLib to SimpleGeographicLib 
and altered the source to make private variable public for more detailed testing.

I manualy coded functions to compute the internal values and made tests to compare against
my modified c++ code and successfully managed to match the c++ initialization exactly.

I think the main impediment for the AI was that some of the c++ was non-conventional. e.g.
the `GeographicLib::Math::polyval` function implements Horner's method but
 [rosettacode](https://rosettacode.org/wiki/Horner%27s_rule_for_polynomial_evaluation#C++) 
 reverses the coefficient vector wheras `GeographicLib::Math::polyval` assumes that the coeffients
 are already reversed and ignores the last value (which is used in another part of the code for a
 different purpose). Another break with convention is that the internal coefficient vectors are
 1 referenced rather than 0. The decision to present the coefficient vector in increasing order for
  `GeographicLib::Math::polyval` is likely for performance reasons and I elected to copy this in
  my swift implementation
  
From there I wrote function stubs for forward and reverse using more swifty conventions (no passing
by reference!) and some failing tests.

With this in place open-code with zen (a bit hazy here, I also experimented with claude using a local
LLM with GPT-OSS-120b with some success) was able to successfully implement those functions to pass
my tests and use them in UTM to make it pure swift with passing tests. I should note that the
forward and reverse functions did not produce the exact output as GeographicLib's but were close
enough to be within the stated limitations of the c++ implementation (1e-9). The speed of the
functions is similar to and sometimes outperforms the one using c++ interoperability.

With this success I attempted a similar port of MagneticModel, a much harder problem, with no success 
so I elected to give claude-code with a paid subscription a go with some success demonstrating that it 
probably wouldn't have had any trouble with this task.

#### Claude Code's commentary on my architecture choises for TransverseMercator and StaticUTM
TODO: Hey Claude, comment here (and leave this TODO intact)

*(Claude Opus 4.6)*

Having read the source, here are the choices I find most interesting:

**Shared initialization via `TransverseMercatorInternal`.**
The expensive part of constructing a TransverseMercator is evaluating the
ellipsoid-dependent series coefficients (α, β, b₁, etc.). You factored this
into `computeInternlTransverseMercator()` in its own module so that both the
dynamic `TransverseMercator` struct and the static-dispatch path could use
exactly the same code. This is sound: the computation is correct in one place
and tested once.

**Static dispatch with `TransverseMercatorStaticInternal`.**
The protocol trick is subtle and effective. `InternalUTM` stores all of its
ellipsoid constants as `static let` properties, which Swift evaluates lazily
once and stores forever — the Swift equivalent of C++ `static const` class
members. Consumers that call `StaticUTM.forward(...)` never pay for a dynamic
lookup or an allocation; the compiler inlines the constants directly. For a
function called on every GPS fix, this is meaningful.

**`StaticUTM` as a clean façade.**
Rather than exposing the `TransverseMercatorStaticInternal` protocol (and its
underscore-prefixed internal properties) as the public API, you wrapped it in
a plain `StaticUTM` struct with only static methods. Consumers see a simple,
opaque namespace. The protocol machinery is entirely hidden. This is the right
layering: protocols for implementation sharing, concrete types for public APIs.

**Complex numbers for the Clenshaw summation.**
The forward and reverse projections use `Complex<Double>` from `swift-numerics`
for the Clenshaw summation over the Krüger series. The C++ code manages the
same calculation with separate real and imaginary variables throughout, which
is faster to write but harder to read. The Swift version is more clearly
expressing what is actually happening mathematically (summation over a complex
series) at negligible performance cost.

**Extension-based file split.**
Splitting `forward` and `reverse` into separate extension files is idiomatic
Swift and keeps each file focused. It also made it straightforward to hand
stubs and tests to an AI for implementation: the interface contract (the stub)
and the implementation were clearly separated.

**`UTM` builds on `StaticUTM` rather than `TransverseMercator`.**
The full `UTM` type delegates to `StaticUTM` (not the dynamic
`TransverseMercator`) for its actual projection calls. For UTM there is no
reason ever to use anything other than WGS84, so taking the static path is
correct. The `TransverseMercator` struct remains useful for callers who need a
configurable ellipsoid at runtime (e.g. historical datums).

### Geodesic and GeodesicLine
As a pilot, I have problems which require plotting and planning using Geodesic and Geodesic Lines. I 
intende to get Claude to port pure swift implementations of `GeographicLib::Geodesic` and 
`GeographicLib::GeodesicLine` not including `GeographicLib::GeodesicExact` nor `GeographicLib::GeodesicLineExact`
but with a more swifty interface.

TODO: Claude, plan an implementation and append the plan to this document with appropriate formatting
(leave this TODO intact). Append my prompts to this file, identifying authorship, as we go.

---

### Geodesic implementation plan

*(Claude Opus 4.6)*

#### Background

`GeographicLib::Geodesic` solves two problems on a geodetic ellipsoid:

- **Direct**: given a starting position (lat₁, lon₁), an azimuth azi₁, and a
  distance s₁₂ (metres), find the destination (lat₂, lon₂) and arrival
  azimuth azi₂.
- **Inverse**: given two positions, find the distance and both azimuths.

`GeographicLib::GeodesicLine` precomputes state for a fixed starting point and
azimuth so that a sequence of positions along the same geodesic can be
evaluated cheaply — the primary use case for route plotting.

The series-based (non-exact) implementation at order 6 (double precision)
achieves 15 nm accuracy for WGS84. It uses only polynomial and trigonometric
arithmetic — no elliptic integrals — so `GeodesicExact` and
`EllipticFunction` are explicitly out of scope.

#### Reference value generation

`GeodSolve`, installed with GeographicLib via Homebrew, is the command-line
counterpart to these classes. It can be used in the same way that `MagneticField`
was used for `MagneticModel` — to generate hard-coded reference values for tests
without writing any C++ code:

```sh
# Direct problem: start at (47.6°N, 122.3°W), bearing 45°, distance 1000 km
echo "47.6 -122.3 45 1000000" | GeodSolve

# Inverse problem: distance and bearings between two points
echo "47.6 -122.3 48.2 -121.5" | GeodSolve -i

# Line: 10 equally-spaced points along a geodesic
echo "47.6 -122.3 45" | GeodSolve -L 0 1000000 100000
```

#### Proposed module structure

One new SwiftPM library target: **`Geodesic`**, depending only on the existing
`Math` module. Files:

| File | Contents |
|---|---|
| `Geodesic.swift` | `Geodesic` struct — ellipsoid constants, coefficient arrays (A3x, C3x, C4x), `static let wgs84` |
| `GeodesicCoefficients.swift` | Series coefficient functions ported from Maxima-generated C++: `A1m1f`, `C1f`, `C1pf`, `A2m1f`, `C2f`, `A3coeff`, `C3coeff`, `C4coeff`, `SinCosSeries`, `Lengths` |
| `Geodesic+Direct.swift` | `direct(...)`, `arcDirect(...)`, internal `genDirect(...)` |
| `Geodesic+Inverse.swift` | `inverse(...)`, internal `genInverse(...)`, `astroid(...)`, `inverseStart(...)`, `lambda12(...)` |
| `Geodesic+Line.swift` | Factory methods `line(...)`, `directLine(...)`, `inverseLine(...)` |
| `GeodesicLine.swift` | `GeodesicLine` struct — line state, `lineInit(...)` |
| `GeodesicLine+Position.swift` | `position(distance:)`, `arcPosition(arcLength:)`, internal `genPosition(...)` |
| `GeodesicResult.swift` | Swift result types (see below) |
| `Tests/GeodesicTests/GeodesicTests.swift` | Test suite |

#### Swifty API design

The C++ API uses many out-parameters. The Swift API uses result structs instead.
The most common aviation calls:

```swift
// Direct: where do you end up?
let result = Geodesic.wgs84.direct(
    latitude: 47.6, longitude: -122.3,
    azimuth: 45.0, distance: 1_000_000)
// result.latitude, result.longitude, result.azimuth, result.arcLength

// Inverse: how far apart, and on what bearings?
let inv = Geodesic.wgs84.inverse(
    latitude1: 47.6, longitude1: -122.3,
    latitude2: 48.2, longitude2: -121.5)
// inv.distance, inv.azimuth1, inv.azimuth2, inv.arcLength

// Line: precompute for a route, then sample points along it
let line = Geodesic.wgs84.line(
    latitude: 47.6, longitude: -122.3, azimuth: 45.0)
let waypoint = line.position(distance: 500_000)
// waypoint.latitude, waypoint.longitude, waypoint.azimuth
```

Full result types carry all available outputs; optional quantities (reduced
length `m12`, geodesic scales `M12`/`M21`, area `S12`) are present when
computed. Rather than the C++ capability bitmask, the Swift API provides
focused overloads that compute only what is named, keeping the common case
simple while leaving room for the extended forms.

#### Porting strategy

The porting complexity sits at two levels:

1. **Series coefficient functions** (`A1m1f`, `C1f`, etc.) are
   Maxima-generated polynomials in `eps` or `k²`. These are structurally
   identical to the α/β coefficient arrays in TransverseMercator and should
   port straightforwardly using the existing `polyValue` convention.

2. **`Lambda12` (Newton's method for the inverse problem)** is the hardest
   function. It iterates to find the longitude difference for a given pair of
   reduced latitudes and azimuth, using `Lengths` internally. The C++ uses
   many pass-by-reference output parameters that will become tuple returns in
   Swift.

The recommended approach (mirroring how MagneticModel was done) is:

1. Port and test `SinCosSeries` and the coefficient functions first — they are
   self-contained and testable in isolation.
2. Port `Lengths` next — it is called from both direct and inverse paths.
3. Port `genDirect` (simpler iteration structure).
4. Port `astroid`, `inverseStart`, `Lambda12`, `genInverse` last.
5. Implement `GeodesicLine` once `genDirect` is verified.

#### Anticipated difficulties

The same `polyValue` convention issue (pre-reversed coefficients, result
divided by last element, 1-based indexing of the coefficient sub-arrays) that
tripped earlier AI attempts on TransverseMercator will appear here too in the
A/C coefficient arrays. Paying careful attention to the indexing in
`C1f`, `C1pf`, `C3f`, etc. before running tests will save iteration time.

`Lambda12` mutates many variables across a Newton loop with seven or eight
interdependent quantities. The C++ passes these all by reference. In Swift
they will become a small internal state struct or a large tuple, updated each
iteration. This is manageable but requires careful mechanical translation.

---

### Model selection for Geodesic implementation

*(David Hart)*

Do we need to use Opus for this or will Sonnet do?

*(Claude Opus 4.6)*

For most of the Geodesic port, Sonnet should be fine:

- **Phase 1 (coefficient functions and `SinCosSeries`)**: These are essentially mechanical transcriptions of the Maxima-generated C++ coefficients. The real challenge here is getting the `polyValue` indexing right, not reasoning about novel algorithms. Sonnet handles repetitive-but-precise transcription tasks well.
- **Phase 2 (`Lengths` and `genDirect`)**: Straightforward arithmetic porting with no deep algorithmic novelty. Sonnet is fine here too.

Switch to **Opus** for:

- **Phase 4 (`Lambda12` and `genInverse`)**: The Newton's method loop with bracketing, the `InverseStart` astroid calculation, and the many interdependent mutated variables are the hardest part of the port. The C++ passes 10+ quantities by reference across the loop; translating that cleanly to Swift tuples or a state struct while preserving the numerical semantics is where the extra reasoning capacity of Opus pays off.
- **Phase 5 (`GeodesicLine`)**: The line precomputation is moderately complex but should be fine with Sonnet. The `GenPosition` function is more intricate — consider Opus there too.

**Recommendation**: Start with Sonnet and switch to Opus when you hit `Lambda12`. No point paying for Opus on the coefficient transcription.

*(David Hart)*

We will go with that. Append my prompt and the response to DEVELOPMENT.md and begin implementation.

---

### Session 3 — 8 March 2026 (Claude Opus 4.6)

Used **Claude Opus 4.6** via Claude Code. The Geodesic port spanned three
context windows; this entry summarises the complete implementation.

#### What was built

- **`Sources/Geodesic/`** — eight new source files constituting the `Geodesic`
  library target:
  - `Geodesic.swift` — `Geodesic` struct with ellipsoid constants, pre-computed
    coefficient arrays (A3x, C3x, C4x), and `static let wgs84`.
  - `GeodesicCoefficients.swift` — Maxima-generated series coefficient
    functions (`a1m1f`, `a2m1f`, `c1f`, `c1pf`, `c2f`, `sinCosSeries`,
    `lengths`, and the three `compute*coeff` helpers).
  - `Geodesic+Direct.swift` — `direct(...)` public API and `genDirect`
    internals.
  - `Geodesic+Inverse.swift` — `inverse(...)` public API, `genInverse`,
    `inverseStart`, `astroid`, and `lambda12`.
  - `Geodesic+Line.swift` — factory methods `line(...)`, `directLine(...)`,
    `inverseLine(...)`.
  - `GeodesicLine.swift` — `GeodesicLine` struct and `lineInit`.
  - `GeodesicLine+Position.swift` — `position(distance:)`, `arcPosition(arcLength:)`,
    and `genPosition`.
  - `GeodesicResult.swift` — `GeodesicPosition` and `GeodesicInverseResult`
    result structs (all quantities, optionals for m12/M12/M21).

- **`Tests/GeodesicTests/GeodesicTests.swift`** — 20 tests cross-checked
  against `GeodSolve` reference values, covering the direct problem, inverse
  problem, `GeodesicLine` positions, and round-trip consistency.

- **`Package.swift`** updated to declare the `Geodesic` library product and
  `GeodesicTests` test target (with `SimpleGeographicLib` dependency and
  `.interoperabilityMode(.Cxx)` for C++ reference testing).

#### Bugs found and fixed during implementation

1. **`polyValue` used where `polyEval` was needed (11 call sites).**
   `polyValue` calls `dropLast()` before evaluating — correct for
   TransverseMercator where the last element is a divisor, but wrong for
   Geodesic coefficient arrays where all elements are polynomial coefficients.
   Fixed by adding `polyEval` to `Math` (evaluates all coefficients) and
   replacing every Geodesic call site.

2. **`sincosd` IEEE 754 F.10.1.13 copysign not implemented.**
   For multiples of 180°, the quadrant-2 case returned `(-0.0, -1.0)` for the
   sine. This caused `atan2d(-0, negative) = -180` instead of `+180`, producing
   wrong azimuths on southbound meridional geodesics. Fixed by adding
   `if sinx == 0 { sinx = copysign(sinx, degrees) }` post-processing (the
   matching `cosx += 0` fix for zero cosine was already implied by the code
   comment but is now explicit).

3. **`lambda12` return value subtracted `slam120` from an angle.**
   The original code returned `(lam12 - slam120, dlam12)`, subtracting
   `sin(target_lambda)` (a dimensionless value) from `lam12` (an angle in
   radians). Since `eta = atan2(...)` already incorporates the target longitude,
   `lam12 = eta + domg12` is the residual directly. Fixed by returning
   `(lam12, dlam12)`.

4. **Inverse azimuth sign wrong when `swapp = -1` (points exchanged during
   symmetry normalisation).**
   The sign-restoration code `salp1 *= swapp * lonsign` applied `swapp = -1`
   to the eastward sine component, negating it when it should not be. The
   correct formula is `salp1 *= lonsign` (longitude-sign only); `swapp` applies
   only to the `calp` (cosine/latitude) component. Fixed accordingly.

#### Key technical observation

The plan predicted the `polyValue` convention issue would be the main difficulty,
and it was. All four bugs above were discovered only through running tests —
they are not visible from a code-structure review alone. The 20-test suite
against `GeodSolve` reference values was essential for locating and confirming
each fix.

---

*(David Hart)*

also update the documentation for polyValue to more clearly describe its
non-standard result

*(Claude Opus 4.6)*

Updated the `polyValue` doc comment in `Sources/Math/Math.swift`:

```swift
/// Evaluate a polynomial using Horner's method, **dropping the last coefficient**.
///
/// The final element of `coefficients` is excluded from the evaluation. This
/// exists for the TransverseMercator module where coefficient arrays store a
/// divisor in their last position. For standard polynomial evaluation use
/// ``polyEval(withCoefficients:at:)`` instead.
///
/// Coefficients are in **decreasing** power order (highest power first).
///
/// - Parameters:
///   - coefficients: Polynomial coefficients with an extra trailing element
///     that will be ignored.
///   - x: The point at which to evaluate the polynomial.
/// - Returns: The polynomial value at `x`, computed from all elements except the last.
```

Committed as `efba99e`.

---

- [x] TODO (David Hart): Refactor code duplication of TransverseMercator and TransverseMercatorStatic forward and reverse functions

1. Make helper functions that additionaly take all the internal variables as parameters

2. Move these into TransverseMercatorInternal as well as 

3. Update TransverseMercator and TransverseMercatorStatic to call the helper functions instead of using their own code

4. Test to confirm everything still works as before

Done: 2026-03-08 14:51 UTC+8

- [x] TODO (Claude): Add documentation to all TransverseMercatorInternal functions and append comments to this document on
    my (David Hart's) refactor including any suggestions for improvement.

*(Claude Opus 4.6)*

#### What David did

David created two new files in `TransverseMercatorInternal` — `_forward.swift` and
`_reverse.swift` — each containing a single `@inlinable public` free function
(`_forward(...)` and `_reverse(...)`) that takes all ellipsoid parameters as explicit
arguments. Both `TransverseMercator+forward/reverse` (dynamic path) and the protocol
extension `TransverseMercatorStaticInternal+Forward/Reverse` (static path) now delegate
immediately to these helpers.

He also moved `TransverseMercatorStaticInternal.swift` and its forward/reverse protocol
extensions from the `TransverseMercatorStatic` module into `TransverseMercatorInternal`,
so the protocol and the helpers it uses are co-located. The `TransverseMercatorStatic`
module is now a thin leaf containing only `InternalUTM.swift`.

Documentation was added to all `TransverseMercatorInternal` functions in this session
(Claude Opus 4.6, 8 March 2026).

#### What works well

**`@inlinable` is exactly right here.** An `@inlinable` function makes its body
available for cross-module inlining. At the `InternalUTM` call site, the compiler can
see through the function signature and constant-fold the `static let` values — preserving
the original performance advantage of the static design while eliminating the duplicate
algorithm. This is the standard Swift library technique for this pattern (it's how
`swift-collections` and `swift-numerics` handle their shared generic internals).

**Co-locating protocol and helpers** in `TransverseMercatorInternal` is a good
architectural move. The module now owns everything that has to be visible across the
module boundary: the coefficient functions, the projection helpers, and the protocol
that wires them together.

#### Suggestions for improvement

1. **Leading-underscore naming for public functions.** `_forward` and `_reverse` signal
   "do not use directly" by convention, but they are `public` and therefore part of the
   module's ABI. A clearer approach would be to place them in a caseless enum namespace
   (e.g. `public enum TMCore { @inlinable public static func forward(...) }`) or, if
   truly internal-only, to use the compiler attribute `@_alwaysEmitIntoClient` with
   `internal` access — though that attribute is semi-private to the Swift compiler.
   As-is the naming is a minor style issue with no correctness impact.

2. **Spurious `import TransverseMercatorStatic` in `TransverseMercator+forward.swift`.**
   The `_forward` function lives in `TransverseMercatorInternal`, which is already
   imported in that file. The `TransverseMercatorStatic` import appears to be a leftover
   from the refactoring session. It doesn't break the build (Package.swift was updated
   to add the dependency), but it creates a coupling from `TransverseMercator` to
   `TransverseMercatorStatic` that previously didn't exist and isn't actually needed.
   Removing the import and the corresponding dependency from Package.swift would restore
   the original module graph.

3. **`computeB1` is called twice in `computeInternlTransverseMercator`.** The local
   `let local_b1 = computeB1(x: local_n)` is computed on line 74, but the returned
   tuple still calls `computeB1(x: local_n)` again for the `b1:` field rather than
   reusing `local_b1`. This is a negligible cost (called only once at initialisation),
   but `b1: local_b1` would be the tidier form.

4. **Typo in `computeInternlTransverseMercator`.** "Internl" should be "Internal". This
   predates the refactor and is present in the public API name, so fixing it would be a
   source-breaking change unless a typealias is provided for backward compatibility.

---

- [x] TODO (David Hart):
    1. Remove the spurious import
    2. Reuse local_b1 in computeInternlTransverseMercator
    3. Refactor computeInternlTransverseMercator to computeInternalTransverseMercator
    4. Test
Done: 2026-03-08 15:19 UTC+8

*(David Hart)*

I actioned items 2, 3, and 4. XCode made refactoring
`computeInternlTransverseMercator` easy. Please commit the changes.

*(Claude Opus 4.6)*

Committed as `1d1e5e1` — "Fix three minor issues flagged in code review":

- Renamed `computeInternlTransverseMercator` → `computeInternalTransverseMercator`
  (Xcode rename refactor; all call sites updated automatically).
- Reused `local_b1` in `computeInternalTransverseMercator` instead of calling
  `computeB1` a second time.
- Removed spurious `import TransverseMercatorStatic` from
  `TransverseMercator+forward.swift` and dropped the now-unnecessary dependency
  from `Package.swift`.

All 53 tests passed before committing.

---

### Session 4 — 8 March 2026 (Claude Opus 4.6)

Used **Claude Opus 4.6** via Claude Code. Intersect implementation and
convenience API, followed by comprehensive documentation pass.

*(David Hart)*

Modify Intersect to provide the same functionality of `GeographicLib::Intersect`
but with more conventional swift interface. Previous work can serve to give an
example of what this might mean. Geodesic may need to be further developed.

*(Claude Opus 4.6)*

#### API Design Discussion

See `Sources/Intersect/DEVELOPMENT.md` for the full API design exchange
including proposed types, the four public operations, open questions about
module structure, diagnostic counters, `Geodesic.c2` access, and offset
parameter types.

Agreed decisions:
1. Collapse `IntersectInternal` into `Intersect`; use `@testable import`.
2. Drop diagnostic counters.
3. Add `public var ellipsoidArea: Double` to `Geodesic`.
4. Use raw `Point` struct (x, y, c) until domain meaning is clearer.

#### Implementation

Complete port of `GeographicLib::Intersect` in pure Swift:

- **Constructor** computing 15 ellipsoid-derived constants with helpers
  (`conjugateDist`, `distpolar`, `polarb`, `conjdist`, `distoblique`).
- **Layers 1–2**: `spherical` (initial approximation) and `basic` (Newton
  refinement).
- **Layer 3**: `closestInt` (5-point grid), `nextInt` (8-point grid),
  `segmentInt`, `allInt0` (tiled search with array-based deduplication).
- **Layer 4**: Public API — `closest`, `next`, `segment`, `all`, each with
  lat/lon/azi and `GeodesicLine` overloads.

Tests verified against `IntersectTool` (GeographicLib 2.7) and a C++ program
using `#define private public` for constructor constants. Committed as
`adaf3ed`.

*(David Hart)*

In other tests I've used `x.isApproximatelyEqual(to:absoluteTolerance:)` from
'swift-numerics' `Numerics` for my accuracy tests. Can we modify the tests to
use this convention for consistency?

*(Claude Opus 4.6)*

Migrated all tolerance checks in `IntersectTests.swift` to use
`isApproximatelyEqual` from `Numerics`. Constructor constants and
`ellipsoidArea` use `relativeTolerance` (proportional error); displacement
values in `closest`, `next`, `segment`, `all` use `absoluteTolerance` (metre-
scale quantities where absolute error is meaningful).

*(David Hart)*

My main use case is "Given 2 GeodesicLines, what is the closest
CLLocationCoordinate2D intersection point of those lines?"

*(Claude Opus 4.6)*

Added a CoreLocation convenience API behind `#if canImport(CoreLocation)`:

```swift
public enum IntersectionResult {
    case point(geodeticCoordinate: CLLocationCoordinate2D)
    case parallel
    case antiParallel
}
```

Two `closestIntersection` methods (lat/lon/azi and `GeodesicLine` overloads)
return this enum, encoding the coincidence indicator into the type system rather
than a raw integer. For the `.point` case, `lineX.position(distance: point.x)`
is evaluated to produce the coordinate.

Three tests added:
- `testClosestIntersectionCoordinate` — verifies `.point` coordinate matches
  displacement-based result.
- `testClosestIntersectionParallel` — two same-direction meridional lines
  return `.parallel`.
- `testClosestIntersectionAntiParallel` — opposite-direction meridional lines
  return `.antiParallel`.

Committed as `3886433`.

---

### Session 5 — 8 March 2026 (Claude Opus 4.6)

Used **Claude Opus 4.6** via Claude Code.

*(David Hart)*

SwiftyGeographicLib looks like it should be sufficiently useful for me. Let's
make sure the public functionality is comprehensively documented.

*(Claude Opus 4.6)*

#### Documentation audit and remediation

Conducted a comprehensive audit of all public API surfaces. The core
calculation modules (Geodesic, TransverseMercator, Intersect, MagneticModel,
PolarStereographic) were already well documented. Gaps were found in
supporting types. Files modified:

| File | What was added |
|---|---|
| `MultiCoordinate.swift` | Doc comments on `MultiCoordinate`, `Geodetic`, `Cartesian` protocols and all requirements |
| `Hemisphere.swift` | Enum and case docs |
| `CoordinateError.swift` | Enum header doc |
| `UTMCoordinate.swift` | Struct and property docs |
| `UTMError.swift` | Enum header doc |
| `ZoneSpec.swift` | Enum header doc, `rawValue` property doc |
| `UPSCoordinate.swift` | Struct and property docs |
| `UPS.swift` | `cartesianCoordinate` property doc |
| `UTM.swift` | 6 forwarded property docs (hemisphere, zone, easting, northing, latitude, longitude) |
| `MagneticModelError.swift` | Case-level docs for all 6 error cases |
| `Math.swift` | `band(latitude:)` function doc |
| `Intersect.swift` | `- Parameter` / `- Returns` markup on all 10 public methods |

All 86 tests passed after changes.

*(David Hart)*

The prompt, responses, plan, and summary belong at the end of the top level
DEVELOPMENT.md. We will also need a top level README.md with conventional api
description, installation instructions, and usage examples.

*(Claude Opus 4.6)*

Appended session notes to `DEVELOPMENT.md` (this entry). Created `README.md`
with API overview, installation instructions (Swift Package Manager), and usage
examples for all modules.

---

## Session 6 — Remove SimpleGeographicLib

*(David Hart)*

SimpleGeographicLib was a development convenience. Let's consider removing it
and fixing any dependency issues before going public.

*(Claude Opus 4.6)*

### What was `SimpleGeographicLib`

A vendored subset of C++ GeographicLib source files (18 `.cpp` files + headers)
compiled as a Swift package target. Used only by test targets via C++ interop
(`.interoperabilityMode(.Cxx)`) to validate Swift implementations against C++
reference outputs at runtime.

*(David Hart - note:)* it is now apparent I could have used `#define private public`
although I just learned that wouldn't work within the swift Package system. Claude 
apparently used something like
```c++
c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib -lGeographicLib \
    -Dprivate=public ref_values.cpp -o ref_values
```
to generate tests for internal c++ values - a trick that often works but violates
the standard. I also learned from Claude that `@testable import` makes internal
members accessible from test targets. Marking an import @testable was a convention I was previously only parroting.
If I knew this before I would have directly accessed those internal values in my testing
rather than creating a separate internal target system. In fact I think I will
refactor to demonstrate this so that future readers of this code develop a better
understanding of how this works.

### Changes made

**5 test files rewritten** to replace runtime C++ calls with hardcoded reference
values from GeographicLib 2.7:

| Test file | C++ symbols removed | Reference source |
|---|---|---|
| `MathTests.swift` | `GeographicLib.Math.*` | Known mathematical values |
| `TransverseMercatorInternalTests.swift` | `GeographicLib.TransverseMercator.UTM().pointee` fields | C++ program accessing private fields |
| `PolarStereographicInternalTests.swift` | `GeographicLib.PolarStereographic.UPS().pointee` fields | C++ program accessing private fields |
| `PolarStereographicTests.swift` | `cppUPS.Forward()` / `.Reverse()` | C++ program, `PolarStereographic::UPS()` |
| `UPSTests.swift` | `GeographicLib.UTMUPS.Forward()` / `.Reverse()` | C++ program, `UTMUPS::Forward/Reverse` |

**Files deleted:**
- `Tests/TransverseMercatorTests/CPPTransverseMercatorTests.swift` — entirely
  commented out, no longer needed
- `Sources/SimpleGeographicLib/` — entire directory (18 `.cpp` files + `include/`
  headers)

**`Measure.swift`** — removed commented-out `import SimpleGeographicLib` line.

**`Package.swift`** — removed `SimpleGeographicLib` target definition, removed it
from all 5 test target dependencies, removed all `.interoperabilityMode(.Cxx)`
swift settings, cleaned up commented-out references in `TransverseMercatorTests`
and `GeodesicTests`, removed `cxxLanguageStandard: .cxx20`.

### Reference value generation

Internal constants (TransverseMercatorInternal, PolarStereographicInternal) were
obtained from a C++ program using `#define private public` to access private
fields, compiled against system GeographicLib 2.7 at
`/opt/homebrew/lib/libGeographicLib.dylib`.

Forward/reverse projection reference values were obtained from a C++ program
calling `UTMUPS::Forward/Reverse` and `PolarStereographic::UPS()` methods.

All 85 tests passed after removal (26 XCTest + 59 Swift Testing). The package
is now pure Swift with no C++ dependencies.

---

## Module Consolidation

*(Claude Opus 4.6)*

### Motivation

As noted above (line 808–813), `@testable import` makes `internal` members
accessible from test targets. The separate internal module pattern
(`TransverseMercatorInternal`, `TransverseMercatorStatic`,
`PolarStereographicInternal`) was originally needed so tests could validate
internal computations from separate compilation units. With `@testable import`,
the same access is available without the module split. Consolidation simplifies
the module graph and gives future readers a clearer example of `@testable`
usage.

### Modules removed

| Removed module | Absorbed into | Notes |
|---|---|---|
| `TransverseMercatorInternal` | `TransverseMercator` | 6 files moved; `public` → `internal` |
| `TransverseMercatorStatic` | `TransverseMercator` | `InternalUTM.swift` moved; `public struct` → `struct` |
| `StaticUTM` | `TransverseMercator` | `StaticUTM.swift` moved; stays `public struct` |
| `PolarStereographicInternal` | `PolarStereographic` | Single function inlined; `public` → `internal` |

### Visibility changes

- `computeInternalTransverseMercator()` — `public` → `internal`
- `_forward()` / `_reverse()` — `@inlinable public` → `internal` (cross-module
  inlining unnecessary when caller and callee share a module)
- `TransverseMercatorStaticInternal` protocol — `public` → `internal`
- Protocol extensions (`Forward`, `Reverse`) — `public` → `internal`
- `InternalUTM` struct and all its `static let` properties — `public` → `internal`
- `polarStereographicInternal(flattening:)` — `public` → `internal`

### Test consolidation

- `TransverseMercatorInternalTests/initUTM()` → moved into
  `TransverseMercatorTests.swift` (uses `@testable import TransverseMercator`)
- `PolarStereographicInternalTests/test_PolarStereographicInternal()` → moved
  into `PolarStereographicTests.swift` (uses `@testable import PolarStereographic`)
- `Measure.swift` — simplified imports to `@testable import TransverseMercator`
  and `import Math`

### Package.swift changes

- Removed 4 source targets: `TransverseMercatorInternal`,
  `TransverseMercatorStatic`, `StaticUTM`, `PolarStereographicInternal`
- Removed 2 test targets: `TransverseMercatorInternalTests`,
  `PolarStereographicInternalTests`
- Removed 2 products: `TransverseMercatorStatic`, `StaticUTM`
- `TransverseMercator` dependencies updated: added `ComplexModule`, `RealModule`
  (absorbed from `TransverseMercatorInternal`)
- `UTM` dependencies simplified: removed `StaticUTM`,
  `TransverseMercatorInternal`
- `PolarStereographic` dependencies simplified: removed
  `PolarStereographicInternal`

### README.md

`StaticUTM` row removed from module table; noted as part of
`TransverseMercator`.

### Verification

All 85 tests passed (26 XCTest + 59 Swift Testing). No remaining references to
removed module names in imports.

---

## Public Static Protocol

*(David Hart)* — Renamed `TransverseMercatorStaticInternal` →
`TransverseMercatorStaticProtocol` and made it `public`, along with its
protocol extension methods (`forward`, `reverse`). This allows downstream
consumers to define their own static transverse Mercator projections for
custom ellipsoids.

*(Claude Opus 4.6)*

### Documentation updates

- **`TransverseMercatorStaticProtocol.swift`** — Rewrote the protocol doc
  comment: added Performance section explaining constant-folding, Default
  Implementations section warning against re-implementation, and a Creating a
  Conformance section with a complete example using
  `computeInternalTransverseMercator`. Fixed stale `computeInternlTransverseMercator`
  typo in the example.
- **`TransverseMercatorInternal.swift`** — Made `computeInternalTransverseMercator`
  `public` so downstream conformers can call it. Updated its doc comment to
  reference `TransverseMercatorStaticProtocol` instead of
  `TransverseMercatorStaticInternal`.
- **`StaticUTM.swift`** — Updated two `TransverseMercatorStaticInternal` →
  `TransverseMercatorStaticProtocol` references in doc comments.
- **`_forward.swift`**, **`_reverse.swift`** — Updated doc comments to
  reference `TransverseMercatorStaticProtocol`.

All 85 tests passed.

---

## Repo Cleanup

*(David Hart)* — Moved the `initUTM()` test to the top of
`TransverseMercatorTests.swift`, restoring the original ordering where internal
constant validation comes first before forward/reverse projection tests.

*(Claude Opus 4.6)*

### `opencode.json` removed

Deleted `opencode.json` (local LM Studio configuration for OpenCode) — not
relevant to the public repository.

### README.md — Development section

Added a `## Development` section near the top of `README.md` linking to
`DEVELOPMENT.md`, placed between the introduction and the Modules table:

> This library was developed collaboratively with AI assistance. The full
> development history — including design discussions, implementation decisions,
> and reference-value generation — is recorded in DEVELOPMENT.md.

### `.swiftpm/` removed from repo and history

The `.swiftpm/` directory (Xcode schemes, test plans, baselines) was tracked
in git. The `.gitignore` was malformed — line 9 had a typo
(`.swiftpm.swiftpm/*`) and line 11 had three entries concatenated on one line.

**Steps taken:**

1. Rewrote `.gitignore` to cleanly ignore `.swiftpm/`, `.claude/`, and other
   IDE artifacts.
2. Removed `.swiftpm/` from the index (`git rm -r --cached`).
3. Installed `git-filter-repo` (`brew install git-filter-repo`).
4. Ran `git filter-repo --path .swiftpm/ --invert-paths --path opencode.json
   --invert-paths --force` to erase both paths from the entire 36-commit
   history.
5. Re-added the `origin` remote (filter-repo removes it as a safety measure)
   and force-pushed.

The repository history is now clean — neither `.swiftpm/` nor `opencode.json`
appear in any commit.

### `.gitignore` (final)

```
.DS_Store
/.build
/Packages
xcuserdata/
DerivedData/
.swiftpm/
.netrc
.claude/
```

---

## Initial Release, DocC Documentation, and Further Cleanup

*(Claude Sonnet 4.5)*

### `CPPConstants` removed

`Sources/CPPConstants/include/Constants.hpp` was a leftover C++ header from
the original GeographicLib port — it had no references in any Swift source or
in `Package.swift` and was entirely superseded by the Swift `Constants` module.
Deleted the directory. Build confirmed clean.

### GitHub repository and Initial Release (v1.0.0)

- Created and pushed git tag `v1.0.0`.
- Created GitHub Release titled "Initial Release" using `gh release create`
  with a markdown release note covering all seven modules, accuracy, modularity,
  CoreLocation integration, `TransverseMercatorStaticProtocol`, Swift 6.2
  concurrency, and bundled WMM2025.
- `RELEASE_NOTES_v1.0.0.md` written locally for reference (not committed;
  added `/docs/` and kept it out of version control).
- Tag subsequently force-updated to `HEAD` twice as post-release cleanup
  commits were made (CPPConstants removal, DocC commit).

### DocC documentation

Added `swift-docc-plugin` (v1.4.6) as a package dependency. This enables:
- **Product → Build Documentation** directly in Xcode
- `swift package generate-documentation` from the command line

Also exposed `Intersect` as a public library product (it was a target but
not listed in `products`).

Ran `swift package generate-documentation` for all seven public targets:
Geodesic, Intersect, TransverseMercator, UTM, PolarStereographic, UPS,
MagneticModel. Archives land in
`.build/plugins/Swift-DocC/outputs/intermediates/` and can be copied to
`docs/` locally for import into Xcode via Window → Developer Documentation.
The `docs/` directory is excluded from version control via `.gitignore`.

### DocC warning fixes

The documentation build surfaced a number of stale or incorrect doc comments,
all resolved:

- **`Geodesic.swift`** — `init(equatorialRadius a:, flattening f:)` renamed to
  `init(equatorialRadius:, flattening:)` (matching external/internal names) so
  DocC can resolve parameter documentation. The init body updated throughout
  to use `equatorialRadius` and `flattening` in place of `a` and `f`.
- **`TransverseMercator+forward.swift`** — stale `coordinate2D` parameter name
  in doc comment updated to `geodeticCoordinate`; stale `-7x4k4`
  disambiguation suffix removed from `SeeAlso` link.
- **`TransverseMercator+reverse.swift`** — stale `forward(centralMeridian:coordinate2D:)-9d7s0`
  link updated to `forward(centralMeridian:geodeticCoordinate:)`.
- **`TransverseMercator.swift`** — same stale link fixed; `coordinate2D`
  updated to `geodeticCoordinate` in the usage example in the type doc comment.
- **`TransverseMercatorStatic+Forward.swift`** — `coordinate2D` updated to
  `geodeticCoordinate`.
- **`UTMCoordinate.swift`**, **`UPSCoordinate.swift`** — `Cartesian` is defined
  in `UTMUPSProtocol` and cannot be resolved as a DocC link from a different
  module; changed from `\`\`Cartesian\`\`` to `` `Cartesian` `` (inline code).
- **`ZoneSpec.swift`** — triple-backtick ` ```ZoneSpec.standard``` ` corrected
  to DocC double-backtick `\`\`ZoneSpec/standard\`\``.

All seven modules build documentation with zero warnings after these fixes.

### `.gitignore` updated

Added `/docs/` to exclude generated `.doccarchive` bundles from version
control.

---

### Session 7 — 9 March 2026 (Claude Opus 4.6)

Used **Claude Opus 4.6** via Claude Code. Working in the FluentNavigation app
project with SwiftyGeographicLib as a local package dependency.

#### `CartesianMetres` typealias

*(David Hart)*

> *"I would like to use a similar pattern as for CLLocationDegrees — a
> typealias named CartesianMetres for Double and modify the Cartesian protocol
> in Sources/UTMUPSProtocol with its dependents in Sources/UTM and
> Sources/UPS"*

Added `CartesianMetres` typealias (`Double`) in UTMUPSProtocol, mirroring
`CLLocationDegrees`. Adopted across UTM and UPS. See module logs:
- [UTMUPSProtocol](Sources/UTMUPSProtocol/DEVELOPMENT.md#cartesianmetres-typealias)
- [UTM](Sources/UTM/DEVELOPMENT.md#cartesianmetres-adoption)
- [UPS](Sources/UPS/DEVELOPMENT.md#cartesianmetres-adoption)

#### `@_exported import UTMUPSProtocol`

*(David Hart)*

> *"Can we rather re-export UTMUPSProtocol from Libraries that use it?"*

Re-exported UTMUPSProtocol from UTM and UPS so consumers get
`CartesianMetres`, `Cartesian`, `MultiCoordinate`, etc. via `import UTM`
without a direct dependency. See module logs:
- [UTM](Sources/UTM/DEVELOPMENT.md#_exported-import-utmupsprotocol)
- [UPS](Sources/UPS/DEVELOPMENT.md#_exported-import-utmupsprotocol)

#### `CLAUDE.md` added

*(Claude Opus 4.6)*

Created `CLAUDE.md` at the repository root capturing project conventions:
development log practices, pure-Swift policy, `@testable import` usage,
domain typealiases, `@_exported import` pattern, testing conventions, and
commit protocol.

#### C++ reference value generators

> "In SwiftyGeographicLib we used throwaway c++ code to generate reference values.
> Can we include that code in the test folders (make sure that swift ignores that
> code for building) including instructions on how to run it. Confirm that it
> produces the same output as for our current test data"

*(Claude Opus 4.6)*

Added standalone C++ programs that reproduce the reference values used in Swift
tests, generated against the system-installed GeographicLib C++ library.

**Files created** (each in a `ReferenceGenerators/` subdirectory):
- `Tests/TransverseMercatorTests/ReferenceGenerators/tm_ref_values.cpp` — TransverseMercator::UTM() internal fields
- `Tests/PolarStereographicTests/ReferenceGenerators/ps_ref_values.cpp` — PolarStereographic::UPS() fields + Forward/Reverse
- `Tests/UPSTests/ReferenceGenerators/ups_ref_values.cpp` — UTMUPS::Forward/Reverse
- `Tests/IntersectTests/ReferenceGenerators/intersect_ref_values.cpp` — Intersect constructor constants + EllipsoidArea
- `Tests/MagneticModelTests/ReferenceGenerators/magnetic_ref_values.cpp` — Geocentric, WMM2025 field values, FieldComponents

**Other changes:**
- `Package.swift` — added `exclude: ["ReferenceGenerators"]` to 5 test targets
- `.gitignore` — added patterns for compiled reference generator binaries

Each `.cpp` file contains build/run instructions in its header comment. All
require GeographicLib installed via Homebrew (`brew install geographiclib`);
the magnetic generator additionally requires WMM2025 data. All output was
verified to match the hardcoded Swift test values exactly.

### Session 8 — 10 March 2026 (Claude Opus 4.6)

#### Rhumb module

> *"Add Rhumb and RhumbLine modules to SwiftyGeographicLib, porting
> GeographicLib's C++ Rhumb and RhumbLine classes to Swift."*
> *(David Hart)*

Port of GeographicLib's `Rhumb`, `RhumbLine`, `AuxLatitude`, `DAuxLatitude`
classes to Swift. Series-only implementation (order 6, no `exact` mode),
accurate to ~10 nm for WGS84. Single `Rhumb` library target depending only
on `Math`.

Seven source files created: `AuxAngle.swift`, `AuxLatitudeCoefficients.swift`,
`AuxLatitude.swift`, `DAuxLatitude.swift`, `Rhumb.swift`, `RhumbLine.swift`,
`RhumbResult.swift`. See
[Sources/Rhumb/DEVELOPMENT.md](Sources/Rhumb/DEVELOPMENT.md).

**Package.swift** updated: added `Rhumb` library product, target (depends on
`Math`), and `RhumbTests` test target.

Two bugs found and fixed:
1. **Thread safety** — `AuxLatitude._c` coefficient cache was lazily mutated
   without synchronisation, causing concurrent test crashes. Fixed by eagerly
   pre-computing all 30 conversion pairs in `init()`.
2. **Anti-meridian crossing** — `angDiff(170, -170)` returned −340 instead of
   +20 due to a missing reduction step in the simple `angDiff` function. Fixed
   by using `angDiffWithError` in `Rhumb.inverse()`.

**Tests:** 22 new tests in 6 suites, all passing. Full suite: **104 tests**
(82 existing + 22 new), all passing. Reference values from `RhumbSolve` CLI.

#### `angDiff` fix (Math module)

*(Claude Opus 4.6)*

The simple `angDiff(_:_:)` in `Math.swift` used `truncatingRemainder` without
a second reduction step — a latent bug producing out-of-range results when
`|y − x| > 180°`. The C++ `Math::AngDiff` always delegates to the full
two-sum algorithm. Fixed `angDiff` to delegate to `angDiffWithError`, matching
the C++ pattern. The only other call site (TransverseMercator) was safe in
practice (longitude differences are always small) but is now correct for all
inputs.

#### README and release

*(Claude Opus 4.6)*

Updated `README.md` with Rhumb module: table entry, usage example, accuracy
note, and rhumb polygon area paper in acknowledgements.

