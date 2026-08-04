// The package:timezone bridge: findLocation, toLocation and inLocation(s).
//
// Initialized from `latest_all` here, which is the variant the package
// documents. The consequences of choosing `latest` instead are covered in
// tzdata_test.dart, which needs a differently initialized process.
//
// Needs no boundary GeoJSON — the index is bundled.

import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

/// A minimal RFC 7946 Feature. `properties` is omitted deliberately: the
/// package does not require it, and every hand-written fixture would carry
/// `"properties": null` as noise if it did.
String feature(double longitude, double latitude) =>
    '{"type": "Feature", "geometry": '
    '{"type": "Point", "coordinates": [$longitude, $latitude]}}';

/// Nominatim's answer for Heathrow, byte for byte as the service returns it
/// (trimmed to the members this package reads plus the ones it ignores). If
/// either service changes shape, this fails here rather than in an
/// application.
const nominatimHeathrow =
    '{"type": "Feature", "properties": {"place_id": 280595718, '
    '"osm_type": "relation", "name": "London Heathrow Airport"}, '
    '"bbox": [-0.4943776, 51.4560987, -0.4151697, 51.4794056], '
    '"geometry": {"type": "Point", '
    '"coordinates": [-0.4587801, 51.467739]}}';

/// Photon's answer for Mumbai, in the same shape.
const photonMumbai =
    '{"type": "Feature", "properties": {"osm_type": "W", '
    '"name": "Chhatrapati Shivaji Maharaj International Airport", '
    '"countrycode": "IN"}, "geometry": {"type": "Point", '
    '"coordinates": [72.8638223, 19.0901376]}}';

