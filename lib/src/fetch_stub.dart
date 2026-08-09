/// Stub fetch for non-web platforms.
library;

import 'boundaries_bin.dart';
import 'install.dart';

/// Always throws — fetch is only available on web.
Future<void> initializeBoundaries([String url = boundariesDefaultUrl]) async {
  throw BoundariesInitException(
    'initializeBoundaries requires a web platform (dart:js_interop). '
    'Use installBoundaries with bytes instead (url was $url).',
  );
}
