// geocentric_gen.cpp — Generate Geocentric reference values from CLI arguments
//
// Build (macOS Apple Silicon with Homebrew):
//   c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
//       -lGeographicLib -Dprivate=public geocentric_gen.cpp -o geocentric_gen
//
// For other platforms see: Tests/ReferenceGenerators-SETUP.md
//
// Usage:
//   ./geocentric_gen LAT LON HEIGHT
//
// Output:
//   X, Y, Z coordinates and 9 rotation matrix elements, one per line,
//   in key=value format with %.17e precision.

#include <GeographicLib/Geocentric.hpp>
#include <cstdio>
#include <cstdlib>

int main(int argc, char* argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s LAT LON HEIGHT\n", argv[0]);
        return 1;
    }

    double lat = atof(argv[1]);
    double lon = atof(argv[2]);
    double h   = atof(argv[3]);

    auto& geo = GeographicLib::Geocentric::WGS84();
    double X, Y, Z;
    double M[9];
    geo.IntForward(lat, lon, h, X, Y, Z, M);

    printf("X=%.17e\n", X);
    printf("Y=%.17e\n", Y);
    printf("Z=%.17e\n", Z);
    for (int i = 0; i < 9; i++)
        printf("M%d=%.17e\n", i, M[i]);

    return 0;
}
