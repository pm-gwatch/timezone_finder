/// Regenerates both indexes from a timezone-boundary-builder release.
///
///     dart run tool/refresh.dart --release 2026c            # regenerate
///     dart run tool/refresh.dart --release 2026c --verify   # check only
///
/// Writes the bundled index to `lib/src/data/` and the unsimplified baseline
/// to `tool/release/`. The release is a parameter rather than "latest" so any
/// past one can be reproduced. Generated files are committed; consumers never
/// run this.
///
/// **Byte-identity is claimed only for the same release.** `--verify` asserts
/// that 2026c regenerates 2026c's committed bytes exactly. A different release
/// *should* produce different bytes — that is not corruption.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:timezone_finder/src/data/boundaries.dart' as bundled_container;
import 'release/boundaries_unsimplified.dart' as unsimplified_container;

import '../test/reference/reference_finder.dart';
import 'src/build_index.dart';
import 'src/emit_dart.dart';
import 'src/fetch.dart';
import 'src/geometry.dart';
import 'src/simplify.dart';

/// Identifiers of the release currently committed, for cheap triage.
File get _committedNames => File('tool/release/timezone-names.json');

Future<void> main(List<String> args) async {
  var release = defaultRelease;
  var verifyOnly = false;
  var chunkKb = 1024;
  var tolerance = 1000;
  var skipTests = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--release' when i + 1 < args.length:
        release = args[i + 1];
      case '--chunk-kb' when i + 1 < args.length:
        chunkKb = int.parse(args[i + 1]);
      case '--tolerance' when i + 1 < args.length:
        tolerance = int.parse(args[i + 1]);
      case '--verify':
        verifyOnly = true;
      case '--no-tests':
        skipTests = true;
      case '-h' || '--help':
        stdout.writeln(
          'Usage: dart run tool/refresh.dart '
          '[--release <tag>] [--verify] [--no-tests]',
        );
        return;
    }
  }

  stdout.writeln('=== timezone_finder refresh: $release ===\n');

  if (!await _triageRelease(release, verifyOnly: verifyOnly)) {
    exitCode = 1;
    return;
  }

  final cached = await ensureGeoJson(release: release, log: stdout.writeln);
  stdout.writeln('\nParsing boundaries …');
  final oracle = await ReferenceTimeZoneFinder.load(cached);
  stdout.writeln(
    '  ${oracle.zones.length} zones, '
    '${oracle.polygons.length} polygons',
  );

  final unsimplified = _pack(release: release, polygons: _sourceOf(oracle));
  final bundled = _pack(
    release: release,
    polygons: _simplified(oracle, tolerance),
  );

  if (verifyOnly) {
    final ok =
        _verify(
          'boundaries_unsimplified',
          unsimplified,
          unsimplified_container.loadContainer(),
        ) &&
        _verify('boundaries', bundled, bundled_container.loadContainer());
    if (!ok) {
      stdout.writeln(
        '\nFAIL — committed data does not match a rebuild of '
        '$release.',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('\nPASS — committed data reproduces $release exactly.');
    return;
  }

  stdout.writeln('\nEmitting Dart source …');
  for (final (name, container) in <(String, Uint8List)>[
    ('boundaries_unsimplified', unsimplified),
    ('boundaries', bundled),
  ]) {
    final result = emitDartData(
      directory: Directory(
        name == 'boundaries' ? 'lib/src/data' : 'tool/release',
      ),
      name: name,
      container: container,
      dataVersion: release,
      chunkBase64Chars: chunkKb * 1024,
    );
    stdout.writeln(
      '  $name: ${_mb(container.length)} in '
      '${result.chunks} chunk(s)',
    );
  }
  await _writeCommittedNames(release, oracle.zones);

  await _run('dart', <String>['format', 'lib/src/data']);
  if (!skipTests) {
    stdout.writeln(
      '\nRunning the suite — regenerated data must not land '
      'unverified …',
    );
    if (!await _run('dart', <String>['test'])) {
      stdout.writeln(
        '\nFAIL — tests did not pass against the regenerated '
        'data. Do not commit it.',
      );
      exitCode = 1;
      return;
    }
  }

  stdout
    ..writeln(
      '\nDone. Review `git diff --stat lib/src/data` before committing,',
    )
    ..writeln('and record the release in CHANGELOG.md.');
}

/// Compares the release's identifier list against the committed one.
///
/// A few kilobytes, fetched before the 51 MB archive, which is enough to say
/// whether a release can change any answer this package gives.
Future<bool> _triageRelease(String release, {required bool verifyOnly}) async {
  stdout.writeln('Triage — comparing identifiers against the committed set …');
  final url = Uri.https(
    'github.com',
    '/evansiroky/timezone-boundary-builder/releases/download/'
        '$release/timezone-names.json',
  );

  List<String> incoming;
  try {
    incoming = await _fetchNames(url);
  } on Object catch (error) {
    stdout.writeln('  could not fetch $url: $error');
    return false;
  }

  if (!_committedNames.existsSync()) {
    stdout.writeln(
      '  no committed baseline yet; recording ${incoming.length} '
      'identifiers',
    );
    return true;
  }

  final committed =
      json.decode(_committedNames.readAsStringSync()) as Map<String, Object?>;
  final committedRelease = committed['release'] as String;
  final committedList = <String>[
    for (final name in committed['names']! as List<Object?>) name! as String,
  ];

  stdout.writeln(
    '  committed data is $committedRelease, '
    'you asked for $release',
  );

  final added = incoming.toSet().difference(committedList.toSet()).toList()
    ..sort();
  final removed = committedList.toSet().difference(incoming.toSet()).toList()
    ..sort();

  if (added.isEmpty && removed.isEmpty) {
    stdout.writeln(
      '  identifier set unchanged (${incoming.length}) — any '
      'change is geometry only, so a patch release',
    );
  } else {
    stdout
      ..writeln(
        '  IDENTIFIER SET CHANGED — this can change answers users '
        'depend on. Minor release, and a changelog entry.',
      )
      ..writeln('    added:   ${added.isEmpty ? '(none)' : added.join(', ')}')
      ..writeln(
        '    removed: '
        '${removed.isEmpty ? '(none)' : removed.join(', ')}',
      );
    if (verifyOnly && committedRelease != release) {
      stdout.writeln(
        '  (--verify against a different release will fail by '
        'design; byte-identity is only claimed release-for-release)',
      );
    }
  }
  return true;
}

Future<List<String>> _fetchNames(Uri url) async {
  final client = HttpClient();
  try {
    var request = await client.getUrl(url);
    var response = await request.close();
    // GitHub redirects release assets to a CDN.
    var hops = 0;
    while (response.isRedirect && hops++ < 5) {
      final location = response.headers.value(HttpHeaders.locationHeader)!;
      await response.drain<void>();
      request = await client.getUrl(url.resolve(location));
      response = await request.close();
    }
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    final body = await response.transform(utf8.decoder).join();
    return <String>[
      for (final name in json.decode(body) as List<Object?>) name! as String,
    ];
  } finally {
    client.close();
  }
}

Future<void> _writeCommittedNames(String release, List<String> names) async {
  _committedNames.parent.createSync(recursive: true);
  _committedNames.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{'release': release, 'names': names})}\n',
  );
  stdout.writeln('  baseline updated: ${_committedNames.path}');
}

