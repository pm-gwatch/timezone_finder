/// Runs the differential gate.
///
///     dart run tool/differential.dart [--points 10000000] [--seed 1]
///         [--index bundled|unsimplified]
///
/// The release gate. Against `unsimplified` the bar is zero disagreements:
/// that index is the source geometry, so any difference is a pipeline defect.
/// Against `bundled` — what actually ships — disagreements are expected and
/// the run measures how many, since simplification is lossy by design.
///
/// The oracle scans every polygon linearly, so a full run takes minutes, which
/// is why the suite runs a smaller sample and this exists for the gate.
library;

import 'dart:io';

import '../test/fixtures/overlap_pins.dart';
import '../test/reference/reference_location_finder.dart';
import 'package:timezone_finder/src/location_finder.dart';

import 'package:timezone_finder/src/generated/boundaries.dart' as bundled;

import 'release/boundaries_unsimplified.dart' as unsimplified;

import 'src/differential.dart';
import 'src/fetch.dart';

Future<void> main(List<String> args) async {
  const usage =
      'Usage: dart run tool/differential.dart [--points <n>] [--seed <n>] '
      '[--index bundled|unsimplified]';
  var points = 10000000;
  var seed = 1;
  var index = 'unsimplified';
  for (var i = 0; i < args.length; i++) {
    final argument = args[i];
    final hasValue = i + 1 < args.length && !args[i + 1].startsWith('--');
    switch (argument) {
      case '--points' when hasValue:
        final parsed = int.tryParse(args[++i]);
        if (parsed == null || parsed <= 0) {
          stderr.writeln('--points needs an integer greater than 0.\n$usage');
          exitCode = 64;
          return;
        }
        points = parsed;
      case '--seed' when hasValue:
        final parsed = int.tryParse(args[++i]);
        if (parsed == null) {
          stderr.writeln('--seed needs an integer.\n$usage');
          exitCode = 64;
          return;
        }
        seed = parsed;
      case '--index' when hasValue:
        index = args[++i];
        if (index != 'bundled' && index != 'unsimplified') {
          stderr.writeln(
            '--index must be bundled or unsimplified, got $index.\n$usage',
          );
          exitCode = 64;
          return;
        }
      case '-h' || '--help':
        stdout.writeln(usage);
        return;
      case '--points' || '--seed' || '--index':
        stderr.writeln('Missing value for $argument.\n$usage');
        exitCode = 64;
        return;
      default:
        stderr.writeln('Unknown argument: $argument\n$usage');
        exitCode = 64;
        return;
    }
  }

  final cached = cachedGeoJsonFile(defaultRelease);
  if (!cached.existsSync()) {
    stderr.writeln('No cached data. Run: dart run tool/fetch_data.dart');
    exitCode = 1;
    return;
  }

  stdout.writeln('Loading reference oracle …');
  final oracle = await ReferenceLocationFinder.load(cached);
  final runtime = finderOverIndex(
    index == 'bundled' ? bundled.loadContainer : unsimplified.loadContainer,
  );
  stdout.writeln('Index under test: $index');

  stdout.writeln('Comparing $points points (seed $seed) …');
  final started = DateTime.now();
  final report = runDifferential(
    oracle: oracle,
    subject: runtime.findLocationName,
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
