/// Top-level lookup. [LocationFinder] is unexported.
library;

import 'dart:typed_data';

import 'package:timezone/timezone.dart';

import '../index/boundary_index.dart';
import '../index/boundary_store.dart';
import '../index/quantization.dart';

typedef _IndexSource = BoundaryIndex Function();

LocationFinder? _default;

/// The finder the top-level functions read through. One per isolate.
LocationFinder get _defaultFinder => _default ??= LocationFinder();

/// Returns the `package:timezone` [Location] containing
/// ([longitude], [latitude]), or `null` if no land time zone covers it.
///
/// Argument order matches GeoJSON: longitude first, then latitude.
/// `Location.name` is the IANA identifier. Overlaps: smallest containing
/// polygon, then lexicographic id.
///
/// Throws [ArgumentError] on invalid coordinates. Throws [StateError] if
/// tzdata is missing or incomplete (`latest_all`), or on web until boundaries
/// are installed (`package:timezone_finder/browser.dart`).
Location? findLocation(double longitude, double latitude) =>
    _defaultFinder.findLocation(longitude, latitude);

/// Decode the container and polygon table now (once per isolate). Rings stay
/// lazy. Harmless if called again. On web, requires `installBoundaries` first.
Future<void> ensurePreloaded() => _defaultFinder.ensurePreloaded();

/// Timezone-boundary-builder release for these borders (e.g. `'2026c'`).
/// Independent of the tzdb version behind `package:timezone`. Reading this
/// decodes the index; on web that requires `installBoundaries` first.
String get boundaryDataVersion => _defaultFinder.boundaryDataVersion;

/// Internal finder over arbitrary bytes (unsimplified baseline).
LocationFinder finderOverIndex(Uint8List Function() indexBytes) {
  BoundaryIndex? own;
  return LocationFinder._(() => own ??= decodeIndex(indexBytes));
}

/// Lookup bound to one index. Not exported; tests and the accuracy pipeline
/// hold a second finder beside the shared index.
class LocationFinder {
  /// A finder over the bundled boundaries, sharing one decoded index.
  factory LocationFinder() => LocationFinder._(() => sharedIndex);

  LocationFinder._(this._index);

  final _IndexSource _index;

  BoundaryIndex get _resolved => _index();

  /// IANA identifier for ([longitude], [latitude]), or `null`.
  ///
  /// Not public — apps use [findLocation] and `Location.name`. Same argument
  /// order and overlap rule as [findLocation]. Tests use this without tzdata.
  ///
  /// Throws [ArgumentError] if [longitude] is outside `-180 .. 180`,
  /// [latitude] is outside `-90 .. 90`, or either is NaN or infinite.
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
      // Not a boundary miss: `latest` omits 106 of this package's 419 ids
      // (it keeps 313). `latest_all` has every id. Named in the error
      // because VM imports `latest` on purpose, while browsers default to it.
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

  /// Loads this finder's index now.
  Future<void> ensurePreloaded() async => _resolved;

  String get boundaryDataVersion => _resolved.dataVersion;

  /// Every IANA identifier in this index, sorted. Unmodifiable. Not public.
  List<String> get availableLocationNames => _resolved.zoneNames;
}
