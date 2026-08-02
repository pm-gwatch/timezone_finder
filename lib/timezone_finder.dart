/// Offline lookup of the IANA time zone for a coordinate on land.
///
/// ```dart
/// findId(48.8566, 2.3522);        // 'Europe/Paris'
/// findLocation(48.8566, 2.3522);  // a package:timezone Location
/// findId(0.0, -140.0);            // null — not inside any land zone
/// ```
///
/// Boundaries are bundled, so lookups work offline with no network and no
/// setup. They are simplified to roughly 110 m — far finer than a time zone,
/// and small enough that the whole package is a few megabytes.
///
/// [findId] returns the identifier, which is what you store: it stays correct
/// when daylight-saving rules change under it. [findLocation] and
/// [TimeZoneLocation.toLocation] return a `package:timezone` `Location`, which
/// is what you render with. Both need your application to have called
/// `initializeTimeZones()`.
///
/// To show one instant in several places, [TZDateTimeInPlace.inPlaces] takes
/// coordinates and [TZDateTimeInLocation.inLocations] takes `Location`s.
///
/// The index is decoded lazily and **once per isolate**. On a server, call
/// [ensurePreloaded] at startup so no request pays for it.
library;

export 'src/finder.dart'
    show
        availableTimeZoneIds,
        ensurePreloaded,
        findId,
        findLocation,
        ianaDatabaseVersion;
export 'src/index.dart' show IndexFormatException;
export 'src/timezone_bridge.dart'
    show TZDateTimeInLocation, TZDateTimeInPlace, TimeZoneLocation;
