/// Zurich Airport departure board — local Shelf server.
///
/// From this directory:
///
///     dart pub get
///     dart run main.dart
///
/// Then open http://127.0.0.1:8080/
library;

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone_finder/timezone_finder.dart';

/// Board clock: civil date and wall time, treated as Zurich local.
final _boardDay = DateTime(2026, 9, 9, 9, 5);

const _port = 8080;

/// ZRH (lon, lat).
const _zurichLngLat = (8.5492, 47.4582);
const _destinations =
    <
      ({
        String flight,
        String city,
        String iata,
        double lng,
        double lat,
        int takeoffHour,
        int takeoffMinute,
        Duration duration,
      })
    >[
      (
        flight: 'SQ345',
        city: 'Singapore',
        iata: 'SIN',
        lng: 103.9899,
        lat: 1.3592,
        takeoffHour: 11,
        takeoffMinute: 35,
        duration: Duration(hours: 12, minutes: 45),
      ),
      (
        flight: 'LX238',
        city: 'Cairo',
        iata: 'CAI',
        lng: 31.4056,
        lat: 30.1219,
        takeoffHour: 12,
        takeoffMinute: 15,
        duration: Duration(hours: 4),
      ),
      (
        flight: 'LX64',
        city: 'Miami',
        iata: 'MIA',
        lng: -80.2906,
        lat: 25.7959,
        takeoffHour: 13,
        takeoffMinute: 0,
        duration: Duration(hours: 10, minutes: 25),
      ),
    ];

void main() async {
  tzdata.initializeTimeZones();

  final origin = findLocation(_zurichLngLat.$1, _zurichLngLat.$2);
  if (origin == null) {
    stderr.writeln('Could not resolve Zurich Airport location.');
    exitCode = 1;
    return;
  }

  final rows = <_FlightRow>[
    for (final d in _destinations)
      _FlightRow.from(
        origin: origin,
        flight: d.flight,
        city: d.city,
        iata: d.iata,
        destLng: d.lng,
        destLat: d.lat,
        takeoffHour: d.takeoffHour,
        takeoffMinute: d.takeoffMinute,
        duration: d.duration,
      ),
  ]..sort((a, b) => a.takeoff.compareTo(b.takeoff));

  // Zurich offset at the board clock (not midnight: that night may be a DST
  // transition).
  final originUtcOffset = tz.TZDateTime(
    origin,
    _boardDay.year,
    _boardDay.month,
    _boardDay.day,
    _boardDay.hour,
    _boardDay.minute,
  ).utcOffsetLabel;

  final router = Router()
    ..get(
      '/',
      (_) => Response.ok(
        _renderBoard(rows, originUtcOffset: originUtcOffset),
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    );

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.loopbackIPv4,
    _port,
  );
  stdout.writeln(
    'Zurich departures → http://${server.address.host}:${server.port}/',
  );
}

class _FlightRow {
  _FlightRow({
    required this.flight,
    required this.city,
    required this.iata,
    required this.takeoff,
    required this.duration,
    required this.landing,
  });

  factory _FlightRow.from({
    required tz.Location origin,
    required String flight,
    required String city,
    required String iata,
    required double destLng,
    required double destLat,
    required int takeoffHour,
    required int takeoffMinute,
    required Duration duration,
  }) {
    final arrival = findLocation(destLng, destLat);
    if (arrival == null) {
      throw StateError('No time zone polygon for $city ($iata)');
    }

    final takeoff = tz.TZDateTime(
      origin,
      _boardDay.year,
      _boardDay.month,
      _boardDay.day,
      takeoffHour,
      takeoffMinute,
    );
    // Same instant, destination clock.
    final landing = takeoff.add(duration).toLocation(arrival);

    return _FlightRow(
      flight: flight,
      city: city,
      iata: iata,
      takeoff: takeoff,
      duration: duration,
      landing: landing,
    );
  }

  final String flight;
  final String city;
  final String iata;
  final tz.TZDateTime takeoff;
  final Duration duration;
  final tz.TZDateTime landing;

  String get destinationLabel => '$city ($iata)';

  String get durationLabel {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}';
  }

  String get takeoffLabel => _formatTime(takeoff);

  /// Destination-local clock; appends `(Day ±n)` when the calendar day differs
  /// from takeoff's (Zurich-local) day.
  String get landingLabel {
    final takeoffDay = DateTime.utc(takeoff.year, takeoff.month, takeoff.day);
    final landingDay = DateTime.utc(landing.year, landing.month, landing.day);
    final dayDelta = landingDay.difference(takeoffDay).inDays;
    final time = _formatTime(landing);
    if (dayDelta == 0) return time;
    final signed = dayDelta > 0 ? '+$dayDelta' : '$dayDelta';
    return '$time (Day $signed)';
  }

  /// Destination UTC offset at landing, e.g. `UTC+08`.
  String get landingOffsetLabel => landing.utcOffsetLabel;
}

