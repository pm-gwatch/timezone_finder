/// Generates the bundled index under `lib/data/`.
///
///     dart run tool/generate_data.dart [--chunk-kb 1024]
///
/// Fetches the boundary data if it is not cached, packs the container, and
/// writes it out as base64 Dart source. Maintainers run this; consumers never
/// do — `tool/refresh.dart` wraps it with the release triage.
library;

import 'dart:io';
import 'dart:typed_data';

import '../test/reference/reference_finder.dart';
import 'src/build_index.dart';
import 'src/emit_dart.dart';
import 'src/geometry.dart';
import 'src/simplify.dart';
import 'src/fetch.dart';

Future<void> main(List<String> args) async {
  var chunkKb = 1024;
  var tier = 'both';
  // 1e-3 degrees, about 110 m. Measured as this as the point where the
  // coordinate blob falls to 3.89 MB.
  var tolerance = 1000;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--chunk-kb' && i + 1 < args.length) {
      chunkKb = int.parse(args[i + 1]);
    } else if (args[i] == '--tier' && i + 1 < args.length) {
      tier = args[i + 1];
    } else if (args[i] == '--tolerance' && i + 1 < args.length) {
      tolerance = int.parse(args[i + 1]);
    }
  }

  final cached = await ensureGeoJson(log: stdout.writeln);

  stdout.writeln('Loading boundaries …');
  final oracle = await ReferenceTimeZoneFinder.load(cached);

  if (tier == 'exact' || tier == 'both') {
    await _emitTier(
      name: 'exact',
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
      chunkKb: chunkKb,
    );
  }

  if (tier == 'compact' || tier == 'both') {
    stdout.writeln(
      '\nSimplifying at $tolerance units '
      '(~${(tolerance / 1000000 * 111000).round()} m) …',
    );
    final stats = SimplifyStats();
    final simplified = <SourcePolygon>[];
    for (final p in oracle.polygons) {
      final result = simplifyPolygon(p.outer, p.holes, tolerance, stats);
      if (result == null) continue;
      simplified.add((
        zone: p.zone,
        // Recomputed: simplification changes the shape, and the precedence
        // rule orders by area. Reusing the exact tier's areas would order the
        // compact tier's polygons by geometry it no longer has.
        area: polygonDoubledArea(result.outer, result.holes),
        minX: _min(result.outer, 0),
        maxX: _max(result.outer, 0),
        minY: _min(result.outer, 1),
        maxY: _max(result.outer, 1),
        outer: result.outer,
        holes: result.holes,
      ));
    }
    stdout.writeln('  $stats');
    await _emitTier(name: 'compact', polygons: simplified, chunkKb: chunkKb);
  }

  stdout.writeln('\nNow run: dart format lib/data && dart analyze');
}

Future<void> _emitTier({
  required String name,
  required List<SourcePolygon> polygons,
  required int chunkKb,
}) async {
  final container = buildIndex(
    dataVersion: defaultRelease,
    cellSize: 1000000,
    polygons: polygons,
  );
  final result = emitDartData(
    directory: Directory('lib/data'),
    tier: name,
    container: container,
    dataVersion: defaultRelease,
    chunkBase64Chars: chunkKb * 1024,
  );
  stdout.writeln(
    '  $name: ${polygons.length} polygons, '
    'container ${_mb(container.length)}, '
    '${result.chunks} chunk(s), source ${_mb(result.sourceBytes)}',
  );
}

int _min(Int32List ring, int offset) {
  var value = ring[offset];
  for (var i = offset; i < ring.length; i += 2) {
    if (ring[i] < value) value = ring[i];
  }
  return value;
}

int _max(Int32List ring, int offset) {
  var value = ring[offset];
  for (var i = offset; i < ring.length; i += 2) {
    if (ring[i] > value) value = ring[i];
  }
  return value;
}

String _mb(int bytes) => '${(bytes / 1e6).toStringAsFixed(2)} MB';
