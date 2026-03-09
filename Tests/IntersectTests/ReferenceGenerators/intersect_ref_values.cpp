// intersect_ref_values.cpp — Generate Intersect constructor reference values
//
// Quick start (macOS Apple Silicon with Homebrew):
//   brew install geographiclib
//   c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
//       -lGeographicLib -Dprivate=public intersect_ref_values.cpp \
//       -o intersect_ref_values
//   ./intersect_ref_values
//
// For other platforms (Intel Mac, Linux, build from source) see:
//   Tests/ReferenceGenerators-SETUP.md

#include <GeographicLib/Intersect.hpp>
#include <GeographicLib/Geodesic.hpp>
#include <cstdio>

int main() {
    auto inter = GeographicLib::Intersect(GeographicLib::Geodesic::WGS84());

    printf("=== Intersect constructor constants (WGS84) ===\n\n");
    printf("a     = %.17e\n", inter._a);
    printf("f     = %.17e\n", inter._f);
    printf("rR    = %.17e\n", inter._rR);
    printf("d     = %.17e\n", inter._d);
    printf("eps   = %.17e\n", inter._eps);
    printf("tol   = %.17e\n", inter._tol);
    printf("delta = %.17e\n", inter._delta);
    printf("t1    = %.17e\n", inter._t1);
    printf("t2    = %.17e\n", inter._t2);
    printf("t3    = %.17e\n", inter._t3);
    printf("t4    = %.17e\n", inter._t4);
    printf("t5    = %.17e\n", inter._t5);
    printf("d1    = %.17e\n", inter._d1);
    printf("d2    = %.17e\n", inter._d2);
    printf("d3    = %.17e\n", inter._d3);

    printf("\n=== Geodesic::WGS84().EllipsoidArea() ===\n\n");
    printf("area  = %.17e\n", GeographicLib::Geodesic::WGS84().EllipsoidArea());

    return 0;
}
