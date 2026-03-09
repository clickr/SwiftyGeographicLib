# Test Case Generator

Generates Swift test code from user-provided coordinates using GeographicLib CLI
tools and small C++ helpers for Geocentric and custom TransverseMercator
parameters.

## Prerequisites

- GeographicLib CLI tools: `GeoConvert`, `IntersectTool`, `MagneticField`
  (installed via `brew install geographiclib` or see
  [ReferenceGenerators-SETUP.md](../ReferenceGenerators-SETUP.md))
- For `geo` and `tm` with custom parameters: a C++ compiler and GeographicLib
  headers/library (helper binaries are auto-compiled on first use)

## Usage

```sh
cd Tests/TestGeneration
./generate-test-cases.sh [--file] [--name SUFFIX] SUBCOMMAND ARGS...
```

### Subcommands

| Subcommand | Arguments | Description |
|---|---|---|
| `tm` | `[--a A] [--f 1/F] [--k0 K0] [--lon0 LON0] LAT LON` | TransverseMercator forward/reverse |
| `ps` | `LAT LON` | PolarStereographic forward/reverse |
| `ups` | `LAT LON` | UPS forward/reverse |
| `intersect closest` | `LATX LONX AZX LATY LONY AZY` | Closest geodesic intersection |
| `intersect next` | `LAT LON AZX AZY` | Next intersection from a point |
| `intersect segment` | `LATX1 LONX1 LATX2 LONX2 LATY1 LONY1 LATY2 LONY2` | Segment intersection |
| `mag` | `TIME LAT LON HEIGHT` | MagneticModel field + rates |
| `geo` | `LAT LON HEIGHT` | Geocentric forward |

### Options

- `--file` — Write a standalone Swift test file to the appropriate test
  directory (`Tests/<Module>Tests/Generated_<name>.swift`). Refuses to
  overwrite existing files.
- `--name SUFFIX` — Suffix for the generated test function name
  (default: `userCase`).

### Output modes

**Default** (no `--file`): prints Swift test code to stdout, suitable for
copying into an existing test file.

**File mode** (`--file`): writes a complete Swift test file with imports.
The file is placed in the correct test target directory with a `Generated_`
prefix.

## Examples

Print TransverseMercator test code for Seattle (UTM defaults):

```sh
./generate-test-cases.sh tm 47.6 -122.3
```

Custom TM with WGS 72 ellipsoid and explicit central meridian:

```sh
./generate-test-cases.sh tm --a 6378135.0 --f 298.26 --k0 0.9996 --lon0 -81 28.3922 -80.6077
```

Without `--a`, `--f`, `--k0`, or `--lon0`, the `tm` subcommand uses UTM
(WGS84, k0=0.9996, auto zone via `GeoConvert`). With any custom flag, it
uses a C++ helper (`tm_gen`) and generates tests using
`TransverseMercator(equatorialRadius:flattening:scaleFactor:)` instead of
`TransverseMercator.UTM`.

Generate a named magnetic field test file:

```sh
./generate-test-cases.sh --file --name seattle mag 2025.0 47.6 -122.3 0
```

Print an intersect closest test:

```sh
./generate-test-cases.sh --name equatorCross intersect closest 0 0 45 1 2 135
```

Generate a UPS test file for Kunlun Station:

```sh
./generate-test-cases.sh --file --name kunlun ups -80.4174 77.1166
```

## Safety

- Default mode only prints to stdout; no files are modified.
- `--file` mode refuses to overwrite existing files.
- Generated files use a `Generated_` prefix to distinguish them from
  hand-written tests.

## MagneticField convention note

The `MagneticField` CLI outputs fields in order: `D I H north east down F`.
The script maps these to the Swift convention:
- `east` = field[4] (east from CLI)
- `north` = field[3] (north from CLI)
- `up` = -field[5] (negated down from CLI)
