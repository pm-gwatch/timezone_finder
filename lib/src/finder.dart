/// Top-level lookup API and the unexported [TimeZoneFinder] implementation.
library;

import 'dart:typed_data';

import 'package:timezone/timezone.dart';

import 'embedded_stub.dart'
    if (dart.library.io) 'embedded_io.dart'
    if (dart.library.js_interop) 'embedded_web.dart'
    as embedded;
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

/// Installs [bytes] as the isolate-wide shared index.
///
/// Used by the VM embedded path after decoding chunks, and by
/// [installBoundaries] on web after the app (or a fetch) supplies the `.bin`.
///
/// A second call with the same [TimeZoneIndex.dataVersion] is a no-op;
/// a different version replaces the installed index.
///
/// Throws [IndexFormatException] if [bytes] are not a valid container.
void installSharedIndex(Uint8List bytes) {
  final index = TimeZoneIndex.fromBytes(bytes);
  final existing = _bundledIndex;
  if (existing != null && existing.dataVersion == index.dataVersion) {
    return;
  }
  _decodes++;
  _bundledIndex = index;
}

/// The bundled index, decoded on first use.
///
/// One copy per isolate. Every default [TimeZoneFinder] (the top-level API's
/// singleton and any constructed in tests) reads this; [ensurePreloaded]
/// warms it for the whole isolate.
///
/// On web, the embedded loader throws until [installSharedIndex] has run
/// (via `installBoundaries` in `browser.dart`).
TimeZoneIndex get _sharedIndex {
  final existing = _bundledIndex;
  if (existing != null) return existing;
  installSharedIndex(embedded.loadContainer());
  return _bundledIndex!;
}

/// How many indexes this library has decoded in this isolate.
///
/// Not exported, and present only so the tests can prove the sharing above is
/// real rather than merely producing equal answers.
int get indexDecodeCount => _decodes;

TimeZoneFinder? _default;

/// The finder the top-level functions read through. One per isolate.
TimeZoneFinder get _defaultFinder => _default ??= TimeZoneFinder();

/// Package-internal: IANA identifier for ([longitude], [latitude]), or `null`.
///
/// Not exported from `package:timezone_finder/timezone_finder.dart`. Public
/// callers should use [findLocation] and read `Location.name` (the IANA id).
/// Kept here so [findLocation] can resolve the id before consulting tzdata,
/// and so package tests can assert the boundary lookup without initializing
/// `package:timezone`.
///
/// Argument order matches GeoJSON: longitude first, then latitude.
///
/// Where zones overlap — disputed territories, see the README — returns one
/// identifier by a documented deterministic rule: the smallest containing
/// polygon by planar area, then lexicographic identifier.
///
/// Throws [ArgumentError] if [longitude] is outside `-180 .. 180`, [latitude]
/// is outside `-90 .. 90`, or either is NaN or infinite.
String? findLocationName(double longitude, double latitude) =>
    _defaultFinder.findLocationName(longitude, latitude);

/// Returns the `package:timezone` [Location] containing
/// ([longitude], [latitude]), or `null` if no land time zone covers it.
///
/// Argument order matches GeoJSON: longitude first, then latitude.
/// `Location.name` is the IANA identifier (e.g. `'Europe/Paris'`).
///
/// ```dart
/// final paris = findLocation(2.3522, 48.8566)!;
/// paris.name; // 'Europe/Paris'
/// TZDateTime(paris, 2026, 8, 23, 17, 30);
/// ```
///
/// Where zones overlap — disputed territories — returns one of them by a fixed
/// rule: the smallest containing polygon, then the lexicographically first
/// identifier.
///
/// Throws [ArgumentError] on invalid coordinates. Throws [StateError] if
/// tzdata was never initialized, if that database lacks the resolved
/// identifier (boundary release vs the tzdata variant your app loaded — use
/// `latest_all`), or on web until boundaries are installed — see
/// `package:timezone_finder/browser.dart`.
Location? findLocation(double longitude, double latitude) =>
    _defaultFinder.findLocation(longitude, latitude);

/// Decodes the boundary index now rather than on the first lookup. Optional.
///
/// Worth calling at startup on a server: the index is decoded lazily and
/// **once per isolate**, so without this the first request handled by each
/// isolate pays for it. Calling it more than once is harmless.
///
/// On web, succeeds only after `installBoundaries` (or
/// `initializeBoundaries`); otherwise throws the same [StateError] as a
/// lookup before install.
///
/// Parses the index header only; polygon outlines are still decoded on
/// demand.
Future<void> ensurePreloaded() => _defaultFinder.ensurePreloaded();

/// The timezone-boundary-builder release these borders were built for,
/// e.g. `'2026c'` (named after the tzdb version it targets).
///
/// Unrelated to the tzdb version behind `package:timezone` in your app — that
/// one governs offsets and DST; this one governs where the borders are.
///
/// Reading this decodes the index if it has not been decoded yet — on web,
/// that means it throws [StateError] until the boundaries have been installed.
String get ianaDatabaseVersion => _defaultFinder.ianaDatabaseVersion;

/// Package-internal: every IANA identifier in the dataset, sorted.
///
/// Not exported from `package:timezone_finder/timezone_finder.dart`. These are
/// the strings [findLocation] can resolve (and that appear as `Location.name`).
/// Reading this decodes the index if it has not been decoded yet.
List<String> get availableLocationNames =>
    _defaultFinder.availableLocationNames;

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

  /// Boundary lookup used by [findLocation]. Not a public package API.
  String? findLocationName(double longitude, double latitude) {
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'must be in [-180, 180]',
      );
    }
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'must be in [-90, 90]');
    }
    return _resolved.lookup(
      quantizeQueryLongitude(longitude),
      quantize(latitude),
    );
  }

  /// Implements the top-level [findLocation], which documents the contract.
  Location? findLocation(double longitude, double latitude) {
    final identifier = findLocationName(longitude, latitude);
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
      // sends people. The "latest" tzdata drops the tzdb link identifiers and
      // carries 341 of our 419; "latest_all" carries every one. Both fixes
      // are named because the wrong variant is a deliberate import on the VM
      // but the *default* in browsers, where there is no import to change.
      throw StateError(
        'The boundary data resolved this coordinate to $identifier, but the '
        'initialized time zone database has no such location — it omits the '
        'tzdb link identifiers. On the VM, initialize from '
        'package:timezone/data/latest_all.dart rather than data/latest.dart. '
        'In a browser, pass the path explicitly: '
        "initializeTimeZone('packages/timezone/data/latest_all.tzf'), because "
        'the default fetches latest.tzf.',
      );
    }
  }

  /// Warms the index *every* default finder reads, not just this one.
  Future<void> ensurePreloaded() async => _resolved;

  /// The tzbb release this index was built from.
  String get ianaDatabaseVersion => _resolved.dataVersion;

  /// Every identifier in this index, sorted. Unmodifiable.
  List<String> get availableLocationNames => _resolved.zoneNames;
}
