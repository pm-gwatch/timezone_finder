/// Assembles the shipped index container.
///
/// Build-time counterpart to the reader in `lib/src/index.dart`; the layout is
/// documented there.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:timezone_finder/src/index.dart';
import 'package:timezone_finder/src/varint.dart';

import 'grid.dart';

/// One polygon as the builder sees it, before packing.
typedef SourcePolygon = ({
  String zone,
  int area,
  int minX,
  int maxX,
  int minY,
  int maxY,
  Int32List outer,
  List<Int32List> holes,
});

/// Largest `|side|` dart2js Number can represent exactly (2⁵³).
const int pipDart2jsLimit = 1 << 53;

/// Sound per-edge `|side|` bound for a straddling ray:
/// `|side| ≤ 360e6·|dy| + |dy|·|dx|`.
int pipSideBound(int dx, int dy) => 360000000 * dy + dy * dx;

/// Fails the pack if any edge's sound `|side|` bound reaches [pipDart2jsLimit].
///
/// Without this gate, a future tzbb release could silently emit rings whose
/// dart2js lookups disagree with the VM. Call before writing coordinates.
void assertPipDart2jsSafe(Iterable<Int32List> rings) {
  var maxBound = 0;
  for (final ring in rings) {
    final n = ring.length ~/ 2;
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final dx = (ring[j * 2] - ring[i * 2]).abs();
      final dy = (ring[j * 2 + 1] - ring[i * 2 + 1]).abs();
      final bound = pipSideBound(dx, dy);
      if (bound > maxBound) maxBound = bound;
    }
  }
  if (maxBound >= pipDart2jsLimit) {
    throw StateError(
      'PIP sound |side| bound $maxBound reaches or exceeds 2^53 '
      '($pipDart2jsLimit); dart2js cannot represent edge tests exactly',
    );
  }
}

/// Packs [polygons] into a container the runtime reader accepts.
///
/// [cellSize] is the grid resolution in quantized units; it must divide 360°.
///
/// Throws [StateError] if any ring edge's sound `|side|` bound is ≥ 2⁵³.
Uint8List buildIndex({
  required String dataVersion,
  required List<SourcePolygon> polygons,
  required int cellSize,
}) {
  assertPipDart2jsSafe([
    for (final polygon in polygons) ...[polygon.outer, ...polygon.holes],
  ]);

  final zoneNames = <String>{for (final p in polygons) p.zone}.toList()..sort();
  final zoneIdOf = <String, int>{
    for (var i = 0; i < zoneNames.length; i++) zoneNames[i]: i,
  };

  // Coordinates first: the polygon table stores offsets into this blob, so it
  // has to exist before the table can be written.
  final coordinates = BytesBuilder();
  final ringOffsets = <List<int>>[];
  for (final polygon in polygons) {
    final offsets = <int>[];
    for (final ring in <Int32List>[polygon.outer, ...polygon.holes]) {
      offsets.add(coordinates.length);
      writeRing(coordinates, ring);
    }
    ringOffsets.add(offsets);
  }

  final grid = buildGrid(GridSpec(cellSize), <PolygonBox>[
    for (var i = 0; i < polygons.length; i++)
      (
        id: i,
        minX: polygons[i].minX,
        maxX: polygons[i].maxX,
        minY: polygons[i].minY,
        maxY: polygons[i].maxY,
        area: polygons[i].area,
        zone: polygons[i].zone,
      ),
  ]);

  final versionSection = BytesBuilder()..add(_string(dataVersion));

  final namesSection = BytesBuilder();
  _varint(namesSection, zoneNames.length);
  for (final name in zoneNames) {
    namesSection.add(_string(name));
  }

  final polygonSection = BytesBuilder();
  _varint(polygonSection, polygons.length);
  var previousRingOffset = 0;
  for (var i = 0; i < polygons.length; i++) {
    final polygon = polygons[i];
    _varint(polygonSection, zoneIdOf[polygon.zone]!);
    for (final value in <int>[
      polygon.minX,
      polygon.maxX,
      polygon.minY,
      polygon.maxY,
    ]) {
      _varint(polygonSection, zigzagEncode(value));
    }
    _varint(polygonSection, ringOffsets[i].length);
    for (final offset in ringOffsets[i]) {
      _varint(polygonSection, offset - previousRingOffset);
      previousRingOffset = offset;
    }
  }

  // Section order matters: the reader derives the grid cell array's length
  // from the gap between its offset and the pool's, so those two must be
  // adjacent and in that order.
  final header = Uint8List(IndexHeader.length);
  final view = ByteData.sublistView(header);
  var cursor = IndexHeader.length;

  int place(BytesBuilder section) {
    final at = cursor;
    cursor += section.length;
    return at;
  }

  final versionAt = place(versionSection);
  final namesAt = place(namesSection);
  final polygonsAt = place(polygonSection);
  final cellBytes = grid.cells.buffer.asUint8List(
    grid.cells.offsetInBytes,
    grid.cells.lengthInBytes,
  );
  // The cell array is read back as an Int32List view, which requires a
  // four-byte aligned start. Pad rather than let the reader copy 259 KB.
  final cellPadding = (4 - cursor % 4) % 4;
  cursor += cellPadding;
  final cellsAt = cursor;
  cursor += cellBytes.length;
  final poolAt = cursor;
  cursor += grid.pool.length;
  final coordinatesAt = cursor;

  view
    ..setUint32(IndexHeader.magic, indexMagic, Endian.little)
    ..setUint32(IndexHeader.formatVersion, indexFormatVersion, Endian.little)
    ..setUint32(IndexHeader.cellSize, cellSize, Endian.little)
    ..setUint32(IndexHeader.dataVersion, versionAt, Endian.little)
    ..setUint32(IndexHeader.zoneNames, namesAt, Endian.little)
    ..setUint32(IndexHeader.polygons, polygonsAt, Endian.little)
    ..setUint32(IndexHeader.gridCells, cellsAt, Endian.little)
    ..setUint32(IndexHeader.gridPool, poolAt, Endian.little)
    ..setUint32(IndexHeader.coordinates, coordinatesAt, Endian.little);

  return (BytesBuilder()
        ..add(header)
        ..add(versionSection.toBytes())
        ..add(namesSection.toBytes())
        ..add(polygonSection.toBytes())
        ..add(Uint8List(cellPadding))
        ..add(cellBytes)
        ..add(grid.pool)
        ..add(coordinates.toBytes()))
      .toBytes();
}

Uint8List _string(String value) {
  final encoded = utf8.encode(value);
  final out = BytesBuilder();
  _varint(out, encoded.length);
  out.add(encoded);
  return out.toBytes();
}

void _varint(BytesBuilder out, int value) {
  var remaining = value;
  while (remaining >= 0x80) {
    out.addByte((remaining & 0x7f) | 0x80);
    remaining >>= 7;
  }
  out.addByte(remaining);
}
