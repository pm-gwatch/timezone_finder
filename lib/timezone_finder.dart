/// Makes `package:timezone` easier to use: turn a place on Earth into the
/// [Location] it sits in, convert a [TZDateTime] from one [Location] to
/// another, and read English metazone labels.
///
/// ```dart
/// findLocation(2.3522, 48.8566);      // Europe/Paris Location — longitude, latitude
/// findLocation(2.3522, 48.8566)?.name; // 'Europe/Paris' — IANA identifier
/// findLocation(-140.0, 0.0);          // null — not inside any land zone
/// ```
///
/// Boundaries are simplified to roughly 110 m — far finer than a time zone,
/// and small enough that the whole package is a few megabytes. On the VM,
/// native and Flutter mobile or desktop they are embedded in this library, so
/// lookups work offline with no network and no setup. **On web they are not**:
/// import `package:timezone_finder/browser.dart` and install the packed index
/// once before any lookup, or every call throws a [StateError] saying so.
///
/// [findLocation] and [GeoJsonLocation.toLocation] return a `package:timezone`
/// `Location` (store `Location.name` when you need the IANA identifier). Both
/// need your application to have initialized the **`latest_all`** tzdata first —
/// `initializeTimeZones()` from `package:timezone/data/latest_all.dart` on the
/// VM, or `await initializeTimeZone('packages/timezone/data/latest_all.tzf')`
/// from `package:timezone/browser.dart` on web, whose default path would
/// otherwise load a variant missing 106 of this package's 419 identifiers.
///
/// To show one instant in several places, resolve each place to a [Location]
/// — with [findLocation] from coordinates, or [GeoJsonLocation.toLocation]
/// from a geocoder's GeoJSON — then use [TZDateTimeAcrossLocations.convertTo].
///
/// The index is decoded lazily and **once per isolate**. On a server, call
/// [ensurePreloaded] at startup so no request pays for it.
library;

export 'src/finder.dart'
    show ensurePreloaded, findLocation, ianaDatabaseVersion;
export 'src/metazone.dart'
    show MetazoneLocation, MetazoneTZDateTime, cldrVersion;
export 'src/timezone_bridge.dart'
    show TZDateTimeAcrossLocations, GeoJsonLocation;