void main() {
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
    test(
      'returns the Location for the identifier findTimeZoneName returns',
      () {
        final paris = findLocation(48.8566, 2.3522)!;
        expect(paris.name, 'Europe/Paris');
        expect(paris, same(getLocation('Europe/Paris')));
      },
    );

    test('returns null exactly where findTimeZoneName returns null', () {
      expect(findTimeZoneName(0, -140), isNull);
      expect(findLocation(0, -140), isNull);
    });

    test('rejects the same coordinates findTimeZoneName rejects', () {
      expect(() => findLocation(91, 0), throwsArgumentError);
      expect(() => findLocation(0, 181), throwsArgumentError);
      expect(() => findLocation(double.nan, 0), throwsArgumentError);
    });

    test('resolves every identifier in the dataset', () {
      // The version-skew guard. Our boundaries track timezone-boundary-builder
      // releases; package:timezone bundles tzdata on its own cadence. A future
      // tzbb identifier can arrive before the other side has it, and this is
      // where that should be reported — not in a user's application.
      final missing = <String>[];
      for (final name in availableTimeZoneIds) {
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
            'boundary release $ianaDatabaseVersion: '
            '${missing.join(', ')}',
      );
    });
  });

  group('String.toLocation', () {
    test('resolves a GeoJSON Feature', () {
      expect(feature(2.3522, 48.8566).toLocation()!.name, 'Europe/Paris');
    });

    test('reads real geocoder answers unchanged', () {
      // The shape these two services actually return. A change at either end
      // fails here rather than in someone's application.
      expect(nominatimHeathrow.toLocation()!.name, 'Europe/London');
      expect(photonMumbai.toLocation()!.name, 'Asia/Kolkata');
    });

    test('ignores altitude in a 3D position', () {
      // RFC 7946 3.1.1 allows a third element. It must be discarded, not
      // mistaken for latitude.
      const withAltitude =
          '{"type": "Feature", "geometry": {"type": "Point", '
          '"coordinates": [2.3522, 48.8566, 35.0]}}';
      expect(withAltitude.toLocation()!.name, 'Europe/Paris');
    });

    test('does not require properties, though RFC 7946 lists it', () {
      // Nothing here reads it, so rejecting an otherwise-usable Feature over
      // an ignored member would be gratuitous — and would force every
      // hand-written example to carry `"properties": null`.
      expect(
        feature(151.2093, -33.8688).toLocation()!.name,
        'Australia/Sydney',
      );
      const withProperties =
          '{"type": "Feature", "properties": {"name": "Sydney"}, '
          '"geometry": {"type": "Point", "coordinates": [151.2093, -33.8688]}}';
      expect(withProperties.toLocation()!.name, 'Australia/Sydney');
    });

    test('accepts a bare Point geometry as well as a Feature', () {
      // RFC 7946 3: a GeoJSON object is a Geometry, a Feature, or a
      // collection. Two of those name one place. A Feature is a Point plus
      // metadata this package ignores, so refusing the Point itself would be
      // arbitrary.
      const point = '{"type": "Point", "coordinates": [2.3522, 48.8566]}';
      expect(point.toLocation()!.name, 'Europe/Paris');
      expect(point.toLocation(), same(feature(2.3522, 48.8566).toLocation()));
    });

    test('a bare Point takes the same contract as a Feature', () {
      const ocean = '{"type": "Point", "coordinates": [-140.0, 0.0]}';
      const withAltitude =
          '{"type": "Point", "coordinates": [2.3522, 48.8566, 35.0]}';
      const offEarth = '{"type": "Point", "coordinates": [0.0, 91.0]}';
      const shortPosition = '{"type": "Point", "coordinates": [2.3522]}';

      expect(ocean.toLocation(), isNull);
      expect(withAltitude.toLocation()!.name, 'Europe/Paris');
      expect(() => offEarth.toLocation(), throwsArgumentError);
      expect(() => shortPosition.toLocation(), throwsFormatException);
    });

    test('returns null for a point no zone covers', () {
      expect(feature(-140, 0).toLocation(), isNull);
    });

    test('rejects a FeatureCollection, which is several places', () {
      // Both geocoders wrap their answer in one. Picking a feature is the
      // caller's decision, not ours — the error says so.
      const collection =
          '{"type": "FeatureCollection", "features": [$photonMumbai]}';
      expect(
        () => collection.toLocation(),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('FeatureCollection'),
          ),
        ),
      );
    });

    test('throws FormatException on anything that is not a Point Feature', () {
      const cases = <String, String>{
        'empty': '',
        'not JSON': 'Europe/Paris',
        'not an object': '[1, 2]',
        'null geometry': '{"type": "Feature", "geometry": null}',
        'geometry not an object': '{"type": "Feature", "geometry": "Point"}',
        'a MultiPoint, which is several places':
            '{"type": "MultiPoint", "coordinates": [[2.35, 48.85]]}',
        'a GeometryCollection':
            '{"type": "GeometryCollection", "geometries": []}',
        'wrong geometry type':
            '{"type": "Feature", "geometry": {"type": "Polygon", '
            '"coordinates": [[[0, 0], [1, 0], [1, 1], [0, 0]]]}}',
        'lower-case type':
            '{"type": "feature", "geometry": {"type": "Point", '
            '"coordinates": [2.35, 48.85]}}',
        'coordinates missing':
            '{"type": "Feature", "geometry": {"type": "Point"}}',
        'coordinates too short':
            '{"type": "Feature", "geometry": {"type": "Point", '
            '"coordinates": [2.35]}}',
        'coordinates too long':
            '{"type": "Feature", "geometry": {"type": "Point", '
            '"coordinates": [2.35, 48.85, 0, 0]}}',
        'coordinates not numbers':
            '{"type": "Feature", "geometry": {"type": "Point", '
            '"coordinates": ["2.35", "48.85"]}}',
      };
      cases.forEach((label, text) {
        expect(
          () => text.toLocation(),
          throwsFormatException,
          reason: 'accepted: $label',
        );
      });
    });

    test('throws ArgumentError when the position is not on Earth', () {
      expect(() => feature(0, 91).toLocation(), throwsArgumentError);
      expect(() => feature(181, 0).toLocation(), throwsArgumentError);
    });

    test('a non-finite coordinate cannot survive JSON at all', () {
      // JSON has no NaN or Infinity literal, so these never reach the range
      // check — they fail while being decoded. Worth pinning: it means
      // ArgumentError here only ever means "out of range".
      expect(() => feature(0, double.nan).toLocation(), throwsFormatException);
      expect(
        () => feature(double.infinity, 0).toLocation(),
        throwsFormatException,
      );
    });

    test('separates "not a Feature" from "no zone here"', () {
      // The distinction the whole contract rests on: a malformed document
      // must not look like the middle of the Pacific.
      expect(() => 'oops'.toLocation(), throwsFormatException);
      expect(feature(-140, 0).toLocation(), isNull);
    });

    test('a hand-reversed position resolves elsewhere, silently', () {
      // The hazard this parsing exists to remove. It now survives only in
      // documents written by hand — a geocoder always emits [lon, lat].
      expect(feature(2.3522, 48.8566).toLocation()!.name, 'Europe/Paris');
      expect(
        feature(48.8566, 2.3522).toLocation()?.name,
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

  test('a geocoder answer reaches a civil time end to end', () {
    // The path the package exists to make short: two geocoded places, one
    // instant, each rendered where it belongs.
    final charlesDeGaulle = feature(2.5479, 49.0097).toLocation()!;
    final jfk = feature(-73.7781, 40.6413).toLocation()!;

    final takeOff = TZDateTime(charlesDeGaulle, 2026, 8, 23, 10, 15);
    final landing = takeOff.add(const Duration(hours: 8, minutes: 20));

    expect(charlesDeGaulle.name, 'Europe/Paris');
    expect(jfk.name, 'America/New_York');
    expect(landing.inLocation(jfk).hour, 12);
    expect(landing.inLocation(jfk).day, 23);
  });
}
