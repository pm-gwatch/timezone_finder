// Contract tests for Location / TZDateTime metazone getters.

import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/src/finder.dart' show availableLocationNames;
import 'package:timezone_finder/src/metazone.dart';
import 'package:timezone_finder/src/data/metazone_data.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('Location.metazoneName', () {
    test('Europe/Zurich → Central European Time', () {
      expect(
        getLocation('Europe/Zurich').metazoneName,
        'Central European Time',
      );
    });

    test('America/Santiago → Chile Time', () {
      expect(getLocation('America/Santiago').metazoneName, 'Chile Time');
    });

    test('Europe/London → Greenwich Mean Time (merged generic)', () {
      expect(getLocation('Europe/London').metazoneName, 'Greenwich Mean Time');
    });

    test('Europe/Jersey → Greenwich Mean Time all year', () {
      expect(getLocation('Europe/Jersey').metazoneName, 'Greenwich Mean Time');
    });

    test('Etc/UTC → Coordinated Universal Time (zone-level only)', () {
      expect(getLocation('Etc/UTC').metazoneName, 'Coordinated Universal Time');
    });

    test('Asia/Kolkata joins via BCP-47 to India Standard Time', () {
      expect(getLocation('Asia/Kolkata').metazoneName, 'India Standard Time');
    });

    test('Europe/Kyiv joins via BCP-47 to Eastern European Time', () {
      expect(getLocation('Europe/Kyiv').metazoneName, 'Eastern European Time');
    });

    test('Asia/Amman now → null (no current metazone)', () {
      expect(getLocation('Asia/Amman').metazoneName, isNull);
    });

    test('Africa/Casablanca now → null', () {
      expect(getLocation('Africa/Casablanca').metazoneName, isNull);
    });

    test('Asia/Urumqi now → null (unnamed metazone in en-001)', () {
      expect(getLocation('Asia/Urumqi').metazoneName, isNull);
    });
  });

  // There is no Location.metazoneAbbreviation: tzdb has no season-neutral
  // abbreviation to offer, so the question is only answerable at an instant.
  // Its coverage lives in the TZDateTime.metazoneAbbreviation group below.

  group('TZDateTime.metazoneName', () {
    test('Zurich January → Central European Standard Time', () {
      final z = TZDateTime(getLocation('Europe/Zurich'), 2026, 1, 15, 12);
      expect(z.metazoneName, 'Central European Standard Time');
    });

    test('Zurich July → Central European Summer Time', () {
      final z = TZDateTime(getLocation('Europe/Zurich'), 2026, 7, 15, 12);
      expect(z.metazoneName, 'Central European Summer Time');
    });

    test('London January → Greenwich Mean Time', () {
      final z = TZDateTime(getLocation('Europe/London'), 2026, 1, 15, 12);
      expect(z.metazoneName, 'Greenwich Mean Time');
    });

    test('London July → British Summer Time', () {
      final z = TZDateTime(getLocation('Europe/London'), 2026, 7, 15, 12);
      expect(z.metazoneName, 'British Summer Time');
    });

    test('Dublin July → Irish Standard Time', () {
      final z = TZDateTime(getLocation('Europe/Dublin'), 2026, 7, 15, 12);
      expect(z.metazoneName, 'Irish Standard Time');
    });

    test('Jersey July → null (DST, no daylight string)', () {
      final z = TZDateTime(getLocation('Europe/Jersey'), 2026, 7, 15, 12);
      expect(z.timeZone.isDst, isTrue);
      expect(z.metazoneName, isNull);
    });

    test('Troll July → null', () {
      final z = TZDateTime(getLocation('Antarctica/Troll'), 2026, 7, 15, 12);
      expect(z.metazoneName, isNull);
    });

    test('Kyiv January / July Eastern European Standard / Summer', () {
      final jan = TZDateTime(getLocation('Europe/Kyiv'), 2026, 1, 15, 12);
      final jul = TZDateTime(getLocation('Europe/Kyiv'), 2026, 7, 15, 12);
      expect(jan.metazoneName, 'Eastern European Standard Time');
      expect(jul.metazoneName, 'Eastern European Summer Time');
    });

    test('Amman 2021 still had Eastern European names', () {
      final jan = TZDateTime(getLocation('Asia/Amman'), 2021, 1, 15, 12);
      final jul = TZDateTime(getLocation('Asia/Amman'), 2021, 7, 15, 12);
      expect(jan.metazoneName, 'Eastern European Standard Time');
      expect(jul.metazoneName, 'Eastern European Summer Time');
    });
  });

  group('TZDateTime.metazoneAbbreviation', () {
    test('Zurich July → CEST', () {
      final z = TZDateTime(getLocation('Europe/Zurich'), 2026, 7, 15, 12);
      expect(z.metazoneAbbreviation, 'CEST');
    });

    test('Santiago January → UTC-03, July → UTC-04', () {
      final jan = TZDateTime(getLocation('America/Santiago'), 2026, 1, 15, 12);
      final jul = TZDateTime(getLocation('America/Santiago'), 2026, 7, 15, 12);
      expect(jan.metazoneAbbreviation, 'UTC-03');
      expect(jul.metazoneAbbreviation, 'UTC-04');
    });

    test('Azores July → UTC', () {
      final z = TZDateTime(getLocation('Atlantic/Azores'), 2026, 7, 15, 12);
      expect(z.metazoneAbbreviation, 'UTC');
    });

    // The abbreviation comes from tzdb, so a zone CLDR has no metazone for
    // still has one. These three are the zones where gating the abbreviation
    // on CLDR membership showed up as a missing answer.
    test('answers for zones with no CLDR metazone', () {
      final casablanca = TZDateTime(
        getLocation('Africa/Casablanca'),
        2026,
        7,
        15,
        12,
      );
      final amman = TZDateTime(getLocation('Asia/Amman'), 2026, 7, 15, 12);
      final utc = TZDateTime(getLocation('Etc/UTC'), 2026, 7, 15, 12);

      expect(casablanca.metazoneName, isNull);
      expect(casablanca.metazoneAbbreviation, 'UTC+01');
      expect(amman.metazoneName, isNull);
      expect(amman.metazoneAbbreviation, 'UTC+03');
      expect(utc.metazoneAbbreviation, 'UTC');
    });
  });

  group('TZDateTime.utcOffset', () {
    test('Zurich July → UTC+02 (not CEST)', () {
      final z = TZDateTime(getLocation('Europe/Zurich'), 2026, 7, 15, 12);
      expect(z.metazoneAbbreviation, 'CEST');
      expect(z.utcOffset, 'UTC+02');
    });

    test('matches formatUtcOffset(timeZone.offset)', () {
      final z = TZDateTime(getLocation('Asia/Kolkata'), 2026, 9, 9, 12);
      expect(z.utcOffset, formatUtcOffset(z.timeZone.offset));
      expect(z.utcOffset, 'UTC+05:30');
    });
  });

  group('CLDR timestamp parsing', () {
    test('UTC _from/_to half-open boundaries', () {
      // Europe/Zurich → Europe_Central from 1979-04-01 01:00 UTC onward in
      // modern ranges; pick a known edge from generated data.
      final ranges = zoneMetazoneHistory['Europe/Zurich']!;
      final last = ranges.last;
      expect(last.metazoneId, 'Europe_Central');
      expect(last.toMs, isNull);
      if (last.fromMs != null) {
        expect(metazoneIdAt('Europe/Zurich', last.fromMs!), 'Europe_Central');
        expect(
          metazoneIdAt('Europe/Zurich', last.fromMs! - 1),
          isNot(equals('Europe_Central')),
        );
      }
    });
  });

  group('coverage', () {
    test('Location name null only for known CLDR gaps', () {
      const expectedNull = {
        'Africa/Casablanca',
        'Africa/El_Aaiun',
        'America/Coyhaique',
        'America/Punta_Arenas',
        'Antarctica/Palmer',
        'Asia/Amman',
        'Asia/Damascus',
        'Asia/Urumqi',
        'Pacific/Bougainville',
      };
      final actualNull = <String>[];
      for (final id in availableLocationNames) {
        final name = getLocation(id).metazoneName;
        if (name == null) actualNull.add(id);
      }
      expect(actualNull.toSet(), expectedNull);
    });

    test('DST half without daylight string → null on TZDateTime', () {
      const islands = [
        'Europe/Jersey',
        'Europe/Guernsey',
        'Europe/Isle_of_Man',
        'Antarctica/Troll',
      ];
      for (final id in islands) {
        final jul = TZDateTime(getLocation(id), 2026, 7, 15, 12);
        if (jul.timeZone.isDst) {
          expect(jul.metazoneName, isNull, reason: id);
        }
      }
    });
  });

  group('formatUtcOffset', () {
    test('zero / whole hours / half hours', () {
      expect(formatUtcOffset(Duration.zero), 'UTC');
      expect(formatUtcOffset(const Duration(hours: 4)), 'UTC+04');
      expect(
        formatUtcOffset(const Duration(hours: 4, minutes: 30)),
        'UTC+04:30',
      );
      expect(formatUtcOffset(const Duration(hours: -3)), 'UTC-03');
    });

    test('a negative offset with minutes keeps the sign out of the minutes', () {
      // The one shape that can regress unnoticed: the sign is taken from the
      // total and the parts come from its absolute value, so a slip here reads
      // 'UTC-03:-30'. Newfoundland is the real zone that exercises it.
      expect(
        formatUtcOffset(const Duration(hours: -3, minutes: -30)),
        'UTC-03:30',
      );
      expect(
        formatUtcOffset(const Duration(hours: -9, minutes: -30)),
        'UTC-09:30',
      );
    });

    test('quarter-hour offsets, which exist and are not half hours', () {
      expect(
        formatUtcOffset(const Duration(hours: 5, minutes: 45)),
        'UTC+05:45',
      );
      expect(
        formatUtcOffset(const Duration(hours: 12, minutes: 45)),
        'UTC+12:45',
      );
    });

    test('offsets past nine hours keep two digits, not three', () {
      expect(formatUtcOffset(const Duration(hours: 13)), 'UTC+13');
      expect(formatUtcOffset(const Duration(hours: -11)), 'UTC-11');
    });
  });

  group('utcOffset on real zones with awkward offsets', () {
    // The formatter is package-internal; these pin the same behaviour through
    // the public getter, on zones that actually have these offsets.
    test('America/St_Johns is a negative half hour', () {
      final stJohns = getLocation('America/St_Johns');
      expect(TZDateTime(stJohns, 2026, 1, 15).utcOffset, 'UTC-03:30');
      expect(TZDateTime(stJohns, 2026, 7, 15).utcOffset, 'UTC-02:30');
    });

    test('Asia/Kathmandu is a quarter hour', () {
      expect(
        TZDateTime(getLocation('Asia/Kathmandu'), 2026, 7, 15).utcOffset,
        'UTC+05:45',
      );
    });

    test('Pacific/Kiritimati is past twelve', () {
      expect(
        TZDateTime(getLocation('Pacific/Kiritimati'), 2026, 7, 15).utcOffset,
        'UTC+14',
      );
    });
  });

  group('export', () {
    test('cldrVersion is exported', () {
      expect(cldrVersion, isNotEmpty);
    });
  });
}