bool _verify(String name, List<int> rebuilt, List<int> committed) {
  if (rebuilt.length != committed.length) {
    stdout.writeln(
      '  $name: MISMATCH — rebuilt ${rebuilt.length} bytes, '
      'committed ${committed.length}',
    );
    return false;
  }
  for (var i = 0; i < rebuilt.length; i++) {
    if (rebuilt[i] != committed[i]) {
      stdout.writeln('  $name: MISMATCH — first difference at byte $i');
      return false;
    }
  }
  stdout.writeln('  $name: identical (${_mb(rebuilt.length)})');
  return true;
}

List<SourcePolygon> _sourceOf(ReferenceTimeZoneFinder oracle) =>
    <SourcePolygon>[
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
    ];

List<SourcePolygon> _simplified(ReferenceTimeZoneFinder oracle, int tolerance) {
  final stats = SimplifyStats();
  final out = <SourcePolygon>[];
  for (final p in oracle.polygons) {
    final simplified = simplifyPolygon(p.outer, p.holes, tolerance, stats);
    if (simplified == null) continue;
    out.add((
      zone: p.zone,
      // Recomputed: the precedence rule orders by area, and these polygons no
      // longer have the geometry the unsimplified areas describe.
      area: polygonDoubledArea(simplified.outer, simplified.holes),
      minX: _extent(simplified.outer, 0, min: true),
      maxX: _extent(simplified.outer, 0, min: false),
      minY: _extent(simplified.outer, 1, min: true),
      maxY: _extent(simplified.outer, 1, min: false),
      outer: simplified.outer,
      holes: simplified.holes,
    ));
  }
  stdout.writeln('  simplified: $stats');
  return out;
}

Uint8List _pack({
  required String release,
  required List<SourcePolygon> polygons,
}) => buildIndex(dataVersion: release, cellSize: 1000000, polygons: polygons);

int _extent(List<int> ring, int offset, {required bool min}) {
  var value = ring[offset];
  for (var i = offset; i < ring.length; i += 2) {
    if (min ? ring[i] < value : ring[i] > value) value = ring[i];
  }
  return value;
}

Future<bool> _run(String executable, List<String> arguments) async {
  stdout.writeln('\n\$ $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
  );
  return await process.exitCode == 0;
}

String _mb(int bytes) => '${(bytes / 1e6).toStringAsFixed(2)} MB';
