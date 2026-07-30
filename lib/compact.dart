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
/// Import this library instead of `timezone_finder.dart`, not alongside it.
/// Both datasets are in the published archive either way; what gets compiled
/// into your program is whichever finder you construct. Constructing both
/// costs about 5.6 MB more than the exact tier alone.
///
/// Some very small islands and enclaves cannot survive simplification at this
/// tolerance and are absent here; those coordinates resolve to a neighbouring
/// zone or to `null`.
library;

export 'src/finder.dart'
    show BaseTimeZoneFinder, CompactTimeZoneFinder, IndexBytesProvider;
export 'src/index.dart' show IndexFormatException;
