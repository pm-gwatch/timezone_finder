/// Point-in-polygon in quantized integers. Shared by runtime, builder, and
/// oracle so they cannot disagree on containment.
library;

import 'dart:typed_data';

/// Even-odd ray cast. [ring] is interleaved quantized `[x,y]`, implicitly
/// closed. **A point on an edge belongs to the polygon east of it** (inside on
/// a west edge, outside on an east). dart2js: products must stay below 2⁵³;
/// the generator refuses rings that would not.
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
