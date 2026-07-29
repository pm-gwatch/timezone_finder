// Milestone 6: the runtime, against a container built from the real dataset.
//
// The bundled data arrives at milestone 8, so the index here is packed in
// memory from the oracle. That is the point of making the byte source
// injectable: the format and the lookup get exercised against all 7.6M real
// vertices before any generated source exists.
//
// The overlap pins matter most. The oracle collects every containing polygon
// and sorts; the runtime walks a list the builder pre-sorted and returns the
// first hit. Two different code paths reaching the same rule, and this is
// where they first have to agree.

@Timeout(Duration(minutes: 10))
library;

import 'dart:typed_data';

import 'dart:math';

import 'package:test/test.dart';
import 'package:timezone_finder/timezone_finder.dart';

import '../tool/src/build_index.dart';
import '../tool/src/fetch.dart';
import 'fixtures/bootstrap_goldens.dart';
import 'fixtures/golden_points.dart';
import 'fixtures/overlap_pins.dart';
import 'reference/reference_finder.dart';

void main() {
  final cached = cachedGeoJsonFile(defaultRelease);
  final available = cached.existsSync();

  group(
    'runtime',
    skip: available
        ? null
        : 'tzbb $defaultRelease data not cached. Run:\n'
              '  dart run tool/fetch_data.dart\n'
              '(downloads ~51 MB into .dart_tool/, which is gitignored)',
    () {
      late ReferenceTimeZoneFinder oracle;
      late Uint8List packed;
      late TimeZoneFinder finder;

      setUpAll(() async {
        oracle = await ReferenceTimeZoneFinder.load(cached);
        packed = buildIndex(
          dataVersion: defaultRelease,
          cellSize: 1000000,
          polygons: <SourcePolygon>[
            for (final p in oracle.polygons)
              (
                zone: p.zone,
                area: p.area,
                minX: p.minX,
                maxX: p.maxX,
                minY: p.minY,
                maxY: p.maxY,
                outer: p.outer,
                holes: p.holes,
              ),
          ],
        );
        finder = TimeZoneFinder(indexBytes: () => packed);
      });

      test('reports the dataset it was built from', () {
        expect(finder.dataVersion, defaultRelease);
        expect(finder.availableTimeZones.length, 419);
        expect(
          finder.availableTimeZones,
          orderedEquals(<String>[...finder.availableTimeZones]..sort()),
          reason: 'zone names must arrive sorted, straight from the container',
        );
        expect(finder.availableTimeZones, contains('Europe/Paris'));
        expect(finder.availableTimeZones, contains('Etc/UTC'));
      });

      test('agrees with the oracle on every ground-truth fixture', () {
        final failures = <String>[];
        for (final point in <GoldenPoint>[
          ...bootstrapGoldens,
          ...goldenPoints,
        ]) {
          final actual = finder.find(point.latitude, point.longitude);
          if (actual != point.zone) {
            failures.add(
              '${point.name}: expected ${point.zone ?? 'null'}, '
              'got ${actual ?? 'null'}',
            );
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      test('reproduces the overlap tiebreak the oracle produces', () {
        // The oracle collects all hits then sorts; the runtime returns the
        // first of a pre-sorted list. Same rule, different paths.
        final drift = <String>[];
        for (final pin in overlapPins) {
          final actual = finder.find(pin.latitude, pin.longitude);
          if (actual != pin.selected) {
            drift.add(
              '${pin.description}: runtime $actual, '
              'pinned ${pin.selected}',
            );
          }
        }
        expect(
          drift,
          isEmpty,
          reason:
              'the runtime and the oracle disagree in disputed '
              'territories:\n${drift.join('\n')}',
        );
      });

      test('agrees with the oracle on 50,000 random points', () {
        final random = Random(424242);
        var land = 0;
        final failures = <String>[];
        for (var i = 0; i < 50000; i++) {
          final lat = (random.nextInt(180000001) - 90000000) / 1000000;
          final lon = (random.nextInt(360000001) - 180000000) / 1000000;

          final expected = oracle.find(lat, lon);
          if (expected != null) land++;
          final actual = finder.find(lat, lon);
          if (actual != expected) {
            failures.add(
              '($lat, $lon): runtime ${actual ?? 'null'}, '
              'oracle ${expected ?? 'null'}',
            );
            if (failures.length > 20) break;
          }
        }
        expect(land, greaterThan(1000));
        expect(failures, isEmpty, reason: failures.take(20).join('\n'));
      });

      test('treats the antimeridian as one seam', () {
        for (final lat in <double>[-85, -80, 51.88, 66]) {
          final west = finder.find(lat, -180);
          expect(west, isNotNull, reason: 'seam has land at $lat');
          for (final lon in <double>[180, 179.9999999, 179.9999995]) {
            expect(finder.find(lat, lon), west, reason: 'seam broken at $lat');
          }
        }
      });

      test('rejects coordinates that are not coordinates', () {
        expect(() => finder.find(91, 0), throwsArgumentError);
        expect(() => finder.find(0, 181), throwsArgumentError);
        expect(() => finder.find(double.nan, 0), throwsArgumentError);
        expect(() => finder.find(0, double.infinity), throwsArgumentError);
      });

      test('ensurePreloaded is optional and idempotent', () {
        final fresh = TimeZoneFinder(indexBytes: () => packed);
        expect(fresh.find(48.8566, 2.3522), 'Europe/Paris');
        expect(fresh.ensurePreloaded(), completes);
        expect(fresh.ensurePreloaded(), completes);
        expect(fresh.find(48.8566, 2.3522), 'Europe/Paris');
      });

      test('rejects a container it cannot trust', () {
        expect(
          () => TimeZoneFinder(indexBytes: () => Uint8List(4)).find(0, 0),
          throwsA(isA<IndexFormatException>()),
          reason: 'buffer shorter than the header',
        );

        final badMagic = Uint8List.fromList(packed)..[0] ^= 0xff;
        expect(
          () => TimeZoneFinder(indexBytes: () => badMagic).find(0, 0),
          throwsA(isA<IndexFormatException>()),
        );

        final badVersion = Uint8List.fromList(packed)..[4] = 99;
        expect(
          () => TimeZoneFinder(indexBytes: () => badVersion).find(0, 0),
          throwsA(isA<IndexFormatException>()),
        );

        final truncated = Uint8List.sublistView(packed, 0, 200);
        expect(
          () => TimeZoneFinder(indexBytes: () => truncated).find(0, 0),
          throwsA(isA<IndexFormatException>()),
        );
      });

      test('says something useful when no data is bundled', () {
        // Until milestone 8 the default constructor has nothing to read.
        expect(() => TimeZoneFinder().find(0, 0), throwsStateError);
      });

      test('the packed container is the size the budget expects', () {
        final megabytes = packed.length / 1e6;
        expect(
          megabytes,
          inInclusiveRange(27.5, 29.0),
          reason:
              'container is ${megabytes.toStringAsFixed(2)} MB; plan §5.3 '
              'budgets ~28.16 MB',
        );
      });
    },
  );
}
