/// Writes the packed index out as Dart source.
///
/// A pure Dart package cannot ship binary assets: `dart:io` is unavailable on
/// some targets, AOT binaries cannot read their own package directory, and
/// Flutter's asset system does not exist for CLI consumers (plan §4.3). So the
/// index travels as base64 inside `const` strings.
///
/// The chunking is a **compiler** concern, not a memory one. A single ~37 MB
/// string literal is hostile to the analyzer and to AOT; several smaller ones
/// are not. At load the chunks are concatenated back into one buffer, so the
/// reader's absolute offsets work unchanged and nothing has to cope with a
/// varint straddling a boundary.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// ODbL notice required on every generated data file by plan §4.5.
const String _dataLicenceHeader = '''
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
''';

/// What an emit produced.
typedef EmitResult = ({int chunks, int sourceBytes, int base64Bytes});

/// Writes [container] to [directory] as `<tier>_000.dart` … plus `<tier>.dart`
/// holding the provider that reassembles them.
///
/// [chunkBase64Chars] is the base64 length of each chunk, so the emitted
/// literals are all about that size regardless of how the binary divides.
EmitResult emitDartData({
  required Directory directory,
  required String tier,
  required Uint8List container,
  required String dataVersion,
  required int chunkBase64Chars,
}) {
  if (chunkBase64Chars % 4 != 0) {
    // base64 encodes three bytes per four characters. A chunk boundary off a
    // four-character group cannot be decoded on its own, which would force the
    // loader back to joining every chunk into one enormous string first.
    throw ArgumentError.value(
      chunkBase64Chars,
      'chunkBase64Chars',
      'must be a multiple of 4 so each chunk decodes independently',
    );
  }
  if (chunkBase64Chars % 4 != 0) {
    // base64 packs three bytes into four characters. A boundary off a
    // four-character group cannot be decoded alone, which would force the
    // loader to join every chunk into one enormous string first.
    throw ArgumentError.value(
      chunkBase64Chars,
      'chunkBase64Chars',
      'must be a multiple of 4 so each chunk decodes independently',
    );
  }
  directory.createSync(recursive: true);
  for (final stale in directory.listSync()) {
    if (stale is File && stale.path.contains('/${tier}_')) {
      stale.deleteSync();
    }
  }

  final encoded = base64.encode(container);
  final chunkCount = (encoded.length / chunkBase64Chars).ceil();
  var sourceBytes = 0;

  for (var i = 0; i < chunkCount; i++) {
    final start = i * chunkBase64Chars;
    final end = start + chunkBase64Chars < encoded.length
        ? start + chunkBase64Chars
        : encoded.length;
    final name = '${tier}_${i.toString().padLeft(3, '0')}';
    final file = File('${directory.path}/$name.dart');
    final source = StringBuffer()
      ..writeln(_dataLicenceHeader)
      ..writeln(
        '/// Chunk ${i + 1} of $chunkCount of the $tier index, '
        'tzbb $dataVersion.',
      )
      ..writeln('library;')
      ..writeln()
      ..writeln(
        '/// Base64 of bytes '
        '${(start ~/ 4) * 3}… of the packed container.',
      )
      ..writeln("const String chunk = '${encoded.substring(start, end)}';");
    file.writeAsStringSync(source.toString());
    sourceBytes += source.length;
  }

  final indexFile = File('${directory.path}/$tier.dart');
  final imports = <String>[
    for (var i = 0; i < chunkCount; i++)
      "import '${tier}_${i.toString().padLeft(3, '0')}.dart' as c$i;",
  ];
  final parts = <String>[for (var i = 0; i < chunkCount; i++) '  c$i.chunk,'];
  final source = StringBuffer()
    ..writeln(_dataLicenceHeader)
    ..writeln(
      '/// The $tier index for tzbb $dataVersion, reassembled from '
      '$chunkCount chunks.',
    )
    ..writeln('library;')
    ..writeln()
    ..writeln("import 'dart:convert';")
    ..writeln("import 'dart:typed_data';")
    ..writeln()
    ..writeAll(imports, '\n')
    ..writeln()
    ..writeln()
    ..writeln('/// The tzbb release this data was built from.')
    ..writeln("const String dataVersion = '$dataVersion';")
    ..writeln()
    ..writeln('/// Size of the packed container, in bytes.')
    ..writeln('const int containerLength = ${container.length};')
    ..writeln()
    ..writeln('/// Decoded container bytes.')
    ..writeln('///')
    ..writeln('/// The chunks exist so that no single string literal is large')
    ..writeln('/// enough to trouble the analyzer or the AOT compiler. They')
    ..writeln('/// carry no runtime meaning: the reader sees one flat buffer.')
    ..writeln('///')
    ..writeln('/// Each chunk decodes straight into its place in the output.')
    ..writeln('/// Joining them into one string first would be simpler to')
    ..writeln('/// write and would cost an extra ~37 MB of peak memory for an')
    ..writeln('/// intermediate discarded immediately. Chunk boundaries fall')
    ..writeln('/// on four-character base64 groups so this is possible.')
    ..writeln('Uint8List loadContainer() {')
    ..writeln('  final container = Uint8List(containerLength);')
    ..writeln('  var offset = 0;')
    ..writeln('  for (final chunk in const <String>[')
    ..writeAll(parts, '\n')
    ..writeln()
    ..writeln('  ]) {')
    ..writeln('    final bytes = base64.decode(chunk);')
    ..writeln('    container.setRange(offset, offset + bytes.length, bytes);')
    ..writeln('    offset += bytes.length;')
    ..writeln('  }')
    ..writeln('  return container;')
    ..writeln('}');
  indexFile.writeAsStringSync(source.toString());
  sourceBytes += source.length;

  return (
    chunks: chunkCount,
    sourceBytes: sourceBytes,
    base64Bytes: encoded.length,
  );
}
