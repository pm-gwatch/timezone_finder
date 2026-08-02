/// Convenience extensions bridging coordinates and `package:timezone`.
library;

import 'package:timezone/timezone.dart';

import 'finder.dart';

/// Resolves a `"latitude,longitude"` string to a time zone.
extension TimeZoneLocation on String {
  /// Parses this as `"latitude,longitude"` and resolves it [using] a finder.
  ///
  /// ```dart
  /// '48.8566,2.3522'.toLocation();   // Europe/Paris
  /// '48.8566, 2.3522'.toLocation();  // same, spaces allowed
  /// ```
  ///
  /// **Latitude first.** GeoJSON orders coordinates the other way, and a
  /// swapped pair usually parses fine and returns a confidently wrong answer.
  ///
  /// [using] is only needed to read a non-default index; omitted, the call
  /// goes through the bundled boundaries every finder shares.
  ///
  /// Returns `null` only when no land time zone covers the point. Throws
  /// [FormatException] if this is not two comma-separated numbers, and
  /// whatever [TimeZoneFinder.findLocation] throws otherwise.
  Location? toLocation({TimeZoneFinder? using}) {
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
    return (using ?? TimeZoneFinder()).findLocation(latitude, longitude);
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

/// The same, for places given as `"latitude,longitude"` rather than resolved.
extension TZDateTimeInPlace on TZDateTime {
  /// This same instant, as the wall clock reads it where [coordinates] is.
  ///
  /// ```dart
  /// takeOff.inPlace('40.6413,-73.7781');  // 04:15, if takeOff is 10:15 Paris
  /// ```
  ///
  /// Shorthand for resolving the coordinate and calling
  /// [TZDateTimeInLocation.inLocation]. Returns `null` when no land time zone
  /// covers the point — which is why it is nullable and `inLocation` is not.
  ///
  /// Throws whatever [TimeZoneLocation.toLocation] throws: [FormatException]
  /// for text that is not two comma-separated numbers, [ArgumentError] for
  /// numbers that are not coordinates.
  TZDateTime? inPlace(String coordinates, {TimeZoneFinder? using}) {
    final location = coordinates.toLocation(using: using);
    return location == null ? null : TZDateTime.from(this, location);
  }

  /// This same instant at each of [coordinates], in the order given.
  ///
  /// ```dart
  /// meetingStart.inPlaces(['40.64,-73.77', '35.67,139.65']);
  /// ```
  ///
  /// **Entry `i` always corresponds to place `i`.** A coordinate no zone
  /// covers becomes a `null` in position rather than a missing element, so a
  /// gap cannot shift the entries after it.
  ///
  /// A coordinate that is not two numbers still throws, as [inPlace] does:
  /// unclaimed water is a result, a malformed string is a mistake.
  ///
  /// An empty list yields an empty list.
  List<TZDateTime?> inPlaces(
    List<String> coordinates, {
    TimeZoneFinder? using,
  }) => <TZDateTime?>[
    for (final each in coordinates) inPlace(each, using: using),
  ];
}
