/// Top-level lookup API and the unexported [TimeZoneFinder] implementation.
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

/// The bundled index, decoded on first use.
///
/// One copy per isolate. Every default [TimeZoneFinder] (the top-level API's
/// singleton and any constructed in tests) reads this; [ensurePreloaded]
/// warms it for the whole isolate.
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

TimeZoneFinder? _default;

/// The finder the top-level functions read through. One per isolate.
TimeZoneFinder get _defaultFinder => _default ??= TimeZoneFinder();

/// Returns the IANA identifier containing ([latitude], [longitude]),
/// e.g. `'Europe/Paris'`, or `null` if the coordinate is not inside any land
/// time zone polygon.
///
/// ```dart
/// findId(48.8566, 2.3522);  // 'Europe/Paris'
/// findId(0.0, -140.0);      // null — open ocean
/// ```
///
/// This is the identifier to store: it stays correct when daylight-saving
/// rules change under it, where a stored UTC offset does not.
///
/// Where zones overlap — disputed territories, see the README — returns one
/// identifier by a documented deterministic rule: the smallest containing
/// polygon by planar area, then lexicographic identifier.
///
/// Throws [ArgumentError] if [latitude] is outside `-90 .. 90`, [longitude]
/// is outside `-180 .. 180`, or either is NaN or infinite.
String? findId(double latitude, double longitude) =>
    _defaultFinder.findId(latitude, longitude);

/// Returns the `package:timezone` [Location] containing
/// ([latitude], [longitude]), or `null` if no land time zone covers it.
///
/// ```dart
/// final paris = findLocation(48.8566, 2.3522)!;
/// TZDateTime(paris, 2026, 8, 23, 17, 30);
/// ```
///
/// Throws [ArgumentError] on the same coordinates [findId] rejects, and
/// [StateError] if your application has not called `initializeTimeZones()`,
/// or if the database it initialized lacks the identifier — see
/// [ianaDatabaseVersion] for why the two can disagree.
Location? findLocation(double latitude, double longitude) =>
    _defaultFinder.findLocation(latitude, longitude);

/// Optional. Decodes the boundary index now rather than on the first lookup.
///
/// Worth calling at startup on a server: the index is decoded lazily and
/// **once per isolate**, so without this the first request handled by each
/// isolate pays for it. Calling it more than once is harmless.
///
/// Ring coordinates are still decoded on demand by design, so this parses the
/// container and no more.
Future<void> ensurePreloaded() => _defaultFinder.ensurePreloaded();

/// The IANA Time Zone Database version these boundaries were built for,
/// e.g. `'2026c'`.
///
/// Strictly this is the timezone-boundary-builder release tag, and tzbb names
/// each release after the tzdb version it was built against. The sequences are
/// not identical — tzbb skips tzdb releases that move no boundary, so there is
/// no tzbb `2023a` or `2023c` — but every tag does name a real tzdb version.
///
/// This says nothing about the tzdb version backing `package:timezone` in your
/// application. That one governs UTC offsets and DST rules and is updated on
/// its own schedule; this one governs where the borders are.
///
/// Reading this decodes the index if it has not been decoded yet.
String get ianaDatabaseVersion => _defaultFinder.ianaDatabaseVersion;

/// Every IANA identifier in the dataset, sorted. Unmodifiable.
///
/// These are the strings [findId] can return, not `package:timezone`
/// `TimeZone` objects. Reading this decodes the index if it has not been
/// decoded yet.
List<String> get availableTimeZoneIds => _defaultFinder.availableTimeZoneIds;

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

/// A lookup bound to one index.
///
/// Not exported: the public API is the top-level functions above, which read
/// through a shared instance of this. It exists so [finderOverIndex] has
/// something to return — the tests and the accuracy pipeline hold a finder
/// over the unsimplified baseline alongside the bundled one.
class TimeZoneFinder {
  /// A finder over the bundled boundaries, sharing one decoded index.
  factory TimeZoneFinder() => TimeZoneFinder._(() => _sharedIndex);

  TimeZoneFinder._(this._index);

  final _IndexSource _index;

  TimeZoneIndex get _resolved => _index();

  /// Implements the top-level `findId`, which documents the contract.
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

  /// Implements the top-level `findLocation`, which documents the contract.
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

  /// Warms the index *every* default finder reads, not just this one.
  Future<void> ensurePreloaded() async => _resolved;

  /// The tzbb release this index was built from.
  String get ianaDatabaseVersion => _resolved.dataVersion;

  /// Every identifier in this index, sorted. Unmodifiable.
  List<String> get availableTimeZoneIds => _resolved.zoneNames;
}
