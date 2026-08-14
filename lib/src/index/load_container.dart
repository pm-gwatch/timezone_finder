/// Default boundary loader: decode the shipped base64 chunks.
///
/// Selected everywhere except web. Web builds use load_container_web.dart
/// instead so the chunks are never linked.
library;

import 'dart:typed_data';

import '../generated/boundaries.dart' as bundled;

Uint8List loadContainer() => bundled.loadContainer();
