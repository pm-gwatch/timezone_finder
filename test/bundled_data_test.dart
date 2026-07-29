// Milestone 8: the data actually shipped.
//
// Everything until now tested a container packed in memory. These tests use
// what a consumer gets — the base64 chunks under `lib/data/`, decoded through
// the default constructor.
//
// Most of this needs no boundary data at all, which is the point: once the
// index is bundled, the fixtures can be checked on a fresh clone with no 51 MB
// download. The one test that does need the cache is the round-trip check
// against a freshly packed container, since that is the only thing proving the
// emit and decode steps did not corrupt anything.

@Timeout(Duration(minutes: 10))
library;

import 'package:test/test.dart';
import 'package:timezone_finder/data/exact.dart' as bundled;
import 'package:timezone_finder/timezone_finder.dart';

import '../tool/src/build_index.dart';
import '../tool/src/fetch.dart';
import 'fixtures/bootstrap_goldens.dart';
import 'fixtures/golden_points.dart';
import 'fixtures/overlap_pins.dart';
import 'reference/reference_finder.dart';

void main() {
  group('bundled data', () {
    final finder = TimeZoneFinder();

    test('the default constructor needs no configuration', () {
      expect(finder.find(48.8566, 2.3522), 'Europe/Paris');
      expect(finder.find(-33.8688, 151.2093), 'Australia/Sydney');
      expect(finder.find(0, -140), isNull);
    });

    test('reports the release it was generated from', () {
      expect(finder.dataVersion, defaultRelease);
      expect(finder.availableTimeZones.length, 419);
      expect(
        finder.availableTimeZones,
        orderedEquals(<String>[...finder.availableTimeZones]..sort()),
      );
    });

    test('resolves every ground-truth fixture', () {
      final failures = <String>[];
      for (final point in <GoldenPoint>[...bootstrapGoldens, ...goldenPoints]) {
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

    test('reproduces the overlap tiebreak', () {
      for (final pin in overlapPins) {
        expect(
          finder.find(pin.latitude, pin.longitude),
          pin.selected,
          reason: pin.description,
        );
      }
    });

    test('treats the antimeridian as one seam', () {
      for (final lat in <double>[-85, -80, 51.88, 66]) {
        final west = finder.find(lat, -180);
        expect(west, isNotNull);
        for (final lon in <double>[180, 179.9999999, 179.9999995]) {
          expect(finder.find(lat, lon), west, reason: 'seam broken at $lat');
        }
      }
    });

    test('rejects coordinates that are not coordinates', () {
      expect(() => finder.find(91, 0), throwsArgumentError);
      expect(() => finder.find(0, 181), throwsArgumentError);
      expect(() => finder.find(double.nan, 0), throwsArgumentError);
    });

    test('two finders share nothing that would corrupt the other', () {
      final a = TimeZoneFinder();
      final b = TimeZoneFinder();
      expect(a.find(48.8566, 2.3522), 'Europe/Paris');
      expect(b.find(35.6762, 139.6503), 'Asia/Tokyo');
      expect(a.find(35.6762, 139.6503), 'Asia/Tokyo');
      expect(b.find(48.8566, 2.3522), 'Europe/Paris');
    });
  });

  group(
    'bundled data matches a freshly packed container',
    skip: cachedGeoJsonFile(defaultRelease).existsSync()
        ? null
        : 'tzbb $defaultRelease data not cached. Run:\n'
              '  dart run tool/fetch_data.dart',
    () {
      test('byte for byte, and answer for answer', () async {
        // The only check that the emit → base64 → decode round trip is
        // lossless. If it were not, every other test here would still pass
        // while the shipped answers quietly drifted from the source data.
        final oracle = await ReferenceTimeZoneFinder.load(
          cachedGeoJsonFile(defaultRelease),
        );
        final fresh = buildIndex(
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

        final bundledBytes = bundled.loadContainer();
        expect(
          bundledBytes.length,
          fresh.length,
          reason:
              'bundled container is a different size from a fresh pack — '
              'lib/data is stale, regenerate with tool/generate_data.dart',
        );
        var firstDifference = -1;
        for (var i = 0; i < fresh.length; i++) {
          if (bundledBytes[i] != fresh[i]) {
            firstDifference = i;
            break;
          }
        }
        expect(
          firstDifference,
          -1,
          reason:
              'bundled bytes differ at offset '
              '$firstDifference',
        );
      });
    },
  );
}
