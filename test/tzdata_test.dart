// Own process: uninitialized tzdata, then `latest` (not latest_all).
// Relies on declaration order; do not pass a randomizing seed.

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as incomplete_tzdata;
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/src/api/location_finder.dart'
    show LocationFinder;
import 'package:timezone_finder/timezone_finder.dart';

void main() {
  test('says so when the database was never initialized', () {
    // Must run first: nothing has called initializeTimeZones() yet.
    expect(timeZoneDatabase.isInitialized, isFalse);

    // The coordinate itself is fine, so this must not be reported as a
    // lookup failure. package:timezone's own error here is a
    // LocationNotFoundException, which points at the wrong thing.
    expect(
      () => findLocation(2.3522, 48.8566),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('not initialized'),
            contains('initializeTimeZones'),
            contains('latest_all'),
          ),
        ),
      ),
    );

    // A point with no zone needs no database, so it still answers.
    expect(findLocation(-140, 0), isNull);

    // String.findLocation reports the same cause rather than a parse failure: the
    // Feature is well-formed, the database simply is not there yet.
    const paris =
        '{"type": "Feature", "geometry": '
        '{"type": "Point", "coordinates": [2.3522, 48.8566]}}';
    const midPacific =
        '{"type": "Feature", "geometry": '
        '{"type": "Point", "coordinates": [-140.0, 0.0]}}';
    expect(paris.findLocation, throwsStateError);

    // Except where no zone covers the point: no database is consulted.
    expect(midPacific.findLocation(), isNull);
  });

  test('names the cause when the tzdata variant omits the identifier', () {
    incomplete_tzdata.initializeTimeZones();

    // data/latest.dart drops the tzdb link identifiers: 106 of our 419 are
    // missing (313 remain). Europe/Zagreb is one of the casualties.
    expect(
      LocationFinder().findLocationName(18.0591377, 42.6634651),
      'Europe/Zagreb',
    );
    expect(
      () => findLocation(18.0591377, 42.6634651),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('Europe/Zagreb'), contains('latest_all')),
        ),
      ),
    );

    // Identifiers that are present still resolve, so this is a gap in the
    // chosen variant rather than a broken bridge.
    expect(findLocation(1.3230653, 51.1269705)!.name, 'Europe/London');
  });

  test('the gap is large enough to be worth naming in the error', () {
    final missing = <String>[];
    for (final name in LocationFinder().availableLocationNames) {
      try {
        getLocation(name);
      } on LocationNotFoundException {
        missing.add(name);
      }
    }
    expect(missing, hasLength(106));
    expect(missing, contains('Europe/Zagreb'));
  });
}
