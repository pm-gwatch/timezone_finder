/// Offline lookup of the IANA time zone identifier for a coordinate on land.
///
/// ```dart
/// final finder = TimeZoneFinder();
/// finder.find(48.8566, 2.3522); // 'Europe/Paris'
/// finder.find(0.0, -140.0);     // null — not inside any land zone
/// ```
///
/// This is the full-fidelity index: boundaries exactly as
/// timezone-boundary-builder publishes them. For a much smaller download at
/// the cost of metre-level border accuracy, import
/// `package:timezone_finder/compact.dart` instead — never both, since each
/// carries its own copy of the data.
///
/// The identifier is the whole answer. For UTC offsets, DST and civil-time
/// arithmetic, pass it to `package:timezone`.
library;

import 'data/exact.dart' as data;
import 'src/finder.dart';

export 'src/finder.dart' show BaseTimeZoneFinder, IndexBytesProvider;
export 'src/index.dart' show IndexFormatException;

/// Maps coordinates to IANA identifiers using the full-fidelity index.
class TimeZoneFinder extends BaseTimeZoneFinder {
  /// Creates a finder over the bundled full-fidelity index.
  TimeZoneFinder({IndexBytesProvider? indexBytes})
    : super(indexBytes ?? data.loadContainer);
}
