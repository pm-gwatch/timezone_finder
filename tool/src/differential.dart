/// Differential testing: the runtime against the reference oracle.
///
/// Uniform sampling is nearly worthless here — most of the globe is ocean and
/// re-tests empty cells. The samplers below aim at the machinery that has
/// actually produced bugs in this project: quantization rounding, the
/// point-in-polygon edge convention, grid cell indexing, and the precedence
/// rule in overlap regions.
library;

import 'dart:math';

import '../../test/reference/reference_finder.dart';

/// What one sampler found.
class SamplerStats {
  int checked = 0;
  int landHits = 0;
  int disagreements = 0;
}

/// The outcome of a differential run.
class DifferentialReport {
  DifferentialReport(this.bySampler, this.examples);

  final Map<String, SamplerStats> bySampler;

  /// Up to a few dozen concrete disagreements, for diagnosis.
  final List<String> examples;

  int get checked =>
      bySampler.values.fold(0, (sum, stats) => sum + stats.checked);
  int get landHits =>
      bySampler.values.fold(0, (sum, stats) => sum + stats.landHits);
  int get disagreements =>
      bySampler.values.fold(0, (sum, stats) => sum + stats.disagreements);

  /// Samplers that never produced a point on land.
  ///
  /// A sampler with no land hits found nothing, whatever it reports about
  /// disagreements — that is how a sampler silently becomes a no-op.
  List<String> get barrenSamplers => <String>[
    for (final entry in bySampler.entries)
      if (entry.value.landHits == 0) entry.key,
  ];

  @override
  String toString() {
    final rows = <String>[
      'sampler         checked      land   disagreements',
      '-' * 50,
    ];
    for (final entry in bySampler.entries) {
      rows.add(
        '${entry.key.padRight(14)} '
        '${entry.value.checked.toString().padLeft(9)} '
        '${entry.value.landHits.toString().padLeft(9)} '
        '${entry.value.disagreements.toString().padLeft(9)}',
      );
    }
    rows
      ..add('-' * 50)
      ..add(
        '${'total'.padRight(14)} ${checked.toString().padLeft(9)} '
        '${landHits.toString().padLeft(9)} '
        '${disagreements.toString().padLeft(9)}',
      );
    return rows.join('\n');
  }
}

/// Compares [subject] against [oracle] over [points] sampled coordinates.
///
/// [overlapSeeds] are coordinates known to sit inside documented zone
/// overlaps; the run samples densely around them, which is the strongest
/// available check that the runtime's first-hit path and the oracle's
/// collect-then-sort path implement the same precedence rule.
DifferentialReport runDifferential({
  required ReferenceTimeZoneFinder oracle,
  required String? Function(double latitude, double longitude) subject,
  required int points,
  required int seed,
  required List<({double lat, double lon})> overlapSeeds,
  int cellSize = 1000000,
  void Function(String message)? progress,
}) {
  final random = Random(seed);
  final polygons = oracle.polygons;

  // Weighted toward the boundary samplers. Uniform coverage is cheap to state
  // and nearly free of information; points a few units from a real vertex are
  // where rounding, edge classification and cell indexing all meet.
  final withHoles = <ReferencePolygon>[
    for (final polygon in polygons)
      if (polygon.holes.isNotEmpty) polygon,
  ];

  final samplers = <String, ({double lat, double lon}) Function()>{
    'border': () => _nearVertex(random, polygons),
    'hole': () => _inHole(random, withHoles),
    'overlap': () => _nearSeed(random, overlapSeeds, 0.05),
    'cell-edge': () => _nearCellEdge(random, cellSize),
    'land': () => _nearVertex(random, polygons, spread: 20000),
    'seam': () => _nearSeam(random),
    'uniform': () => _uniform(random),
  };
  // 'hole' carries real weight despite holes being only 64,489 of 7.6M
  // vertices. Sampling proportionally would almost never enter one: a negative
  // control that disabled the hole test entirely went undetected across 20,000
  // points until this sampler existed.
  final weights = <String, int>{
    'border': 32,
    'overlap': 18,
    'hole': 15,
    'cell-edge': 13,
    'land': 12,
    'seam': 5,
    'uniform': 5,
  };
  final ladder = <String>[
    for (final entry in weights.entries)
      for (var i = 0; i < entry.value; i++) entry.key,
  ];

  final stats = <String, SamplerStats>{
    for (final name in samplers.keys) name: SamplerStats(),
  };
  final examples = <String>[];
  final report = DifferentialReport(stats, examples);

  final reportEvery = points < 100000 ? points : points ~/ 10;
  for (var i = 0; i < points; i++) {
    final name = ladder[random.nextInt(ladder.length)];
    final point = samplers[name]!();
    final entry = stats[name]!;
    entry.checked++;

    final expected = oracle.findId(point.lat, point.lon);
    if (expected != null) entry.landHits++;
    final actual = subject(point.lat, point.lon);
    if (actual != expected) {
      entry.disagreements++;
      if (examples.length < 40) {
        examples.add(
          '[$name] (${point.lat}, ${point.lon}): '
          'runtime ${actual ?? 'null'}, oracle ${expected ?? 'null'}',
        );
      }
    }

    if (progress != null && (i + 1) % reportEvery == 0) {
      progress(
        '  ${i + 1} of $points checked, '
        '${report.disagreements} disagreement(s)',
      );
    }
  }
  return report;
}

