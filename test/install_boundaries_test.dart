/// VM tests for [installBoundaries] without requiring Chrome.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone_finder/src/generated/boundaries_bin.dart';
import 'package:timezone_finder/src/exceptions.dart';
import 'package:timezone_finder/src/api/location_finder.dart';
import 'package:timezone_finder/src/index/boundary_store.dart'
    show installBoundaries;

import '../tool/src/build_index.dart';

Uint8List _shippedBytes() =>
    File('lib/data/$boundariesBinName').readAsBytesSync();

/// A one-polygon container under a version no real release will ever carry.
///
/// Covers a square of ocean off West Africa, so it answers where the shipped
/// data answers `null` — which is what makes a replacement observable.
Uint8List _syntheticContainer(String dataVersion) => buildIndex(
  dataVersion: dataVersion,
  cellSize: 1000000,
  polygons: <SourcePolygon>[
    (
      zone: 'Test/Synthetic',
      area: 4000000000000,
      minX: -2000000,
      maxX: 2000000,
      minY: -2000000,
      maxY: 2000000,
      outer: Int32List.fromList(<int>[
        -2000000, -2000000, //
        2000000, -2000000,
        2000000, 2000000,
        -2000000, 2000000,
      ]),
      holes: <Int32List>[],
    ),
  ],
);

void main() {
  // Every test installs what it needs, but the shared index is isolate-wide:
  // leaving a synthetic container installed would break whatever runs next.
  tearDown(() => installBoundaries(_shippedBytes()));

  test('installBoundaries accepts the shipped .bin', () {
    installBoundaries(_shippedBytes());
    final finder = LocationFinder();
    expect(finder.findLocationName(2.3522, 48.8566), 'Europe/Paris');
    expect(finder.findLocationName(-140.0, 0.0), isNull);
  });

  test('installBoundaries rejects corrupt bytes', () {
    expect(
      () => installBoundaries(Uint8List.fromList(<int>[0, 1, 2, 3])),
      throwsA(isA<IndexFormatException>()),
    );
  });

  test('second install with the same version is a no-op', () {
    final bytes = _shippedBytes();
    installBoundaries(bytes);
    final version = boundaryDataVersion;
    installBoundaries(bytes);
    expect(boundaryDataVersion, version);
    expect(LocationFinder().findLocationName(2.3522, 48.8566), 'Europe/Paris');
  });

  test('a different data version replaces the installed index', () {
    installBoundaries(_shippedBytes());
    final finder = LocationFinder();
    expect(boundaryDataVersion, isNot('synthetic-0000'));
    expect(
      finder.findLocationName(0.5, 0.5),
      isNull,
      reason: 'ocean in real data',
    );

    installBoundaries(_syntheticContainer('synthetic-0000'));

    // Version *and* answers move: a no-op here would leave Paris resolving,
    // which is exactly the bug this distinguishes from the same-version case.
    expect(boundaryDataVersion, 'synthetic-0000');
    expect(finder.findLocationName(0.5, 0.5), 'Test/Synthetic');
    expect(finder.findLocationName(2.3522, 48.8566), isNull);
  });
}
