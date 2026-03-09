# GeographicLib Installation for Reference Generators

The C++ reference generators in `Tests/*/ReferenceGenerators/` link against
the [GeographicLib](https://geographiclib.sourceforge.io) C++ library. This
document covers three ways to install it.

---

## Option 1: macOS — Homebrew (recommended)

```sh
brew install geographiclib
```

Set the include/lib paths based on your Mac's architecture:

```sh
# Apple Silicon (M1/M2/M3/M4)
GEOLIB_INC=/opt/homebrew/include
GEOLIB_LIB=/opt/homebrew/lib

# Intel Mac
GEOLIB_INC=/usr/local/include
GEOLIB_LIB=/usr/local/lib
```

Then build any generator with:

```sh
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB -lGeographicLib \
    [-Dprivate=public] <source>.cpp -o <output>
```

---

## Option 2: Linux — apt

```sh
sudo apt-get install -y libgeographic-dev
```

Headers and libraries install to standard system paths, so no `-I` or `-L`
flags are needed:

```sh
c++ -std=c++20 -lGeographicLib [-Dprivate=public] <source>.cpp -o <output>
```

---

## Option 3: Build from source (any platform)

Use this when neither Homebrew nor apt is available.

```sh
# Clone
git clone https://github.com/geographiclib/geographiclib.git
cd geographiclib

# Build
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$PWD/../install ..
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
make install
cd ../..
```

Set the paths to the local install:

```sh
GEOLIB_INC=geographiclib/install/include
GEOLIB_LIB=geographiclib/install/lib
```

Then build any generator with:

```sh
c++ -std=c++20 -I$GEOLIB_INC -L$GEOLIB_LIB -lGeographicLib \
    -Wl,-rpath,$GEOLIB_LIB [-Dprivate=public] <source>.cpp -o <output>
```

The `-Wl,-rpath` flag ensures the dynamic linker can find `libGeographicLib.so`
(or `.dylib`) at runtime without setting `LD_LIBRARY_PATH`/`DYLD_LIBRARY_PATH`.

---

## WMM2025 magnetic data (MagneticModel generator only)

The `magnetic_ref_values.cpp` generator requires WMM2025 coefficients.

**Homebrew / apt install:**

```sh
# Uses the geographiclib-get-magnetic script installed with the library
sudo geographiclib-get-magnetic wmm2025
```

This installs data to `/usr/local/share/GeographicLib/magnetic/`.

**From-source install:**

After building GeographicLib from source, the download script is at
`geographiclib/install/bin/geographiclib-get-magnetic`. Either run it with
sudo to install to the default system path, or download the data manually:

```sh
# Manual download
mkdir -p geographiclib/install/share/GeographicLib/magnetic
cd geographiclib/install/share/GeographicLib/magnetic
curl -LO https://downloads.sourceforge.net/project/geographiclib/magnetic-distrib/wmm2025.tar.bz2
tar xjf wmm2025.tar.bz2
cd -
```

Then update the data path in `magnetic_ref_values.cpp` to point to your local
install (change the `MagneticModel` constructor's second argument).

---

## Which generators need `-Dprivate=public`?

| Generator | Needs `-Dprivate=public` | Reason |
|---|---|---|
| `tm_ref_values.cpp` | Yes | Accesses private TransverseMercator fields |
| `ps_ref_values.cpp` | Yes | Accesses private PolarStereographic fields |
| `ups_ref_values.cpp` | No | Uses only public UTMUPS API |
| `intersect_ref_values.cpp` | Yes | Accesses private Intersect fields |
| `magnetic_ref_values.cpp` | Yes | Accesses private Geocentric method |
