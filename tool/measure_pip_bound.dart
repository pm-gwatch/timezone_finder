/// Scans every ring edge in the bundled index for the dart2js PIP bound.
///
/// Sound per-edge bound (ray straddles only): `|side| <= 360e6·|dy| + |dy|·|dx|`.
/// Must stay strictly below 2^53 so dart2js Number stays exact.
///
///     dart run tool/measure_pip_bound.dart
library;

import 'package:timezone_finder/src/data/boundaries.dart' as bundled;
import 'package:timezone_finder/src/index.dart';

void main() {
  final bytes = bundled.loadContainer();
  final index = TimeZoneIndex.fromBytes(bytes);
  final maxBound = index.maxPipSideBound();

  const limit = 1 << 53;
  print('Packed container: ${bytes.length} bytes');
  print('dataVersion: ${index.dataVersion}');
  print('polygonCount: ${index.polygonCount}');
  print('max sound |side| bound: $maxBound');
  print('2^53: $limit');
  print('headroom: ${(limit / maxBound).toStringAsFixed(3)}x');

  if (maxBound >= limit) {
    throw StateError(
      'bundled PIP bound $maxBound is not dart2js-safe (limit $limit)',
    );
  }
  print('OK — bundled rings are dart2js-safe under the sound bound.');
}
