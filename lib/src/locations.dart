/// Convenience extensions bridging coordinates and `package:timezone`.
library;

import 'package:timezone/timezone.dart';

import 'finder.dart';

/// Resolves a `"latitude,longitude"` string to a time zone.
extension TimeZoneLocation on String {
  /// Parses this as `"latitude,longitude"` and resolves it [using] a finder.
  ///
  /// ```dart
  /// '48.8566,2.3522'.toLocation(using: finder);   // Europe/Paris
  /// '48.8566, 2.3522'.toLocation(using: finder);  // same, spaces allowed
  /// ```
  ///
  /// **Latitude first.** GeoJSON orders coordinates the other way, and a
  /// swapped pair usually parses fine and returns a confidently wrong answer.
  ///
  /// Required rather than defaulted, so the call uses the finder you already
  /// hold. A default would construct its own and decode a second copy of the
  /// index.
  ///
  /// Returns `null` only when no land time zone covers the point. Throws
  /// [FormatException] if this is not two comma-separated numbers, and
  /// whatever [TimeZoneFinder.findLocation] throws otherwise.
  Location? toLocation({required TimeZoneFinder using}) {
    final comma = indexOf(',');
    // Exactly one comma: '1,2,3' is a mistake, not a coordinate.
    if (comma < 0 || indexOf(',', comma + 1) >= 0) {
      throw FormatException(
        'Expected "latitude,longitude" with a single comma',
        this,
      );
    }
    final latitude = double.tryParse(substring(0, comma).trim());
    final longitude = double.tryParse(substring(comma + 1).trim());
    if (latitude == null || longitude == null) {
      throw FormatException(
        'Expected "latitude,longitude" as two numbers',
        this,
        latitude == null ? 0 : comma + 1,
      );
    }
    return using.findLocation(latitude, longitude);
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
  /// The receiver's own location is not included unless [locations] names it.
  /// An empty list yields an empty list.
  List<TZDateTime> inLocations(List<Location> locations) => <TZDateTime>[
    for (final location in locations) TZDateTime.from(this, location),
  ];
}
