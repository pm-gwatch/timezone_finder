/// Web boundary loader — chunks are never linked here.
///
/// On web, install boundaries first (`package:timezone_finder/browser.dart`).
library;

import 'dart:typed_data';

/// Always throws: web builds do not embed the base64 index chunks.
Uint8List loadContainer() {
  throw StateError(
    'Boundary data is not installed. Call installBoundaries(...) from '
    'package:timezone_finder/browser.dart before lookups.',
  );
}
