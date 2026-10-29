/// Fetches the timezone-boundary-builder GeoJSON the reference oracle needs.
///
///     dart run tool/fetch_data.dart [--release 2026e]
///
/// Downloads ~51 MB and expands it to ~170 MB under `.dart_tool/`, which is
/// gitignored. Idempotent — re-running with the data already cached does
/// nothing. The oracle tests skip themselves when this has not been run, so
/// that a checkout without the data still has a green suite.
library;

import 'dart:io';

import 'src/fetch.dart';

Future<void> main(List<String> args) async {
  const usage = 'Usage: dart run tool/fetch_data.dart [--release <tag>]';
  var release = defaultRelease;
  for (var i = 0; i < args.length; i++) {
    final argument = args[i];
    final hasValue = i + 1 < args.length && !args[i + 1].startsWith('--');
    switch (argument) {
      case '--release' when hasValue:
        release = args[++i];
      case '-h' || '--help':
        stdout.writeln(usage);
        return;
      case '--release':
        stderr.writeln('Missing value for $argument.\n$usage');
        exitCode = 64;
        return;
      default:
        stderr.writeln('Unknown argument: $argument\n$usage');
        exitCode = 64;
        return;
    }
  }

  try {
    await ensureGeoJson(release: release, log: stdout.writeln);
  } on Object catch (error) {
    stderr.writeln('Fetch failed: $error');
    exitCode = 1;
  }
}
