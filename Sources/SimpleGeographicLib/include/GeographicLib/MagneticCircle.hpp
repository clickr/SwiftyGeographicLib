/**
 * \file MagneticCircle.hpp
 * \brief Header for GeographicLib::MagneticCircle class
 *
 * Minimal stub to allow MagneticModel.cpp to compile.
 **********************************************************************/

#if !defined(GEOGRAPHICLIB_MAGNETICCIRCLE_HPP)
#define GEOGRAPHICLIB_MAGNETICCIRCLE_HPP 1

#include <GeographicLib/Constants.hpp>
#include <GeographicLib/CircularEngine.hpp>

namespace GeographicLib {

  class GEOGRAPHICLIB_EXPORT MagneticCircle {
  private:
    typedef Math::real real;
    real _a, _f, _lat, _h, _t, _cphi, _sphi, _t1, _dt0;
    bool _interpolate;
    CircularEngine _circ0, _circ1, _circC;
    bool _hasConstants;

  public:
    MagneticCircle(real a, real f, real lat, real h, real t,
                   real cphi, real sphi, real t1, real dt0,
                   bool interpolate,
                   const CircularEngine& circ0,
                   const CircularEngine& circ1)
      : _a(a), _f(f), _lat(lat), _h(h), _t(t)
      , _cphi(cphi), _sphi(sphi), _t1(t1), _dt0(dt0)
      , _interpolate(interpolate)
      , _circ0(circ0), _circ1(circ1)
      , _hasConstants(false)
    {}

    MagneticCircle(real a, real f, real lat, real h, real t,
                   real cphi, real sphi, real t1, real dt0,
                   bool interpolate,
                   const CircularEngine& circ0,
                   const CircularEngine& circ1,
                   const CircularEngine& circC)
      : _a(a), _f(f), _lat(lat), _h(h), _t(t)
      , _cphi(cphi), _sphi(sphi), _t1(t1), _dt0(dt0)
      , _interpolate(interpolate)
      , _circ0(circ0), _circ1(circ1), _circC(circC)
      , _hasConstants(true)
    {}
  };

} // namespace GeographicLib

#endif  // GEOGRAPHICLIB_MAGNETICCIRCLE_HPP
