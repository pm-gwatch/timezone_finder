/// GeoJSON → [Location], [TZDateTime] → another clock, English CLDR labels
/// on both.
library;

import 'dart:convert';

import 'package:timezone/timezone.dart';

import '../generated/metazone_data.dart';
import 'location_finder.dart' as finder;

export '../generated/metazone_data.dart' show cldrVersion;

/// Resolves a geocoder's GeoJSON answer to a [Location].
extension GeoJsonLocation on String {
  /// Parses this GeoJSON string and resolves its Point to a [Location].
  ///
  /// Accepts an RFC 7946 `Feature` with a Point geometry, or a bare `Point`.
  /// Coordinates are `[longitude, latitude]` (optional altitude ignored).
  /// Returns `null` only when no land zone covers the point.
  ///
  /// Throws [FormatException] for malformed input, including a
  /// `FeatureCollection` (several places). Throws [ArgumentError] if longitude
  /// is outside `-180 .. 180` or latitude outside `-90 .. 90`. Same
  /// [StateError]s as a coordinate lookup.
  Location? findLocation() {
    final Object? decoded;
    try {
      decoded = jsonDecode(this);
    } on FormatException catch (error) {
      throw FormatException(
        'Expected a GeoJSON Feature or Point: ${error.message}',
        this,
        error.offset,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected a GeoJSON Feature or Point object', this);
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
      case 'FeatureCollection':
        throw FormatException(
          'Expected a GeoJSON Feature or Point, found FeatureCollection — '
          'a collection holds several places, so pick a feature first',
          this,
        );
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
  /// This same instant on [location]'s clock — the [Location] analogue of
  /// [TZDateTime.toUtc] and [TZDateTime.toLocal].
  ///
  /// ```dart
  /// final takeOff = TZDateTime(paris, 2026, 8, 23, 10, 15);
  /// takeOff.toLocation(newYork); // 04:15, the same moment
  /// ```
  ///
  /// The instant is preserved. To keep the wall clock and change the moment,
  /// construct a new [TZDateTime] with the other location.
  TZDateTime toLocation(Location location) => TZDateTime.from(this, location);

  /// Signed gap between this clock's offset and [location]'s at this
  /// instant (positive = [location] ahead).
  ///
  /// Not travel time and not [TZDateTime.difference]. Equals
  /// `toLocation(location).timeZoneOffset - timeZoneOffset`; use `.abs()` for
  /// a directionless magnitude.
  ///
  /// ```dart
  /// final call = TZDateTime(paris, 2026, 8, 3, 15);
  /// call.offsetDifference(tokyo); // 7 hours
  /// ```
  Duration offsetDifference(Location location) =>
      toLocation(location).timeZoneOffset - timeZoneOffset;
}

/// English display name for a [Location].
///
/// Paris, Madrid and Zurich share *Central European Time*: CLDR's
/// season-neutral label for that group.
extension LocationZoneNames on Location {
  /// Season-neutral English long name as of now, or `null` if CLDR has none.
  ///
  /// Generic when present (*Central European Time*). Else standard, but only
  /// if that group has no daylight name (*India Standard Time*). A DST group
  /// with no generic is not given the winter label all year. Zone-level summer
  /// overlays (*British Summer Time*) do not hide this label.
  ///
  /// Not DST-aware. No abbreviation on [Location] — use
  /// [TZDateTime.timeZoneName] at an instant.
  String? get timeZoneGenericName {
    // CLDR keeps dated metazone memberships; now picks the current one.
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    final lookup = _mergedLongNames(name, now);
    if (lookup.names.generic != null) return lookup.names.generic;
    if (lookup.meta?.daylight != null) return null;
    return lookup.names.standard;
  }
}

/// English labels for a [TZDateTime] at its instant.
extension TZDateTimeZoneNames on TZDateTime {
  /// English long name at this instant from CLDR, or `null` if CLDR has none.
  ///
  /// Uses the daylight string when [TimeZone.isDst] is true (and returns
  /// `null` if that string is missing — no fallback to standard); otherwise
  /// `standard ?? generic`. For a label that is never null, use
  /// `timeZoneLongName ?? utcOffsetLabel`.
  String? get timeZoneLongName {
    final names = _mergedLongNames(location.name, millisecondsSinceEpoch).names;
    if (timeZone.isDst) return names.daylight;
    return names.standard ?? names.generic;
  }

  /// Numeric UTC label at this instant. See [formatUtcOffset].
  ///
  /// Never a letter code like `CEST`. Use `timeZoneOffset` for the exact
  /// [Duration]; [TZDateTimeAcrossLocations.offsetDifference] for the gap to
  /// another place.
  String get utcOffsetLabel => formatUtcOffset(timeZoneOffset);
}

/// CLDR zone overlay plus the metazone record at [utcMilliseconds].
({MetazoneLongNames names, MetazoneLongNames? meta}) _mergedLongNames(
  String ianaId,
  int utcMilliseconds,
) {
  final cldrKey = ianaToCldrZoneKey[ianaId] ?? ianaId;
  final metazoneId = metazoneIdAt(cldrKey, utcMilliseconds);
  final zone = zoneLongNames[cldrKey] ?? zoneLongNames[ianaId];
  final meta = metazoneId == null ? null : metazoneLongNames[metazoneId];
  return (
    names: MetazoneLongNames(
      generic: zone?.generic ?? meta?.generic,
      standard: zone?.standard ?? meta?.standard,
      daylight: zone?.daylight ?? meta?.daylight,
    ),
    meta: meta,
  );
}

/// Metazone id whose half-open UTC range contains [utcMilliseconds].
String? metazoneIdAt(String cldrZoneKey, int utcMilliseconds) {
  final ranges = zoneMetazoneHistory[cldrZoneKey];
  if (ranges == null) return null;
  for (final range in ranges) {
    final start = range.start;
    final end = range.end;
    if (start != null && utcMilliseconds < start) continue;
    if (end != null && utcMilliseconds >= end) continue;
    return range.metazoneId;
  }
  return null;
}

/// Formats a UTC offset as `UTC`, `UTC+04`, `UTC+04:30`, or `UTC-03`.
///
/// Truncated to whole minutes. Pre-standardisation leftovers (Paris 1880
/// `0:09:21`) print as `UTC+00:09`. Truncating, not rounding, avoids inventing
/// a minute.
String formatUtcOffset(Duration duration) {
  // Driven off inMinutes so the truncation is visible rather than falling out
  // of the arithmetic below.
  final totalMinutes = duration.inMinutes;
  if (totalMinutes == 0) return 'UTC';
  final sign = totalMinutes.isNegative ? '-' : '+';
  final abs = totalMinutes.abs();
  final hours = abs ~/ 60;
  final minutes = abs % 60;
  final hourPart = hours.toString().padLeft(2, '0');
  if (minutes == 0) return 'UTC$sign$hourPart';
  final minutePart = minutes.toString().padLeft(2, '0');
  return 'UTC$sign$hourPart:$minutePart';
}
