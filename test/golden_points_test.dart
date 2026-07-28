// Milestone 3: the full golden set, run against the Phase A oracle.
//
// Two fixture sets with two different contracts:
//
//   * `bootstrapGoldens` + `goldenPoints` are external ground truth. A failure
//     means the oracle or the fixture is wrong.
//   * `overlapPins` pin the §6.5 tiebreak in regions where two zones genuinely
//     contain the point. A failure means the rule changed.
//
// Failures are reported grouped by category, because a cluster in one category
// is a systematic bug — a hole-handling or coastline problem — rather than
// several unrelated bad fixtures.

@Timeout(Duration(minutes: 10))
library;

import 'package:test/test.dart';

import '../tool/src/fetch.dart';
import 'fixtures/bootstrap_goldens.dart';
import 'fixtures/golden_points.dart';
import 'fixtures/overlap_pins.dart';
import 'reference/reference_finder.dart';

void main() {
  final cached = cachedGeoJsonFile(defaultRelease);
  final available = cached.existsSync();

  group(
    'golden set',
    skip: available
        ? null
        : 'tzbb $defaultRelease data not cached. Run:\n'
              '  dart run tool/fetch_data.dart\n'
              '(downloads ~51 MB into .dart_tool/, which is gitignored)',
    () {
      late ReferenceTimeZoneFinder oracle;
      final all = <GoldenPoint>[...bootstrapGoldens, ...goldenPoints];

      setUpAll(() async {
        oracle = await ReferenceTimeZoneFinder.load(cached);
      });

      test('the set is broad enough to be worth running', () {
        expect(all.length, greaterThanOrEqualTo(250));
        final zones = all.map((p) => p.zone).whereType<String>().toSet();
        expect(
          zones.length,
          greaterThanOrEqualTo(230),
          reason: 'coverage across the 419 identifiers matters more than count',
        );
        for (final category in GoldenCategory.values) {
          expect(
            all.where((p) => p.category == category),
            isNotEmpty,
            reason: 'no fixtures exercise ${category.name}',
          );
        }
      });

      test('the oracle agrees with every ground-truth fixture', () {
        final byCategory = <GoldenCategory, List<String>>{};
        for (final point in all) {
          final actual = oracle.find(point.latitude, point.longitude);
          if (actual != point.zone) {
            byCategory
                .putIfAbsent(point.category, () => <String>[])
                .add(
                  '${point.name}: expected ${point.zone ?? 'null'}, '
                  'got ${actual ?? 'null'}',
                );
          }
        }

        final report = StringBuffer();
        for (final entry in byCategory.entries) {
          report.writeln(
            '[${entry.key.name}] ${entry.value.length} failure(s)',
          );
          for (final line in entry.value) {
            report.writeln('   $line');
          }
        }
        expect(
          byCategory,
          isEmpty,
          reason:
              'Ground-truth fixtures are external facts. Resolve a failure '
              'by investigation, never by adopting the oracle\'s answer. '
              'Several failures in one category suggest a systematic bug '
              'rather than bad fixtures.\n$report',
        );
      });

      test('no ground-truth fixture sits in an overlap region', () {
        // Enforces the split between the two fixture files. A point covered by
        // two zones has no external answer — its result comes from the
        // tiebreak — so filing it as ground truth would assert a position on
        // disputed territory that this package explicitly disclaims.
        final misfiled = <String>[];
        for (final point in all) {
          if (point.zone == null) continue;
          final zones = oracle.zonesContaining(point.latitude, point.longitude);
          if (zones.length > 1) {
            misfiled.add('${point.name}: covered by ${zones.join(' + ')}');
          }
        }
        expect(
          misfiled,
          isEmpty,
          reason: 'These belong in overlap_pins.dart:\n${misfiled.join('\n')}',
        );
      });

      test('the antimeridian is a seam, not a wall', () {
        // Plan §9.3: lon 180 and lon -180 are the same meridian and must give
        // the same answer. Sampled across latitudes that cross the five split
        // zones and open ocean alike.
        for (var lat = -80.0; lat <= 80.0; lat += 5) {
          expect(
            oracle.find(lat, 180),
            oracle.find(lat, -180),
            reason: 'lon 180 and -180 disagree at latitude $lat',
          );
        }
      });

      test('the whole seam band resolves, not just its endpoints', () {
        // Comparing only exact ±180 is not enough, and this is not
        // hypothetical: an earlier normalisation tested the incoming double
        // against 180.0, so every other longitude rounding to +180000000 was
        // left on the east edge and returned null while both 180.0 and
        // 179.9999994 resolved — a ~5.5 cm strip of nothing.
        //
        // Sample latitudes where the meridian actually crosses land, so a
        // regression cannot hide behind an all-null ocean result.
        const seamLatitudes = <double>[-85, -80, 51.88, 66];
        const band = <double>[
          -180.0,
          180.0,
          179.9999999,
          179.9999998,
          179.9999995,
        ];
        for (final lat in seamLatitudes) {
          final expected = oracle.find(lat, -180);
          expect(
            expected,
            isNotNull,
            reason:
                'latitude $lat was chosen because the seam has land '
                'there; if this is null the dataset changed',
          );
          for (final lon in band) {
            expect(
              oracle.find(lat, lon),
              expected,
              reason: 'seam is discontinuous at ($lat, $lon)',
            );
          }
        }
      });

      test('overlap pins reproduce the documented tiebreak', () {
        final drift = <String>[];
        for (final pin in overlapPins) {
          final zones = oracle.zonesContaining(pin.latitude, pin.longitude);
          if (zones.length < 2) {
            drift.add(
              '${pin.description}: now covered by ${zones.length} '
              'zone(s) (${zones.join(', ')}), expected an overlap',
            );
          } else if (!_sameOrder(zones, pin.contenders)) {
            drift.add(
              '${pin.description}: contenders are now '
              '${zones.join(' + ')}, pinned as ${pin.contenders.join(' + ')}',
            );
          }
          final selected = oracle.find(pin.latitude, pin.longitude);
          if (selected != pin.selected) {
            drift.add(
              '${pin.description}: rule selects $selected, '
              'pinned as ${pin.selected}',
            );
          }
        }
        expect(
          drift,
          isEmpty,
          reason:
              'The overlap tiebreak changed. DO NOT update these pins to '
              'match. They govern which identifier is returned in disputed '
              'territories; a change needs a deliberate decision, not a '
              'refresh.\n${drift.join('\n')}',
        );
      });

      test(
        'every pin is genuinely ambiguous, and selects its first contender',
        () {
          for (final pin in overlapPins) {
            expect(
              pin.contenders.length,
              greaterThanOrEqualTo(2),
              reason:
                  '${pin.description} pins a single zone — it is ground '
                  'truth, not an overlap',
            );
            expect(pin.selected, pin.contenders.first);
          }
        },
      );
    },
  );
}

bool _sameOrder(List<String> a, List<String> b) =>
    a.length == b.length &&
    List<int>.generate(a.length, (i) => i).every((i) => a[i] == b[i]);
