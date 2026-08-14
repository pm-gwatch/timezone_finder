// CI-sized differential (full 10M gate is tool/differential.dart).
// Samplers bias to boundaries/holes; uniform sampling is mostly ocean.

@Timeout(Duration(minutes: 15))
library;

import 'package:test/test.dart';
import 'package:timezone_finder/src/api/location_finder.dart';

import '../tool/release/boundaries_unsimplified.dart' as unsimplified;

import '../tool/src/differential.dart';
import '../tool/src/fetch.dart';
import 'fixtures/overlap_pins.dart';
import 'reference/reference_location_finder.dart';

/// Enough to give every sampler thousands of points without slowing the suite
/// to a crawl. The release gate is the 10M run in `tool/`.
const _points = 200000;

void main() {
  final cached = cachedGeoJsonFile(defaultRelease);
  final available = cached.existsSync();

  group(
    'differential',
    skip: available
        ? null
        : 'tzbb $defaultRelease data not cached. Run:\n'
              '  dart run tool/fetch_data.dart\n'
              '(downloads ~51 MB into .dart_tool/, which is gitignored)',
    () {
      late DifferentialReport report;

      setUpAll(() async {
        final oracle = await ReferenceLocationFinder.load(cached);
        final runtime = finderOverIndex(unsimplified.loadContainer);
        report = runDifferential(
          oracle: oracle,
          subject: runtime.findLocationName,
          points: _points,
          seed: 7,
          overlapSeeds: <({double lat, double lon})>[
            for (final pin in overlapPins)
              (lat: pin.latitude, lon: pin.longitude),
          ],
        );
      });

      test('the runtime never disagrees with the oracle', () {
        expect(
          report.disagreements,
          0,
          reason:
              'the unsimplified baseline must not disagree with the oracle at all.\n'
              '$report\n\n${report.examples.join('\n')}',
        );
      });

      test('every sampler reached land', () {
        // A sampler that never lands on a polygon proves nothing, however many
        // points it checked. Without this, a sampler could silently become a
        // no-op and the zero above would still be reported.
        expect(
          report.barrenSamplers,
          isEmpty,
          reason:
              'these samplers found only ocean, so tested nothing:\n'
              '$report',
        );
      });

      test('the sample is big enough to mean something', () {
        expect(report.checked, _points);
        expect(
          report.landHits,
          greaterThan(_points ~/ 4),
          reason: 'too few points on land to exercise the geometry',
        );
        for (final entry in report.bySampler.entries) {
          expect(
            entry.value.checked,
            greaterThan(1000),
            reason: '${entry.key} barely ran',
          );
        }
      });
    },
  );
}