String _formatTime(tz.TZDateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}';

String _formatBoardDate(DateTime d) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]} ${d.year}';
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _renderBoard(List<_FlightRow> rows, {required String originUtcOffset}) {
  final bodyRows = rows
      .map(
        (r) =>
            '''
        <tr>
          <td class="mono">${_esc(r.flight)}</td>
          <td>${_esc(r.destinationLabel)}</td>
          <td class="mono">${_esc(r.takeoffLabel)}</td>
          <td class="mono">${_esc(r.landingLabel)}
            <span class="offset">${_esc(r.landingOffsetLabel)}</span>
          </td>
          <td class="mono">${_esc(r.durationLabel)}</td>
        </tr>''',
      )
      .join();

  final boardTime =
      '${_boardDay.hour.toString().padLeft(2, '0')}:'
      '${_boardDay.minute.toString().padLeft(2, '0')}';
  final boardDate = _formatBoardDate(_boardDay);

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Zurich Airport (ZRH) — Departures</title>
  <style>
    :root {
      --ink: #e8d48b;
      --muted: #9a8f5c;
      --line: #3a3420;
      --panel: #12110e;
      --bg: #0a0907;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: "IBM Plex Sans", "Segoe UI", system-ui, sans-serif;
      background:
        radial-gradient(ellipse 80% 50% at 50% -10%, #1a1810 0%, transparent 55%),
        var(--bg);
      color: var(--ink);
      display: flex;
      justify-content: center;
      padding: 2.5rem 1.25rem;
      overflow-x: auto;
    }
    .board {
      flex: 0 0 auto;
      width: max(52rem, max-content);
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 2px;
      padding: 1.75rem 1.5rem 1.25rem;
      box-shadow: 0 24px 48px rgba(0, 0, 0, 0.45);
    }
    header {
      display: grid;
      grid-template-columns: auto auto;
      grid-template-rows: auto auto;
      justify-content: space-between;
      align-items: baseline;
      column-gap: 1rem;
      row-gap: 0.2rem;
      margin-bottom: 1.25rem;
      padding-bottom: 0.85rem;
      border-bottom: 1px solid var(--line);
    }
    h1 {
      grid-column: 1;
      grid-row: 1;
      margin: 0;
      padding: 0;
      font-size: 1.15rem;
      font-weight: 600;
      letter-spacing: 0.02em;
      line-height: 1.25;
      white-space: nowrap;
    }
    .clock {
      display: contents;
    }
    .clock .date-time {
      grid-column: 2;
      grid-row: 1;
      margin: 0;
      margin-inline-start: 2.5rem;
      font-variant-numeric: tabular-nums;
      font-size: 1.15rem;
      line-height: 1.25;
      white-space: nowrap;
    }
    .clock .offset {
      grid-column: 2;
      grid-row: 2;
      margin: 0;
      text-align: end;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 0.95rem;
    }
    th {
      text-align: start;
      font-weight: 500;
      color: #fff;
      font-size: 0.72rem;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      padding: 0.4rem 0.6rem 0.65rem 0;
      border-bottom: 1px solid var(--line);
    }
    td {
      padding: 0.85rem 0.6rem 0.85rem 0;
      border-bottom: 1px solid var(--line);
      vertical-align: baseline;
    }
    tr:last-child td { border-bottom: none; }
    .mono {
      font-family: "IBM Plex Mono", "SF Mono", ui-monospace, monospace;
      font-variant-numeric: tabular-nums;
      letter-spacing: 0.02em;
    }
    .offset {
      display: block;
      margin-top: 0.2rem;
      color: var(--muted);
      font-size: 0.72rem;
      letter-spacing: 0.06em;
    }
    footer {
      margin-top: 1.25rem;
      padding-top: 0.85rem;
      border-top: 1px solid var(--line);
      font-size: 0.7rem;
      color: var(--muted);
    }
    footer p { margin: 0; }
    a { color: var(--ink); }
  </style>
</head>
<body>
  <main class="board">
    <header>
      <h1>Zurich Airport (ZRH) — Departures</h1>
      <div class="clock">
        <p class="mono date-time">${_esc(boardDate)} - ${_esc(boardTime)}</p>
        <p class="offset">${_esc(originUtcOffset)}</p>
      </div>
    </header>
    <table>
      <thead>
        <tr>
          <th>Flight</th>
          <th>Destination</th>
          <th>Takeoff</th>
          <th>Landing</th>
          <th>Flight Duration</th>
        </tr>
      </thead>
      <tbody>
$bodyRows
      </tbody>
    </table>
    <footer>
      <p>Example built with the
        <a href="https://pub.dev/packages/timezone_finder">timezone_finder</a>
        and
        <a href="https://pub.dev/packages/timezone">timezone</a>
        packages.</p>
    </footer>
  </main>
</body>
</html>
''';
}
