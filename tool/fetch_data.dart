/// Fetches the timezone-boundary-builder GeoJSON the reference oracle needs.
///
///     dart run tool/fetch_data.dart [--release 2026c]
///
/// Downloads ~51 MB and expands it to ~170 MB under `.dart_tool/`, which is
/// gitignored. Idempotent — re-running with the data already cached does
/// nothing. The oracle tests skip themselves when this has not been run, so
/// that a checkout without the data still has a green suite.
library;

import 'dart:io';

import 'src/fetch.dart';

Future<void> main(List<String> args) async {
  var release = defaultRelease;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--release' && i + 1 < args.length) {
      release = args[i + 1];
    } else if (args[i] == '-h' || args[i] == '--help') {
      stdout.writeln('Usage: dart run tool/fetch_data.dart [--release <tag>]');
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
