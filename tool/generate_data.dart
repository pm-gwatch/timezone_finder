/// Generates — or verifies — the indexes as base64 Dart source.
///
///     dart run tool/generate_data.dart [--release 2026c] [--tolerance 1000]
///         [--chunk-kb 1024] [--emit bundled|unsimplified|both] [--verify]
///
/// The bundled index goes to `lib/src/data/` and ships; the unsimplified
/// baseline goes to `tool/release/` and does not. `--verify` rebuilds both and
/// compares them against what is committed, writing nothing.
///
/// Maintainers run this; consumers never do. `tool/refresh.dart` wraps it with
/// the release triage, the CLDR refresh and the test suite — use that for a
/// release bump, and this directly to re-emit at a release already committed.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:timezone_finder/src/data/boundaries.dart' as bundled_container;

import '../test/reference/reference_finder.dart';
import 'release/boundaries_unsimplified.dart' as unsimplified_container;
import 'src/build_index.dart';
import 'src/emit_dart.dart';
import 'src/geometry.dart';
import 'src/simplify.dart';
import 'src/fetch.dart';

const String _usage =
    'Usage: dart run tool/generate_data.dart [--release <tag>] '
    '[--tolerance <units>] [--chunk-kb <n>] '
    '[--emit bundled|unsimplified|both] [--verify]';

const Set<String> _emitChoices = <String>{'bundled', 'unsimplified', 'both'};

/// One index tier: what it was built from, and what it is compared against.
typedef _Tier = ({
  String name,
  Directory directory,
  List<SourcePolygon> polygons,
  Uint8List container,
  Uint8List Function() committed,
});

Future<void> main(List<String> args) async {
  var release = defaultRelease;
  var chunkKb = 1024;
  var emit = 'both';
  var verifyOnly = false;
  // 1e-3 degrees, about 110 m: measured as the point where the coordinate
  // blob falls to 3.89 MB.
  var tolerance = 1000;
  // Value flags consume their value with `++i`, so a value can never be read
  // as a flag, and anything left unrecognised is a hard error. This writes
  // committed data, so a typo must not fall through to the defaults.
  for (var i = 0; i < args.length; i++) {
    final argument = args[i];
    // A following `--flag` is never a value: `--release --verify` means the
    // release was forgotten, not that it is named "--verify".
    final hasValue = i + 1 < args.length && !args[i + 1].startsWith('--');
    switch (argument) {
      case '--release' when hasValue:
        release = args[++i];
      case '--chunk-kb' when hasValue:
        final chunk = int.tryParse(args[++i]);
        if (chunk == null) {
          stderr.writeln(
            '--chunk-kb needs an integer, got ${args[i]}\n$_usage',
          );
          exitCode = 64;
          return;
        }
        chunkKb = chunk;
      case '--emit' when hasValue:
        emit = args[++i];
        if (!_emitChoices.contains(emit)) {
          // Otherwise this builds no tier at all and still exits 0.
          stderr.writeln('Unknown --emit value: $emit\n$_usage');
          exitCode = 64;
          return;
        }
      case '--tolerance' when hasValue:
        final units = int.tryParse(args[++i]);
        if (units == null) {
          stderr.writeln(
            '--tolerance needs an integer, got ${args[i]}\n$_usage',
          );
          exitCode = 64;
          return;
        }
        tolerance = units;
      case '--verify':
        verifyOnly = true;
      case '-h' || '--help':
        stdout.writeln(_usage);
        return;
      case '--release' || '--chunk-kb' || '--emit' || '--tolerance':
        stderr.writeln('Missing value for $argument.\n$_usage');
        exitCode = 64;
        return;
      default:
        stderr.writeln('Unknown argument: $argument\n$_usage');
        exitCode = 64;
        return;
    }
  }

  final cached = await ensureGeoJson(release: release, log: stdout.writeln);

  stdout.writeln('Loading boundaries …');
  final oracle = await ReferenceTimeZoneFinder.load(cached);
  stdout.writeln(
    '  ${oracle.zones.length} zones, ${oracle.polygons.length} polygons',
  );

  final tiers = <_Tier>[];
  if (emit == 'unsimplified' || emit == 'both') {
    final polygons = _sourcePolygons(oracle);
    tiers.add((
      name: 'boundaries_unsimplified',
      directory: Directory('tool/release'),
      polygons: polygons,
      container: _pack(release, polygons),
      committed: unsimplified_container.loadContainer,
    ));
  }
  if (emit == 'bundled' || emit == 'both') {
    stdout.writeln(
      '\nSimplifying at $tolerance units '
      '(~${(tolerance / 1000000 * 111000).round()} m) …',
    );
    final polygons = _simplified(oracle, tolerance);
    tiers.add((
      name: 'boundaries',
      directory: Directory('lib/src/data'),
      polygons: polygons,
      container: _pack(release, polygons),
      committed: bundled_container.loadContainer,
    ));
  }

  // Everything above only reads. --verify returns from inside this branch so
  // that no emit runs: it must be safe against a clean tree and leave it clean.
  if (verifyOnly) {
    var ok = true;
    for (final tier in tiers) {
      ok = _verify(tier.name, tier.container, tier.committed()) && ok;
    }
    if (!ok) {
      stdout.writeln(
        '\nFAIL — committed data does not match a rebuild of $release.',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('\nPASS — committed data reproduces $release exactly.');
    return;
  }

  stdout.writeln('\nEmitting Dart source …');
  for (final tier in tiers) {
    _emitTier(tier, release: release, chunkKb: chunkKb);
  }
  _writeCommittedNames(release, oracle.zones);

  stdout.writeln('\nNow run: dart format lib/src/data && dart analyze');
}

void _emitTier(_Tier tier, {required String release, required int chunkKb}) {
  final result = emitDartData(
    directory: tier.directory,
    name: tier.name,
    container: tier.container,
    dataVersion: release,
    chunkBase64Chars: chunkKb * 1024,
  );
  stdout.writeln(
    '  ${tier.name}: ${tier.polygons.length} polygons, '
    'container ${_mb(tier.container.length)}, '
    '${result.chunks} chunk(s), source ${_mb(result.sourceBytes)}',
  );

  // Only the bundled tier has a web asset; the unsimplified baseline is a
  // measurement input and never leaves the repository.
  if (tier.name == 'boundaries') {
    final binFile = File('lib/data/boundaries_$release.bin');
    emitBinaryData(file: binFile, container: tier.container);
    emitBoundariesBinMeta(
      file: File('lib/src/boundaries_bin.dart'),
      dataVersion: release,
      containerLength: tier.container.length,
    );
    stdout.writeln(
      '  web asset: ${binFile.path} (${_mb(tier.container.length)})',
    );
  }
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

void _writeCommittedNames(String release, List<String> names) {
  committedNamesFile.parent.createSync(recursive: true);
  committedNamesFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{'release': release, 'names': names})}\n',
  );
  stdout.writeln('  baseline updated: ${committedNamesFile.path}');
}

Uint8List _pack(String release, List<SourcePolygon> polygons) =>
    buildIndex(dataVersion: release, cellSize: 1000000, polygons: polygons);

List<SourcePolygon> _sourcePolygons(ReferenceTimeZoneFinder oracle) =>
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
    final result = simplifyPolygon(p.outer, p.holes, tolerance, stats);
    if (result == null) continue;
    out.add((
      zone: p.zone,
      // Recomputed: simplification changes the shape, and the precedence rule
      // orders by area. Reusing the unsimplified areas would order these
      // polygons by geometry they no longer have.
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
  return out;
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
