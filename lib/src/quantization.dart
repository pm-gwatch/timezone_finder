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
