/// Point-in-polygon testing in fixed-point integer space.
///
/// Shared by the runtime lookup, the index builder and the reference oracle,
/// for the same reason as `quantization.dart`: three implementations of the
/// containment rule would be three chances to disagree, and a disagreement
/// between the index and the oracle is indistinguishable from a bug in the
/// index.
library;

import 'dart:typed_data';

/// Whether the point (`px`, `py`) lies inside [ring].
///
/// The ring is interleaved `[x0, y0, x1, y1, …]` in quantized units, and is
/// treated as implicitly closed — the last vertex joins back to the first, so
/// a GeoJSON ring that repeats its first point as its last works unchanged
/// (the repeated edge is degenerate and contributes nothing).
///
/// ## Algorithm
///
/// Even-odd ray casting: a ray is cast in the +x direction and edge crossings
/// are counted. An edge is crossed when the point's y lies between the edge's
/// endpoints, tested as `(yi > py) != (yj > py)`. Writing it that way handles
/// two cases at once — a horizontal edge has `yi == yj`, so the test is false
/// and the edge is skipped, which is what even-odd counting requires; and
/// using a strict comparison on one end and not the other means a vertex
/// lying exactly at `py` is counted once rather than twice.
///
/// The usual intersection formula `xi + (py - yi) * (xj - xi) / (yj - yi)` is
/// cross-multiplied to stay in integers. Multiplying an inequality by a
/// negative number reverses it, so the comparison flips when the edge runs
/// downward.
///
/// ## Boundary behaviour
///
/// A point exactly on an edge is not classified consistently, and cannot be
/// by this family of algorithms: a point on a *west* edge has the ray cross
/// the interior and reads as inside, while one on an *east* edge has the ray
/// leave immediately and reads as outside. This is not a defect to fix here —
/// it is why query longitudes at the antimeridian are collapsed to a single
/// representation by `quantizeQueryLongitude`. Along ordinary shared borders
/// it means adjacent zones partition the plane without gaps or double
/// counting, which is the desirable half of the same property.
///
/// ## Range
///
/// The intermediate products reach about 1.3e17 for antipodal coordinates —
/// `(px - xi)` spans at most 3.6e8 and `dy` at most 1.8e8 — leaving roughly
/// 70x headroom inside the 64-bit range. On the web, where integers are
/// doubles, values above 2^53 would lose precision; this is one reason web
/// support is deferred, and a reason to revisit this function rather than
/// assume it transfers.
bool pointInRing(Int32List ring, int px, int py) {
  final n = ring.length ~/ 2;
  var inside = false;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final xi = ring[i * 2], yi = ring[i * 2 + 1];
    final xj = ring[j * 2], yj = ring[j * 2 + 1];
    if ((yi > py) == (yj > py)) continue;
    final dy = yj - yi;
    final side = (px - xi) * dy - (py - yi) * (xj - xi);
    if (dy > 0 ? side < 0 : side > 0) inside = !inside;
  }
  return inside;
}

/// Whether the point lies inside [outer] and outside every ring in [holes].
bool pointInPolygon(
  Int32List outer,
  List<Int32List> holes,
  int px,
  int py,
) {
  if (!pointInRing(outer, px, py)) return false;
  for (final hole in holes) {
    if (pointInRing(hole, px, py)) return false;
  }
  return true;
}
