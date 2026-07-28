// Milestone 2: validate the Phase A reference oracle against the bootstrap
// goldens.
//
// This is the gate the whole test strategy rests on. The oracle is the
// authority for the wider golden set (milestone 3) and for differential
// testing (milestone 7), but it cannot be validated against fixtures derived
// from itself. These 66 pairs are external ground truth; the oracle earns its
// authority by passing them, and not before.
//
// The oracle needs ~170 MB of tzbb GeoJSON, which is far too large to commit.
// When it is absent these tests skip rather than fail, so a fresh checkout
// still has a green suite and so an auditor without the bandwidth to pull
// 51 MB is not blocked.

@Timeout(Duration(minutes: 10))
library;

import 'package:test/test.dart';

import '../tool/src/fetch.dart';
import 'fixtures/bootstrap_goldens.dart';
import 'reference/reference_finder.dart';

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
      late ReferenceTimeZoneFinder oracle;

      setUpAll(() async {
        oracle = await ReferenceTimeZoneFinder.load(cached);
      });

      test('parses the expected shape of the dataset', () {
        // Measured independently from tzbb 2026c before the oracle existed;
        // see plan §5.1. Asserting all five totals — not just the two cheap
        // ones — means a parse that silently drops rings or vertices fails CI
        // rather than quietly weakening every downstream guarantee.
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
          final actual = oracle.find(point.latitude, point.longitude);
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
        // Land-only dataset (plan §2.2): open ocean is not in any polygon.
        expect(oracle.find(0, -140), isNull); // mid-Pacific
        expect(oracle.find(-40, -30), isNull); // South Atlantic
        expect(oracle.find(0, -25), isNull); // equatorial Atlantic
      });

      test('rejects coordinates that are not coordinates', () {
        expect(() => oracle.find(91, 0), throwsArgumentError);
        expect(() => oracle.find(-91, 0), throwsArgumentError);
        expect(() => oracle.find(0, 181), throwsArgumentError);
        expect(() => oracle.find(0, -181), throwsArgumentError);
        expect(() => oracle.find(double.nan, 0), throwsArgumentError);
        expect(() => oracle.find(0, double.infinity), throwsArgumentError);
      });

      test('accepts the boundary values, which are valid coordinates', () {
        // Must not throw. The poles and the antimeridian are in range; what
        // they return is a milestone 3 concern (plan §9.2, §9.3).
        expect(() => oracle.find(90, 0), returnsNormally);
        expect(() => oracle.find(-90, 0), returnsNormally);
        expect(() => oracle.find(0, 180), returnsNormally);
        expect(() => oracle.find(0, -180), returnsNormally);
      });

      test('precedence is deterministic and total', () {
        // Every polygon must order consistently against every other, or the
        // overlap rule is not a rule. Spot-check a sample rather than all
        // 1,184 x 1,184 pairs.
        final sample = oracle.polygons.take(120).toList();
        for (final a in sample) {
          expect(comparePrecedence(a, a), 0, reason: 'not reflexive');
          for (final b in sample) {
            expect(
              comparePrecedence(a, b),
              -comparePrecedence(b, a),
              reason: 'not antisymmetric for ${a.zone} vs ${b.zone}',
            );
          }
        }
      });
    },
  );
}
