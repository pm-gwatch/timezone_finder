// Validate the oracle on bootstrapGoldens (66 external pairs) before it
// authorizes anything else. Skips if tzbb GeoJSON is not cached.

@Timeout(Duration(minutes: 10))
library;

import 'dart:typed_data';

import 'package:test/test.dart';

import '../tool/src/fetch.dart';
import '../tool/src/geometry.dart';
import 'fixtures/bootstrap_goldens.dart';
import 'reference/reference_location_finder.dart';

void main() {
  final cached = cachedGeoJsonFile(defaultRelease);
  final available = cached.existsSync();

  group(
    'reference oracle',
    skip: available
        ? null
        : 'tzbb $defaultRelease data not cached. Run:\n'
              '  dart run tool/fetch_data.dart\n'
              '(downloads ~51 MB into .dart_tool/, which is gitignored)',
    () {
      late ReferenceLocationFinder oracle;

      setUpAll(() async {
        oracle = await ReferenceLocationFinder.load(cached);
      });

      test('parses the expected shape of the dataset', () {
        // Measured independently from tzbb 2026c before the oracle existed.
        // Asserting all five totals — not just the two cheap ones — means a
        // parse that silently drops rings or vertices fails CI rather than
        // quietly weakening every downstream guarantee.
        //
        // If these change, the release changed, and every golden needs
        // re-checking.
        var rings = 0;
        var holes = 0;
        var vertices = 0;
        for (final polygon in oracle.polygons) {
          rings += 1 + polygon.holes.length;
          holes += polygon.holes.length;
          vertices += polygon.outer.length ~/ 2;
          for (final hole in polygon.holes) {
            vertices += hole.length ~/ 2;
          }
        }

        expect(oracle.zones.length, 419, reason: 'zones');
        expect(oracle.polygons.length, 1184, reason: 'polygons');
        expect(rings, 1456, reason: 'rings');
        expect(holes, 272, reason: 'holes');
        expect(vertices, 7649092, reason: 'vertices');
      });

      test('agrees with every bootstrap golden', () {
        final failures = <String>[];
        for (final point in bootstrapGoldens) {
          final actual = oracle.findLocationName(
            point.longitude,
            point.latitude,
          );
          if (actual != point.zone) {
            failures.add('${point.name}: expected ${point.zone}, got $actual');
          }
        }
        expect(
          failures,
          isEmpty,
          reason:
              'The oracle disagrees with external ground truth. Either the '
              'oracle is wrong, or a golden is — resolve it by hand, never by '
              'adopting the oracle\'s answer.\n${failures.join('\n')}',
        );
      });

      test('every golden zone is one the dataset knows about', () {
        for (final point in bootstrapGoldens) {
          expect(
            oracle.zones,
            contains(point.zone),
            reason: '${point.zone} is absent from tzbb $defaultRelease',
          );
        }
      });

      test('returns null at sea', () {
        // Land-only dataset : open ocean is not in any polygon.
        expect(oracle.findLocationName(-140, 0), isNull); // mid-Pacific
        expect(oracle.findLocationName(-30, -40), isNull); // South Atlantic
        expect(oracle.findLocationName(-25, 0), isNull); // equatorial Atlantic
      });

      test('rejects coordinates that are not coordinates', () {
        expect(() => oracle.findLocationName(0, 91), throwsArgumentError);
        expect(() => oracle.findLocationName(0, -91), throwsArgumentError);
        expect(() => oracle.findLocationName(181, 0), throwsArgumentError);
        expect(() => oracle.findLocationName(-181, 0), throwsArgumentError);
        expect(
          () => oracle.findLocationName(0, double.nan),
          throwsArgumentError,
        );
        expect(
          () => oracle.findLocationName(double.infinity, 0),
          throwsArgumentError,
        );
      });

      test('accepts the boundary values, which are valid coordinates', () {
        // Must not throw. The poles and the antimeridian are in range; the
        // golden fixtures cover what they return.
        expect(() => oracle.findLocationName(0, 90), returnsNormally);
        expect(() => oracle.findLocationName(0, -90), returnsNormally);
        expect(() => oracle.findLocationName(180, 0), returnsNormally);
        expect(() => oracle.findLocationName(-180, 0), returnsNormally);
      });

      test('the shoelace sum is exact for every ring in the dataset', () {
        // ringDoubledArea accumulates in int64. That is safe only while the
        // running sum stays inside the 64-bit range, which is a property of
        // the data, not of the code — so it is checked against the data rather
        // than argued for. Measured on 2026c the peak is 5.12e15, about 1801x
        // inside the limit, but a future release with wider rings could
        // approach it and the failure would otherwise be silent.
        //
        // Comparing against an exact BigInt sum detects overflow directly: an
        // int64 that wrapped would not match.
        var checked = 0;
        final mismatches = <String>[];
        for (final polygon in oracle.polygons) {
          for (final ring in <Int32List>[polygon.outer, ...polygon.holes]) {
            checked++;
            final fast = ringDoubledArea(ring);
            final exact = _exactDoubledArea(ring);
            if (BigInt.from(fast) != exact) {
              mismatches.add('${polygon.zone}: int64 $fast, exact $exact');
            }
          }
        }
        expect(checked, 1456, reason: 'ring count changed');
        expect(
          mismatches.take(5),
          isEmpty,
          reason: 'the int64 shoelace sum overflowed or lost precision',
        );
      });

      test('precedence is deterministic and total', () {
        // Every polygon must order consistently against every other, or the
        // overlap rule is not a rule. Spot-check a sample rather than all
        // 1,184 x 1,184 pairs.
        final sample = oracle.polygons.take(120).toList();
        for (final a in sample) {
          expect(comparePolygons(a, a), 0, reason: 'not reflexive');
          for (final b in sample) {
            expect(
              comparePolygons(a, b),
              -comparePolygons(b, a),
              reason: 'not antisymmetric for ${a.zone} vs ${b.zone}',
            );
          }
        }
      });
    },
  );
}

/// The doubled area a perfectly precise implementation would produce.
///
/// Used only to check the int64 version; far too slow for production use.
BigInt _exactDoubledArea(Int32List ring) {
  final n = ring.length ~/ 2;
  if (n < 3) return BigInt.zero;
  final x0 = BigInt.from(ring[0]);
  final y0 = BigInt.from(ring[1]);
  var total = BigInt.zero;
  for (var i = 0; i < n; i++) {
    final j = (i + 1) % n;
    final xi = BigInt.from(ring[i * 2]) - x0;
    final yi = BigInt.from(ring[i * 2 + 1]) - y0;
    final xj = BigInt.from(ring[j * 2]) - x0;
    final yj = BigInt.from(ring[j * 2 + 1]) - y0;
    total += xi * yj - xj * yi;
  }
  return total.abs();
}
