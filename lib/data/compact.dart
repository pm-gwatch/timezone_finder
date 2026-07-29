// GENERATED FILE — DO NOT EDIT.
//
// Produced by tool/generate_data.dart from timezone-boundary-builder data.
//
// This file contains a derived database of time zone boundaries. It is
// licensed under the Open Data Commons Open Database License (ODbL) v1.0,
// NOT under the MIT licence that covers this package's source code.
// See LICENSE-DATA at the package root.
//
// Time zone boundary data © OpenStreetMap contributors, available under the
// Open Database License. Boundaries built by Timezone Boundary Builder
// (https://github.com/evansiroky/timezone-boundary-builder).

/// The compact index for tzbb 2026c, reassembled from 6 chunks.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'compact_000.dart' as c0;
import 'compact_001.dart' as c1;
import 'compact_002.dart' as c2;
import 'compact_003.dart' as c3;
import 'compact_004.dart' as c4;
import 'compact_005.dart' as c5;

/// The tzbb release this data was built from.
const String dataVersion = '2026c';

/// Size of the packed container, in bytes.
const int containerLength = 4202630;

/// Decoded container bytes.
///
/// The chunks exist so that no single string literal is large
/// enough to trouble the analyzer or the AOT compiler. They
/// carry no runtime meaning: the reader sees one flat buffer.
///
/// Each chunk decodes straight into its place in the output.
/// Joining them into one string first would be simpler to
/// write and would cost an extra ~37 MB of peak memory for an
/// intermediate discarded immediately. Chunk boundaries fall
/// on four-character base64 groups so this is possible.
Uint8List loadContainer() {
  final container = Uint8List(containerLength);
  var offset = 0;
  for (final chunk in const <String>[
    c0.chunk,
    c1.chunk,
    c2.chunk,
    c3.chunk,
    c4.chunk,
    c5.chunk,
  ]) {
    final bytes = base64.decode(chunk);
    container.setRange(offset, offset + bytes.length, bytes);
    offset += bytes.length;
  }
  return container;
}
