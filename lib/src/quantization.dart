/// Fixed-point representation of geographic coordinates.
///
/// Every part of this package that compares geometry does so in quantized
/// integer space: the runtime lookup, the index builder in `tool/`, and the
/// Phase A reference oracle in `test/`. Sharing one definition is deliberate —
/// if any of them quantized differently, points within one unit of a border
/// would resolve differently and the differential test's zero-disagreement
/// guarantee (plan §10.3) would be unachievable.
///
/// Integer geometry also removes floating-point edge cases from
/// point-in-polygon tests along shared borders, where two polygons reference
/// the same vertices.
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
/// Mapping +180 to −180 makes the seam single-valued, and picks the
/// representation where the geometry actually resolves.
///
/// **This applies to query coordinates only.** Polygon vertices must be
/// quantized with plain [quantize]: normalising a stored vertex at +180 would
/// move geometry to the far side of the world.
int quantizeQueryLongitude(double degrees) =>
    quantize(degrees == 180.0 ? -180.0 : degrees);
