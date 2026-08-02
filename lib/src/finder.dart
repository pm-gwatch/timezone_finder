/// The public lookup.
library;

import 'dart:typed_data';

import 'package:timezone/timezone.dart';

import 'data/boundaries.dart' as bundled_data;
import 'index.dart';
import 'quantization.dart';

/// Supplies the index a finder reads.
typedef _IndexSource = TimeZoneIndex Function();

TimeZoneIndex? _bundledIndex;
int _decodes = 0;

/// Every decode routes through here, so [indexDecodeCount] cannot be bypassed
/// by one added elsewhere.
TimeZoneIndex _decode(Uint8List Function() bytes) {
  _decodes++;
  return TimeZoneIndex.fromBytes(bytes());
}

/// The bundled index, decoded on first use and shared by every
/// [TimeZoneFinder] built with the default constructor.
///
/// One copy per isolate. Holding several finders costs nothing beyond the
/// objects themselves, and `ensurePreloaded` on any of them warms the index
/// all of them read.
TimeZoneIndex get _sharedIndex {
  final existing = _bundledIndex;
  if (existing != null) return existing;
  return _bundledIndex = _decode(bundled_data.loadContainer);
}

/// How many indexes this library has decoded in this isolate.
///
/// Not exported, and present only so the tests can prove the sharing above is
/// real rather than merely producing equal answers.
int get indexDecodeCount => _decodes;

/// Builds a finder over an arbitrary index. Not exported, so not public API.
///
/// Exists for the unsimplified boundaries under `tool/release/`, which are the
/// baseline the bundled ones are measured against and do not ship. The finder
/// decodes its own index rather than the shared one, so both can be held at
/// once — which is how the accuracy numbers are produced.
TimeZoneFinder finderOverIndex(Uint8List Function() indexBytes) {
  TimeZoneIndex? own;
  return TimeZoneFinder._(() => own ??= _decode(indexBytes));
}

/// Maps geographic coordinates to IANA time zone identifiers.
///
/// ```dart
/// final finder = TimeZoneFinder();
/// finder.findId(48.8566, 2.3522);  // 'Europe/Paris'
/// ```
///
/// Boundaries are simplified to roughly 110 m, which is far finer than a time
/// zone and keeps the compiled program to about 11 MB. The README publishes
/// the measured cost of that simplification.
class TimeZoneFinder {
  /// A finder over the bundled boundaries.
  ///
  /// Cheap: every instance reads one shared index, decoded on first use.
  factory TimeZoneFinder() => TimeZoneFinder._(() => _sharedIndex);

  TimeZoneFinder._(this._index);

  final _IndexSource _index;

  TimeZoneIndex get _resolved => _index();

  /// Returns the IANA identifier containing ([latitude], [longitude]),
  /// e.g. `'Europe/Paris'`, or `null` if the coordinate is not inside any
  /// land time zone polygon.
  ///
  /// Where zones overlap — disputed territories, see the README — returns one
  /// identifier by a documented deterministic rule: the smallest containing
  /// polygon by planar area, then lexicographic identifier.
  ///
  /// Throws [ArgumentError] if [latitude] is outside `-90 .. 90`, [longitude]
  /// is outside `-180 .. 180`, or either is NaN or infinite.
  String? findId(double latitude, double longitude) {
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
  /// The identifier from [findId] is looked up in the time zone database your
  /// application initialized. Use it to build civil times:
  ///
  /// ```dart
  /// final paris = finder.findLocation(48.8566, 2.3522)!;
  /// TZDateTime(paris, 2026, 8, 23, 17, 30);
  /// ```
  ///
  /// Throws [ArgumentError] on the same coordinates [findId] rejects, and
  /// [StateError] if the database has not been initialized or does not contain
  /// the identifier — see [ianaDatabaseVersion] for why the two can disagree.
  Location? findLocation(double latitude, double longitude) {
    final identifier = findId(latitude, longitude);
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

  /// Optional. Decodes the index now rather than on the first [findId].
  ///
  /// Warms the index *every* default finder reads, not just this one, so it
  /// needs calling at most once per isolate. Ring coordinates are still
  /// decoded on demand by design, so this parses the container and no more.
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
