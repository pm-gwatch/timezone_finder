/// Offline lookup of the IANA time zone identifier for a coordinate on land.
///
/// ```dart
/// final finder = TimeZoneFinder();
/// finder.find(48.8566, 2.3522); // 'Europe/Paris'
/// finder.find(0.0, -140.0);     // null — not inside any land zone
/// ```
///
/// The identifier is the whole answer. For UTC offsets, DST and civil-time
/// arithmetic, pass it to `package:timezone`.
library;

export 'src/finder.dart' show IndexBytesProvider, TimeZoneFinder;
export 'src/index.dart' show IndexFormatException;
