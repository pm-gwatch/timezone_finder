/// Embedded boundary loader for platforms with `dart:io` (VM, native).
library;

import 'dart:typed_data';

import 'data/boundaries.dart' as bundled;

/// Decodes the base64 chunk constants into one packed container.
Uint8List loadContainer() => bundled.loadContainer();
