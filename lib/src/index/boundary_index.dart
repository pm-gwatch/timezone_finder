/// The shipped index: container layout and the runtime reader.
///
/// The reader never learns where its bytes came from. Tests build a container
/// in memory; VM loads generated chunks, web installs the packed `.bin`.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../exceptions.dart';
import 'point_in_polygon.dart';
import 'varint.dart';

export '../exceptions.dart' show IndexFormatException;

/// Identifies the container. Checked before anything else is trusted.
const int indexMagic = 0x58465a54; // 'TZFX', little-endian

/// Incremented whenever the layout changes in a way an older reader would
/// misparse. Refuse unknown versions; a corrupt `.bin` or edited chunk must
/// not be guessed.
const int indexFormatVersion = 1;

abstract final class IndexHeader {
  static const int magic = 0;
  static const int formatVersion = 4;
  static const int cellSize = 8;
  static const int dataVersion = 12;
  static const int zoneNames = 16;
  static const int polygons = 20;
  static const int gridCells = 24;
  static const int gridPool = 28;
  static const int coordinates = 32;

  /// Total header size. Sections begin after this.
  static const int length = 36;
}

/// Reads a packed index and resolves quantized coordinates against it.
///
/// The polygon table is parsed eagerly (~1000 records). Ring coordinates are
/// decoded on first use and memoised. Counts are approximate on purpose:
/// shipped and unsimplified indexes both move each release.
/// `polygonCount` is exact.
class BoundaryIndex {
  BoundaryIndex._({
    required Uint8List bytes,
    required this.dataVersion,
    required this.zoneNames,
    required int cellSize,
    required int gridCellsOffset,
    required int gridPoolOffset,
    required int coordinatesOffset,
    required Int32List polygonZoneIds,
    required Int32List polygonBoxes,
    required List<Int32List> polygonRingOffsets,
  }) : _bytes = bytes,
       _cellSize = cellSize,
       _gridCells = _viewCells(bytes, gridCellsOffset, gridPoolOffset),
       _gridPoolOffset = gridPoolOffset,
       _coordinatesOffset = coordinatesOffset,
       _polygonZoneIds = polygonZoneIds,
       _polygonBoxes = polygonBoxes,
       _polygonRingOffsets = polygonRingOffsets {
    _columns = 360000000 ~/ cellSize;
  }

  /// Parses [bytes] as a container.
  ///
  /// Throws [IndexFormatException] if the magic, the version or the declared
  /// section offsets do not describe a container this reader can handle.
  factory BoundaryIndex.fromBytes(Uint8List bytes) {
    if (bytes.length < IndexHeader.length) {
      throw const IndexFormatException('buffer is shorter than the header');
    }
    final header = ByteData.sublistView(bytes);
    if (header.getUint32(IndexHeader.magic, Endian.little) != indexMagic) {
      throw const IndexFormatException('not a timezone_finder index');
    }
    final version = header.getUint32(IndexHeader.formatVersion, Endian.little);
    if (version != indexFormatVersion) {
      throw IndexFormatException(
        'index format version $version, this build reads $indexFormatVersion',
      );
    }

    int offset(int field) {
      final value = header.getUint32(field, Endian.little);
      if (value > bytes.length) {
        throw IndexFormatException(
          'section offset $value lies past the end of a ${bytes.length}-byte '
          'buffer',
        );
      }
      return value;
    }

    final cellSize = header.getUint32(IndexHeader.cellSize, Endian.little);
    if (cellSize <= 0 || 360000000 % cellSize != 0) {
      throw IndexFormatException('cell size $cellSize does not divide 360°');
    }

    final dataVersion = _readString(bytes, offset(IndexHeader.dataVersion));

    var cursor = offset(IndexHeader.zoneNames);
    final nameCount = _varint(bytes, cursor);
    cursor = nameCount.next;
    final names = <String>[];
    for (var i = 0; i < nameCount.value; i++) {
      final name = _readString(bytes, cursor);
      names.add(name.value);
      cursor = name.next;
    }

    cursor = offset(IndexHeader.polygons);
    final polygonCount = _varint(bytes, cursor);
    cursor = polygonCount.next;
    final zoneIds = Int32List(polygonCount.value);
    final boxes = Int32List(polygonCount.value * 4);
    final ringOffsets = <Int32List>[];
    var previousRingOffset = 0;
    for (var i = 0; i < polygonCount.value; i++) {
      final zoneId = _varint(bytes, cursor);
      cursor = zoneId.next;
      zoneIds[i] = zoneId.value;

      for (var f = 0; f < 4; f++) {
        final field = _varint(bytes, cursor);
        cursor = field.next;
        boxes[i * 4 + f] = zigzagDecode(field.value);
      }

      final ringCount = _varint(bytes, cursor);
      cursor = ringCount.next;
      final offsets = Int32List(ringCount.value);
      for (var r = 0; r < ringCount.value; r++) {
        final delta = _varint(bytes, cursor);
        cursor = delta.next;
        previousRingOffset += delta.value;
        offsets[r] = previousRingOffset;
      }
      ringOffsets.add(offsets);
    }

    return BoundaryIndex._(
      bytes: bytes,
      dataVersion: dataVersion.value,
      zoneNames: List<String>.unmodifiable(names),
      cellSize: cellSize,
      gridCellsOffset: offset(IndexHeader.gridCells),
      gridPoolOffset: offset(IndexHeader.gridPool),
      coordinatesOffset: offset(IndexHeader.coordinates),
      polygonZoneIds: zoneIds,
      polygonBoxes: boxes,
      polygonRingOffsets: ringOffsets,
    );
  }

