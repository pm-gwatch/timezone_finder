/// VM tests for [installBoundaries] without requiring Chrome.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone_finder/src/generated/boundaries_bin.dart';
import 'package:timezone_finder/src/exceptions.dart';
import 'package:timezone_finder/src/location_finder.dart';
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

  test('mutating the buffer after install does not change answers', () {
    // A same-version install returns early, so start from a different version.
    // Otherwise this would pass even if the shipped bytes were not copied.
    installBoundaries(_syntheticContainer('synthetic-0000'));
    final bytes = Uint8List.fromList(_shippedBytes());
    installBoundaries(bytes);
    bytes.fillRange(0, bytes.length, 0);
    expect(LocationFinder().findLocationName(2.3522, 48.8566), 'Europe/Paris');
  });

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

  test('different bytes under the same version are discarded', () {
    // The test above would pass whether the second install replaced or kept
    // the index, since the bytes were identical. Here they differ, so only a
    // discard leaves the real answers in place.
    installBoundaries(_shippedBytes());
    final finder = LocationFinder();
    final version = boundaryDataVersion;

    installBoundaries(_syntheticContainer(version));

    expect(boundaryDataVersion, version);
    expect(finder.findLocationName(2.3522, 48.8566), 'Europe/Paris');
    expect(finder.findLocationName(0.5, 0.5), isNull, reason: 'still real');
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
