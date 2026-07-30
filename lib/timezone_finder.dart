/// Offline lookup of the IANA time zone identifier for a coordinate on land.
///
/// ```dart
/// final finder = TimeZoneFinder.exact();
/// finder.find(48.8566, 2.3522); // 'Europe/Paris'
/// finder.find(0.0, -140.0);     // null — not inside any land zone
/// ```
///
/// Two tiers ship with the package, chosen at the constructor:
/// [TimeZoneFinder.exact] reproduces the published boundaries, and
/// [TimeZoneFinder.compact] simplifies them to roughly 110 m for a far smaller
/// binary. Only the tier you construct is compiled in.
///
/// The identifier is the whole answer. For UTC offsets, DST and civil-time
/// arithmetic, pass it to `package:timezone`.
library;

export 'src/finder.dart' show TimeZoneFinder;
export 'src/index.dart' show IndexFormatException;
