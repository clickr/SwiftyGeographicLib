// tm_gen.cpp — Generate TransverseMercator forward/reverse reference values
//
// Build (macOS Apple Silicon with Homebrew):
//   c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
//       -lGeographicLib tm_gen.cpp -o tm_gen
//
// For other platforms see: Tests/ReferenceGenerators-SETUP.md
//
// Usage:
//   ./tm_gen A F K0 LON0 LAT LON
//
// Arguments:
//   A    — equatorial radius (e.g. 6378137.0 for WGS84)
//   F    — flattening (e.g. 0.0033528106647474805 for WGS84, i.e. 1/298.257223563)
//   K0   — central scale factor (e.g. 0.9996 for UTM)
//   LON0 — central meridian in degrees
//   LAT  — latitude in degrees
//   LON  — longitude in degrees
//
// Output:
//   Forward and reverse results in key=value format with %.17e precision.

#include <GeographicLib/TransverseMercator.hpp>
#include <cstdio>
#include <cstdlib>

int main(int argc, char* argv[]) {
    if (argc != 7) {
        fprintf(stderr, "Usage: %s A F K0 LON0 LAT LON\n", argv[0]);
        return 1;
    }

    double a    = atof(argv[1]);
    double f    = atof(argv[2]);
    double k0   = atof(argv[3]);
    double lon0 = atof(argv[4]);
    double lat  = atof(argv[5]);
    double lon  = atof(argv[6]);

    GeographicLib::TransverseMercator tm(a, f, k0);

    double x, y, gamma, k;
    tm.Forward(lon0, lat, lon, x, y, gamma, k);
    printf("x=%.17e\n", x);
    printf("y=%.17e\n", y);
    printf("gamma=%.17e\n", gamma);
    printf("k=%.17e\n", k);

    double rlat, rlon;
    tm.Reverse(lon0, x, y, rlat, rlon, gamma, k);
    printf("rlat=%.17e\n", rlat);
    printf("rlon=%.17e\n", rlon);

    return 0;
}
