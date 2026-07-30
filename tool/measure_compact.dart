/// Measures what the compact tier costs in accuracy.
///
///     dart run tool/measure_compact.dart [--points 2000000]
///
/// The compact tier simplifies boundaries to roughly 110 m, so it *will*
/// disagree with the full-fidelity index near borders — that is what
/// simplification means (plan §10.3). The number that matters is how often,
/// and where. A tier that disagreed away from borders would be a bug in
/// simplification rather than simplification working.
library;

import 'dart:io';

import 'package:timezone_finder/compact.dart' as compact;
import 'package:timezone_finder/timezone_finder.dart' as exact;

import '../test/fixtures/bootstrap_goldens.dart';
import '../test/fixtures/golden_points.dart';
import '../test/fixtures/overlap_pins.dart';
import '../test/reference/reference_finder.dart';
import 'src/differential.dart';
import 'src/fetch.dart';

Future<void> main(List<String> args) async {
  var points = 2000000;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--points' && i + 1 < args.length) {
      points = int.parse(args[i + 1]);
    }
  }

  final cached = cachedGeoJsonFile(defaultRelease);
  if (!cached.existsSync()) {
    stderr.writeln('No cached data. Run: dart run tool/fetch_data.dart');
    exitCode = 1;
    return;
  }

  stdout.writeln('Loading reference oracle …');
  final oracle = await ReferenceTimeZoneFinder.load(cached);
  final compactFinder = compact.CompactTimeZoneFinder();
  final exactFinder = exact.TimeZoneFinder();

  // --- the fixtures, which are ground truth for the exact tier only --------
  stdout.writeln(
    '\nGround-truth fixtures (the compact tier is measured '
    'against these, not gated by them):',
  );
  final byCategory = <String, ({int total, int missed})>{};
  final missedNames = <String>[];
  for (final point in <GoldenPoint>[...bootstrapGoldens, ...goldenPoints]) {
    final key = point.category.name;
    final current = byCategory[key] ?? (total: 0, missed: 0);
    final actual = compactFinder.find(point.latitude, point.longitude);
    final wrong = actual != point.zone;
    if (wrong) {
      missedNames.add(
        '${point.name}: ${point.zone ?? 'null'} -> ${actual ?? 'null'}',
      );
    }
    byCategory[key] = (
      total: current.total + 1,
      missed: current.missed + (wrong ? 1 : 0),
    );
  }
  for (final entry in byCategory.entries) {
    stdout.writeln(
      '  ${entry.key.padRight(13)} '
      '${entry.value.missed}/${entry.value.total} differ',
    );
  }
  if (missedNames.isNotEmpty) {
    stdout.writeln('\n  which ones:');
    for (final name in missedNames) {
      stdout.writeln('    $name');
    }
  }

  // --- overlap pins ---------------------------------------------------------
  var pinsDiffering = 0;
  for (final pin in overlapPins) {
    if (compactFinder.find(pin.latitude, pin.longitude) != pin.selected) {
      pinsDiffering++;
    }
  }
  stdout.writeln(
    '\noverlap pins differing: $pinsDiffering of '
    '${overlapPins.length}',
  );

  // --- the sampled rate -----------------------------------------------------
  stdout.writeln('\nSampling $points points …');
  final report = runDifferential(
    oracle: oracle,
    subject: compactFinder.find,
    points: points,
    seed: 9,
    overlapSeeds: <({double lat, double lon})>[
      for (final pin in overlapPins) (lat: pin.latitude, lon: pin.longitude),
    ],
  );
  stdout
    ..writeln('')
    ..writeln(report)
    ..writeln('');
  for (final entry in report.bySampler.entries) {
    final rate = 100 * entry.value.disagreements / entry.value.checked;
    stdout.writeln(
      '  ${entry.key.padRight(13)} '
      '${rate.toStringAsFixed(3)}% of its samples differ',
    );
  }
  final overall = 100 * report.disagreements / report.checked;
  stdout.writeln(
    '\noverall: ${overall.toStringAsFixed(3)}% of '
    '${report.checked} sampled points',
  );

  // A control: the exact tier over the same samplers must stay at zero, or the
  // rate above is measuring something other than simplification.
  stdout.writeln('\nControl — the exact tier over the same samplers:');
  final control = runDifferential(
    oracle: oracle,
    subject: exactFinder.find,
    points: points ~/ 10,
    seed: 9,
    overlapSeeds: <({double lat, double lon})>[
      for (final pin in overlapPins) (lat: pin.latitude, lon: pin.longitude),
    ],
  );
  stdout.writeln(
    '  ${control.disagreements} disagreement(s) over '
    '${control.checked} points',
  );
}
