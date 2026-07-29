/// The public lookup.
library;

import 'dart:typed_data';

import 'index.dart';
import 'quantization.dart';

/// Supplies the packed index bytes.
///
/// Injectable so the runtime can be tested against a container built in
/// memory — which is how the format was exercised against the real dataset
/// before any generated source existed.
typedef IndexBytesProvider = Uint8List Function();

/// Maps geographic coordinates to IANA time zone identifiers.
///
/// Not constructed directly. Each entry library declares a `TimeZoneFinder`
/// bound to its own data — `package:timezone_finder/timezone_finder.dart` for
/// the full-fidelity index, `package:timezone_finder/compact.dart` for the
/// simplified one.
///
/// The split has to happen at import time rather than through a runtime flag.
/// A `const` referenced by the library you import is in your binary whether or
/// not you call anything, so a finder that could reach both datasets would
/// ship both.
class BaseTimeZoneFinder {
  /// Creates a finder over [indexBytes]. Cheap — the index is decoded lazily
  /// on first lookup.
  BaseTimeZoneFinder(IndexBytesProvider indexBytes) : _indexBytes = indexBytes;

  final IndexBytesProvider _indexBytes;
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

  /// Optional. Decodes the index ahead of time so the first [find] is not
  /// slower than the ones after it. Calling [find] without this works fine.
  ///
  /// Currently this parses the container and nothing more, which is honest
  /// rather than lazy: ring coordinates are decoded on demand by design, so
  /// there is nothing else to do ahead of time. Whether cold-start latency
  /// warrants moving the parse to an isolate is plan §13.2, and is deliberately
  /// left until milestone 8 measures it.
  Future<void> ensurePreloaded() async => _resolved;

  /// The tzbb release this index was built from, e.g. `'2026c'`.
  String get dataVersion => _resolved.dataVersion;

  /// Every identifier in the dataset, sorted. Unmodifiable.
  List<String> get availableTimeZones => _resolved.zoneNames;
}