/// A point a short distance from a real polygon vertex.
///
/// [spread] is the maximum offset in quantized units. Defaults to a mixture of
/// scales so that some points land on the boundary itself, some a hair away,
/// and some clearly inside or outside.
({double lat, double lon}) _nearVertex(
  Random random,
  List<ReferencePolygon> polygons, {
  int? spread,
}) {
  final polygon = polygons[random.nextInt(polygons.length)];
  final ring = polygon.outer;
  final vertex = random.nextInt(ring.length ~/ 2);
  final scale =
      spread ?? const <int>[0, 1, 2, 10, 100, 5000][random.nextInt(6)];
  final x =
      ring[vertex * 2] + (scale == 0 ? 0 : random.nextInt(scale * 2) - scale);
  final y =
      ring[vertex * 2 + 1] +
      (scale == 0 ? 0 : random.nextInt(scale * 2) - scale);
  return _clamp(x, y);
}

/// A point in or near a polygon hole — an enclave such as Lesotho.
///
/// Half the samples land inside the hole's bounding box, which is mostly
/// inside the hole itself and must resolve to the enclave rather than the
/// surrounding zone; the rest sit a few units from a hole vertex, where the
/// inside/outside decision is finest.
({double lat, double lon}) _inHole(
  Random random,
  List<ReferencePolygon> withHoles,
) {
  if (withHoles.isEmpty) return _uniform(random);
  final polygon = withHoles[random.nextInt(withHoles.length)];
  final hole = polygon.holes[random.nextInt(polygon.holes.length)];
  if (hole.length < 2) return _uniform(random);

  if (random.nextBool()) {
    var minX = hole[0], maxX = hole[0], minY = hole[1], maxY = hole[1];
    for (var i = 0; i < hole.length; i += 2) {
      if (hole[i] < minX) minX = hole[i];
      if (hole[i] > maxX) maxX = hole[i];
      if (hole[i + 1] < minY) minY = hole[i + 1];
      if (hole[i + 1] > maxY) maxY = hole[i + 1];
    }
    return _clamp(
      minX + (maxX > minX ? random.nextInt(maxX - minX) : 0),
      minY + (maxY > minY ? random.nextInt(maxY - minY) : 0),
    );
  }

  final vertex = random.nextInt(hole.length ~/ 2);
  final spread = <int>[1, 2, 10, 100, 1000][random.nextInt(5)];
  return _clamp(
    hole[vertex * 2] + random.nextInt(spread * 2) - spread,
    hole[vertex * 2 + 1] + random.nextInt(spread * 2) - spread,
  );
}

({double lat, double lon}) _nearSeed(
  Random random,
  List<({double lat, double lon})> seeds,
  double spreadDegrees,
) {
  if (seeds.isEmpty) return _uniform(random);
  final seed = seeds[random.nextInt(seeds.length)];
  final spread = (spreadDegrees * 1000000).round();
  return _clamp(
    (seed.lon * 1000000).round() + random.nextInt(spread * 2) - spread,
    (seed.lat * 1000000).round() + random.nextInt(spread * 2) - spread,
  );
}

/// A point on, or one unit either side of, a grid cell boundary.
///
/// The grid is the newest code in the package, and its index clamps at the
/// array edges — a path nothing else exercises deliberately.
({double lat, double lon}) _nearCellEdge(Random random, int cellSize) {
  final columns = 360000000 ~/ cellSize;
  final rows = 180000000 ~/ cellSize;
  final x = -180000000 + random.nextInt(columns + 1) * cellSize;
  final y = -90000000 + random.nextInt(rows + 1) * cellSize;
  const nudge = <int>[-1, 0, 1];
  return _clamp(x + nudge[random.nextInt(3)], y + nudge[random.nextInt(3)]);
}

({double lat, double lon}) _nearSeam(Random random) {
  final y = random.nextInt(180000001) - 90000000;
  final x = <int>[
    180000000,
    -180000000,
    179999999,
    -179999999,
    179999995,
  ][random.nextInt(5)];
  return _clamp(x, y);
}

({double lat, double lon}) _uniform(Random random) => _clamp(
  random.nextInt(360000001) - 180000000,
  random.nextInt(180000001) - 90000000,
);

({double lat, double lon}) _clamp(int x, int y) => (
  lat: (y < -90000000 ? -90000000 : (y > 90000000 ? 90000000 : y)) / 1000000,
  lon:
      (x < -180000000 ? -180000000 : (x > 180000000 ? 180000000 : x)) / 1000000,
);
