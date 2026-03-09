// magnetic_ref_values.cpp — Generate Geocentric and MagneticModel reference values
//
// Quick start (macOS Apple Silicon with Homebrew):
//   brew install geographiclib
//   sudo geographiclib-get-magnetic wmm2025
//   c++ -std=c++20 -I/opt/homebrew/include -L/opt/homebrew/lib \
//       -lGeographicLib -Dprivate=public magnetic_ref_values.cpp \
//       -o magnetic_ref_values
//   ./magnetic_ref_values
//
// For other platforms (Intel Mac, Linux, build from source) see:
//   Tests/ReferenceGenerators-SETUP.md

#include <GeographicLib/Geocentric.hpp>
#include <GeographicLib/MagneticModel.hpp>
#include <cstdio>
#include <cmath>

void printGeocentric(double lat, double lon, double h) {
    auto& geo = GeographicLib::Geocentric::WGS84();
    double X, Y, Z;
    double M[9];
    geo.IntForward(lat, lon, h, X, Y, Z, M);

    printf("  (lat: %.4f, lon: %.4f, h: %.1f,\n", lat, lon, h);
    printf("   X: %.15e, Y: %.15e, Z: %.15e,\n", X, Y, Z);
    printf("   M: [%.15e, %.15e, %.15e,\n", M[0], M[1], M[2]);
    printf("       %.15e, %.15e, %.15e,\n", M[3], M[4], M[5]);
    printf("       %.15e, %.15e, %.15e]),\n\n", M[6], M[7], M[8]);
}

void printUnrotate() {
    auto& geo = GeographicLib::Geocentric::WGS84();
    double X, Y, Z;
    double M[9];
    geo.IntForward(47.6, -122.3, 100, X, Y, Z, M);

    // M^T * (100, -200, 50)
    double vx = 100.0, vy = -200.0, vz = 50.0;
    double rx = M[0]*vx + M[3]*vy + M[6]*vz;
    double ry = M[1]*vx + M[4]*vy + M[7]*vz;
    double rz = M[2]*vx + M[5]*vy + M[8]*vz;

    printf("=== Unrotate (M^T * [100, -200, 50]) at (47.6, -122.3, 100) ===\n");
    printf("refX = %.15e\n", rx);
    printf("refY = %.15e\n", ry);
    printf("refZ = %.15e\n\n", rz);
}

struct MagTestCase {
    double t, lat, lon, h;
};

void printMagneticField() {
    GeographicLib::MagneticModel model("wmm2025", "/usr/local/share/GeographicLib/magnetic");

    MagTestCase cases[] = {
        {2025.0,   0.0,     0.0,   0},
        {2025.0,  80.0,     0.0,   0},
        {2025.0, -80.0,     0.0,   0},
        {2025.0,   0.0,   120.0,   0},
        {2025.0,   0.0,  -120.0,   0},
        {2025.0,  47.6,  -122.3,   0},
        {2025.0, -33.86,  151.2,   0},
        {2027.5,  47.6,  -122.3,   1000},
        {2025.5,   0.0,     0.0,   100000},
        {2029.0,  45.0,    45.0,   50000},
    };

    printf("=== WMM2025 field values ===\n\n");
    for (auto& tc : cases) {
        double Bx, By, Bz, Bxt, Byt, Bzt;
        model(tc.t, tc.lat, tc.lon, tc.h, Bx, By, Bz, Bxt, Byt, Bzt);
        // Swift convention: east=Bx, north=By, up=Bz
        printf("  (t: %.1f, lat: %.2f, lon: %.1f, h: %.0f,\n", tc.t, tc.lat, tc.lon, tc.h);
        printf("   east: %.15e, north: %.15e, up: %.15e,\n", Bx, By, Bz);
        printf("   eastDeltaT: %.15e, northDeltaT: %.15e, upDeltaT: %.15e),\n\n",
               Bxt, Byt, Bzt);
    }

    // Full pipeline test: t=2026.0, lat=47.6, lon=-122.3, h=0
    {
        double Bx, By, Bz, Bxt, Byt, Bzt;
        model(2026.0, 47.6, -122.3, 0, Bx, By, Bz, Bxt, Byt, Bzt);
        // Swift convention: east=Bx, north=By, up=Bz
        double east = Bx, north = By, up = Bz;
        double H = hypot(east, north);
        double F = hypot(H, up);
        double D = atan2(east, north) * 180.0 / M_PI;
        double I = atan2(-up, H) * 180.0 / M_PI;
        printf("=== Full pipeline (t=2026.0, lat=47.6, lon=-122.3, h=0) ===\n");
        printf("east  = %.15e\n", east);
        printf("north = %.15e\n", north);
        printf("up    = %.15e\n", up);
        printf("H     = %.15e\n", H);
        printf("F     = %.15e\n", F);
        printf("D     = %.15e\n", D);
        printf("I     = %.15e\n\n", I);
    }

    // FieldComponents test values
    {
        double east = 1234.5, north = 20000.0, up = -40000.0;
        double H = hypot(east, north);
        double F = hypot(H, up);
        double D = atan2(east, north) * 180.0 / M_PI;
        double I = atan2(-up, H) * 180.0 / M_PI;
        printf("=== FieldComponents (east=1234.5, north=20000, up=-40000) ===\n");
        printf("H = %.15e\n", H);
        printf("F = %.15e\n", F);
        printf("D = %.15e\n", D);
        printf("I = %.15e\n\n", I);

        // With rates
        double eastDt = 10.0, northDt = -5.0, upDt = 3.0;
        double Hdt = (east*eastDt + north*northDt) / H;
        double Fdt = (east*eastDt + north*northDt + up*upDt) / F;
        double Ddt = (eastDt*north - east*northDt) / (H*H) * 180.0 / M_PI;
        double Idt = (-upDt*H + up*Hdt) / (F*F) * 180.0 / M_PI;
        printf("Hdt = %.15e\n", Hdt);
        printf("Fdt = %.15e\n", Fdt);
        printf("Ddt = %.15e\n", Ddt);
        printf("Idt = %.15e\n", Idt);
    }
}

int main() {
    printf("=== Geocentric::WGS84().IntForward() ===\n\n");
    printGeocentric(0.0, 0.0, 0.0);
    printGeocentric(47.6, -122.3, 100.0);
    printGeocentric(-33.86, 151.2, 50.0);
    printGeocentric(90.0, 0.0, 0.0);
    printGeocentric(-90.0, 0.0, 0.0);
    printGeocentric(0.0, 180.0, 10000.0);
    printGeocentric(45.0, 45.0, 500.0);
    printGeocentric(-80.4174, 77.1166, 3000.0);

    printf("\n");
    printUnrotate();

    printf("\n");
    printMagneticField();

    return 0;
}
