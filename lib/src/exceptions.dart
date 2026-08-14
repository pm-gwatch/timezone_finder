/// Shared public exceptions. Lives outside `api/` and `index/` so those
/// folders do not import each other.
library;

/// Thrown when a container cannot be trusted.
///
/// Documented failure of `installBoundaries`. Exported from `browser.dart`.
class IndexFormatException implements Exception {
  const IndexFormatException(this.message);

  final String message;

  @override
  String toString() => 'IndexFormatException: $message';
}

/// Thrown when [initializeBoundaries] cannot obtain a valid `.bin` (HTTP
/// error or wrong size).
class BoundariesInitException implements Exception {
  BoundariesInitException(this.message);

  final String message;

  @override
  String toString() => 'BoundariesInitException: $message';
}
