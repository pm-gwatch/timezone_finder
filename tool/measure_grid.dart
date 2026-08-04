/// Measures the shortcut grid across resolutions.
///
///     dart run tool/measure_grid.dart
///
/// Chooses the grid resolution from evidence rather than taste. Grid size
/// trades against filter strength: coarse grids are small but
/// hand long candidate lists to point-in-polygon, fine grids are the reverse.
/// The table below is where that curve turns.
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../test/reference/reference_finder.dart';
import 'src/fetch.dart';
import 'src/grid.dart';

/// Cell sizes to compare, in quantized units. 1e6 is one degree.
const _resolutions = <int>[2000000, 1000000, 500000, 250000, 125000];

Future<void> main() async {
  final cached = cachedGeoJsonFile(defaultRelease);
  if (!cached.existsSync()) {
    stderr.writeln('No cached data. Run: dart run tool/fetch_data.dart');
    exitCode = 1;
    return;
  }

  stdout.writeln('Loading reference oracle …');
  final oracle = await ReferenceTimeZoneFinder.load(cached);
  final boxes = <PolygonBox>[
    for (var i = 0; i < oracle.polygons.length; i++)
      (
        id: i,
        minX: oracle.polygons[i].minX,
        maxX: oracle.polygons[i].maxX,
        minY: oracle.polygons[i].minY,
        maxY: oracle.polygons[i].maxY,
        area: oracle.polygons[i].area,
        zone: oracle.polygons[i].zone,
      ),
  ];
  stdout.writeln('${boxes.length} polygons\n');

  _checkNoBoxWrapsTheAntimeridian(boxes);

  stdout.writeln(
    'cell     cells      empty   occupied  lists   cand p50/p95/max   '
    'raw       gzipped',
  );
  stdout.writeln('-' * 92);

  for (final cellSize in _resolutions) {
    final spec = GridSpec(cellSize);
    final grid = buildGrid(spec, boxes);
    final emptyShare = 100 * grid.emptyCells / spec.cellCount;
    stdout.writeln(
      '${spec.degrees.toStringAsFixed(3).padLeft(6)}° '
      '${_count(spec.cellCount).padLeft(10)} '
      '${'${emptyShare.toStringAsFixed(1)}%'.padLeft(9)} '
      '${_count(grid.candidateCells).padLeft(10)} '
      '${_count(grid.distinctLists).padLeft(6)} '
      '${grid.percentileLength(50).toString().padLeft(5)}'
      '/${grid.percentileLength(95).toString().padLeft(4)}'
      '/${(grid.candidateLengths.isEmpty ? 0 : grid.candidateLengths.last).toString().padLeft(4)}  '
      '${_bytes(grid.serializedBytes).padLeft(9)} '
      '${_bytes(gzippedLength(grid.cells.buffer.asUint8List()) + gzippedLength(grid.pool)).padLeft(9)}',
    );
  }

  stdout.writeln(
    '\nFilter strength against a linear scan of ${boxes.length} '
    'polygons, sampled over land:',
  );
  for (final cellSize in _resolutions) {
    final spec = GridSpec(cellSize);
    final grid = buildGrid(spec, boxes);
    final sampled = _averageCandidatesOverLand(oracle, grid);
    stdout.writeln(
      '  ${spec.degrees.toStringAsFixed(3).padLeft(6)}°  '
      'mean ${sampled.mean.toStringAsFixed(1).padLeft(6)} candidates  '
      '(${(boxes.length / sampled.mean).toStringAsFixed(0).padLeft(4)}x fewer), '
      'worst ${sampled.worst}',
    );
  }
}

void _checkNoBoxWrapsTheAntimeridian(List<PolygonBox> boxes) {
  // Grid indexing treats a box as a plain interval in x, so a polygon whose
  // real extent crosses ±180 would be a problem: its box would claim all 360°
  // while the polygon occupies a sliver. tzbb splits such zones, but the index
  // depends on it, so it is checked rather than assumed.
  //
  // A box spanning every longitude is not automatically that case. A polygon
  // enclosing a pole genuinely occupies all longitudes, and its box is honest.
  // The two are distinguished by whether the box reaches the pole.
  final fullWidth = boxes.where(
    (b) => b.minX <= -179000000 && b.maxX >= 179000000,
  );
  final polar = fullWidth.where(
    (b) => b.minY <= -89000000 || b.maxY >= 89000000,
  );
  final wrapping = fullWidth.where(
    (b) => b.minY > -89000000 && b.maxY < 89000000,
  );

  for (final box in polar) {
    stdout.writeln(
      'polygon ${box.id} spans every longitude and reaches the '
      'pole — a polar cap, so the box is honest',
    );
  }
  if (wrapping.isEmpty) {
    stdout.writeln(
      'no polygon box wraps the antimeridian — grid indexing is '
      'a plain interval in x\n',
    );
  } else {
    stdout.writeln(
      'WARNING: ${wrapping.length} box(es) span every longitude '
      'without reaching a pole, which means a seam wrap; grid indexing '
      'assumes none do\n',
    );
  }
}

({double mean, int worst}) _averageCandidatesOverLand(
  ReferenceTimeZoneFinder oracle,
  BuiltGrid grid,
) {
  // Sampling uniformly over the globe would be dominated by empty ocean cells
  // and flatter the filter. Sample where the answers are instead: points that
  // actually resolve to a zone.
  var total = 0;
  var count = 0;
  var worst = 0;
  final random = Random(20260728);
  while (count < 4000) {
    final lat = random.nextInt(180000001) - 90000000;
    final lon = random.nextInt(360000001) - 180000000;
    if (oracle.findTimeZoneName(lat / 1000000, lon / 1000000) == null) continue;
    final candidates = grid.candidatesAt(lon, lat).length;
    total += candidates;
    if (candidates > worst) worst = candidates;
    count++;
  }
  return (mean: total / count, worst: worst);
}

String _count(int value) {
  final text = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) out.write(',');
    out.write(text[i]);
  }
  return out.toString();
}

String _bytes(int value) => value < 1000000
    ? '${(value / 1000).toStringAsFixed(0)} KB'
    : '${(value / 1000000).toStringAsFixed(2)} MB';

/// Compressed size, as an estimate of what the pub archive pays.
///
/// The grid is mostly long runs of identical values, which gzip removes almost
/// entirely, so the raw figure overstates the shipped cost by a wide margin.
int gzippedLength(Uint8List bytes) => gzip.encode(bytes).length;
