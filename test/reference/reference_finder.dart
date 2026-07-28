/// Phase A reference implementation — the correctness oracle.
///
/// This is deliberately the dumbest thing that can be correct: parse the
/// GeoJSON, keep every polygon, test them all. No spatial index, no encoding,
/// no size discipline. It is slow (a linear scan of 1,184 polygons per lookup)
/// and needs ~170 MB of source data, and it **never ships** — it exists only
/// in `test/`.
///
/// Its job is to be the authority the real index is validated against. It is
/// the only component whose correctness must be established by hand, which is
/// why it is short enough to review line by line.
///
/// ## Validation order
///
/// This oracle must pass `bootstrapGoldens` before it is trusted for anything
/// else. Those 66 pairs are the only ground truth in the package that does not
/// derive from timezone-boundary-builder data. Once it passes them, this
/// oracle — not the fixture file — becomes the authority for the wider golden
/// set and for differential testing.
///
/// ## Known blind spot: quantization
///
/// This oracle quantizes coordinates with the same [quantize] the index uses.
/// That is required — if the index compared quantized geometry and the oracle
/// compared raw doubles, points within ~11 cm of a border would legitimately
/// resolve differently, and the zero-disagreement gate at plan §10.3 could not
/// be met.
///
/// The cost is that **this oracle cannot catch a bug in quantization itself**.
/// A wrong scale, a wrong rounding mode, or a sign error on negative
/// coordinates would corrupt both sides identically and the differential test
/// would still pass. The bootstrap goldens cannot catch it either: all 66 are
/// deep inland, so an 11 cm shift cannot move any of them across a border.
///
/// Milestone 4's round-trip test is therefore the *only* guard on
/// quantization correctness, and it must exercise negative coordinates and
/// values that land near a half-unit boundary.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:timezone_finder/src/quantization.dart';

/// A polygon in quantized space: one outer ring, zero or more holes.
class ReferencePolygon {
  ReferencePolygon({
    required this.zone,
    required this.outer,
    required this.holes,
  })  : minX = _min(outer, 0),
        maxX = _max(outer, 0),
        minY = _min(outer, 1),
        maxY = _max(outer, 1),
        area = _netArea(outer, holes);

  /// The IANA identifier this polygon belongs to.
  final String zone;

  /// Outer ring, as interleaved `[x0, y0, x1, y1, …]` in quantized units,
  /// where x is longitude and y is latitude.
  final Int32List outer;

  /// Interior rings, same encoding. A point inside one of these is not inside
  /// the polygon.
  final List<Int32List> holes;

  /// Bounding box of [outer], for cheap rejection.
  final int minX, maxX, minY, maxY;

  /// Planar area in square quantized units, holes subtracted.
  ///
  /// This is the overlap tiebreak of plan §6.5 and carries no geographic
  /// meaning — it is distorted near the poles and ignores the ellipsoid. It
  /// only has to be stable and reproducible.
  final double area;

  bool _bboxContains(int x, int y) =>
      x >= minX && x <= maxX && y >= minY && y <= maxY;

  /// Whether ([x], [y]) in quantized units lies inside this polygon.
  bool contains(int x, int y) {
    if (!_bboxContains(x, y)) return false;
    if (!_pointInRing(outer, x, y)) return false;
    for (final hole in holes) {
      if (_pointInRing(hole, x, y)) return false;
    }
    return true;
  }
}

/// The Phase A oracle.
class ReferenceTimeZoneFinder {
  ReferenceTimeZoneFinder._(this.polygons, this.zones);

  /// Every polygon in the dataset, in source order.
  final List<ReferencePolygon> polygons;

  /// Every distinct identifier, sorted.
  final List<String> zones;

  /// Parses [geoJson] — the expanded `combined.json` of a tzbb release.
  ///
  /// Decodes as a stream so the ~170 MB of source is never materialised as a
  /// single Dart string, which would cost ~340 MB on its own.
  static Future<ReferenceTimeZoneFinder> load(File geoJson) async {
    final decoded = await geoJson
        .openRead()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .first;

    final root = decoded as Map<String, Object?>;
    final features = root['features']! as List<Object?>;

    final polygons = <ReferencePolygon>[];
    final zones = <String>{};

    for (final feature in features) {
      final map = feature! as Map<String, Object?>;
      final properties = map['properties']! as Map<String, Object?>;
      final zone = properties['tzid']! as String;
      zones.add(zone);

      final geometry = map['geometry']! as Map<String, Object?>;
      final type = geometry['type']! as String;
      final coordinates = geometry['coordinates']! as List<Object?>;

      // A Polygon is a list of rings; a MultiPolygon is a list of those.
      final parts = switch (type) {
        'Polygon' => <Object?>[coordinates],
        'MultiPolygon' => coordinates,
        _ => throw StateError('Unsupported geometry type "$type" for $zone'),
      };

      for (final part in parts) {
        final rings = (part! as List<Object?>).map(_quantizeRing).toList();
        if (rings.isEmpty) continue;
        polygons.add(
          ReferencePolygon(
            zone: zone,
            outer: rings.first,
            holes: rings.skip(1).toList(),
          ),
        );
      }
    }

    return ReferenceTimeZoneFinder._(
      polygons,
      zones.toList()..sort(),
    );
  }

