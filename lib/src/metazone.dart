/// English metazone display names and IANA-based abbreviations.
library;

import 'package:timezone/timezone.dart';

import 'data/metazone_data.dart';

export 'data/metazone_data.dart'
    show MetazoneLongNames, MetazoneRange, cldrVersion;

/// English display name for a [Location].
///
/// A metazone is CLDR's grouping of zones that share a display name: Paris,
/// Madrid and Zurich are all *Central European Time*.
extension MetazoneLocation on Location {
  /// Season-neutral English long name as of now (`generic ?? standard`), or
  /// `null` if CLDR has none for this zone.
  ///
  /// Does not reflect daylight saving — even in August, `Europe/Jersey` is
  /// *Greenwich Mean Time*. There is deliberately no abbreviation on
  /// [Location]: tzdb abbreviations are always standard or daylight. Use
  /// [MetazoneTZDateTime.metazoneAbbreviation] on a [TZDateTime] instead.
  String? get metazoneName {
    final names = mergedLongNames(
      name,
      DateTime.timestamp().millisecondsSinceEpoch,
    );
    return names.generic ?? names.standard;
  }
}

/// English labels for a [TZDateTime] at its instant.
extension MetazoneTZDateTime on TZDateTime {
  /// English long name at this instant from CLDR, or `null` if CLDR has none.
  ///
  /// Uses the daylight string when [TimeZone.isDst] is true (and returns
  /// `null` if that string is missing — no fallback to standard); otherwise
  /// `standard ?? generic`.
  String? get metazoneName {
    final names = mergedLongNames(location.name, millisecondsSinceEpoch);
    if (timeZone.isDst) return names.daylight;
    return names.standard ?? names.generic;
  }

  /// Abbreviation at this instant from tzdb — always a [String].
  ///
  /// Letter code (e.g. `CEST`), or `UTC±…` / `UTC` when tzdb's value is
  /// numeric. Never `null`, including for zones where [metazoneName] is.
  String get metazoneAbbreviation => formatZoneAbbreviation(timeZone);

  /// UTC offset at this instant as `UTC`, `UTC+04`, `UTC+04:30`, or `UTC-03`.
  ///
  /// Always the numeric form — never a letter code like `CEST`. Whole minutes:
  /// pre-standardisation offsets carry seconds that this format cannot show,
  /// so `Europe/Paris` in 1880 reads `UTC+00:09`, not `UTC+00:09:21`. Use
  /// `timeZoneOffset` for the exact [Duration]. For the signed gap to another
  /// place, see [TZDateTimeAcrossLocations.utcOffsetDifference].
  String get utcOffset => formatUtcOffset(timeZone.offset);
}

/// Zone-level long names overlaid on the metazone longs for [ianaId] at
/// [utcMilliseconds].
MetazoneLongNames mergedLongNames(String ianaId, int utcMilliseconds) {
  final cldrKey = ianaToCldrZoneKey[ianaId] ?? ianaId;
  final metazoneId = metazoneIdAt(cldrKey, utcMilliseconds);
  final zone = zoneLongNames[cldrKey] ?? zoneLongNames[ianaId];
  final meta = metazoneId == null ? null : metazoneLongNames[metazoneId];
  return MetazoneLongNames(
    generic: zone?.generic ?? meta?.generic,
    standard: zone?.standard ?? meta?.standard,
    daylight: zone?.daylight ?? meta?.daylight,
  );
}

/// Metazone id whose half-open UTC range contains [utcMilliseconds].
String? metazoneIdAt(String cldrZoneKey, int utcMilliseconds) {
  final ranges = zoneMetazoneHistory[cldrZoneKey];
  if (ranges == null) return null;
  for (final range in ranges) {
    final from = range.fromMs;
    final to = range.toMs;
    if (from != null && utcMilliseconds < from) continue;
    if (to != null && utcMilliseconds >= to) continue;
    return range.metazoneId;
  }
  return null;
}

/// Letter abbreviations unchanged; numeric ones become `UTC±…` / `UTC`.
String formatZoneAbbreviation(TimeZone zone) {
  final abbr = zone.abbreviation;
  if (abbr.isEmpty) return formatUtcOffset(zone.offset);
  if (abbr.startsWith('+') || abbr.startsWith('-')) {
    return formatUtcOffset(zone.offset);
  }
  return abbr;
}

/// Formats a UTC offset as `UTC`, `UTC+04`, `UTC+04:30`, or `UTC-03`.
///
/// Truncated to whole minutes. tzdb offsets carry leftover seconds before a
/// zone standardised — `Europe/Paris` in 1880 is `0:09:21`, printed here as
/// `UTC+00:09` — and this format has no seconds field. Truncating rather than
/// rounding keeps a 59-second remainder from inventing a minute that never
/// existed.
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
