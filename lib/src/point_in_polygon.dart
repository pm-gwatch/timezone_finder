/// Point-in-polygon testing in fixed-point integer space.
///
/// Shared by the runtime lookup, the index builder and the reference oracle:
/// three implementations of the containment rule would be three chances to
/// disagree, and index/oracle disagreement is indistinguishable from a bug in
/// the index.
library;

import 'dart:typed_data';

/// Whether (`px`, `py`) lies inside [ring], by even-odd ray casting.
///
/// [ring] is interleaved `[x0, y0, x1, y1, …]` in quantized units and is
/// implicitly closed, so a GeoJSON ring that repeats its first vertex as its
/// last works unchanged.
///
/// **A point on an edge resolves to the polygon east of it** — inside when the
/// edge is the ring's west side, outside when it is the east. Adjacent
/// polygons therefore partition a shared border with no gap or overlap, and
/// `quantizeQueryLongitude` depends on this when it collapses +180 onto -180.
///
/// Intermediate products stay exact on dart2js as well as the VM: for an edge
/// the ray can straddle, `|side| ≤ 360e6·|dy| + |dy|·|dx|`, and the index
/// generator refuses to emit data whose maximum sound bound is ≥ 2⁵³.
bool pointInRing(Int32List ring, int px, int py) {
  final n = ring.length ~/ 2;
  var inside = false;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final xi = ring[i * 2], yi = ring[i * 2 + 1];
    final xj = ring[j * 2], yj = ring[j * 2 + 1];
    // Skip edges the ray cannot cross. Comparing strictly at one end only is
    // deliberate: it drops horizontal edges, and counts a vertex sitting
    // exactly at py once rather than twice.
    if ((yi > py) == (yj > py)) continue;
    // `px < xi + (py - yi) * (xj - xi) / (yj - yi)`, cross-multiplied to stay
    // in integers. Multiplying by a negative reverses the inequality, hence
    // the flip for downward edges.
    final dy = yj - yi;
    final side = (px - xi) * dy - (py - yi) * (xj - xi);
    if (dy > 0 ? side < 0 : side > 0) inside = !inside;
  }
  return inside;
}

/// Whether the point lies inside [outer] and outside every ring in [holes].
bool pointInPolygon(Int32List outer, List<Int32List> holes, int px, int py) {
  if (!pointInRing(outer, px, py)) return false;
  for (final hole in holes) {
    if (pointInRing(hole, px, py)) return false;
  }
  return true;
}