  final Uint8List _bytes;
  final int _cellSize;
  final Int32List _gridCells;
  final int _gridPoolOffset;
  final int _coordinatesOffset;
  final Int32List _polygonZoneIds;
  final Int32List _polygonBoxes;
  final List<Int32List> _polygonRingOffsets;
  final Map<int, Int32List> _ringCache = <int, Int32List>{};
  late final int _columns;

  /// The tzbb release this index was built from, e.g. `'2026c'`.
  final String dataVersion;

  /// Every identifier in the dataset, sorted, straight from the container.
  final List<String> zoneNames;

  int get polygonCount => _polygonZoneIds.length;

  /// Resolves quantized coordinates, or `null` if no polygon contains them.
  ///
  /// Candidates arrive from the grid already ordered by the overlap tiebreak,
  /// so the first polygon containing the point is the answer and no polygon
  /// areas need to ship.
  String? lookup(int x, int y) {
    final cell = _gridCells[_cellIndex(x, y)];
    if (cell == 0) return null;

    var cursor = _gridPoolOffset + (-cell - 1);
    final count = _varint(_bytes, cursor);
    cursor = count.next;

    var id = 0;
    for (var i = 0; i < count.value; i++) {
      final dx = _varint(_bytes, cursor);
      cursor = dx.next;
      final dy = _varint(_bytes, cursor);
      cursor = dy.next;
      id += zigzagDecode(dx.value);

      if (id < 0 || id >= _polygonZoneIds.length) {
        throw IndexFormatException(
          'grid pool yielded polygon id $id, but the index has '
          '${_polygonZoneIds.length} polygons',
        );
      }

      if (_boxContains(id, x, y) && _polygonContains(id, x, y)) {
        return zoneNames[_polygonZoneIds[id]];
      }
    }
    return null;
  }

  int _cellIndex(int x, int y) {
    var column = (x + 180000000) ~/ _cellSize;
    var row = (y + 90000000) ~/ _cellSize;
    if (column < 0) column = 0;
    if (column >= _columns) column = _columns - 1;
    final rows = _gridCells.length ~/ _columns;
    if (row < 0) row = 0;
    if (row >= rows) row = rows - 1;
    return row * _columns + column;
  }

  bool _boxContains(int id, int x, int y) {
    final base = id * 4;
    return x >= _polygonBoxes[base] &&
        x <= _polygonBoxes[base + 1] &&
        y >= _polygonBoxes[base + 2] &&
        y <= _polygonBoxes[base + 3];
  }

  bool _polygonContains(int id, int x, int y) {
    final offsets = _polygonRingOffsets[id];
    if (!pointInRing(_ring(offsets[0]), x, y)) return false;
    for (var r = 1; r < offsets.length; r++) {
      if (pointInRing(_ring(offsets[r]), x, y)) return false;
    }
    return true;
  }

  Int32List _ring(int offset) => _ringCache.putIfAbsent(
    offset,
    () => readRing(_bytes, _coordinatesOffset + offset).ring,
  );

  /// All rings, without using or filling the lookup cache. Build/measure only.
  Iterable<Int32List> get decodeAllRings sync* {
    for (final offsets in _polygonRingOffsets) {
      for (final offset in offsets) {
        yield readRing(_bytes, _coordinatesOffset + offset).ring;
      }
    }
  }
}

/// The cell array as an [Int32List], copied with explicit little-endian reads.
///
/// A zero-copy view is possible on the VM; we copy via [ByteData] so chunks
/// and `.bin` share one path across compilers.
Int32List _viewCells(Uint8List bytes, int cellsOffset, int poolOffset) {
  final byteLength = poolOffset - cellsOffset;
  if (byteLength < 0 || byteLength % 4 != 0) {
    throw IndexFormatException(
      'grid cell section is $byteLength bytes, not a whole number of int32s',
    );
  }
  final count = byteLength ~/ 4;
  final view = ByteData.sublistView(bytes, cellsOffset, poolOffset);
  final copy = Int32List(count);
  for (var i = 0; i < count; i++) {
    copy[i] = view.getInt32(i * 4, Endian.little);
  }
  return copy;
}

({int value, int next}) _varint(Uint8List bytes, int offset) {
  var value = 0;
  var shift = 0;
  var position = offset;
  while (true) {
    if (position >= bytes.length) {
      throw const IndexFormatException('varint runs past the end of the index');
    }
    if (shift > 63) {
      throw const IndexFormatException('varint longer than 64 bits');
    }
    final byte = bytes[position++];
    value |= (byte & 0x7f) << shift;
    if (byte < 0x80) return (value: value, next: position);
    shift += 7;
  }
}

({String value, int next}) _readString(Uint8List bytes, int offset) {
  final length = _varint(bytes, offset);
  final end = length.next + length.value;
  if (end > bytes.length) {
    throw const IndexFormatException('string runs past the end of the index');
  }
  return (value: utf8.decode(bytes.sublist(length.next, end)), next: end);
}
