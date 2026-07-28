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

/// Twice the shoelace area of one ring, in square quantized units.
///
/// Rings are interleaved `[x0, y0, x1, y1, …]`. The result is **doubled** so
/// that it stays an exact integer: the shoelace sum of integer coordinates is
/// always a whole number, but the area itself may be a half-integer. Only
/// relative order matters for the precedence rule (§6.5), and doubling every
/// value preserves order.
///
/// Vertices are translated by the ring's first point before accumulating. The
/// formula is translation-invariant, so this changes nothing mathematically,
/// but it keeps the running sum small relative to the raw coordinate
/// magnitudes.
///
/// ## Why integers rather than doubles
///
/// This accumulated in `double` until it was measured. Across all 1,456 rings
/// of tzbb 2026c the largest magnitude any partial sum reaches is 5.12e15,
/// which leaves:
///
///   * **1801x** headroom inside the int64 range, and
///   * only **1.76x** below 2^53, where doubles stop representing integers
///     exactly.
///
/// The double version was in fact bit-exact on this dataset — relative error
/// measured at 0 for every ring, precisely because 5.12e15 < 2^53 — but the
/// margin was thin enough that a future release with larger rings could cross
/// it and start losing precision silently. Integer arithmetic has three orders
/// of magnitude more room and cannot degrade quietly.
///
/// It also makes [comparePrecedence] an integer comparison, so the ordering is
/// exact and transitive by construction rather than by argument.
///
/// Rings of fewer than three vertices enclose nothing and return zero.
int ringDoubledArea(Int32List ring) {
  final n = ring.length ~/ 2;
  if (n < 3) return 0;
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

/// Twice the area of a polygon: its outer ring less its holes.
///
/// Clamped at zero. A valid polygon's holes lie inside its outer ring and
/// cannot exceed it, but upstream geometry is not assumed to be valid, and a
/// negative area would invert the precedence rule.
int polygonDoubledArea(Int32List outer, List<Int32List> holes) {
  var area = ringDoubledArea(outer);
  for (final hole in holes) {
    area -= ringDoubledArea(hole);
  }
  return area < 0 ? 0 : area;
}

/// Orders two overlapping polygons by the precedence rule of plan §6.5.
///
/// Smallest area wins; ties break on identifier. Returns a negative number
/// when `a` takes precedence. Areas are the doubled integer values from
/// [polygonDoubledArea]; comparing doubled values is equivalent to comparing
/// areas.
///
/// ## Why the comparison is exact
///
/// An earlier version compared `double` areas with a *relative tolerance*, so
/// that a last-bit difference between two implementations of the shoelace sum
/// could not flip the ordering. That was the wrong fix for a real concern,
/// because **a tolerance-based comparator is not a valid total order.**
/// "Within tolerance" is not transitive: for `a = 1.0`, `b = 1.0 + 0.6e-9` and
/// `c = 1.0 + 1.2e-9` at a 1e-9 relative tolerance, `a` ties with `b` and `b`
/// ties with `c`, yet `a` sorts strictly before `c`. A comparator that
/// contradicts itself lets `List.sort` produce an arbitrary order, and here
/// that order decides which identifier is returned in a disputed territory.
///
/// The concern it addressed is now removed twice over: the area is an exact
/// integer, and there is a single implementation of it shared by the oracle
/// and the index builder. There is nothing left to reconcile, so the
/// comparison is exact — and integer ordering is transitive by construction.
int comparePrecedence(int areaA, String zoneA, int areaB, String zoneB) {
  final byArea = areaA.compareTo(areaB);
  if (byArea != 0) return byArea;
  return zoneA.compareTo(zoneB);
}
