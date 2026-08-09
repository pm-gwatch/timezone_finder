/// Stub embedded loader — selected only when neither io nor js_interop apply.
library;

import 'dart:typed_data';

/// Always throws; real platforms use a conditional import.
Uint8List loadContainer() {
  throw UnsupportedError(
    'No embedded boundary loader for this platform. Call installBoundaries '
    'from package:timezone_finder/browser.dart, or use a dart:io target.',
  );
}
