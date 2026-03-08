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
