/// Offline lookup of the IANA time zone identifier for a coordinate on land.
///
/// ```dart
/// final finder = TimeZoneFinder();
/// finder.find(48.8566, 2.3522); // 'Europe/Paris'
/// finder.find(0.0, -140.0);     // null — not inside any land zone
/// ```
///
/// This is the full-fidelity index: boundaries exactly as
/// timezone-boundary-builder publishes them. For a much smaller binary at the
/// cost of metre-level border accuracy, import
/// `package:timezone_finder/compact.dart` instead.
///
/// Import one or the other. Both datasets are in the published archive either
/// way — the import decides which is compiled into your program, not what you
/// download. Constructing both `TimeZoneFinder` and `CompactTimeZoneFinder` in
/// one program costs about 5.6 MB more than the exact tier alone, for answers
/// that differ only within a few hundred metres of a border.
///
/// The identifier is the whole answer. For UTC offsets, DST and civil-time
/// arithmetic, pass it to `package:timezone`.
library;

export 'src/finder.dart'
    show BaseTimeZoneFinder, IndexBytesProvider, TimeZoneFinder;
export 'src/index.dart' show IndexFormatException;
