// Integrity tests for the bootstrap golden fixtures.
//
// There is no lookup implementation yet (milestone 1), so these tests validate
// the fixture file's own consistency rather than any behaviour. They make the
// integrity of the ground-truth set a CI concern instead of a review-time hope.
//
// The external cross-check — that each coordinate really maps to its claimed
// zone — is documented in test/fixtures/README.md and is deliberately not run
// here: it needs a Python dependency this repository does not carry.

import 'package:test/test.dart';

import 'fixtures/bootstrap_goldens.dart';

void main() {
  group('bootstrap goldens', () {
    test('the set is large enough to be a meaningful bootstrap', () {
      expect(bootstrapGoldens.length, greaterThanOrEqualTo(50));
    });

    test('latitudes are within [-90, 90]', () {
      for (final point in bootstrapGoldens) {
        expect(
          point.latitude,
          inInclusiveRange(-90, 90),
          reason: 'latitude out of range for ${point.name}',
        );
      }
    });

    test('longitudes are within [-180, 180]', () {
      for (final point in bootstrapGoldens) {
        expect(
          point.longitude,
          inInclusiveRange(-180, 180),
          reason: 'longitude out of range for ${point.name}',
        );
      }
    });

    test('coordinates are finite', () {
      for (final point in bootstrapGoldens) {
        expect(point.latitude.isFinite, isTrue, reason: point.name);
        expect(point.longitude.isFinite, isTrue, reason: point.name);
      }
    });

    test('identifiers are well-formed IANA names', () {
      // Area/Location, optionally Area/Region/Location. Letters, digits,
      // underscores and hyphens only; no trailing or doubled separators.
      final pattern = RegExp(r'^[A-Za-z][A-Za-z0-9_+-]*'
          r'(?:/[A-Za-z][A-Za-z0-9_+-]*){1,2}$');
      for (final point in bootstrapGoldens) {
        expect(
          point.zone,
          matches(pattern),
          reason: 'malformed identifier for ${point.name}',
        );
      }
    });

    test('no duplicate coordinates', () {
      final seen = <String, String>{};
      for (final point in bootstrapGoldens) {
        final key = '${point.latitude},${point.longitude}';
        expect(
          seen,
          isNot(contains(key)),
          reason: '${point.name} duplicates the coordinates of ${seen[key]}',
        );
        seen[key] = point.name;
      }
    });

    test('no duplicate labels', () {
      final names = bootstrapGoldens.map((p) => p.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('a point never claims the exact null island origin', () {
      // (0, 0) is in the Gulf of Guinea and is the classic sign of a
      // coordinate that failed to parse.
      for (final point in bootstrapGoldens) {
        expect(
          point.latitude == 0 && point.longitude == 0,
          isFalse,
          reason: '${point.name} sits at (0, 0)',
        );
      }
    });

    test('coverage spans multiple continents and many zones', () {
      final areas = bootstrapGoldens.map((p) => p.zone.split('/').first).toSet();
      expect(
        areas,
        containsAll(<String>['Europe', 'America', 'Africa', 'Asia']),
      );
      expect(
        bootstrapGoldens.map((p) => p.zone).toSet().length,
        greaterThanOrEqualTo(50),
        reason: 'too many points share a zone to exercise an index',
      );
    });

    test('several countries are sampled in more than one zone', () {
      // An index that collapses a large country to one answer must fail
      // somewhere. Russia, Australia and the USA are the cheapest detectors.
      String? zoneOf(String label) => bootstrapGoldens
          .where((p) => p.name == label)
          .map((p) => p.zone)
          .firstOrNull;

      expect(zoneOf('Perth, Australia'), isNot(zoneOf('Sydney, Australia')));
      expect(
        zoneOf('Vladivostok, Russia'),
        isNot(zoneOf('Yekaterinburg, Russia')),
      );
      expect(zoneOf('Phoenix, USA'), isNot(zoneOf('Denver, USA')));
    });
  });
}
