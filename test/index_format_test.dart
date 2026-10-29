// Container guards runtime_test skips without the 51 MB cache. Uses bundled +
// synthetic bytes. See indexFormatVersion.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone_finder/src/generated/boundaries.dart' as bundled;
import 'package:timezone_finder/src/index/boundary_index.dart';

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
    test('a cell size that does not divide 180°', () {
      expect(
        () =>
            BoundaryIndex.fromBytes(_withHeaderField(IndexHeader.cellSize, 7)),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a cell size that divides 360° but not 180°', () {
      // Latitude is 180°. 72000000 is 72°: it divides 360° and builds a short
      // row axis, clamping the north into the last row.
      expect(
        () => BoundaryIndex.fromBytes(
          _withHeaderField(IndexHeader.cellSize, 72000000),
        ),
        throwsA(
          isA<IndexFormatException>().having(
            (e) => e.message,
            'message',
            contains('180'),
          ),
        ),
      );
    });

    test('a cell size of zero', () {
      expect(
        () =>
            BoundaryIndex.fromBytes(_withHeaderField(IndexHeader.cellSize, 0)),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a section offset past the end of the buffer', () {
      final length = bundled.loadContainer().length;
      expect(
        () => BoundaryIndex.fromBytes(
          _withHeaderField(IndexHeader.coordinates, length + 1),
        ),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a grid cell section that is not a whole number of int32s', () {
      final bytes = bundled.loadContainer();
      final cells = _headerField(bytes, IndexHeader.gridCells);
      expect(
        () => BoundaryIndex.fromBytes(
          _withHeaderField(IndexHeader.gridPool, cells + 1),
        ),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a grid cell section too short for the cell size', () {
      // Whole int32s, so only the count check catches it. Without it every
      // lookup indexes past the array and surfaces as a RangeError.
      final bytes = bundled.loadContainer();
      final cells = _headerField(bytes, IndexHeader.gridCells);
      expect(
        () => BoundaryIndex.fromBytes(
          _withHeaderField(IndexHeader.gridPool, cells + 4),
        ),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a polygon naming a zone the index does not have', () {
      // Polygon section starts `count=1, zoneId=0`; 5 is past the one name.
      final corrupt = Uint8List.fromList(_syntheticContainer());
      final polygons = _headerField(corrupt, IndexHeader.polygons);
      expect(corrupt[polygons], 1, reason: 'expected a single polygon');
      expect(corrupt[polygons + 1], 0, reason: 'expected zone id 0');
      corrupt[polygons + 1] = 5;

      expect(
        () => BoundaryIndex.fromBytes(corrupt),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a polygon with no rings', () {
      // Polygon section: count=1, zoneId=0, four 4-byte box varints (±2e6
      // zigzagged), then ringCount=1. Zero rings would make every lookup
      // that reaches it read offsets[0] and throw RangeError.
      final corrupt = Uint8List.fromList(_syntheticContainer());
      final ringCount = _headerField(corrupt, IndexHeader.polygons) + 18;
      expect(corrupt[ringCount], 1, reason: 'expected a one-ring polygon');
      corrupt[ringCount] = 0;

      expect(
        () => BoundaryIndex.fromBytes(corrupt),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a bad magic on a full container', () {
      final bytes = Uint8List.fromList(_syntheticContainer());
      bytes[0] ^= 0xff;
      expect(
        () => BoundaryIndex.fromBytes(bytes),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('an unknown format version', () {
      final bytes = Uint8List.fromList(_syntheticContainer());
      ByteData.sublistView(
        bytes,
      ).setUint32(IndexHeader.formatVersion, 99, Endian.little);
      expect(
        () => BoundaryIndex.fromBytes(bytes),
        throwsA(
          isA<IndexFormatException>().having(
            (e) => e.message,
            'message',
            contains('format version'),
          ),
        ),
      );
    });

    test('invalid UTF-8 in a container string', () {
      final corrupt = Uint8List.fromList(_syntheticContainer());
      final at = _headerField(corrupt, IndexHeader.dataVersion);
      expect(corrupt[at], 9, reason: 'length of "synthetic"');
      corrupt[at + 1] = 0xff;
      expect(
        () => BoundaryIndex.fromBytes(corrupt),
        throwsA(
          isA<IndexFormatException>().having(
            (e) => e.message,
            'message',
            contains('UTF-8'),
          ),
        ),
      );
    });

    test('a varint longer than five bytes', () {
      final corrupt = Uint8List.fromList(_syntheticContainer());
      final at = _headerField(corrupt, IndexHeader.dataVersion);
      for (var i = 0; i < 5; i++) {
        corrupt[at + i] = 0x80;
      }
      corrupt[at + 5] = 0x01;
      expect(
        () => BoundaryIndex.fromBytes(corrupt),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('a polygon count larger than the bytes left', () {
      final corrupt = Uint8List.fromList(_syntheticContainer());
      final at = _headerField(corrupt, IndexHeader.polygons);
      // Four-byte varint for 268435455 polygons. The buffer is far smaller.
      corrupt[at] = 0xff;
      corrupt[at + 1] = 0xff;
      corrupt[at + 2] = 0xff;
      corrupt[at + 3] = 0x7f;
      expect(
        () => BoundaryIndex.fromBytes(corrupt),
        throwsA(
          isA<IndexFormatException>().having(
            (e) => e.message,
            'message',
            contains('polygon count'),
          ),
        ),
      );
    });

    test('a positive grid cell', () {
      final corrupt = Uint8List.fromList(_syntheticContainer());
      final cells = _headerField(corrupt, IndexHeader.gridCells);
      ByteData.sublistView(corrupt).setInt32(cells, 1, Endian.little);
      expect(
        () => BoundaryIndex.fromBytes(corrupt),
        throwsA(
          isA<IndexFormatException>().having(
            (e) => e.message,
            'message',
            contains('negative pool'),
          ),
        ),
      );
    });

    test('a pool offset past the pool', () {
      final corrupt = Uint8List.fromList(_syntheticContainer());
      final cells = _headerField(corrupt, IndexHeader.gridCells);
      ByteData.sublistView(corrupt).setInt32(cells, -2000000000, Endian.little);
      expect(
        () => BoundaryIndex.fromBytes(corrupt),
        throwsA(
          isA<IndexFormatException>().having(
            (e) => e.message,
            'message',
            contains('pool'),
          ),
        ),
      );
    });

    test('a grid pool that starts before the cells it follows', () {
      final bytes = bundled.loadContainer();
      final cells = _headerField(bytes, IndexHeader.gridCells);
      expect(
        () => BoundaryIndex.fromBytes(
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
        BoundaryIndex.fromBytes(clean).lookup(x, y),
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

      final index = BoundaryIndex.fromBytes(corrupt);
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

      final index = BoundaryIndex.fromBytes(corrupt);
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
