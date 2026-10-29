// Location helpers: findLocation.
// Uses latest_all (latest is tzdata_test.dart, separate process).
// Index is bundled.

import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/src/location_finder.dart' show LocationFinder;
import 'package:timezone_finder/timezone_finder.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('findLocation', () {
    test('returns a Location whose name is the IANA identifier', () {
      final paris = findLocation(2.3522, 48.8566)!;
      expect(paris.name, 'Europe/Paris');
      expect(paris, same(getLocation('Europe/Paris')));
    });

    test('returns null for open ocean', () {
      expect(findLocation(-140, 0), isNull);
    });

    test('rejects invalid coordinates', () {
      expect(() => findLocation(0, 91), throwsArgumentError);
      expect(() => findLocation(0, -91), throwsArgumentError);
      expect(() => findLocation(181, 0), throwsArgumentError);
      expect(() => findLocation(-181, 0), throwsArgumentError);
      expect(() => findLocation(0, double.nan), throwsArgumentError);
      expect(() => findLocation(double.nan, 0), throwsArgumentError);
      expect(() => findLocation(double.infinity, 0), throwsArgumentError);
      expect(
        () => findLocation(0, double.negativeInfinity),
        throwsArgumentError,
      );
    });

    test('resolves every identifier in the dataset', () {
      // The version-skew guard. Our boundaries track timezone-boundary-builder
      // releases; package:timezone bundles tzdata on its own cadence. A future
      // tzbb identifier can arrive before the other side has it, and this is
      // where that should be reported — not in a user's application.
      final missing = <String>[];
      for (final name in LocationFinder().availableLocationNames) {
        try {
          getLocation(name);
        } on LocationNotFoundException {
          missing.add(name);
        }
      }
      expect(
        missing,
        isEmpty,
        reason:
            'package:timezone (tzdata) no longer carries every identifier in '
            'boundary release $boundaryDataVersion: '
            '${missing.join(', ')}',
      );
    });
  });

  test('a geocoder answer reaches a civil time end to end', () {
    // The path the package exists to make short: two geocoded places, one
    // instant, each rendered where it belongs.
    final charlesDeGaulle = findLocation(2.5479, 49.0097)!;
    final jfk = findLocation(-73.7781, 40.6413)!;

    final takeOff = TZDateTime(charlesDeGaulle, 2026, 8, 23, 10, 15);
    final landing = takeOff.add(const Duration(hours: 8, minutes: 20));
    final landingInNewYork = TZDateTime.from(landing, jfk);

    expect(charlesDeGaulle.name, 'Europe/Paris');
    expect(jfk.name, 'America/New_York');
    expect(landingInNewYork.hour, 12);
    expect(landingInNewYork.day, 23);
  });
}
