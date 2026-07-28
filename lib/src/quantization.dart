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

/// Units per degree. 1e-6 degrees is roughly 11 cm at the equator — finer than
/// the positional accuracy of the underlying OpenStreetMap data, and chosen
/// because the size budget does not require anything coarser (plan §5.2).
const int coordinateScale = 1000000;

/// Converts [degrees] to fixed-point units.
///
/// Rounds half away from zero, symmetrically about the meridian and equator,
/// so that positive and negative coordinates are treated identically.
///
/// Valid inputs are bounded by ±180, giving a maximum magnitude of 1.8e8 —
/// comfortably inside the 2^53 range that is exact on every Dart platform,
/// including the web.
int quantize(double degrees) => (degrees * coordinateScale).round();

/// Converts fixed-point [units] back to degrees.
///
/// Lossy by construction: the result is within half a unit (~5.5 cm) of the
/// original coordinate, never closer.
double dequantize(int units) => units / coordinateScale;

/// Quantizes a **query** longitude, collapsing the antimeridian to one seam.
///
/// +180° and −180° name the same meridian, and plan §9.3 requires that both
/// return the same answer. They do not do so naturally, for a reason that is
/// about the algorithm rather than the data: point-in-polygon casts a ray in
/// the +x direction, so a point lying exactly on a polygon's **west** edge has
/// the ray cross the interior and counts as inside, while a point on an
/// **east** edge has the ray leave immediately and counts as outside.
///
/// timezone-boundary-builder splits zones that span the meridian into separate
/// polygons, one ending at +180 and one beginning at −180. Querying at +180
/// therefore lands on an east edge and finds nothing, while −180 lands on a
/// west edge and resolves. Measured against 2026c: of fifteen latitudes
/// sampled at the meridian, every non-empty answer — `Antarctica/McMurdo`,
/// `America/Adak`, `Asia/Anadyr` — came from the −180 side, and +180 was
/// empty at all fifteen.
///
/// Mapping the east seam to the west one makes it single-valued, and picks the
/// representation where the geometry actually resolves.
///
/// The remapping is applied **after** quantizing, not to the incoming double.
/// That distinction is not cosmetic: every longitude in
/// `[179.9999995, 180.0]` quantizes to the same `+180000000`, so testing the
/// double for equality with `180.0` would leave the rest of that band on the
/// east edge. It would then return nothing while both `180.0` and
/// `179.9999994` resolved — a ~5.5 cm hole in the map rather than a
/// disagreement at a single point.
///
/// The west side needs no such care: `-179.9999996` and `-180.0` already
/// quantize alike, and anything beyond ±180 is rejected as out of range before
/// reaching here.
///
/// **This applies to query coordinates only.** Polygon vertices must be
/// quantized with plain [quantize]: normalising a stored vertex at +180 would
/// move geometry to the far side of the world.
int quantizeQueryLongitude(double degrees) {
  const eastSeam = 180 * coordinateScale;
  final units = quantize(degrees);
  return units == eastSeam ? -eastSeam : units;
}
