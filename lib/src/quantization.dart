/// Fixed-point geographic coordinates, used everywhere this package compares
/// geometry.
///
/// Latitude and longitude are stored as integers in millionths of a degree, so
/// lookups, the index and the tests all round identically and a point near a
/// border cannot resolve differently in one of them. Integers also avoid
/// floating-point edge cases where adjacent polygons share border vertices.
library;

/// Fixed-point units per degree: one unit is 0.000001°, about 11 cm at the
/// equator.
const int coordinateScale = 1000000;

/// Converts a latitude or longitude in degrees to fixed-point units.
///
/// Rounds half away from zero, so positive and negative values are treated the
/// same.
int quantize(double degrees) => (degrees * coordinateScale).round();

/// Converts fixed-point [units] back to degrees.
///
/// Lossy: the result is within half a unit (~5.5 cm) of the original.
double dequantize(int units) => units / coordinateScale;

/// Quantizes a longitude supplied by a caller, so that +180° and −180° resolve
/// alike.
///
/// Use this for lookup coordinates only. Polygon vertices must use [quantize]:
/// remapping a stored +180 vertex would move that edge to the far side of the
/// world.
///
/// Zones crossing the antimeridian are split there, and point-in-polygon
/// resolves a point on a west edge but not on an east one, so a bare +180
/// misses hits that −180 finds.
int quantizeQueryLongitude(double degrees) {
  const eastSeam = 180 * coordinateScale;
  // Remap after rounding rather than testing `degrees == 180.0`: every
  // longitude from 179.9999995 up also lands on the east seam, and leaving
  // those behind opens a ~5.5 cm strip that resolves to nothing.
  final units = quantize(degrees);
  return units == eastSeam ? -eastSeam : units;
}
