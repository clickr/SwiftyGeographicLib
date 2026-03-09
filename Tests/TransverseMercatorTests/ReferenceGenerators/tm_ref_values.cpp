// tm_ref_values.cpp — Generate TransverseMercator::UTM() reference values
//
// Quick start (macOS Apple Silicon with Homebrew):
//   brew install geographiclib
//   c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
//       -lGeographicLib -Dprivate=public tm_ref_values.cpp -o tm_ref_values
//   ./tm_ref_values
//
// For other platforms (Intel Mac, Linux, build from source) see:
//   Tests/ReferenceGenerators-SETUP.md

#include <GeographicLib/TransverseMercator.hpp>
#include <cstdio>

int main() {
    auto& utm = GeographicLib::TransverseMercator::UTM();

    printf("=== TransverseMercator::UTM() internal fields ===\n\n");
    printf("n   = %.17e\n", utm._n);
    printf("a1  = %.17e\n", utm._a1);
    printf("b1  = %.17e\n", utm._b1);
    printf("c   = %.17e\n", utm._c);
    printf("e2  = %.17e\n", utm._e2);
    printf("e2m = %.17e\n", utm._e2m);
    printf("es  = %.17e\n", utm._es);

    printf("\nalp coefficients (1-indexed):\n");
    for (int i = 1; i <= 6; ++i)
        printf("alp[%d] = %.17e\n", i, utm._alp[i]);

    printf("\nbet coefficients (1-indexed):\n");
    for (int i = 1; i <= 6; ++i)
        printf("bet[%d] = %.17e\n", i, utm._bet[i]);

    return 0;
}
