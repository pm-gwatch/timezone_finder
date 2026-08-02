/// Offline lookup of the IANA time zone for a coordinate on land.
///
/// ```dart
/// final finder = TimeZoneFinder();
/// finder.findId(48.8566, 2.3522);        // 'Europe/Paris'
/// finder.findLocation(48.8566, 2.3522);  // a package:timezone Location
/// finder.findId(0.0, -140.0);            // null — not inside any land zone
/// ```
///
/// Boundaries are bundled, so lookups work offline with no network and no
/// setup. They are simplified to roughly 110 m — far finer than a time zone,
/// and small enough that the whole package is a few megabytes.
///
/// [TimeZoneFinder.findId] returns the identifier, which is what you store: it
/// stays correct when daylight-saving rules change under it.
/// [TimeZoneFinder.findLocation] and [TimeZoneLocation.toLocation] return a
/// `package:timezone` `Location`, which is what you render with. Both need
/// your application to have called `initializeTimeZones()`.
///
/// To show one instant in several places, [TZDateTimeInPlace.inPlaces] takes
/// coordinates and [TZDateTimeInLocation.inLocations] takes `Location`s.
library;

export 'src/finder.dart' show TimeZoneFinder;
export 'src/index.dart' show IndexFormatException;
export 'src/timezone_bridge.dart'
    show TZDateTimeInLocation, TZDateTimeInPlace, TimeZoneLocation;
