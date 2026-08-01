// The data actually shipped.
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

import 'dart:math';

import 'package:test/test.dart';
import 'package:timezone_finder/data/compact.dart' as compact_data;
import 'package:timezone_finder/data/exact.dart' as bundled;
import 'package:timezone_finder/timezone_finder.dart';

import '../tool/src/build_index.dart';
import '../tool/src/geometry.dart';
import '../tool/src/simplify.dart';
import '../tool/src/fetch.dart';
import 'fixtures/bootstrap_goldens.dart';
import 'fixtures/golden_points.dart';
import 'fixtures/overlap_pins.dart';
import 'reference/reference_finder.dart';

void main() {
  group('bundled data', () {
    final finder = TimeZoneFinder.exact();

    test('the default constructor needs no configuration', () {
      expect(finder.find(48.8566, 2.3522), 'Europe/Paris');
      expect(finder.find(-33.8688, 151.2093), 'Australia/Sydney');
      expect(finder.find(0, -140), isNull);
    });

    test('reports the release it was generated from', () {
      expect(finder.ianaDatabaseVersion, defaultRelease);
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

    test('a straight boundary is still straight in the shipped data', () {
      // Every other test in this suite checks *answers*: what identifier is at
      // this coordinate. None of them would notice if the pipeline
      // systematically bent geometry, so long as it bent it consistently.
      //
      // Brazilian law (Federal Law 12,876/2013) draws the Amazonas time zone
      // boundary as a straight line between the municipalities of Tabatinga
      // and Porto Acre. That makes it a rare natural oracle for shape rather
      // than for answers: quantization, the grid, the varint encoder and the
      // container all sit between the source polygon and this measurement, and
      // any of them distorting it would show up as a bend.
      //
      // The bracket has to be found rather than assumed: the line is oblique,
      // so a fixed western endpoint falls in Peru at the northern end and in
      // Acre at the southern one. Walk east to west until the answer flips,
      // then bisect inside that step.
      double? crossing(double latitude) {
        const step = 0.05;
        var east = -66.5;
        if (finder.find(latitude, east) != 'America/Manaus') return null;
        var west = east;
        while (west > -70.5) {
          west -= step;
          final zone = finder.find(latitude, west);
          if (zone == 'America/Eirunepe') break;
          if (zone != 'America/Manaus') return null; // left Amazonas entirely
          east = west;
        }
        if (finder.find(latitude, west) != 'America/Eirunepe') return null;
        for (var i = 0; i < 40; i++) {
          final middle = (west + east) / 2;
          if (finder.find(latitude, middle) == 'America/Eirunepe') {
            west = middle;
          } else {
            east = middle;
          }
        }
        return (west + east) / 2;
      }

      final samples = <(double, double)>[];
      for (var latitude = -4.5; latitude >= -9.5; latitude -= 0.5) {
        final longitude = crossing(latitude);
        if (longitude != null) samples.add((latitude, longitude));
      }
      expect(
        samples.length,
        11,
        reason:
            'the Manaus/Eirunepe boundary is no longer where it was; '
            'the dataset changed and this test needs re-deriving',
      );

      // Least-squares fit, then the worst residual in metres.
      final n = samples.length;
      final sx = samples.fold(0.0, (t, p) => t + p.$1);
      final sy = samples.fold(0.0, (t, p) => t + p.$2);
      final sxx = samples.fold(0.0, (t, p) => t + p.$1 * p.$1);
      final sxy = samples.fold(0.0, (t, p) => t + p.$1 * p.$2);
      final slope = (n * sxy - sx * sy) / (n * sxx - sx * sx);
      final intercept = (sy - slope * sx) / n;

      var worstMetres = 0.0;
      for (final (latitude, longitude) in samples) {
        final predicted = slope * latitude + intercept;
        final metres =
            (longitude - predicted).abs() * 111320 * cos(latitude * pi / 180);
        if (metres > worstMetres) worstMetres = metres;
      }
      // Measured: below 0.1 mm. The bound is set at half a metre instead,
      // because quantization to 1e-6 deg can move a vertex by up to ~11 cm on
      // its own — a threshold tighter than the data's own resolution would
      // fail for a legitimate reason. Anything above this is a real bend.
      expect(
        worstMetres,
        lessThan(0.5),
        reason:
            'a legally straight boundary bends by '
            '${worstMetres.toStringAsFixed(2)} m over ~555 km — more than '
            'quantization can explain, so the pipeline is distorting geometry',
      );

      // And it is the line the law describes: extrapolate to each named
      // municipality and check it arrives.
      for (final (name, latitude, longitude) in <(String, double, double)>[
        ('Tabatinga', -4.2528, -69.9386),
        ('Porto Acre', -9.5928, -67.5403),
      ]) {
        final predicted = slope * latitude + intercept;
        final km =
            (longitude - predicted).abs() *
            111320 *
            cos(latitude * pi / 180) /
            1000;
        expect(
          km,
          lessThan(3),
          reason:
              'the boundary line misses $name by '
              '${km.toStringAsFixed(1)} km',
        );
      }
    });

    test('two finders share nothing that would corrupt the other', () {
      final a = TimeZoneFinder.exact();
      final b = TimeZoneFinder.exact();
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
      test('the exact tier, byte for byte', () async {
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

      test('the compact tier, byte for byte', () async {
        // Without this a stale compact tier would ship silently: every other
        // compact test compares it against the exact tier's answers, which
        // says nothing about whether it was regenerated from current source.
        final oracle = await ReferenceTimeZoneFinder.load(
          cachedGeoJsonFile(defaultRelease),
        );
        final stats = SimplifyStats();
        final simplified = <SourcePolygon>[];
        for (final p in oracle.polygons) {
          final result = simplifyPolygon(p.outer, p.holes, 1000, stats);
          if (result == null) continue;
          simplified.add((
            zone: p.zone,
            area: polygonDoubledArea(result.outer, result.holes),
            minX: _extent(result.outer, 0, min: true),
            maxX: _extent(result.outer, 0, min: false),
            minY: _extent(result.outer, 1, min: true),
            maxY: _extent(result.outer, 1, min: false),
            outer: result.outer,
            holes: result.holes,
          ));
        }
        final fresh = buildIndex(
          dataVersion: defaultRelease,
          cellSize: 1000000,
          polygons: simplified,
        );
        final shipped = compact_data.loadContainer();
        expect(
          shipped.length,
          fresh.length,
          reason: 'compact tier is stale; regenerate with tool/refresh.dart',
        );
        for (var i = 0; i < fresh.length; i++) {
          if (shipped[i] != fresh[i]) {
            fail('compact bundled bytes differ at offset $i');
          }
        }
      });
    },
  );
}

int _extent(List<int> ring, int offset, {required bool min}) {
  var value = ring[offset];
  for (var i = offset; i < ring.length; i += 2) {
    if (min ? ring[i] < value : ring[i] > value) value = ring[i];
  }
  return value;
}
