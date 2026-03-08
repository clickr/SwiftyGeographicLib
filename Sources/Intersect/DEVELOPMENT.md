#  Intersect Development Notes

This document records how Intersect was developed. It is intended as a transparent record for
contributors and anyone curious about the process.

This should include AI prompts and responses, along with contributer comments and notes, todos,
implementation plans, 

## Task Overview
Modify Intersect to provide the same functionality of `GeographicLib::Intersect` but with 
more conventional swift interface. Previous work can serve to give an example of what this might
mean. Geodesic may need to be further developed.

## Work so far
An incomplete init(geodesic:) and a helper function that fails tests.

---

## API Design Discussion

*(David Hart)*

Discuss an approach to implement Intersect — API design first, then work backwards to
implementation.

*(Claude Opus 4.6)*

### What the C++ exposes

`GeographicLib::Intersect` has four public operations, each with two overloads
(lat/lon/azi parameters, or pre-built `GeodesicLine` objects):

| Method | Purpose |
|---|---|
| `Closest` | Find the intersection closest to an offset point (L1 metric) |
| `Segment` | Find intersection of two geodesic segments; returns a `segmode` indicator |
| `Next` | Find the next closest intersection from a known intersection point |
| `All` | Find all intersections within a maximum distance |

All methods return `Point` = `std::pair<real, real>` — signed displacements
(metres) along geodesics X and Y. The coincidence indicator (`c`) is an
optional out-parameter.

### Proposed Swift result types

The C++ uses a raw pair + separate out-parameter. Swift should bundle everything
into named structs:

```swift
/// Signed displacements along two geodesics at an intersection.
public struct IntersectionPoint {
    /// Signed displacement along geodesic X (metres).
    public let displacementX: Double
    /// Signed displacement along geodesic Y (metres).
    public let displacementY: Double
    /// Coincidence indicator: 0 = transverse, +1 = parallel, −1 = antiparallel.
    public let coincidence: Int
}
```

For `segment`, which additionally returns a mode indicator:

```swift
public struct SegmentIntersection {
    /// The intersection point.
    public let point: IntersectionPoint
    /// Zero if the segments actually intersect. Non-zero encodes which
    /// side of each segment the closest intersection lies on.
    public let segmentMode: Int
}
```

The `offset` parameter (called `p0` in C++) could be a labelled tuple
`(x: Double, y: Double)` with a default of `(0, 0)`.

### Proposed public methods

```swift
public struct Intersect {
    public init(geodesic: Geodesic)

    // MARK: - Closest intersection

    public func closest(
        latitudeX: Double, longitudeX: Double, azimuthX: Double,
        latitudeY: Double, longitudeY: Double, azimuthY: Double,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> IntersectionPoint

    public func closest(
        lineX: GeodesicLine, lineY: GeodesicLine,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> IntersectionPoint

    // MARK: - Segment intersection

    public func segment(
        latitudeX1: Double, longitudeX1: Double,
        latitudeX2: Double, longitudeX2: Double,
        latitudeY1: Double, longitudeY1: Double,
        latitudeY2: Double, longitudeY2: Double
    ) -> SegmentIntersection

    public func segment(
        lineX: GeodesicLine, lineY: GeodesicLine
    ) -> SegmentIntersection

    // MARK: - Next closest intersection

    public func next(
        latitude: Double, longitude: Double,
        azimuthX: Double, azimuthY: Double
    ) -> IntersectionPoint

    public func next(
        lineX: GeodesicLine, lineY: GeodesicLine
    ) -> IntersectionPoint

    // MARK: - All intersections within distance

    public func all(
        latitudeX: Double, longitudeX: Double, azimuthX: Double,
        latitudeY: Double, longitudeY: Double, azimuthY: Double,
        maxDistance: Double,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> [IntersectionPoint]

    public func all(
        lineX: GeodesicLine, lineY: GeodesicLine,
        maxDistance: Double,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> [IntersectionPoint]
}
```

### Open questions

**1. The `IntersectInternal` module split — is it needed?**

For TransverseMercator, the split served the static/dynamic dispatch pattern.
Here there is no analogous reason. The `@testable import Intersect` gives test
access to internal members. Keeping a separate module adds complexity for no
apparent benefit. Recommendation: collapse `IntersectInternal` into `Intersect`
and use `internal` access for anything tests need to poke at.

**2. Diagnostic counters (`cnt0`–`cnt4`).**

In C++ these are `mutable` fields on `const` methods — a pattern with no direct
Swift equivalent. A Swift struct method that modifies `var` properties must be
`mutating`, which is awkward for methods that are logically queries. Options:

- (a) Drop the counters entirely (simplest; add later if needed).
- (b) Store them in a reference-type wrapper (`class Counters`) held as a `let`
  property, so the struct methods remain non-mutating.
- (c) Make `Intersect` a class instead of a struct.

Recommendation: (a) for now. The counters are diagnostic, not part of the
algorithmic contract.

**3. `Geodesic.c2` is internal.**

The constructor needs `rR = sqrt(c2)` (authalic radius). Currently `c2` is an
internal property on `Geodesic`. We need to either:

- (a) Add a `public var ellipsoidArea: Double { 4 * .pi * c2 }` property on
  `Geodesic` (mirrors the C++ `EllipsoidArea()`).
