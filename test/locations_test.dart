// The package:timezone bridge: findLocation, toLocation, inLocation(s).
//
// Initialized from `latest_all` here, which is the variant the package
// documents. The consequences of choosing `latest` instead are covered in
// locations_tzdata_test.dart, which needs a differently initialized process.
//
// Needs no boundary GeoJSON — the index is bundled.

import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

void main() {
  final finder = TimeZoneFinder();

  // Bound in setUpAll, not at declaration: group bodies run while tests are
  // being collected, which is before any setUpAll has initialized the
  // database.
  late final Location paris;
  late final Location newYork;
  late final Location tokyo;

  setUpAll(() {
    tzdata.initializeTimeZones();
    paris = getLocation('Europe/Paris');
    newYork = getLocation('America/New_York');
    tokyo = getLocation('Asia/Tokyo');
  });

  group('findLocation', () {
    test('returns the Location for the identifier find returns', () {
      final paris = finder.findLocation(48.8566, 2.3522)!;
      expect(paris.name, 'Europe/Paris');
      expect(paris, same(getLocation('Europe/Paris')));
    });

    test('returns null exactly where find returns null', () {
      expect(finder.find(0, -140), isNull);
      expect(finder.findLocation(0, -140), isNull);
    });

    test('rejects the same coordinates find rejects', () {
      expect(() => finder.findLocation(91, 0), throwsArgumentError);
      expect(() => finder.findLocation(0, 181), throwsArgumentError);
      expect(() => finder.findLocation(double.nan, 0), throwsArgumentError);
    });

    test('resolves every identifier in the dataset', () {
      // The version-skew guard. Our boundaries track timezone-boundary-builder
      // releases; package:timezone bundles tzdata on its own cadence. A future
      // tzbb identifier can arrive before the other side has it, and this is
      // where that should be reported — not in a user's application.
      final missing = <String>[];
      for (final name in finder.availableTimeZones) {
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
            'boundary release ${finder.ianaDatabaseVersion}: '
            '${missing.join(', ')}',
      );
    });
  });

  group('String.toLocation', () {
    test('parses a coordinate pair', () {
      expect('48.8566,2.3522'.toLocation(using: finder)!.name, 'Europe/Paris');
    });

    test('tolerates whitespace around either number', () {
      for (final text in <String>[
        '48.8566, 2.3522',
        ' 48.8566,2.3522 ',
        '48.8566 , 2.3522',
      ]) {
        expect(
          text.toLocation(using: finder)!.name,
          'Europe/Paris',
          reason: text,
        );
      }
    });

    test('handles negative and integer-valued coordinates', () {
      expect(
        '-33.8688,151.2093'.toLocation(using: finder)!.name,
        'Australia/Sydney',
      );
      expect('51,0'.toLocation(using: finder)!.name, 'Europe/London');
    });

    test('returns null for a point no zone covers', () {
      expect('0,-140'.toLocation(using: finder), isNull);
    });

    test('throws FormatException on anything that is not two numbers', () {
      for (final text in <String>[
        '',
        'Europe/Paris',
        '48.8566',
        '48.8566,2.3522,0',
        '48.8566;2.3522',
        ',',
        '48.8566,',
        'north,east',
        // A European decimal comma cannot be told apart from the separator,
        // so it must fail rather than be guessed at.
        '48,8566, 2,3522',
      ]) {
        expect(
          () => text.toLocation(using: finder),
          throwsFormatException,
          reason: 'accepted ${text.isEmpty ? '<empty>' : text}',
        );
      }
    });

    test('throws ArgumentError when the numbers are not coordinates', () {
      expect(() => '91,0'.toLocation(using: finder), throwsArgumentError);
      expect(() => '0,181'.toLocation(using: finder), throwsArgumentError);
      expect(() => 'NaN,0'.toLocation(using: finder), throwsArgumentError);
    });

    test('separates "not a coordinate" from "no zone here"', () {
      // The distinction the whole contract rests on: a typo must not look
      // like the middle of the Pacific.
      expect(() => 'oops'.toLocation(using: finder), throwsFormatException);
      expect('0,-140'.toLocation(using: finder), isNull);
    });

    test('reversed coordinates parse, which is why order is documented', () {
      // Not a bug to fix — a hazard to pin. GeoJSON is lon,lat, and a swapped
      // pair is usually still a valid coordinate somewhere else entirely.
      expect('48.8566,2.3522'.toLocation(using: finder)!.name, 'Europe/Paris');
      expect(
        '2.3522,48.8566'.toLocation(using: finder)?.name,
        isNot('Europe/Paris'),
      );
    });
  });

  group('TZDateTime.inLocation', () {
    test('keeps the instant and changes the wall clock', () {
      final takeOff = TZDateTime(paris, 2026, 8, 23, 10, 15);
      final there = takeOff.inLocation(newYork);

      expect(
        there.millisecondsSinceEpoch,
        takeOff.millisecondsSinceEpoch,
        reason: 'inLocation must not move the moment',
      );
      expect(there.location, same(newYork));
      expect(there.hour, 4); // 10:15 CEST is 04:15 EDT
      expect(there.day, 23);
    });

    test('crosses the date line where the zones require it', () {
      final evening = TZDateTime(paris, 2026, 8, 23, 23, 30);
      expect(evening.inLocation(tokyo).day, 24);
      expect(evening.inLocation(newYork).day, 23);
    });

    test('is a no-op onto its own location', () {
      final start = TZDateTime(paris, 2026, 8, 23, 17, 30);
      expect(start.inLocation(paris), start);
    });

    test('tracks daylight saving rather than a fixed offset', () {
      // The reason a Location is not an offset: the same pair of zones is
      // 6 hours apart in August and 6 hours apart in January only because
      // both happen to shift. New York alone moves by an hour.
      final summer = TZDateTime(paris, 2026, 8, 23, 12).inLocation(newYork);
      final winter = TZDateTime(paris, 2026, 1, 23, 12).inLocation(newYork);
      expect(summer.timeZoneOffset, const Duration(hours: -4));
      expect(winter.timeZoneOffset, const Duration(hours: -5));
    });
  });

  group('TZDateTime.inLocations', () {
    test('returns one entry per location, in order', () {
      final start = TZDateTime(paris, 2026, 8, 23, 17, 30);
      final elsewhere = start.inLocations(<Location>[newYork, tokyo]);

      expect(elsewhere, hasLength(2));
      expect(elsewhere[0].location, same(newYork));
      expect(elsewhere[1].location, same(tokyo));
    });

    test('every entry is the same instant as the receiver', () {
      final start = TZDateTime(paris, 2026, 8, 23, 17, 30);
      for (final other in start.inLocations(<Location>[
        newYork,
        tokyo,
        paris,
      ])) {
        expect(other.millisecondsSinceEpoch, start.millisecondsSinceEpoch);
      }
    });

    test('an empty list yields an empty list', () {
      final start = TZDateTime(paris, 2026, 8, 23, 17, 30);
      expect(start.inLocations(const <Location>[]), isEmpty);
    });

    test('does not include the receiver location unless asked', () {
      final start = TZDateTime(paris, 2026, 8, 23, 17, 30);
      final elsewhere = start.inLocations(<Location>[newYork]);
      expect(elsewhere.map((d) => d.location.name), <String>[
        'America/New_York',
      ]);
    });

    test('agrees with inLocation applied one at a time', () {
      final start = TZDateTime(paris, 2026, 8, 23, 17, 30);
      expect(start.inLocations(<Location>[newYork, tokyo]), <TZDateTime>[
        start.inLocation(newYork),
        start.inLocation(tokyo),
      ]);
    });
  });

  test('a coordinate string reaches a civil time end to end', () {
    // The path the package exists to make short: two coordinates, one
    // instant, each rendered where it belongs.
    final charlesDeGaulle = '49.0097,2.5479'.toLocation(using: finder)!;
    final jfk = '40.6413,-73.7781'.toLocation(using: finder)!;

    final takeOff = TZDateTime(charlesDeGaulle, 2026, 8, 23, 10, 15);
    final landing = takeOff.add(const Duration(hours: 8, minutes: 20));

    expect(charlesDeGaulle.name, 'Europe/Paris');
    expect(jfk.name, 'America/New_York');
    expect(landing.inLocation(jfk).hour, 12);
    expect(landing.inLocation(jfk).day, 23);
  });
}
