/// The failure type for untrustworthy container bytes.
///
/// Its own library because both halves of the reader raise it: [TimeZoneIndex]
/// while parsing the header and section tables, and `readRing` while decoding
/// coordinates during a lookup. `varint.dart` sits below `index.dart` in the
/// import graph, so the type cannot live in either of them.
library;

/// Thrown when a container cannot be trusted.
///
/// Reaches callers as the documented failure of `installBoundaries`, and is
/// exported from `package:timezone_finder/browser.dart` so an application can
/// tell bad data apart from a bad install.
class IndexFormatException implements Exception {
  /// Creates an exception describing why a container was rejected.
  const IndexFormatException(this.message);

  /// Human-readable reason.
  final String message;

  @override
  String toString() => 'IndexFormatException: $message';
}
