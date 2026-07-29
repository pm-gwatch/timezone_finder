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

/// The exact index for tzbb 2026c, reassembled from 36 chunks.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'exact_000.dart' as c0;
import 'exact_001.dart' as c1;
import 'exact_002.dart' as c2;
import 'exact_003.dart' as c3;
import 'exact_004.dart' as c4;
import 'exact_005.dart' as c5;
import 'exact_006.dart' as c6;
import 'exact_007.dart' as c7;
import 'exact_008.dart' as c8;
import 'exact_009.dart' as c9;
import 'exact_010.dart' as c10;
import 'exact_011.dart' as c11;
import 'exact_012.dart' as c12;
import 'exact_013.dart' as c13;
import 'exact_014.dart' as c14;
import 'exact_015.dart' as c15;
import 'exact_016.dart' as c16;
import 'exact_017.dart' as c17;
import 'exact_018.dart' as c18;
import 'exact_019.dart' as c19;
import 'exact_020.dart' as c20;
import 'exact_021.dart' as c21;
import 'exact_022.dart' as c22;
import 'exact_023.dart' as c23;
import 'exact_024.dart' as c24;
import 'exact_025.dart' as c25;
import 'exact_026.dart' as c26;
import 'exact_027.dart' as c27;
import 'exact_028.dart' as c28;
import 'exact_029.dart' as c29;
import 'exact_030.dart' as c30;
import 'exact_031.dart' as c31;
import 'exact_032.dart' as c32;
import 'exact_033.dart' as c33;
import 'exact_034.dart' as c34;
import 'exact_035.dart' as c35;

/// The tzbb release this data was built from.
const String dataVersion = '2026c';

/// Size of the packed container, in bytes.
const int containerLength = 28152685;

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
    c6.chunk,
    c7.chunk,
    c8.chunk,
    c9.chunk,
    c10.chunk,
    c11.chunk,
    c12.chunk,
    c13.chunk,
    c14.chunk,
    c15.chunk,
    c16.chunk,
    c17.chunk,
    c18.chunk,
    c19.chunk,
    c20.chunk,
    c21.chunk,
    c22.chunk,
    c23.chunk,
    c24.chunk,
    c25.chunk,
    c26.chunk,
    c27.chunk,
    c28.chunk,
    c29.chunk,
    c30.chunk,
    c31.chunk,
    c32.chunk,
    c33.chunk,
    c34.chunk,
    c35.chunk,
  ]) {
    final bytes = base64.decode(chunk);
    container.setRange(offset, offset + bytes.length, bytes);
    offset += bytes.length;
  }
  return container;
}
