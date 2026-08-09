// Container validation branches the runtime suite does not reach.
//
// `runtime_test` covers four rejections (short buffer, bad magic, unknown
// version, truncated) but its whole group is skipped without the 51 MB GeoJSON
// cache, so on CI none of them run. These work from the bundled container and a
// synthetic one, so the reader's guards are exercised on every run.
//
// The index ships as editable Dart source, which is why it validates at all —
// see the rationale on `indexFormatVersion`.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone_finder/src/data/boundaries.dart' as bundled;
import 'package:timezone_finder/src/index.dart';

import '../tool/src/build_index.dart';

/// The bundled bytes with one little-endian uint32 header field overwritten.
Uint8List _withHeaderField(int fieldOffset, int value) {
  final bytes = Uint8List.fromList(bundled.loadContainer());
  ByteData.sublistView(bytes).setUint32(fieldOffset, value, Endian.little);
  return bytes;
}

int _headerField(Uint8List bytes, int fieldOffset) =>
    ByteData.sublistView(bytes).getUint32(fieldOffset, Endian.little);

/// A one-polygon container covering a square of ocean around (0.5°, 0.5°).
Uint8List _syntheticContainer() => buildIndex(
  dataVersion: 'synthetic',
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
  group('rejects a header that does not describe a container', () {
    test('a cell size that does not divide 360°', () {
      // The reader derives its column count from this, so a value that does
      // not divide the globe silently skews every cell index.
      expect(
        () =>
            TimeZoneIndex.fromBytes(_withHeaderField(IndexHeader.cellSize, 7)),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a cell size of zero', () {
      expect(
        () =>
            TimeZoneIndex.fromBytes(_withHeaderField(IndexHeader.cellSize, 0)),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a section offset past the end of the buffer', () {
      final length = bundled.loadContainer().length;
      expect(
        () => TimeZoneIndex.fromBytes(
          _withHeaderField(IndexHeader.coordinates, length + 1),
        ),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a grid cell section that is not a whole number of int32s', () {
      final bytes = bundled.loadContainer();
      final cells = _headerField(bytes, IndexHeader.gridCells);
      expect(
        () => TimeZoneIndex.fromBytes(
          _withHeaderField(IndexHeader.gridPool, cells + 1),
        ),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a grid pool that starts before the cells it follows', () {
      final bytes = bundled.loadContainer();
      final cells = _headerField(bytes, IndexHeader.gridCells);
      expect(
        () => TimeZoneIndex.fromBytes(
          _withHeaderField(IndexHeader.gridPool, cells - 4),
        ),
        throwsA(isA<IndexFormatException>()),
      );
    });
  });

  group('rejects corruption that only surfaces during a lookup', () {
    // Everything above fails while parsing. This one parses cleanly and only
    // goes wrong when a query reaches the grid pool — the path a hand-edited
    // index is most likely to break, and the only guard in the hot loop.
    test('a grid pool entry naming a polygon the index does not have', () {
      final clean = _syntheticContainer();
      const x = 500000, y = 500000;

      expect(
        TimeZoneIndex.fromBytes(clean).lookup(x, y),
        'Test/Synthetic',
        reason: 'the pool entry must be live before corrupting it',
      );

      // First pool entry is `count=1, dxZigzag=0, dy…`; the zero is the delta
      // that resolves to polygon 0. Zigzag 10 makes it polygon 5, and the
      // index has exactly one.
      final corrupt = Uint8List.fromList(clean);
      final pool = _headerField(corrupt, IndexHeader.gridPool);
      expect(corrupt[pool], 1, reason: 'expected a single-candidate entry');
      expect(corrupt[pool + 1], 0, reason: 'expected a zero id delta');
      corrupt[pool + 1] = 10;

      final index = TimeZoneIndex.fromBytes(corrupt);
      expect(
        () => index.lookup(x, y),
        throwsA(isA<IndexFormatException>()),
        reason: 'an out-of-range polygon id must not index past the table',
      );
    });

    test('a corrupt coordinate blob reports as bad data, not bad state', () {
      // The coordinate section is the largest part of the container and the
      // only one read lazily, so its corruption surfaces from `readRing`
      // during a lookup rather than from `fromBytes`. It used to arrive as
      // StateError, which an app catching IndexFormatException would miss —
      // and which on web is indistinguishable from "boundaries not installed".
      final corrupt = Uint8List.fromList(_syntheticContainer());
      for (var i = corrupt.length - 12; i < corrupt.length; i++) {
        corrupt[i] = 0x80; // continuation bytes with no terminator
      }

      final index = TimeZoneIndex.fromBytes(corrupt);
      expect(
        index,
        isNotNull,
        reason: 'the blob is not validated up front, by design',
      );
      expect(
        () => index.lookup(500000, 500000),
        throwsA(isA<IndexFormatException>()),
      );
    });
  });
}
