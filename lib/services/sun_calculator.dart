import 'dart:math' as math;
import '../models/sun_position.dart';

/// Calculates the sun's position using the NOAA Solar Calculator algorithm.
///
/// References:
///   https://gml.noaa.gov/grad/solcalc/solareqns.PDF
///   https://gml.noaa.gov/grad/solcalc/
///
/// All intermediate angles are in degrees unless explicitly named with "Rad".
class SunCalculator {
  const SunCalculator();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the [SunPosition] (azimuth + altitude) for a given location and
  /// moment in time.
  ///
  /// [latitude]  – decimal degrees, positive = North
  /// [longitude] – decimal degrees, positive = East
  /// [dateTime]  – the moment to evaluate; uses local time zone offset
  SunPosition calculate(
    double latitude,
    double longitude,
    DateTime dateTime,
  ) {
    // Work in UTC so we can apply the timezone offset ourselves.
    final utc = dateTime.toUtc();

    // Julian Day Number (fractional)
    final jd = _julianDay(utc);

    // Julian century from J2000.0
    final t = (jd - 2451545.0) / 36525.0;

    // Geometric mean longitude of the sun (degrees)
    final l0 = _normalise360(280.46646 + t * (36000.76983 + t * 0.0003032));

    // Geometric mean anomaly of the sun (degrees)
    final m = _normalise360(357.52911 + t * (35999.05029 - t * 0.0001537));

    // Equation of centre
    final mRad = _toRad(m);
    final c = math.sin(mRad) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(2 * mRad) * (0.019993 - 0.000101 * t) +
        math.sin(3 * mRad) * 0.000289;

    // Sun's true longitude (degrees)
    final sunLon = l0 + c;

    // Sun's apparent longitude (degrees) — correct for nutation & aberration
    final omega = 125.04 - 1934.136 * t;
    final lambda = sunLon - 0.00569 - 0.00478 * math.sin(_toRad(omega));

    // Mean obliquity of the ecliptic (degrees)
    final obliq0 = 23.0 +
        (26.0 +
                ((21.448 -
                        t *
                            (46.8150 +
                                t * (0.00059 - t * 0.001813)))) /
                    60.0) /
            60.0;

    // Corrected obliquity
    final obliqCorr =
        obliq0 + 0.00256 * math.cos(_toRad(omega));

    // Sun's declination (degrees)
    final declRad = math.asin(
      math.sin(_toRad(obliqCorr)) * math.sin(_toRad(lambda)),
    );
    final decl = _toDeg(declRad);

    // Eccentricity of Earth's orbit
    final e =
        0.016708634 - t * (0.000042037 + 0.0000001267 * t);

    // Equation of Time (minutes)
    final y = math.pow(math.tan(_toRad(obliqCorr / 2)), 2);
    final mRad2 = _toRad(
      _normalise360(357.52911 + t * (35999.05029 - t * 0.0001537)),
    );
    final l0Rad = _toRad(l0);
    final eot = 4.0 *
        _toDeg(y * math.sin(2 * l0Rad) -
            2 * e * math.sin(mRad2) +
            4 * e * y * math.sin(mRad2) * math.cos(2 * l0Rad) -
            0.5 * y * y * math.sin(4 * l0Rad) -
            1.25 * e * e * math.sin(2 * mRad2));

    // Time zone offset in minutes
    final tzOffsetMin =
        dateTime.timeZoneOffset.inSeconds / 60.0;

    // True solar time (minutes past midnight)
    final trueSolarTimeMin =
        (utc.hour * 60.0 + utc.minute + utc.second / 60.0) +
            eot +
            4.0 * longitude +
            tzOffsetMin;

    // Hour angle (degrees). At solar noon ha = 0; morning negative, afternoon positive.
    final ha = _haFromTrueSolarTime(trueSolarTimeMin);

    // Solar zenith angle
    final latRad = _toRad(latitude);
    final cosZenith = math.sin(latRad) * math.sin(declRad) +
        math.cos(latRad) * math.cos(declRad) * math.cos(_toRad(ha));
    final zenithDeg = _toDeg(math.acos(cosZenith.clamp(-1.0, 1.0)));

    // Solar altitude (elevation)
    final altitude = 90.0 - zenithDeg;

    // Atmospheric refraction correction (approx.)
    final altitudeCorrected = altitude + _refractionCorrection(altitude);

    // Solar azimuth (degrees from North, clockwise)
    final azimuth = _azimuth(latitude, decl, zenithDeg, ha);

    return SunPosition(
      azimuth: azimuth,
      altitude: altitudeCorrected,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Julian Day Number for a UTC DateTime.
  double _julianDay(DateTime utc) {
    int y = utc.year;
    int m = utc.month;
    final double d = utc.day +
        (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final int a = (y / 100).floor();
    final int b = 2 - a + (a / 4).floor();

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  /// Hour angle from true solar time in minutes.
  double _haFromTrueSolarTime(double trueSolarTimeMin) {
    final mod = trueSolarTimeMin % 1440;
    if (mod / 4.0 < 0) {
      return mod / 4.0 + 180;
    } else {
      return mod / 4.0 - 180;
    }
  }

  /// Solar azimuth in degrees from North, clockwise.
  double _azimuth(
    double latitude,
    double decl,
    double zenithDeg,
    double ha,
  ) {
    final latRad = _toRad(latitude);
    final declRad = _toRad(decl);
    final zenithRad = _toRad(zenithDeg);

    double azRad = math.acos(
      ((math.sin(latRad) * math.cos(zenithRad)) -
              math.sin(declRad)) /
          (math.cos(latRad) * math.sin(zenithRad)),
    );

    // Clamp for floating-point safety
    azRad = math.acos(
      (((math.sin(latRad) * math.cos(zenithRad)) - math.sin(declRad)) /
              (math.cos(latRad) * math.sin(zenithRad)))
          .clamp(-1.0, 1.0),
    );

    double az = _toDeg(azRad);

    // Adjust for morning/afternoon
    if (ha > 0) {
      az = (az + 180) % 360;
    } else {
      az = (540 - az) % 360;
    }

    return az;
  }

  /// Approximate atmospheric refraction correction in degrees.
  double _refractionCorrection(double altitudeDeg) {
    if (altitudeDeg > 85) return 0.0;
    if (altitudeDeg > 5) {
      return (58.1 / math.tan(_toRad(altitudeDeg)) -
              0.07 / math.pow(math.tan(_toRad(altitudeDeg)), 3) +
              0.000086 / math.pow(math.tan(_toRad(altitudeDeg)), 5)) /
          3600.0;
    }
    if (altitudeDeg > -0.575) {
      return (1735.0 +
              altitudeDeg *
                  (-518.2 + altitudeDeg * (103.4 + altitudeDeg * (-12.79 + altitudeDeg * 0.711)))) /
          3600.0;
    }
    return (-20.774 / math.tan(_toRad(altitudeDeg))) / 3600.0;
  }

  double _normalise360(double deg) => ((deg % 360) + 360) % 360;

  double _toRad(double deg) => deg * math.pi / 180.0;

  double _toDeg(double rad) => rad * 180.0 / math.pi;
}
