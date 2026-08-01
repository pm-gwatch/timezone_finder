/// The public lookup.
library;

import 'dart:typed_data';

import 'package:timezone/timezone.dart';

import '../data/compact.dart' as compact_data;
import '../data/exact.dart' as exact_data;
import 'index.dart';
import 'quantization.dart';

/// Supplies the packed index bytes.
///
/// Deliberately not exported. The factory constructors are the only ways to
/// build a finder, so callers never hold one of these — and never need to,
/// since the data ships with the package.
typedef _IndexBytes = Uint8List Function();

/// Maps geographic coordinates to IANA time zone identifiers.
///
/// Pick a tier when you construct one:
///
/// ```dart
/// final finder = TimeZoneFinder.exact();    // full-fidelity boundaries
/// final small = TimeZoneFinder.compact();   // ~110 m, far smaller binary
/// ```
///
/// Only the tier you construct is compiled into your program. Both are in the
/// published archive either way, so the constructor decides what you ship, not
/// what you download.
class TimeZoneFinder {
  TimeZoneFinder._(this._indexBytes);

  /// A finder over the full-fidelity index.
  ///
  /// Reproduces timezone-boundary-builder's published boundaries with no
  /// simplification, storing coordinates to 1e-6° — about 11 cm at the equator,
  /// and finer in longitude away from it.
  ///
  /// That figure is the *storage* resolution, not an accuracy claim. The
  /// boundaries derive from OpenStreetMap, whose own positional error is metres
  /// to tens of metres; the quantization is deliberately finer than the source
  /// so that it contributes nothing of its own.
  ///
  /// Costs roughly 32 MB of compiled binary over [TimeZoneFinder.compact].
  factory TimeZoneFinder.exact() => TimeZoneFinder._(exact_data.loadContainer);

  /// A finder over the simplified index.
  ///
  /// Boundaries are reduced by Douglas-Peucker at 1e-3° — about 110 m — which
  /// discards roughly seven eighths of the vertices. Away from borders the
  /// answers are almost always identical to [TimeZoneFinder.exact]; within a few
  /// hundred metres of one they often differ. The README publishes the measured
  /// rates.
  ///
  /// A handful of very small islands and enclaves cannot survive simplification
  /// and are absent here, so those coordinates resolve to a neighbouring zone
  /// or to `null`.
  factory TimeZoneFinder.compact() =>
      TimeZoneFinder._(compact_data.loadContainer);

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
