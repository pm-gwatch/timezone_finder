/// Embedded boundary loader for web — chunks are never linked here.
///
/// Call [installBoundaries] from `package:timezone_finder/browser.dart` (or
/// hand bytes to the shared install path) before any lookup.
library;

import 'dart:typed_data';

/// Always throws: web builds do not embed the base64 index chunks.
Uint8List loadContainer() {
  throw StateError(
    'Boundary data is not installed. Call installBoundaries(...) from '
    'package:timezone_finder/browser.dart before lookups.',
  );
}
