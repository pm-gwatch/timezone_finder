/// Convenience extensions bridging geocoded places and `package:timezone`.
library;

import 'dart:convert';

import 'package:timezone/timezone.dart';

import 'finder.dart' as finder;

/// Resolves a geocoder's GeoJSON answer to a [Location].
extension GeoJsonLocation on String {
  /// Parses this GeoJSON string and resolves its Point to a [Location].
  ///
  /// Accepts an RFC 7946 `Feature` with a Point geometry, or a bare `Point`.
  /// Coordinates are `[longitude, latitude]` (optional altitude ignored).
  ///
  /// ```dart
  /// const paris = '''{
  ///   "type": "Feature",
  ///   "geometry": {
  ///     "type": "Point",
  ///     "coordinates": [2.3522, 48.8566]
  ///   }
  /// }''';
  /// paris.toLocation(); // Europe/Paris
  /// ```
  ///
  /// Returns `null` only when no land zone covers the point. Throws
  /// [FormatException] for malformed input — including a `FeatureCollection`,
  /// which holds several points, so there is no single answer — and
  /// [ArgumentError] if longitude is outside `-180 .. 180` or latitude outside
  /// `-90 .. 90`.
  ///
  /// Throws [StateError] under the same conditions as a coordinate lookup:
  /// tzdata not initialized, or, on web, boundaries not installed.
  Location? toLocation() {
    final Object? decoded;
    try {
      decoded = jsonDecode(this);
    } on FormatException catch (error) {
      throw FormatException(
        'Expected a GeoJSON Feature: ${error.message}',
        this,
        error.offset,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected a GeoJSON Feature object', this);
    }
    final Map<String, dynamic> geometry;
    switch (decoded['type']) {
      case 'Feature':
        final wrapped = decoded['geometry'];
        if (wrapped is! Map<String, dynamic>) {
          throw FormatException('Feature has no geometry object', this);
        }
        geometry = wrapped;
      case 'Point':
        geometry = decoded;
      default:
        throw FormatException(
          'Expected a GeoJSON Feature or Point, '
          'found ${decoded['type']}',
          this,
        );
    }
    if (geometry['type'] != 'Point') {
      throw FormatException(
        'Expected a Point geometry, found ${geometry['type']}',
        this,
      );
    }

    final coordinates = geometry['coordinates'];
    if (coordinates is! List ||
        coordinates.length < 2 ||
        coordinates.length > 3) {
      throw FormatException(
        'Expected coordinates as [longitude, latitude] or '
        '[longitude, latitude, altitude]',
        this,
      );
    }
    final longitude = coordinates[0];
    final latitude = coordinates[1];
    if (longitude is! num || latitude is! num) {
      throw FormatException('Coordinates must be numbers', this);
    }

    return finder.findLocation(longitude.toDouble(), latitude.toDouble());
  }
}

/// Relates this instant to another place: its wall clock, and its offset.
extension TZDateTimeAcrossLocations on TZDateTime {
  /// This same instant, as the wall clock reads it in [location].
  ///
  /// ```dart
  /// final takeOff = TZDateTime(paris, 2026, 8, 23, 10, 15);
  /// takeOff.convertTo(newYork); // 04:15, the same moment
  /// ```
  ///
  /// The instant is preserved; only the zone, and therefore the wall clock,
  /// changes. To keep the wall clock and change the moment, construct a new
  /// [TZDateTime] with the other location instead.
  TZDateTime convertTo(Location location) => TZDateTime.from(this, location);

  /// Signed gap between this clock's UTC offset and [location]'s at this
  /// instant (positive = [location] ahead).
  ///
  /// Not travel time and not [TZDateTime.difference]. Equals
  /// `convertTo(location).timeZoneOffset - timeZoneOffset`; use `.abs()` for
  /// a directionless magnitude.
  ///
  /// ```dart
  /// final call = TZDateTime(paris, 2026, 8, 3, 15);
  /// call.utcOffsetDifference(tokyo); // 7 hours
  /// ```
  Duration utcOffsetDifference(Location location) =>
      convertTo(location).timeZoneOffset - timeZoneOffset;
}
