// Milestone 9: the compact tier.
//
// The compact tier is *measured against* the ground-truth fixtures, not gated
// by them. Its boundaries are simplified to roughly 110 m, so disagreeing near
// a border is the tier working as designed, and a disagreement here is data
// rather than a failure.
//
// What is worth pinning is the character of the tier: that it loads, that it
// agrees away from borders, that the enclaves and small islands most at risk
// from simplification survived, and that its rate has not silently drifted.
//
// Needs no boundary data — both tiers are bundled.

@Timeout(Duration(minutes: 10))
library;

import 'package:test/test.dart';
import 'package:timezone_finder/timezone_finder.dart';

import 'fixtures/bootstrap_goldens.dart';
import 'fixtures/golden_points.dart';
import 'fixtures/overlap_pins.dart';

void main() {
  group('compact tier', () {
    final compactFinder = TimeZoneFinder.compact();
    final exactFinder = TimeZoneFinder.exact();

    test('works with no configuration, same API as the exact tier', () {
      expect(compactFinder.find(48.8566, 2.3522), 'Europe/Paris');
      expect(compactFinder.find(-33.8688, 151.2093), 'Australia/Sydney');
      expect(compactFinder.find(0, -140), isNull);
      expect(
        compactFinder.ianaDatabaseVersion,
        exactFinder.ianaDatabaseVersion,
      );
    });

    test('carries fewer zones, because some polygons cannot survive', () {
      // 33 polygons and 27 holes collapse below three vertices at this
      // tolerance and are dropped. A zone disappears only if every one of its
      // polygons went, so the count barely moves — but it can move.
      expect(
        compactFinder.availableTimeZones.length,
        lessThanOrEqualTo(exactFinder.availableTimeZones.length),
      );
      expect(
        compactFinder.availableTimeZones.length,
        greaterThan(400),
        reason: 'simplification should not be losing whole zones wholesale',
      );
    });

    test('agrees with the exact tier on every ground-truth fixture', () {
      // Measured, not assumed: at 110 m all 265 currently agree. A failure
      // here is a finding to investigate and re-publish the rate for, not a
      // fixture to "fix" — the fixtures are ground truth for the exact tier.
      final differing = <String>[];
      for (final point in <GoldenPoint>[...bootstrapGoldens, ...goldenPoints]) {
        final actual = compactFinder.find(point.latitude, point.longitude);
        if (actual != point.zone) {
          differing.add(
            '${point.name}: ${point.zone ?? 'null'} -> '
            '${actual ?? 'null'}',
          );
        }
      }
      expect(
        differing,
        isEmpty,
        reason:
            'the compact tier now differs on fixtures it used to match. '
            'Re-run tool/measure_compact.dart and update the published rate '
            'rather than changing the fixture.\n${differing.join('\n')}',
      );
    });

    test('keeps the enclaves and small islands most at risk', () {
      // These are the shapes simplification would erase first: a country
      // inside another country, microstates, and specks of land with their own
      // zone. If any of these vanished the tier would be much less useful than
      // its size suggests.
      const fragile = <(String, double, double)>[
        ('Maseru, Lesotho', -29.3151, 27.4869),
        ('Vatican City', 41.9029, 12.4534),
        ('San Marino', 43.9424, 12.4578),
        ('Monaco', 43.7384, 7.4246),
        ('Büsingen', 47.6961, 8.6892),
        ('Gibraltar', 36.1408, -5.3536),
        ('Chatham Islands', -43.9535, -176.5597),
        ('Easter Island', -27.1500, -109.4333),
      ];
      for (final (name, lat, lon) in fragile) {
        expect(
          compactFinder.find(lat, lon),
          exactFinder.find(lat, lon),
          reason: '$name did not survive simplification',
        );
      }
    });

    test('agrees away from borders', () {
      // The user-facing number. Points drawn uniformly — the situation of a
      // geocoded address, which is rarely metres from a zone boundary.
      var checked = 0;
      var differing = 0;
      for (var i = 0; i < 40000; i++) {
        final lat = -90 + (i * 7919 % 180000000) / 1000000;
        final lon = -180 + (i * 15485863 % 360000000) / 1000000;
        final expected = exactFinder.find(lat, lon);
        if (expected == null) continue;
        checked++;
        if (compactFinder.find(lat, lon) != expected) differing++;
      }
      expect(checked, greaterThan(1000), reason: 'sample missed land');
      final rate = differing / checked;
      expect(
        rate,
        lessThan(0.02),
        reason:
            'away from borders the tiers should almost always agree; '
            'measured ${(100 * rate).toStringAsFixed(3)}% over $checked '
            'land points',
      );
    });

    test('agrees exactly on a straight border, metres from the line', () {
      // The complement of the test above, and the case the tier's framing
      // usually leaves out. Simplification costs accuracy only where there is
      // detail to remove: Douglas-Peucker collapses a straight run of vertices
      // to its two endpoints with *zero* error, so a legally straight boundary
      // survives the compact tier intact.
      //
      // The Amazonas line between Tabatinga and Porto Acre (Brazilian Federal
      // Law 12,876/2013) is exactly that. The contrast is measured, not
      // assumed: probing 22 m either side of an arbitrary land border, the
      // tiers disagree 20.8% of the time (2000 probes worldwide). Here they
      // must not disagree at all, down to 5.5 m.
      var probed = 0;
      for (var latitude = -4.5; latitude >= -9.5; latitude -= 0.25) {
        // Bracket the crossing, then bisect. The line is oblique, so the
        // western endpoint has to be found rather than assumed.
        var east = -66.5;
        if (exactFinder.find(latitude, east) != 'America/Manaus') continue;
        var west = east;
        var found = false;
        while (west > -70.5) {
          west -= 0.05;
          final zone = exactFinder.find(latitude, west);
          if (zone == 'America/Eirunepe') {
            found = true;
            break;
          }
          if (zone != 'America/Manaus') break;
          east = west;
        }
        if (!found) continue;
        for (var i = 0; i < 40; i++) {
          final middle = (west + east) / 2;
          if (exactFinder.find(latitude, middle) == 'America/Eirunepe') {
            west = middle;
          } else {
            east = middle;
          }
        }
        final line = (west + east) / 2;

        // ~5.5 m, ~22 m, ~110 m, ~1.1 km and ~11 km either side.
        for (final offset in <double>[0.00005, 0.0002, 0.001, 0.01, 0.1]) {
          for (final longitude in <double>[line - offset, line + offset]) {
            final expected = exactFinder.find(latitude, longitude);
            probed++;
            expect(
              compactFinder.find(latitude, longitude),
              expected,
              reason:
                  'the tiers differ ${(offset * 111320 * 0.995).round()} m '
                  'from a straight border at $latitude, $longitude — '
                  'simplification should have nothing to remove here',
            );
          }
        }
      }
      expect(probed, 210, reason: 'boundary not found');
    });

    test('still resolves the disputed overlaps deterministically', () {
      // Simplification can move which polygon wins in an overlap. Whatever it
      // decides must at least be stable, and must still be one of the
      // contenders rather than something else entirely.
      for (final pin in overlapPins) {
        final answer = compactFinder.find(pin.latitude, pin.longitude);
        if (answer == null) continue;
        expect(
          pin.contenders,
          contains(answer),
          reason:
              '${pin.description}: compact returned $answer, which is '
              'neither contender',
        );
        expect(compactFinder.find(pin.latitude, pin.longitude), answer);
      }
    });
  });
}
