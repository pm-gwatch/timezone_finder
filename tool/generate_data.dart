/// Generates the bundled index under `lib/data/`.
///
///     dart run tool/generate_data.dart [--chunk-kb 1024]
///
/// Fetches the boundary data if it is not cached, packs the container, and
/// writes it out as base64 Dart source. Maintainers run this; consumers never
/// do. Milestone 10 folds it into `tool/refresh.dart` along with the release
/// triage.
library;

import 'dart:io';

import '../test/reference/reference_finder.dart';
import 'src/build_index.dart';
import 'src/emit_dart.dart';
import 'src/fetch.dart';

Future<void> main(List<String> args) async {
  var chunkKb = 1024;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--chunk-kb' && i + 1 < args.length) {
      chunkKb = int.parse(args[i + 1]);
    }
  }

  final cached = await ensureGeoJson(log: stdout.writeln);

  stdout.writeln('Loading boundaries …');
  final oracle = await ReferenceTimeZoneFinder.load(cached);

  stdout.writeln('Packing the container …');
  final container = buildIndex(
    dataVersion: defaultRelease,
    cellSize: 1000000,
    polygons: <SourcePolygon>[
      for (final p in oracle.polygons)
        (
          zone: p.zone,
          area: p.area,
          minX: p.minX,
          maxX: p.maxX,
          minY: p.minY,
          maxY: p.maxY,
          outer: p.outer,
          holes: p.holes,
        ),
    ],
  );
  stdout.writeln('  container: ${_mb(container.length)}');

  stdout.writeln('Emitting Dart source ($chunkKb KB chunks) …');
  final result = emitDartData(
    directory: Directory('lib/data'),
    tier: 'exact',
    container: container,
    dataVersion: defaultRelease,
    chunkBase64Chars: chunkKb * 1024,
  );

  stdout
    ..writeln('  chunks:  ${result.chunks}')
    ..writeln('  base64:  ${_mb(result.base64Bytes)}')
    ..writeln('  source:  ${_mb(result.sourceBytes)}')
    ..writeln('')
    ..writeln('Now run: dart format lib/data && dart analyze');
}

String _mb(int bytes) => '${(bytes / 1e6).toStringAsFixed(2)} MB';
