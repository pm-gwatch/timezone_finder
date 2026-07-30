/// Offline time zone lookup with a much smaller download.
///
/// ```dart
/// import 'package:timezone_finder/compact.dart';
///
/// final finder = CompactTimeZoneFinder();
/// finder.find(48.8566, 2.3522); // 'Europe/Paris'
/// ```
///
/// Boundaries are simplified to roughly 110 m, so the data is about a seventh
/// the size and answers near a border can differ from the full-fidelity tier.
/// The measured rates are in the README: away from borders the two agree on all
/// but 0.008 % of random land coordinates.
///
/// Importing this library instead of `timezone_finder.dart` is what keeps the
/// full-fidelity data out of your binary. Both are always present in the
/// published archive; only what you construct is compiled in.
///
/// Some very small islands and enclaves cannot survive simplification at this
/// tolerance and are absent here; those coordinates resolve to a neighbouring
/// zone or to `null`.
library;

export 'src/finder.dart'
    show BaseTimeZoneFinder, CompactTimeZoneFinder, IndexBytesProvider;
export 'src/index.dart' show IndexFormatException;
