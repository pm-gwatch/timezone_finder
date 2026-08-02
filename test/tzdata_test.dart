// Two failures that depend on the state of the global time zone database, and
// so cannot share a process with timezone_bridge_test.dart.
//
// `initializeTimeZones()` has no inverse — it clears and repopulates a global —
// so the uninitialized case has to be asserted before anything initializes,
// and the `latest` variant has to be the one this process loads. Both tests
// below rely on package:test running them in declaration order, which it does
// unless a randomizing seed is passed.

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as incomplete_tzdata;
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

void main() {
  final finder = TimeZoneFinder();

  test('says so when the database was never initialized', () {
    // Must run first: nothing has called initializeTimeZones() yet.
    expect(timeZoneDatabase.isInitialized, isFalse);

    // The coordinate itself is fine, so this must not be reported as a
    // lookup failure. package:timezone's own error here is a
    // LocationNotFoundException, which points at the wrong thing.
    expect(
      () => finder.findLocation(48.8566, 2.3522),
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
    expect(finder.findLocation(0, -140), isNull);

    // The extensions report the same cause rather than a parse or lookup
    // failure, since the coordinate itself is fine in every case.
    final utc = TZDateTime.utc(2026, 8, 23, 10, 15);
    expect(() => '48.8566,2.3522'.toLocation(), throwsStateError);
    expect(() => utc.inPlace('48.8566,2.3522'), throwsStateError);
    expect(() => utc.inPlaces(<String>['48.8566,2.3522']), throwsStateError);

    // Except where no zone covers the point: no database is consulted.
    expect(utc.inPlace('0,-140'), isNull);
  });

  test('names the cause when the tzdata variant omits the identifier', () {
    incomplete_tzdata.initializeTimeZones();

    // data/latest.dart drops the tzdb link identifiers: 341 locations against
    // our 419. Europe/Zagreb is one of the casualties, and it is a coordinate
    // the package's own example uses.
    expect(finder.findId(42.6634651, 18.0591377), 'Europe/Zagreb');
    expect(
      () => finder.findLocation(42.6634651, 18.0591377),
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
    expect(finder.findLocation(51.1269705, 1.3230653)!.name, 'Europe/London');
  });

  test('the gap is large enough to be worth naming in the error', () {
    final missing = <String>[];
    for (final name in finder.availableTimeZoneIds) {
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
