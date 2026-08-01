/// The public lookup.
library;

import 'dart:typed_data';

import 'package:timezone/timezone.dart';

import '../data/boundaries.dart' as bundled_data;
import 'index.dart';
import 'quantization.dart';

/// Supplies the packed index bytes.
typedef _IndexBytes = Uint8List Function();

/// Builds a finder over an arbitrary index, for the build pipeline and the
/// tests.
///
/// Not exported from `package:timezone_finder/timezone_finder.dart`, so it is
/// not public API. It exists because the unsimplified boundaries under
/// `tool/release/` are the baseline the bundled ones are measured against, and
/// they do not ship.
TimeZoneFinder finderOverIndex(Uint8List Function() indexBytes) =>
    TimeZoneFinder._(indexBytes);

/// Maps geographic coordinates to IANA time zone identifiers.
///
/// ```dart
/// final finder = TimeZoneFinder();
/// finder.find(48.8566, 2.3522);  // 'Europe/Paris'
/// ```
///
/// Boundaries are simplified to roughly 110 m, which is far finer than a time
/// zone and keeps the compiled program to about 11 MB. The README publishes
/// the measured cost of that simplification.
class TimeZoneFinder {
  /// A finder over the bundled boundaries.
  factory TimeZoneFinder() => TimeZoneFinder._(bundled_data.loadContainer);

  TimeZoneFinder._(this._indexBytes);

  final _IndexBytes _indexBytes;
  TimeZoneIndex? _index;

  TimeZoneIndex get _resolved =>
      _index ??= TimeZoneIndex.fromBytes(_indexBytes());

  /// Returns the IANA identifier containing ([latitude], [longitude]),
  /// e.g. `'Europe/Paris'`, or `null` if the coordinate is not inside any
  /// land time zone polygon.
  ///
  /// Where zones overlap — disputed territories, see the README — returns one
  /// identifier by a documented deterministic rule: the smallest containing
  /// polygon by planar area, then lexicographic identifier.
  ///
  /// Throws [ArgumentError] if [latitude] is outside [-90, 90], [longitude] is
  /// outside [-180, 180], or either is NaN or infinite.
  String? find(double latitude, double longitude) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'must be in [-90, 90]');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'must be in [-180, 180]',
      );
    }
    return _resolved.lookup(
      quantizeQueryLongitude(longitude),
      quantize(latitude),
    );
  }

  /// Returns the `package:timezone` [Location] containing
  /// ([latitude], [longitude]), or `null` if no land time zone covers it.
  ///
  /// The identifier from [find] is looked up in the time zone database your
  /// application initialized. Use it to build civil times:
  ///
  /// ```dart
  /// final paris = finder.findLocation(48.8566, 2.3522)!;
  /// TZDateTime(paris, 2026, 8, 23, 17, 30);
  /// ```
  ///
  /// Throws [ArgumentError] on the same coordinates [find] rejects, and
  /// [StateError] if the database has not been initialized or does not contain
  /// the identifier — see [ianaDatabaseVersion] for why the two can disagree.
  Location? findLocation(double latitude, double longitude) {
    final identifier = find(latitude, longitude);
    if (identifier == null) return null;
    if (!timeZoneDatabase.isInitialized) {
      throw StateError(
        'The time zone database is not initialized, so $identifier cannot be '
        'resolved to a Location. Call initializeTimeZones() from '
        "package:timezone/data/latest_all.dart before using findLocation.",
      );
    }
    try {
      return getLocation(identifier);
    } on LocationNotFoundException {
      // Not a boundary-data problem, which is where the upstream message
      // sends people. data/latest.dart drops the tzdb link identifiers and
      // carries 341 of our 419; latest_all.dart carries every one.
      throw StateError(
        'The boundary data resolved this coordinate to $identifier, but the '
        'initialized time zone database has no such location. Initialize from '
        'package:timezone/data/latest_all.dart rather than data/latest.dart, '
        'which omits the tzdb link identifiers.',
      );
    }
  }

  /// Optional. Decodes the index ahead of time so the first [find] is not
  /// slower than the ones after it. Calling [find] without this works fine.
  ///
  /// Currently this parses the container and nothing more, which is honest
  /// rather than lazy: ring coordinates are decoded on demand by design, so
  /// there is nothing else to do ahead of time.
  Future<void> ensurePreloaded() async => _resolved;

  /// The IANA Time Zone Database version these boundaries were built for,
  /// e.g. `'2026c'`.
  ///
  /// Strictly this is the timezone-boundary-builder release tag, and tzbb names
  /// each release after the tzdb version it was built against. The sequences
  /// are not identical — tzbb skips tzdb releases that move no boundary, so
  /// there is no tzbb `2023a` or `2023c` — but every tag does name a real tzdb
  /// version.
  ///
  /// This says nothing about the tzdb version backing `package:timezone` in
  /// your application. That one governs UTC offsets and DST rules and is
  /// updated on its own schedule; this one governs where the borders are.
  String get ianaDatabaseVersion => _resolved.dataVersion;

  /// Every identifier in the dataset, sorted. Unmodifiable.
  List<String> get availableTimeZones => _resolved.zoneNames;
}
