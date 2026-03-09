// ups_ref_values.cpp — Generate UTMUPS::Forward/Reverse reference values
//
// Quick start (macOS Apple Silicon with Homebrew):
//   brew install geographiclib
//   c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
//       -lGeographicLib ups_ref_values.cpp -o ups_ref_values
//   ./ups_ref_values
//
// For other platforms (Intel Mac, Linux, build from source) see:
//   Tests/ReferenceGenerators-SETUP.md

#include <GeographicLib/UTMUPS.hpp>
#include <cstdio>

int main() {
    int zone;
    bool northp;
    double x, y, gamma, k;

    printf("=== UTMUPS::Forward — Northern Hemisphere ===\n\n");
    GeographicLib::UTMUPS::Forward(84.5, 45.0, zone, northp, x, y, gamma, k);
    printf("zone   = %d\n", zone);
    printf("northp = %s\n", northp ? "true" : "false");
    printf("x      = %.17e\n", x);
    printf("y      = %.17e\n", y);
    printf("gamma  = %.17e\n", gamma);
    printf("k      = %.17e\n", k);

    printf("\n=== UTMUPS::Forward — Southern Hemisphere ===\n\n");
    GeographicLib::UTMUPS::Forward(-80.4174, 77.1166, zone, northp, x, y, gamma, k);
    printf("zone   = %d\n", zone);
    printf("northp = %s\n", northp ? "true" : "false");
    printf("x      = %.17e\n", x);
    printf("y      = %.17e\n", y);
    printf("gamma  = %.17e\n", gamma);
    printf("k      = %.17e\n", k);

    printf("\n=== UTMUPS::Reverse — Southern Hemisphere ===\n\n");
    double lat, lon;
    GeographicLib::UTMUPS::Reverse(0, false, 3039440.641302266, 2237746.759453198,
                                    lat, lon, gamma, k);
    printf("lat    = %.17e\n", lat);
    printf("lon    = %.17e\n", lon);

    printf("\n=== UTMUPS::Reverse — Northern Hemisphere ===\n\n");
    GeographicLib::UTMUPS::Reverse(0, true, 2649639.515832669, 1850018.900096025,
                                    lat, lon, gamma, k);
    printf("lat    = %.17e\n", lat);
    printf("lon    = %.17e\n", lon);

    return 0;
}
