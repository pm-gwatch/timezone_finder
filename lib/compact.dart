/// Offline time zone lookup with a much smaller download.
///
/// ```dart
/// import 'package:timezone_finder/compact.dart';
///
/// final finder = TimeZoneFinder();
/// finder.find(48.8566, 2.3522); // 'Europe/Paris'
/// ```
///
/// The API is identical to `package:timezone_finder/timezone_finder.dart`;
/// only the data differs. Boundaries here are simplified to roughly 110 m, so
/// the index is about a seventh the size and answers near a border can differ
/// from the full-fidelity tier. The measured disagreement rate is in the
/// README.
///
/// **Import one tier or the other, never both.** Each carries its own copy of
/// the data, and a `const` reachable from anything you import is in your
/// binary whether or not you call it.
///
/// Some very small islands and enclaves cannot survive simplification at this
/// tolerance and are absent here; those coordinates resolve to a neighbouring
/// zone or to `null`.
library;

import 'data/compact.dart' as data;
import 'src/finder.dart';

export 'src/finder.dart' show BaseTimeZoneFinder, IndexBytesProvider;
export 'src/index.dart' show IndexFormatException;

/// Maps coordinates to IANA identifiers using the simplified index.
class TimeZoneFinder extends BaseTimeZoneFinder {
  /// Creates a finder over the bundled simplified index.
  TimeZoneFinder({IndexBytesProvider? indexBytes})
    : super(indexBytes ?? data.loadContainer);
}
