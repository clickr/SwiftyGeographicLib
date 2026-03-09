#!/usr/bin/env bash
# generate-test-cases.sh — Generate Swift test cases from user coordinates
#
# Uses GeographicLib CLI tools (GeoConvert, IntersectTool, MagneticField) and
# a small C++ helper (geocentric_gen) to produce correctly formatted Swift
# testing code.
#
# Usage:
#   ./generate-test-cases.sh [--file] [--name SUFFIX] SUBCOMMAND ARGS...
#
# Subcommands:
#   tm    [--a A] [--f 1/F] [--k0 K0] [--lon0 LON0] LAT LON
#                                     TransverseMercator forward/reverse
#                                     Without flags: UTM (WGS84, k0=0.9996, auto zone)
#                                     With flags: custom ellipsoid/scale/meridian
#                                     --f takes inverse flattening (e.g. 298.26)
#   ps    LAT LON                     PolarStereographic forward/reverse
#   ups   LAT LON                     UPS forward/reverse
#   intersect closest  LATX LONX AZX LATY LONY AZY
#   intersect next     LAT LON AZX AZY
#   intersect segment  LATX1 LONX1 LATX2 LONX2 LATY1 LONY1 LATY2 LONY2
#   mag   TIME LAT LON HEIGHT         MagneticModel field + rates
#   geo   LAT LON HEIGHT              Geocentric forward
#
# Options:
#   --file          Write a standalone Swift test file instead of printing to stdout.
#                   Output goes to Tests/<Module>Tests/Generated_<name>.swift.
#                   Refuses to overwrite existing files.
#   --name SUFFIX   Suffix for the test function name (default: "userCase")
#
# Examples:
#   ./generate-test-cases.sh tm 47.6 -122.3
#   ./generate-test-cases.sh tm --k0 1.0 --lon0 -75 47.6 -75.5
#   ./generate-test-cases.sh --name seattle mag 2025.0 47.6 -122.3 0
#   ./generate-test-cases.sh --file --name kunlun ups -80.4174 77.1166

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() { echo "error: $*" >&2; exit 1; }

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "'$1' not found. Install GeographicLib CLI tools."
}

# Parse a UTM/UPS line like "50s 402314.322464520 6465770.872261507"
# or "n 2432099.770743945 1567900.229256055"
parse_geoconvert() {
    local line="$1"
    echo "$line"
}

# ---------------------------------------------------------------------------
# Option parsing
# ---------------------------------------------------------------------------

FILE_MODE=false
NAME_SUFFIX="userCase"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file)  FILE_MODE=true; shift ;;
        --name)  NAME_SUFFIX="$2"; shift 2 ;;
        --help|-h)
            sed -n '2,/^$/s/^# //p' "$0"
            exit 0
            ;;
        --*)     die "Unknown option: $1" ;;
        *)       break ;;
    esac
done

