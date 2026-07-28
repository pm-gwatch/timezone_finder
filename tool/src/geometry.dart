/// Polygon area and the overlap precedence rule.
///
/// Both are needed by the Phase A reference oracle in `test/` and by the index
/// builder, and they must agree exactly. This is the single implementation, for
/// the same reason `lib/src/quantization.dart` is: two copies of a rule that
/// decides which identifier is returned in a disputed territory would be two
/// chances to disagree.
///
/// Deliberately not in `lib/`. Areas are computed once at build time and the
/// candidate order is baked into the index, so nothing here runs at lookup
/// time and none of it needs to ship.
library;

import 'dart:typed_data';

/// Shoelace area of one ring, in square quantized units.
///
/// Rings are interleaved `[x0, y0, x1, y1, …]`. Vertices are translated by the
/// ring's first point before accumulating: the shoelace formula is
/// translation-invariant, so this changes nothing mathematically but keeps the
/// products small relative to the raw coordinate magnitudes. Accumulation is
/// in `double` because an exact integer sum would overflow int64 on the
/// largest rings — the biggest here has 192,961 vertices.
///
/// Degenerate rings of fewer than three vertices have zero area.
double ringArea(Int32List ring) {
  final n = ring.length ~/ 2;
  if (n < 3) return 0;
  final x0 = ring[0].toDouble();
  final y0 = ring[1].toDouble();
  var total = 0.0;
  for (var i = 0; i < n; i++) {
    final j = (i + 1) % n;
    final xi = ring[i * 2] - x0, yi = ring[i * 2 + 1] - y0;
    final xj = ring[j * 2] - x0, yj = ring[j * 2 + 1] - y0;
    total += xi * yj - xj * yi;
  }
  return total.abs() / 2;
}

/// Area of a polygon: its outer ring less its holes.
double netPolygonArea(Int32List outer, List<Int32List> holes) {
  var area = ringArea(outer);
  for (final hole in holes) {
    area -= ringArea(hole);
  }
  return area;
}

/// Orders two overlapping polygons by the precedence rule of plan §6.5.
///
/// Smallest planar area wins; ties break on identifier. Returns a negative
/// number when `a` takes precedence.
///
/// ## Why the comparison is exact
///
/// An earlier version compared areas with a *relative tolerance*, so that a
/// last-bit difference between two implementations of the shoelace sum could
/// not flip the ordering. That was the wrong fix for a real concern, because
/// **a tolerance-based comparator is not a valid total order.** "Within
/// tolerance" is not transitive: for `a = 1.0`, `b = 1.0 + 1e-9` and
/// `c = 1.0 + 2e-9` at a 1e-9 relative tolerance, `a` ties with `b` and `b`
/// ties with `c`, yet `a` sorts strictly before `c`. A comparator that
/// contradicts itself lets `List.sort` produce an arbitrary order, and here
/// that order decides which identifier is returned in a disputed territory.
///
/// The concern it was addressing is instead removed at the source: there is
/// exactly one implementation of [ringArea], shared by the oracle and the
/// index builder. IEEE 754 arithmetic is deterministic for a fixed sequence of
/// operations, so both sides sum the same terms in the same order and get
/// bit-identical results. With one implementation there is nothing to
/// reconcile, and the comparison can be exact.
///
/// If a second implementation of the area ever becomes necessary — a different
/// language in the pipeline, say — do not reintroduce a tolerance here. Make
/// the two agree, or compare an integer key derived from the area, which stays
/// transitive because it is a function into a totally ordered set.
int comparePrecedence(double areaA, String zoneA, double areaB, String zoneB) {
  final byArea = areaA.compareTo(areaB);
  if (byArea != 0) return byArea;
  return zoneA.compareTo(zoneB);
}
