// Milestone 5: the shortcut grid must never drop a polygon.
//
// The grid is a filter, not an answer: it narrows 1,184 polygons to a handful
// and point-in-polygon decides among those. That is only sound if the handful
// always contains every polygon that could have won. A grid that returns a
// wrong-but-plausible answer is far worse than one that is slow, and nothing
// else in the suite would notice — the oracle does not use the grid.
//
// So these tests compare a grid-filtered lookup against the oracle directly,
// over the fixtures and over a large random sample.

@Timeout(Duration(minutes: 10))
library;

import 'package:test/test.dart';
import 'package:timezone_finder/src/quantization.dart';

import '../tool/src/fetch.dart';
import '../tool/src/geometry.dart';
import '../tool/src/grid.dart';
import 'fixtures/bootstrap_goldens.dart';
import 'fixtures/golden_points.dart';
import 'reference/reference_finder.dart';

/// The resolution milestone 5 selected. See plan §6.1.
const _chosenCellSize = 1000000;

void main() {
  final cached = cachedGeoJsonFile(defaultRelease);
  final available = cached.existsSync();

  group(
    'shortcut grid',
    skip: available
        ? null
        : 'tzbb $defaultRelease data not cached. Run:\n'
              '  dart run tool/fetch_data.dart\n'
              '(downloads ~51 MB into .dart_tool/, which is gitignored)',
    () {
      late ReferenceTimeZoneFinder oracle;
      late BuiltGrid grid;

      setUpAll(() async {
        oracle = await ReferenceTimeZoneFinder.load(cached);
        grid = buildGrid(const GridSpec(_chosenCellSize), <PolygonBox>[
          for (var i = 0; i < oracle.polygons.length; i++)
            (
              id: i,
              minX: oracle.polygons[i].minX,
              maxX: oracle.polygons[i].maxX,
              minY: oracle.polygons[i].minY,
              maxY: oracle.polygons[i].maxY,
              area: oracle.polygons[i].area,
              zone: oracle.polygons[i].zone,
            ),
        ]);
      });

      /// What the runtime will do: filter by grid, then test geometry.
      String? gridFind(double latitude, double longitude) {
        final x = quantizeQueryLongitude(longitude);
        final y = quantize(latitude);
        ReferencePolygon? best;
        for (final id in grid.candidatesAt(x, y)) {
          final polygon = oracle.polygons[id];
          if (!polygon.contains(x, y)) continue;
          if (best == null ||
              comparePrecedence(
                    polygon.area,
                    polygon.zone,
                    best.area,
                    best.zone,
                  ) <
                  0) {
            best = polygon;
          }
        }
        return best?.zone;
      }

      test('agrees with the oracle on every ground-truth fixture', () {
        final failures = <String>[];
        for (final point in <GoldenPoint>[
          ...bootstrapGoldens,
          ...goldenPoints,
        ]) {
          final viaGrid = gridFind(point.latitude, point.longitude);
          final direct = oracle.find(point.latitude, point.longitude);
          if (viaGrid != direct) {
            failures.add(
              '${point.name}: grid ${viaGrid ?? 'null'}, '
              'oracle ${direct ?? 'null'}',
            );
          }
        }
        expect(
          failures,
          isEmpty,
          reason:
              'the grid dropped a polygon the oracle found:\n'
              '${failures.join('\n')}',
        );
      });

      test('agrees with the oracle on 50,000 random points', () {
        // Uniform over the globe, so most land here.  Ocean points matter too:
        // a grid that wrongly marked a cell empty would return null where the
        // oracle finds a zone, and only a sample this size reliably lands in
        // the thin coastal cells where that would show.
        var seed = 20260728;
        var checked = 0;
        var land = 0;
        final failures = <String>[];
        while (checked < 50000) {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          final lat = ((seed % 180000000) - 90000000) / 1000000;
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          final lon = ((seed % 360000000) - 180000000) / 1000000;
          checked++;

          final direct = oracle.find(lat, lon);
          if (direct != null) land++;
          final viaGrid = gridFind(lat, lon);
          if (viaGrid != direct) {
            failures.add(
              '($lat, $lon): grid ${viaGrid ?? 'null'}, '
              'oracle ${direct ?? 'null'}',
            );
            if (failures.length > 20) break;
          }
        }
        expect(land, greaterThan(1000), reason: 'sample barely touched land');
        expect(
          failures,
          isEmpty,
          reason:
              '${failures.length} disagreement(s):\n'
              '${failures.take(20).join('\n')}',
        );
      });

      test('never omits a polygon that contains the point', () {
        // Stronger than agreeing on the final answer: even a polygon that
        // loses the precedence tiebreak must be offered to the geometry test,
        // or an overlap would resolve differently once the runtime replaces
        // the oracle's linear scan.
        var seed = 987654321;
        final failures = <String>[];
        for (var i = 0; i < 20000; i++) {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          final latUnits = (seed % 180000000) - 90000000;
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          final lonUnits = (seed % 360000000) - 180000000;

          final containing = <int>[];
          for (var p = 0; p < oracle.polygons.length; p++) {
            if (oracle.polygons[p].contains(lonUnits, latUnits)) {
              containing.add(p);
            }
          }
          if (containing.isEmpty) continue;

          final offered = grid.candidatesAt(lonUnits, latUnits).toSet();
          for (final id in containing) {
            if (!offered.contains(id)) {
              failures.add(
                '($latUnits, $lonUnits): polygon $id '
                '(${oracle.polygons[id].zone}) contains the point but was '
                'not offered',
              );
            }
          }
        }
        expect(failures.take(10), isEmpty);
      });

      test('resolves the poles and the antimeridian seam', () {
        for (final lon in <double>[-180, 180, 0, 179.9999999]) {
          for (final lat in <double>[-90, -89, 89, 90]) {
            expect(
              gridFind(lat, lon),
              oracle.find(lat, lon),
              reason: 'grid and oracle disagree at ($lat, $lon)',
            );
          }
        }
      });

      test('the filter is strong enough to be worth having', () {
        // If the grid did not narrow the search it would be pure overhead.
        expect(grid.spec.cellCount, 64800);
        expect(grid.percentileLength(50), lessThanOrEqualTo(4));
        expect(grid.percentileLength(95), lessThanOrEqualTo(8));
        expect(
          grid.candidateLengths.last,
          lessThan(100),
          reason: 'worst-case candidate list is out of hand',
        );
      });

      test('the serialized grid is far smaller than the coordinate blob', () {
        // Plan §5.3 estimated 1–3 MB for the grid. Measured, the raw cell
        // array at this resolution is ~275 KB, so the index total is
        // essentially the 27.8 MB of coordinates.
        expect(grid.serializedBytes, lessThan(1000000));
      });
    },
  );
}
