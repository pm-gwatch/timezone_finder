/// Fixed-point geographic coordinates used everywhere this package
/// compares geometry.
///
/// Latitude and longitude are stored as integers in millionths of a degree
/// ([coordinateScale]): one unit is \(10^{-6}\)°, about 11 cm at the equator.
/// The same conversion is used for lookups, the on-disk index, and tests, so
/// a point near a border cannot resolve differently in one place than another.
///
/// Working in integers also avoids floating-point edge cases when polygons
/// share border vertices.
library;

/// How many fixed-point units equal one degree of latitude or longitude.
///
/// With the current value, one unit is \(10^{-6}\)° — about 11 cm at the
/// equator.
const int coordinateScale = 1000000;

/// Converts a latitude or longitude in degrees to fixed-point units.
///
/// Multiplies by [coordinateScale] and rounds half away from zero, so
/// positive and negative values are treated the same.
int quantize(double degrees) => (degrees * coordinateScale).round();

/// Converts fixed-point [units] back to degrees.
///
/// Lossy: the result is within half a unit (~5.5 cm at the equator) of the
/// original coordinate.
double dequantize(int units) => units / coordinateScale;

/// Quantizes a lookup longitude (the `lon` passed to `find`) so that
/// +180° and −180° resolve the same.
///
/// Use this for the caller's coordinates. Boundary vertices from the
/// timezone polygons must use [quantize] instead: remapping a stored +180
/// vertex would move that edge to the other side of the world.
///
/// After [quantize], maps the east antimeridian seam
/// (`+180 × coordinateScale`) to the west (`−180 × coordinateScale`).
/// Point-in-polygon treats those edges differently, and zones that cross
/// 180° are split there, so a bare +180 can miss a hit that −180 gets.
///
/// Remapping after quantization (not via `degrees == 180.0`) covers every
/// value that rounds to the east seam.
int quantizeQueryLongitude(double degrees) {
  const eastSeam = 180 * coordinateScale;
  final units = quantize(degrees);
  return units == eastSeam ? -eastSeam : units;
}
