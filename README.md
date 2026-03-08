# SwiftyGeographicLib

A pure Swift library for geographic coordinate transformations and geomagnetic
field evaluation, ported from Charles Karney's
[GeographicLib](https://geographiclib.sourceforge.io) C++ library.

No C++ runtime dependency. All arithmetic is native Swift.

## Modules

| Module | Description |
|---|---|
| **Geodesic** | Solve the direct and inverse geodesic problems on an ellipsoid; compute positions along a geodesic line |
| **Intersect** | Find intersections of two geodesics on an ellipsoid |
| **TransverseMercator** | Transverse Mercator projection (configurable ellipsoid); includes `StaticUTM` for lightweight compile-time WGS84 constants |
| **UTM** | Full UTM projection with zone selection and validation |
| **PolarStereographic** | Polar Stereographic projection |
| **UPS** | Universal Polar Stereographic projection |
| **MagneticModel** | Geomagnetic field evaluation (WMM, IGRF, EMM) |

## Installation

Add SwiftyGeographicLib as a Swift Package Manager dependency:

```swift
dependencies: [
    .package(url: "https://github.com/user/SwiftyGeographicLib.git", from: "1.0.0")
]
```

Then add the libraries you need to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "Geodesic", package: "SwiftyGeographicLib"),
        .product(name: "UTM", package: "SwiftyGeographicLib"),
        // add others as needed
    ]
)
```

## Requirements

- Swift 6.2+
- macOS 15+ / iOS 17+

## Usage

### Geodesic

Solve the direct and inverse problems on the WGS84 ellipsoid.

```swift
import Geodesic

let geod = Geodesic.wgs84

// Direct: given a start point, azimuth, and distance, find the destination
let dest = geod.direct(
    latitude: 47.6, longitude: -122.3,
    azimuth: 45.0, distance: 1_000_000)
// dest.latitude, dest.longitude, dest.azimuth

// Inverse: given two points, find the distance and azimuths
let inv = geod.inverse(
    latitude1: 47.6, longitude1: -122.3,
    latitude2: 48.2, longitude2: -121.5)
// inv.distance, inv.azimuth1, inv.azimuth2

// Line: precompute for a route, then sample positions along it
let line = geod.line(latitude: 47.6, longitude: -122.3, azimuth: 45.0)
let waypoint = line.position(distance: 500_000)
// waypoint.latitude, waypoint.longitude, waypoint.azimuth
```

### Intersect

Find where two geodesics cross.

```swift
import Geodesic
import Intersect

let geod = Geodesic.wgs84
let inter = Intersect(geodesic: geod)

// Closest intersection of two geodesics
let p = inter.closest(
    latitudeX: 0, longitudeX: 0, azimuthX: 45,
    latitudeY: 1, longitudeY: 2, azimuthY: 135)
// p.x = displacement along geodesic X (metres)
// p.y = displacement along geodesic Y (metres)
// p.c = coincidence indicator (0 = crossing, +1 = parallel, -1 = antiparallel)

// Segment intersection (do two geodesic segments cross?)
let seg = inter.segment(
    latitudeX1: 0, longitudeX1: -1, latitudeX2: 0, longitudeX2: 1,
    latitudeY1: -1, longitudeY1: 0, latitudeY2: 1, longitudeY2: 0)
// seg.segmentMode == 0 means the segments actually cross
```

On Apple platforms, a CoreLocation convenience API is available:

```swift
import CoreLocation

let lineX = geod.line(latitude: 0, longitude: 0, azimuth: 45)
let lineY = geod.line(latitude: 1, longitude: 2, azimuth: 135)

switch inter.closestIntersection(lineX: lineX, lineY: lineY) {
case .point(let coord):
    print("Intersection at \(coord.latitude), \(coord.longitude)")
case .parallel:
    print("Lines are parallel (coincident, same direction)")
case .antiParallel:
    print("Lines are antiparallel (coincident, opposite directions)")
}
```

### UTM

Convert between latitude/longitude and UTM coordinates.

```swift
import UTM

// Forward: latitude/longitude to UTM
let utm = try UTM(latitude: 47.6, longitude: -122.3)
// utm.zone, utm.hemisphere, utm.easting, utm.northing

// Reverse: UTM to latitude/longitude
let rev = try UTM(hemisphere: .northern, zone: 10, easting: 552_657, northing: 5_272_648)
// rev.latitude, rev.longitude
```

### UPS

Convert between latitude/longitude and UPS coordinates for the polar regions.

```swift
import UPS

let ups = try UPS(latitude: 85.0, longitude: 45.0)
// ups.hemisphere, ups.easting, ups.northing
```

### TransverseMercator

Use the Transverse Mercator projection directly with a configurable ellipsoid.

```swift
import TransverseMercator

let tm = TransverseMercator.UTM  // WGS84, k0 = 0.9996
let fwd = tm.forward(centralMeridian: -123.0, latitude: 47.6, longitude: -122.3)
// fwd.x, fwd.y, fwd.convergence, fwd.centralScale
```

### MagneticModel

Evaluate the geomagnetic field at a given position and time. The WMM2025 model
data is bundled; other models can be loaded from disk.

```swift
import MagneticModel

let model = try MagneticModel(name: "wmm2025")

// Evaluate at a fractional year
let field = model.field(time: 2026.5, latitude: 47.6, longitude: -122.3, height: 0)
let components = MagneticModel.fieldComponents(
    east: field.east, north: field.north, up: field.up)
// components.declination — magnetic declination in degrees
// components.inclination — magnetic inclination in degrees
// components.totalFieldIntensity — total field in nT

// Or use a Date directly
let fieldNow = model.field(date: Date(), latitude: 47.6, longitude: -122.3, height: 0)
```

## Accuracy

The series-based implementations match GeographicLib's stated accuracy:

- **Geodesic**: 15 nm for the WGS84 ellipsoid
- **Transverse Mercator**: 9 nm for points within 3900 km of the central
  meridian
- **Intersect**: validated against `IntersectTool` (GeographicLib 2.7)
- **MagneticModel**: produces identical results to the C++ library for the
  same coefficient files

## Acknowledgements

Based on [GeographicLib](https://geographiclib.sourceforge.io) by Charles
Karney. The algorithms and coefficient tables are described in:

- C. F. F. Karney, *Algorithms for geodesics*, J. Geodesy **87**(1), 43--55
  (2013). [doi:10.1007/s00190-012-0578-z](https://doi.org/10.1007/s00190-012-0578-z)
- C. F. F. Karney, *Transverse Mercator with an accuracy of a few nanometers*,
  J. Geodesy **85**(8), 475--485 (2011).
  [doi:10.1007/s00190-011-0445-3](https://doi.org/10.1007/s00190-011-0445-3)

## License

See [LICENSE](LICENSE) for details.