[[ $# -ge 1 ]] || die "No subcommand specified. Use --help for usage."

SUBCOMMAND="$1"; shift

# ---------------------------------------------------------------------------
# File output helpers
# ---------------------------------------------------------------------------

write_output() {
    local module_dir="$1"
    local content="$2"

    if [[ "$FILE_MODE" == true ]]; then
        local outpath="$TESTS_DIR/${module_dir}/Generated_${NAME_SUFFIX}.swift"
        if [[ -e "$outpath" ]]; then
            die "File already exists: $outpath — refusing to overwrite"
        fi
        mkdir -p "$(dirname "$outpath")"
        echo "$content" > "$outpath"
        echo "Wrote $outpath"
    else
        echo "$content"
    fi
}

# ---------------------------------------------------------------------------
# Build C++ helpers on demand
# ---------------------------------------------------------------------------

build_cpp_helper() {
    local name="$1"
    local needs_private="${2:-false}"
    local bin="$SCRIPT_DIR/$name"

    if [[ -x "$bin" ]]; then
        return 0
    fi

    echo "Building $name..." >&2

    local inc_flag="" lib_flag=""
    if [[ -d /opt/homebrew/include/GeographicLib ]]; then
        inc_flag="-I/opt/homebrew/include"
        lib_flag="-L/opt/homebrew/lib"
    elif [[ -d /usr/local/include/GeographicLib ]]; then
        inc_flag="-I/usr/local/include"
        lib_flag="-L/usr/local/lib"
    fi

    local private_flag=""
    [[ "$needs_private" == true ]] && private_flag="-Dprivate=public"

    c++ -std=c++20 $inc_flag $lib_flag \
        -lGeographicLib $private_flag \
        "$SCRIPT_DIR/${name}.cpp" -o "$bin" \
        || die "Failed to build $name. See Tests/ReferenceGenerators-SETUP.md"
}

# ---------------------------------------------------------------------------
# tm — TransverseMercator forward/reverse
# ---------------------------------------------------------------------------

cmd_tm() {
    # Parse tm-specific options
    local tm_a="" tm_f="" tm_k0="" tm_lon0=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --a)    tm_a="$2";    shift 2 ;;
            --f)    tm_f="$2";    shift 2 ;;
            --k0)   tm_k0="$2";   shift 2 ;;
            --lon0) tm_lon0="$2"; shift 2 ;;
            --)     shift; break ;;
            --*)    die "Unknown tm option: $1" ;;
            *)      break ;;
        esac
    done

    [[ $# -eq 2 ]] || die "Usage: tm [--a A] [--f F] [--k0 K0] [--lon0 LON0] LAT LON"

    local lat="$1" lon="$2"

    # If any custom parameter is set, use tm_gen; otherwise use GeoConvert (UTM)
    if [[ -n "$tm_a" || -n "$tm_f" || -n "$tm_k0" || -n "$tm_lon0" ]]; then
        cmd_tm_custom "$lat" "$lon" "$tm_a" "$tm_f" "$tm_k0" "$tm_lon0"
    else
        cmd_tm_utm "$lat" "$lon"
    fi
}

cmd_tm_utm() {
    require_cmd GeoConvert

    local lat="$1" lon="$2"

    # Get UTM coordinates
    local utm_line
    utm_line=$(echo "$lat $lon" | GeoConvert -u -s -p 9)
    # Parse: "50s 402314.322464520 6465770.872261507"
    local zone_hemi easting northing
    read -r zone_hemi easting northing <<< "$utm_line"

    # Extract zone number and hemisphere
    local zone="${zone_hemi%[ns]}"
    local hemi="${zone_hemi: -1}"

    # Get convergence and scale
    local conv_line
    conv_line=$(echo "$lat $lon" | GeoConvert -u -s -p 9 -c)
    local convergence scale
    read -r convergence scale <<< "$conv_line"

    # Determine if southern hemisphere
    local is_south=false
    [[ "$hemi" == "s" ]] && is_south=true

    local swift=""
    swift+="// Reference: echo $lat $lon | GeoConvert -u -s -p 9"$'\n'
    swift+="// $utm_line"$'\n'
    swift+="// Convergence and scale: $convergence $scale"$'\n'

    if [[ "$FILE_MODE" == true ]]; then
        swift+=$'\n'"import Testing"$'\n'
        swift+="@testable import TransverseMercator"$'\n'
        swift+="import Math"$'\n'
        swift+="import Numerics"$'\n'
        swift+="import CoreLocation"$'\n'
        swift+=$'\n'"// utmFalseEasting and utmNorthShift are declared in TransverseMercatorTests.swift"$'\n'
    fi

    swift+=$'\n'"@Test func testTransverseMercatorForward_${NAME_SUFFIX}() {"$'\n'
    swift+="    let lon0 = centralMeridian(zone: $zone)"$'\n'
    swift+="    let forward = TransverseMercator.UTM.forward(centralMeridian: lon0, latitude: $lat, longitude: $lon)"$'\n'
    swift+="    #expect((forward.x + utmFalseEasting).isApproximatelyEqual(to: $easting, absoluteTolerance: 1e-9))"$'\n'

    if [[ "$is_south" == true ]]; then
        swift+="    #expect((forward.y + utmNorthShift).isApproximatelyEqual(to: $northing, absoluteTolerance: 1e-9))"$'\n'
    else
        swift+="    #expect(forward.y.isApproximatelyEqual(to: $northing, absoluteTolerance: 1e-9))"$'\n'
    fi

    swift+="    #expect(forward.convergence.isApproximatelyEqual(to: $convergence, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(forward.centralScale.isApproximatelyEqual(to: $scale, absoluteTolerance: 1e-9))"$'\n'
    swift+="}"$'\n'

    swift+=$'\n'"@Test func testTransverseMercatorReverse_${NAME_SUFFIX}() {"$'\n'
    swift+="    let lon0 = centralMeridian(zone: $zone)"$'\n'

    if [[ "$is_south" == true ]]; then
        swift+="    let reverse = TransverseMercator.UTM.reverse(centralMeridian: lon0, x: $easting - utmFalseEasting, y: $northing - utmNorthShift)"$'\n'
    else
        swift+="    let reverse = TransverseMercator.UTM.reverse(centralMeridian: lon0, x: $easting - utmFalseEasting, y: $northing)"$'\n'
    fi

    swift+="    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: $lat, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: $lon, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(reverse.convergence.isApproximatelyEqual(to: $convergence, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(reverse.centralScale.isApproximatelyEqual(to: $scale, absoluteTolerance: 1e-9))"$'\n'
    swift+="}"$'\n'

    write_output "TransverseMercatorTests" "$swift"
}

cmd_tm_custom() {
    local lat="$1" lon="$2"
    local tm_a="${3}" tm_f="${4}" tm_k0="${5}" tm_lon0="${6}"

    # Default to WGS84 values if not provided.
    # --f accepts inverse flattening (e.g. 298.257223563) and converts to
    # actual flattening for tm_gen.
    [[ -z "$tm_a" ]]    && tm_a="6378137.0"
    if [[ -z "$tm_f" ]]; then
        tm_f="$(awk 'BEGIN { printf "%.17e", 1.0/298.257223563 }')"
    else
        tm_f="$(awk "BEGIN { printf \"%.17e\", 1.0/$tm_f }")"
    fi
    [[ -z "$tm_k0" ]]   && tm_k0="0.9996"
    [[ -z "$tm_lon0" ]] && tm_lon0="0"

    build_cpp_helper "tm_gen"

    local output
    output=$("$SCRIPT_DIR/tm_gen" "$tm_a" "$tm_f" "$tm_k0" "$tm_lon0" "$lat" "$lon")

    # Parse key=value lines
    local x y gamma k rlat rlon
    eval "$(echo "$output" | sed 's/^/local /')"

    local swift=""
    swift+="// Reference: tm_gen $tm_a $tm_f $tm_k0 $tm_lon0 $lat $lon"$'\n'
    swift+="// x=$x y=$y gamma=$gamma k=$k"$'\n'

    if [[ "$FILE_MODE" == true ]]; then
        swift+=$'\n'"import Testing"$'\n'
        swift+="@testable import TransverseMercator"$'\n'
        swift+="import Numerics"$'\n'
    fi

    swift+=$'\n'"@Test func testTransverseMercatorCustomForward_${NAME_SUFFIX}() throws {"$'\n'
    swift+="    let tm = try TransverseMercator("$'\n'
    swift+="        equatorialRadius: $tm_a,"$'\n'
    swift+="        flattening: $tm_f,"$'\n'
    swift+="        scaleFactor: $tm_k0)"$'\n'
    swift+="    let forward = tm.forward(centralMeridian: $tm_lon0, latitude: $lat, longitude: $lon)"$'\n'
    swift+="    #expect(forward.x.isApproximatelyEqual(to: $x, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(forward.y.isApproximatelyEqual(to: $y, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(forward.convergence.isApproximatelyEqual(to: $gamma, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(forward.centralScale.isApproximatelyEqual(to: $k, absoluteTolerance: 1e-9))"$'\n'
    swift+="}"$'\n'

    swift+=$'\n'"@Test func testTransverseMercatorCustomReverse_${NAME_SUFFIX}() throws {"$'\n'
    swift+="    let tm = try TransverseMercator("$'\n'
    swift+="        equatorialRadius: $tm_a,"$'\n'
    swift+="        flattening: $tm_f,"$'\n'
    swift+="        scaleFactor: $tm_k0)"$'\n'
    swift+="    let reverse = tm.reverse(centralMeridian: $tm_lon0, x: $x, y: $y)"$'\n'
    swift+="    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: $lat, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: $lon, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(reverse.convergence.isApproximatelyEqual(to: $gamma, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(reverse.centralScale.isApproximatelyEqual(to: $k, absoluteTolerance: 1e-9))"$'\n'
    swift+="}"$'\n'

    write_output "TransverseMercatorTests" "$swift"
}

# ---------------------------------------------------------------------------
# ps — PolarStereographic forward/reverse
# ---------------------------------------------------------------------------

cmd_ps() {
    [[ $# -eq 2 ]] || die "Usage: ps LAT LON"
    require_cmd GeoConvert

    local lat="$1" lon="$2"

    # Get UPS coordinates via GeoConvert
    local ups_line
    ups_line=$(echo "$lat $lon" | GeoConvert -u -p 9)
    local hemi easting northing
    read -r hemi easting northing <<< "$ups_line"

    # Get convergence and scale
    local conv_line
    conv_line=$(echo "$lat $lon" | GeoConvert -u -p 9 -c)
    local convergence scale
    read -r convergence scale <<< "$conv_line"

    local northp="false"
    [[ "$hemi" == "n" ]] && northp="true"

    # PolarStereographic uses coordinates relative to pole (no false easting/northing)
    # UPS adds 2,000,000 false easting/northing
    # PS x = UPS easting - 2e6, PS y = UPS northing - 2e6

    local swift=""
    swift+="// Reference: echo $lat $lon | GeoConvert -u -p 9"$'\n'
    swift+="// $ups_line"$'\n'
    swift+="// Convergence and scale: $convergence $scale"$'\n'

    if [[ "$FILE_MODE" == true ]]; then
        swift+=$'\n'"import Testing"$'\n'
        swift+="@testable import PolarStereographic"$'\n'
        swift+="import CoreLocation"$'\n'
        swift+="import Numerics"$'\n'
    fi

    swift+=$'\n'"@Test func testPolarStereographicForward_${NAME_SUFFIX}() {"$'\n'
    swift+="    let coord: CLLocationCoordinate2D = .init(latitude: $lat, longitude: $lon)"$'\n'
    swift+="    let forward = PolarStereographic.UPS.forward(coordinate: coord)"$'\n'
    swift+="    #expect(forward.northp == $northp)"$'\n'
    swift+="    #expect((forward.x + 20e5).isApproximatelyEqual(to: $easting, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect((forward.y + 20e5).isApproximatelyEqual(to: $northing, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(forward.convergence.isApproximatelyEqual(to: $convergence, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(forward.centralScale.isApproximatelyEqual(to: $scale, absoluteTolerance: 1e-9))"$'\n'
    swift+="}"$'\n'

    swift+=$'\n'"@Test func testPolarStereographicReverse_${NAME_SUFFIX}() {"$'\n'
    swift+="    let x = $easting - 20e5"$'\n'
    swift+="    let y = $northing - 20e5"$'\n'
    swift+="    let reverse = PolarStereographic.UPS.reverse(northp: $northp, x: x, y: y)"$'\n'
    swift+="    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: $lat, absoluteTolerance: 1e-6))"$'\n'
    swift+="    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: $lon, absoluteTolerance: 1e-6))"$'\n'
    swift+="}"$'\n'

    write_output "PolarStereographicTests" "$swift"
}

# ---------------------------------------------------------------------------
# ups — UPS forward/reverse
# ---------------------------------------------------------------------------

cmd_ups() {
    [[ $# -eq 2 ]] || die "Usage: ups LAT LON"
    require_cmd GeoConvert

    local lat="$1" lon="$2"

    # Get UPS coordinates
    local ups_line
    ups_line=$(echo "$lat $lon" | GeoConvert -u -p 9)
    local hemi easting northing
    read -r hemi easting northing <<< "$ups_line"

    # Get convergence and scale
    local conv_line
    conv_line=$(echo "$lat $lon" | GeoConvert -u -p 9 -c)
    local convergence scale
    read -r convergence scale <<< "$conv_line"

    local hemisphere=".northern"
    [[ "$hemi" == "s" ]] && hemisphere=".southern"

    local swift=""
    swift+="// Reference: echo $lat $lon | GeoConvert -u -p 9"$'\n'
    swift+="// $ups_line"$'\n'
    swift+="// Convergence and scale: $convergence $scale"$'\n'

    if [[ "$FILE_MODE" == true ]]; then
        swift+=$'\n'"import Testing"$'\n'
        swift+="@testable import UPS"$'\n'
        swift+="import Numerics"$'\n'
        swift+="import CoreLocation"$'\n'
    fi

    swift+=$'\n'"@Test func testUPSForward_${NAME_SUFFIX}() throws {"$'\n'
    swift+="    let ups = try UPS(latitude: $lat, longitude: $lon)"$'\n'
    swift+="    #expect(ups.hemisphere == $hemisphere)"$'\n'
    swift+="    #expect(ups.easting.isApproximatelyEqual(to: $easting, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(ups.northing.isApproximatelyEqual(to: $northing, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(ups.convergence.isApproximatelyEqual(to: $convergence, absoluteTolerance: 1e-9))"$'\n'
    swift+="    #expect(ups.centralScale.isApproximatelyEqual(to: $scale, absoluteTolerance: 1e-9))"$'\n'
    swift+="}"$'\n'

    swift+=$'\n'"@Test func testUPSReverse_${NAME_SUFFIX}() throws {"$'\n'
    swift+="    let ups = try UPS(hemisphere: $hemisphere, easting: $easting, northing: $northing)"$'\n'
    swift+="    #expect(ups.geodeticCoordinate.latitude.isApproximatelyEqual(to: $lat, absoluteTolerance: 1e-6))"$'\n'
    swift+="    #expect(ups.geodeticCoordinate.longitude.isApproximatelyEqual(to: $lon, absoluteTolerance: 1e-6))"$'\n'
    swift+="}"$'\n'

    write_output "UPSTests" "$swift"
}

# ---------------------------------------------------------------------------
# intersect — Intersect closest/next/segment
# ---------------------------------------------------------------------------

cmd_intersect() {
    [[ $# -ge 1 ]] || die "Usage: intersect {closest|next|segment} ARGS..."
    require_cmd IntersectTool

    local mode="$1"; shift

    case "$mode" in
        closest)
            [[ $# -eq 6 ]] || die "Usage: intersect closest LATX LONX AZX LATY LONY AZY"
            local latX="$1" lonX="$2" azX="$3" latY="$4" lonY="$5" azY="$6"

            local result
            result=$(echo "$latX $lonX $azX $latY $lonY $azY" | IntersectTool -c -p 17)
            local px py pc
            read -r px py pc <<< "$result"

            local swift=""
            swift+="// Reference: echo \"$latX $lonX $azX $latY $lonY $azY\" | IntersectTool -c -p 17"$'\n'
            swift+="// => $result"$'\n'

            if [[ "$FILE_MODE" == true ]]; then
                swift+=$'\n'"import Testing"$'\n'
                swift+="import Numerics"$'\n'
                swift+="@testable import Intersect"$'\n'
                swift+="import Geodesic"$'\n'
            fi

            swift+=$'\n'"@Test func testIntersectClosest_${NAME_SUFFIX}() {"$'\n'
            swift+="    let inter = Intersect(geodesic: .wgs84)"$'\n'
            swift+="    let p = inter.closest("$'\n'
            swift+="        latitudeX: $latX, longitudeX: $lonX, azimuthX: $azX,"$'\n'
            swift+="        latitudeY: $latY, longitudeY: $lonY, azimuthY: $azY)"$'\n'
            swift+="    #expect(p.x.isApproximatelyEqual(to: $px, absoluteTolerance: 0.01))"$'\n'
            swift+="    #expect(p.y.isApproximatelyEqual(to: $py, absoluteTolerance: 0.01))"$'\n'
            swift+="    #expect(p.c == $pc)"$'\n'
            swift+="}"$'\n'

            write_output "IntersectTests" "$swift"
            ;;

        next)
            [[ $# -eq 4 ]] || die "Usage: intersect next LAT LON AZX AZY"
            local lat="$1" lon="$2" azX="$3" azY="$4"

            local result
            result=$(echo "$lat $lon $azX $azY" | IntersectTool -n -p 17)
            local px py pc
            read -r px py pc <<< "$result"

            local swift=""
            swift+="// Reference: echo \"$lat $lon $azX $azY\" | IntersectTool -n -p 17"$'\n'
            swift+="// => $result"$'\n'

            if [[ "$FILE_MODE" == true ]]; then
                swift+=$'\n'"import Testing"$'\n'
                swift+="import Numerics"$'\n'
                swift+="@testable import Intersect"$'\n'
                swift+="import Geodesic"$'\n'
            fi

            swift+=$'\n'"@Test func testIntersectNext_${NAME_SUFFIX}() {"$'\n'
            swift+="    let inter = Intersect(geodesic: .wgs84)"$'\n'
            swift+="    let p = inter.next("$'\n'
            swift+="        latitude: $lat, longitude: $lon,"$'\n'
            swift+="        azimuthX: $azX, azimuthY: $azY)"$'\n'
            swift+="    #expect(p.x.isApproximatelyEqual(to: $px, absoluteTolerance: 0.1))"$'\n'
            swift+="    #expect(p.y.isApproximatelyEqual(to: $py, absoluteTolerance: 0.1))"$'\n'
            swift+="    #expect(p.c == $pc)"$'\n'
            swift+="}"$'\n'

            write_output "IntersectTests" "$swift"
            ;;

        segment)
            [[ $# -eq 8 ]] || die "Usage: intersect segment LATX1 LONX1 LATX2 LONX2 LATY1 LONY1 LATY2 LONY2"
            local lx1="$1" lo1="$2" lx2="$3" lo2="$4"
            local ly1="$5" lo3="$6" ly2="$7" lo4="$8"

            local result
            result=$(echo "$lx1 $lo1 $lx2 $lo2 $ly1 $lo3 $ly2 $lo4" | IntersectTool -i -p 17)
            local px py pc psm
            read -r px py pc psm <<< "$result"

            local swift=""
            swift+="// Reference: echo \"$lx1 $lo1 $lx2 $lo2 $ly1 $lo3 $ly2 $lo4\" | IntersectTool -i -p 17"$'\n'
            swift+="// => $result"$'\n'

            if [[ "$FILE_MODE" == true ]]; then
                swift+=$'\n'"import Testing"$'\n'
                swift+="import Numerics"$'\n'
                swift+="@testable import Intersect"$'\n'
                swift+="import Geodesic"$'\n'
            fi

            swift+=$'\n'"@Test func testIntersectSegment_${NAME_SUFFIX}() {"$'\n'
            swift+="    let inter = Intersect(geodesic: .wgs84)"$'\n'
            swift+="    let r = inter.segment("$'\n'
            swift+="        latitudeX1: $lx1, longitudeX1: $lo1,"$'\n'
            swift+="        latitudeX2: $lx2, longitudeX2: $lo2,"$'\n'
            swift+="        latitudeY1: $ly1, longitudeY1: $lo3,"$'\n'
            swift+="        latitudeY2: $ly2, longitudeY2: $lo4)"$'\n'
            swift+="    #expect(r.point.x.isApproximatelyEqual(to: $px, absoluteTolerance: 0.01))"$'\n'
            swift+="    #expect(r.point.y.isApproximatelyEqual(to: $py, absoluteTolerance: 0.01))"$'\n'
            swift+="    #expect(r.point.c == $pc)"$'\n'
            swift+="    #expect(r.segmentMode == $psm)"$'\n'
            swift+="}"$'\n'

            write_output "IntersectTests" "$swift"
            ;;

        *)
            die "Unknown intersect mode: $mode. Use closest, next, or segment."
            ;;
    esac
}

# ---------------------------------------------------------------------------
# mag — MagneticModel field + rates
# ---------------------------------------------------------------------------

cmd_mag() {
    [[ $# -eq 4 ]] || die "Usage: mag TIME LAT LON HEIGHT"
    require_cmd MagneticField

    local time="$1" lat="$2" lon="$3" height="$4"

    # MagneticField -r outputs two lines:
    # Line 1: D I H north east down F
    # Line 2: Ddt Idt Hdt northDt eastDt downDt Fdt
    local output
    output=$(echo "$lat $lon $height" | MagneticField -n wmm2025 -t "$time" -r -p 15)

    local line1 line2
    line1=$(echo "$output" | head -1)
    line2=$(echo "$output" | tail -1)

    # Parse fields (0-indexed): D(0) I(1) H(2) north(3) east(4) down(5) F(6)
    local fields1=($line1)
    local fields2=($line2)

    # Swift convention: east=field[4], north=field[3], up=-field[5]
    local east="${fields1[4]}"
    local north="${fields1[3]}"
    local down="${fields1[5]}"
    local eastDt="${fields2[4]}"
    local northDt="${fields2[3]}"
    local downDt="${fields2[5]}"

    # Negate down to get up (Swift convention)
    # Use awk for reliable negation
    local up
    up=$(echo "$down" | awk '{ printf "%.15e", -$1 }')
    local upDt
    upDt=$(echo "$downDt" | awk '{ printf "%.15e", -$1 }')

    local swift=""
    swift+="// Reference: echo \"$lat $lon $height\" | MagneticField -n wmm2025 -t $time -r -p 15"$'\n'

    if [[ "$FILE_MODE" == true ]]; then
        swift+=$'\n'"import Testing"$'\n'
        swift+="import Foundation"$'\n'
        swift+="@testable import MagneticModel"$'\n'
        swift+="import Numerics"$'\n'
    fi

    swift+=$'\n'"// Tuple for array-based testing pattern:"$'\n'
    swift+="// (t: $time, lat: $lat, lon: $lon, h: ${height},"$'\n'
    swift+="//  east: $east, north: $north, up: $up,"$'\n'
    swift+="//  eastDeltaT: $eastDt, northDeltaT: $northDt, upDeltaT: $upDt),"$'\n'

    swift+=$'\n'"@Test func testWMM2025Field_${NAME_SUFFIX}() throws {"$'\n'
    swift+="    let model = try MagneticModel(name: \"wmm2025\")"$'\n'
    swift+="    let result = model.fieldWithRates("$'\n'
    swift+="        time: $time, latitude: $lat,"$'\n'
    swift+="        longitude: $lon, height: ${height})"$'\n'
    swift+="    let tol = 1e-6"$'\n'
    swift+="    #expect(result.field.east.isApproximatelyEqual(to: $east, absoluteTolerance: tol))"$'\n'
    swift+="    #expect(result.field.north.isApproximatelyEqual(to: $north, absoluteTolerance: tol))"$'\n'
    swift+="    #expect(result.field.up.isApproximatelyEqual(to: $up, absoluteTolerance: tol))"$'\n'
    swift+="    #expect(result.eastDeltaT.isApproximatelyEqual(to: $eastDt, absoluteTolerance: tol))"$'\n'
    swift+="    #expect(result.northDeltaT.isApproximatelyEqual(to: $northDt, absoluteTolerance: tol))"$'\n'
    swift+="    #expect(result.upDeltaT.isApproximatelyEqual(to: $upDt, absoluteTolerance: tol))"$'\n'
    swift+="}"$'\n'

    write_output "MagneticModelTests" "$swift"
}

# ---------------------------------------------------------------------------
# geo — Geocentric forward
# ---------------------------------------------------------------------------

cmd_geo() {
    [[ $# -eq 3 ]] || die "Usage: geo LAT LON HEIGHT"

    local lat="$1" lon="$2" height="$3"

    build_cpp_helper "geocentric_gen" true

    local output
    output=$("$SCRIPT_DIR/geocentric_gen" "$lat" "$lon" "$height")

    # Parse key=value lines
    local X Y Z M0 M1 M2 M3 M4 M5 M6 M7 M8
    eval "$(echo "$output" | sed 's/^/local /')"

    local swift=""
    swift+="// Reference: geocentric_gen $lat $lon $height"$'\n'

    if [[ "$FILE_MODE" == true ]]; then
        swift+=$'\n'"import Testing"$'\n'
        swift+="@testable import MagneticModel"$'\n'
        swift+="import Numerics"$'\n'
    fi

    swift+=$'\n'"// Tuple for array-based testing pattern:"$'\n'
    swift+="// (lat: $lat, lon: $lon, h: ${height},"$'\n'
    swift+="//  X: $X, Y: $Y, Z: $Z,"$'\n'
    swift+="//  M: [$M0, $M1, $M2,"$'\n'
    swift+="//      $M3, $M4, $M5,"$'\n'
    swift+="//      $M6, $M7, $M8]),"$'\n'

    swift+=$'\n'"@Test func testGeocentricForward_${NAME_SUFFIX}() {"$'\n'
    swift+="    let swiftGeo = Geocentric.wgs84"$'\n'
    swift+="    let result = swiftGeo.intForward(lat: $lat, lon: $lon, h: ${height})"$'\n'
    swift+="    #expect(result.X.isApproximatelyEqual(to: $X, absoluteTolerance: 1e-6))"$'\n'
    swift+="    #expect(result.Y.isApproximatelyEqual(to: $Y, absoluteTolerance: 1e-6))"$'\n'
    swift+="    #expect(result.Z.isApproximatelyEqual(to: $Z, absoluteTolerance: 1e-6))"$'\n'
    swift+="    let refM = [$M0, $M1, $M2,"$'\n'
    swift+="                $M3, $M4, $M5,"$'\n'
    swift+="                $M6, $M7, $M8]"$'\n'
    swift+="    for i in 0..<9 {"$'\n'
    swift+="        #expect(result.M[i].isApproximatelyEqual(to: refM[i], absoluteTolerance: 1e-12))"$'\n'
    swift+="    }"$'\n'
    swift+="}"$'\n'

    write_output "MagneticModelTests" "$swift"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

case "$SUBCOMMAND" in
    tm)         cmd_tm "$@" ;;
    ps)         cmd_ps "$@" ;;
    ups)        cmd_ups "$@" ;;
    intersect)  cmd_intersect "$@" ;;
    mag)        cmd_mag "$@" ;;
    geo)        cmd_geo "$@" ;;
    *)          die "Unknown subcommand: $SUBCOMMAND. Use tm, ps, ups, intersect, mag, or geo." ;;
esac
