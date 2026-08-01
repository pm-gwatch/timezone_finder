/// Douglas-Peucker simplification of the bundled boundaries.
///
/// Build-time only. The bundled data trades border accuracy for download size:
/// dropping vertices that lie within a tolerance of the line between their
/// neighbours removes most of the coastline detail while leaving the shape
/// recognisable.
///
/// This is lossy by design and the loss is measured, not hoped about — see the
/// disagreement rate reported by `tool/measure_simplification.dart`.
library;

import 'dart:typed_data';

/// What simplifying a whole dataset cost.
class SimplifyStats {
  int ringsIn = 0;
  int ringsOut = 0;
  int verticesIn = 0;
  int verticesOut = 0;

  /// Polygons whose outer ring collapsed below three vertices and were
  /// dropped. Each is a small island that the bundled data cannot answer for.
  int polygonsDropped = 0;

  /// Holes that collapsed and were dropped. Each is an enclave that the
  /// bundled data folds into its surrounding zone.
  int holesDropped = 0;

  double get vertexRetention => verticesIn == 0 ? 0 : verticesOut / verticesIn;

  @override
  String toString() =>
      'vertices $verticesIn -> $verticesOut '
      '(${(100 * vertexRetention).toStringAsFixed(1)}%), '
      'rings $ringsIn -> $ringsOut, '
      '$polygonsDropped polygon(s) and $holesDropped hole(s) dropped';
}

/// Simplifies [ring] to within [tolerance] quantized units.
///
/// The first and last vertices are always kept, so a closed ring stays closed.
/// Returns the input unchanged when it has fewer than three vertices.
Int32List simplifyRing(Int32List ring, int tolerance) {
  final count = ring.length ~/ 2;
  if (count < 3) return ring;

  final keep = List<bool>.filled(count, false);
  keep[0] = true;
  keep[count - 1] = true;

  final toleranceSquared = tolerance.toDouble() * tolerance;
  final stack = <int>[0, count - 1];
  while (stack.isNotEmpty) {
    final end = stack.removeLast();
    final start = stack.removeLast();
    if (end <= start + 1) continue;

    final ax = ring[start * 2].toDouble();
    final ay = ring[start * 2 + 1].toDouble();
    final bx = ring[end * 2].toDouble();
    final by = ring[end * 2 + 1].toDouble();
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;

    var worst = -1.0;
    var worstAt = -1;
    for (var i = start + 1; i < end; i++) {
      final px = ring[i * 2].toDouble();
      final py = ring[i * 2 + 1].toDouble();
      double distanceSquared;
      if (lengthSquared == 0) {
        final ex = px - ax;
        final ey = py - ay;
        distanceSquared = ex * ex + ey * ey;
      } else {
        var t = ((px - ax) * dx + (py - ay) * dy) / lengthSquared;
        if (t < 0) t = 0;
        if (t > 1) t = 1;
        final ex = px - (ax + t * dx);
        final ey = py - (ay + t * dy);
        distanceSquared = ex * ex + ey * ey;
      }
      if (distanceSquared > worst) {
        worst = distanceSquared;
        worstAt = i;
      }
    }

    if (worst > toleranceSquared) {
      keep[worstAt] = true;
      stack
        ..add(start)
        ..add(worstAt)
        ..add(worstAt)
        ..add(end);
    }
  }

  var kept = 0;
  for (final flag in keep) {
    if (flag) kept++;
  }
  final out = Int32List(kept * 2);
  var at = 0;
  for (var i = 0; i < count; i++) {
    if (!keep[i]) continue;
    out[at * 2] = ring[i * 2];
    out[at * 2 + 1] = ring[i * 2 + 1];
    at++;
  }
  return out;
}

/// Simplifies one polygon, dropping rings that collapse.
///
/// Returns `null` when the outer ring no longer encloses anything — a small
/// island the bundled data simply cannot represent at this tolerance.
///
/// Simplification can in principle make a ring self-intersect. For an
/// deliberately approximate boundary that is tolerable: the effect is a
/// slightly wrong answer near a border, which is what simplification already
/// trades away and what the measured disagreement rate accounts for.
({Int32List outer, List<Int32List> holes})? simplifyPolygon(
  Int32List outer,
  List<Int32List> holes,
  int tolerance,
  SimplifyStats stats,
) {
  stats
    ..ringsIn += 1 + holes.length
    ..verticesIn += outer.length ~/ 2;
  for (final hole in holes) {
    stats.verticesIn += hole.length ~/ 2;
  }

  final simplifiedOuter = simplifyRing(outer, tolerance);
  if (simplifiedOuter.length ~/ 2 < 3) {
    stats.polygonsDropped++;
    return null;
  }

  final simplifiedHoles = <Int32List>[];
  for (final hole in holes) {
    final simplified = simplifyRing(hole, tolerance);
    if (simplified.length ~/ 2 < 3) {
      stats.holesDropped++;
      continue;
    }
    simplifiedHoles.add(simplified);
  }

  stats
    ..ringsOut += 1 + simplifiedHoles.length
    ..verticesOut += simplifiedOuter.length ~/ 2;
  for (final hole in simplifiedHoles) {
    stats.verticesOut += hole.length ~/ 2;
  }
  return (outer: simplifiedOuter, holes: simplifiedHoles);
}
