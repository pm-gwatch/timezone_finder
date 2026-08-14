/// Oracle: every polygon, no index. Slow; never ships. Trust only after
/// `bootstrapGoldens`. Same [quantize] as the index — quantization_test
/// catches quantization bugs.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:timezone_finder/src/index/point_in_polygon.dart';
import 'package:timezone_finder/src/index/quantization.dart';

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

class ReferenceLocationFinder {
  ReferenceLocationFinder._(this.polygons, this.zones);

  /// Every polygon in the dataset, in source order.
  final List<ReferencePolygon> polygons;

  /// Every distinct identifier, sorted.
  final List<String> zones;

  /// Parses [geoJson] — the expanded `combined.json` of a tzbb release.
  ///
  /// Decodes as a stream so the ~170 MB of source is never materialised as a
  /// single Dart string, which would cost ~340 MB on its own.
  static Future<ReferenceLocationFinder> load(File geoJson) async {
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

    return ReferenceLocationFinder._(polygons, zones.toList()..sort());
  }

  /// IANA id containing ([longitude], [latitude]), or `null`.
  ///
  /// Overlaps: smallest planar area, then lexicographic id. Unlike the index
  /// (first pre-sorted hit), this collects all hits then chooses — same
  /// answer; [zonesContaining] is free.
  String? findLocationName(double longitude, double latitude) {
    _validate(longitude, latitude);
    final hits = _containing(longitude, latitude);
    if (hits.isEmpty) return null;
    hits.sort(comparePolygons);
    return hits.first.zone;
  }

  /// Every distinct identifier whose polygons contain the point, ordered by
  /// the same precedence [findLocationName] applies.
  ///
  /// A diagnostic for probing the documented overlap regions. This is **not**
  /// the `findAll()` public API, which is deferred.
  ///
  /// Argument order matches the public API: longitude first, then latitude.
  List<String> zonesContaining(double longitude, double latitude) {
    _validate(longitude, latitude);
    final hits = _containing(longitude, latitude)..sort(comparePolygons);
    final seen = <String>{};
    return <String>[
      for (final polygon in hits)
        if (seen.add(polygon.zone)) polygon.zone,
    ];
  }

  List<ReferencePolygon> _containing(double longitude, double latitude) {
    // Query longitudes are normalised so the antimeridian is one seam; stored
    // vertices are not. See quantizeQueryLongitude.
    final x = quantizeQueryLongitude(longitude);
    final y = quantize(latitude);
    return <ReferencePolygon>[
      for (final polygon in polygons)
        if (polygon.contains(x, y)) polygon,
    ];
  }

  static void _validate(double longitude, double latitude) {
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
    if (latitude.isNaN ||
        !latitude.isFinite ||
        latitude < -90 ||
        latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'must be in [-90, 90]');
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
