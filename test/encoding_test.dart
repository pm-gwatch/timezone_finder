// Packed format vs the real dataset: encoder/decoder inverses + independent
// size check. Quantization_test is the only other quantization guard.

@Timeout(Duration(minutes: 10))
library;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone_finder/src/index/varint.dart';

import '../tool/src/fetch.dart';
import 'reference/reference_location_finder.dart';

void main() {
  final cached = cachedGeoJsonFile(defaultRelease);
  final available = cached.existsSync();

  group(
    'packed coordinates',
    skip: available
        ? null
        : 'tzbb $defaultRelease data not cached. Run:\n'
              '  dart run tool/fetch_data.dart\n'
              '(downloads ~51 MB into .dart_tool/, which is gitignored)',
    () {
      late List<Int32List> rings;

      setUpAll(() async {
        final oracle = await ReferenceLocationFinder.load(cached);
        rings = <Int32List>[
          for (final polygon in oracle.polygons) ...<Int32List>[
            polygon.outer,
            ...polygon.holes,
          ],
        ];
      });

      test('round-trips every ring in the dataset bit-for-bit', () {
        var vertices = 0;
        final failures = <String>[];
        for (var i = 0; i < rings.length; i++) {
          final original = rings[i];
          vertices += original.length ~/ 2;

          final out = BytesBuilder();
          writeRing(out, original);
          final decoded = readRing(out.toBytes(), 0);

          if (decoded.ring.length != original.length) {
            failures.add(
              'ring $i: length ${decoded.ring.length} != '
              '${original.length}',
            );
            continue;
          }
          for (var v = 0; v < original.length; v++) {
            if (decoded.ring[v] != original[v]) {
              failures.add(
                'ring $i, slot $v: ${decoded.ring[v]} != '
                '${original[v]}',
              );
              break;
            }
          }
        }

        expect(rings.length, 1456, reason: 'ring count changed');
        expect(vertices, 7649092, reason: 'vertex count changed');
        expect(
          failures.take(5),
          isEmpty,
          reason: 'the codec is lossy: ${failures.length} ring(s) differ',
        );
      });

      test('rings survive being packed back to back', () {
        // The dataset round-trip above encodes each ring alone. In the index
        // they are concatenated, so a decoder that ignored its offset or read
        // one byte too many would still pass that test and fail here.
        final out = BytesBuilder();
        final offsets = <int>[];
        var cursor = 0;
        for (final value in rings) {
          offsets.add(cursor);
          final before = out.length;
          writeRing(out, value);
          cursor += out.length - before;
        }
        final bytes = out.toBytes();

        for (var i = 0; i < rings.length; i++) {
          final decoded = readRing(bytes, offsets[i]);
          expect(decoded.ring, rings[i], reason: 'ring $i at ${offsets[i]}');
          final end = i + 1 < offsets.length ? offsets[i + 1] : bytes.length;
          expect(
            decoded.next,
            end,
            reason: 'ring $i ended at the wrong offset',
          );
        }
      });

      test('encodedRingLength predicts the packed size exactly', () {
        // The index builder sizes the buffer and builds the offset table
        // without encoding twice.
        var predicted = 0;
        for (final value in rings) {
          predicted += encodedRingLength(value);
        }
        final out = BytesBuilder();
        for (final value in rings) {
          writeRing(out, value);
        }
        expect(predicted, out.length);
      });

      test('the coordinate blob matches the budget in the size budget', () {
        var total = 0;
        for (final value in rings) {
          total += encodedRingLength(value);
        }
        final megabytes = total / 1e6;
        printOnFailure('coordinate blob: ${megabytes.toStringAsFixed(2)} MB');

        // 27.84 MB from the Python prototype, plus ~4 KB of vertex-count
        // prefixes this format adds. A drift of more than 1% means the two
        // implementations disagree about the encoding, not merely about
        // bookkeeping.
        expect(
          megabytes,
          inInclusiveRange(27.5, 28.2),
          reason:
              'encoded size ${megabytes.toStringAsFixed(2)} MB departs '
              'from the 27.84 MB the size budget assumes',
        );
      });
    },
  );
}
