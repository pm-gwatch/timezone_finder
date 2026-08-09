/// Shared install path used by [installBoundaries] on every platform.
library;

import 'dart:typed_data';

import 'finder.dart' show installSharedIndex;
import 'index.dart' show IndexFormatException;

export 'index.dart' show IndexFormatException;

/// Thrown when [initializeBoundaries] cannot fetch the index (or when it is
/// called off web).
class BoundariesInitException implements Exception {
  /// Creates an exception describing a failed boundary fetch/install.
  BoundariesInitException(this.message);

  /// Human-readable failure reason.
  final String message;

  @override
  String toString() => 'BoundariesInitException: $message';
}

/// Installs packed boundary bytes as the isolate-wide shared index.
///
/// Primary web API (Flutter `rootBundle`, CDN, tests). Corrupt bytes throw
/// [IndexFormatException]. Same data version again is a no-op; a different
/// version replaces the index.
void installBoundaries(Uint8List bytes) => installSharedIndex(bytes);