- (b) Add a `public var authalicRadius: Double { sqrt(c2) }`.
- (c) Compute `c2` independently from `a` and `f` inside `Intersect`.

Recommendation: (a) — it's a natural property of the ellipsoid and matches the
C++ API.

**4. The `offset` parameter type.**

Options: labelled tuple `(x: Double, y: Double)`, a lightweight
`Displacement` struct, or reuse `IntersectionPoint` (but it carries an
irrelevant `coincidence` field). A tuple is lightweight and idiomatic for a
defaulted parameter. A struct is more discoverable in documentation.

---

*(David Hart)*

Go with recommendations. GeographicLib was installed on system using homebrew so
we may be able to use that to build against for any helper c++ programs that
might be needed. I don't yet understand what IntersectPoint tells me so just go
with the raw representation for now until I know what I want to do with it.

*(Claude Opus 4.6)*

### Agreed decisions

1. **Collapse `IntersectInternal` into `Intersect`.** One module, `internal`
   access for test-visible helpers via `@testable import`.
2. **Drop diagnostic counters** for now.
3. **Add `public var ellipsoidArea: Double` to `Geodesic`** (= `4 * .pi * c2`).
4. **Raw result types.** Keep it minimal until the domain meaning is clearer:

```swift
/// Displacement along two geodesics at an intersection.
public struct Point {
    public let x: Double  // signed displacement along geodesic X (metres)
    public let y: Double  // signed displacement along geodesic Y (metres)
    public let c: Int     // coincidence: 0 = transverse, +1 = parallel, −1 = anti
}
```

`Point` mirrors the C++ `Intersect::Point` (a pair) plus the coincidence
indicator bundled in. Methods return `Point` directly; `segment` returns
`(point: Point, segmentMode: Int)` as a tuple. `offset` parameters use
`(x: Double, y: Double)` tuples defaulting to `(0, 0)`. All of this can be
renamed or wrapped later once you know what you want the consumer API to look
like.

### Porting strategy

The C++ `Intersect` has a clear layered structure. From bottom up:

| Layer | C++ function(s) | Purpose |
|---|---|---|
| 0 | Constructor | Compute ellipsoid-derived constants (`rR`, `d`, tolerance thresholds, tile spacings) |
| 1 | `Spherical` | Solve the spherical intersection triangle — initial approximation |
| 2 | `Basic` | Newton refinement of a spherical approximation to the ellipsoidal answer |
| 3 | `ClosestInt`, `NextInt`, `SegmentInt`, `AllInt0` | Tiled search strategies that call `Basic` on candidate offsets |
| 4 | `Closest`, `Segment`, `Next`, `All` | Public wrappers — build `GeodesicLine`s, delegate to layer 3 |
| Helper | `ConjugateDist`, `polarb`, `conjdist`, `distoblique`, `distpolar` | Conjugate/semi-conjugate point geometry, used in constructor and `AllInt0` |
| Helper | `fixcoincident`, `fixsegment`, `segmentmode` | Post-processing adjustments for coincident lines and segment bounds |

**Recommended porting order:**

1. **Constructor (layer 0) + helpers.** Port `_computeIntersectInternals` to
   produce all 15 values. This requires `ConjugateDist`, `polarb`, `conjdist`,
   `distoblique`, `distpolar` — the conjugate-point geometry. These are
   self-contained and testable against the C++ via `IntersectTool` (Homebrew) or
   a small C++ program linked against `-lGeographic`.

2. **`Spherical` + `Basic` (layers 1–2).** The core algorithm. `Spherical`
   calls `Geodesic.inverse` to solve a spherical triangle. `Basic` iterates
   Newton's method using `GeodesicLine.position` with reduced length and
   geodesic scale outputs. These need the `GeodesicLine` enhancements from the
   Geodesic module to return `m12`, `M12`, `M21` — verify those are already
   available.

3. **`ClosestInt` + `NextInt` (layer 3, partial).** Grid search over candidate
   tiles. Once `Basic` works, these are structurally straightforward loops.

4. **Public wrappers (layer 4, `Closest` + `Next`).** Thin wrappers that build
   lines and call layer 3.

5. **`SegmentInt` + `AllInt0` + remaining wrappers.** `SegmentInt` has corner-
   checking logic. `AllInt0` uses `std::set<XPoint, SetComp>` for deduplication
   — in Swift, a sorted array with a custom equality threshold, or a wrapper
   conforming to `Hashable` with snapped coordinates.

**Testing strategy:** Reference values from `IntersectTool` (installed with
GeographicLib via Homebrew — `man IntersectTool`). For internal values
(`Spherical`, `Basic`, conjugate distances), a small C++ program linked against
`-lGeographic` that prints intermediate results, same approach used for
`Geocentric` in the MagneticModel port.

### Prerequisites check

- [ ] `Geodesic` exposes `ellipsoidArea` — **needs adding** (`c2` is internal)
- [x] `GeodesicLine.genPosition` returns `m12`, `M12`, `M21` — **already
  available** via `reducedLength`, `geodesicScale12`, `geodesicScale21` on
  `GeodesicPosition`
- [x] `IntersectTool` is installed — **GeographicLib 2.7** at
  `/opt/homebrew/bin/IntersectTool`

