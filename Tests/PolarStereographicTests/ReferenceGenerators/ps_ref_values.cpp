// ps_ref_values.cpp — Generate PolarStereographic::UPS() reference values
//
// Quick start (macOS Apple Silicon with Homebrew):
//   brew install geographiclib
//   c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
//       -lGeographicLib -Dprivate=public ps_ref_values.cpp -o ps_ref_values
//   ./ps_ref_values
//
// For other platforms (Intel Mac, Linux, build from source) see:
//   Tests/ReferenceGenerators-SETUP.md

#include <GeographicLib/PolarStereographic.hpp>
#include <cstdio>

int main() {
    auto& ups = GeographicLib::PolarStereographic::UPS();

    printf("=== PolarStereographic::UPS() internal fields ===\n\n");
    printf("e2  = %.17e\n", ups._e2);
    printf("e2m = %.17e\n", ups._e2m);
    printf("es  = %.17e\n", ups._es);
    printf("c   = %.17e\n", ups._c);

    printf("\n=== Forward(-80.4174, 77.1166) ===\n\n");
    double x, y, gamma, k;
    ups.Forward(false, -80.4174, 77.1166, x, y, gamma, k);
    printf("x           = %.17e\n", x);
    printf("y           = %.17e\n", y);
    printf("convergence = %.17e\n", gamma);
    printf("centralScale= %.17e\n", k);

    printf("\n=== Reverse(false, x, y) ===\n\n");
    double lat, lon;
    ups.Reverse(false, x, y, lat, lon, gamma, k);
    printf("lat         = %.17e\n", lat);
    printf("lon         = %.17e\n", lon);
    printf("convergence = %.17e\n", gamma);
    printf("centralScale= %.17e\n", k);

    return 0;
}
