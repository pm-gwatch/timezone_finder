/// The reference implementation — the correctness oracle.
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
/// resolve differently, and the zero-disagreement gate could not
/// be met.
///
/// The cost is that **this oracle cannot catch a bug in quantization itself**.
/// A wrong scale, a wrong rounding mode, or a sign error on negative
/// coordinates would corrupt both sides identically and the differential test
/// would still pass. The bootstrap goldens cannot catch it either: all 66 are
/// deep inland, so an 11 cm shift cannot move any of them across a border.
///
/// The round-trip test is therefore the *only* guard on
/// quantization correctness, and it must exercise negative coordinates and
/// values that land near a half-unit boundary.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:timezone_finder/src/point_in_polygon.dart';
import 'package:timezone_finder/src/quantization.dart';

import '../../tool/src/geometry.dart';

/// A polygon in quantized space: one outer ring, zero or more holes.
class ReferencePolygon {
  ReferencePolygon({
    required this.zone,
    required this.outer,
    required this.holes,
  }) : minX = _min(outer, 0),
       maxX = _max(outer, 0),
       minY = _min(outer, 1),
       maxY = _max(outer, 1),
       area = polygonDoubledArea(outer, holes);

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

  /// Twice the planar area in square quantized units, holes subtracted.
  ///
  /// This is the overlap tiebreak and carries no geographic
  /// meaning — it is distorted near the poles and ignores the ellipsoid. It
  /// only has to be stable and reproducible. Doubled so it stays an exact
  /// integer; see `polygonDoubledArea`.
  final int area;

  bool _bboxContains(int x, int y) =>
      x >= minX && x <= maxX && y >= minY && y <= maxY;

  /// Whether ([x], [y]) in quantized units lies inside this polygon.
  ///
  /// The bounding-box test is only an optimisation; containment itself is
  /// delegated to the shared [pointInPolygon] so the oracle and the index
  /// cannot drift apart on it.
  bool contains(int x, int y) {
    if (!_bboxContains(x, y)) return false;
    return pointInPolygon(outer, holes, x, y);
  }
}

/// The oracle.
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

    return ReferenceTimeZoneFinder._(polygons, zones.toList()..sort());
  }

  /// Returns the identifier containing ([latitude], [longitude]), or `null`
  /// when the coordinate is not inside any land polygon.
  ///
  /// Where polygons overlap — 25 pairs are documented upstream, mostly
  /// disputed territories — applies the overlap tiebreak: the
  /// smallest containing polygon by planar area, then lexicographic
  /// identifier.
  ///
  /// Unlike the real index, which sorts candidates and returns the first hit,
  /// this collects every containing polygon before choosing. Same answer, but
  /// hand-checkable, and it makes [zonesContaining] free.
  String? findTimeZoneName(double latitude, double longitude) {
    _validate(latitude, longitude);
    final hits = _containing(latitude, longitude);
    if (hits.isEmpty) return null;
    hits.sort(comparePolygons);
    return hits.first.zone;
  }

  /// Every distinct identifier whose polygons contain the point, ordered by
  /// the same precedence [findTimeZoneName] applies.
  ///
  /// A diagnostic for probing the documented overlap regions. This is **not**
  /// the `findAll()` public API, which is deferred.
  List<String> zonesContaining(double latitude, double longitude) {
    _validate(latitude, longitude);
    final hits = _containing(latitude, longitude)..sort(comparePolygons);
    final seen = <String>{};
    return <String>[
      for (final polygon in hits)
        if (seen.add(polygon.zone)) polygon.zone,
    ];
  }

  List<ReferencePolygon> _containing(double latitude, double longitude) {
    // Query longitudes are normalised so the antimeridian is one seam; stored
    // vertices are not. See quantizeQueryLongitude.
    final x = quantizeQueryLongitude(longitude);
    final y = quantize(latitude);
    return <ReferencePolygon>[
      for (final polygon in polygons)
        if (polygon.contains(x, y)) polygon,
    ];
  }

  static void _validate(double latitude, double longitude) {
    if (latitude.isNaN ||
        !latitude.isFinite ||
        latitude < -90 ||
        latitude > 90) {
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

/// Orders overlapping polygons by the overlap tiebreak.
///
/// Delegates to the shared [comparePrecedence] so the oracle and the index
/// builder cannot drift apart on the rule that decides disputed territories.
int comparePolygons(ReferencePolygon a, ReferencePolygon b) =>
    comparePrecedence(a.area, a.zone, b.area, b.zone);

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
