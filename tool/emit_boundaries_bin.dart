/// One-shot: write `lib/data/boundaries_<ver>.bin` from the embedded chunks.
///
///     dart run tool/emit_boundaries_bin.dart
///
/// Maintainers normally get this from `tool/generate_data.dart` /
/// `tool/refresh.dart`; this exists so a `.bin` can be emitted without a full
/// rebuild from GeoJSON.
library;

import 'dart:io';

import 'package:timezone_finder/src/generated/boundaries.dart' as bundled;

import 'src/emit_dart.dart';

void main() {
  final container = bundled.loadContainer();
  final version = bundled.dataVersion;
  final binFile = File('lib/data/boundaries_$version.bin');
  emitBinaryData(file: binFile, container: container);
  emitBoundariesBinMeta(
    file: File('lib/src/generated/boundaries_bin.dart'),
    dataVersion: version,
    containerLength: container.length,
  );
  stdout.writeln(
    'Wrote ${binFile.path} (${container.length} bytes) and '
    'lib/src/generated/boundaries_bin.dart',
  );
}
