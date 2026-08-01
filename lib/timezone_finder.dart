/// Offline lookup of the IANA time zone for a coordinate on land.
///
/// ```dart
/// final finder = TimeZoneFinder.exact();
/// finder.find(48.8566, 2.3522);          // 'Europe/Paris'
/// finder.findLocation(48.8566, 2.3522);  // a package:timezone Location
/// finder.find(0.0, -140.0);              // null — not inside any land zone
/// ```
///
/// Two tiers ship with the package, chosen at the constructor:
/// [TimeZoneFinder.exact] reproduces the published boundaries, and
/// [TimeZoneFinder.compact] simplifies them to roughly 110 m for a far smaller
/// binary. Only the tier you construct is compiled in.
///
/// [find] returns the identifier, which is what you store: it stays correct
/// when daylight-saving rules change under it. [TimeZoneFinder.findLocation]
/// and [TimeZoneLocation.toLocation] return a `package:timezone` `Location`,
/// which is what you render with — pair it with
/// [TZDateTimeInLocation.inLocations] to show one instant in several places at
/// once. Both require your application to have called `initializeTimeZones()`.
library;

export 'src/finder.dart' show TimeZoneFinder;
export 'src/index.dart' show IndexFormatException;
export 'src/locations.dart' show TZDateTimeInLocation, TimeZoneLocation;
