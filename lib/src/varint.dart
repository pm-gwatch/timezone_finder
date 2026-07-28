/// The packed coordinate format: delta encoding with zigzag varints.
///
/// Rings are stored as deltas between consecutive vertices rather than as
/// absolute coordinates. Neighbouring vertices on a coastline are close
/// together, so the deltas are small, and a variable-length encoding spends
/// one or two bytes on them instead of eight.
///
/// Reading runs at lookup time; writing runs only in the index builder. Both
/// live here because a wire format is one artifact — splitting the halves
/// across directories would make it impossible to review as a unit.
library;

import 'dart:typed_data';

/// Largest coordinate delta the format admits: the full width of the
/// quantized coordinate space, 360°.
///
/// Zigzag doubles it, so encoded values stay under 7.2e8 — far below the sign
/// bit, which is what lets the encoder use a plain arithmetic shift. Anything
/// larger is not a coordinate and the encoder rejects it.
const int maxCoordinateDelta = 360000000;

/// Maps a signed value onto the non-negative integers, small magnitudes first.
///
/// Without this, a delta of -1 would set every high bit and encode as ten
/// bytes. See [maxCoordinateDelta] for why the shift is safe.
int zigzagEncode(int value) => (value << 1) ^ (value >> 63);

/// Inverse of [zigzagEncode].
int zigzagDecode(int value) => (value >> 1) ^ -(value & 1);

/// Appends [ring] to [out] as `count, dx0, dy0, dx1, dy1, …`.
///
/// [ring] is interleaved `[x0, y0, x1, y1, …]` in quantized units. The vertex
/// count is written first so a ring can be decoded from its start offset
/// alone, without consulting a length table — which is what per-chunk lazy
/// decoding needs.
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
      throw StateError('varint runs past the end of the buffer at $offset');
    }
    // The encoder never emits more than nine continuation bytes, so a tenth
    // means the data is corrupt. Checked because the index ships as source
    // that could in principle be edited, and a silently wrong coordinate is
    // worse than a thrown error.
    if (shift > 63) {
      throw StateError('varint longer than 64 bits at $offset');
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
