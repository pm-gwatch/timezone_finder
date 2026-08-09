/// Measures shoelace area numerics on a cached release.
///
///     dart run tool/measure_geometry.dart
///
/// Reports, over every ring in the dataset:
///
///   * largest partial-sum magnitude vs the int64 range
///   * relative error of a `double` sum against an exact BigInt sum
///
/// Confirms integer accumulation stays inside int64 so areas can stay exact
/// (as in `tool/src/geometry.dart`).
library;

import 'dart:io';
import 'dart:typed_data';

import '../test/reference/reference_finder.dart';
import 'src/fetch.dart';
import 'src/geometry.dart';

Future<void> main() async {
  final cached = cachedGeoJsonFile(defaultRelease);
  if (!cached.existsSync()) {
    stderr.writeln('No cached data. Run: dart run tool/fetch_data.dart');
    exitCode = 1;
    return;
  }

  stdout.writeln('Loading reference oracle …');
  final oracle = await ReferenceTimeZoneFinder.load(cached);

  final rings = <Int32List>[];
  for (final polygon in oracle.polygons) {
    rings
      ..add(polygon.outer)
      ..addAll(polygon.holes);
  }
  rings.sort((a, b) => b.length.compareTo(a.length));
  stdout.writeln(
    '${rings.length} rings, largest ${rings.first.length ~/ 2} '
    'vertices\n',
  );

  // --- partial-sum magnitude -----------------------------------------------
  var worstPartial = BigInt.zero;
  Int32List? worstRing;
  for (final ring in rings) {
    final peak = _peakPartialSum(ring);
    if (peak > worstPartial) {
      worstPartial = peak;
      worstRing = ring;
    }
  }
  final int64Max = BigInt.parse('9223372036854775807');
  final headroom =
      int64Max ~/ (worstPartial == BigInt.zero ? BigInt.one : worstPartial);
  stdout
    ..writeln('largest |partial sum| : $worstPartial')
    ..writeln('  in a ring of        : ${worstRing!.length ~/ 2} vertices')
    ..writeln('int64 max             : $int64Max')
    ..writeln('headroom              : ${headroom}x')
    ..writeln(
      'exact int64 is ${worstPartial < int64Max ? 'SAFE' : 'UNSAFE'}\n',
    );

  // --- double vs exact ------------------------------------------------------
  stdout.writeln('double vs exact BigInt, on the 10 largest rings:');
  var worstError = 0.0;
  for (final ring in rings.take(10)) {
    final approx = ringDoubledArea(ring).toDouble();
    final exact = _exactDoubledArea(ring);
    final error = exact == 0 ? 0.0 : (approx - exact).abs() / exact;
    if (error > worstError) worstError = error;
    stdout.writeln(
      '  ${(ring.length ~/ 2).toString().padLeft(7)} vertices  '
      'rel err ${error.toStringAsExponential(3)}',
    );
  }

  var worstOverall = 0.0;
  for (final ring in rings) {
    final approx = ringDoubledArea(ring).toDouble();
    final exact = _exactDoubledArea(ring);
    if (exact == 0) continue;
    final error = (approx - exact).abs() / exact;
    if (error > worstOverall) worstOverall = error;
  }
  stdout.writeln(
    '\nworst relative error over all ${rings.length} rings: '
    '${worstOverall.toStringAsExponential(3)}',
  );
}

/// Peak magnitude reached by the running shoelace sum, computed exactly.
BigInt _peakPartialSum(Int32List ring) {
  final n = ring.length ~/ 2;
  if (n < 3) return BigInt.zero;
  final x0 = BigInt.from(ring[0]);
  final y0 = BigInt.from(ring[1]);
  var total = BigInt.zero;
  var peak = BigInt.zero;
  for (var i = 0; i < n; i++) {
    final j = (i + 1) % n;
    final xi = BigInt.from(ring[i * 2]) - x0;
    final yi = BigInt.from(ring[i * 2 + 1]) - y0;
    final xj = BigInt.from(ring[j * 2]) - x0;
    final yj = BigInt.from(ring[j * 2 + 1]) - y0;
    total += xi * yj - xj * yi;
    final magnitude = total.abs();
    if (magnitude > peak) peak = magnitude;
  }
  return peak;
}

/// The area a perfectly precise implementation would produce.
double _exactDoubledArea(Int32List ring) {
  final n = ring.length ~/ 2;
  if (n < 3) return 0;
  final x0 = BigInt.from(ring[0]);
  final y0 = BigInt.from(ring[1]);
  var total = BigInt.zero;
  for (var i = 0; i < n; i++) {
    final j = (i + 1) % n;
    final xi = BigInt.from(ring[i * 2]) - x0;
    final yi = BigInt.from(ring[i * 2 + 1]) - y0;
    final xj = BigInt.from(ring[j * 2]) - x0;
    final yj = BigInt.from(ring[j * 2 + 1]) - y0;
    total += xi * yj - xj * yi;
  }
  return total.abs().toDouble();
}
