/// Packed coordinates: delta + zigzag varints. Lookup reads; the builder
/// writes. One artifact — do not split the halves.
library;

import 'dart:typed_data';

import '../exceptions.dart';

/// Largest coordinate delta the format admits: the full width of the
/// quantized coordinate space, 360°.
///
/// Zigzag doubles it, so encoded values stay under 7.2e8 — comfortably below
/// the **32-bit** sign bit at 2³¹. That is the bound [zigzagEncode] depends on
/// to agree between the VM and dart2js. Anything larger is not a coordinate
/// and the encoder rejects it.
const int maxCoordinateDelta = 360000000;

/// Maps signed deltas to small non-negative ints (−1 would otherwise be 10
/// bytes). Unused on the web lookup path. dart2js: `value >> 63` is
/// 4294967295, not −1; the XOR still matches the VM while the result stays
/// below 2³¹ ([maxCoordinateDelta]). Do not rewrite as
/// `(value << 1) + (value >> 63)` — VM-right, dart2js-wrong.
int zigzagEncode(int value) => (value << 1) ^ (value >> 63);

/// Inverse of [zigzagEncode].
///
/// Written without `^(−1)` so dart2js cannot turn a negative delta into a
/// large unsigned value (e.g. −19 becoming 4294967277), which blew up polygon
/// ids when reading the grid pool on Chrome.
int zigzagDecode(int value) {
  final half = value >> 1;
  return (value & 1) == 0 ? half : -half - 1;
}

/// Appends [ring] to [out] as `count, dx0, dy0, dx1, dy1, …`.
///
/// [ring] is interleaved `[x0, y0, x1, y1, …]` in quantized units. Vertex
/// count first so a ring can be decoded from its start offset alone.
///
/// Throws [ArgumentError] if a delta exceeds [maxCoordinateDelta], which would
/// mean the input is not a quantized coordinate.
void writeRing(BytesBuilder out, Int32List ring) {
  final count = ring.length ~/ 2;
  _writeVarint(out, count);
  var previousX = 0;
  var previousY = 0;
  for (var i = 0; i < count; i++) {
    final x = ring[i * 2];
    final y = ring[i * 2 + 1];
    _writeDelta(out, x - previousX);
    _writeDelta(out, y - previousY);
    previousX = x;
    previousY = y;
  }
}

/// Reads a ring written by [writeRing], starting at [offset].
///
/// Returns the decoded ring and the offset just past it, so rings stored back
/// to back can be read in sequence.
///
/// Throws [IndexFormatException] if the bytes do not decode — the same type
/// the container reader raises, because this runs during a lookup and a caller
/// catching bad data should not have to know which section it came from.
({Int32List ring, int next}) readRing(Uint8List bytes, int offset) {
  var position = offset;
  final count = _readVarint(bytes, position);
  position = count.next;

  final ring = Int32List(count.value * 2);
  var x = 0;
  var y = 0;
  for (var i = 0; i < count.value; i++) {
    final dx = _readVarint(bytes, position);
    position = dx.next;
    final dy = _readVarint(bytes, position);
    position = dy.next;
    x += zigzagDecode(dx.value);
    y += zigzagDecode(dy.value);
    ring[i * 2] = x;
    ring[i * 2 + 1] = y;
  }
  return (ring: ring, next: position);
}

/// Bytes [writeRing] would emit for [ring], without building them.
int encodedRingLength(Int32List ring) {
  final count = ring.length ~/ 2;
  var total = _varintLength(count);
  var previousX = 0;
  var previousY = 0;
  for (var i = 0; i < count; i++) {
    final x = ring[i * 2];
    final y = ring[i * 2 + 1];
    total += _varintLength(zigzagEncode(x - previousX));
    total += _varintLength(zigzagEncode(y - previousY));
    previousX = x;
    previousY = y;
  }
  return total;
}

void _writeDelta(BytesBuilder out, int delta) {
  if (delta > maxCoordinateDelta || delta < -maxCoordinateDelta) {
    throw ArgumentError.value(
      delta,
      'delta',
      'exceeds $maxCoordinateDelta; not a quantized coordinate',
    );
  }
  _writeVarint(out, zigzagEncode(delta));
}

void _writeVarint(BytesBuilder out, int value) {
  var remaining = value;
  while (remaining >= 0x80) {
    out.addByte((remaining & 0x7f) | 0x80);
    remaining >>= 7;
  }
  out.addByte(remaining);
}

({int value, int next}) _readVarint(Uint8List bytes, int offset) {
  var value = 0;
  var shift = 0;
  var position = offset;
  while (true) {
    if (position >= bytes.length) {
      throw IndexFormatException(
        'varint runs past the end of the buffer at $offset',
      );
    }
    // A tenth continuation byte means corrupt data; fail instead of inventing
    // a coordinate.
    if (shift > 63) {
      throw IndexFormatException('varint longer than 64 bits at $offset');
    }
    final byte = bytes[position++];
    value |= (byte & 0x7f) << shift;
    if (byte < 0x80) return (value: value, next: position);
    shift += 7;
  }
}

int _varintLength(int value) {
  var remaining = value;
  var length = 1;
  while (remaining >= 0x80) {
    remaining >>= 7;
    length++;
  }
  return length;
}
