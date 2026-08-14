/// Makes `package:timezone` easier to use: turn a place on Earth into the
/// [Location] it sits in, convert a [TZDateTime] from one [Location] to
/// another, and read English time zone labels.
///
/// ```dart
/// findLocation(2.3522, 48.8566);      // Europe/Paris Location — longitude, latitude
/// findLocation(2.3522, 48.8566)?.name; // 'Europe/Paris' — IANA identifier
/// findLocation(-140.0, 0.0);          // null — not inside any land zone
/// ```
///
/// Borders are simplified to ~110 m and embedded on VM / native / Flutter
/// mobile and desktop. **On web they are not:** import
/// `package:timezone_finder/browser.dart` only and install the `.bin` before
/// any lookup.
///
/// [findLocation] and [GeoJsonLocation.findLocation] return a `Location`
/// (store `Location.name`). Initialize **`latest_all`** tzdata first —
/// `initializeTimeZones()` on the VM, or
/// `initializeTimeZone('packages/timezone/data/latest_all.tzf')` on web.
/// Convert across places with [TZDateTimeAcrossLocations.toLocation].
/// On a server, call [ensurePreloaded] at isolate startup so the first
/// request is not the first decode.
library;

export 'src/api/location_finder.dart'
    show ensurePreloaded, findLocation, boundaryDataVersion;
export 'src/api/timezone_extensions.dart'
    show
        GeoJsonLocation,
        LocationZoneNames,
        TZDateTimeAcrossLocations,
        TZDateTimeZoneNames,
        cldrVersion;
