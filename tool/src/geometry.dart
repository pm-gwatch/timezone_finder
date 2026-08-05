/// Polygon area and the overlap precedence rule.
///
/// Shared by the reference oracle and the index builder, which must agree
/// exactly: two copies of a rule that decides which identifier is returned in
/// a disputed territory would be two chances to disagree.
///
/// Not in `lib/` — areas are computed at build time and candidate order is
/// baked into the index, so none of this runs at lookup time.
library;

import 'dart:typed_data';

/// Twice the shoelace area of [ring], in square quantized units.
///
/// [ring] is interleaved `[x0, y0, x1, y1, …]`. The result is doubled to keep
/// it an exact integer — the shoelace sum of integer coordinates is always
/// whole, while the area itself may be a half-integer — and only relative
/// order matters to [comparePrecedence], which doubling preserves.
///
/// Rings of fewer than three vertices return zero. Accumulates in int64, with
/// ~1800x headroom on tzbb 2026c; `tool/measure_geometry.dart` re-measures
/// that margin against a new release.
int ringDoubledArea(Int32List ring) {
  final n = ring.length ~/ 2;
  if (n < 3) return 0;
  // Translating by the first vertex keeps the running sum small. The shoelace
  // formula is translation-invariant, so the result is unchanged.
  final x0 = ring[0];
  final y0 = ring[1];
  var total = 0;
  for (var i = 0; i < n; i++) {
    final j = (i + 1) % n;
    final xi = ring[i * 2] - x0, yi = ring[i * 2 + 1] - y0;
    final xj = ring[j * 2] - x0, yj = ring[j * 2 + 1] - y0;
    total += xi * yj - xj * yi;
  }
  return total.abs();
}

/// Twice the area of a polygon: its outer ring less its holes, never negative.
///
/// Upstream geometry is not assumed to be valid, and a negative area would
/// invert the precedence rule.
int polygonDoubledArea(Int32List outer, List<Int32List> holes) {
  var area = ringDoubledArea(outer);
  for (final hole in holes) {
    area -= ringDoubledArea(hole);
  }
  return area < 0 ? 0 : area;
}

/// Orders two overlapping polygons by the overlap tiebreak:
/// smallest area first, ties broken on identifier. Negative when `a` wins.
///
/// Areas are the doubled values from [polygonDoubledArea]. The comparison is
/// exact by design — do not reintroduce a tolerance, which would not be
/// transitive and would let `List.sort` order disputed territories
/// arbitrarily.
int comparePrecedence(int areaA, String zoneA, int areaB, String zoneB) {
  final byArea = areaA.compareTo(areaB);
  if (byArea != 0) return byArea;
  return zoneA.compareTo(zoneB);
}