  /// Returns the identifier containing ([latitude], [longitude]), or `null`
  /// when the coordinate is not inside any land polygon.
  ///
  /// Where polygons overlap — 25 pairs are documented upstream, mostly
  /// disputed territories — applies the precedence rule of plan §6.5: the
  /// smallest containing polygon by planar area, then lexicographic
  /// identifier.
  ///
  /// Unlike the real index, which sorts candidates and returns the first hit,
  /// this collects every containing polygon before choosing. Same answer, but
  /// hand-checkable, and it makes [zonesContaining] free.
  String? find(double latitude, double longitude) {
    _validate(latitude, longitude);
    final hits = _containing(latitude, longitude);
    if (hits.isEmpty) return null;
    hits.sort(comparePrecedence);
    return hits.first.zone;
  }

  /// Every distinct identifier whose polygons contain the point, ordered by
  /// the same precedence [find] applies.
  ///
  /// A diagnostic for probing the documented overlap regions. This is **not**
  /// the `findAll()` public API, which is deferred (plan §2.5).
  List<String> zonesContaining(double latitude, double longitude) {
    _validate(latitude, longitude);
    final hits = _containing(latitude, longitude)..sort(comparePrecedence);
    final seen = <String>{};
    return <String>[
      for (final polygon in hits)
        if (seen.add(polygon.zone)) polygon.zone,
    ];
  }

  List<ReferencePolygon> _containing(double latitude, double longitude) {
    final x = quantize(longitude);
    final y = quantize(latitude);
    return <ReferencePolygon>[
      for (final polygon in polygons)
        if (polygon.contains(x, y)) polygon,
    ];
  }

  static void _validate(double latitude, double longitude) {
    if (latitude.isNaN || !latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'must be in [-90, 90]');
    }
    if (longitude.isNaN ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'must be in [-180, 180]',
      );
    }
  }
}

/// Orders overlapping polygons by the precedence rule of plan §6.5.
///
/// Smallest planar area wins; ties break on identifier. Areas are compared
/// with a relative tolerance rather than for exact equality, so that a
/// last-bit difference in floating-point accumulation between this oracle and
/// the index builder cannot flip the ordering and manufacture a spurious
/// disagreement. Two genuinely distinct polygons are never within 1e-9
/// relative area of each other in this dataset; two implementations summing
/// the same shoelace terms can be.
int comparePrecedence(ReferencePolygon a, ReferencePolygon b) {
  final scale = math.max(a.area.abs(), b.area.abs());
  if ((a.area - b.area).abs() > 1e-9 * scale) {
    return a.area.compareTo(b.area);
  }
  return a.zone.compareTo(b.zone);
}

Int32List _quantizeRing(Object? ring) {
  final points = ring! as List<Object?>;
  final out = Int32List(points.length * 2);
  for (var i = 0; i < points.length; i++) {
    final point = points[i]! as List<Object?>;
    // GeoJSON is [longitude, latitude].
    out[i * 2] = quantize((point[0]! as num).toDouble());
    out[i * 2 + 1] = quantize((point[1]! as num).toDouble());
  }
  return out;
}

/// Even-odd ray casting in integer space.
///
/// Casts a ray in +x from the point and counts edge crossings. The usual
/// intersection formula is `xi + (py - yi) * (xj - xi) / (yj - yi)`; here it
/// is cross-multiplied to stay in integers, with the comparison flipped when
/// the edge runs downward so that multiplying by a negative preserves it.
///
/// Products reach ~1.3e17 for antipodal coordinates, inside the int64 range
/// of the Dart VM. This runs only in tests, never on the web.
bool _pointInRing(Int32List ring, int px, int py) {
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

/// Shoelace area of one ring, in square quantized units.
///
/// Vertices are translated by the ring's first point before accumulating, so
/// the products stay small relative to the coordinate magnitudes; the shoelace
/// formula is translation-invariant, so this changes nothing but the
/// numerics. Accumulation is in `double` because an exact integer sum would
/// overflow int64 for the largest rings.
double _ringArea(Int32List ring) {
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
double _netArea(Int32List outer, List<Int32List> holes) {
  var area = _ringArea(outer);
  for (final hole in holes) {
    area -= _ringArea(hole);
  }
  return area;
}

int _min(Int32List ring, int offset) {
  var value = ring[offset];
  for (var i = offset; i < ring.length; i += 2) {
    if (ring[i] < value) value = ring[i];
  }
  return value;
}

int _max(Int32List ring, int offset) {
  var value = ring[offset];
  for (var i = offset; i < ring.length; i += 2) {
    if (ring[i] > value) value = ring[i];
  }
  return value;
}
