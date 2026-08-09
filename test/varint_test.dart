// Tests for the packed coordinate format.
//
// Needs no boundary data, so it always runs. The round-trip over every
// vertex in the real dataset lives in encoding_test.dart, which does need
// the data.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone_finder/src/index_format_exception.dart';
import 'package:timezone_finder/src/varint.dart';

Int32List ring(List<List<int>> points) {
  final out = Int32List(points.length * 2);
  for (var i = 0; i < points.length; i++) {
    out[i * 2] = points[i][0];
    out[i * 2 + 1] = points[i][1];
  }
  return out;
}

Uint8List encode(Int32List value) {
  final out = BytesBuilder();
  writeRing(out, value);
  return out.toBytes();
}

void main() {
  group('zigzag', () {
    // Encode is unused on the web product path, but CI runs this file under
    // Chrome on purpose. dart2js gives `v >> 63` as 4294967295, not −1, and
    // `v << 1` as an unsigned 32-bit pattern; `^` still lands on the VM's
    // answer while the zigzag result stays below 2³¹. These cases pin that.
    test('round-trips across signs and magnitudes', () {
      const samples = <int>[
        0,
        1,
        -1,
        2,
        -2,
        127,
        -127,
        128,
        -128,
        maxCoordinateDelta,
        -maxCoordinateDelta,
      ];
      for (final value in samples) {
        expect(zigzagDecode(zigzagEncode(value)), value, reason: '$value');
      }
    });

    test('maps small magnitudes to small non-negative values', () {
      // The whole point: -1 must not become a ten-byte varint.
      expect(zigzagEncode(0), 0);
      expect(zigzagEncode(-1), 1);
      expect(zigzagEncode(1), 2);
      expect(zigzagEncode(-2), 3);
      expect(zigzagEncode(2), 4);
    });

    test('stays well below the 32-bit sign bit at the extreme', () {
      expect(zigzagEncode(-maxCoordinateDelta), isNonNegative);
      // Do not use large `1 << n` thresholds — under dart2js they are not 2^n.
      expect(zigzagEncode(maxCoordinateDelta), 2 * maxCoordinateDelta);
      expect(zigzagEncode(maxCoordinateDelta), lessThan(1000000000));
    });

    test('decode returns negatives without uint32 wrap (dart2js)', () {
      // Regression: `(n >> 1) ^ -1` became 4294967277 on dart2js, which then
      // corrupted polygon ids in the grid pool (Rome lookup).
      expect(zigzagDecode(37), -19);
      expect(zigzagDecode(1), -1);
      expect(zigzagDecode(3), -2);
    });
  });

  group('writeRing / readRing', () {
    test('round-trips a simple ring', () {
      final original = ring([
        [0, 0],
        [100, 0],
        [100, 100],
        [0, 100],
      ]);
      final decoded = readRing(encode(original), 0);
      expect(decoded.ring, original);
    });

    test('round-trips negative and mixed-sign coordinates', () {
      final original = ring([
        [-74006000, 40712800],
        [2352200, 48856600],
        [-58381600, -34603700],
        [139650300, 35676200],
      ]);
      expect(readRing(encode(original), 0).ring, original);
    });

    test('round-trips the extremes of the coordinate space', () {
      final original = ring([
        [-180000000, -90000000],
        [180000000, 90000000],
        [-180000000, 90000000],
        [180000000, -90000000],
      ]);
      expect(readRing(encode(original), 0).ring, original);
    });

    test('round-trips repeated vertices, where every delta is zero', () {
      final original = ring([
        [5000, 5000],
        [5000, 5000],
        [5000, 5000],
      ]);
      expect(readRing(encode(original), 0).ring, original);
    });

    test('a repeated vertex costs two bytes', () {
      // The property that matters, rather than a total that also folds in the
      // first vertex — which is delta-encoded from the origin and so is not
      // zero. A duplicate vertex should cost one byte per axis and no more.
      Int32List repeated(int times) => ring([
        for (var i = 0; i < times; i++) [5000, 5000],
      ]);
      final one = encode(repeated(1)).length;
      expect(encode(repeated(2)).length, one + 2);
      expect(encode(repeated(3)).length, one + 4);
    });

    test('round-trips degenerate rings', () {
      for (final original in <Int32List>[
        ring([]),
        ring([
          [1, 2],
        ]),
        ring([
          [1, 2],
          [3, 4],
        ]),
      ]) {
        expect(readRing(encode(original), 0).ring, original);
      }
    });

    test('reports the offset just past the ring', () {
      final original = ring([
        [7, 9],
        [11, 13],
      ]);
      final bytes = encode(original);
      expect(readRing(bytes, 0).next, bytes.length);
    });

    test('reads rings stored back to back', () {
      final first = ring([
        [1, 2],
        [3, 4],
      ]);
      final second = ring([
        [-100, -200],
        [300, 400],
        [500, 600],
      ]);
      final out = BytesBuilder();
      writeRing(out, first);
      writeRing(out, second);
      final bytes = out.toBytes();

      final a = readRing(bytes, 0);
      expect(a.ring, first);
      final b = readRing(bytes, a.next);
      expect(b.ring, second);
      expect(b.next, bytes.length);
    });

    test('encodedRingLength agrees with what writeRing emits', () {
      final rings = <Int32List>[
        ring([]),
        ring([
          [0, 0],
        ]),
        ring([
          [-180000000, -90000000],
          [180000000, 90000000],
        ]),
        ring([
          for (var i = 0; i < 500; i++) [i * 37 - 9000, i * -11 + 4000],
        ]),
      ];
      for (final value in rings) {
        expect(encodedRingLength(value), encode(value).length);
      }
    });

    test('rejects a delta that is not a coordinate', () {
      // Guards the bound zigzagEncode relies on: a delta within
      // ±maxCoordinateDelta keeps the encoded value under 2³¹, which is what
      // makes the VM and dart2js agree.
      final tooFar = ring([
        [0, 0],
        [maxCoordinateDelta + 1, 0],
      ]);
      expect(() => encode(tooFar), throwsArgumentError);
    });
  });

  group('malformed input', () {
    test('throws rather than reading past the buffer', () {
      final truncated = Uint8List.fromList([2, 0x80]); // count 2, then a stub
      expect(
        () => readRing(truncated, 0),
        throwsA(isA<IndexFormatException>()),
      );
    });

    test('throws on a varint longer than 64 bits', () {
      // The index ships as source. A corrupt continuation run must not decode
      // into a silently wrong coordinate.
      final bytes = Uint8List.fromList([
        1,
        ...List<int>.filled(12, 0x80),
        0x01,
      ]);
      expect(() => readRing(bytes, 0), throwsA(isA<IndexFormatException>()));
    });
  });
}
