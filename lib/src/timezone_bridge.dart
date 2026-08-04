/// Convenience extensions bridging geocoded places and `package:timezone`.
library;

import 'dart:convert';

import 'package:timezone/timezone.dart';

import 'finder.dart' as finder;

/// Resolves a geocoded place to a time zone.
extension TimeZoneLocation on String {
  /// Parses this as a GeoJSON object naming one place, and resolves its Point
  /// to a [Location].
  ///
  /// Accepts either form RFC 7946 gives for a single place — a `Feature`
  /// carrying a Point, or a bare `Point` geometry:
  ///
  /// ```dart
  /// const paris = '{"type": "Feature", "geometry": '
  ///     '{"type": "Point", "coordinates": [2.3522, 48.8566]}}';
  /// const alsoParis = '{"type": "Point", "coordinates": [2.3522, 48.8566]}';
  ///
  /// paris.toLocation();     // Europe/Paris
  /// alsoParis.toLocation(); // the same
  /// ```
  ///
  /// The object must follow [RFC 7946](https://www.rfc-editor.org/rfc/rfc7946):
  /// `type` is `"Feature"` or `"Point"` — exactly, the values are
  /// case-sensitive — and the Point's `coordinates` are
  /// **`[longitude, latitude]`**, the reverse of the top-level `findLocation`.
  /// An optional third element is altitude and is ignored.
  ///
  /// You do not choose that order and cannot get it wrong: it arrives from the
  /// geocoder in the standard's layout. Unpacking it by hand is what this
  /// exists to avoid — a swapped pair does not throw, it resolves somewhere
  /// else entirely and answers confidently.
  ///
  /// **Ask the geocoder for GeoJSON.** Nominatim needs `&format=geojson`; its
  /// default `jsonv2` answers with `lat` and `lon` as top-level strings and
  /// will not parse here. Photon answers in GeoJSON already.
  ///
  /// Both return a `FeatureCollection`, which is several places and is
  /// rejected — choosing among matches is your decision, not this package's.
  /// Pass one feature, or just its geometry:
  ///
  /// ```dart
  /// final body = jsonDecode(responseBody) as Map<String, dynamic>;
  /// final feature = (body['features'] as List).first;
  /// final location = jsonEncode(feature).toLocation();
  /// ```
  ///
  /// Returns `null` only when no land time zone covers the point — every
  /// malformed input throws instead, so `null` is never ambiguous. Throws
  /// [FormatException] if this is not a Feature or Point carrying one
  /// position, and
  /// [ArgumentError] if the position is off the Earth. A non-finite
  /// coordinate raises [FormatException] rather than [ArgumentError]: JSON has
  /// no `NaN` literal, so it fails while being decoded.
  Location? toLocation() {
    final Object? decoded;
    try {
      decoded = jsonDecode(this);
    } on FormatException catch (error) {
      // Re-thrown with our own message: jsonDecode's names the syntax error
      // but not what the caller was trying to do.
      throw FormatException(
        'Expected a GeoJSON Feature: ${error.message}',
        this,
        error.offset,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected a GeoJSON Feature object', this);
    }
    // RFC 7946 §3: a GeoJSON object is a Geometry, a Feature, or a collection
    // of Features. Two of those name one place, so both are accepted; the
    // type member says which. Comparisons are exact — RFC 7946 type values
    // are case-sensitive.
    final Map<String, dynamic> geometry;
    switch (decoded['type']) {
      case 'Feature':
        final wrapped = decoded['geometry'];
        if (wrapped is! Map<String, dynamic>) {
          // A Feature may carry a null geometry per RFC 7946 §3.2 — valid
          // GeoJSON, but there is no point to resolve.
          throw FormatException('Feature has no geometry object', this);
        }
        geometry = wrapped;
      case 'Point':
        // A bare Point is the Feature's geometry without the metadata this
        // package ignores anyway.
        geometry = decoded;
      default:
        // A FeatureCollection is several places, and choosing among them is
        // the caller's decision, not ours.
        throw FormatException(
          'Expected a GeoJSON Feature or Point, '
          'found ${decoded['type']}',
          this,
        );
    }
    if (geometry['type'] != 'Point') {
      // Nominatim returns Polygon geometries when asked with
      // polygon_geojson=1; there is no single coordinate to answer for.
      throw FormatException(
        'Expected a Point geometry, found ${geometry['type']}',
        this,
      );
    }

    final coordinates = geometry['coordinates'];
    // RFC 7946 §3.1.1: a position is [longitude, latitude] with an optional
    // third altitude element, and SHOULD NOT be longer.
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

    // Longitude first, latitude second — the reverse of findLocation, and the
    // whole reason this parsing lives in the package rather than in every
    // caller. Range checking stays findLocation's, so a position off the Earth
    // raises ArgumentError exactly as a bad coordinate pair does.
    return finder.findLocation(latitude.toDouble(), longitude.toDouble());
  }
}

/// Re-expresses an instant in other places' time zones.
extension TZDateTimeInLocation on TZDateTime {
  /// This same instant, as the wall clock reads it in [location].
  ///
  /// ```dart
  /// final takeOff = TZDateTime(paris, 2026, 8, 23, 10, 15);
  /// takeOff.inLocation(newYork); // 04:15, the same moment
  /// ```
  ///
  /// The instant is preserved; only the zone, and therefore the wall clock,
  /// changes. To keep the wall clock and change the moment, construct a new
  /// [TZDateTime] with the other location instead.
  TZDateTime inLocation(Location location) => TZDateTime.from(this, location);

  /// This same instant in each of [locations], in the order given.
  ///
  /// ```dart
  /// meetingStart.inLocations([newYork, tokyo, sydney]);
  /// ```
  ///
  /// Every entry resolves — a place with no time zone cannot become a
  /// [Location] in the first place, so there are no gaps to account for. The
  /// receiver's own location is not included unless [locations] names it. An
  /// empty list yields an empty list.
  List<TZDateTime> inLocations(List<Location> locations) => <TZDateTime>[
    for (final location in locations) TZDateTime.from(this, location),
  ];
}
