/// Runs the Phase B differential gate.
///
///     dart run tool/differential.dart [--points 10000000] [--seed 1]
///
/// Plan §10.3 sets the exit criterion for milestone 7: ten million points, zero
/// disagreements between the runtime and the reference oracle. The oracle scans
/// every polygon linearly, so a full run takes minutes — which is why the
/// suite runs a smaller sample and this exists for the gate itself.
library;

import 'dart:io';

import '../test/fixtures/overlap_pins.dart';
import '../test/reference/reference_finder.dart';
import 'package:timezone_finder/timezone_finder.dart';

import 'src/differential.dart';
import 'src/fetch.dart';

Future<void> main(List<String> args) async {
  var points = 10000000;
  var seed = 1;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--points' && i + 1 < args.length) {
      points = int.parse(args[i + 1]);
    } else if (args[i] == '--seed' && i + 1 < args.length) {
      seed = int.parse(args[i + 1]);
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
  final runtime = TimeZoneFinder.exact();

  stdout.writeln('Comparing $points points (seed $seed) …');
  final started = DateTime.now();
  final report = runDifferential(
    oracle: oracle,
    subject: runtime.find,
    points: points,
    seed: seed,
    overlapSeeds: <({double lat, double lon})>[
      for (final pin in overlapPins) (lat: pin.latitude, lon: pin.longitude),
    ],
    progress: stdout.writeln,
  );
  final elapsed = DateTime.now().difference(started);

  stdout
    ..writeln('')
    ..writeln(report)
    ..writeln('')
    ..writeln('elapsed: ${elapsed.inSeconds}s');

  if (report.barrenSamplers.isNotEmpty) {
    stdout.writeln(
      'WARNING: samplers that never hit land, so proved nothing: '
      '${report.barrenSamplers.join(', ')}',
    );
  }
  if (report.examples.isNotEmpty) {
    stdout.writeln('\nfirst disagreements:');
    for (final line in report.examples) {
      stdout.writeln('  $line');
    }
  }

  if (report.disagreements == 0 && report.barrenSamplers.isEmpty) {
    stdout.writeln(
      '\nPASS — zero disagreements over ${report.checked} points, '
      '${report.landHits} of them on land.',
    );
  } else {
    stdout.writeln('\nFAIL');
    exitCode = 1;
  }
}
